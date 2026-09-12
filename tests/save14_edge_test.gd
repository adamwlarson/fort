extends SceneTree
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func complete(k:String)->void:
	p.position=w.castle.rooms[k].sign;w.castle.fund(1,k,true,w.castle.revision)
	for i in 60:
		if w.castle.rooms[k].task=="":break
		w.clock+=.7;w.castle.work(1,k)
func run()->void:
	FortSave.test_directory="res://build/save14_edge_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24707;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);w.set_hearth_level(3)
	for id in w.resource_nodes:w.recv_resource(id,0,false)
	w.scenery_keepouts.clear();w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	for c in w.castle.candidates("0:0:0"):
		p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",c,"Stairs",w.castle.revision);complete(c.key)
	p.position=w.castle.rooms["1:0:0"].sign;w.castle.plan(1,"1:0:0",{"x":1,"z":0,"floor":1},"Research",w.castle.revision);complete("1:0:1")
	p.position=w.castle.rooms["1:0:1"].sign;w.castle.begin_task(1,"1:0:1","tech:Ballistics",w.castle.revision);complete("1:0:1")
	p.position=w.castle.rooms["0:0:0"].sign;w.castle.begin_task(1,"0:0:0","walls",w.castle.revision);complete("0:0:0")
	var wall_id:int=w.castle.rooms["0:0:0"].walls[0];w.defenses[wall_id].hp=321
	w.recv_defense(800,"Watchtower",Vector3(20,4.6,0),.3,300,false);w.defenses[800].paid={"wood":25,"stone":15};w.defenses[800].hp=250
	w.add_network_player(30,{"name":"Builder","class":2});w.construction.begin(800,30,{"wood":20,"stone":15},"upgrade");w.defenses[800].work=3.0;w.recv_remove_player(30)
	w.pets._create(1,0,FortPets.HOME+Vector3(-1,0,2));w.pets.pets[1].resource="rest";w.pets.pets[1].cargo=5;w.pets.pets[1].cargo_kind="wood";w.pets.next_id=2
	p.position=Vector3(18,4.6,0)
	check(FortSave.write_slot("slot2",w)=="","multi-storey castle checkpoint writes")
	var snapshot:=FortSave.read_slot("slot2");var stock:Dictionary=w.shared.duplicate()
	# A stray interrupted temporary file must never displace the committed primary.
	var stray:=FileAccess.open(FortSave.path("slot2")+".tmp",FileAccess.WRITE);stray.store_string("unfinished");stray.close()
	check(FortSave.read_slot("slot2").error=="","interrupted temporary write leaves primary readable")
	main._leave_game("reload castle");await create_timer(.1).timeout;main.port_edit.value=24707;main.pending_save=snapshot.data;main._host();main._start_match();w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.castle.rooms.size()==6 and w.castle.rooms["1:0:1"].complete and is_equal_approx(w.castle.floor_at(Vector3(18,4.6,0)),4.6),"completed upper floor and supporting wings restore")
	check(w.defenses[wall_id].hp==321 and w.defenses[wall_id].node.has_meta("castle_skin") and w.castle.rooms["0:0:0"].walls.size()==16,"curtain walls retain damage and castle artwork")
	check(is_equal_approx(w.castle.tower_multiplier(),1.15),"completed research remains active")
	check(w.defenses[800].work==3 and w.defenses[800].work_kind=="upgrade" and w.defenses[800].paid.wood==25,"partial tower upgrade and paid ledger survive")
	w.add_network_player(60,{"name":"Returning builder","class":2});check(w.defenses[800].work_owner==60,"disconnected construction ownership maps to returning class")
	var refund:=w.construction.refund(w.defenses[800]);w.players[60].position=Vector3(20,4.6,1);w.construction.cancel(60,800,w.defenses[800].work_revision)
	check(w.shared.wood==stock.wood+refund.wood and w.defenses[800].work_total==0,"returning owner can cancel for the unused-material refund")
	var before:int=w.shared.wood;w.pets.tick(.01);w.pets.tick(.01)
	check(w.shared.wood==before+5 and w.pets.pets[1].cargo==0,"saved pet cargo deposits exactly once")
	w.recv_remove_player(60)
	main.world.toggle_pause();await create_timer(.1).timeout
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/save14_camp.png"))
	# A file in place of the folder simulates a non-writable destination without touching real saves.
	var good_folder:=FortSave.test_directory;var blocked:=good_folder+"/blocked";var blocker:=FileAccess.open(blocked,FileAccess.WRITE);blocker.store_string("test");blocker.close();FortSave.test_directory=blocked
	main.save_and_leave();check(is_instance_valid(main.world) and w.save_status.contains("failed"),"failed save-and-exit keeps the expedition open")
	w.autosave_enabled=true;main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST);w.autosave_enabled=false
	check(is_instance_valid(main.world),"window-close save failure also keeps the game open")
	FortSave.test_directory=good_folder;check(FortSave.read_slot("slot2").error=="","failed save leaves the previous checkpoint intact")
	w.ended=true;check(FortSave.write_slot("slot2",w)!="","ended expedition cannot overwrite a live checkpoint")
	w.ended=false;main.queue_free();await create_timer(.1).timeout
	print("SAVE14_EDGE_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
