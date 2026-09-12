class_name FortFrontier
extends Node3D

const COSTS := [{"wood":50,"stone":40,"crystal":8},{"wood":90,"stone":70,"crystal":18}]
var built_level := 1
var ward: Node3D
var world: FortWorld

func _ready()->void:
	world=get_parent()
	_rebuild_ward()

func expand(level:int)->void:
	while built_level<level:
		built_level+=1
		_build_ring(built_level)
	_rebuild_ward()
	# Additional runestones make the hearth itself visibly grow in power.
	for i in (level-1)*4:
		if has_node("HearthRune%d"%i):continue
		var rune:=FortArt.asset("waystone")
		# Hearth upgrade trim is decoration, not a ring of movement obstacles.
		for body in rune.find_children("*","StaticBody3D",true,false):body.collision_layer=0;body.collision_mask=0
		rune.name="HearthRune%d"%i
		var angle:=PI/4+i*TAU/8
		rune.position=Vector3(sin(angle)*2.5,0,cos(angle)*2.5)
		rune.position.y=int(i/8)*.5
		rune.scale=Vector3.ONE*0.36
		add_child(rune)

func _rebuild_ward()->void:
	if is_instance_valid(ward):ward.queue_free()
	ward=Node3D.new();ward.name="FrontierWard";add_child(ward)
	var radius:=world.frontier_radius()
	var ring:=TorusMesh.new();ring.inner_radius=radius-0.10;ring.outer_radius=radius+0.10;ring.rings=160;ring.ring_segments=4
	var mesh:=Visuals.mesh_node(ring,Color("#74b5a6"));mesh.position.y=0.13
	(mesh.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ward.add_child(mesh)
	for i in 8:
		var angle:=i*TAU/8
		var pos:=Vector3(sin(angle),0,cos(angle))*radius
		FortLandscape.place(ward,"waystone",pos,angle,0.85)
		var label:=Visuals.label_3d("WARD LIMIT / UPGRADE HEARTH" if built_level<GameData.MAX_HEARTH else "THE EDGE OF THE MARCH",Color("#a6dbca"),2.2)
		label.position+=pos;label.font_size=22;ward.add_child(label)

func _build_ring(level:int)->void:
	if level>3:world.expedition.build_ring(self,level);return
	var radius:=112.0 if level==2 else 202.0
	var grove:=Node3D.new();grove.name="OuterMarchTier%d"%level;add_child(grove)
	var quarry_ore:=0
	if level==2:FortRustscar.build(world);FortTerrain.build(world)
	# Deterministic IDs and positions ensure live upgrades and late joins agree.
	for i in 72:
		var id:=1000+level*100+i
		var angle:float=(i+0.5)*TAU/72
		var pos:=Vector3(sin(angle),0,cos(angle))*(radius+sin(i*2.4)*20)
		for site in FortProgression.SITES:
			if pos.distance_to(site.pos)<(15 if site.get("village",false) else 10):pos+=pos.normalized()*24
		var kind:String=["wood","stone","crystal"][i%3]
		if level==2 and pos.x>0:kind="iron" if i%3!=0 else "stone"
		if level==3:kind="aether" if pos.z<0 else ("iron" if i%2==0 else "crystal")
		if level==2 and kind=="iron" and quarry_ore<FortRustscar.ORE.size():
			pos=FortRustscar.ORE[quarry_ore];quarry_ore+=1
		else:
			for attempt in 48:
				if not FortEncounters.reserved(pos,level,world.expedition.seed_value):break
				pos=pos.rotated(Vector3.UP,.025)
		var node:=Node3D.new();node.position=pos;world.resource_root.add_child(node)
		var model:=FortArt.asset({"wood":"pine_tree","stone":"stone_outcrop_b","crystal":"crystal_vein","iron":"iron_ore","aether":"aether_geode"}[kind])
		node.add_child(model);node.rotation.y=angle
		var anim:=FortPlayer.find_animation(model)
		if anim:
			anim.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR;anim.play("Idle")
			anim.animation_finished.connect(func(clip):
				if clip=="Hit":anim.play("Idle",0.1))
		if kind=="wood":
			var trunk:=StaticBody3D.new();trunk.name="TreeTrunk";node.add_child(trunk)
			var shape:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new();cylinder.radius=0.24;cylinder.height=1.8
			shape.shape=cylinder;shape.position.y=0.9;trunk.add_child(shape)
		world.resource_nodes[id]={"kind":kind,"amount":6 if kind in ["crystal","aether"] else 12,"node":node,"animation":anim,"respawn":0.0}
		if i%4==0 and not FortTerrain.reserved(pos,world.expedition.seed_value,5):
			FortLandscape.place(grove,"moss_rock",pos+Vector3(3,0,2),angle,0.8)
			FortLandscape.place(grove,"fern",pos+Vector3(-2,0,1),angle,1.5)
	for i in 4:
		if level==2 and i==1:continue # Authored quarry replaces the old generic eastern camp.
		var angle:=i*TAU/4
		var pos:=Vector3(sin(angle),0,cos(angle))*radius
		if FortTerrain.reserved(pos,world.expedition.seed_value,30):continue
		FortLandscape.place(grove,"ruin_arch",pos+Vector3(4,0,4),angle,0.8)
		FortLandscape.place(grove,"camp_tent",pos+Vector3(-4,0,3),angle,0.85)
		var zone:String=("RUSTSCAR QUARRY / IRON" if pos.x>10 else "ELDERWOOD / TIMBER") if level==2 else ("STORMGLASS BASIN / AETHER" if pos.z<0 else "FROSTVEIN RIDGE / IRON & CRYSTAL")
		var label:=Visuals.label_3d(zone,Color("#b1e3d4"),3)
		label.position+=pos;grove.add_child(label)
		for j in 5:FortLandscape.place(grove,"cliff_chunk",pos+Vector3(sin(j*1.25)*25,-0.5,cos(j*1.25)*25),j,0.7 if level==2 else 1.1)
	var rng:=RandomNumberGenerator.new();rng.seed=4100+level
	var ferns:Array[Transform3D]=[]
	var flowers:Array[Transform3D]=[]
	var rubble:Array[Transform3D]=[]
	var verts:=PackedVector3Array();var colors:=PackedColorArray()
	for i in 9000:
		var angle:=rng.randf()*TAU
		var p:=Vector3(sin(angle),0,cos(angle))*sqrt(rng.randf_range(pow(74 if level==2 else 154,2),pow(152 if level==2 else 240,2)))
		if FortTerrain.reserved(p,world.expedition.seed_value):continue
		# Leave broad cardinal travel lanes between the new resource camps.
		if absf(p.x)<3 or absf(p.z)<3:continue
		var lush:bool=level==2 and p.x<0
		if i%13==0:
			var transform:=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*rng.randf_range(0.8,1.4)),p)
			if lush:ferns.append(transform)
			elif i%2==0:flowers.append(transform)
			else:rubble.append(Transform3D(transform.basis.scaled(Vector3.ONE*.3),p))
		var height:=rng.randf_range(0.18,0.45)
		for blade in 2:
			var side:=Vector3(cos(angle+blade*PI/2),0,sin(angle+blade*PI/2))*0.05
			var color:=Color("#718657") if lush else (Color("#ad9166") if level==2 else Color("#9caebb"))
			for v in [p-side,p+Vector3(0.07,height,0.03),p+side]:verts.append(v);colors.append(color)
	FortLandscape.instance_asset(grove,"fern",ferns)
	FortLandscape.instance_asset(grove,"wildflowers",flowers)
	FortLandscape.instance_asset(grove,"moss_rock",rubble)
	if level==2:FortForestry.add_edge_woods(world)
	FortFoliage.populate(grove,world,74 if level==2 else 154,152 if level==2 else 240,1200+level,"frontier" if level==2 else "frost")
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_COLOR]=colors
	var grass:=MeshInstance3D.new();var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);grass.mesh=mesh
	var material:=ShaderMaterial.new();material.shader=preload("res://assets/shaders/meadow_grass.gdshader");grass.material_override=material;grove.add_child(grass)
