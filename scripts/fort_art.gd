class_name FortArt
extends RefCounted

const STONE := Color("#616875")
const DARK := Color("#323c49")
const WOOD := Color("#775137")
const TRIM := Color("#c59b5d")
const TEAL := Color("#347c7a")

static var exporting := false
static var dwarf_palette:Dictionary = {}
static var swarm_meshes:Dictionary = {}
static var scene_cache:Dictionary = {}

static func asset(key: String) -> Node3D:
	if exporting: return null
	var path := "res://assets/models/fort/" + key + ".glb"
	if not ResourceLoader.exists(path): return null
	if not scene_cache.has(path):scene_cache[path]=load(path)
	var model:Node3D=(scene_cache[path] as PackedScene).instantiate()
	if key in ["raider","brute","sapper","ashwing","emberrunner","chieftain","sapper7","cinderlobber","bombwing","shieldguard","prowler","hexer","colossus","razorback","direwolf","stonebear","emberdrake","frostwyrm"] and ProjectSettings.get_setting("rendering/renderer/rendering_method")=="gl_compatibility":
		_compatibility_palette(model)
	return model

static func _compatibility_palette(node:Node)->void:
	# glTF colors are linear. Compatibility renders vertex colors as supplied,
	# unlike the linear-light renderers: convert once per shared mesh for this backend.
	if node is MeshInstance3D:
		var original:Mesh=node.mesh
		var key:=original.get_instance_id()
		if not swarm_meshes.has(key):
			var converted:=ArrayMesh.new()
			for surface in original.get_surface_count():
				var arrays:=original.surface_get_arrays(surface)
				var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
				for i in colors.size():colors[i]=colors[i].linear_to_srgb()
				arrays[Mesh.ARRAY_COLOR]=colors
				converted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				converted.surface_set_material(surface,original.surface_get_material(surface))
			swarm_meshes[key]=converted
		node.mesh=swarm_meshes[key]
	for child in node.get_children():_compatibility_palette(child)

static func strip_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			node.remove_child(child)
			child.free()
		else:
			strip_meshes(child)

static func clear_scene_owner(node:Node)->void:
	node.owner=null
	for child in node.get_children():clear_scene_owner(child)

static func replace_meshes(node: Node3D, key: String) -> void:
	var model := asset(key)
	if model == null: return
	strip_meshes(node)
	var old_turret := node.get_node_or_null("Turret")
	if old_turret: old_turret.name = "OldPivot"
	node.add_child(model)
	if key == "hearthhold":
		var old_flames := model.find_child("HearthFire*", true, false)
		if old_flames:
			old_flames.get_parent().remove_child(old_flames)
			old_flames.free()
		for replacement in ["workshop", "stockpile"]:
			var old := model.find_child(replacement.capitalize()+"*", true, false)
			var detail := asset(replacement)
			if old and detail:
				var old_parent: Node = old.get_parent()
				old_parent.add_child(detail)
				detail.transform = old.transform
				old_parent.remove_child(old)
				old.free()
			elif detail: detail.free()
	var pivot := model.find_child("Turret*", true, false)
	if pivot:
		var pose: Transform3D = pivot.transform
		var ancestor: Node = pivot.get_parent()
		while ancestor != node:
			if ancestor is Node3D: pose = ancestor.transform * pose
			ancestor = ancestor.get_parent()
		pivot.owner = null
		pivot.reparent(node, false)
		pivot.transform = pose
		pivot.name = "Turret"

static func tint_dwarf(node: Node, role: int) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(i)
			if not original is StandardMaterial3D: continue
			var cache_key := "%d/%s" % [role, original.resource_name]
			if dwarf_palette.has(cache_key):
				node.set_surface_override_material(i,dwarf_palette[cache_key])
				continue
			var mat: StandardMaterial3D = original.duplicate()
			var key := original.resource_name
			if key == "MAT_Tunic": mat.albedo_color = GameData.class_data(role).color.darkened(0.16)
			elif key == "MAT_Dark_Steel": mat.albedo_color = GameData.class_data(role).color.darkened(0.55)
			elif key == "MAT_Beard": mat.albedo_color = [Color("#894f2c"), Color("#b0aaa0"), Color("#50372e"), Color("#cda558")][role]
			elif key == "MAT_Beard_Highlight": mat.albedo_color = [Color("#b67941"), Color("#ddd0ae"), Color("#80583b"), Color("#ead096")][role]
			elif key == "MAT_Steel": mat.albedo_color = Color("#8a9ea9")
			mat.metallic = 0.15
			mat.roughness = 0.86
			dwarf_palette[cache_key] = mat
			node.set_surface_override_material(i, mat)
	for child in node.get_children(): tint_dwarf(child, role)

static func cone(radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 5
	return Visuals.mesh_node(mesh, color, pos)

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> MeshInstance3D:
	var node := Visuals.box(Vector3(width, a.distance_to(b), width), color, (a + b) * 0.5)
	var direction := (b - a).normalized()
	node.quaternion = Quaternion(Vector3.UP, direction)
	parent.add_child(node)
	return node

static func box_collider(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	Visuals.add_static_collision(parent, shape, pos)

static func crystal(parent: Node3D, pos: Vector3, height := 1.0, color := Color("#70ded0")) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var rock := cone(height * 0.23, height, color, Vector3(0, height * 0.5, 0))
	rock.material_override = Visuals.material(color, 0.65, color * 0.20)
	root.add_child(rock)
	return root

static func lantern(parent: Node3D, pos: Vector3, light := true) -> void:
	parent.add_child(Visuals.cylinder(0.12, 1.9, WOOD, pos + Vector3(0, 0.95, 0)))
	parent.add_child(Visuals.box(Vector3(0.4,0.5,0.4), DARK, pos + Vector3(0,1.9,0)))
	var glow := Visuals.box(Vector3(0.28,0.32,0.42),Color("#ffd77d"),pos + Vector3(0,1.9,0))
	glow.material_override = Visuals.material(Color("#ffd77d"), 0.9, Color("#dc862f"))
	parent.add_child(glow)
	parent.add_child(cone(0.35,0.3,DARK,pos+Vector3(0,2.28,0)))
	if light:
		var lamp := OmniLight3D.new()
		lamp.position = pos + Vector3(0,2,0)
		lamp.light_color = Color("#ffba68")
		lamp.light_energy = 0.55
		lamp.omni_range = 7
		parent.add_child(lamp)

static func make_fort(parent: Node3D) -> void:
	var fort := Node3D.new()
	fort.name = "Hearthhold"
	parent.add_child(fort)
	# Flush courtyard: no invisible step blocking a returning dwarf.
	fort.add_child(Visuals.cylinder(9,0.12,Color("#827964"),Vector3(0,-0.04,0)))
	for row in 2:
		for i in 48:
			var angle := (i + row * 0.5) * TAU / 48
			# Four broad entrances with uninterrupted approach paths.
			if abs(sin(angle * 2)) < 0.42: continue
			var block := Visuals.box(Vector3(0.94,0.49,0.60),STONE.lightened(float((i*7)%4)*0.035),Vector3(sin(angle)*8.2,0.25+row*0.49,cos(angle)*8.2))
			block.rotation.y = angle
			fort.add_child(block)
			var wall := Node3D.new()
			wall.position = block.position
			wall.rotation.y = angle
			fort.add_child(wall)
			box_collider(wall,Vector3(0.96,0.49,0.62),Vector3.ZERO)
	for quadrant in 4:
		var root := Node3D.new()
		root.rotation.y = quadrant * PI / 2
		fort.add_child(root)
		for side in [-1,1]:
			root.add_child(Visuals.box(Vector3(0.7,2.35,0.8),DARK,Vector3(side*2.0,1.17,7.9)))
			box_collider(root,Vector3(0.7,2.85,0.8),Vector3(side*2.0,1.42,7.9))
			root.add_child(cone(0.58,0.6,TEAL,Vector3(side*2.0,2.65,7.9)))
			lantern(root,Vector3(side*2.65,0,7.9),quadrant%2==0)
		var banner := Visuals.box(Vector3(0.6,1.05,0.06), TEAL, Vector3(-2.03,1.45,8.34))
		root.add_child(banner)
		root.add_child(Visuals.box(Vector3(0.13,0.42,0.075),TRIM,Vector3(-2.03,1.5,8.38)))
	for i in 12:
		var angle := i*TAU/12
		var block := Visuals.box(Vector3(0.70,0.55,0.45),STONE,Vector3(sin(angle)*1.45,0.27,cos(angle)*1.45))
		block.rotation.y=angle
		fort.add_child(block)
	fort.add_child(Visuals.cylinder(1.2,0.3,DARK,Vector3(0,0.35,0)))
	var hearth := Node3D.new()
	hearth.name = "HearthFire"
	fort.add_child(hearth)
	for i in 7:
		crystal(hearth,Vector3(sin(i*2.4)*0.5,0.5,cos(i*2.4)*0.5),1.0+(i%3)*0.25,Color("#ffa84a"))
	box_collider(fort,Vector3(2.7,0.65,2.7),Vector3(0,0.3,0))
	# Timber stockpile with bands, stacked logs, and an unmistakable gold marker.
	var stock := Node3D.new()
	stock.name="Stockpile"
	stock.position=Vector3(4.6,0,0)
	fort.add_child(stock)
	for i in 3:
		var pos:=Vector3((i-1)*0.75,0.45,0)
		stock.add_child(Visuals.box(Vector3(0.7,0.85,1.1),WOOD,pos))
		for x in [-0.24,0.24]:stock.add_child(Visuals.box(Vector3(0.065,0.89,1.14),TRIM,pos+Vector3(x,0,0)))
	for i in 5:
		var log:=Visuals.cylinder(0.16,1.1,TRIM,Vector3(-0.7+i*0.33,1.0,0))
		log.rotation.x=PI/2
		stock.add_child(log)
	box_collider(stock,Vector3(2.3,0.9,1.2),Vector3(0,0.45,0))
	var stock_sign:=Visuals.label_3d("STOCKPILE\nHOLD E TO DEPOSIT",Color("#efd094"),2.1)
	stock_sign.font_size=30;stock_sign.pixel_size=0.006
	stock.add_child(stock_sign)
	var shop:=Node3D.new()
	shop.name="Workshop"
	shop.position=Vector3(-4.6,0,0)
	fort.add_child(shop)
	for x in [-1.25,1.25]:
		for z in [-0.8,0.8]: shop.add_child(Visuals.box(Vector3(0.17,2.5,0.17),WOOD,Vector3(x,1.25,z)))
	for side in [-1,1]:
		var roof:=Visuals.box(Vector3(1.8,0.18,2.25),TEAL,Vector3(side*0.70,2.8,0))
		roof.rotation.z=side*-0.45
		shop.add_child(roof)
	shop.add_child(Visuals.box(Vector3(2.2,0.16,1.2),TRIM,Vector3(0,0.9,0)))
	shop.add_child(Visuals.box(Vector3(0.9,0.45,0.5),DARK,Vector3(0,1.20,0)))
	shop.add_child(Visuals.box(Vector3(1.3,0.18,0.6),STONE,Vector3(0,1.46,0)))
	box_collider(shop,Vector3(2.3,1.1,1.3),Vector3(0,0.55,0))
	var forge_sign:=Visuals.label_3d("WORKSHOP\nE · WEAPON FORGE",Color("#9ed5c9"),3.45)
	forge_sign.font_size=30;forge_sign.pixel_size=0.006
	shop.add_child(forge_sign)
	replace_meshes(fort, "hearthhold")
	if not exporting:
		hearth.free()
		fort.add_child(FortCampfire.new())

static func make_defense(kind: String, collision := true) -> Node3D:
	var root:=Node3D.new()
	if kind in ["MetalWall","StormSpire","FrostMortar","Embercoil","GravityWell","Sunlance"]:
		var model:=asset(kind.to_lower());root.add_child(model)
		var pivot:Node3D=model.find_child("Turret*",true,false)
		if pivot:
			# Assemble before entering the tree: global transforms are unavailable here.
			var local_transform:=pivot.transform
			var ancestor:Node3D=pivot.get_parent()
			while ancestor!=root:
				local_transform=ancestor.transform*local_transform;ancestor=ancestor.get_parent()
			pivot.owner=null;pivot.reparent(root,false);pivot.transform=local_transform;pivot.name="Turret"
			if kind=="Sunlance":
				var parts:=pivot.get_children();var forward:=Node3D.new();pivot.add_child(forward)
				for part in parts:clear_scene_owner(part);part.reparent(forward,false)
				forward.rotation.y=PI
		if collision:box_collider(root,Vector3(2.8,2.1,0.4) if kind=="MetalWall" else Vector3(1.7,1.7,1.7),Vector3(0,1.05 if kind=="MetalWall" else 0.85,0))
		return root
	if kind == "Watchtower":
		for x in [-0.8,0.8]:
			for z in [-0.8,0.8]:
				root.add_child(Visuals.box(Vector3(0.22,2.6,0.22),WOOD,Vector3(x,1.3,z)))
		beam(root,Vector3(-0.8,0.3,0.8),Vector3(0.8,2.3,0.8),0.13,TRIM)
		beam(root,Vector3(0.8,0.3,0.8),Vector3(-0.8,2.3,0.8),0.13,TRIM)
		root.add_child(Visuals.box(Vector3(2.1,0.18,2.1),WOOD.lightened(0.1),Vector3(0,2.45,0)))
		if collision:box_collider(root,Vector3(1.85,2.4,1.85),Vector3(0,1.2,0))
		var gun:=make_crossbow()
		gun.name="Turret"
		gun.position.y=2.75
		root.add_child(gun)
		if collision:box_collider(root,Vector3(2.1,0.18,2.1),Vector3(0,2.45,0))
	elif kind == "Barricade":
		for i in 7:
			var x:float=(i-3)*0.48
			root.add_child(Visuals.cylinder(0.22,1.1,WOOD,Vector3(x,0.55,0)))
			root.add_child(cone(0.22,0.4,TRIM,Vector3(x,1.3,0)))
		for y in [0.4,0.95]:root.add_child(Visuals.box(Vector3(3.5,0.15,0.12),DARK,Vector3(0,y,0.24)))
		if collision:box_collider(root,Vector3(3.5,1.35,0.55),Vector3(0,0.675,0))
	elif kind == "Ballista":
		for x in [-0.6,0.6]:
			beam(root,Vector3(x,0,0.6),Vector3(x*0.5,1.1,0),0.18,WOOD)
			beam(root,Vector3(x,0,-0.6),Vector3(x*0.5,1.1,0),0.18,WOOD)
		var gun:=make_crossbow()
		gun.name="Turret"
		gun.scale=Vector3.ONE*1.45
		gun.position.y=1.2
		root.add_child(gun)
		if collision:box_collider(root,Vector3(1.4,0.8,1.4),Vector3(0,0.4,0))
	else:
		root.add_child(Visuals.cylinder(0.85,0.35,STONE,Vector3(0,0.175,0)))
		for i in 4:
			var angle:=i*TAU/4
			beam(root,Vector3(sin(angle)*0.65,0.3,cos(angle)*0.65),Vector3(sin(angle)*0.4,1.4,cos(angle)*0.4),0.14,TRIM)
		crystal(root,Vector3(0,0.5,0),1.25)
		if collision:box_collider(root,Vector3(1.4,1.5,1.4),Vector3(0,0.75,0))
	replace_meshes(root, "watchtower7" if kind=="Watchtower" else kind.to_lower())
	if kind=="Watchtower" and not exporting:
		# Hand-weapon sculptures face +Z; fixed defenses use -Z as their aim axis.
		var pivot:Node3D=root.get_node("Turret")
		var parts:=pivot.get_children()
		var forward:=Node3D.new();forward.name="ForwardArt";pivot.add_child(forward)
		for part in parts:
			clear_scene_owner(part);part.reparent(forward,false)
		forward.rotation.y=PI
	return root

static func make_crossbow() -> Node3D:
	var gun:=Node3D.new()
	gun.add_child(Visuals.box(Vector3(0.22,0.24,1.65),WOOD,Vector3(0,0,-0.25)))
	for side in [-1,1]:
		beam(gun,Vector3(0,0,-0.65),Vector3(side*0.88,0,-0.25),0.12,TRIM)
		beam(gun,Vector3(side*0.88,0,-0.25),Vector3(0,0,0.15),0.025,Color("#ded3ae"))
	gun.add_child(Visuals.box(Vector3(0.05,0.06,1.8),STONE.lightened(0.3),Vector3(0,0.16,-0.4)))
	gun.add_child(cone(0.14,0.35,STONE.lightened(0.3),Vector3(0,0.16,-1.35)))
	return gun

static func make_enemy(kind: String) -> Node3D:
	var model := asset("sapper7" if kind=="Sapper" else kind.to_lower())
	if model: return model
	var root:=Node3D.new()
	var skin:=Color("#7c986e") if kind=="Raider" else (Color("#a86f60") if kind=="Brute" else Color("#9c8aab"))
	root.add_child(Visuals.sphere(0.48,skin,Vector3(0,1.0,0)))
	root.add_child(Visuals.box(Vector3(0.7,0.32,0.45),Color("#493d38"),Vector3(0,0.7,0)))
	var head:=Visuals.sphere(0.39,skin.lightened(0.1),Vector3(0,1.62,0))
	head.scale=Vector3(1.1,0.87,0.9)
	root.add_child(head)
	for side in [-1,1]:
		var ear:=cone(0.16,0.48,skin,Vector3(side*0.45,1.69,0))
		ear.rotation.z=-side*PI/2
		root.add_child(ear)
		root.add_child(Visuals.sphere(0.055,Color("#ffc37c"),Vector3(side*0.14,1.65,0.31)))
		var arm:=Node3D.new()
		arm.name="ArmL" if side<0 else "ArmR"
		arm.position=Vector3(side*0.47,1.25,0)
		root.add_child(arm)
		arm.add_child(Visuals.box(Vector3(0.24,0.62,0.27),skin,Vector3(0,-0.27,0)))
		var leg:=Node3D.new()
		leg.name="LegL" if side<0 else "LegR"
		leg.position=Vector3(side*0.22,0.6,0)
		root.add_child(leg)
		leg.add_child(Visuals.box(Vector3(0.25,0.5,0.27),skin.darkened(0.15),Vector3(0,-0.23,0)))
		leg.add_child(Visuals.box(Vector3(0.29,0.18,0.4),Color("#493d38"),Vector3(0,-0.47,0.06)))
	var club:=Node3D.new()
	club.position=Vector3(0,-0.45,0)
	root.get_node("ArmR").add_child(club)
	club.add_child(Visuals.box(Vector3(0.12,0.65,0.12),WOOD,Vector3(0,0.1,0)))
	club.add_child(Visuals.box(Vector3(0.38,0.32,0.35),STONE,Vector3(0,0.5,0)))
	if kind=="Brute":
		root.scale=Vector3.ONE*1.45
		root.add_child(Visuals.box(Vector3(1.1,0.22,0.6),DARK,Vector3(0,1.4,0)))
	if kind=="Sapper":
		root.add_child(Visuals.sphere(0.33,Color("#df854b"),Vector3(0,1.0,-0.45)))
	return root

static func animate_enemy(root: Node3D, time: float, attacking: bool, moving: bool) -> void:
	if not root.has_meta("animation_cache"):root.set_meta("animation_cache",FortPlayer.find_animation(root))
	var anim:AnimationPlayer = root.get_meta("animation_cache")
	if anim:
		var was_attacking: bool = root.get_meta("attacking", false)
		root.set_meta("attacking", attacking)
		if attacking and not was_attacking and anim.has_animation("Attack"):
			anim.play("Attack", 0.08)
		if anim.current_animation in ["Attack", "Hit"] and anim.is_playing(): return
		var clip := "Walk" if moving else "Idle"
		if anim.has_animation(clip):
			if clip != "Attack": anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			if anim.current_animation != clip: anim.play(clip, 0.12)
		return
	var stride:=sin(time*9)*0.6 if moving else sin(time*2)*0.04
	root.get_node("LegL").rotation.x=stride
	root.get_node("LegR").rotation.x=-stride
	root.get_node("ArmL").rotation.x=-stride*0.7
	root.get_node("ArmR").rotation.x=-1.9 if attacking else stride*0.7
	root.position.y=abs(sin(time*9))*0.035 if moving else 0.0

static func make_mount(mode: int) -> Node3D:
	var model := asset("horse" if mode == 1 else "jetpack")
	if model:
		if mode == 1: model.position.y = -0.67
		return model
	var root:=Node3D.new()
	if mode==1:
		root.position.y=-0.67
		var body:=Visuals.sphere(0.5,Color("#8b6041"),Vector3(0,0.78,0))
		body.scale=Vector3(0.88,0.85,1.55)
		root.add_child(body)
		var neck:=Visuals.sphere(0.5,Color("#8b6041"),Vector3(0,1.18,0.48))
		neck.scale=Vector3(0.65,1.1,0.65)
		neck.rotation.x=0.25
		root.add_child(neck)
		var head:=Visuals.sphere(0.4,Color("#a07451"),Vector3(0,1.61,0.72))
		head.scale=Vector3(0.76,0.92,1.1)
		root.add_child(head)
		var muzzle:=Visuals.sphere(0.28,Color("#5e463a"),Vector3(0,1.44,1.02))
		muzzle.scale=Vector3(0.88,0.8,1.2)
		root.add_child(muzzle)
		for i in 5:
			var mane:=Visuals.sphere(0.15,DARK,Vector3(0,1.15+i*0.15,0.22+i*0.045))
			mane.scale=Vector3(0.8,1.15,0.8)
			root.add_child(mane)
		for side in [-1,1]:
			root.add_child(cone(0.10,0.24,WOOD,Vector3(side*0.14,1.86,0.58)))
			root.add_child(Visuals.sphere(0.065,Color("#ded3ae"),Vector3(side*0.26,1.68,0.83)))
			root.add_child(Visuals.sphere(0.043,DARK,Vector3(side*0.3,1.68,0.85)))
			beam(root,Vector3(side*0.27,1.48,0.94),Vector3(side*0.29,1.13,-0.12),0.026,TRIM)
			for end in [-1,1]:
				var leg:=Visuals.box(Vector3(0.14,0.65,0.16),Color("#513c30"),Vector3(side*0.25,0.33,end*0.48))
				leg.name="Leg_%s_%s"%[side,end]
				root.add_child(leg)
		root.add_child(Visuals.box(Vector3(0.80,0.12,0.62),TEAL,Vector3(0,1.06,-0.06)))
		beam(root,Vector3(0,0.97,-0.68),Vector3(0,0.63,-1.05),0.15,DARK)
		beam(root,Vector3(0,0.63,-1.05),Vector3(0,0.28,-1.01),0.12,DARK)
	else:
		for side in [-1,1]:
			root.add_child(Visuals.cylinder(0.13,0.62,DARK,Vector3(side*0.2,1.05,-0.32)))
			root.add_child(Visuals.cylinder(0.15,0.1,TRIM,Vector3(side*0.2,0.76,-0.32)))
			var flame:=cone(0.1,0.48,Color("#88eddb"),Vector3(side*0.2,0.45,-0.32))
			flame.rotation.x=PI
			flame.name="FlameL" if side<0 else "FlameR"
			root.add_child(flame)
	return root

static func animate_mount(root: Node3D, time: float, speed: float, thrust: bool) -> void:
	var anim := FortPlayer.find_animation(root)
	if anim and anim.has_animation("Gallop"):
		anim.get_animation("Gallop").loop_mode = Animation.LOOP_LINEAR
		if anim.current_animation != "Gallop": anim.play("Gallop")
		anim.speed_scale = clampf(speed / 8.0, 0, 2)
	for flame in root.find_children("Flame*", "MeshInstance3D", true, false): flame.visible = thrust
	for child in root.get_children():
		if str(child.name).begins_with("Leg_"):child.rotation.x=sin(time*11+child.position.z*3+child.position.x*5)*minf(speed*0.08,0.7)
		if str(child.name).begins_with("Flame"):child.visible=thrust

static func make_landscape(parent: Node3D) -> void:
	FortLandscape.build_base(parent)
