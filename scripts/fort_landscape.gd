class_name FortLandscape
extends RefCounted

static var asset_parts:Dictionary={}

const LANDMARKS := [
	{"name":"Pinewatch Grove","pos":Vector3(-31,0,28),"kind":"wood","letter":"G","color":Color("#b5c68a")},
	{"name":"Old Quarry","pos":Vector3(36,0,-28),"kind":"stone","letter":"Q","color":Color("#b4c5ce")},
	{"name":"Moonwell Ruins","pos":Vector3(-37,0,-34),"kind":"crystal","letter":"R","color":Color("#88d9ce")},
]
const TRAILS := [
	[Vector2.ZERO,Vector2(0,12),Vector2(-31,28)],
	[Vector2.ZERO,Vector2(12,0),Vector2(36,-28)],
	[Vector2.ZERO,Vector2(-12,0),Vector2(-37,-34)],
	[Vector2.ZERO,Vector2(0,-14)],
]

static func trail_distance(pos:Vector3)->float:
	var p:=Vector2(pos.x,pos.z)
	var distance:=1000.0
	for trail in TRAILS:
		for i in range(trail.size()-1):
			var a:Vector2=trail[i]
			var d:Vector2=trail[i+1]-a
			distance=minf(distance,p.distance_to(a+d*clampf((p-a).dot(d)/d.length_squared(),0,1)))
	return distance

static func region_name(pos:Vector3)->String:
	if Vector2(pos.x,pos.z).length()>153:return "Stormglass Basin / Aether" if pos.z<0 else "Frostvein Ridge / Iron"
	if Vector2(pos.x,pos.z).length()>73:return "Rustscar Quarry / Iron" if pos.x>0 else "Elderwood"
	if Vector2(pos.x,pos.z).length()<12:return "Hearthhold"
	for landmark in LANDMARKS:
		if pos.distance_to(landmark.pos)<17:return landmark.name
	return "The Marchlands"

static func resource_position(rng:RandomNumberGenerator,kind:String,index:int,count:int,existing:Dictionary)->Vector3:
	var selected:=Vector3.ZERO
	for attempt in 128:
		var angle:=rng.randf_range(0,TAU)
		var radius:=rng.randf_range(14,49) if kind=="wood" else (rng.randf_range(22,56) if kind=="stone" else rng.randf_range(39,66))
		selected=Vector3(cos(angle)*radius,0,sin(angle)*radius)
		if index>=count/2:
			var site:Dictionary=LANDMARKS[0 if kind=="wood" else (1 if kind=="stone" else 2)]
			selected=site.pos+Vector3(cos(angle),0,sin(angle))*rng.randf_range(7,16)
		if selected.length()<13 or selected.length()>68 or trail_distance(selected)<3.0:continue
		if absf(selected.x)<12 and absf(selected.z)<12:continue
		if selected.distance_to(Vector3(36,0,-36))<6.2:continue
		var clear:=true
		for camp in FortProgression.SITES:
			if selected.distance_to(camp.pos)<(14 if camp.get("village",false) else 8):clear=false;break
		for other in existing.values():
			if selected.distance_to(other.node.position)<3.4:clear=false;break
		if clear:return selected
	return selected

static func build_base(parent:Node3D)->void:
	var ground:=MeshInstance3D.new()
	ground.name="MarchlandsGround"
	var plane:=PlaneMesh.new()
	plane.size=Vector2(1440,1440)
	ground.mesh=plane
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/world_ground.gdshader")
	ground.material_override=mat
	parent.add_child(ground)
	FortArt.box_collider(parent,Vector3(1440,0.2,1440),Vector3(0,-0.11,0))

static func clear_for_scenery(world:Node3D,pos:Vector3,radius:float)->bool:
	# Reserve four initial castle connections for harvestable resources, not immovable props.
	if (absf(pos.x)<10+radius and absf(pos.z)<30+radius) or (absf(pos.z)<10+radius and absf(pos.x)<30+radius):return false
	if pos.length()<12 or pos.length()>69 or trail_distance(pos)<radius+1.9:return false
	for site in FortProgression.SITES:
		if pos.distance_to(site.pos)<(14 if site.get("village",false) else 8):return false
	for resource in world.resource_nodes.values():
		if pos.distance_to(resource.node.position)<radius+1.8:return false
	for landmark in LANDMARKS:
		if pos.distance_to(landmark.pos)<5.5:return false
	return true

static func populate(world:Node3D)->void:
	var root:=Node3D.new()
	root.name="MarchlandsScenery"
	world.add_child(root)
	var rng:=RandomNumberGenerator.new()
	rng.seed=772804
	# Low foliage is instanced in shared mesh batches, not thousands of scene nodes.
	var ferns:Array[Transform3D]=[]
	var flowers:Array[Transform3D]=[]
	for i in 750:
		var p:=Vector3(rng.randf_range(-67,67),0,rng.randf_range(-67,67))
		if not clear_for_scenery(world,p,0.25):continue
		var basis:=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*rng.randf_range(0.65,1.3))
		if p.distance_to(LANDMARKS[1].pos)>16 and i%3==0:flowers.append(Transform3D(basis,p))
		else:ferns.append(Transform3D(basis,p))
	instance_asset(root,"fern",ferns)
	instance_asset(root,"wildflowers",flowers)
	for i in 65:
		var p:=Vector3(rng.randf_range(-68,68),0,rng.randf_range(-68,68))
		if not clear_for_scenery(world,p,1.3):continue
		var rock:=place(root,"moss_rock",p,rng.randf_range(0,TAU),rng.randf_range(0.65,1.15))
		FortArt.box_collider(rock,Vector3(1.35,0.82,1.0),Vector3(0,0.4,0))
		world.scenery_keepouts.append({"pos":p,"radius":1.25,"clearable":true,"node":rock})
	# Broken ridgelines beyond the playable boundary replace the identical hills.
	for i in 14:
		var a:=i*TAU/14
		var p:=Vector3(sin(a)*rng.randf_range(255,269),-1.0,cos(a)*rng.randf_range(255,269))
		var cliff:=place(root,"cliff_chunk",p,-a,rng.randf_range(2.0,3.0))
		cliff.scale.x*=1.6
		cliff.scale.y*=rng.randf_range(0.85,1.3)
	# Edge woods now unlock as real harvest nodes with the second hearth ring.
	FortFoliage.populate(root,world,12,70,1201,"meadow")
	make_landmarks(root,world)
	# Camp dressing fits inside the walls and stays out of the four gateway lanes.
	var tent:=place(root,"camp_tent",Vector3(-4.6,FortCastle.BASE,4.3),-0.35,0.88)
	FortArt.box_collider(tent,Vector3(1.9,1.45,1.8),Vector3(0,0.7,0))
	var barrel:=place(root,"barrel",Vector3(5.7,FortCastle.BASE,-4.0),0,0.85)
	FortArt.box_collider(barrel,Vector3(0.8,0.95,0.8),Vector3(0,0.48,0))
	place(root,"supply_crate",Vector3(4.7,FortCastle.BASE,-4.7),0.12,0.72)

static func place(parent:Node3D,key:String,pos:Vector3,yaw:=0.0,scale_factor:=1.0)->Node3D:
	var model:=FortArt.asset(key)
	parent.add_child(model)
	model.position=pos
	model.rotation.y=yaw
	model.scale*=scale_factor
	return model

static func make_landmarks(parent:Node3D,world:FortWorld)->void:
	for i in LANDMARKS.size():
		var landmark:Dictionary=LANDMARKS[i]
		var pos:Vector3=landmark.pos
		var site:=Node3D.new()
		site.name=landmark.name.replace(" ","")
		site.position=pos
		parent.add_child(site)
		world.scenery_keepouts.append({"pos":pos,"radius":10.0,"node":site,"clearable":true})
		var marker:=place(site,"waystone",Vector3(-3.5,0,0))
		FortArt.box_collider(marker,Vector3(0.8,1.8,0.8),Vector3(0,0.9,0))
		var label:=Visuals.label_3d(landmark.name.to_upper(),landmark.color,2.35)
		label.position.x=-3.5
		label.pixel_size=0.006
		site.add_child(label)
		if i==0:
			place(site,"supply_crate",Vector3(3.5,0,2.5),0.3,0.8)
		elif i==1:
			var cart:=place(site,"quarry_cart",Vector3(3.5,0,2.3),-0.45)
			FortArt.box_collider(cart,Vector3(1.45,1.2,1.65),Vector3(0,0.7,0))
			var rockface:=place(site,"cliff_chunk",Vector3(0,0,-8),0,1.1)
			FortArt.box_collider(rockface,Vector3(6.6,2.4,2.2),Vector3(0,1.1,0))
		else:
			var arch:=place(site,"ruin_arch",Vector3(0,0,-2.0))
			for side in [-1,1]:FortArt.box_collider(arch,Vector3(1,2.9,1),Vector3(side*1.42,1.45,0))
			var lamp:=OmniLight3D.new()
			lamp.light_color=Color("#76cabd");lamp.light_energy=0.55;lamp.omni_range=9;lamp.position=Vector3(0,2.0,-2)
			site.add_child(lamp)

static func collect_parts(node:Node,pose:Transform3D,parts:Array)->void:
	if node is Node3D:pose=pose*node.transform
	if node is MeshInstance3D:parts.append({"mesh":node.mesh,"pose":pose})
	for child in node.get_children():collect_parts(child,pose,parts)

static func instance_asset(parent:Node3D,key:String,poses:Array[Transform3D])->Array[MultiMeshInstance3D]:
	var batches:Array[MultiMeshInstance3D]=[]
	if poses.is_empty():return batches
	if not asset_parts.has(key):
		var source:=FortArt.asset(key)
		var collected:Array=[];collect_parts(source,Transform3D.IDENTITY,collected)
		asset_parts[key]=collected;source.free()
	var parts:Array=asset_parts[key]
	for part in parts:
		var batch:=MultiMeshInstance3D.new()
		batch.name=key+"_batch"
		var multimesh:=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=part.mesh
		multimesh.instance_count=poses.size()
		for i in poses.size():multimesh.set_instance_transform(i,poses[i]*part.pose)
		batch.multimesh=multimesh
		parent.add_child(batch)
		batches.append(batch)
	return batches

static func make_grass(parent:Node3D,world:Node3D,rng:RandomNumberGenerator)->void:
	var verts:=PackedVector3Array()
	var colors:=PackedColorArray()
	for i in 10000:
		var p:=Vector3(rng.randf_range(-73,73),0.018,rng.randf_range(-73,73))
		if p.length()<10.5 or trail_distance(p)<1.8:continue
		if p.distance_to(LANDMARKS[1].pos)<10 and i%5!=0:continue
		var h:=rng.randf_range(0.18,0.44)
		var color:=Color("#7d9056").darkened(rng.randf_range(0,0.25))
		for blade in 3:
			var a:=blade*PI/3+i*1.7
			var side:=Vector3(cos(a),0,sin(a))*0.05
			var lean:=Vector3(sin(a),0,cos(a))*h*0.3
			for v in [p-side,p+Vector3.UP*h+lean,p+side]:verts.append(v);colors.append(color)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var grass:=MeshInstance3D.new();grass.name="WindblownMeadow";grass.mesh=mesh
	var material:=ShaderMaterial.new();material.shader=preload("res://assets/shaders/meadow_grass.gdshader")
	grass.material_override=material
	parent.add_child(grass)
