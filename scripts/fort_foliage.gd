class_name FortFoliage
extends RefCounted

static var blade_mesh:ArrayMesh
static var grass_material:ShaderMaterial

static func clump_mesh()->ArrayMesh:
	if blade_mesh:return blade_mesh
	var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var normals:=PackedVector3Array()
	for i in 5:
		var a:=i*2.399;var side:=Vector3(cos(a),0,sin(a))*.035
		var base:=Vector3(sin(a),0,cos(a))*.09;var lean:=Vector3(sin(a),0,cos(a))*.14
		var mid:=base+Vector3.UP*.25+lean*.22;var tip:=base+Vector3.UP*(.4+i*.027)+lean
		var points:=[base-side,mid-side*.6,base+side,base+side,mid-side*.6,mid+side*.6,mid-side*.6,tip,mid+side*.6]
		for j in points.size():
			vertices.append(points[j]);uv.append(Vector2(0,points[j].y/.51));normals.append(Vector3.UP)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_NORMAL]=normals
	blade_mesh=ArrayMesh.new();blade_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	grass_material=ShaderMaterial.new();grass_material.shader=preload("res://assets/shaders/living_grass.gdshader")
	return blade_mesh

static func clear(_world:FortWorld,p:Vector3,inner:float)->bool:
	if p.length()<12:return false
	if inner<20 and FortLandscape.trail_distance(p)<2.1:return false
	if inner>=20 and (absf(p.x)<3.4 or absf(p.z)<3.4):return false
	return true

static func populate(parent:Node3D,world:FortWorld,inner:float,outer:float,seed_value:int,biome:String)->void:
	if DisplayServer.get_name()=="headless":return # Rendering-only foliage has no gameplay state.
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var mesh:=clump_mesh()
	var flora:=Node3D.new();flora.name="LivingGroundcover";parent.add_child(flora)
	var tint:=Color("#73914c")
	var plant:="woodland_brush";var flowers:="bluebell_patch"
	if biome in ["AMBERWOOD","CINDER WASTES"]:tint=Color("#ac914d");plant="dry_sedge"
	elif biome in ["frost","GLACIER REACH"]:tint=Color("#9daeb0");plant="frost_shrub"
	elif biome=="MYCELIUM HOLLOW":tint=Color("#8e80a3");plant="frost_shrub"
	# Spatial batches can be culled independently; distant biomes don't draw grass.
	var tile:=24.0;var extent:=ceili(outer/tile)
	var clearings:Array=FortProgression.SITES.duplicate()
	clearings.append_array(FortEncounters.layout(world.expedition.seed_value if world.expedition else 0))
	for x in range(-extent,extent):
		for z in range(-extent,extent):
			var center:=Vector3((x+.5)*tile,0,(z+.5)*tile)
			if center.length()>outer+17 or center.length()<inner-17:continue
			var nearby:Array=[]
			for site in clearings:
				if center.distance_to(site.pos)<float(site.get("radius",12))+20:nearby.append(site)
			var poses:Array[Transform3D]=[];var shades:PackedColorArray=[]
			var bushes:Array[Transform3D]=[];var blooms:Array[Transform3D]=[];var litter:Array[Transform3D]=[]
			# Patch density varies smoothly, forming clearings and taller meadow islands.
			for i in 1000:
				var p:=center+Vector3(rng.randf_range(-12,12),.025,rng.randf_range(-12,12))
				if p.length()<inner or p.length()>outer or not clear(world,p,inner):continue
				var blocked:=false
				for site in nearby:
					if p.distance_to(site.pos)<float(site.get("radius",12)):blocked=true;break
				if blocked:continue
				var patch:=sin(p.x*.14+sin(p.z*.09)*2)*cos(p.z*.12)
				if patch<-.45 and i%3!=0:continue
				var color:=tint.lightened(rng.randf_range(0,.13)).darkened(rng.randf_range(0,.18))
				if biome=="frontier" and p.x>0:color=Color("#ab925c")
				var h:=rng.randf_range(.65,1.35)*(1+maxf(0,patch)*.55)
				poses.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(1,h,1)),p-center));shades.append(color)
				if i%47==0:
					var pose:=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.7,1.2)),p-center)
					if i%3==0:blooms.append(pose)
					elif i%3==1:bushes.append(pose)
					else:litter.append(pose)
			if poses.is_empty():continue
			var patch_root:=Node3D.new();patch_root.position=center;flora.add_child(patch_root)
			var batch:=MultiMeshInstance3D.new();batch.name="GrassPatch"
			var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.mesh=mesh;multi.instance_count=poses.size()
			for i in poses.size():multi.set_instance_transform(i,poses[i]);multi.set_instance_color(i,shades[i])
			batch.multimesh=multi;batch.material_override=grass_material;batch.visibility_range_end=105;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;patch_root.add_child(batch)
			FortLandscape.instance_asset(patch_root,plant,bushes)
			FortLandscape.instance_asset(patch_root,flowers,blooms)
			FortLandscape.instance_asset(patch_root,"forest_floor",litter)
			for child in patch_root.get_children():
				if child is GeometryInstance3D and child!=batch:child.visibility_range_end=88;child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
