extends SceneTree
# Renders the locally sculpted pets and pony in-engine, plus walking / sprinting / riding dwarves.
func _initialize()->void:run.call_deferred()
func capture(name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/pets26_"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24867;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.hud.visible=false
	var base:=Vector3(0,.6,5.5)
	var keys:=["pet_badger","pet_mole","pet_sprite","horse"]
	for i in keys.size():
		var model:=FortArt.asset(keys[i]);w.add_child(model);model.position=base+Vector3(-3.2+i*2.0,0,0);model.rotation.y=.5
		FortArt.animate_enemy(model,0,false,i%2==1) if i<3 else FortArt.animate_mount(model,0,0,false)
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=30;camera.position=base+Vector3(0,2.0,7.5);camera.look_at(base+Vector3(0,.6,0));camera.current=true
	p.position=Vector3(30,.1,30)
	await create_timer(.6).timeout;await capture("lineup")
	# walking and sprinting strips, seen from the side while the dwarf really moves
	p.position=Vector3(-20,0.05,24);p.look_yaw=-PI/2;p.look_pitch=0
	camera.fov=26
	for mode in ["walk","sprint","ride"]:
		if mode=="sprint":Input.action_press("sprint")
		if mode=="ride":Input.action_release("sprint");p.set_travel_mode(1)
		Input.action_press("move_forward")
		await create_timer(.7).timeout
		for i in 4:
			camera.position=p.position+Vector3(0,1.3,7.0);camera.look_at(p.position+Vector3(0,.8,0))
			await capture("%s_%d"%[mode,i])
			await create_timer(.11).timeout
		Input.action_release("move_forward")
		await create_timer(.3).timeout
	camera.position=p.position+Vector3(2.5,1.6,4.5);camera.look_at(p.position+Vector3(0,.9,0))
	await create_timer(.6).timeout;await capture("ride_idle")
	main.queue_free();await process_frame;print("PETS26_REVIEW_CAPTURED");quit()
