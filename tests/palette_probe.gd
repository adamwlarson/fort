extends SceneTree
func _initialize()->void:
	var model:=FortArt.asset("ashwing")
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var mat:StandardMaterial3D=mesh.mesh.surface_get_material(0)
		var colors:PackedColorArray=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		print(mesh.name," srgb=",mat.vertex_color_is_srgb," use=",mat.vertex_color_use_as_albedo," base=",mat.albedo_color," color=",colors[0])
	model.free();quit()
