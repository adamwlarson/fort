extends SceneTree
# Renders Fort 30 terrain views to build/terrain30_*.png: the keep, the first ring, the
# opened frontier, a wilderness site on its shelf, the far ranges, dusk and night.
var w:FortWorld
var camera:Camera3D
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/terrain30_"+name+".png"))
## Stand the camera `up` metres above the ground at a map position and look at another.
func view(from:Vector2,up:float,to:Vector2,to_up:=1.5)->void:
	camera.position=Vector3(from.x,FortGround.height(from.x,from.y)+up,from.y)
	camera.look_at(Vector3(to.x,FortGround.height(to.x,to.y)+to_up,to.y))
func run()->void:
	FortGround.home_override=FortGround.HOME
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24871;main._host();main._start_match()
	w=main.world;var p:=w.local_player();p.set_physics_process(false);w.hud.visible=false
	camera=Camera3D.new();w.add_child(camera);camera.fov=62;camera.far=3000;camera.current=true
	w.phase_time=w.day_length()*.5
	for i in 40:w._update_lighting(.2)
	var start:=Time.get_ticks_msec()
	view(Vector2(6,16),4.9,Vector2(-30,-40));await capture("keep")
	view(Vector2(26,62),2.2,Vector2(-10,-10));await capture("ring1_walk")
	view(Vector2(-60,58),14,Vector2(0,0));await capture("ring1_over")
	w.set_hearth_level(3)
	print("TERRAIN30 hearth 3 opened in ",Time.get_ticks_msec()-start," ms")
	view(Vector2(70,-95),2.4,Vector2(150,-160));await capture("ring2_walk")
	view(Vector2(-150,150),30,Vector2(0,0));await capture("ring3_over")
	# The broadest water in the opened frontier, seen from its shore and from above.
	var lake:=Vector2.ZERO;var widest:=0
	for i in 1400:
		var at:=Vector2(sin(i*.61),cos(i*.61))*(80.0+(i%70)*2.2);var count:=0
		for step in 12:
			if FortGround.wet(at.x+sin(step*TAU/12.0)*9.0,at.y+cos(step*TAU/12.0)*9.0):count+=1
		if FortGround.wet(at.x,at.y) and count>widest:widest=count;lake=at
	var bank:=lake
	for step in 60:
		bank=lake+Vector2(sin(step*.7),cos(step*.7))*(12.0+step*.6)
		if FortGround.height(bank.x,bank.y)>FortGround.WATER+.8:break
	print("TERRAIN30 lake at ",lake)
	view(bank,2.0,lake,-3.0);await capture("lake_shore")
	view(lake+Vector2(30,34),18,lake,0);await capture("lake_over")
	var spec:Dictionary=FortEncounters.layout(w.expedition.seed_value)[5]
	view(Vector2(spec.pos.x+26,spec.pos.z+22),7,Vector2(spec.pos.x,spec.pos.z));await capture("site")
	var quarry:=Vector2(120,7)
	view(quarry+Vector2(-52,-46),16,quarry,2);await capture("quarry")
	view(Vector2(0,-120),3,Vector2(0,-700),60);await capture("peaks")
	view(Vector2(0,0),190,Vector2(260,260),0);await capture("high")
	print("TERRAIN30 frame ms ",Performance.get_monitor(Performance.TIME_PROCESS)*1000.0," draw calls ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives ",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	w.phase_time=w.day_length()*.03
	for i in 40:w._update_lighting(.2)
	view(Vector2(34,70),3,Vector2(-40,-120),12);await capture("dusk")
	w.is_night=true;w.phase_time=40
	for i in 60:w._update_lighting(.2)
	await capture("night")
	# The map with the land painted on it: region view, then the whole explored world.
	w.is_night=false;w.phase_time=w.day_length()*.5
	for i in 40:w._update_lighting(.2)
	w.hud.visible=true;camera.current=false;p.position=FortGround.on(Vector3(60,0,-70),.2)
	for mode in [2,3]:
		w.hud.map.set_mode(mode)
		await create_timer(1.2).timeout
		await capture("map_%d"%mode)
	FortGround.home_override=-1.0
	main.queue_free();await process_frame;print("TERRAIN30_REVIEW_CAPTURED");quit()
