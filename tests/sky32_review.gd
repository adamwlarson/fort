extends SceneTree
# Renders the Fort 32 sky to build/sky32_*.png: noon, dawn, dusk towards and away from the
# sun, and the night sky south (moon and Milky Way) and north (aurora).
var w:FortWorld
var camera:Camera3D
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.35).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/sky32_"+name+".png"))
func light(night:bool,t:float)->void:
	w.is_night=night;w.phase_time=(w.night_length(w.wave) if night else w.day_length())*(1.0-t)
	for i in 80:w._update_lighting(.2)
func look(yaw:float,pitch:float)->void:
	camera.rotation=Vector3(deg_to_rad(pitch),deg_to_rad(yaw),0)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24878;main._host();main._start_match()
	w=main.world;var p:=w.local_player();p.set_physics_process(false);w.hud.visible=false;w.set_process(false)
	camera=Camera3D.new();w.add_child(camera);camera.fov=70;camera.far=3000;camera.current=true;camera.position=Vector3(0,6,26)
	var sun_yaw:=func()->float:
		var forward:Vector3=-w.sun.global_basis.z
		return rad_to_deg(atan2(forward.x,forward.z))
	light(false,.5);look(sun_yaw.call(),22);await capture("noon")
	light(false,.04);look(sun_yaw.call(),10);await capture("dawn")
	light(false,.965);look(sun_yaw.call(),10);await capture("dusk_sun")
	look(sun_yaw.call()+180,14);await capture("dusk_away")
	look(sun_yaw.call()+70,38);await capture("dusk_clouds")
	light(true,.45);look(sun_yaw.call(),30);await capture("night_moon")
	look(0,30);await capture("night_north")
	look(120,58);await capture("night_zenith")
	main.queue_free();await process_frame;print("SKY32_REVIEW_CAPTURED");quit()
