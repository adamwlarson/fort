class_name FortPlayer
extends CharacterBody3D

var peer_id := 1
var display_name := "Dwarf"
var class_id := 0
var health := 100.0
var max_health := 100.0
var carrying := {"wood":0, "stone":0, "crystal":0}
var carry_limit := 18
var travel_mode := 0
var ability_cooldown := 0.0
var attack_cooldown := 0.0
var rally_time := 0.0
var down_time := 0.0
var invulnerable := 0.0
var mounted_ballista := -1
var look_yaw := 0.0
var look_pitch := -0.40
var visual_root: Node3D
var camera_pivot: Node3D
var camera: Camera3D
var animation_player: AnimationPlayer
var nameplate: Label3D
var gear_root: Node3D
var action_time := 0.0
var interact_timer := 0.0
var repair_timer := 0.0
var send_timer := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
var fuel := 4.0
var target_position := Vector3.ZERO
var target_yaw := 0.0
var remote_moving := false
var dash_time := 0.0
var world: Node3D
var mount_visual: Node3D
var weapon := "Axe"
var owned_weapons:PackedStringArray=["Axe"]
var equipment:Dictionary={}
var weapon_visual:Node3D
var action_kind:=""
var showing_tool:=false
var loadout_revision:=0
var backpack_level:=0
var relics:PackedStringArray=[]
var armor:=false
var progression_revision:=0
var backpack_visual:Node3D
var armor_visual:Node3D
var weapon_asset_key:=""
var work_hammer:Node3D
var weapon_levels:Dictionary={}
var weapon_revision:=0

func weapon_power(kind:String)->float:
	return 1.0+(int(weapon_levels.get(kind,1))-1)*.25

func apply_weapon_levels(levels:Dictionary,revision:int)->void:
	if revision<weapon_revision:return
	weapon_revision=revision;weapon_levels=levels.duplicate()
	weapon_trim()

func weapon_trim()->void:
	var node:Node3D=weapon_visual if is_instance_valid(weapon_visual) else equipment.get("socket")
	if not node:return
	var level:int=weapon_levels.get(weapon,1)
	if int(node.get_meta("forge_level",0))==level:return
	node.set_meta("forge_level",level)
	var old:=node.get_node_or_null("ForgeTrim")
	if old:node.remove_child(old);old.queue_free()
	if level<=1:return
	var trim:=Node3D.new();trim.name="ForgeTrim";node.add_child(trim)
	for i in level:
		var band:=Visuals.box(Vector3(.13,.04,.04),Color("#bfa0ef") if level==3 else Color("#e7bb65"),Vector3(0,.1+i*.07,.07));trim.add_child(band)

func aiming()->bool:
	return is_local_player() and not world.menu_open and health>0 and (mounted_ballista>=0 or (GameData.ranged(weapon) and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)))

func setup(id: int, info: Dictionary) -> void:
	peer_id = id
	display_name = str(info.get("name", "Dwarf"))
	class_id = int(info.get("class", 0))
	max_health = GameData.class_data(class_id).hp
	health = max_health
	carry_limit = 26 if class_id == 3 else 18

func _ready() -> void:
	world = get_parent().get_parent()
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(48)
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	col.shape = capsule
	col.position.y = 0.77
	add_child(col)
	visual_root = Node3D.new()
	add_child(visual_root)
	var dwarf:Node3D=FortArt.asset(["dwarf_vanguard","dwarf_warden","dwarf_engineer","dwarf_ranger"][class_id])
	if not dwarf:dwarf=preload("res://assets/models/dwarf.glb").instantiate()
	# The authored rig faces +Z, matching visual_root's movement heading.
	dwarf.rotation.y = 0
	visual_root.add_child(dwarf)
	equipment=FortEquipment.prepare(dwarf)
	FortArt.tint_dwarf(dwarf, class_id)
	animation_player = find_animation(dwarf)
	if animation_player:
		for clip in ["Idle", "Walk"]:
			animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		animation_player.get_animation("Axe_Swing").loop_mode = Animation.LOOP_NONE
		_add_travel_poses()
		FortEquipment.pose_clips(animation_player)
		animation_player.play("Idle")
	gear_root = Node3D.new()
	visual_root.add_child(gear_root)
	nameplate = Visuals.label_3d(display_name, GameData.class_data(class_id).color.lightened(0.3), 1.95)
	nameplate.font_size = 24
	nameplate.visible = not is_local_player()
	add_child(nameplate)
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.3
	add_child(camera_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 6.2
	arm.margin = 0.25
	arm.collision_mask = 1
	camera_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 66
	camera.near = 0.08
	arm.add_child(camera)
	camera.current = is_local_player()
	if is_local_player(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	position = Vector3((class_id - 1.5) * 0.6, 0.1, 4.8)
	target_position = position
	visual_root.rotation.y = PI
	target_yaw = PI

static func find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := find_animation(child)
		if found: return found
	return null

func is_local_player() -> bool:
	return peer_id == multiplayer.get_unique_id()

func aim_direction() -> Vector3:
	return Vector3(-sin(look_yaw), 0, -cos(look_yaw))

func shot_direction()->Vector3:
	return FortAim.camera_direction(world,self)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player() or world.ended: return
	if event.is_action_pressed("cancel"):
		if world.local_build_mode: world.toggle_build_mode()
		else: world.toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if world.menu_open: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_yaw -= event.relative.x * world.mouse_sensitivity
		look_pitch = clampf(look_pitch - event.relative.y * world.mouse_sensitivity, -1.05, 0.75)
	if health <= 0: return
	if event.is_action_pressed("jump"): jump_buffer = 0.15
	if event.is_action_pressed("ability"): world.player_ability(self)
	if event.is_action_pressed("travel"): world.cycle_travel(self)
	if event.is_action_pressed("cycle_weapon"):world.cycle_weapon(self)
	if event.is_action_pressed("build_mode"): world.toggle_build_mode()
	if event.is_action_pressed("rotate_build"): world.build_rotation += PI / 4
	if event.is_action_pressed("ready_night"): world.request_action("ready")
	if event.is_action_pressed("interact"):
		world.player_interact(self)
		interact_timer = 0.78
	if event.is_action_pressed("attack"): _try_attack()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_U:world.hud.hearth_menu.open_panel()
		if event.physical_keycode==KEY_K:world.castle.menu.open_nearest()
		if event.physical_keycode==KEY_G:world.hud.upgrade_menu.open_nearest()
		if event.physical_keycode==KEY_0:world.select_build(9)
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
			world.select_build(int(event.physical_keycode - KEY_1))

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0, attack_cooldown - delta)
	ability_cooldown = maxf(0, ability_cooldown - delta)
	rally_time = maxf(0, rally_time - delta)
	action_time = maxf(0, action_time - delta)
	invulnerable = maxf(0, invulnerable - delta)
	down_time = maxf(0, down_time - delta)
	_animate(delta)
	if not is_local_player():
		position = position.lerp(target_position, 1.0 - exp(-18.0 * delta))
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, 1.0 - exp(-18.0 * delta))
		return
	camera_pivot.rotation = Vector3(look_pitch, look_yaw, 0)
	camera.fov=lerpf(camera.fov,56.0 if aiming() else 66.0,1-exp(-8*delta))
	camera.h_offset=lerpf(camera.h_offset,.85 if GameData.ranged(weapon) or mounted_ballista>=0 else 0.0,1-exp(-8*delta))
	var can_act: bool = not world.menu_open and not world.ended and health > 0
	if can_act:
		interact_timer -= delta
		repair_timer -= delta
		if Input.is_action_pressed("interact") and interact_timer <= 0 and mounted_ballista < 0:
			world.player_interact(self)
			interact_timer = 0.78
		if Input.is_action_pressed("repair") and repair_timer <= 0:
			world.player_repair(self)
			repair_timer = 0.65
		if Input.is_action_pressed("attack") and not world.local_build_mode: _try_attack()
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if can_act else Vector2.ZERO
	var forward := aim_direction()
	var right := Vector3(cos(look_yaw), 0, -sin(look_yaw))
	var direction := (right * input.x - forward * input.y).normalized()
	var speed: float = GameData.class_data(class_id).speed
	if can_act and Input.is_action_pressed("sprint"): speed *= 1.35
	if aiming():speed*=0.65
	if rally_time > 0: speed *= 1.25
	if travel_mode == 1: speed *= 1.85
	if action_time > 0 and travel_mode == 0: speed *= 0.5
	dash_time = maxf(0, dash_time - delta)
	if dash_time > 0:
		direction = forward
		speed = 22.0
	velocity.x = move_toward(velocity.x, direction.x * speed, 32.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 32.0 * delta)
	coyote_time = 0.12 if is_on_floor() else maxf(0, coyote_time - delta)
	jump_buffer = maxf(0, jump_buffer - delta)
	if is_on_floor(): fuel = minf(4.0, fuel + delta * 1.4)
	if travel_mode == 2 and can_act and Input.is_action_pressed("jump") and fuel > 0:
		fuel -= delta
		velocity.y = move_toward(velocity.y, 6.8, 22.0 * delta)
	else:
		velocity.y -= 24.0 * delta
		if jump_buffer > 0 and coyote_time > 0 and can_act:
			velocity.y = 8.3
			jump_buffer = 0
			coyote_time = 0
	if mounted_ballista >= 0: velocity = Vector3.ZERO
	else: move_and_slide()
	var distance_from_hearth:=Vector2(position.x,position.z).length()
	if distance_from_hearth>world.frontier_radius():
		var edge:Vector2=Vector2(position.x,position.z).normalized()*(world.frontier_radius()-0.1)
		position.x=edge.x;position.z=edge.y;velocity.x=0;velocity.z=0
		if world.toast_time<=0:world.show_toast("The hearth ward ends here. Upgrade at the hearth (U) to explore further.")
	if position.y < -5:
		position = Vector3(0, 0.3, 5)
		velocity = Vector3.ZERO
	if aiming():visual_root.rotation.y=lerp_angle(visual_root.rotation.y,atan2(forward.x,forward.z),1-exp(-18*delta))
	elif direction.length_squared() > 0.01 and action_time <= 0:
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-16.0 * delta))
	send_timer -= delta
	if send_timer <= 0:
		send_timer = 0.05
		world.send_movement(position, visual_root.rotation.y, velocity)

func _animate(delta: float) -> void:
	var use_tool:bool=action_time>0 and action_kind in ["gather","repair","ability","construct"]
	if use_tool!=showing_tool:
		showing_tool=use_tool
		_update_equipment_visibility()
	if is_instance_valid(work_hammer):
		if work_hammer.visible and not (action_time>0 and action_kind=="construct"):_update_equipment_visibility()
		work_hammer.visible=action_time>0 and action_kind=="construct"
		if work_hammer.visible:equipment.axe.visible=false
	if GameData.ranged(weapon) and is_instance_valid(weapon_visual):
		var ammo:=weapon_visual.find_child("LoadedAmmo*",true,false)
		if ammo:ammo.visible=not (action_kind=="attack" and action_time>0.22 and action_time<0.93)
	visual_root.rotation.z = lerp_angle(visual_root.rotation.z, PI * 0.45 if health <= 0 else 0.0, delta * 8)
	if not animation_player: return
	if health <= 0:
		animation_player.pause()
		return
	if action_time <= 0:
		var moving := Vector2(velocity.x, velocity.z).length() > 0.3 if is_local_player() else remote_moving
		var clip := "Walk" if moving and travel_mode != 1 else "Idle"
		if GameData.ranged(weapon) or weapon=="Pike":clip="crossbow/March" if moving else "crossbow/Aim"
		if travel_mode == 1:clip="poses/Ride"
		elif absf(velocity.y)>0.7:clip="poses/Air"
		if animation_player.current_animation != clip or not animation_player.is_playing(): animation_player.play(clip, 0.14)
		animation_player.speed_scale = clampf(Vector2(velocity.x, velocity.z).length() / 3.8, 0.85, 1.8) if clip == "Walk" else 1.0
	if is_instance_valid(mount_visual):
		FortArt.animate_mount(mount_visual, Time.get_ticks_msec() * 0.001, Vector2(velocity.x, velocity.z).length(), fuel > 0 and velocity.y > 0)

func _try_attack() -> void:
	if attack_cooldown > 0 or health <= 0: return
	attack_cooldown = GameData.WEAPONS[weapon].cooldown
	if world.local_build_mode:
		world.place_build()
	elif mounted_ballista >= 0:
		world.request_action("ballista", {"direction": shot_direction()})
	else:
		visual_root.rotation.y = atan2(aim_direction().x, aim_direction().z)
		world.player_attack(self, shot_direction() if GameData.ranged(weapon) else aim_direction())

func play_action(kind: String) -> void:
	if health <= 0: return
	action_time = 0.70
	action_kind=kind
	if kind=="construct" and not is_instance_valid(work_hammer):
		work_hammer=FortArt.asset("weapon_hammer");equipment.socket.add_child(work_hammer)
	if animation_player:
		if kind=="attack" and weapon=="Pike":
			action_time=.85;animation_player.speed_scale=1.0;animation_player.play("pike/Thrust",.04);animation_player.seek(0,true);return
		if kind=="attack" and GameData.ranged(weapon):
			action_time=GameData.WEAPONS[weapon].cooldown
			animation_player.speed_scale=1.05/action_time
			animation_player.play("crossbow/Shoot",0.04)
			animation_player.seek(0,true)
			return
		animation_player.speed_scale = 1.65 if kind != "ability" else 1.35
		if kind=="attack" and weapon in ["Hammer","Greatmaul","Warpick"]:
			action_time=float(GameData.WEAPONS[weapon].cooldown)-.07
			animation_player.speed_scale=.65/maxf(.1,float(GameData.WEAPONS[weapon].windup))
		animation_player.play("Axe_Swing", 0.06)
		animation_player.seek(0, true)

func equip_weapon(kind:String)->void:
	if not GameData.WEAPONS.has(kind):return
	var asset_key:="weapon_"+kind.to_lower()
	if kind=="Hammer" and "Embermaul" in relics:asset_key="embermaul"
	if kind=="Crossbow" and "Stormstring" in relics:asset_key="stormstring"
	if kind==weapon and asset_key==weapon_asset_key:return
	weapon=kind
	weapon_asset_key=asset_key
	if is_instance_valid(weapon_visual):
		weapon_visual.get_parent().remove_child(weapon_visual)
		weapon_visual.queue_free()
	weapon_visual=null
	if kind!="Axe":
		weapon_visual=FortArt.asset(asset_key)
		equipment.socket.add_child(weapon_visual)
		# hand.R's rest basis is X right, Y down, Z backward.
		weapon_visual.rotation.x=PI if GameData.ranged(kind) else 0.0
	_update_equipment_visibility()
	weapon_trim()
	if animation_player:
		animation_player.stop()
		if GameData.ranged(kind) or kind=="Pike":
			animation_player.play("crossbow/Aim")
			animation_player.seek(0,true)
			animation_player.advance(0)
			var skeleton:Skeleton3D=equipment.skeleton
			# Calibrate the grip to the actual posed hand, not an assumed bone roll.
			weapon_visual.basis=skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).basis.inverse()
			if kind=="Pike":weapon_visual.basis=weapon_visual.basis*Basis(Vector3.RIGHT,PI/2)

func _update_equipment_visibility()->void:
	if equipment.is_empty():return
	equipment.axe.visible=weapon=="Axe" or showing_tool
	var axe_trim:Node3D=equipment.socket.get_node_or_null("ForgeTrim")
	if axe_trim:axe_trim.visible=weapon=="Axe" or showing_tool
	if is_instance_valid(weapon_visual):weapon_visual.visible=not showing_tool

func _add_travel_poses()->void:
	var library:=AnimationLibrary.new()
	var source:=animation_player.get_animation("Idle")
	for pose_name in ["Air","Ride"]:
		var pose:=Animation.new()
		pose.length=0.8
		pose.loop_mode=Animation.LOOP_LINEAR
		for track in source.get_track_count():
			var index:=pose.add_track(source.track_get_type(track))
			pose.track_set_path(index,source.track_get_path(track))
			var value:Variant=source.track_get_key_value(track,0)
			if source.track_get_type(track)==Animation.TYPE_ROTATION_3D:
				var bone:=str(source.track_get_path(track)).get_slice(":",1)
				var angle:=0.0
				if bone.begins_with("thigh"):angle=-0.65 if pose_name=="Air" else -1.0
				if bone.begins_with("shin"):angle=0.85
				if bone.begins_with("upper_arm"):angle=-0.32
				value=value*Quaternion(Vector3.RIGHT,angle)
			pose.track_insert_key(index,0,value)
		library.add_animation(pose_name,pose)
	animation_player.add_animation_library("poses",library)

func set_travel_mode(mode: int) -> void:
	if travel_mode == mode: return
	travel_mode = mode
	if is_instance_valid(mount_visual):
		mount_visual.get_parent().remove_child(mount_visual)
		mount_visual.queue_free()
	mount_visual = null
	visual_root.position.y = 0.65 if mode == 1 else 0.0
	if mode > 0:
		mount_visual = FortArt.make_mount(mode)
		gear_root.add_child(mount_visual)

func set_health(value: float) -> void:
	health = clampf(value, 0, max_health)

func total_carried() -> int:
	var total:=0
	for amount in carrying.values():total+=int(amount)
	return total

func apply_progression(pack_level:int,items:PackedStringArray,ironheart:bool,revision:int)->void:
	if revision<progression_revision:return
	progression_revision=revision
	relics=items.duplicate()
	backpack_level=clampi(pack_level,0,2)
	carry_limit=(26 if class_id==3 else 18)+(GameData.BACKPACKS[backpack_level-1].bonus if backpack_level>0 else 0)
	if world.castle:carry_limit+=world.castle.pack_bonus()
	max_health=GameData.class_data(class_id).hp+(40 if ironheart else 0)
	armor=ironheart
	if backpack_level>0 and (not is_instance_valid(backpack_visual) or backpack_visual.get_meta("tier",0)!=backpack_level):
		if is_instance_valid(backpack_visual):backpack_visual.queue_free()
		backpack_visual=FortArt.asset("backpack_trail" if backpack_level==1 else "backpack_frame")
		backpack_visual.set_meta("tier",backpack_level);visual_root.add_child(backpack_visual)
	if armor and not is_instance_valid(armor_visual):
		armor_visual=FortArt.asset("armor_ironheart");visual_root.add_child(armor_visual)
	equip_weapon(weapon)
