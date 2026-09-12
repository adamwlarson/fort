extends SceneTree
var failures:=0
var w:FortWorld
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func box(pos:Vector3,size:Vector3)->StaticBody3D:
	var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;body.add_child(col);w.add_child(body);body.position=pos;return body
func walk(body:CharacterBody3D,state:Dictionary,goal:Vector3,count:int)->void:
	for i in count:
		await physics_frame;w.clock+=1.0/60
		var direction:=FortNavigation.direction(w,body,state,w.castle.travel_goal(body.position,goal));direction.y=0;direction=direction.normalized()
		body.velocity=direction*5+Vector3.UP*(body.velocity.y-22.0/60);FortRecovery.step_up(body,Vector3(body.velocity.x,0,body.velocity.z)/60);body.move_and_slide()
		if body.position.distance_to(goal)<.65:break
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24823;main._host();main._start_match()
	w=main.world;w.set_process(false);var p:=w.local_player();p.set_physics_process(false)
	var platform:=box(Vector3(0,12,0),Vector3(40,1,40))
	var obstacles:=[box(Vector3(0,14,0),Vector3(6,3,1)),box(Vector3(-3,14,2),Vector3(1,3,5)),box(Vector3(3,14,2),Vector3(1,3,5))]
	w.recv_enemy(21001,"Raider",Vector3(0,12.55,3),100);var e:Dictionary=w.enemies[21001];var body:CharacterBody3D=e.node
	await physics_frame;await physics_frame
	var goal:=Vector3(0,12.54,-7)
	var route:=FortNavigation.path(w,body,goal)
	check(not route.is_empty(),"bounded route escapes a U-shaped obstacle instead of repeatedly steering into its corners")
	await walk(body,e,goal,900);print("U_ROUTE_END ",body.position)
	check(body.position.distance_to(goal)<1,"real enemy-sized physics body follows the detour around the U")
	var before:=w.navigation_revision;w.recv_defense(21002,"MetalWall",Vector3(10,12.5,0),0,850,false)
	check(w.navigation_revision>before,"new defense invalidates cached routes")
	before=w.navigation_revision;w.recv_remove_defense(21002,true);check(w.navigation_revision>before,"removed defense invalidates cached routes")
	for obstacle in obstacles:obstacle.queue_free()
	await physics_frame;await physics_frame
	var gap:=[box(Vector3(-.65,14,0),Vector3(.7,3,2)),box(Vector3(.65,14,0),Vector3(.7,3,2))]
	await physics_frame;await physics_frame
	check(not FortNavigation.clear(w,Vector3(0,12.5,-3),Vector3(0,12.5,3),FortNavigation.width(body)),"body-width check rejects a gap that a center ray would incorrectly accept")
	for obstacle in gap:obstacle.queue_free()
	var ledge:=box(Vector3(2,12.625,0),Vector3(2,.25,4));var ceiling:=box(Vector3(2,14.6,0),Vector3(4,1,4))
	p.position=Vector3(0,12.55,0);p.velocity=Vector3.ZERO
	for i in 15:await physics_frame;p._physics_process(1.0/60)
	Input.action_press("move_right")
	for i in 60:await physics_frame;p.look_yaw=0;p._physics_process(1.0/60)
	Input.action_release("move_right")
	check(p.position.x<1 and p.position.y<12.7,"step assist will not force a dwarf into a low ceiling")
	ledge.queue_free();ceiling.queue_free();platform.queue_free();w.recv_enemy_dead(21001);await physics_frame;await physics_frame
	w.pets._create(1,0,Vector3(100,-8,100));var pet:Dictionary=w.pets.pets[1];pet.resource="rest";pet.mode="RETURN";pet.cargo=3;pet.cargo_kind="stone";pet.stuck=6
	var blocker:=box(Vector3(4.6,1.3,2),Vector3(2,2,2));await physics_frame;await physics_frame
	w.clock+=1;w.pets.tick(1.0/60)
	check(pet.node.position.y>0 and pet.cargo==3,"pet recall preserves cargo and returns above ground")
	var landing:=FortNavigation.floor_point(w,pet.node.position,pet.node)
	check(landing.is_finite() and pet.node.position.distance_to(blocker.position)>1.5,"pet recall avoids an occupied old home landing")
	p.position=Vector3(0,-6,0);p.velocity=Vector3.ZERO;p.health=37;p.invulnerable=0;p._physics_process(1.0/60)
	check(p.position.y>0 and not FortRecovery.occupied(w,p,p.position) and p.health==37,"fall-through recovery uses checked authoritative ground and preserves health")
	var saved:=p.position;w.request_action("unstuck_fall");check(p.position==saved,"fall recovery cannot be requested while standing safely")
	blocker.queue_free()
	w.set_hearth_level(3);w.scenery_keepouts.clear();w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	for option in w.castle.candidates("0:0:0"):
		p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",option,"Stairs" if option.x==1 else "Courtyard",w.castle.revision);complete(option.key)
	p.position=w.castle.rooms["1:0:0"].sign;w.castle.plan(1,"1:0:0",{"x":1,"z":0,"floor":1},"Courtyard",w.castle.revision);complete("1:0:1")
	w.recv_enemy(21003,"Raider",Vector3(26,.7,-6),100);e=w.enemies[21003];body=e.node;await physics_frame;await physics_frame
	await walk(body,e,Vector3(24,4.65,8),600);print("STAIR_ASCENT_END ",body.position)
	check(body.position.y>4.4 and body.position.z>7,"enemy-sized body routes through actual stair lane to an upper target")
	await walk(body,e,Vector3(24,.65,-8),600);print("STAIR_DESCENT_END ",body.position)
	check(body.position.y<.9 and body.position.z< -7,"enemy-sized body descends through the staircase without cutting through its floor")
	p.position=Vector3(24,4.65,8);body.position=Vector3(24,.65,8);body.velocity=Vector3.ZERO;e.nav_points=[];e.nav_until=0.0;e.route_until=0.0
	for i in 1200:
		await physics_frame;w.clock+=1.0/60;w._simulate_enemies(1.0/60)
		if body.position.y>4.4:break
	print("UPSTAIRS_PURSUIT_END ",body.position)
	check(body.position.y>4.4,"live raid AI retains its upstairs target long enough to reach the staircase")
	main.queue_free();await create_timer(.1).timeout;print("NAVIGATION21_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
func complete(key:String)->void:
	var p:=w.local_player();p.position=w.castle.rooms[key].sign;w.castle.fund(1,key,true,w.castle.revision)
	for i in 100:
		if w.castle.rooms[key].task=="":break
		w.clock+=.7;w.castle.work(1,key)
