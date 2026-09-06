extends SceneTree

var failures:Array[String]=[]
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures.append(message)

func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await wait(0.1)
	main._host()
	main._start_match()
	await wait(0.25)
	var w:FortWorld=main.world
	var p:FortPlayer=w.local_player()
	check(w.resource_nodes.size()==90,"expanded resource population is deterministic")
	var layout_ok:=true
	for resource in w.resource_nodes.values():
		var pos:Vector3=resource.node.position
		if pos.length()>68.01 or pos.length()<13 or FortLandscape.trail_distance(pos)<2.99:layout_ok=false
	check(layout_ok,"resources keep the travel trails and camp clear")
	for landmark in FortLandscape.LANDMARKS:
		check(FortLandscape.region_name(landmark.pos)==landmark.name,landmark.name+" is discoverable")
		var nearby:=0
		for resource in w.resource_nodes.values():
			if resource.kind==landmark.kind and resource.node.position.distance_to(landmark.pos)<17:nearby+=1
		check(nearby>=8,landmark.name+" has its signature resource")
	for id in [1,2]:
		var resource:Dictionary=w.resource_nodes[id]
		check(resource.animation.has_animation("Hit") and resource.animation.has_animation("Destruction"),"new tree variant has harvest animations")
		w.recv_resource(id,0,true)
		check(resource.node.get_node("TreeTrunk").collision_layer==0,"felled tree immediately clears its collision")
		w.recv_resource(id,12,false)
		check(resource.node.get_node("TreeTrunk").collision_layer==1,"regrown tree restores its collision")
	# Walk each designed trail using normal player movement, not teleports along it.
	Engine.time_scale=3
	for trail in FortLandscape.TRAILS:
		var start:Vector2=trail[1]
		p.position=Vector3(start.x,0.1,start.y)
		p.velocity=Vector3.ZERO
		if trail.size()<3:continue
		var goal:Vector2=trail[2]
		var end:=Vector3(goal.x,0,goal.y)
		var elapsed:=0.0
		while Vector2(p.position.x,p.position.z).distance_to(goal)>1.0 and elapsed<12:
			var direction:Vector3=(end-p.position).normalized()
			p.look_yaw=atan2(-direction.x,-direction.z)
			Input.action_press("move_forward")
			await wait(0.1)
			elapsed+=0.1
		Input.action_release("move_forward")
		p.velocity=Vector3.ZERO
		check(Vector2(p.position.x,p.position.z).distance_to(goal)<1.5,"trail to "+FortLandscape.region_name(end)+" is walkable")
	# A tree-sized obstacle in an enemy's route must not trap that raider forever.
	p.position=Vector3(62,0.1,0)
	var obstruction:=Node3D.new()
	w.add_child(obstruction)
	FortArt.box_collider(obstruction,Vector3(0.65,2,0.65),Vector3(0,1,13))
	w.recv_enemy(777,"Raider",Vector3(0,0,17),200)
	await wait(9)
	check(w.enemies[777].node.position.z<10,"raider steers around a tree-sized obstruction")
	Engine.time_scale=1
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free()
	await wait(0.1)
	print("WORLD_TEST_", "OK" if failures.is_empty() else "FAILED",failures)
	quit(0 if failures.is_empty() else 1)
