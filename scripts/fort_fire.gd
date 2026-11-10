class_name FortFire
extends RefCounted
const WOOD:=["Barricade","Watchtower","Ballista","Mender","CastleGate"]
static var flash_material:StandardMaterial3D
static func hit(e:Dictionary,clock:float)->void:
	if not flash_material:
		flash_material=StandardMaterial3D.new();flash_material.albedo_color=Color(1,.035,.015,.65);flash_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;flash_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	e.flash_until=clock+.16
	for mesh in e.visual.find_children("*","MeshInstance3D",true,false):
		if not mesh.has_meta("hit_overlay"):mesh.set_meta("hit_overlay",mesh.material_overlay)
		mesh.material_overlay=flash_material
static func restore(e:Dictionary,clock:float)->void:
	if not e.has("flash_until") or clock<float(e.flash_until):return
	e.erase("flash_until")
	for mesh in e.visual.find_children("*","MeshInstance3D",true,false):
		if mesh.has_meta("hit_overlay"):mesh.material_overlay=mesh.get_meta("hit_overlay");mesh.remove_meta("hit_overlay")
static func ignite(w:FortWorld,id:int,roll:float=-1)->void:
	if not w.multiplayer.is_server() or not w.defenses.has(id):return
	var d:Dictionary=w.defenses[id]
	if d.kind not in WOOD:return
	if (w.expedition.rng.randf() if roll<0 else roll)<.3:d.burning=12.0
static func tick(w:FortWorld,delta:float)->void:
	for id in w.defenses.keys():
		var d:Dictionary=w.defenses[id]
		if float(d.get("burning",0))<=0:continue
		d.burning=maxf(0,float(d.burning)-delta)
		if w.clock>=float(d.get("burn_tick",0)):
			d.burn_tick=w.clock+1;d.charred=true;w._damage_defense(id,maxf(3,d.max_hp*.02))
static func visual(d:Dictionary)->void:
	var burning:=float(d.get("burning",0))>0
	var fire:=d.node.get_node_or_null("StructureFire") as CPUParticles3D
	if burning and not fire:
		fire=FortParticles.emitter("StructureFire",18,1.0,FortParticles.quad(Vector2(.5,.9),true));fire.position.y=.8;fire.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;fire.emission_sphere_radius=.8
		fire.initial_velocity_min=.6;fire.initial_velocity_max=1.4;fire.gravity=Vector3(0,.8,0);fire.color_ramp=FortParticles.ramp([Color("#ffe19a"),Color("#ed6b25"),Color(.2,.1,.05,0)]);d.node.add_child(fire)
	if fire:fire.emitting=burning
	if d.get("charred",false):
		var alpha:=clampf(1.0-float(d.hp)/float(d.max_hp),0,.8)
		var material:StandardMaterial3D=d.node.get_meta("scorch",null)
		if not material:
			material=StandardMaterial3D.new();material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;d.node.set_meta("scorch",material)
			for mesh in d.node.find_children("*","MeshInstance3D",true,false):mesh.material_overlay=material
		material.albedo_color=Color(.035,.02,.01,alpha)
