class_name FortRustscar
extends RefCounted
const ORE:=[Vector3(101,0,7),Vector3(108,0,5),Vector3(105,0,-5),Vector3(116,0,8),Vector3(124,2,8),Vector3(128,2,18),Vector3(125,2,26),Vector3(128,2,-4),Vector3(136,4,7),Vector3(136,4,16),Vector3(136,4,26),Vector3(136,4,-4)]
static func build(world:FortWorld)->void:
	var root:=Node3D.new();root.name="RustscarQuarry";world.frontier.add_child(root)
	for shelf in [{"pos":Vector3(126,1,10),"size":Vector3(12,2,36)},{"pos":Vector3(136,2,10),"size":Vector3(8,4,36)}]:
		root.add_child(Visuals.box(shelf.size,Color("#856d56"),shelf.pos));FortArt.box_collider(root,shelf.size,shelf.pos)
	for z in [-5,1,7,13,25]:
		var ledge:=FortLandscape.place(root,"quarry_retaining",Vector3(120,0,z),PI/2)
		ledge.scale.z=.8
		FortLandscape.place(root,"quarry_retaining",Vector3(132,2,z),PI/2)
	ramp(root,Vector3(108,0,20),Vector3(120,2,20),4)
	ramp(root,Vector3(122,2,-11),Vector3(132,4,-11),4)
	# Second access links into the shelf, with a repaired timber crossing.
	root.add_child(Visuals.box(Vector3(10,.25,4),Color("#7c6045"),Vector3(127,2,-10)))
	FortArt.box_collider(root,Vector3(10,.25,4),Vector3(127,1.87,-10))
	root.add_child(Visuals.box(Vector3(8,.2,4),Color("#856d56"),Vector3(136,3.9,-10)))
	FortArt.box_collider(root,Vector3(8,.2,4),Vector3(136,3.9,-10))
	var bridge:=FortLandscape.place(root,"quarry_bridge",Vector3(124,2,-10),PI/2);bridge.scale.z=1.5
	FortArt.box_collider(root,Vector3(9,.2,2.7),Vector3(124,1.91,-10))
	FortLandscape.place(root,"quarry_crane",Vector3(126,2,1),PI/2)
	FortArt.box_collider(root,Vector3(1,5,1),Vector3(126,4.5,1))
	FortLandscape.place(root,"mine_portal",Vector3(140,4,10),PI/2)
	for i in 5:
		var cliff:=FortLandscape.place(root,"cliff_chunk",Vector3(143,2,-6+i*8),PI/2,1.3)
		cliff.scale.y=1.7
	for pos in [Vector3(104,0,14),Vector3(122,2,27),Vector3(134,4,0)]:
		var cart:=FortLandscape.place(root,"quarry_cart",pos,.5,.9)
		world.scenery_keepouts.append({"pos":pos,"radius":1.8,"clearable":true,"node":cart})
	for i in 9:
		root.add_child(Visuals.box(Vector3(.16,.1,1.9),Color("#6b4e38"),Vector3(95+i*1.4,.06,0)))
	for z in [-.7,.7]:root.add_child(Visuals.box(Vector3(14,.1,.08),Color("#7f8e91"),Vector3(101,.15,z)))
	var sign:=Visuals.label_3d("RUSTSCAR QUARRY\nIRON / UPPER TERRACES",Color("#e2c598"),3);sign.position=Vector3(101,3,17);sign.visibility_range_end=55;root.add_child(sign)
static func ramp(root:Node3D,a:Vector3,b:Vector3,width:float)->void:
	var side:Vector3=(b-a).cross(Vector3.UP).normalized()*width*.5
	var points:=PackedVector3Array([a-side,a+side,b-side,b+side,Vector3(b.x,a.y,b.z)-side,Vector3(b.x,a.y,b.z)+side])
	var shape:=ConvexPolygonShape3D.new();shape.points=points;Visuals.add_static_collision(root,shape)
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [a-side,b-side,b+side,a-side,b+side,a+side]:mesh.surface_add_vertex(point)
	mesh.surface_end();var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=Visuals.material(Color("#af8d68"));node.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;root.add_child(node)
