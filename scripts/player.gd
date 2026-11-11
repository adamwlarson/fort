class_name FortPlayer
extends CharacterBody3D

var peer_id := 1
var display_name := "Dwarf"
var class_id := 0
var role_id:int:
	get:return GameData.role(class_id)
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
var stuck_time:=0.0
## Fort 33: timed boosts from meals, seconds remaining by name. The host owns them.
var buffs:Dictionary={}
var buff_light:OmniLight3D
var step_distance:=0.0
var last_step_position:=Vector3.INF
var was_airborne:=false
var fall_speed:=0.0
var fall_retry:=0.0
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
var xp:=0
var level:=1
var stat_points:=0
var stats:Dictionary={}
var stats_revision:=0

func weapon_power(kind:String)->float:
	return (1.0+(int(weapon_levels.get(kind,1))-1)*.25)*FortStats.damage_multiplier(self)*(1.25 if FortCooking.has(self,"fiery") else 1.0)

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
	class_id = clampi(int(info.get("class", 0)),0,GameData.MAX_PLAYERS-1)
	max_health = GameData.class_data(class_id).hp
	health = max_health
	carry_limit = 26 if role_id == 3 else 18

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
	var dwarf:Node3D=FortArt.dwarf(class_id)
	# The authored rig faces +Z, matching visual_root's movement heading.
	dwarf.rotation.y = 0
	visual_root.add_child(dwarf)
	equipment=FortEquipment.prepare(dwarf)
	FortArt.tint_dwarf(dwarf, class_id)
	animation_player = find_animation(dwarf)
	if animation_player:
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
	position = GameData.spawn_position(class_id)
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
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_TAB:
		# In build mode Tab walks the build categories; otherwise it opens the character sheet.
		if world.local_build_mode and not world.menu_open:world.select_tab(world.build_tab+(-1 if event.shift_pressed else 1))
		else:world.hud.sheet.toggle()
		get_viewport().set_input_as_handled();return
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
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		var step:=-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1
		if world.local_build_mode:world.cycle_build(step)
		elif mounted_ballista<0:world.cycle_weapon(self,step)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("jump"): jump_buffer = 0.15
	if event.is_action_pressed("ability"): world.player_ability(self)
	if event.is_action_pressed("travel"): world.cycle_travel(self)
	if event.is_action_pressed("cycle_weapon"):world.cycle_weapon(self)
	if event.is_action_pressed("build_mode"): world.toggle_build_mode()
	if event.is_action_pressed("rotate_build"): world.build_rotation += PI / 4;world.pieces.turn+=1
	if world.local_build_mode:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode==KEY_X:world.pieces.remove_aimed()
			if event.physical_keycode==KEY_UP:world.pieces.lift=mini(world.pieces.lift+1,6)
			if event.physical_keycode==KEY_DOWN:world.pieces.lift=maxi(world.pieces.lift-1,-6)
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_MIDDLE:world.pieces.remove_aimed()
	if event.is_action_pressed("ready_night"): world.request_action("ready")
	if event.is_action_pressed("interact"):
		world.player_interact(self)
		interact_timer = 0.78
	if event.is_action_pressed("attack"): _try_attack()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_U:world.hud.hearth_menu.open_panel()
		if event.physical_keycode==KEY_K:world.castle.menu.open_nearest()
		if event.physical_keycode==KEY_G:world.hud.upgrade_menu.open_nearest()
		if event.physical_keycode==KEY_0:world.select_build_slot(9)
		if event.physical_keycode in [KEY_PAGEDOWN,KEY_PAGEUP]:world.select_tab(world.build_tab+(1 if event.physical_keycode==KEY_PAGEDOWN else -1) if world.local_build_mode else 0)
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
			world.select_build_slot(int(event.physical_keycode - KEY_1))

## Footfalls on grass and stone, wading through the lakes, and the splash of landing in one.
func _footsteps(grounded:bool,vertical:float)->void:
	if world==null or world.sound==null or health<=0 or mounted_ballista>=0:
		last_step_position=position;return
	if not last_step_position.is_finite():last_step_position=position
	var moved:=Vector2(position.x-last_step_position.x,position.z-last_step_position.z).length()
	last_step_position=position
	var wet:=position.y<FortGround.WATER-.15 and FortGround.wet(position.x,position.z)
	if not grounded:
		was_airborne=true;fall_speed=minf(fall_speed,vertical);return
	if was_airborne:
		was_airborne=false
		if wet and fall_speed<-5.0:FortParticles.wade(world,position,true)
		elif fall_speed<-7.0:world.sound.play_at("step_stone" if position.y>FortGround.height(position.x,position.z)+.3 else "step_grass",position,-3.0,.8)
		fall_speed=0.0;step_distance=0.0
	if moved>1.5:return # A teleport is not a stride.
	step_distance+=moved
	# A dwarf's stride; the pony's is longer.
	if step_distance<(2.6 if travel_mode==1 else 1.75):return
	step_distance=0.0
	if wet:FortParticles.wade(world,position)
	elif travel_mode!=2 or is_local_player():
		var stone:=position.y>FortGround.height(position.x,position.z)+.3
		var pitch:=.8 if travel_mode==1 else 1.0
		if is_local_player():world.sound.play("step_stone" if stone else "step_grass",-14.0)
		else:world.sound.play_at("step_stone" if stone else "step_grass",position,-6.0,pitch,26.0)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0, attack_cooldown - delta)
	ability_cooldown = maxf(0, ability_cooldown - delta)
	rally_time = maxf(0, rally_time - delta)
	action_time = maxf(0, action_time - delta)
	invulnerable = maxf(0, invulnerable - delta)
	down_time = maxf(0, down_time - delta)
	_animate(delta)
	# Glowcap Broth: a soft light that follows the dwarf.
	if FortCooking.has(self,"glowing")!=is_instance_valid(buff_light):
		if is_instance_valid(buff_light):buff_light.queue_free();buff_light=null
		else:
			buff_light=OmniLight3D.new();buff_light.light_color=Color("#7ff0d2");buff_light.light_energy=.9;buff_light.omni_range=9.0;buff_light.position=Vector3(0,1.4,0);add_child(buff_light)
	if not is_local_player():
		position = position.lerp(target_position, 1.0 - exp(-18.0 * delta))
		_footsteps(position.y<=world.castle.floor_at(position)+.25 if world and world.castle else true,velocity.y)
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
			world.player_interact(self,true)
			interact_timer = 0.78*FortStats.gather_multiplier(self)
		if Input.is_action_pressed("repair") and repair_timer <= 0:
			world.player_repair(self)
			repair_timer = 0.65
		if Input.is_action_pressed("attack") and not world.local_build_mode: _try_attack()
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if can_act else Vector2.ZERO
	var forward := aim_direction()
	var right := Vector3(cos(look_yaw), 0, -sin(look_yaw))
	var direction := (right * input.x - forward * input.y).normalized()
	var speed: float = GameData.class_data(class_id).speed*FortStats.speed_multiplier(self)
	speed*=FortCastleFeatures.room_multiplier(world.castle,position,["Stairs"],.1)
	if can_act and Input.is_action_pressed("sprint"): speed *= 1.35
	if aiming():speed*=0.65
	if rally_time > 0: speed *= 1.25
	if travel_mode == 1: speed *= 1.85
	if action_time > 0 and travel_mode == 0: speed *= 0.5
	if FortCooking.has(self,"fleet"): speed *= 1.15
	# Wading through a lake is slower going than the meadow.
	if position.y<FortGround.WATER-.3 and FortGround.wet(position.x,position.z):speed*=.72
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
	else:
		var before:=position
		FortRecovery.step_up(self,Vector3(velocity.x,0,velocity.z)*delta)
		move_and_slide()
		_footsteps(is_on_floor(),velocity.y)
		# A dwarf who slips just under the land is set back on it. Deeper falls use the checked recovery below.
		var land:=FortGround.height(position.x,position.z)
		if position.y<land-.6 and position.y>=land-5.0:position.y=land+.05;velocity.y=0
		if can_act and direction.length_squared()>.1 and position.distance_to(before)<.002:stuck_time+=delta
		else:stuck_time=0
		if stuck_time>2.5:
			stuck_time=0
			if FortRecovery.occupied(world,self,position,true):world.request_action("unstuck_auto")
	var distance_from_hearth:=Vector2(position.x,position.z).length()
	if distance_from_hearth>world.frontier_radius():
		var edge:Vector2=Vector2(position.x,position.z).normalized()*(world.frontier_radius()-0.1)
		position.x=edge.x;position.z=edge.y;velocity.x=0;velocity.z=0
		if world.toast_time<=0:world.show_toast("Edge of the explored land. Upgrade the hearth (U) to travel further.")
	if position.y < FortGround.height(position.x,position.z)-5:
		velocity = Vector3.ZERO
		fall_retry-=delta
		if fall_retry<=0:
			fall_retry=.75;world.send_movement(position,visual_root.rotation.y,velocity);world.request_action("unstuck_fall")
	else:fall_retry=0
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
	if not animation_player: return
	if health <= 0:
		if not animation_player.current_animation in ["Fall","Downed"]:
			animation_player.speed_scale=1.0
			animation_player.play("Fall",0.08);animation_player.queue("Downed")
		return
	if action_time <= 0:
		var ground_speed := Vector2(velocity.x, velocity.z).length()
		var moving := ground_speed > 0.3 if is_local_player() else remote_moving
		var base_speed:float=GameData.class_data(class_id).speed
		var clip := "Idle"
		if moving:clip="Run" if ground_speed>base_speed*1.18 else "Walk"
		if GameData.ranged(weapon) or weapon=="Pike":clip="March" if moving else "Aim"
		if travel_mode == 1:clip="Ride"
		elif absf(velocity.y)>1.6 and not is_on_floor():clip="Air"
		if animation_player.current_animation != clip or not animation_player.is_playing(): animation_player.play(clip, 0.16)
		# Cadence follows ground speed so slowed dwarves (aiming, working) take slower steps.
		if clip=="Walk":animation_player.speed_scale=clampf(ground_speed/6.0,0.55,1.45)
		elif clip=="March":animation_player.speed_scale=clampf(ground_speed/4.0,0.6,1.4)
		elif clip=="Run":animation_player.speed_scale=clampf(ground_speed/8.2,0.8,1.4)
		else:animation_player.speed_scale=1.0
	if is_instance_valid(mount_visual):
		FortArt.animate_mount(mount_visual, Time.get_ticks_msec() * 0.001, Vector2(velocity.x, velocity.z).length(), fuel > 0 and velocity.y > 0)

func _try_attack() -> void:
	if attack_cooldown > 0 or health <= 0: return
	attack_cooldown = GameData.WEAPONS[weapon].cooldown*FortStats.cooldown_multiplier(self)
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
		var clip:="Axe_Swing"
		animation_player.speed_scale=1.65
		if kind=="attack" and weapon=="Pike":
			action_time=.85;clip="Thrust";animation_player.speed_scale=1.0
		elif kind=="attack" and GameData.ranged(weapon):
			action_time=GameData.WEAPONS[weapon].cooldown
			clip="Shoot";animation_player.speed_scale=1.05/action_time
		elif kind=="attack" and weapon in ["Hammer","Greatmaul","Warpick"]:
			action_time=float(GameData.WEAPONS[weapon].cooldown)-.07
			clip="Heavy_Swing";animation_player.speed_scale=.667/maxf(.1,float(GameData.WEAPONS[weapon].windup))
		elif kind=="gather":clip="Gather";animation_player.speed_scale=1.0
		elif kind in ["repair","construct"]:clip="Build";animation_player.speed_scale=1.0
		elif kind=="ability":clip="Cast";animation_player.speed_scale=1.25;action_time=.8
		animation_player.play(clip, 0.06)
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
	_update_equipment_visibility()
	weapon_trim()
	if animation_player:
		animation_player.stop()
		if GameData.ranged(kind) or kind=="Pike":
			animation_player.play("Aim")
			animation_player.seek(0,true)
			animation_player.advance(0)
			var skeleton:Skeleton3D=equipment.skeleton
			# Calibrate to the posed aiming hand so ranged weapons point along the dwarf's facing.
			var held:Basis=skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).basis.orthonormalized()*FortEquipment.grip_basis()
			weapon_visual.basis=held.inverse()
			if kind=="Pike":weapon_visual.basis=weapon_visual.basis*Basis(Vector3.RIGHT,PI/2)

func _update_equipment_visibility()->void:
	if equipment.is_empty():return
	equipment.axe.visible=weapon=="Axe" or showing_tool
	var axe_trim:Node3D=equipment.socket.get_node_or_null("ForgeTrim")
	if axe_trim:axe_trim.visible=weapon=="Axe" or showing_tool
	if is_instance_valid(weapon_visual):weapon_visual.visible=not showing_tool

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
	carry_limit=(26 if role_id==3 else 18)+(GameData.BACKPACKS[backpack_level-1].bonus if backpack_level>0 else 0)
	if world.castle:carry_limit+=world.castle.pack_bonus()
	carry_limit+=FortStats.storage_bonus(self)
	max_health=GameData.class_data(class_id).hp+(40 if ironheart else 0)+FortStats.health_bonus(self)
	armor=ironheart
	if backpack_level>0 and (not is_instance_valid(backpack_visual) or backpack_visual.get_meta("tier",0)!=backpack_level):
		if is_instance_valid(backpack_visual):backpack_visual.queue_free()
		backpack_visual=FortArt.asset("backpack_trail" if backpack_level==1 else "backpack_frame")
		backpack_visual.set_meta("tier",backpack_level);visual_root.add_child(backpack_visual)
	if armor and not is_instance_valid(armor_visual):
		armor_visual=FortArt.asset("armor_ironheart");visual_root.add_child(armor_visual)
	equip_weapon(weapon)
