extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,text:String)->void:
	print(("PASS " if ok else "FAIL ")+text)
	if not ok:failures+=1
func capture(key:String)->void:
	if DisplayServer.get_name()=="headless":return
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/cast13_"+key+".png"))
func run()->void:
	var gallery:=Node3D.new();root.add_child(gallery)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("#26323d");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("#b1c2cf");env.environment.ambient_light_energy=.65;gallery.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-30,0);sun.light_energy=.9;gallery.add_child(sun)
	var camera:=Camera3D.new();gallery.add_child(camera);camera.position=Vector3(1.5,2.6,8.3);camera.look_at(Vector3(0,.9,0));camera.fov=43;camera.current=true
	var models:Array=[];var skeletons:Array=[];var animators:Array=[];var meshes:Array=[]
	for role in 4:
		var model:=FortArt.asset(["dwarf_vanguard","dwarf_warden","dwarf_engineer","dwarf_ranger"][role]);gallery.add_child(model);model.position.x=(role-1.5)*1.8;models.append(model)
		var equipment:=FortEquipment.prepare(model);FortArt.tint_dwarf(model,role);skeletons.append(equipment.skeleton);meshes.append(equipment.axe.mesh.get_instance_id())
		var anim:=FortPlayer.find_animation(model);animators.append(anim)
		for clip in ["Idle","Walk","Axe_Swing"]:check(anim.has_animation(clip),"hero %d preserves %s"%[role,clip])
		check(equipment.skeleton.find_bone("hand.R")>=0,"hero %d keeps weapon hand binding"%role)
		anim.play("Idle");anim.seek(.2,true);anim.pause()
	check(meshes[0]!=meshes[1] and meshes[2]!=meshes[3],"equipment mesh cache preserves distinct hero geometry")
	await capture("heroes")
	for anim in animators:anim.play("Axe_Swing");anim.seek(.3,true);anim.pause()
	await capture("heroes_attack")
	for model in models:model.hide()
	var enemies:=["raider","brute","sapper","ashwing","emberrunner","chieftain","sapper7","cinderlobber","bombwing","shieldguard","hexer","colossus","prowler","razorback","direwolf","stonebear","emberdrake","frostwyrm"]
	for start in range(0,enemies.size(),3):
		var group:Array=[]
		for i in range(start,mini(start+3,enemies.size())):
			var model:=FortArt.asset(enemies[i]);gallery.add_child(model);group.append(model);model.position.x=(i-start-1)*3.1
			var anim:=FortPlayer.find_animation(model)
			for clip in ["Idle","Walk","Attack","Hit","Death"]:check(anim!=null and anim.has_animation(clip),enemies[i]+" preserves "+clip)
			if anim and anim.has_animation("Idle"):anim.play("Idle")
		camera.position=Vector3(2.0,3.3,12 if start<15 else 20);camera.look_at(Vector3(0,1.2,0));await capture("enemies_%d"%start)
		for model in group:model.free()
	gallery.free();print("CAST13_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
