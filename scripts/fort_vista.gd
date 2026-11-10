class_name FortVista
extends RefCounted

# Fort 26 environment pass: painted sky, warmer light, rolling walkable knolls,
# distant mountain ranges, drifting motes and cloud shadows.
# Knolls are rebuilt from the expedition seed, so hosts, guests and saves agree without packets.

static var knolls:Array[Dictionary]=[]
static var built_seed:=-1
static var built_world:int=0
static var sky:ShaderMaterial
static var range_material:ShaderMaterial

static func height(pos:Vector3)->float:
	var best:=0.0
	for k in knolls:
		var d:float=Vector2(pos.x-k.pos.x,pos.z-k.pos.z).length()/float(k.radius)
		if d<1.0:best=maxf(best,float(k.height)*pow(1.0-d*d,2.0))
	return best

static func on_knoll(pos:Vector3,padding:=0.0)->bool:
	for k in knolls:
		if Vector2(pos.x-k.pos.x,pos.z-k.pos.z).length()<float(k.radius)+padding:return true
	return false

# ---------------------------------------------------------------- sky and light
static func build_sky(world:FortWorld)->void:
	sky=ShaderMaterial.new();sky.shader=preload("res://assets/shaders/vista_sky.gdshader")
	var holder:=Sky.new();holder.sky_material=sky
	world.environment.sky=holder
	world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment.tonemap_white=2.2
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color("#b9c8dc")
	world.environment.ambient_light_energy=0.42
	world.environment.fog_enabled=true
	world.environment.fog_density=0.0011
	world.environment.fog_sun_scatter=0.18
	world.environment.fog_aerial_perspective=0.15
	world.environment.adjustment_enabled=true
	world.environment.adjustment_saturation=1.18
	world.environment.adjustment_contrast=1.04
	world.sun.shadow_bias=0.04
	world.sun.directional_shadow_max_distance=110
	world.sun.directional_shadow_blend_splits=true

static func update_light(world:FortWorld,delta:float,t:float)->void:
	var night:=world.is_night
	var blend:=clampf(delta*0.9,0,1)
	# Dawn and dusk warm the first and last tenth of each day.
	var edge:=0.0 if night else clampf(1.0-minf(t,1.0-t)*9.0,0.0,1.0)
	var energy:=0.3 if night else lerpf(1.05,0.8,edge)
	world.sun.light_energy=lerpf(world.sun.light_energy,energy,blend)
	var day_color:=Color("#fff1d2").lerp(Color("#ffb074"),edge)
	world.sun.light_color=world.sun.light_color.lerp(Color("#8fa6e6") if night else day_color,blend)
	world.sun.rotation_degrees=Vector3(-22-sin(clampf(t,0,1)*PI)*38,-32+t*64.0,0) if not night else Vector3(-52,38,0)
	world.environment.ambient_light_energy=lerpf(world.environment.ambient_light_energy,0.3 if night else 0.44,blend)
	world.environment.ambient_light_color=world.environment.ambient_light_color.lerp(Color("#6f86b8") if night else Color("#b9c8dc").lerp(Color("#d9b9a3"),edge),blend)
	world.environment.fog_light_color=world.environment.fog_light_color.lerp(Color("#1d2c44") if night else Color("#a9c3d6").lerp(Color("#e0a983"),edge),blend)
	if not sky:return
	var top:Color=sky.get_shader_parameter("top_color") if sky.get_shader_parameter("top_color")!=null else Color("#4278b8")
	var horizon:Color=sky.get_shader_parameter("horizon_color") if sky.get_shader_parameter("horizon_color")!=null else Color("#c7d6db")
	var amount:float=sky.get_shader_parameter("night") if sky.get_shader_parameter("night")!=null else 0.0
	sky.set_shader_parameter("top_color",top.lerp(Color("#0b1630") if night else Color("#2f6fc4").lerp(Color("#59669e"),edge),blend))
	sky.set_shader_parameter("horizon_color",horizon.lerp(Color("#2c3a55") if night else Color("#b4d3ea").lerp(Color("#f3b888"),edge),blend))
	sky.set_shader_parameter("ground_color",Color("#16202b") if night else Color("#4d6156"))
	sky.set_shader_parameter("night",lerpf(amount,1.0 if night else 0.0,blend))
	if range_material:
		range_material.set_shader_parameter("haze",world.environment.fog_light_color)
		range_material.set_shader_parameter("dim",lerpf(float(range_material.get_shader_parameter("dim")),0.34 if night else 1.0,blend))

# ---------------------------------------------------------------- horizon
static func build_horizon(world:FortWorld)->void:
	var root:=Node3D.new();root.name="VistaHorizon";world.add_child(root)
	range_material=ShaderMaterial.new();range_material.shader=preload("res://assets/shaders/vista_range.gdshader");range_material.set_shader_parameter("dim",1.0)
	var rng:=RandomNumberGenerator.new();rng.seed=260026
	# Three overlapping ridgelines: forested foothills, bare rock, snow peaks.
	var layers:=[
		{"radius":700.0,"base":26.0,"peak":52.0,"low":Color("#2f5a3c"),"high":Color("#58803f"),"snow":2.0,"haze":0.16},
		{"radius":790.0,"base":52.0,"peak":104.0,"low":Color("#4a5f66"),"high":Color("#7d8791"),"snow":0.84,"haze":0.3},
		{"radius":900.0,"base":84.0,"peak":170.0,"low":Color("#5d7190"),"high":Color("#8496b4"),"snow":0.66,"haze":0.44},
	]
	for layer in layers:
		var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segments:=150
		var crest:PackedFloat32Array=[]
		for i in segments+1:
			var a:=float(i)/segments*TAU
			var h:=float(layer.base)+float(layer.peak)*(0.5+0.5*sin(a*5.0+float(layer.radius)))*(0.35+0.65*rng.randf())
			if i%3==0:h*=1.0+rng.randf()*0.5
			crest.append(h)
		crest[segments]=crest[0]
		for i in segments:
			var a0:=float(i)/segments*TAU;var a1:=float(i+1)/segments*TAU
			var r:=float(layer.radius)
			var b0:=Vector3(sin(a0)*r,-6,cos(a0)*r);var b1:=Vector3(sin(a1)*r,-6,cos(a1)*r)
			var mid0:=Vector3(sin(a0)*(r+18),crest[i]*0.55,cos(a0)*(r+18));var mid1:=Vector3(sin(a1)*(r+18),crest[i+1]*0.55,cos(a1)*(r+18))
			var t0:=Vector3(sin(a0)*(r+46),crest[i],cos(a0)*(r+46));var t1:=Vector3(sin(a1)*(r+46),crest[i+1],cos(a1)*(r+46))
			var top0:Color=layer.high;var top1:Color=layer.high
			var limit:=(float(layer.base)+float(layer.peak))*float(layer.snow)
			if crest[i]>limit:top0=Color("#eef3f7")
			if crest[i+1]>limit:top1=Color("#eef3f7")
			var low:Color=layer.low;var mid_color:Color=low.lerp(layer.high,0.6)
			for tri in [[b0,low,mid0,mid_color,b1,low],[b1,low,mid0,mid_color,mid1,mid_color],[mid0,mid_color,t0,top0,mid1,mid_color],[mid1,mid_color,t0,top0,t1,top1]]:
				for corner in 3:
					tool.set_color(tri[corner*2+1]);tool.set_uv(Vector2(a0/TAU,0));tool.add_vertex(tri[corner*2])
		tool.generate_normals()
		var ridge:=MeshInstance3D.new();ridge.name="Ridgeline";ridge.mesh=tool.commit()
		var material:ShaderMaterial=range_material.duplicate() if layer!=layers[0] else range_material
		material.set_shader_parameter("haze_amount",layer.haze)
		ridge.material_override=material;ridge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ridge.extra_cull_margin=2000
		root.add_child(ridge)
		if layer!=layers[0]:ridge.set_meta("vista_material",material)
	# Motes of pollen by day and fireflies by night drift around the camera.
	var motes:=CPUParticles3D.new();motes.name="VistaMotes";motes.amount=70;motes.lifetime=7.0;motes.preprocess=7.0
	motes.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;motes.emission_box_extents=Vector3(18,3.5,18)
	motes.gravity=Vector3(0.12,0.05,0.05);motes.initial_velocity_min=0.05;motes.initial_velocity_max=0.3;motes.spread=180
	motes.scale_amount_min=0.5;motes.scale_amount_max=1.2
	var quad:=QuadMesh.new();quad.size=Vector2(0.07,0.07)
	var glow:=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	glow.albedo_color=Color(1.0,0.96,0.7,0.75);glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glow.vertex_color_use_as_albedo=true
	quad.material=glow;motes.mesh=quad
	motes.color_ramp=FortParticles.ramp([Color(1,1,1,0),Color(1,1,1,1),Color(1,1,1,0)])
	world.add_child(motes)

static func follow(world:FortWorld)->void:
	var motes:=world.get_node_or_null("VistaMotes") as CPUParticles3D
	var p:=world.local_player()
	if motes and p:
		motes.position=p.position+Vector3(0,3.2,0)
		motes.color=Color("#bdf59a") if world.is_night else Color("#fff3c4")
	var horizon:=world.get_node_or_null("VistaHorizon")
	if horizon:
		for ridge in horizon.get_children():
			if ridge.has_meta("vista_material") and range_material:
				var material:ShaderMaterial=ridge.get_meta("vista_material")
				material.set_shader_parameter("haze",range_material.get_shader_parameter("haze"));material.set_shader_parameter("dim",range_material.get_shader_parameter("dim"))

# ---------------------------------------------------------------- knolls
static func clear_spot(world:FortWorld,pos:Vector3,radius:float)->bool:
	if absf(pos.x)<11+radius*0.2 or absf(pos.z)<11+radius*0.2:return false
	if pos.x>90 and pos.x<150 and pos.z>-32 and pos.z<46:return false
	for site in FortProgression.SITES:
		if pos.distance_to(site.pos)<radius+(26 if site.get("village",false) else 17):return false
	for landmark in FortLandscape.LANDMARKS:
		if pos.distance_to(landmark.pos)<radius+17:return false
	for spec in FortEncounters.layout(world.expedition.seed_value):
		if pos.distance_to(spec.pos)<radius+float(spec.radius)+6:return false
	if FortTerrain.reserved(pos,world.expedition.seed_value,radius+8):return false
	for other in knolls:
		if pos.distance_to(other.pos)<radius+float(other.radius)+5:return false
	if world.castle:
		for room in world.castle.rooms.values():
			if pos.distance_to(FortCastle.position(room))<radius+26:return false
	for defense in world.defenses.values():
		if pos.distance_to(defense.node.position)<radius+4:return false
	return true

static func ensure(world:FortWorld)->void:
	if not world.expedition:return
	if built_seed==world.expedition.seed_value and built_world==world.get_instance_id():return
	built_seed=world.expedition.seed_value;built_world=world.get_instance_id()
	var old:=world.get_node_or_null("VistaKnolls")
	if old:world.remove_child(old);old.queue_free()
	for i in range(world.scenery_keepouts.size()-1,-1,-1):
		if world.scenery_keepouts[i].get("knoll",false):world.scenery_keepouts.remove_at(i)
	knolls.clear()
	var root:=Node3D.new();root.name="VistaKnolls";world.add_child(root)
	var rng:=RandomNumberGenerator.new();rng.seed=built_seed+260026
	var wanted:=[[40.0,70.0,5],[78.0,150.0,9],[158.0,238.0,10]]
	# Automated fixtures place walls and raiders at fixed meadow coordinates; keep that ring level for them.
	if "--fort-test" in OS.get_cmdline_user_args():wanted.remove_at(0)
	for band in wanted:
		var made:=0
		for attempt in 260:
			if made>=int(band[2]):break
			var angle:=rng.randf()*TAU;var distance:=rng.randf_range(band[0],band[1])
			var radius:=rng.randf_range(9.0,15.0) if band[0]<75 else rng.randf_range(11.0,19.0)
			var pos:=Vector3(sin(angle)*distance,0,cos(angle)*distance)
			if distance-radius<34 or not clear_spot(world,pos,radius):continue
			var knoll:={"pos":pos,"radius":radius,"height":radius*rng.randf_range(0.14,0.21)}
			knolls.append(knoll);made+=1
			root.add_child(make_knoll(knoll,rng))
			world.scenery_keepouts.append({"pos":pos,"radius":radius*0.92,"terrain":true,"knoll":true})
	settle(world)
	world.navigation_revision+=1

static func make_knoll(knoll:Dictionary,rng:RandomNumberGenerator)->Node3D:
	var node:=Node3D.new();node.name="Knoll";node.position=knoll.pos
	var rings:=9;var segments:=26
	var radius:float=knoll.radius;var top:float=knoll.height
	var faces:=PackedVector3Array()
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_smooth_group(0)
	var point:=func(ring:int,segment:int)->Vector3:
		var d:=float(ring)/rings
		var a:=float(segment%segments)/segments*TAU
		return Vector3(sin(a)*radius*d,top*pow(1.0-d*d,2.0)-0.02,cos(a)*radius*d)
	for ring in rings:
		for segment in segments:
			var a:Vector3=point.call(ring,segment);var b:Vector3=point.call(ring+1,segment)
			var c:Vector3=point.call(ring+1,segment+1);var d:Vector3=point.call(ring,segment+1)
			var tris:=[b,a,c] if ring==0 else [a,d,c,a,c,b]
			if ring==0:tris=[a,c,b]
			for v in tris:tool.add_vertex(v);faces.append(v)
	tool.generate_normals();tool.index()
	var mesh:=MeshInstance3D.new();mesh.mesh=tool.commit()
	var material:=ShaderMaterial.new();material.shader=preload("res://assets/shaders/world_ground.gdshader");mesh.material_override=material
	node.add_child(mesh)
	var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true
	Visuals.add_static_collision(node,shape)
	# Wind-blown grass and a few stones so the hill reads as part of the meadow.
	var verts:=PackedVector3Array();var colors:=PackedColorArray()
	for i in int(radius*radius*4.5):
		var a:=rng.randf()*TAU;var d:=sqrt(rng.randf())*0.96
		var base:=Vector3(sin(a)*radius*d,top*pow(1.0-d*d,2.0),cos(a)*radius*d)
		var h:=rng.randf_range(0.2,0.5)
		var color:=Color("#87a25a").darkened(rng.randf_range(0,0.2))
		for blade in 2:
			var ba:=blade*PI/2+i*1.7
			var side:=Vector3(cos(ba),0,sin(ba))*0.05
			for v in [base-side,base+Vector3.UP*h+Vector3(sin(ba),0,cos(ba))*h*0.3,base+side]:verts.append(v);colors.append(color if v.y<base.y+0.01 else color.lightened(0.18))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_COLOR]=colors
	var blades:=ArrayMesh.new();blades.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var grass:=MeshInstance3D.new();grass.mesh=blades;grass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var grass_material:=ShaderMaterial.new();grass_material.shader=preload("res://assets/shaders/knoll_grass.gdshader");grass.material_override=grass_material
	node.add_child(grass)
	for i in 2+int(radius/5):
		var a:=rng.randf()*TAU;var d:=rng.randf_range(0.2,0.85)
		var spot:=Vector3(sin(a)*radius*d,top*pow(1.0-d*d,2.0)-0.08,cos(a)*radius*d)
		FortLandscape.place(node,"moss_rock",spot,rng.randf()*TAU,rng.randf_range(0.45,0.95))
	return node

# Harvest nodes that happen to sit inside a knoll are lifted onto its surface.
static func settle(world:FortWorld)->void:
	for resource in world.resource_nodes.values():
		var node:Node3D=resource.node
		if not is_instance_valid(node):continue
		var lift:=height(node.position)
		if lift>0.02 and (node.position.y<0.05 or node.has_meta("vista_lift")):
			node.position.y=lift;node.set_meta("vista_lift",true)
		elif node.has_meta("vista_lift") and lift<=0.02:
			node.position.y=0;node.remove_meta("vista_lift")

# Raiders that fall through or spawn inside the ground are removed (host only).
static func cull_buried(world:FortWorld)->void:
	for id in world.enemies.keys():
		var e:Dictionary=world.enemies[id]
		var body:Node3D=e.node
		var floor_height:=height(body.position)
		if body.position.y<-1.8 or (floor_height>0.5 and body.position.y<floor_height-1.6):
			world._damage_enemy(int(id),float(e.hp)+1.0,Vector3.ZERO,"buried")

static func release(world:FortWorld)->void:
	if built_world==world.get_instance_id():knolls.clear();built_seed=-1;built_world=0
	if world.environment:world.environment.sky=null
	sky=null;range_material=null
