extends SceneTree

func _initialize() -> void:
	for path in ["res://assets/models/dwarf.glb", "res://assets/models/tree.glb"]:
		var model = load(path).instantiate()
		root.add_child(model)
		print(path)
		inspect(model)
		model.queue_free()
	quit()

func inspect(node: Node) -> void:
	if node is AnimationPlayer:
		for clip in node.get_animation_list():
			var animation = node.get_animation(clip)
			print("CLIP ", clip, " length=", animation.length, " loop=", animation.loop_mode)
			if clip=="Idle":
				for track in mini(12,animation.get_track_count()):print("TRACK ",animation.track_get_path(track)," type=",animation.track_get_type(track)," first=",animation.track_get_key_value(track,0))
	if node is MeshInstance3D:
		print("MESH ", node.name, " bounds=", node.get_aabb(), " rotation=", node.rotation)
		for i in node.mesh.get_surface_count():
			var mat = node.mesh.surface_get_material(i)
			print("  MATERIAL ", mat.resource_name if mat else "none")
	for child in node.get_children(): inspect(child)
