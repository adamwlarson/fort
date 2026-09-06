extends SceneTree

var failures: Array[String]=[]
var main: Node
var world: FortWorld
var player: FortPlayer

func _initialize()->void:
	run.call_deferred()

func check(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
		push_error("FAIL: "+message)
	else:print("PASS: "+message)

func wait(seconds:float)->void:
	await create_timer(seconds).timeout

func action(name:String)->void:
	var event:=InputEventAction.new()
	event.action=name;event.pressed=true
	Input.parse_input_event(event)

func run()->void:
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await wait(0.1)
	main._host()
	main._start_match()
	await wait(0.25)
	world=main.world
	player=world.local_player()
	check(player!=null,"actual Host flow spawns the local dwarf")
	check(player.animation_player!=null,"imported dwarf has an AnimationPlayer")
	check(player.animation_player.has_animation("Axe_Swing"),"axe clip is present")
	check(player.animation_player.get_animation("Walk").loop_mode==Animation.LOOP_LINEAR,"walk clip loops")

	action("build_mode")
	await wait(0.1)
	check(world.local_build_mode and is_instance_valid(world.preview),"B input reaches world and creates placement preview")
	action("build_mode")
	await wait(0.1)
	check(not world.local_build_mode,"B closes building")
	action("cancel")
	await wait(0.1)
	check(world.menu_open,"Escape opens usable menu")
	var old:=player.position
	Input.action_press("move_forward")
	await wait(0.15)
	Input.action_release("move_forward")
	check(player.position.distance_to(old)<0.1,"menu stops movement input")
	action("cancel")
	await wait(0.1)

	# Move to an actual resource, then hold the same action used by a player.
	var rid:=int(world.resource_nodes.keys()[0])
	player.position=world.resource_nodes[rid].node.position+Vector3(1.5,0.1,0)
	player.velocity=Vector3.ZERO
	await wait(0.1)
	action("interact")
	await wait(0.12)
	check(world.focused_resource==rid and world.focus_ring.visible,"nearby resource has a visible targeting ring")
	var gather_direction:Vector3=(world.resource_nodes[rid].node.position-player.position).normalized()
	var visual_direction:=Vector3(sin(player.visual_root.rotation.y),0,cos(player.visual_root.rotation.y))
	check(visual_direction.dot(gather_direction)>0.95,"gathering turns the dwarf toward the resource")
	check(player.total_carried()>0,"E input gathers into personal pack")
	check(player.action_time>0 and player.animation_player.current_animation=="Axe_Swing","gather action plays the axe clip")
	check(world.resource_nodes[rid].animation.current_animation=="Hit","tree hit animation is connected")
	Input.action_press("move_right")
	await wait(0.15)
	check(player.animation_player.current_animation=="Axe_Swing","locomotion does not interrupt an action")
	Input.action_release("move_right")
	Input.action_release("interact")
	await wait(0.85)
	check(player.animation_player.current_animation=="Idle","completed action returns to idle")

	player.position=Vector3(4.6,0.05,2.1)
	player.velocity=Vector3.ZERO
	var stock_before:int=world.shared.wood
	action("interact")
	await wait(0.15)
	Input.action_release("interact")
	check(player.total_carried()==0 and world.shared.wood>stock_before,"E deposits into shared stock")
	await wait(0.7)

	# Combat requires an input, a visible swing, and its impact delay.
	player.position=Vector3(0,0.1,15)
	player.look_yaw=0
	player.velocity=Vector3.ZERO
	world.recv_enemy(999,"Raider",Vector3(0,0,13),100)
	world.enemies[999].stun=10
	action("attack")
	await wait(0.10)
	check(world.enemies[999].hp==100,"melee damage waits for the swing impact")
	check(player.animation_player.current_animation=="Axe_Swing","click input plays combat animation")
	Input.action_release("attack")
	await wait(0.25)
	check(world.enemies[999].hp<100,"swing damages target in front")
	var hp:float=world.enemies[999].hp
	world.server_action(1,"attack",{"direction":Vector3.FORWARD})
	await wait(0.1)
	check(world.enemies[999].hp==hp,"server rejects attacks faster than cooldown")
	await wait(0.55)

	world.shared={"wood":150,"stone":100,"crystal":25}
	player.position=Vector3(0,0.05,16)
	world.server_action(1,"build",{"kind":"Ballista","pos":Vector3(0,0,12),"rotation":0.0})
	check(world.defenses.size()==1,"valid build spends resources and creates usable defense")
	var bid:=int(world.defenses.keys()[0])
	player.position=Vector3(0,0.05,13.3)
	for i in 10:
		world.clock+=.8;world.server_action(1,"work_defense",{"id":bid})
	check(not FortConstruction.pending(world.defenses[bid]),"held construction work completes the ballista before use")
	await wait(0.75)
	action("interact")
	await wait(0.1)
	Input.action_release("interact")
	check(player.mounted_ballista==bid,"E mounts a nearby ballista")
	await wait(0.7)
	action("interact")
	await wait(0.1)
	Input.action_release("interact")
	check(player.mounted_ballista==-1,"E dismounts without gathering instead")
	var count:int=world.defenses.size()
	await wait(0.6)
	world.server_action(1,"build",{"kind":"Barricade","pos":Vector3.ZERO,"rotation":0.0})
	check(world.defenses.size()==count,"placement rejects the hearth footprint")

	# Death disables play, teammates can revive, and rescue moves the owner too.
	world._set_health(1,0)
	await wait(0.1)
	check(player.health==0 and player.down_time>0,"damage downs the player")
	var down_pos:=player.position
	Input.action_press("move_forward")
	await wait(0.2)
	Input.action_release("move_forward")
	check(player.position.distance_to(down_pos)<0.2,"downed dwarf cannot keep walking")
	world._respawn(1)
	await wait(0.1)
	check(player.health>0 and player.position.length()<8,"rescue restores health and owner position")
	player.carrying.crystal=20
	world._deposit(1)
	check(world.workshop_level==3,"deposited crystal unlocks shared traversal")
	world.server_action(1,"travel",{"mode":2})
	await wait(0.1)
	check(player.travel_mode==2 and is_instance_valid(player.mount_visual),"jetpack has a real attached visual")
	var visual_count:=player.gear_root.get_child_count()
	for i in 40:player.set_travel_mode(2)
	check(player.gear_root.get_child_count()==visual_count,"repeated snapshots do not duplicate travel visuals")
	var y:=player.position.y
	Input.action_press("jump")
	await wait(0.5)
	Input.action_release("jump")
	check(player.position.y>y+0.5 and player.fuel<4,"jetpack thrust consumes fuel and lifts dwarf")
	world._advance_phase()
	check(world.is_night and world.wave==1,"day transitions to night")
	world._advance_phase()
	check(not world.is_night and world.enemies.is_empty(),"dawn clears the swarm")
	print("GAMEPLAY_TEST_RESULT: ", "PASS" if failures.is_empty() else "FAIL", " failures=",failures)
	main.queue_free()
	await wait(0.1)
	quit(0 if failures.is_empty() else 1)
