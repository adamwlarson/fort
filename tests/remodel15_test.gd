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
		if not w.castle.rooms.has(k) or w.castle.rooms[k].task=="":break
		w.clock+=.7;w.castle.work(1,k)
func plan(from:String,x:int,z:int,floor:int,kind:String)->void:
	p.position=w.castle.rooms[from].sign;w.castle.plan(1,from,{"x":x,"z":z,"floor":floor},kind,w.castle.revision);complete(FortCastle.key(x,z,floor))
func run()->void:
	FortSave.test_directory="res://build/remodel15_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24717;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);w.set_hearth_level(3)
	for id in w.resource_nodes:w.recv_resource(id,0,false)
	w.scenery_keepouts.clear();w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	plan("0:0:0",1,0,0,"Courtyard")
	check(w.castle.rooms["1:0:0"].paid.wood==30,"finished wing retains original paid ledger")
	check(FortCastleRemodel.reason(w.castle,"0:0:0","Merchant",1)!="","keep is protected")
	p.position=w.castle.rooms["1:0:0"].sign
	w.castle.menu.open_nearest();w.castle.menu.kinds.select(1);w.castle.menu.refresh_preview();await create_timer(.15).timeout
	check(is_instance_valid(w.castle.menu.overview) and w.castle.menu.overview.current and w.castle.menu.ghost.get_child_count()>15,"architect has overview and detailed stair/entrance preview")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/remodel15_preview.png"))
	w.castle.menu.mode.select(1);w.castle.menu.kinds.select(3);w.castle.menu.refresh_preview()
	check(not w.castle.menu.remodel_button.disabled,"valid remodel is available in the architect menu")
	w.castle.menu.remodel_button.pressed.emit();check(w.castle.rooms["1:0:0"].task=="","remodel requires confirmation")
	w.castle.menu.remodel_button.pressed.emit();w.castle.menu.close_panel()
	check(w.castle.rooms["1:0:0"].task=="remodel" and w.castle.rooms["1:0:0"].kind=="Courtyard","confirmed project preserves old room until crew finishes")
	check(w.castle.placement_reason(Vector3(20,.6,0))!="","new defenses cannot obstruct an active remodel")
	var stock:Dictionary=w.shared.duplicate();var rev:=w.castle.revision
	w.castle.fund(1,"1:0:0",true,rev);w.castle.fund(1,"1:0:0",true,rev)
	check(w.shared.wood==stock.wood-65 and w.shared.crystal==stock.crystal-8,"racing donations charge new room materials once")
	w.clock+=1;w.castle.work(1,"1:0:0");var progress:float=w.castle.rooms["1:0:0"].work
	check(FortSave.write_slot("slot1",w)=="","partial remodel can be saved")
	var checkpoint:=FortSave.read_slot("slot1")
	check(checkpoint.data.schema==2,"new projects use save format 2")
	var legacy:Dictionary=checkpoint.data.duplicate(true);legacy.schema=1;legacy.world.castle.rooms["1:0:0"].task="";legacy.world.castle.rooms["1:0:0"].erase("paid")
	check(FortSave.validate(legacy)=="","Fort 14 schema and rooms without paid ledgers remain supported")
	main._leave_game("resume remodel");await create_timer(.1).timeout;main.port_edit.value=24717;main.load_expedition("slot1");main._start_match();w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.castle.rooms["1:0:0"].remodel_kind=="Merchant" and w.castle.rooms["1:0:0"].work==progress,"save resumes exact remodeling target and work")
	w.scenery_keepouts.clear()
	complete("1:0:0")
	check(w.castle.rooms["1:0:0"].kind=="Merchant" and w.shared.wood==stock.wood-65+15 and w.shared.stone==stock.stone-65+27,"completion refunds half the OLD room after paying for the new room")
	var paid_before:Dictionary=w.shared.duplicate();p.position=w.castle.rooms["1:0:0"].sign
	FortCastleRemodel.begin(w.castle,1,"1:0:0","Research",w.castle.revision);w.castle.fund(1,"1:0:0",true,w.castle.revision);w.castle.cancel(1,"1:0:0",w.castle.revision)
	check(w.shared==paid_before and w.castle.rooms["1:0:0"].kind=="Merchant","cancel before work refunds only new donations and retains old room")
	w.is_night=true;check(FortCastleRemodel.reason(w.castle,"1:0:0","",1).contains("daylight"),"dismantling is blocked at night");w.is_night=false
	w.recv_enemy(888,"Raider",Vector3(23,0,0),100);check(FortCastleRemodel.reason(w.castle,"1:0:0","",1).contains("enemies"),"nearby enemies block demolition");w.recv_enemy_dead(888)
	w.add_network_player(42,{"name":"Visitor","class":1});w.players[42].position=Vector3(20,.7,2)
	check(FortCastleRemodel.reason(w.castle,"1:0:0","",1).contains("dwarves"),"crew must leave the room before remodeling");w.recv_remove_player(42)
	w.recv_defense(889,"Barricade",Vector3(20,.6,2),0,300,false)
	check(FortCastleRemodel.reason(w.castle,"1:0:0","",1).contains("Salvage"),"existing defenses must be salvaged explicitly");w.recv_remove_defense(889,true)
	plan("1:0:0",2,0,0,"Courtyard")
	check(FortCastleRemodel.reason(w.castle,"1:0:0","",1).contains("connection"),"bridge room cannot strand an outer wing")
	p.position=w.castle.rooms["2:0:0"].sign;FortCastleRemodel.begin(w.castle,1,"2:0:0","",w.castle.revision);var before:int=w.shared.wood;complete("2:0:0")
	check(not w.castle.rooms.has("2:0:0") and w.shared.wood==before+15 and p.position.distance_to(Vector3(0,.7,7))<.1,"hands-on dismantling refunds once and returns worker to keep")
	for target in [[-1,0],[0,1],[0,-1]]:plan("0:0:0",target[0],target[1],0,"Stairs")
	plan("0:-1:0",0,-1,1,"Courtyard")
	check(FortCastleRemodel.reason(w.castle,"0:-1:0","Merchant",1).contains("upper"),"essential stairs cannot be remodeled under an upper floor")
	check(FortCastleRemodel.reason(w.castle,"0:-1:0","",1).contains("upper"),"supporting floor cannot be removed")
	check(w.castle.placement_reason(Vector3(0,.6,10),1.4).contains("entrances"),"building footprints cannot block room entrances")
	check(w.castle.placement_reason(Vector3(6,4.6,-14),1.4).contains("stairwell"),"upper landing clearance includes building footprint")
	p.position=w.castle.rooms["1:0:0"].sign;FortCastleRemodel.begin(w.castle,1,"1:0:0","Research",w.castle.revision);w.castle.fund(1,"1:0:0",true,w.castle.revision);w.clock+=1;w.castle.work(1,"1:0:0")
	var sign:Node3D=w.castle.visuals["1:0:0"].get_node("ProjectSign")
	check(sign.get_node("WorkMeter").visible and sign.get_node("Caption").text.contains("WORK"),"signpost shows work stage and visible progress meter")
	w.castle.menu.open_nearest();w.castle.menu.mode.select(1);w.castle.menu.refresh_preview();await create_timer(.15).timeout
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/remodel15_project.png"))
	w.castle.menu.close_panel();main.queue_free();await create_timer(.1).timeout
	print("REMODEL15_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
