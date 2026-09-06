extends SceneTree

func _initialize() -> void: run.call_deferred()
func capture(key: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))

func run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main._host()
	main._start_match()
	var w: FortWorld = main.world
	w.hud.hide()
	var camera := Camera3D.new()
	w.add_child(camera)
	camera.position = Vector3(3,2.8,4.2)
	camera.look_at(Vector3(0,1,0))
	camera.current = true
	await create_timer(2).timeout
	await capture("campfire_day")
	w.is_night = true
	await create_timer(3).timeout
	await capture("campfire_night")
	await create_timer(0.3).timeout
	await capture("campfire_motion")
	w.is_night = false
	var tree_pos: Vector3 = w.resource_nodes[0].node.position
	camera.position = tree_pos+Vector3(4,3,6)
	camera.look_at(tree_pos+Vector3(0,1.7,0))
	await create_timer(3).timeout
	w.resource_nodes[0].respawn = 500
	w.recv_resource(0,0,true)
	await create_timer(0.18).timeout
	await capture("tree_chips")
	await create_timer(0.5).timeout
	await capture("tree_leaves")
	await create_timer(1.4).timeout
	await capture("tree_settling")
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	main.queue_free()
	await create_timer(0.1).timeout
	quit()
