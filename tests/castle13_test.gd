extends SceneTree
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func complete(k:String)->void:
	p.position=w.castle.rooms[k].sign+Vector3(0,.1,1)
	w.castle.fund(1,k,true,w.castle.revision)
	for i in 100:
		if not w.castle.rooms.has(k) or w.castle.rooms[k].task=="":break
		w.clock+=.7;w.castle.work(1,k)
func walk_to(goal:Vector3,seconds:=4.0)->void:
	p.set_physics_process(true);var start:=Time.get_ticks_msec()
	while Vector2(p.position.x-goal.x,p.position.z-goal.z).length()>.6 and Time.get_ticks_msec()-start<seconds*1000:
		var direction:Vector3=goal-p.position;p.look_yaw=atan2(-direction.x,-direction.z);Input.action_press("move_forward");await create_timer(.05).timeout
	Input.action_release("move_forward");p.velocity=Vector3.ZERO;p.set_physics_process(false)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24667;main._host();main._start_match();await create_timer(.3).timeout
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);w.hud.hide()
	check(w.castle.rooms.size()==1,"starts with one open raised keep")
	check(p.position.y>.5,"dwarf spawns above the raised floor")
	p.position=Vector3(0,.1,14);await walk_to(Vector3(0,.6,8))
	check(p.position.z<9 and p.position.y>.5,"normal movement climbs the keep entrance steps")
	for r in w.resource_nodes.values():w.recv_resource(r.id if r.has("id") else w.resource_nodes.find_key(r),0,false)
	for c in w.castle.candidates("0:0:0"):check(w.castle.plan_reason("0:0:0",c,"Courtyard")=="","starter "+c.label+" wing can be cleared and built")
	w.set_hearth_level(3)
	for r in w.resource_nodes.values():w.recv_resource(w.resource_nodes.find_key(r),0,false)
	# Isolate construction semantics from world obstacles, tested above and separately below.
	w.scenery_keepouts.clear();w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	var first:=true
	for c in w.castle.candidates("0:0:0"):
		p.position=w.castle.rooms["0:0:0"].sign
		w.castle.plan(1,"0:0:0",c,"Stairs" if first else "Courtyard",w.castle.revision)
		check(w.castle.rooms.has(c.key) and not w.castle.rooms[c.key].complete,"planning creates an unfinished signpost")
		var revision:=w.castle.revision;p.position=w.castle.rooms[c.key].sign;p.carrying={"wood":3}
		w.castle.fund(1,c.key,false,revision);check(p.carrying.wood==0 and w.castle.rooms[c.key].funded.wood==3,"partial carried supplies go into project")
		w.castle.fund(1,c.key,false,revision);check(w.castle.rooms[c.key].funded.wood==3,"stale donations cannot double charge")
		complete(c.key);check(w.castle.rooms[c.key].complete,"hands-on crew work completes the wing")
		first=false
	check(w.castle.completed_ground()==4,"four ground wings unlock upward expansion")
	p.position=Vector3(0,.6,4)
	w.recv_enemy(999,"EmberRunner",Vector3(34,0,6),100)
	for i in 800:
		w.clock+=.016;w._simulate_enemies(.016)
		if i%8==0:await physics_frame
	print("CASTLE_RAIDER_POSITION ",w.enemies[999].node.position," route ",w.enemies[999].get("route_points",[]))
	check(w.enemies[999].node.position.length()<8,"hearth attackers enter expanded platforms through stairs")
	w.recv_enemy_dead(999)
	var upstairs:={"x":1,"z":0,"floor":1};p.position=w.castle.rooms["1:0:0"].sign
	w.castle.plan(1,"1:0:0",upstairs,"Stairs",w.castle.revision);complete("1:0:1")
	check(is_equal_approx(w.castle.floor_at(Vector3(20,4.6,0)),4.6),"upper floor supports elevated construction")
	p.position=Vector3(26,.7,-5.5);await walk_to(Vector3(26,4.6,5.7))
	check(p.position.y>4.4 and p.position.z>4.7,"normal movement climbs to the second storey through the open stairwell")
	await walk_to(Vector3(26,.6,-5.5))
	check(p.position.y<.9 and p.position.z< -4.7,"normal movement descends the stairwell without getting stuck")
	check(w.castle.plan_reason("1:0:1",{"x":2,"z":0,"floor":1},"Courtyard").contains("supporting"),"unsupported upper wings are rejected")
	p.position=w.castle.rooms["1:0:1"].sign;w.castle.plan(1,"1:0:1",{"x":1,"z":0,"floor":2},"Research",w.castle.revision);complete("1:0:2")
	p.position=Vector3(14,4.7,-5.5);await walk_to(Vector3(14,8.6,5.7))
	check(p.position.y>8.4 and p.position.z>4.7,"alternating stairwells remain walkable to the third storey")
	p.position=w.castle.rooms["1:0:2"].sign;w.castle.begin_task(1,"1:0:2","tech:Logistics",w.castle.revision);complete("1:0:2")
	check(w.castle.pack_bonus()==6 and p.carry_limit==24,"research is hand-built and changes crew capacity")
	var before:int=w.shared.wood;w.castle.begin_task(1,"1:0:2","tech:Logistics",w.castle.revision);check(w.shared.wood==before and w.castle.rooms["1:0:2"].task=="","completed research cannot charge again")
	p.position=w.castle.rooms["0:0:0"].sign;w.castle.begin_task(1,"0:0:0","walls",w.castle.revision);complete("0:0:0")
	check(w.castle.rooms["0:0:0"].walls.size()==16,"curtain walls create sixteen damageable, salvageable defenses")
	check(w.full_state().castle.rooms.size()==7,"late join receives castle layout, funding and research")
	check(w.castle.blocks_resource(Vector3(20,0,0)),"resources cannot respawn in completed wings")
	for addition in [["1:0:0",2,0,"Merchant"],["0:1:0",0,2,"Gatherers"],["-1:0:0",-2,0,"Rampart"]]:
		p.position=w.castle.rooms[addition[0]].sign
		w.castle.plan(1,addition[0],{"x":addition[1],"z":addition[2],"floor":0},addition[3],w.castle.revision)
		complete(FortCastle.key(addition[1],addition[2],0))
	p.position=w.castle.rooms["2:0:0"].sign;var stock:=w.shared.duplicate();var rev:=w.castle.revision
	w.castle.trade(1,"2:0:0","iron",rev);w.castle.trade(1,"2:0:0","iron",rev)
	check(w.shared.wood==stock.wood-20 and w.shared.stone==stock.stone-10 and w.shared.iron==stock.iron+2,"merchant trade charges once and delivers the advertised iron")
	p.position=w.castle.rooms["0:2:0"].sign;w.castle.assign(1,"0:2:0","wood",w.castle.revision)
	var resource_id:=-1
	for id in w.resource_nodes:
		if w.resource_nodes[id].kind=="wood":resource_id=id;break
	var resource:Dictionary=w.resource_nodes[resource_id];resource.node.position=Vector3(13,0,40);w.recv_resource(resource_id,10,false)
	var wood:int=w.shared.wood;w.clock+=13;w.castle.tick()
	check(resource.amount==8 and w.shared.wood==wood+2,"gathering lodge consumes real resources and delivers shared supplies")
	w.is_night=true;w.clock+=13;w.castle.tick();check(resource.amount==8,"lodges stop gathering during night raids");w.is_night=false
	p.position=w.castle.rooms["1:0:2"].sign
	for tech in ["Masonry","Ballistics"]:w.castle.begin_task(1,"1:0:2","tech:"+tech,w.castle.revision);complete("1:0:2")
	check(is_equal_approx(w.castle.work_multiplier(),1.15) and is_equal_approx(w.castle.tower_multiplier(),1.15),"masonry and ballistics research activate crew bonuses")
	w.recv_enemy(998,"Raider",Vector3(70,0,0),1000);w._damage_enemy(998,100,Vector3.ZERO,"tower_damage")
	check(is_equal_approx(w.enemies[998].hp,885),"ballistics multiplies actual tower damage");w.recv_enemy_dead(998)
	p.position=w.castle.rooms["2:0:0"].sign;w.castle.plan(1,"2:0:0",{"x":3,"z":0,"floor":0},"Courtyard",w.castle.revision)
	p.position=w.castle.rooms["3:0:0"].sign;stock=w.shared.duplicate();w.castle.fund(1,"3:0:0",true,w.castle.revision);w.clock+=1;w.castle.work(1,"3:0:0")
	var refund:=floori(30*(1-float(w.castle.rooms["3:0:0"].work)/20));w.castle.cancel(1,"3:0:0",w.castle.revision)
	check(not w.castle.rooms.has("3:0:0") and w.shared.wood==stock.wood-30+refund,"cancellation removes blueprint and refunds only unused paid materials")
	p.position=Vector3(18,8.6,-1);p.class_id=2;w._ability(1);p.class_id=0
	var field:Dictionary=w.defenses[w.next_defense_id-1]
	check(field.temporary and is_equal_approx(field.node.position.y,8.6),"engineer field turret deploys on the occupied upper floor")
	for k in w.castle.rooms.keys():
		if k=="0:0:0":continue
		p.position=w.castle.rooms[k].sign;w.castle.begin_task(1,k,"walls",w.castle.revision);complete(k)
	check(w.defenses.size()>=162,"a ten-room three-storey castle supports 160 real wall defenses")
	var camera:=Camera3D.new();w.add_child(camera);camera.current=true;camera.position=Vector3(49,34,53);camera.look_at(Vector3(6,1,0));camera.far=200
	if DisplayServer.get_name()!="headless":
		await create_timer(.5).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/castle13_overview.png"))
		camera.position=Vector3(32,10,21);camera.look_at(Vector3(17,4,0));await create_timer(.2).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/castle13_detail.png"))
	p.position=w.castle.rooms["1:0:2"].sign;w.castle.menu.open_nearest();await create_timer(.2).timeout
	check(w.castle.menu.panel.visible,"architect menu opens at a construction sign")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/castle13_menu.png"))
	w.castle.menu.close_panel();main.queue_free();await create_timer(.2).timeout
	print("CASTLE13_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
