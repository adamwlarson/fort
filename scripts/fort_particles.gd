class_name FortParticles
extends RefCounted

# CPU particles keep the Compatibility renderer and modest client GPUs supported.
static func ramp(colors: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	var offsets := PackedFloat32Array()
	for i in colors.size(): offsets.append(float(i) / (colors.size() - 1))
	gradient.offsets = offsets
	return gradient

static func curve(values: Array[float]) -> Curve:
	var result := Curve.new()
	result.max_value = 2.0
	for i in values.size(): result.add_point(Vector2(float(i)/(values.size()-1), values[i]))
	return result

static func soft_material(flame := false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/soft_particle.gdshader")
	material.set_shader_parameter("flame", flame)
	return material

static func emitter(label: String, count: int, seconds: float, draw_mesh: Mesh) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = label
	particles.emitting = false
	particles.amount = count
	particles.lifetime = seconds
	particles.mesh = draw_mesh
	particles.fixed_fps = 30
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.visibility_aabb = AABB(Vector3(-7,-2,-7), Vector3(14,12,14))
	return particles

static func quad(size: Vector2, flame := false) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = size
	mesh.material = soft_material(flame)
	return mesh

static func tree_destroyed(parent: Node3D, origin: Vector3, birch := false, foliage_color:=Color.TRANSPARENT) -> Node3D:
	var burst := Node3D.new()
	burst.name = "TreeDestruction"
	parent.add_child(burst)
	burst.global_position = origin
	burst.add_to_group("tree_destruction_fx")
	var solid := StandardMaterial3D.new()
	solid.vertex_color_use_as_albedo = true
	solid.roughness = 1.0
	solid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	solid.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chip_mesh := BoxMesh.new()
	chip_mesh.size = Vector3(0.07,0.045,0.22)
	chip_mesh.material = solid
	var chips := emitter("WoodChips", 36, 1.1, chip_mesh)
	chips.position.y = 0.85
	chips.spread = 75
	chips.initial_velocity_min = 2.0
	chips.initial_velocity_max = 4.2
	chips.gravity = Vector3(0,-8,0)
	chips.angular_velocity_min = -360
	chips.angular_velocity_max = 360
	chips.color_initial_ramp = ramp([Color("#805334"),Color("#dcba7b")])
	chips.color_ramp = ramp([Color.WHITE,Color.WHITE,Color(1,1,1,0)])
	chips.scale_amount_curve = curve([1.0,1.0,0.0])
	var leaf_mesh := ArrayMesh.new()
	var leaf_arrays := []
	leaf_arrays.resize(Mesh.ARRAY_MAX)
	# A folded diamond silhouette reads as foliage rather than square confetti.
	leaf_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0,0.13,0),Vector3(-0.07,-0.01,0),Vector3(0,-0.12,0),Vector3(0.07,-0.01,0),Vector3(0,0,0.025)])
	leaf_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK,Vector3.BACK,Vector3.BACK,Vector3.BACK,Vector3.BACK])
	leaf_arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,4,1,2,4,2,3,4,3,0,4])
	leaf_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,leaf_arrays)
	leaf_mesh.surface_set_material(0,solid)
	var leaves := emitter("FallingLeaves", 42, 2.8, leaf_mesh)
	leaves.position.y = 2.8
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	leaves.emission_sphere_radius = 1.1
	leaves.spread = 100
	leaves.initial_velocity_min = 0.7
	leaves.initial_velocity_max = 1.9
	leaves.gravity = Vector3(0.12,-0.75,0.06)
	leaves.angle_min = -180
	leaves.angle_max = 180
	leaves.angular_velocity_min = -200
	leaves.angular_velocity_max = 200
	leaves.particle_flag_rotate_y = true
	leaves.tangential_accel_min = -0.4
	leaves.tangential_accel_max = 0.4
	leaves.color_initial_ramp = ramp([Color("#b5b956") if birch else Color("#658a44"),Color("#c4cd7a")])
	if foliage_color.a>0:leaves.color_initial_ramp=ramp([foliage_color,foliage_color.lightened(.25)])
	leaves.color_ramp = ramp([Color.WHITE,Color.WHITE,Color(1,1,1,0)])
	var dust := emitter("BarkDust", 12, 1.3, quad(Vector2(0.65,0.65)))
	dust.position.y = 0.5
	dust.spread = 100
	dust.initial_velocity_min = 0.5
	dust.initial_velocity_max = 1.6
	dust.gravity = Vector3(0,0.1,0)
	dust.color_ramp = ramp([Color(0.64,0.48,0.28,0.25),Color(0.64,0.48,0.28,0.15),Color(0.64,0.48,0.28,0)])
	dust.scale_amount_curve = curve([0.4,1.0,1.5])
	for particles in [chips, leaves, dust]:
		particles.one_shot = true
		particles.explosiveness = 1.0
		burst.add_child(particles)
		particles.emitting = true
	# Independent of the hidden tree; the timer also cleans up on headless servers.
	burst.get_tree().create_timer(3.2).timeout.connect(burst.queue_free)
	return burst

static func mineral_hit(parent: Node3D, origin: Vector3, crystal := false) -> void:
	var burst:=Node3D.new()
	burst.name="MineralChips"
	parent.add_child(burst)
	burst.global_position=origin+Vector3.UP*0.6
	var shard:=PrismMesh.new()
	shard.size=Vector3(0.07,0.13,0.06)
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("#a8e7ce") if crystal else Color("#a9b4a9")
	shard.material=material
	var chips:=emitter("Chips",12,0.6,shard)
	chips.one_shot=true;chips.explosiveness=1.0
	chips.spread=80;chips.initial_velocity_min=1.0;chips.initial_velocity_max=2.5
	chips.gravity=Vector3(0,-7,0)
	chips.scale_amount_curve=curve([1.0,0.8,0.0])
	burst.add_child(chips);chips.emitting=true
	burst.get_tree().create_timer(0.8).timeout.connect(burst.queue_free)
