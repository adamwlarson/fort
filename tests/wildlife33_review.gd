extends SceneTree
# Renders Fort 33 views to build/wildlife33_*.png: the common and exotic animals in the
# meadow, a cooking pot with its menu, and a pile of dropped game.
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.45).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/wildlife33_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24880;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
	w.phase_time=w.day_length()*.6
	for i in 60:w._update_lighting(.2)
	w.hud.visible=false
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=42;camera.current=true
	p.position=Vector3(0,FortCastle.BASE,3)
	var rows:=[["Rabbit","Fox","Boar","Ram","Deer","Stag","Yak"],["Frosthare","Salamander","Tortoise","Sunhorn","Amberstag"]]
	var gaps:=[1.2,1.4,1.7,1.7,1.8,2.0,2.6]
	for r in 2:
		var x:float=-8.0 if r==0 else -6.0
		for i in rows[r].size():
			var kind:String=rows[r][i];var id:int=9000+r*20+i
			w.recv_enemy(id,kind,Vector3(x,0,22+r*40),float(FortWildlife.SPECIES[kind].hp),FortWildlife.CAMP)
			w.enemies[id].node.rotation.y=PI*.82
			x+=(gaps[i] if r==0 else 2.6)+float(FortWildlife.SPECIES[kind].radius)*2.0
	w.set_process(false)
	for e in w.enemies.values():e.label.text=FortWildlife.title(e)
	camera.position=Vector3(1.5,2.6,10.5);camera.look_at(Vector3(1.5,.7,22))
	await capture("common")
	camera.position=Vector3(1.0,2.8,49.5);camera.look_at(Vector3(1.0,.7,62))
	await capture("exotic")
	w.set_process(true)
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w._spawn_defense("CookingPot",Vector3(13,0,13),0,false)
	w.pieces.spawn_drop(Vector3(15.5,0,11.5),{"venison":2,"meat":3})
	camera.position=Vector3(16.5,2.2,16.5);camera.look_at(Vector3(13.4,.9,12.6))
	await capture("pot")
	w.shared=GameData.stock({"wood":40,"stone":20,"meat":6,"venison":4,"glowcap":2,"stew":2});p.health=90;p.buffs={"hearty":142.0,"fleet":66.0}
	camera.current=false;w.hud.visible=true;p.position=Vector3(14.5,0,13);p.look_yaw=PI*.5
	w.hud.cook.open_panel()
	await capture("menu")
	main.queue_free();await process_frame;print("WILDLIFE33_REVIEW_CAPTURED");quit()
