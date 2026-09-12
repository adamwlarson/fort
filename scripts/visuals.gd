class_name Visuals
extends RefCounted

static func material(color:Color, roughness:=0.82, emission:=Color.BLACK) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 2.2
	return mat

static func mesh_node(mesh:Mesh, color:Color, position:=Vector3.ZERO, scale_value:=Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = position
	node.scale = scale_value
	return node

static func box(size:Vector3, color:Color, position:=Vector3.ZERO) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh_node(shape, color, position)

static func cylinder(radius:float, height:float, color:Color, position:=Vector3.ZERO) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 10
	return mesh_node(shape, color, position)

static func sphere(radius:float, color:Color, position:=Vector3.ZERO) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 10
	shape.rings = 5
	return mesh_node(shape, color, position)

static func add_static_collision(parent:Node3D, shape:Shape3D, position:=Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body

static func label_3d(text:String, color:=Color.WHITE, height:=1.5) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position.y = height
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 25
	label.outline_size = 5
	label.pixel_size = 0.004
	label.visibility_range_end = 22
	label.modulate = color
	return label
