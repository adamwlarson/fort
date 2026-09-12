extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24799;main._host();main._start_match()
	var w:FortWorld=main.world;w.expedition.configure(1919);w.set_hearth_level(3);w.wave=10;w.is_night=true;w.phase_time=200;w.fort_health=100000
	for i in 3:w.recv_player(50+i,{"name":"Stress Dwarf","class":i+1})
	for p in w.players.values():p.invulnerable=100
	seed(1919)
	for i in 100:w._spawn_enemy()
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(0,32,58);camera.look_at(Vector3.ZERO);camera.current=true
	var solids:=w.find_children("SolidGeometry","StaticBody3D",true,false)
	var triangles:=0
	for body in solids:
		var shape:Shape3D=body.get_child(0).shape
		if shape is ConcavePolygonShape3D:triangles+=shape.get_faces().size()/3
	print("SOLID_PROFILE bodies=",solids.size()," triangles=",triangles)
	for enabled in [true,false,true]:
		for body in solids:
			if is_instance_valid(body):body.collision_layer=1 if enabled else 0
		await create_timer(1).timeout
		var start:=Time.get_ticks_msec();var frames:=0;var process_time:=0.0;var physics_time:=0.0
		while Time.get_ticks_msec()-start<5000:
			await process_frame;frames+=1
			process_time+=Performance.get_monitor(Performance.TIME_PROCESS);physics_time+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		print("SOLID_PERF enabled=",enabled," fps=",frames/5.0," process_ms=",process_time/frames*1000," physics_ms=",physics_time/frames*1000)
	main.queue_free();await create_timer(.3).timeout;quit()
