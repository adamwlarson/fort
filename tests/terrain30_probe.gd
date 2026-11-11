extends SceneTree
# Frame-time probe for the terrain: the opening view, then the opened frontier with a
# hundred raiders. Run windowed (not --headless) so the renderer is measured.
func _initialize()->void:run.call_deferred()
func measure(label:String,seconds:float)->void:
	await create_timer(1.0).timeout
	var start:=Time.get_ticks_msec();var frames:=0;var process_time:=0.0;var physics_time:=0.0;var worst:=0.0
	var last:=Time.get_ticks_usec()
	while Time.get_ticks_msec()-start<seconds*1000.0:
		await process_frame;frames+=1
		var now:=Time.get_ticks_usec();worst=maxf(worst,(now-last)/1000.0);last=now
		process_time+=Performance.get_monitor(Performance.TIME_PROCESS);physics_time+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	print("TERRAIN30_PERF ",label," fps=",snappedf(frames/seconds,.1)," worst_ms=",snappedf(worst,.1)," process_ms=",snappedf(process_time/frames*1000,.01)," physics_ms=",snappedf(physics_time/frames*1000,.01)," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," tris=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
func run()->void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	# Also runs on builds from before the terrain, for comparison.
	var ground=load("res://scripts/fort_ground.gd") if ResourceLoader.exists("res://scripts/fort_ground.gd") else null
	if ground:ground.home_override=38.0
	var started:=Time.get_ticks_msec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24873;main._host();main._start_match()
	var w:FortWorld=main.world
	print("TERRAIN30_PERF world_ready_ms=",Time.get_ticks_msec()-started)
	w.expedition.configure(1919);w.fort_health=100000
	var p:=w.local_player();p.invulnerable=1000
	await measure("hearth1_keep",4)
	p.position=Vector3(40,6,44);p.look_yaw=PI*.25
	await measure("hearth1_meadow",4)
	started=Time.get_ticks_msec()
	w.set_hearth_level(3)
	print("TERRAIN30_PERF hearth3_open_ms=",Time.get_ticks_msec()-started)
	p.position=Vector3(0,3,6)
	await measure("hearth3_keep",4)
	p.position=Vector3(120,30,-120)
	await measure("hearth3_frontier",4)
	p.position=Vector3(0,3,6)
	w.wave=10;w.is_night=true;w.phase_time=200
	seed(1919)
	for i in 100:w._spawn_enemy()
	await measure("hearth3_raid100",6)
	main.queue_free();await create_timer(.3).timeout;quit()
