extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world
	w.set_hearth_level(3);w.wave=10;w.is_night=true;w.phase_time=75;w.fort_health=100000
	for i in 3:w.recv_player(50+i,{"name":"Stress Dwarf","class":i+1})
	for p in w.players.values():p.invulnerable=100
	for i in 100:w._spawn_enemy()
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(0,32,58);camera.look_at(Vector3.ZERO);camera.current=true
	var max_ms:=0.0;var start:=Time.get_ticks_msec();var frames:=0
	while Time.get_ticks_msec()-start<5000:
		var before:=Time.get_ticks_usec();await process_frame
		max_ms=maxf(max_ms,(Time.get_ticks_usec()-before)/1000.0);frames+=1
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/fort4_swarm.png"))
	var valid:bool=w.enemies.size()==100 and w.raid_cap()==100
	print("SWARM_RESULT ","PASS" if valid else "FAIL"," active=",w.enemies.size()," average_fps=",frames/5.0," worst_frame_ms=",max_ms)
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await process_frame;quit(0 if valid else 1)
