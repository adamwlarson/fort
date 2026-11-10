extends SceneTree
# Renders every Fort 26 enemy in-engine: idle line-up, walk, attack and death frames.
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.1).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/enemies26_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24862;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.hud.visible=false
	p.position=Vector3(0,.6,-7)
	var rows:=[["Raider","EmberRunner","Sapper","FireArcher","Shieldguard","Prowler","Hexer","Cinderlobber","Brute"],["Ashwing","Bombwing","Razorback","Direwolf","Stonebear","Chieftain"],["Emberdrake","Colossus","Frostwyrm"]]
	var id:=5000
	var base:=Vector3(60,0,60)
	for r in rows.size():
		for i in rows[r].size():
			var spacing:float=[2.3,3.6,8.5][r]
			var pos:=base+Vector3((i-(rows[r].size()-1)*.5)*spacing,1.6 if rows[r][i] in ["Ashwing","Bombwing"] else 0.0,-r*5.5-(3.0 if r==2 else 0.0))
			w.recv_enemy(id,rows[r][i],pos,100);w.enemies[id].node.set_physics_process(false);w.enemies[id].label.visible=false;id+=1
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=40;camera.position=base+Vector3(0,7.5,17);camera.look_at(base+Vector3(0,1.6,-5));camera.current=true
	for mode in ["idle","walk","attack"]:
		for e in w.enemies.values():FortArt.animate_enemy(e.visual,0,mode=="attack",mode=="walk")
		await create_timer(.42).timeout
		await capture(mode)
	camera.fov=30;camera.position=base+Vector3(0,3.2,9.5);camera.look_at(base+Vector3(0,.9,0))
	for e in w.enemies.values():FortArt.animate_enemy(e.visual,0,false,false)
	await create_timer(.5).timeout
	await capture("front_row")
	for key in w.enemies.keys():w.recv_enemy_dead(key)
	await create_timer(.7).timeout
	await capture("death")
	main.queue_free();await process_frame;print("ENEMIES26_REVIEW_CAPTURED");quit()
