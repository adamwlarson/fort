class_name FortVista
extends RefCounted

# Environment pass: painted sky, warmer light, distant mountain ranges, drifting motes
# and cloud shadows. The walkable land itself is FortGround (Fort 30); the Fort 26 knolls
# that used to sit on a flat plane are now part of the real terrain.

static var sky:ShaderMaterial
static var range_material:ShaderMaterial

static func height(pos:Vector3)->float:
	return FortGround.height(pos.x,pos.z)

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
	world.environment.fog_density=0.0006
	world.environment.fog_sun_scatter=0.18
	world.environment.fog_aerial_perspective=0.15
	# The sky paints its own horizon haze; scene fog over it would wash out clouds and stars.
	world.environment.fog_sky_affect=0.0
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
	var edge:=0.0 if night else clampf(1.0-minf(t,1.0-t)*7.0,0.0,1.0)
	var energy:=0.3 if night else lerpf(1.05,0.8,edge)
	world.sun.light_energy=lerpf(world.sun.light_energy,energy,blend)
	var day_color:=Color("#fff1d2").lerp(Color("#ffb074"),edge)
	world.sun.light_color=world.sun.light_color.lerp(Color("#8fa6e6") if night else day_color,blend)
	# The sun climbs from low in the east to high at noon and sinks low in the west, so dawn
	# and dusk are real sunsets. The moon crosses the other way, more slowly.
	var arc:=sin(clampf(t,0,1)*PI)
	world.sun.rotation_degrees=Vector3(-11-arc*49,-70+t*140.0,0) if not night else Vector3(-36-arc*16,48-t*96.0,0)
	world.environment.ambient_light_energy=lerpf(world.environment.ambient_light_energy,0.3 if night else 0.44,blend)
	world.environment.ambient_light_color=world.environment.ambient_light_color.lerp(Color("#6f86b8") if night else Color("#b9c8dc").lerp(Color("#d9b9a3"),edge),blend)
	world.environment.fog_light_color=world.environment.fog_light_color.lerp(Color("#1d2c44") if night else Color("#a9c3d6").lerp(Color("#e0a983"),edge),blend)
	if not sky:return
	var top:Color=sky.get_shader_parameter("top_color") if sky.get_shader_parameter("top_color")!=null else Color("#4278b8")
	var horizon:Color=sky.get_shader_parameter("horizon_color") if sky.get_shader_parameter("horizon_color")!=null else Color("#c7d6db")
	var amount:float=sky.get_shader_parameter("night") if sky.get_shader_parameter("night")!=null else 0.0
	sky.set_shader_parameter("top_color",top.lerp(Color("#050a1c") if night else Color("#2364c2").lerp(Color("#4a5aa0"),edge),blend))
	sky.set_shader_parameter("horizon_color",horizon.lerp(Color("#17243f") if night else Color("#b4d3ea").lerp(Color("#f6b27c"),edge),blend))
	sky.set_shader_parameter("ground_color",Color("#16202b") if night else Color("#4d6156"))
	sky.set_shader_parameter("night",lerpf(amount,1.0 if night else 0.0,blend))
	var glow:float=sky.get_shader_parameter("dusk") if sky.get_shader_parameter("dusk")!=null else 0.0
	sky.set_shader_parameter("dusk",lerpf(glow,edge,blend))
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
		{"radius":1250.0,"base":170.0,"peak":240.0,"low":Color("#35464f"),"high":Color("#5f6c77"),"snow":0.93,"haze":0.34},
		{"radius":1500.0,"base":240.0,"peak":380.0,"low":Color("#4d6182"),"high":Color("#7486a6"),"snow":0.86,"haze":0.5},
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
			var mid0:=Vector3(sin(a0)*(r+60),crest[i]*0.55,cos(a0)*(r+60));var mid1:=Vector3(sin(a1)*(r+60),crest[i+1]*0.55,cos(a1)*(r+60))
			var t0:=Vector3(sin(a0)*(r+150),crest[i],cos(a0)*(r+150));var t1:=Vector3(sin(a1)*(r+150),crest[i+1],cos(a1)*(r+150))
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
		ridge.extra_cull_margin=4000
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

# Raiders that fall through or spawn inside the ground are removed (host only).
static func cull_buried(world:FortWorld)->void:
	for id in world.enemies.keys():
		var e:Dictionary=world.enemies[id]
		var body:Node3D=e.node
		if body.position.y<FortGround.height(body.position.x,body.position.z)-1.8:
			world._damage_enemy(int(id),float(e.hp)+1.0,Vector3.ZERO,"buried")

static func release(world:FortWorld)->void:
	if world.environment:world.environment.sky=null
	sky=null;range_material=null
