extends SceneTree
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.5).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/fort25_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24827;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	p.position=Vector3(0,.6,7)
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(15,12,18);camera.look_at(Vector3(0,1,0));camera.current=true
	await capture("hearth1_hud")
	w.set_hearth_level(4);await capture("hearth4_hud")
	w.set_hearth_level(8);await capture("hearth8_hud")
	w.toggle_pause();await capture("camp_menu");w.hud.controls.open_panel();await capture("controls");w.hud.controls.close_panel();w.toggle_pause()
	w.castle.rooms["1:0:0"]={"x":1,"z":0,"floor":0,"kind":"Sentry","complete":true,"funded":{},"work":0.0,"total":0.0,"sign":Vector3(13,.6,-7),"walls":[],"task":"sentry_cannons","resource":"wood","level":3}
	var room:Dictionary=w.castle.rooms["1:0:0"];FortCastleFeatures.finish(w.castle,room);room.task="";room.portals={0:"gate"};w.castle.finish_walls(room);w.castle.changed()
	camera.position=Vector3(38,15,22);camera.look_at(Vector3(20,2,0));await capture("sentry")
	p.position=room.sign;w.castle.menu.open_nearest();await capture("castle_menu")
	w.castle.menu.close_panel();room.kind="Merchant";w.castle.changed();p.position=FortMerchant.location(w.castle,"1:0:0")+Vector3(2,0,0);w.shared.gold=150;w.hud.merchant.open_panel("1:0:0");await capture("merchant")
	main.queue_free();await process_frame;print("FORT25_VISUAL_REVIEW_CAPTURED");quit()
