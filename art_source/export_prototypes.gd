extends SceneTree

func _initialize()->void:
	run.call_deferred()

func run()->void:
	FortArt.exporting = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/asset_stage"))
	var holder:=Node3D.new()
	root.add_child(holder)
	FortArt.make_fort(holder)
	save_asset(holder.get_child(0),"hearthhold")
	save_asset(holder.get_child(0).get_node("Stockpile").duplicate(),"stockpile")
	save_asset(holder.get_child(0).get_node("Workshop").duplicate(),"workshop")
	for kind in GameData.BUILD_ORDER:save_asset(FortArt.make_defense(kind,false),kind.to_lower())
	for kind in ["Raider","Brute","Sapper"]:save_asset(FortArt.make_enemy(kind),kind.to_lower())
	save_asset(FortArt.make_mount(1),"horse")
	save_asset(FortArt.make_mount(2),"jetpack")
	var ore:=Node3D.new()
	for i in 5:
		var rock:=Visuals.sphere(0.45+i*0.08,FortArt.STONE.lightened(i*0.04),Vector3(sin(i*2.4)*0.4,0.4,cos(i*2.4)*0.4))
		rock.scale.y=0.75
		ore.add_child(rock)
	save_asset(ore,"stone_deposit")
	var cluster:=Node3D.new()
	for i in 5:FortArt.crystal(cluster,Vector3(sin(i*2.4)*0.5,0,cos(i*2.4)*0.5),0.7+i*0.2)
	save_asset(cluster,"crystal_deposit")
	var lantern:=Node3D.new()
	FortArt.lantern(lantern,Vector3.ZERO,false)
	save_asset(lantern,"lantern")
	var bolt:=Node3D.new()
	bolt.add_child(Visuals.box(Vector3(0.04,0.04,1.3),FortArt.WOOD,Vector3.ZERO))
	var tip:=FortArt.cone(0.09,0.25,FortArt.STONE,Vector3(0,0,-0.75))
	tip.rotation.x=-PI/2
	bolt.add_child(tip)
	save_asset(bolt,"bolt")
	print("ASSET_STAGE_EXPORT_OK")
	quit()

func clean(node:Node)->void:
	for child in node.get_children():
		if child is CollisionObject3D or child is Label3D or child is Light3D:
			node.remove_child(child);child.free()
		else:clean(child)

func save_asset(node:Node3D,key:String)->void:
	if node.get_parent():node=node.duplicate()
	node.name=key
	node.position=Vector3.ZERO
	root.add_child(node)
	clean(node)
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	var error:=document.append_from_scene(node,state)
	if error!=OK:push_error("export scene "+key)
	error=document.write_to_filesystem(state,"res://.tools/asset_stage/"+key+".glb")
	if error!=OK:push_error("export file "+key)
	node.queue_free()
