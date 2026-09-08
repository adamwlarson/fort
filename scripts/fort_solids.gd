class_name FortSolids
extends RefCounted

# Small plants/litter and living actors deliberately do not use scenery collision.
# Mesh-shaped static collision preserves arches, doorways and irregular rock edges.
const KEYS := ["treasure_chest", "supply_crate", "barrel", "quarry_cart", "ruin_arch", "mine_portal", "cliff_chunk", "moss_rock", "camp_tent", "waystone", "trail_sign", "wrecked_caravan", "beast_den", "bandit_totem", "forgotten_shrine", "ruined_observatory", "dragon_nest", "quarry_crane", "quarry_retaining", "quarry_bridge", "stone_outcrop_a", "stone_outcrop_b", "stone_outcrop_c", "crystal_vein", "iron_ore", "aether_geode", "village_house", "village_well"]
static var shapes:Dictionary = {}
const HULLS := ["treasure_chest", "supply_crate", "barrel", "quarry_cart", "cliff_chunk", "moss_rock", "camp_tent", "waystone", "trail_sign", "stone_outcrop_a", "stone_outcrop_b", "stone_outcrop_c", "crystal_vein", "iron_ore", "aether_geode"]

static func vertices(node:Node3D,pose:=Transform3D.IDENTITY)->PackedVector3Array:
	var points:=PackedVector3Array()
	if node is MeshInstance3D and node.mesh:
		for point in node.mesh.get_faces():points.append(pose*point)
	for child in node.get_children():
		if child is Node3D:points.append_array(vertices(child,pose*child.transform))
	return points

static func attach(model:Node3D,key:String)->void:
	if key not in KEYS:return
	if not shapes.has(key):
		var points:=vertices(model)
		if key in HULLS:
			# A single simplified hull keeps hundreds of deposits inexpensive for
			# swarm steering. Only hollow architecture needs triangle collision.
			var mesh:=ArrayMesh.new();var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			shapes[key]=mesh.create_convex_shape(true,true)
		else:
			var shape:=ConcavePolygonShape3D.new();shape.set_faces(points);shape.backface_collision=true
			shapes[key]=shape
	var body:=Visuals.add_static_collision(model,shapes[key]);body.name="SolidGeometry"
	model.set_meta("solid_asset",key)

static func harvest_collision(node:Node3D,active:bool)->void:
	for body in node.find_children("*","StaticBody3D",true,false):
		body.collision_layer=1 if active else 0
		body.collision_mask=1 if active else 0

static func harvest_reachable(world:Node3D,from:Vector3,resource:Node3D)->bool:
	# Seeing the deposit itself is not an obstruction; walls in front of it are.
	var excluded:Array[RID]=[]
	for body in resource.find_children("*","StaticBody3D",true,false):excluded.append(body.get_rid())
	var query:=PhysicsRayQueryParameters3D.create(from+Vector3.UP*.7,resource.global_position+Vector3.UP*.7,1,excluded)
	return world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
