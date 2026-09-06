extends SceneTree

func _initialize()->void:run.call_deferred()

func capture(key:String)->void:
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))

func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await capture("title")
	main._host()
	main._start_match()
	await create_timer(1.0).timeout
	var w:FortWorld=main.world
	var p:FortPlayer=w.local_player()
	w.toast_time=0
	await capture("day")
	var gather_resource:Dictionary=w.resource_nodes[0]
	p.position=gather_resource.node.position+Vector3(0,0.1,2.2)
	p.velocity=Vector3.ZERO
	await capture("gather_focus")
	# A staged visual review, not a simulation/balance test.
	w._spawn_defense("Watchtower",Vector3(5,0,-6),0,false)
	w._spawn_defense("Ballista",Vector3(0,0,-6),0,false)
	w._spawn_defense("Barricade",Vector3(-5,0,-8),0,false)
	w._spawn_defense("Mender",Vector3(2,0,-3),0,false)
	w.wave=2;w.is_night=true;w.phase_time=70
	p.position=Vector3(0,0.1,3)
	await create_timer(3).timeout
	for i in 3:
		w.recv_enemy(500+i,["Raider","Brute","Sapper"][i],Vector3(-3+i*3,0,-3),300)
		w.enemies[500+i].stun=10
	await capture("night")
	w.is_night=false
	w.hud.hide()
	for resource in w.resource_nodes.values():resource.node.hide()
	for id in w.enemies.keys():w.recv_enemy_dead(int(id))
	for i in 3:
		w.recv_player(100+i,{"name":["Warden","Engineer","Scout"][i],"class":i+1})
		var ally:FortPlayer=w.players[100+i]
		ally.position=Vector3(-1+i*2.2,0.1,17)
		ally.target_position=ally.position
		ally.target_yaw=0
	p.position=Vector3(-3.7,0.1,17)
	p.visual_root.rotation.y=0
	p.set_travel_mode(1)
	var camera:=Camera3D.new()
	w.add_child(camera)
	camera.position=Vector3(0,3,24)
	camera.look_at(Vector3(0,1.0,17))
	camera.current=true
	await create_timer(2).timeout
	await capture("crew")
	p.set_travel_mode(2)
	await capture("jetpack")
	for resource_node in w.resource_nodes.values():resource_node.node.visible=resource_node.amount>0
	p.set_travel_mode(0)
	w.hud.show()
	camera.current=false
	p.camera.current=true
	for i in FortLandscape.LANDMARKS.size():
		var landmark:Dictionary=FortLandscape.LANDMARKS[i]
		var start:Vector2=FortLandscape.TRAILS[i][1]
		var approach:Vector3=(landmark.pos-Vector3(start.x,0,start.y)).normalized()
		p.position=landmark.pos-approach*7+Vector3.UP*0.1
		p.velocity=Vector3.ZERO
		p.look_yaw=atan2(-approach.x,-approach.z)
		p.look_pitch=-0.30
		p.visual_root.rotation.y=atan2(approach.x,approach.z)
		await capture(["grove","quarry","ruins"][i])
	w.hud.hide()
	camera.position=Vector3(0,88,79)
	camera.look_at(Vector3(0,0,0))
	camera.current=true
	await capture("world_overview")
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free()
	await process_frame
	quit()
