extends SceneTree
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/gate24_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24769;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.castle.finish_walls(w.castle.rooms["0:0:0"])
	w._spawn_defense("Gatehouse",Vector3(0,.6,9.5),0,false)
	var gate:Dictionary=w.defenses[w.next_defense_id-1]
	gate.gate_open=0.0;gate.gate_target=0.0;FortGates.pose(gate)
	p.position=Vector3(0,.6,13)
	p.camera.reparent(w);p.camera.position=Vector3(15,10,27);p.camera.look_at(Vector3(0,2,7));p.camera.current=true
	w._update_lighting(10);w.gates.tick(0)
	await capture("curtain_day")
	w.is_night=true;w.wave=3;w.phase_time=w.night_length(3)*.5;w._update_lighting(10);w.gates.tick(0)
	await capture("curtain_night")
	gate.gate_open=1.0;gate.gate_target=1.0;w.gates.tick(0)
	p.camera.position=Vector3(7,5,20);p.camera.look_at(Vector3(0,2.5,9.5))
	await capture("lanterns_night")
	main.queue_free();await create_timer(.2).timeout;print("GATE24_REVIEW_PASS");quit()
