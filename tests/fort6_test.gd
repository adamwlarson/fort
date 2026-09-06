extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func capture(key:String)->void:
	await wait(.15)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func finish(w:FortWorld,id:int,player_id:=1)->void:
	for i in 12:
		if not FortConstruction.pending(w.defenses[id]):break
		w.clock+=.8;w.server_action(player_id,"work_defense",{"id":id})
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.shared={"wood":500,"stone":500,"crystal":100,"iron":100,"aether":100}
	p.position=Vector3(0,0,18);w._build(1,{"kind":"Watchtower","pos":Vector3(0,0,22)})
	if w.defenses.is_empty():print("PLACEMENT_BLOCK ",w.build_block_reason("Watchtower",Vector3(0,0,22),0));quit(1);return
	check(w.defenses.size()==1 and FortConstruction.foundation(w.defenses[1]),"placement creates a foundation rather than finished tower")
	var d:Dictionary=w.defenses[1];var stock:=w.shared.duplicate()
	check(d.hp==72 and stock.wood==482,"foundation reserves exact cost and starts vulnerable")
	w.recv_enemy(901,"Raider",Vector3(0,0,32),500);w._tick_defenses();check(w.enemies[901].hp==500,"unfinished tower does not fire")
	w.recv_player(42,{"name":"Builder","class":2});var engineer:FortPlayer=w.players[42];engineer.set_physics_process(false);engineer.position=Vector3(1,0,25)
	p.position=Vector3(0,0,25);w.server_action(1,"work_defense",{"id":1});w.server_action(1,"work_defense",{"id":1})
	check(d.work==1,"server cooldown blocks rapid construction requests")
	w.server_action(42,"work_defense",{"id":1});check(d.work==3,"second dwarf contributes immediately; Engineer works twice as fast")
	w.clock+=.8;w.server_action(1,"work_defense",{"id":1});check(d.work_visual_stage==1,"frame stage appears while building")
	p.camera_pivot.rotation=Vector3(-.24,0,0);await capture("fort6_construction_frame")
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(6,4,29);camera.look_at(Vector3(0,1,22));camera.current=true
	await capture("fort6_scaffold")
	w.clock+=.8;w.server_action(42,"work_defense",{"id":1});w.clock+=.8;w.server_action(1,"work_defense",{"id":1})
	check(d.work_visual_stage==2,"partially assembled structure is visible before completion");await capture("fort6_assembly")
	w._damage_defense(1,20);finish(w,1)
	check(not FortConstruction.pending(d) and d.max_hp==240 and d.hp==220,"completed tower retains siege damage and receives full maximum health")
	w._tick_defenses();check(w.enemies[901].hp<500,"completed tower starts firing")
	check(w.shared==stock,"hammering consumes reserved materials, not extra supplies")
	await capture("fort6_completed")
	w.set_hearth_level(2);w.server_action(1,"upgrade_defense",{"id":1,"level":1});stock=w.shared.duplicate()
	w.server_action(42,"upgrade_defense",{"id":1,"level":1})
	check(d.level==1 and FortConstruction.pending(d) and w.shared==stock,"upgrade remains a single shared work project until completed")
	w.hud.upgrade_menu.open_nearest();await capture("fort6_project_menu");check(w.hud.upgrade_menu.cancel.visible,"project menu offers refund review");w.toggle_pause()
	finish(w,1);check(d.level==2 and is_equal_approx(d.max_hp,396),"working completes tower upgrade")
	# Cancellation refunds only the untouched fraction and cannot refund twice.
	p.position=Vector3(0,0,35);w._build(1,{"kind":"Barricade","pos":Vector3(0,0,38)});var cancel_id:int=w.next_defense_id-1
	w.clock+=.8;w.server_action(1,"work_defense",{"id":cancel_id})
	var refund:=w.construction.refund(w.defenses[cancel_id]);var revision:int=w.defenses[cancel_id].work_revision;var wood:int=w.shared.wood
	engineer.position=Vector3(1,0,35);w.server_action(42,"cancel_construction",{"id":cancel_id,"revision":revision})
	check(w.defenses.has(cancel_id),"only project owner or host can cancel")
	w.server_action(1,"cancel_construction",{"id":cancel_id,"revision":revision});w.server_action(1,"cancel_construction",{"id":cancel_id,"revision":revision})
	check(not w.defenses.has(cancel_id) and w.shared.wood==wood+refund.wood,"cancellation refunds unused materials exactly once")
	check(FortPlacement.wall_overlap(Vector3.ZERO,0,"MetalWall",Vector3(2.8,0,0),0,"MetalWall")==false,"wall ends can touch without placement gaps")
	check(FortPlacement.wall_overlap(Vector3.ZERO,0,"MetalWall",Vector3.ZERO,PI/2,"MetalWall"),"crossing walls are rejected")
	check(not FortPlacement.wall_overlap(Vector3.ZERO,0,"MetalWall",Vector3(1.4,0,1.4),PI/2,"MetalWall"),"right-angle wall corners connect")
	w._spawn_defense("MetalWall",Vector3(20,0,35),0,false);var wall_id:int=w.next_defense_id-1
	check(FortPlacement.snap(w,"MetalWall",Vector3(23.5,0,35),0).is_equal_approx(Vector3(22.8,0,35)),"preview snaps to existing wall endpoint")
	# Route around a short barrier; specialized enemies choose actual siege targets.
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w.recv_enemy(902,"Raider",Vector3(20,0,41),500);await physics_frame
	var raider:Dictionary=w.enemies[902];FortSiege.route(w,raider,Vector3(20,0,29))
	check(not raider.get("route_points",[]).is_empty(),"raider finds exposed wall end instead of sliding against it")
	w.recv_enemy(903,"Brute",Vector3(20,0,38),500)
	check(FortSiege.priority(w,w.enemies[903])==wall_id,"brute selects nearby wall for breaching")
	w.enemies[903].node.position=Vector3(20,0,36.8);var wall_hp:float=w.defenses[wall_id].hp
	FortSiege.strike(w,w.enemies[903],wall_id);check(w.defenses[wall_id].hp==wall_hp,"siege attack has a warning before impact")
	w.clock+=.7;FortSiege.strike(w,w.enemies[903],wall_id);check(w.defenses[wall_id].hp==wall_hp-42,"brute windup lands structural damage")
	var guarded_stock:=w.shared.duplicate();w._damage_defense(wall_id,9999);check(w.shared==guarded_stock,"enemy destruction never refunds materials")
	w._spawn_defense("Mender",Vector3(31,0,35),0,false)
	w._spawn_defense("Watchtower",Vector3(30,0,42),0,false);var work_target:int=w.next_defense_id-1
	w.construction.begin(work_target,1,{},"build")
	w.recv_enemy(904,"Sapper",Vector3(30,0,35),500)
	check(FortSiege.priority(w,w.enemies[904])==work_target,"sapper favors a vulnerable work site over a nearby finished tower")
	for id in w.enemies.keys():
		if id!=904:w.recv_enemy_dead(id)
	w._spawn_defense("MetalWall",Vector3(30,0,38.5),0,false);var blocking_wall:int=w.next_defense_id-1
	for frame in 80:
		w.clock+=1.0/30;w._simulate_enemies(1.0/30);w.raiders.tick();await physics_frame
	check(w.defenses[blocking_wall].hp<850,"sapper breaches the intervening wall instead of getting stuck pursuing its work-site target")
	# Physical quarry ramp and elevated mining resources.
	check(w.frontier.has_node("RustscarQuarry"),"hearth two loads authored quarry")
	var elevated:=0
	for resource in w.resource_nodes.values():
		if resource.kind=="iron" and resource.node.position.y>=2:elevated+=1
	check(elevated>=8,"quarry contains iron on real upper terraces")
	w.hud.hide();camera.position=Vector3(87,24,43);camera.look_at(Vector3(122,2,9));await capture("fort6_rustscar")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	p.position=Vector3(109,.4,20);p.look_yaw=-PI/2;p.set_physics_process(true);Input.action_press("move_forward")
	await wait(2.5);Input.action_release("move_forward");await wait(.1)
	check(p.position.x>120 and p.position.y>1.8,"dwarf walks up quarry ramp onto terrace")
	p.position=Vector3(123,2.2,-11);p.velocity=Vector3.ZERO;Input.action_press("move_forward");await wait(2);Input.action_release("move_forward");await wait(.1)
	check(p.position.x>133 and p.position.y>3.8,"second ramp and landing reach the upper quarry shelf")
	p.set_physics_process(false);p.position=Vector3(124,2.1,9);w.clock+=2;w.server_action(1,"interact",{})
	check(p.carrying.get("iron",0)>0,"elevated quarry ore is harvestable")
	camera.position=Vector3(119,7,16);camera.look_at(Vector3(126,4,1));await capture("fort6_crane")
	w.hud.show();p.camera.current=true;w.local_build_mode=true;w.construction.draw_range();check(w.construction.range_ring.visible,"construction mode shows current build boundary")
	w.local_build_mode=false;w.construction.draw_range();check(not w.construction.range_ring.visible,"build boundary disappears outside construction")
	main._leave_game();await wait(.2);main.queue_free();await wait(.1)
	print("FORT6_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
