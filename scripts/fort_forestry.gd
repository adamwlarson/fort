class_name FortForestry
extends RefCounted

const SPECIES := {
	"pine":{"name":"March Pine","asset":"pine_tree","kind":"wood","capacity":12,"axe":1},
	"oak":{"name":"Elder Oak","asset":"elder_oak","kind":"wood","capacity":18,"axe":1},
	"amber":{"name":"Amberwood","asset":"amber_tree","kind":"wood","capacity":24,"axe":2},
	"mooncap":{"name":"Mooncap","asset":"spore_tree","kind":"crystal","capacity":12,"axe":2},
	"starcap":{"name":"Starcap","asset":"spore_tree","kind":"aether","capacity":8,"axe":3},
}

static func capacity(r:Dictionary)->int:
	return int(r.get("capacity",6 if r.kind in ["crystal","aether"] else 12))

static func is_tree(r:Dictionary)->bool:return r.kind=="wood" or r.get("tree",false)

static func requirement(r:Dictionary,p:FortPlayer)->String:
	var level:int=r.get("axe",1)
	return "Requires Forester's Axe +%d / upgrade at Workshop (T)"%level if int(p.weapon_levels.get("Axe",1))<level else ""

static func title(r:Dictionary)->String:return str(r.get("species",r.kind)).to_upper()

static func add_tree(world:FortWorld,id:int,species:String,pose:Transform3D)->void:
	if world.resource_nodes.has(id):return
	var spec:Dictionary=SPECIES[species]
	var node:=Node3D.new();node.name="HarvestTree%d"%id;node.position=pose.origin
	world.resource_root.add_child(node)
	var model:=FortArt.asset(spec.asset);model.name="TreeModel";model.basis=pose.basis;node.add_child(model)
	# Colliders use world scale; chopping removes this one tree, never the whole grove.
	var trunk:=StaticBody3D.new();trunk.name="TreeTrunk";node.add_child(trunk)
	var shape:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new()
	cylinder.radius=.36*pose.basis.get_scale().x;cylinder.height=2.2;shape.shape=cylinder;shape.position.y=1.1;trunk.add_child(shape)
	var anim:=FortPlayer.find_animation(model)
	if anim and anim.has_animation("Idle"):
		anim.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR;anim.play("Idle")
		anim.animation_finished.connect(func(clip):
			if clip=="Hit":anim.play("Idle",.1))
	world.resource_nodes[id]={"kind":spec.kind,"amount":spec.capacity,"capacity":spec.capacity,"species":spec.name,"axe":spec.axe,"tree":true,"node":node,"animation":anim,"respawn":0.0}

static func add_edge_woods(world:FortWorld)->void:
	var rng:=RandomNumberGenerator.new();rng.seed=120075
	# A deterministic, harvestable replacement for the old unchoppable skyline.
	for i in 100:
		var a:=i*TAU/100+.018;var p:=Vector3(sin(a),0,cos(a))*rng.randf_range(77,85)
		if absf(p.x)<4 or absf(p.z)<4:continue
		var blocked:=false
		for site in FortProgression.SITES:
			if p.distance_to(site.pos)<16:blocked=true
		if blocked:continue
		if FortEncounters.reserved(p,2,world.expedition.seed_value):continue
		add_tree(world,10000+i,"oak" if i%4==0 else "pine",Transform3D(Basis(Vector3.UP,a).scaled(Vector3.ONE*rng.randf_range(.85,1.35)),p))

static func pet_can_harvest(r:Dictionary,hearth:int,radius:float)->bool:
	# Workshop-trained companions unlock tough wood at hearth 2, starcaps at 3.
	return hearth>=int(r.get("axe",1)) and r.node.position.length()<radius
