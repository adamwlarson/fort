extends SceneTree
# Renders Fort 31 views to build/fort31_*.png: the three elites, a biome material deposit,
# and the hearth menu with its boons.
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/fort31_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24877;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
	w.phase_time=w.day_length()*.5
	for i in 40:w._update_lighting(.2)
	w.hud.visible=false
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=50;camera.current=true
	var kinds:=[["Raider",""],["Raider","Ironhide"],["Raider","Frenzied"],["Brute","Warbanner"]]
	for i in kinds.size():
		w.recv_enemy(9000+i,kinds[i][0],Vector3(18+i*2.6,0,20),100.0,-1,kinds[i][1]);w.enemies[9000+i].node.rotation.y=PI
	w.set_process(false)
	for e in w.enemies.values():e.label.text=FortElites.title(e)
	camera.position=Vector3(22,2.4,12.5);camera.look_at(Vector3(22,1.3,20))
	await capture("elites")
	w.set_process(true)
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w.set_hearth_level(5)
	var rare:=w.expedition.rare(1);var spot:=Vector3.ZERO
	for r in w.resource_nodes.values():
		if r.kind==rare:spot=r.node.position;break
	camera.position=spot+Vector3(4.5,2.6,4.5);camera.look_at(spot+Vector3.UP*.8)
	await capture("material")
	for kind in GameData.RARE:w.shared[kind]=30
	w.shared.aether=40;w.expedition.attune[rare]=1
	camera.current=false;w.hud.visible=true;p.position=Vector3(0,FortCastle.BASE,2.5)
	w.hud.hearth_menu.open_panel()
	await capture("hearth_menu")
	main.queue_free();await process_frame;print("FORT31_REVIEW_CAPTURED");quit()
