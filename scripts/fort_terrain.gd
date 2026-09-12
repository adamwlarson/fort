class_name FortTerrain
extends RefCounted

# A contained terrain trial: the castle and existing authored sites stay flat.
# Rebuilt from the expedition seed, so joining/loading never needs mesh packets.
static var origins:Dictionary={}
static func origin(seed_value:int)->Vector3:
	if origins.has(seed_value):return origins[seed_value]
	var chosen:=Vector3(-112,0,0);var best:=-INF
	for i in 180:
		var a:float=PI*1.5+i*TAU/180
		var p:=Vector3(sin(a),0,cos(a))*112
		if p.x>45:continue # Preserve the quarry terraces and their access ramps.
		var clearance:=INF
		for spec in FortEncounters.layout(seed_value):clearance=minf(clearance,p.distance_to(spec.pos)-float(spec.radius))
		for spec in FortProgression.SITES:clearance=minf(clearance,p.distance_to(spec.pos)-16)
		if clearance>best:best=clearance;chosen=p
		if clearance>44:break
	origins[seed_value]=chosen
	return chosen

static func reserved(p:Vector3,seed_value:int,padding:=0.0)->bool:
	var offset:=p-origin(seed_value)
	return Vector2(offset.x,offset.z).length()<40+padding

static func height_at(x:float,z:float)->float:
	var envelope:=maxf(0,1-pow(x/26,2)-pow(z/30,2))
	return 8.0*pow(envelope,1.2)+sin(x*.35)*sin(z*.28)*.25*envelope

static func ceiling_height(z:float)->float:return 4.8+.8*(1-pow(z/4,2))

static func safe_position(p:Vector3,seed_value:int)->Vector3:
	var local:=p-origin(seed_value)
	# The same X/Z has two traversable levels. Do not eject cave occupants.
	if absf(local.z)<4 and (absf(local.x)>6 or local.y<ceiling_height(local.z)-.2):return p
	p.y=maxf(p.y,height_at(local.x,local.z)+.06)
	return p

static func point(x:float,z:float)->Vector3:return Vector3(x,height_at(x,z),z)
static func triangle(points:PackedVector3Array,a:Vector3,b:Vector3,c:Vector3)->void:
	# Godot uses clockwise front faces; upward terrain must face the camera.
	points.append_array(PackedVector3Array([a,c,b]))
static func quad(points:PackedVector3Array,a:Vector3,b:Vector3,c:Vector3,d:Vector3)->void:
	triangle(points,a,b,c);triangle(points,a,c,d)
static func surface(root:Node3D,points:PackedVector3Array,color:Color,name:String,smooth:bool)->void:
	var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_smooth_group(0 if smooth else -1)
	for vertex in points:builder.add_vertex(vertex)
	builder.generate_normals();builder.index()
	var mesh:=builder.commit();var node:=Visuals.mesh_node(mesh,color);node.name=name
	(node.material_override as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/world_ground.gdshader") if smooth else preload("res://assets/shaders/ridge_rock.gdshader")
	node.material_override=material
	root.add_child(node)
	var shape:=ConcavePolygonShape3D.new();shape.set_faces(points);shape.backface_collision=true
	Visuals.add_static_collision(root,shape)

static func build(world:FortWorld)->void:
	if not world.expedition.terrain_enabled:return
	if world.frontier.has_node("HollowbackRidge"):return
	var root:=Node3D.new();root.name="HollowbackRidge";root.position=origin(world.expedition.seed_value);world.frontier.add_child(root)
	world.scenery_keepouts.append({"pos":root.position,"radius":40.0,"terrain":true})
	var top:=PackedVector3Array();var rock:=PackedVector3Array()
	for x in range(-26,26,2):
		for z in range(-30,30,2):
			# Cut an east/west entrance trench; retain a thick central stone roof.
			if z>=-4 and z<4 and (x< -6 or x>=6):continue
			if maxf(maxf(height_at(x,z),height_at(x+2,z)),maxf(height_at(x,z+2),height_at(x+2,z+2)))<.03:continue
			quad(top,point(x,z),point(x,z+2),point(x+2,z+2),point(x+2,z))
		for z in [-4,4]:
			for layer in 5:
				var corners:Array[Vector3]=[]
				for corner in [Vector2(x,layer/5.0),Vector2(x,(layer+1)/5.0),Vector2(x+2,(layer+1)/5.0),Vector2(x+2,layer/5.0)]:
					var y:float=height_at(corner.x,z)*corner.y
					var recess:=sin(corner.y*PI)*(.25+.18*sin(corner.x*1.7+corner.y*5))
					corners.append(Vector3(corner.x,y,z+signf(z)*recess))
				quad(rock,corners[0],corners[1],corners[2],corners[3])
	for x in [-6,6]:
		for z in range(-4,4,2):quad(rock,Vector3(x,ceiling_height(z),z),point(x,z),point(x,z+2),Vector3(x,ceiling_height(z+2),z+2))
	for z in range(-4,4,2):quad(rock,Vector3(-6,ceiling_height(z),z),Vector3(6,ceiling_height(z),z),Vector3(6,ceiling_height(z+2),z+2),Vector3(-6,ceiling_height(z+2),z+2))
	surface(root,top,Color("#738257"),"GrassySlopes",true)
	surface(root,rock,Color("#666e73"),"CavernStone",false)
	# Dark worn trail under the roof, with warm lanterns framing both entrances.
	var trail:=Visuals.box(Vector3(51,.035,6.8),Color("#645c4d"),Vector3(0,.012,0));root.add_child(trail)
	for side in [-1,1]:
		for z in [-4.6,4.6]:
			FortLandscape.place(root,"moss_rock",Vector3(side*7,0,z),side*.4,1.7)
		for z in [-3.5,3.5]:
			var lamp:=OmniLight3D.new();lamp.position=Vector3(side*7,2.4,z);lamp.light_color=Color("#f4bc76");lamp.light_energy=.75;lamp.omni_range=8;root.add_child(lamp)
			root.add_child(Visuals.cylinder(.12,1.2,FortArt.WOOD,Vector3(side*7,1.1,z)))
			var glow:=Visuals.sphere(.18,Color("#ffcf7d"),Vector3(side*7,1.8,z));glow.material_override=Visuals.material(Color("#ffcf7d"),.8,Color("#eaa75b"));root.add_child(glow)
		FortLandscape.place(root,"trail_sign",Vector3(side*28,0,4),side*PI/2)
		var sign:=Visuals.label_3d("HOLLOWBACK RIDGE\nCAVERN / STRAIGHT\nSUMMIT / AROUND THE SLOPE",Color("#ead3a1"),3.3)
		sign.position.x=side*28;sign.visibility_range_end=70;root.add_child(sign)
	# Harvestable rewards share ordinary depletion, pet collection and save IDs.
	for i in 6:
		var p:=Vector3([-3,0,3,-3,0,3][i],0,[-2.8,2.8,-2.8,12,14,12][i])
		if i>=3:p.y=height_at(p.x,p.z)
		var node:=Node3D.new();node.position=root.position+p;world.resource_root.add_child(node)
		var kind:="crystal" if i<3 else "iron"
		node.add_child(FortArt.asset("crystal_vein" if i<3 else "iron_ore"))
		world.resource_nodes[29000+i]={"kind":kind,"amount":6 if i<3 else 12,"node":node,"animation":null,"respawn":0.0}
	var grass:Array[Transform3D]=[];var flowers:Array[Transform3D]=[]
	var random:=RandomNumberGenerator.new();random.seed=191912
	for i in 850:
		var x:=random.randf_range(-25,25);var z:=random.randf_range(-29,29)
		if absf(z)<5 or absf(x)<3 or height_at(x,z)<.12:continue # Clear north/south climbs.
		var p:=point(x,z)
		var pose:=Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*random.randf_range(.6,1.1)),p)
		if i%7==0:flowers.append(pose)
		else:grass.append(pose)
	FortLandscape.instance_asset(root,"fern",grass);FortLandscape.instance_asset(root,"wildflowers",flowers)
	var direction:=root.position.normalized()
	var guide:=FortLandscape.place(world.frontier,"trail_sign",direction*77)
	var caption:=Visuals.label_3d("HOLLOWBACK RIDGE\nFOLLOW THIS TRAIL / HEARTH 2",Color("#ead3a1"),2.4);caption.visibility_range_end=70;guide.add_child(caption)
	for i in 5:
		var p:=direction*(80+i*4.5)
		if reserved(p,world.expedition.seed_value,-9):break
		FortLandscape.place(world.frontier,"moss_rock",p+Vector3(2,0,0),0,.25)
