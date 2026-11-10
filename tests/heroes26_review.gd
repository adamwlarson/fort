extends SceneTree
# Renders the Fort 26 dwarves in-engine: idle line-up plus weapon grips and action poses.
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await create_timer(.12).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/heroes26_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24861;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false)
	w.hud.visible=false
	for i in range(1,8):
		w.recv_player(100+i,{"name":"Hero %d"%i,"class":i})
	var index:=0
	for q in w.players.values():
		q.set_physics_process(false);q.position=Vector3((q.class_id%4-1.5)*1.7,.6,6.0+(2.2 if q.class_id>=4 else 0.0));q.target_position=q.position
		q.visual_root.rotation.y=0;q.target_yaw=0;q.nameplate.visible=false
		index+=1
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=38;camera.position=Vector3(0,2.6,15.5);camera.look_at(Vector3(0,1.0,7));camera.current=true
	await capture("lineup")
	camera.position=Vector3(-6.2,1.5,8.6);camera.look_at(Vector3(-1.2,.8,6.3));camera.fov=24
	await capture("side")
	camera.fov=27;camera.position=Vector3(0,2.3,15.5);camera.look_at(Vector3(0,.9,7))
	var shots:=[["Axe","attack",.22],["Axe","gather",.3],["Hammer","attack",.55],["Crossbow","",0.0],["Crossbow","attack",.1],["Pike","attack",.3],["Axe","construct",.2],["Axe","ability",.3]]
	for shot in shots:
		for q in w.players.values():
			q.owned_weapons=PackedStringArray(["Axe","Hammer","Crossbow","Pike"]);q.equip_weapon(shot[0]);q.action_time=0
			q.set_physics_process(true)
		await create_timer(.3).timeout
		if shot[1]!="":
			for q in w.players.values():q.play_action(shot[1])
			await create_timer(shot[2]).timeout
		for q in w.players.values():q.set_physics_process(false);q.animation_player.pause()
		await capture("%s_%s"%[shot[0],shot[1] if shot[1]!="" else "hold"])
		for q in w.players.values():q.animation_player.play()
	for q in w.players.values():q.set_physics_process(true);q.health=0
	await create_timer(1.2).timeout
	await capture("downed")
	main.queue_free();await process_frame;print("HEROES26_REVIEW_CAPTURED");quit()
