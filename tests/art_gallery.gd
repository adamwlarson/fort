extends SceneTree

func _initialize()->void:run.call_deferred()

func run()->void:
	var gallery:=Node3D.new()
	root.add_child(gallery)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("#202e36")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#b1c2cf")
	env.environment.ambient_light_energy=0.52
	gallery.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-30,0)
	sun.light_energy=0.9
	sun.light_color=Color("#ffdebb")
	sun.shadow_enabled=true
	gallery.add_child(sun)
	var camera:=Camera3D.new()
	gallery.add_child(camera)
	camera.position=Vector3(1.8,3.1,8.8)
	camera.look_at(Vector3(0,1.3,0))
	camera.fov=43
	camera.current=true
	var animations:Array[AnimationPlayer]=[]
	for i in 3:
		var model:=FortArt.asset(["raider","brute","sapper"][i])
		gallery.add_child(model)
		model.position.x=(i-1)*2.5
		var anim:=FortPlayer.find_animation(model)
		animations.append(anim)
		anim.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR
		anim.play("Idle")
		gallery.add_child(Visuals.cylinder(1.08,0.1,Color("#485453"),Vector3((i-1)*2.5,-0.04,0)))
		var label:=Visuals.label_3d(["RAIDER","BRUTE","SAPPER"][i],Color("#e6d3aa"),0)
		gallery.add_child(label)
		label.position=Vector3((i-1)*2.5,-0.15,1.0)
	await create_timer(0.6).timeout
	await capture("enemy_gallery")
	for anim in animations:
		anim.play("Attack")
		anim.seek(0.25,true)
		anim.pause()
	await capture("enemy_attack")
	camera.position=Vector3(-3.9,2.2,3.2)
	camera.look_at(Vector3(-2.5,1.35,0))
	for anim in animations:anim.play("Idle")
	await capture("raider_detail")
	for child in gallery.get_children():
		if child is Node3D and not child is Camera3D and not child is Light3D:child.hide()
	for key in ["workshop","stockpile"]:
		var camp:=FortArt.asset(key)
		gallery.add_child(camp)
		camp.position.x=-1.55 if key=="workshop" else 1.8
	camera.position=Vector3(4.3,4.4,7.3)
	camera.look_at(Vector3(0,1.35,0))
	await capture("camp_gallery")
	gallery.queue_free()
	await process_frame
	quit()

func capture(key:String)->void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
