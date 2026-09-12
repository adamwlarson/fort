extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var dwarf:Node3D=load("res://assets/models/dwarf.glb").instantiate()
	root.add_child(dwarf)
	var skeleton:Skeleton3D=dwarf.find_children("*","Skeleton3D",true,false)[0]
	print("SKELETON ",skeleton.get_path()," hand ",skeleton.find_bone("hand.R")," rest ",skeleton.get_bone_global_rest(skeleton.find_bone("hand.R")))
	for node in dwarf.find_children("*","MeshInstance3D",true,false):
		print("MESH ",node.name," skin ",node.skin.get_bind_count())
		for i in node.skin.get_bind_count():print("BIND ",i," ",node.skin.get_bind_name(i)," ",node.skin.get_bind_bone(i))
	var anim:=FortPlayer.find_animation(dwarf)
	print("SWING LENGTH ",anim.get_animation("Axe_Swing").length)
	anim.play("Axe_Swing")
	for t in [0.0,0.15,0.3,0.45,0.6,0.75,0.9,1.05,1.2]:
		anim.seek(t,true);anim.advance(0)
		print("HEAD ",t," ",skeleton.get_bone_global_pose(skeleton.find_bone("hand.R"))*Vector3(0,0.43,0))
	dwarf.free();quit()
