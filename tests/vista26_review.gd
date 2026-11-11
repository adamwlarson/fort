extends SceneTree
# Renders Fort 26 environment views: day, dusk and night from the keep and from a knoll.
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/vista26_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24863;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false);w.hud.visible=false
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=62;camera.far=2500;camera.current=true
	camera.position=Vector3(6,5.5,16);camera.look_at(Vector3(-30,2,-40))
	w.phase_time=w.day_length()*.5
	for i in 40:w._update_lighting(.2)
	await capture("day_keep")
	var hill:=Vector3.ZERO
	for i in 360:
		var at:=FortGround.on(Vector3(sin(i*.7),0,cos(i*.7))*(80.0+(i%40)*3.0))
		if at.y>hill.y:hill=at
	camera.position=hill+Vector3(22,6,22);camera.look_at(hill)
	await capture("day_knoll")
	camera.position=Vector3(0,34,60);camera.look_at(Vector3(0,0,-20))
	await capture("day_overview")
	w.phase_time=w.day_length()*.03
	for i in 40:w._update_lighting(.2)
	camera.position=Vector3(6,5.5,16);camera.look_at(Vector3(-30,3,-40))
	await capture("dusk_keep")
	w.is_night=true;w.phase_time=40
	for i in 60:w._update_lighting(.2)
	await capture("night_keep")
	main.queue_free();await process_frame;print("VISTA26_REVIEW_CAPTURED");quit()
