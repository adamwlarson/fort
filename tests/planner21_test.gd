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
	for i in 100:
		if w.castle.rooms[k].task=="":break
		w.clock+=.7;w.castle.work(1,k)
func shot(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24821;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);w.scenery_keepouts.clear();w.set_hearth_level(3)
	w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	for option in w.castle.candidates("0:0:0"):
		p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",option,"Stairs" if option.x==1 else "Courtyard",w.castle.revision);complete(option.key)
	p.position=w.castle.rooms["1:0:0"].sign;w.castle.plan(1,"1:0:0",{"x":1,"z":0,"floor":1},"Courtyard",w.castle.revision);complete("1:0:1")
	p.position=w.castle.rooms["0:0:0"].sign;var menu:=w.castle.menu;menu.open_nearest();await create_timer(.1).timeout
	var map:=menu.planner
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=map.map.global_position+map.regions["2:0:0"].get_center();root.push_input(click,true)
		click=click.duplicate();click.pressed=false;root.push_input(click,true);await create_timer(.1).timeout
		check(map.selected=="2:0:0" and menu.target=="1:0:0","real mouse click selects the map footprint and its construction source")
		click=click.duplicate();click.button_index=MOUSE_BUTTON_WHEEL_UP;click.pressed=true;root.push_input(click,true)
		check(map.zoom>1,"mouse wheel zooms the floor plan")
		map.zoom=1;map.pan=Vector2.ZERO;map.select_room("0:0:0")
	check(map.visible and map.cells["0:0:0"].status=="finished" and map.cells["2:0:0"].status=="ready","ground map shows finished rooms and buildable connections across the castle")
	var revision:=w.castle.revision;map.select_room("1:0:1");await create_timer(.1).timeout
	check(menu.panel.visible and menu.anchor=="0:0:0" and menu.target=="1:0:1","browsing another floor does not close the architect or move the player")
	check(menu.plan_button.disabled and menu.placement_status.text.contains("REMOTELY"),"remote inspection visibly requires the selected room's sign")
	menu.send("castle_task",{"task":"walls"});check(w.castle.revision==revision,"remote map inspection cannot perform unauthorized construction")
	map.select_cell("2:0:1")
	check(map.cells["2:0:1"].status=="locked" and map.support.visible and menu.placement_status.text.contains("supporting"),"locked upper footprint identifies missing supporting room")
	await shot("planner21_upstairs")
	map.show_support();check(map.floor_index==0 and map.required=="2:0:0" and map.caption.text.contains("REQUIRED SUPPORT"),"show support changes floor and highlights the exact missing cell")
	check(menu.target=="1:0:0","missing support selects its downstairs construction sign, not the upstairs sign")
	await shot("planner21_support")
	map.select_cell("2:0:0");map.mark_sign()
	check(not w.menu_open and is_instance_valid(map.marker) and map.marker.position.distance_to(w.castle.rooms["1:0:0"].sign+Vector3.UP*3)<.1,"mark sign returns to play with a world-space construction destination")
	p.position=w.castle.rooms["1:0:0"].sign;menu.open_nearest();map.select_cell("2:0:0")
	check(not menu.plan_button.disabled,"walking to the marked sign enables the valid plan")
	menu.place_selected();await create_timer(.1).timeout;map.refresh()
	check(w.castle.rooms.has("2:0:0") and map.cells["2:0:0"].status=="project","placing from map creates a gold unfinished project")
	map.select_room("2:0:0");check(menu.guidance.text.contains("STEP 2"),"unfinished room inspection exposes missing resources and work instructions")
	menu.close_panel();complete("2:0:0");p.position=w.castle.rooms["1:0:1"].sign;menu.open_nearest();map.select_cell("2:0:1")
	check(not menu.plan_button.disabled and not map.support.visible and map.cells["2:0:1"].status=="ready","finishing support unlocks the same upstairs map cell")
	await shot("planner21_ready");menu.close_panel()
	main.queue_free();await create_timer(.1).timeout;print("PLANNER21_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
