extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func pulse(w:FortWorld,k:String)->void:w.clock+=.7;w.castle.work(1,k)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24757;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	for id in w.resource_nodes:w.recv_resource(id,0,false)
	w.scenery_keepouts.clear();p.position=w.castle.rooms["0:0:0"].sign
	w.castle.plan(1,"0:0:0",{"x":1,"z":0,"floor":0},"Courtyard",w.castle.revision)
	var k:="1:0:0";p.position=w.castle.rooms[k].sign;w.shared={"wood":100,"stone":100};p.carrying={"wood":5,"stone":5}
	w.castle.menu.open_nearest();await create_timer(.1).timeout
	check(w.castle.menu.guidance.text.contains("shared stock first") and w.castle.prompt(p).contains("shared stock"),"architect and sign explain hold-E shared funding")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/shared_castle17.png"))
	w.castle.menu.close_panel()
	pulse(w,k)
	check(w.shared.wood==70 and w.shared.stone==45 and p.carrying.wood==5 and p.carrying.stone==5,"hold E supplies exact recipe from shared stock first, preserving the pack")
	check(not w.castle.needs_supplies(w.castle.rooms[k]) and not w.castle.rooms[k].complete,"funding still requires hands-on construction")
	for i in 30:pulse(w,k)
	check(w.castle.rooms[k].complete and w.shared.wood==70 and w.shared.stone==45,"continued holding completes without another charge")
	p.position=w.castle.rooms[k].sign;w.castle.begin_task(1,k,"walls",w.castle.revision)
	w.shared={"wood":10,"stone":20};p.carrying={"wood":7,"stone":9};pulse(w,k)
	check(w.castle.rooms[k].funded.wood==17 and w.castle.rooms[k].funded.stone==29,"partial wall funding combines shared stock and carried supplies")
	check(w.shared.wood==0 and w.shared.stone==0 and p.carrying.wood==0 and p.carrying.stone==0,"partial funding never makes either inventory negative")
	var revision:=w.castle.revision;pulse(w,k)
	check(w.castle.revision==revision and w.castle.rooms[k].work==0,"empty inventories cannot advance unpaid construction")
	w.shared={"wood":100,"stone":100};p.position=Vector3(0,0,80);pulse(w,k)
	check(w.shared.wood==100 and w.shared.stone==100,"distant dwarf cannot spend shared stock at a sign")
	p.position=w.castle.rooms[k].sign;pulse(w,k)
	check(w.shared.wood==77 and w.shared.stone==29,"restocking funds only the remaining wall materials")
	w.castle.cancel(1,k,w.castle.revision)
	check(w.shared.wood==117 and w.shared.stone==129,"canceling unworked project returns both funding sources to shared stock once")
	w.castle.cancel(1,k,w.castle.revision)
	check(w.shared.wood==117 and w.shared.stone==129,"repeated cancellation cannot duplicate a refund")
	main.queue_free();await create_timer(.1).timeout;print("SHARED_CASTLE17_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
