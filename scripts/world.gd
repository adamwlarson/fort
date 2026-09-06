class_name FortWorld
extends Node3D

signal return_to_menu(reason: String)

const DAY_LENGTH := 150.0
const NIGHT_LENGTH := 85.0
const FINAL_WAVE := 10
const PlayerScript = preload("res://scripts/player.gd")
const HUDScript = preload("res://scripts/fort_hud.gd")
const SoundScript = preload("res://scripts/fort_sound.gd")

var players: Dictionary = {}
var resource_nodes: Dictionary = {}
var tree_burst_count := 0
var enemies: Dictionary = {}
var defenses: Dictionary = {}
var shared := {"wood":48,"stone":28,"crystal":0,"iron":0,"aether":0}
var lifetime_crystal := 0
var workshop_level := 1
var fort_health := 1000.0
var fort_max_health := 1000.0
var hearth_level := 1
var frontier: FortFrontier
var raid_spawned := 0
var progression:FortProgression
var construction:FortConstruction
var battlements:FortBattlements
var raiders:FortRaidcraft
var director:FortRaidDirector
var expedition:FortExpedition
var pets:FortPets
var encounters:FortEncounters
var solo_rescue_wave:=-1
var is_night := false
var wave := 0
var phase_time := DAY_LENGTH
var next_enemy_id := 1
var next_defense_id := 1
var snapshot_timer := 0.0
var defense_timer := 0.0
var ended := false
var local_build_mode := false
var selected_build := 0
var menu_open := false
var forge_open := false
var mouse_sensitivity := 0.0025
var build_rotation := 0.0
var build_position := Vector3.ZERO
var preview: Node3D
var preview_kind := ""
var preview_valid := false
var toast_text := ""
var toast_time := 0.0
var clock := 0.0
var cooldowns: Dictionary = {}
var delayed_hits: Array[Dictionary] = []
var ready_votes: Dictionary = {}
var revive_progress: Dictionary = {}
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sun: DirectionalLight3D
var player_root: Node3D
var enemy_root: Node3D
var defense_root: Node3D
var resource_root: Node3D
var scenery_keepouts: Array[Dictionary] = []
var hud: FortHUD
var sound: FortSound
var focused_resource := -1
var focus_ring: MeshInstance3D
var focus_label: Label3D

func _ready() -> void:
	player_root = _root("Players")
	enemy_root = _root("Enemies")
	defense_root = _root("Defenses")
	resource_root = _root("Resources")
	_build_environment()
	FortArt.make_landscape(self)
	FortArt.make_fort(self)
	_build_resources()
	FortLandscape.populate(self)
	frontier = FortFrontier.new()
	expedition=FortExpedition.new(self)
	pets=FortPets.new(self)
	add_child(frontier)
	progression=FortProgression.new(self)
	construction=FortConstruction.new(self)
	battlements=FortBattlements.new(self)
	raiders=FortRaidcraft.new(self)
	director=FortRaidDirector.new(self)
	progression.unlock_zones(1)
	encounters=FortEncounters.new(self)
	encounters.unlock(1)
	var ring_mesh:=TorusMesh.new()
	ring_mesh.inner_radius=0.87
	ring_mesh.outer_radius=0.92
	ring_mesh.rings=32
	ring_mesh.ring_segments=6
	focus_ring=Visuals.mesh_node(ring_mesh,Color("#edca7b"))
	focus_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(focus_ring.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(focus_ring)
	focus_label=Visuals.label_3d("",Color("#edca7b"),0)
	focus_label.font_size=24
	focus_label.pixel_size=0.007
	focus_label.no_depth_test=true
	add_child(focus_label)
	focus_ring.hide()
	focus_label.hide()
	sound = SoundScript.new()
	add_child(sound)
	hud = HUDScript.new()
	add_child(hud)
	show_toast("Welcome to Hearthhold. Hold E to gather; return your pack to the stockpile.",6)

func _root(title: String) -> Node3D:
	var node:=Node3D.new()
	node.name=title
	add_child(node)
	return node

func _build_environment() -> void:
	var env:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_SKY
	var sky:=Sky.new()
	sky_material=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("#57818c")
	sky_material.sky_horizon_color=Color("#b5c0ad")
	sky_material.ground_horizon_color=Color("#778f76")
	sky_material.ground_bottom_color=Color("#2c443b")
	sky_material.sun_angle_max=2.0
	sky.sky_material=sky_material
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("#b2c3d1")
	environment.ambient_light_energy=0.3
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled=true
	environment.fog_density=0.003
	env.environment=environment
	add_child(env)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-32,0)
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=90
	sun.light_angular_distance=0.8
	add_child(sun)

func _build_resources() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=884422
	var id:=0
	for kind in ["wood","stone","crystal"]:
		var count:=48 if kind=="wood" else (24 if kind=="stone" else 18)
		for i in count:
			var pos:=FortLandscape.resource_position(rng,kind,i,count,resource_nodes)
			var node:=Node3D.new()
			node.position=pos
			resource_root.add_child(node)
			var anim:AnimationPlayer
			if kind=="wood":
				var tree:Node3D=FortArt.asset(["elder_oak","pine_tree","birch_tree"][i%3])
				tree.scale=Vector3.ONE*rng.randf_range(0.95,1.30)
				tree.rotation.y=rng.randf_range(0,TAU)
				node.add_child(tree)
				anim=FortPlayer.find_animation(tree)
				if anim:
					anim.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR
					anim.play("Idle")
					anim.seek(rng.randf_range(0,2))
					anim.animation_finished.connect(func(clip):
						if clip=="Hit":anim.play("Idle",0.15))
				if i%3!=0:_tint_tree(tree)
				var trunk:=StaticBody3D.new()
				trunk.name="TreeTrunk"
				trunk.collision_layer=1
				node.add_child(trunk)
				var shape:=CollisionShape3D.new()
				var cylinder:=CylinderShape3D.new()
				cylinder.radius=0.24;cylinder.height=1.8
				shape.shape=cylinder;shape.position.y=0.9
				trunk.add_child(shape)
			elif kind=="stone":
				node.add_child(FortArt.asset(["stone_outcrop_a","stone_outcrop_b","stone_outcrop_c"][i%3]))
				node.rotation.y=float(i)*2.399
			else:
				node.add_child(FortArt.asset("crystal_vein"))
				node.rotation.y=float(i)*2.399
			resource_nodes[id]={"kind":kind,"amount":12 if kind!="crystal" else 6,"node":node,"animation":anim,"respawn":0.0}
			if kind=="wood":resource_nodes[id].species=["Elder Oak","March Pine","Silver Birch"][i%3]
			id+=1

func _tint_tree(node:Node)->void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var source:Material=node.mesh.surface_get_material(i)
			if source is StandardMaterial3D and "Leaves" in source.resource_name:
				var mat:StandardMaterial3D=source.duplicate()
				mat.albedo_color=Color("#567b52") if source.resource_name=="MAT_Leaves" else (Color("#839951") if source.resource_name.ends_with("Light") else Color("#365d4b"))
				node.set_surface_override_material(i,mat)
	for child in node.get_children():_tint_tree(child)

# Network packets travel through Main, which exists before any world loads.
# Only acknowledged peers receive broadcasts, and dispatch has a fixed allowlist.
func broadcast(method:String,args:Array=[]) -> void:
	if get_parent().has_method("broadcast_world"):
		get_parent().broadcast_world(method,args)
	else:
		receive(method,args)

func receive(method:String,args:Array) -> void:
	if method not in ["recv_player","recv_remove_player","recv_snapshot","recv_full","recv_resource","recv_defense","recv_remove_defense","recv_enemy","recv_enemy_hit","recv_enemy_dead","recv_action","recv_fx","recv_notice","recv_phase","recv_health","recv_teleport","recv_mount","recv_end","recv_loadout"]:return
	callv(method,args)

func request_action(kind:String,data:Dictionary={}) -> void:
	if ended:return
	if multiplayer.is_server():server_action(multiplayer.get_unique_id(),kind,data)
	else:get_parent().submit_action.rpc_id(1,kind,data)

func send_movement(pos:Vector3,yaw:float,motion:Vector3) -> void:
	if multiplayer.is_server():return
	if get_parent().has_method("submit_movement"):
		get_parent().submit_movement.rpc_id(1,pos,yaw,motion)

func accept_movement(id:int,pos:Vector3,yaw:float,motion:Vector3) -> void:
	if not players.has(id) or not pos.is_finite() or not motion.is_finite() or not is_finite(yaw):return
	var p:FortPlayer=players[id]
	if p.health<=0 or p.mounted_ballista>=0:return
	if pos.distance_to(p.position)>5.0 or Vector2(pos.x,pos.z).length()>frontier_radius()+1 or pos.y>35:return
	p.position=pos
	p.target_position=pos
	p.target_yaw=yaw
	p.visual_root.rotation.y=yaw
	p.velocity=motion.limit_length(35)
	p.remote_moving=Vector2(motion.x,motion.z).length()>0.2

func add_network_player(id:int,info:Dictionary) -> void:
	recv_player(id,info)

func prepare_network_player(id:int,info:Dictionary) -> void:
	recv_player(id,info)

func recv_player(id:int,info:Dictionary) -> void:
	if players.has(id):return
	var player:=PlayerScript.new()
	player.name=str(id)
	player.setup(id,info)
	player_root.add_child(player)
	players[id]=player
	if multiplayer.is_server() and progression:progression.grant_loot(player)
	if multiplayer.is_server() and encounters:encounters.grant_loot(player)
	if multiplayer.is_server() and expedition and expedition.bosses_defeated>0:
		var owned:PackedStringArray=player.owned_weapons.duplicate()
		if "Runeblade" not in owned:owned.append("Runeblade")
		recv_loadout(id,owned,player.weapon,player.loadout_revision+1)

func remove_network_player(id:int) -> void:
	broadcast("recv_remove_player",[id])

func recv_remove_player(id:int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	ready_votes.erase(id)
	for d in defenses.values():
		if d.occupant==id:d.occupant=-1

func local_player() -> FortPlayer:
	return players.get(multiplayer.get_unique_id())

func snapshot() -> Dictionary:
	var roster:Dictionary={}
	for id in players:
		var p:FortPlayer=players[id]
		roster[id]={"pos":p.position,"yaw":p.visual_root.rotation.y,"velocity":p.velocity,"health":p.health,"carry":p.carrying.duplicate(),"travel":p.travel_mode,"ability":p.ability_cooldown,"down":p.down_time,"mount":p.mounted_ballista,"rally":p.rally_time}
		roster[id].merge({"weapon":p.weapon,"owned":p.owned_weapons,"loadout_revision":p.loadout_revision})
		roster[id].merge({"weapon_levels":p.weapon_levels,"weapon_revision":p.weapon_revision})
		roster[id].merge({"pack_level":p.backpack_level,"relics":p.relics,"armor":p.armor,"progression_revision":p.progression_revision})
	var swarm:Dictionary={}
	for id in enemies:
		var e:Dictionary=enemies[id]
		swarm[id]={"pos":e.node.position,"yaw":e.node.rotation.y,"hp":e.hp,"attack":e.attack}
	var buildings:Dictionary={}
	for id in defenses:
		buildings[id]={"hp":defenses[id].hp,"max_hp":defenses[id].max_hp,"level":defenses[id].get("level",1)}
		buildings[id].merge(FortConstruction.state(defenses[id]))
		buildings[id]["aim"]=defenses[id].get("aim",Vector3.FORWARD.rotated(Vector3.UP,defenses[id].node.rotation.y))
	return {"players":roster,"enemies":swarm,"defenses":buildings,"shared":shared.duplicate(),"level":workshop_level,"crystals":lifetime_crystal,"fort":fort_health,"night":is_night,"wave":wave,"time":phase_time,"votes":ready_votes.size(),"hearth_level":hearth_level,"raid_spawned":raid_spawned,"progression":progression.state(),"raid":director.state(),"solo_rescue_wave":solo_rescue_wave,"expedition":expedition.state(),"pets":pets.state(),"encounters":encounters.state()}

func full_state() -> Dictionary:
	var state:=snapshot()
	var resources:Dictionary={}
	for id in resource_nodes:resources[id]=resource_nodes[id].amount
	state["resources"]=resources
	var buildings:Array=[]
	for id in defenses:
		var d:Dictionary=defenses[id]
		buildings.append([id,d.kind,d.node.position,d.node.rotation.y,d.max_hp,d.temporary])
	state["buildings"]=buildings
	var swarm:Array=[]
	for id in enemies:
		var e:Dictionary=enemies[id]
		swarm.append([id,e.kind,e.node.position,e.max_hp,e.get("camp",-1)])
	state["swarm"]=swarm
	state["ended"]=ended
	state["victory"]=fort_health>0
	return state

func recv_full(state:Dictionary) -> void:
	expedition.receive(state.get("expedition",{}))
	set_hearth_level(int(state.get("hearth_level",1)))
	for args in state.buildings:callv("recv_defense",args)
	for args in state.swarm:callv("recv_enemy",args)
	for id in state.resources:
		recv_resource(int(id),int(state.resources[id]),false)
	recv_snapshot(state)
	if state.ended:recv_end(state.victory)

func recv_snapshot(state:Dictionary) -> void:
	expedition.receive(state.get("expedition",{}))
	if not multiplayer.is_server():pets.receive(state.get("pets",{}))
	set_hearth_level(int(state.get("hearth_level",1)))
	raid_spawned = int(state.get("raid_spawned",0))
	if not multiplayer.is_server():director.receive(state.get("raid",{}))
	solo_rescue_wave=maxi(solo_rescue_wave,int(state.get("solo_rescue_wave",-1)))
	progression.receive(state.get("progression",{}))
	encounters.unlock(hearth_level)
	encounters.receive(state.get("encounters",{}))
	shared=state.shared.duplicate();workshop_level=state.level;lifetime_crystal=state.crystals
	fort_health=state.fort;is_night=state.night;wave=state.wave;phase_time=state.time
	for raw_id in state.players:
		var id:=int(raw_id)
		if not players.has(id):continue
		var data:Dictionary=state.players[raw_id]
		var p:FortPlayer=players[id]
		if not p.is_local_player():
			p.target_position=data.pos;p.target_yaw=data.yaw;p.velocity=data.velocity
			p.remote_moving=Vector2(p.velocity.x,p.velocity.z).length()>0.2
		p.health=data.health;p.carrying=data.carry.duplicate();p.set_travel_mode(data.travel)
		p.ability_cooldown=data.ability;p.down_time=data.down;p.mounted_ballista=data.mount;p.rally_time=data.rally
		recv_loadout(id,data.get("owned",PackedStringArray(["Axe"])),data.get("weapon","Axe"),data.get("loadout_revision",0))
		p.apply_weapon_levels(data.get("weapon_levels",{}),int(data.get("weapon_revision",0)))
		p.apply_progression(data.get("pack_level",0),data.get("relics",PackedStringArray()),data.get("armor",false),data.get("progression_revision",0))
	for raw_id in state.enemies:
		var id:=int(raw_id)
		if not enemies.has(id):continue
		var data:Dictionary=state.enemies[raw_id]
		enemies[id].target=data.pos;enemies[id].yaw=data.yaw;enemies[id].hp=data.hp;enemies[id].attack=data.attack
	for raw_id in state.defenses:
		var id:=int(raw_id)
		if defenses.has(id):
			var data:Dictionary=state.defenses[raw_id]
			if int(data.get("level",1))<int(defenses[id].get("level",1)):continue
			if int(data.get("work_revision",0))<int(defenses[id].get("work_revision",0)):continue
			defenses[id].merge(data,true)
			construction.visual(defenses[id])
			progression.defense_visual(defenses[id])
			if not local_player() or local_player().mounted_ballista!=id:FortBattlements.pose(defenses[id])

func recv_enemy_snapshot(state:Dictionary)->void:
	for raw_id in state:
		var id:=int(raw_id)
		if not enemies.has(id):continue
		var data:Dictionary=state[raw_id]
		enemies[id].target=data.pos;enemies[id].yaw=data.yaw;enemies[id].hp=data.hp;enemies[id].attack=data.attack

func _process(delta:float) -> void:
	construction.draw_range()
	clock+=delta
	toast_time=maxf(0,toast_time-delta)
	_update_lighting(delta)
	_update_preview()
	battlements.tick(delta)
	_update_resource_focus()
	_animate_enemies(delta)
	raiders.visual_tick()
	if ended:return
	pets.tick(delta)
	phase_time=maxf(0,phase_time-delta)
	if not multiplayer.is_server():return
	expedition.tick(delta)
	progression.tick()
	encounters.tick()
	raiders.tick()
	for id in players:
		var p:FortPlayer=players[id]
		if p.health<=0 and p.down_time<=0:_respawn(int(id))
	for hit in delayed_hits.duplicate():
		if clock>=hit.when:
			delayed_hits.erase(hit)
			_resolve_hit(hit.id,hit.direction,hit.get("weapon","Axe"))
	if phase_time<=0:_advance_phase()
	if ended:return
	if is_night:
		director.tick(delta)
	_simulate_enemies(delta)
	defense_timer-=delta
	if defense_timer<=0:
		defense_timer=0.8
		_tick_defenses()
	for id in defenses.keys():
		var d:Dictionary=defenses[id]
		if d.temporary:
			d.life-=delta
			if d.life<=0:broadcast("recv_remove_defense",[id])
	for id in resource_nodes:
		var r:Dictionary=resource_nodes[id]
		if r.amount<=0:
			r.respawn-=delta
			if r.respawn<=0 and resource_respawn_clear(r):
				broadcast("recv_resource",[id,FortForestry.capacity(r),false])
			elif r.respawn<=0:r.respawn=5.0
	snapshot_timer-=delta
	if snapshot_timer<=0:
		snapshot_timer=0.08
		if get_parent().has_method("broadcast_snapshot"):get_parent().broadcast_snapshot(snapshot())

func _update_lighting(delta:float)->void:
	var t:=1.0-clampf(phase_time/(night_length(wave) if is_night else day_length()),0,1)
	var energy:=0.23 if is_night else lerpf(0.65,0.44,t)
	sun.light_energy=lerpf(sun.light_energy,energy,delta*1.2)
	sun.light_color=sun.light_color.lerp(Color("#9aaee0") if is_night else Color("#ffdea5"),delta)
	sun.rotation_degrees=Vector3(-48+sin(t*PI)*12,-32,0)
	environment.ambient_light_energy=lerpf(environment.ambient_light_energy,0.23 if is_night else 0.32,delta)
	environment.fog_light_color=environment.fog_light_color.lerp(Color("#263b51") if is_night else Color("#9bb0bd"),delta)
	sky_material.sky_top_color=sky_material.sky_top_color.lerp(Color("#162638") if is_night else Color("#638cab"),delta)
	sky_material.sky_horizon_color=sky_material.sky_horizon_color.lerp(Color("#40505d") if is_night else Color("#c6c9bc"),delta)

func _advance_phase()->void:
	ready_votes.clear()
	if is_night:
		director.finish()
		for id in enemies.keys():
			if int(enemies[id].get("camp",-1))<0 and not FortEncounters.is_wild(int(enemies[id].get("camp",-1))) and enemies[id].kind!="Colossus":broadcast("recv_enemy_dead",[id])
		broadcast("recv_phase",[false,wave,day_length()])
		expedition.day_start()
		for p in players.values():
			if p.health>0:_set_health(p.peer_id,minf(p.max_health,p.health+35))
	else:
		raid_spawned=0
		broadcast("recv_phase",[true,wave+1,night_length(wave+1)])
		director.start()
		expedition.night_start()

func recv_phase(night:bool,new_wave:int,seconds:float)->void:
	is_night=night;wave=new_wave;phase_time=seconds
	show_toast("NIGHT %d · Defend the hearth!"%wave if night else "DAWN · The swarm retreats. Heal, gather, rebuild.",5)
	sound.play("night" if night else "dawn",-10)

func night_length(night:int)->float:
	var base:=NIGHT_LENGTH+mini(29,maxi(0,night-1))*5.0+(hearth_level-1)*15.0
	return base if hearth_level<=3 else maxf(base,(maxf(52,build_radius()+15)-8)/1.8+74)

func day_length()->float:return DAY_LENGTH+(hearth_level-1)*30.0

func resource_respawn_clear(r:Dictionary)->bool:
	for d in defenses.values():
		var offset:Vector3=(r.node.position-d.node.position).rotated(Vector3.UP,-d.node.rotation.y)
		if FortPlacement.is_wall(d.kind):
			if absf(offset.x)<FortPlacement.wall_width(d.kind)*.5+.65 and absf(offset.z)<1.15 and absf(offset.y)<3:return false
		elif Vector2(offset.x,offset.z).length()<3.0 and absf(offset.y)<5:return false
	for p in players.values():
		if p.position.distance_to(r.node.position)<1.5:return false
	return true

func configure_opening_day()->void:
	if multiplayer.is_server() and wave==0 and not is_night:
		phase_time=180.0 if players.size()==1 else DAY_LENGTH
		if players.size()==1:show_toast("SOLO / +30s preparation, +25% construction, one 8s rescue each night.",8)

func _allow(id:int,action:String,interval:float)->bool:
	var key:="%d/%s"%[id,action]
	if clock<float(cooldowns.get(key,-100)):return false
	cooldowns[key]=clock+interval
	return true

func server_action(id:int,kind:String,data:Dictionary) -> void:
	if not multiplayer.is_server() or ended or not players.has(id):return
	var p:FortPlayer=players[id]
	if p.health<=0:return
	match kind:
		"attack":
			var dir:Vector3=data.get("direction",Vector3.FORWARD)
			if not dir.is_finite() or Vector2(dir.x,dir.z).length()<0.01:return
			var weapon_data:Dictionary=GameData.WEAPONS[p.weapon]
			if p.mounted_ballista>=0 or not _allow(id,"attack",weapon_data.cooldown):return
			dir=dir.normalized() if GameData.ranged(p.weapon) else Vector3(dir.x,0,dir.z).normalized()
			broadcast("recv_action",[id,"attack",p.position+dir])
			delayed_hits.append({"id":id,"direction":dir,"when":clock+weapon_data.windup,"weapon":p.weapon})
		"craft_weapon":_craft_weapon(id,str(data.get("weapon","")))
		"upgrade_weapon":_upgrade_weapon(id,str(data.get("weapon","")),int(data.get("level",0)))
		"equip_weapon":_equip_weapon(id,str(data.get("weapon","")))
		"upgrade_hearth":_upgrade_hearth(id,int(data.get("level",0)))
		"craft_pack":progression.craft_pack(id,int(data.get("level",-1)))
		"upgrade_defense":progression.upgrade_defense(id,int(data.get("id",-1)),int(data.get("level",-1)))
		"work_defense":construction.work(id,int(data.get("id",-1)))
		"cancel_construction":construction.cancel(id,int(data.get("id",-1)),int(data.get("revision",-1)))
		"salvage_defense":construction.salvage(id,int(data.get("id",-1)),int(data.get("revision",-1)))
		"recruit_pet":pets.recruit(id,int(data.get("kind",-1)),int(data.get("revision",-1)))
		"assign_pet":pets.assign(id,int(data.get("id",-1)),str(data.get("resource","")),int(data.get("revision",-1)))
		"release_pet":pets.release(id,int(data.get("id",-1)),int(data.get("revision",-1)))
		"interact":_interact(id)
		"repair":
			if _allow(id,"work",0.60):_repair(id)
		"ability":_ability(id)
		"build":
			if _allow(id,"build",0.50):_build(id,data)
		"travel":
			var mode:=int(data.get("mode",0))
			if mode>=0 and mode<workshop_level and _allow(id,"travel",0.3):
				p.set_travel_mode(mode)
		"ballista":_fire_ballista(id,data.get("direction",Vector3.FORWARD))
		"ballista_aim":
			var direction:Vector3=data.get("direction",Vector3.ZERO)
			if defenses.has(p.mounted_ballista) and _allow(id,"aim",.06):FortBattlements.aim(defenses[p.mounted_ballista],direction)
		"ready":
			if not is_night:
				ready_votes[id]=true
				broadcast("recv_notice",["%d / %d dwarves ready for night"%[ready_votes.size(),players.size()]])
				if ready_votes.size()>=players.size():phase_time=minf(phase_time,3.0)

func player_attack(_player:FortPlayer,direction:Vector3)->void:
	request_action("attack",{"direction":direction})

func player_interact(_player:FortPlayer)->void:
	if _player.is_local_player() and _player.mounted_ballista<0 and not local_build_mode and _player.position.distance_to(Vector3(-4.6,0,0))<3.2:
		var rescue:=false
		for ally in players.values():
			if ally.health<=0 and _player.position.distance_to(ally.position)<2.7:rescue=true
		if not rescue:
			open_forge()
			return
	request_action("interact")

func cycle_weapon(p:FortPlayer)->void:
	if p.owned_weapons.size()<2:
		show_toast("Visit the WORKSHOP and press E to craft a weapon.")
		return
	var next:int=(p.owned_weapons.find(p.weapon)+1)%p.owned_weapons.size()
	request_action("equip_weapon",{"weapon":p.owned_weapons[next]})

func _craft_weapon(id:int,kind:String)->void:
	var p:FortPlayer=players[id]
	if not GameData.WEAPONS.has(kind):return
	if p.position.distance_to(Vector3(-4.6,0,0))>=3.2 or p.mounted_ballista>=0:
		personal(id,"Stand beside the workshop to craft.");return
	if clock<float(cooldowns.get("%d/attack"%id,0)):
		personal(id,"Finish your attack before changing weapons.");return
	if kind in p.owned_weapons:
		_equip_weapon(id,kind);return
	if not _allow(id,"craft",0.35):return
	var recipe:Dictionary=GameData.WEAPONS[kind]
	if hearth_level<int(recipe.get("tier",1)):personal(id,"Upgrade the hearth before forging this weapon.");return
	for resource in GameData.RESOURCES:
		if int(shared.get(resource,0))<int(recipe.get(resource,0)):personal(id,"Not enough shared supplies. Deposit your pack first.");return
	for resource in GameData.RESOURCES:
		if int(recipe.get(resource,0))>0:shared[resource]=int(shared.get(resource,0))-int(recipe[resource])
	p.owned_weapons.append(kind)
	broadcast("recv_loadout",[id,p.owned_weapons,kind,p.loadout_revision+1])
	broadcast("recv_notice",["%s forged %s. Press C to switch weapons."%[p.display_name,recipe.name]])
	broadcast("recv_fx",[Vector3(-4.6,1.5,0),Color("#efbd70"),"FORGED","build"])

func _equip_weapon(id:int,kind:String)->void:
	var p:FortPlayer=players[id]
	if not kind in p.owned_weapons or p.mounted_ballista>=0:return
	if clock<float(cooldowns.get("%d/attack"%id,0)):
		personal(id,"Finish your attack before changing weapons.");return
	if kind==p.weapon or not _allow(id,"equip",0.25):return
	broadcast("recv_loadout",[id,p.owned_weapons,kind,p.loadout_revision+1])

func _upgrade_weapon(id:int,kind:String,expected:int)->void:
	var p:FortPlayer=players[id]
	if kind not in p.owned_weapons or expected!=int(p.weapon_levels.get(kind,1)) or expected<1 or expected>=GameData.MAX_GEAR_LEVEL:return
	if p.position.distance_to(Vector3(-4.6,0,0))>=3.2 or p.mounted_ballista>=0 or hearth_level<expected+1:return
	if not _allow(id,"forge_upgrade",.4):return
	var cost:=GameData.weapon_upgrade_cost(expected)
	for resource in cost:
		if int(shared.get(resource,0))<int(cost[resource]):personal(id,"Deposit more iron, crystals or aether to reinforce this weapon.");return
	for resource in cost:shared[resource]-=int(cost[resource])
	p.weapon_levels[kind]=expected+1;p.weapon_revision+=1;p.weapon_trim()
	broadcast("recv_full",[full_state()])
	personal(id,"%s reinforced to level %d / +%d%% base damage."%[GameData.WEAPONS[kind].name,expected+1,expected*25])

func recv_loadout(id:int,owned:PackedStringArray,kind:String,revision:int)->void:
	if not players.has(id) or not GameData.WEAPONS.has(kind):return
	var p:FortPlayer=players[id]
	if revision<p.loadout_revision:return
	p.loadout_revision=revision;p.owned_weapons=owned.duplicate()
	p.equip_weapon(kind)

func player_repair(_player:FortPlayer)->void:
	request_action("repair")

func player_ability(_player:FortPlayer)->void:
	request_action("ability")

func cycle_travel(p:FortPlayer)->void:
	if workshop_level<=1:show_toast("Deposit 8 crystals to unlock the crew's horses.");return
	request_action("travel",{"mode":(p.travel_mode+1)%workshop_level})

func _interact(id:int)->void:
	if not _allow(id,"interact",0.65):return
	var p:FortPlayer=players[id]
	if p.mounted_ballista>=0:
		_mount(id,-1)
		return
	for other_id in players:
		var ally:FortPlayer=players[other_id]
		if ally.health<=0 and p.position.distance_to(ally.position)<2.7:
			revive_progress[other_id]=int(revive_progress.get(other_id,0))+1
			broadcast("recv_action",[id,"repair"])
			broadcast("recv_fx",[ally.position+Vector3.UP,Color("#9fe3cb"),"REVIVING %d / 3"%revive_progress[other_id],"ability"])
			if revive_progress[other_id]>=3:
				revive_progress.erase(other_id)
				_set_health(int(other_id),ally.max_health*0.6)
				ally.invulnerable=3.0
				broadcast("recv_notice",["%s helped %s back up!"%[p.display_name,ally.display_name]])
			return
	if p.position.distance_to(Vector3(4.6,0,0))<3.2 and p.total_carried()>0:
		_deposit(id)
		return
	if expedition.interact(id) or progression.interact(id) or encounters.interact(id):return
	var work_id:=construction.nearest(p)
	if work_id>=0:construction.work(id,work_id);return
	var resource_id:=nearest_resource(p.position)
	if resource_id>=0:
		_gather(id,resource_id)
		return
	var ballista:=_nearest_defense(p.position,"Ballista",3.0)
	if ballista>=0:_mount(id,ballista)

func nearest_resource(pos:Vector3)->int:
	var best:=-1
	var distance:=2.7
	for id in resource_nodes:
		var r:Dictionary=resource_nodes[id]
		var d:float=pos.distance_to(r.node.position)
		if r.amount>0 and d<distance:best=int(id);distance=d
	return best

func _update_resource_focus()->void:
	var p:=local_player()
	if p and FortFoliage.grass_material:FortFoliage.grass_material.set_shader_parameter("dwarf_position",p.position)
	focused_resource=-1
	if p and p.health>0 and not menu_open and not local_build_mode and not ended and p.mounted_ballista<0:
		focused_resource=nearest_resource(p.position)
	focus_ring.visible=focused_resource>=0
	focus_label.visible=focused_resource>=0
	if focused_resource<0:return
	var resource:Dictionary=resource_nodes[focused_resource]
	var capacity:int=FortForestry.capacity(resource)
	var color:=GameData.resource_color(resource.kind).lightened(0.25)
	focus_ring.position=resource.node.position+Vector3.UP*0.065
	focus_ring.scale=Vector3.ONE*(1.0+sin(clock*3)*0.025)
	(focus_ring.material_override as StandardMaterial3D).albedo_color=color
	var toward_player:Vector3=p.position-resource.node.position
	toward_player.y=0
	focus_label.position=resource.node.position+Vector3.UP*1.7+toward_player.normalized()*0.55
	focus_label.modulate=color
	var filled:=ceili(float(resource.amount)/capacity*6)
	var requirement:=FortForestry.requirement(resource,p)
	if not requirement.is_empty():
		focus_label.text=FortForestry.title(resource)+"\n"+requirement
		return
	focus_label.text="%s / %s  %d / %d\n%s%s"%[FortForestry.title(resource),resource.kind,resource.amount,capacity,"■".repeat(filled),"·".repeat(6-filled)]

func _gather(id:int,resource_id:int)->void:
	if not players.has(id) or not resource_nodes.has(resource_id):return
	var p:FortPlayer=players[id]
	var r:Dictionary=resource_nodes[resource_id]
	if r.amount<=0 or p.position.distance_to(r.node.position)>2.7:return
	var requirement:=FortForestry.requirement(r,p)
	if not requirement.is_empty():personal(id,requirement);return
	if p.total_carried()>=p.carry_limit:
		personal(id,"Pack full. Bring it home to the shared stockpile.")
		return
	var amount:=mini(mini((3 if p.class_id==3 else 2)*expedition.gather_multiplier(),r.amount),p.carry_limit-p.total_carried())
	p.carrying[r.kind]=int(p.carrying.get(r.kind,0))+amount
	r.respawn=65.0
	broadcast("recv_action",[id,"gather",r.node.position])
	broadcast("recv_resource",[resource_id,r.amount-amount,true])
	broadcast("recv_fx",[r.node.position+Vector3.UP,GameData.resource_color(r.kind),"+%d %s"%[amount,r.kind],"chop" if FortForestry.is_tree(r) else "mine"])

func recv_resource(id:int,amount:int,hit:bool)->void:
	if not resource_nodes.has(id):return
	var r:Dictionary=resource_nodes[id]
	var previous:int=r.amount
	var destroyed:bool=hit and r.amount>0 and amount<=0 and FortForestry.is_tree(r)
	r.amount=amount
	var node:Node3D=r.node
	if not FortForestry.is_tree(r):
		var chunks:=ceili(float(amount)/(6.0 if r.kind in ["crystal","aether"] else 12.0)*6.0)
		for chunk in node.find_children("HarvestChunk_*","Node3D",true,false):
			chunk.visible=chunk.name.get_slice("_",1).to_int()<chunks
		if hit and amount<previous:FortParticles.mineral_hit(self,node.global_position,r.kind=="crystal")
	if destroyed:
		var leaf_color:=Color("#cf963d") if r.get("species","")=="Amberwood" else (Color("#bfa6d2") if r.get("tree",false) and r.kind!="wood" else Color.TRANSPARENT)
		FortParticles.tree_destroyed(self,node.global_position,id%3==2,leaf_color)
		tree_burst_count+=1
	var trunk:StaticBody3D=node.get_node_or_null("TreeTrunk")
	if trunk:trunk.collision_layer=1 if amount>0 else 0
	var anim:AnimationPlayer=r.animation
	if amount>0:
		node.visible=true
		if anim:
			anim.play("Hit" if hit else "Idle",0.05)
			if hit:anim.seek(0,true)
		elif hit:
			var tween:=create_tween()
			tween.tween_property(node,"rotation:z",0.13,0.08)
			tween.tween_property(node,"rotation:z",0.0,0.18)
	elif hit and anim:
		anim.play("Destruction",0.05)
		var tween:=create_tween()
		tween.tween_interval(1.85)
		tween.tween_callback(func():
			if is_instance_valid(node) and r.amount<=0:node.hide())
	else:node.hide()

func _deposit(id:int)->void:
	var p:FortPlayer=players[id]
	var amount:=p.total_carried()
	for kind in GameData.RESOURCES:shared[kind]=int(shared.get(kind,0))+int(p.carrying.get(kind,0))
	lifetime_crystal+=int(p.carrying.crystal)
	p.carrying={"wood":0,"stone":0,"crystal":0}
	var level:=3 if lifetime_crystal>=20 else (2 if lifetime_crystal>=8 else 1)
	if level>workshop_level:broadcast("recv_notice",["%s unlocked for everyone! Press T."%("Jetpacks" if level==3 else "Horses")])
	workshop_level=level
	broadcast("recv_fx",[Vector3(4.6,1.5,0),Color("#f2d18a"),"+%d to shared stock"%amount,"deposit"])

func recv_action(id:int,kind:String,target:=Vector3.INF)->void:
	if not players.has(id):return
	var p:FortPlayer=players[id]
	p.play_action(kind)
	if target.is_finite():
		var toward:Vector3=target-p.position
		if Vector2(toward.x,toward.z).length()>0.01:
			p.visual_root.rotation.y=atan2(toward.x,toward.z)
			p.target_yaw=p.visual_root.rotation.y
	if kind=="attack" and not GameData.ranged(p.weapon):
		sound.play("shot",-23)
		var front:=Vector3(sin(p.visual_root.rotation.y),0,cos(p.visual_root.rotation.y))
		_ring(p.position+front*1.0+Vector3.UP*0.8,Color("#f7d394"),1.35,0.25)

func _resolve_hit(id:int,direction:Vector3,weapon_kind:="Axe")->void:
	if not players.has(id) or players[id].health<=0:return
	var p:FortPlayer=players[id]
	if GameData.ranged(weapon_kind):
		_fire_crossbow(p,direction,weapon_kind)
		return
	var weapon_data:Dictionary=GameData.WEAPONS[weapon_kind]
	var hits:=0
	for enemy_id in enemies.keys():
		var e:Dictionary=enemies[enemy_id]
		var offset:Vector3=e.node.position-p.position
		if absf(offset.y)>2.2:continue
		offset.y=0
		if offset.length()<weapon_data.range and direction.dot(offset.normalized())>(.9 if weapon_kind=="Pike" else .10):
			if not FortSiege.clear(self,p.position,e.node.position):continue
			var damage:float=weapon_data.damage+(13.0 if p.class_id==0 else 0.0)
			if weapon_kind=="Hammer" and "Embermaul" in p.relics:damage+=28;e.stun=maxf(e.stun,1.5)
			if weapon_kind in ["Hammer","Greatmaul","Warpick","Runeblade"]:e.stun=maxf(e.stun,.2 if e.kind=="Colossus" else .75)
			if weapon_kind=="Warpick" and e.kind=="Shieldguard":damage*=1.5
			_damage_enemy(int(enemy_id),damage*p.weapon_power(weapon_kind),direction*float(weapon_data.get("knockback",3.0 if weapon_kind=="Hammer" else .45)))
			hits+=1
			if hits>=int(weapon_data.get("targets",5 if weapon_kind=="Hammer" else 3)):break
	if weapon_kind in ["Hammer","Greatmaul"]:broadcast("recv_fx",[p.position+direction*1.8,Color("#d4b47c"),"","hammer"])

func _fire_crossbow(p:FortPlayer,direction:Vector3,kind:="Crossbow")->void:
	var shot:=FortAim.solution(self,p,direction,false,kind)
	if shot.enemy>=0:
		_damage_enemy(shot.enemy,(80.0 if kind=="Crossbow" and "Stormstring" in p.relics else float(GameData.WEAPONS[kind].damage))*p.weapon_power(kind),direction*0.3)
	broadcast("recv_fx",[shot.origin,Color("#c8e5ca"),"bolt","crossbow",shot.point])
	FortAdvancedArsenal.ranged_effect(self,p,kind,shot)


func _ability(id:int)->void:
	var p:FortPlayer=players[id]
	if not _allow(id,"ability",12):return
	p.ability_cooldown=12
	broadcast("recv_action",[id,"ability"])
	match p.class_id:
		0:
			broadcast("recv_fx",[p.position,GameData.class_data(0).color,"GROUND SLAM","ability"])
			for enemy_id in enemies.keys():
				var e:Dictionary=enemies[enemy_id]
				if p.position.distance_to(e.node.position)<6:
					e.stun=2.0;e.taunt=id
					_damage_enemy(int(enemy_id),65,(e.node.position-p.position).normalized())
		1:
			for ally in players.values():
				if ally.health>0 and p.position.distance_to(ally.position)<10:
					_set_health(ally.peer_id,ally.health+45)
					ally.rally_time=6
			broadcast("recv_fx",[p.position,Color("#8fe0c5"),"RALLY · HEAL + HASTE","ability"])
		2:
			var pos:=p.position+Vector3(2.4,0,0)
			pos.y=0
			if not build_block_reason("Watchtower",pos,0,true).is_empty():
				p.ability_cooldown=0;cooldowns.erase("%d/ability"%id)
				personal(id,"Move to open ground to deploy your field turret.")
				return
			_spawn_defense("Watchtower",pos,0,true)
			broadcast("recv_fx",[pos,Color("#efc883"),"FIELD TURRET","build"])
		3:
			broadcast("recv_fx",[p.position,Color("#96dd95"),"TRAILBLAZE","ability"])
			if p.is_local_player():p.dash_time=0.40
			else:get_parent().send_personal_event(id,"dash",{})


func toggle_build_mode()->void:
	local_build_mode=not local_build_mode
	if not local_build_mode and is_instance_valid(preview):preview.hide()

func select_build(index:int)->void:
	selected_build=clampi(index,0,GameData.BUILD_ORDER.size()-1)
	local_build_mode=true

func _update_preview()->void:
	var p:=local_player()
	if not p or not local_build_mode or menu_open or p.health<=0:
		if is_instance_valid(preview):preview.hide()
		return
	var kind:String=GameData.BUILD_ORDER[selected_build]
	if not is_instance_valid(preview) or preview_kind!=kind:
		if is_instance_valid(preview):preview.queue_free()
		preview=FortArt.make_defense(kind,false)
		preview_kind=kind
		add_child(preview)
	preview.show()
	build_position=p.position+p.aim_direction()*4.3
	build_position=Vector3(snappedf(build_position.x,0.5),0,snappedf(build_position.z,0.5))
	build_position=FortPlacement.snap(self,kind,build_position,build_rotation)
	preview.position=build_position
	preview.rotation.y=build_rotation
	var reason:=build_block_reason(kind,build_position,build_rotation)
	preview_valid=reason.is_empty() and can_afford(p,kind)
	var color:=Color(0.25,0.85,0.65,0.42) if preview_valid else Color(0.95,0.25,0.18,0.45)
	var mat:=Visuals.material(color)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	_override_material(preview,mat)

func _override_material(node:Node,mat:Material)->void:
	if node is MeshInstance3D:node.material_override=mat
	for child in node.get_children():_override_material(child,mat)

func can_afford(p:FortPlayer,kind:String)->bool:
	var recipe:Dictionary=GameData.RECIPES[kind]
	var factor:=0.75 if p.class_id==2 else 1.0
	for resource in GameData.RESOURCES:
		if int(shared.get(resource,0))<ceili(int(recipe.get(resource,0))*factor):return false
	return true

func build_block_reason(kind:String,pos:Vector3,rotation_y:float,_temporary:=false)->String:
	if not pos.is_finite() or not is_finite(rotation_y):return "Invalid location"
	if hearth_level<int(GameData.RECIPES[kind].get("tier",1)):return "Requires Hearth tier %d"%GameData.RECIPES[kind].tier
	if Vector2(pos.x,pos.z).length()>build_radius():return "Build within %dm of the hearth (upgrade to expand)"%build_radius()
	if Vector2(pos.x,pos.z).length()<3.1:return "Keep the hearth clear"
	if pos.distance_to(Vector3(4.6,0,0))<3 or pos.distance_to(Vector3(-4.6,0,0))<3:return "Keep the stockpile and workshop clear"
	var radius:=Vector2(pos.x,pos.z).length()
	if radius>6.6 and radius<9.8:
		return "Leave the walls and gateways clear"
	var footprint:=2.7 if kind=="Watchtower" else 2.0
	for obstacle in scenery_keepouts:
		if pos.distance_to(obstacle.pos)<footprint+obstacle.radius:return "Keep scenery and camp supplies clear"
	if pos.distance_to(Vector3(-4.6,0,4.3))<footprint or pos.distance_to(Vector3(5.3,0,-4.4))<footprint:return "Keep camp supplies clear"
	for resource in resource_nodes.values():
		if resource.amount>0 and resource.node.position.distance_to(pos)<footprint:return "Clear the resource before building here"
	for defense in defenses.values():
		if FortPlacement.is_wall(kind) and FortPlacement.is_wall(defense.kind):
			if FortPlacement.wall_overlap(pos,rotation_y,kind,defense.node.position,defense.node.rotation.y,defense.kind):return "Walls overlap; connect their ends"
			continue
		if defense.node.position.distance_to(pos)<footprint+0.8:return "Too close to another defense"
	for p in players.values():
		if p.position.distance_to(pos)<1.7:return "A dwarf is standing here"
	return ""

func place_build()->void:
	if not preview_valid:
		var reason:=build_block_reason(GameData.BUILD_ORDER[selected_build],build_position,build_rotation)
		show_toast(reason if not reason.is_empty() else "Not enough resources in the shared stockpile.")
		return
	request_action("build",{"kind":GameData.BUILD_ORDER[selected_build],"pos":build_position,"rotation":build_rotation})

func _build(id:int,data:Dictionary)->void:
	var kind:String=str(data.get("kind",""))
	if not GameData.RECIPES.has(kind):return
	var pos:Vector3=data.get("pos",Vector3.ZERO)
	var yaw:float=float(data.get("rotation",0))
	pos=FortPlacement.snap(self,kind,pos,yaw)
	var p:FortPlayer=players[id]
	if p.position.distance_to(pos)>6:return
	var reason:=build_block_reason(kind,pos,yaw)
	if not reason.is_empty():personal(id,reason);return
	if not can_afford(p,kind):personal(id,"Not enough resources in the shared stockpile.");return
	var reserved:Dictionary={}
	for resource in GameData.RESOURCES:
		reserved[resource]=ceili(int(GameData.RECIPES[kind].get(resource,0))*(0.75 if p.class_id==2 else 1.0));shared[resource]=int(shared.get(resource,0))-reserved[resource]
	_spawn_defense(kind,pos,yaw,false)
	construction.begin(next_defense_id-1,id,reserved,"build")
	broadcast("recv_action",[id,"repair"])
	broadcast("recv_fx",[pos+Vector3.UP,Color("#f2c880"),"FOUNDATION / HOLD E TO BUILD","build"])

func _spawn_defense(kind:String,pos:Vector3,yaw:float,temporary:bool)->void:
	var id:=next_defense_id
	next_defense_id+=1
	broadcast("recv_defense",[id,kind,pos,yaw,float(GameData.RECIPES[kind].hp)*(0.6 if temporary else 1),temporary])

func recv_defense(id:int,kind:String,pos:Vector3,yaw:float,hp:float,temporary:bool)->void:
	if defenses.has(id):return
	var node:=FortArt.make_defense(kind)
	node.name="Defense_%d"%id
	node.set_meta("defense_id",id)
	node.position=pos;node.rotation.y=yaw
	defense_root.add_child(node)
	var label:=Visuals.label_3d(kind,Color("#e0d4b4"),3.4 if kind=="Watchtower" else 2.1)
	label.name="Status"
	label.visible=false
	node.add_child(label)
	defenses[id]={"node":node,"kind":kind,"hp":hp,"max_hp":hp,"temporary":temporary,"life":40.0,"occupant":-1,"level":1}

func recv_remove_defense(id:int,quiet:=false)->void:
	if not defenses.has(id):return
	for p in players.values():
		if p.mounted_ballista==id:
			p.mounted_ballista=-1
			p.position+=Vector3(1.8,0,0)
			p.target_position=p.position
	var node:Node3D=defenses[id].node
	if not quiet:recv_fx(node.position+Vector3.UP,FortArt.WOOD,"DESTROYED","hit")
	node.queue_free()
	defenses.erase(id)

func _nearest_defense(pos:Vector3,kind:String,max_dist:float)->int:
	var best:=-1
	var distance:=max_dist
	for id in defenses:
		var d:Dictionary=defenses[id]
		var dist:float=pos.distance_to(d.node.position)
		if dist<distance and (kind.is_empty() or kind==d.kind):best=int(id);distance=dist
	return best

func _repair(id:int)->void:
	var p:FortPlayer=players[id]
	var work_id:=construction.nearest(p)
	if work_id>=0:construction.work(id,work_id);return
	if shared.wood<=0:personal(id,"Repairs need wood in the shared stockpile.");return
	var defense_id:=_nearest_defense(p.position,"",3.5)
	var amount:=48.0 if p.class_id==2 else 24.0
	var target:=p.position
	if defense_id>=0 and defenses[defense_id].hp<defenses[defense_id].max_hp:
		defenses[defense_id].hp=minf(defenses[defense_id].max_hp,defenses[defense_id].hp+amount)
		target=defenses[defense_id].node.position
	elif p.position.length()<9.5 and fort_health<fort_max_health:
		fort_health=minf(fort_max_health,fort_health+amount)
		target=Vector3.ZERO
	else:return
	shared.wood-=1
	director.record("repair_wood",1)
	broadcast("recv_action",[id,"repair"])
	broadcast("recv_fx",[target+Vector3.UP,Color("#9fe4c7"),"+%d repair"%amount,"build"])

func _mount(id:int,defense_id:int)->void:
	var p:FortPlayer=players[id]
	if defense_id<0:
		if defenses.has(p.mounted_ballista):defenses[p.mounted_ballista].occupant=-1
		broadcast("recv_mount",[id,-1,p.position+Vector3(1.6,0,0)])
		return
	if not defenses.has(defense_id) or defenses[defense_id].kind!="Ballista":return
	if FortConstruction.foundation(defenses[defense_id]):personal(id,"Finish building the ballista first.");return
	var d:Dictionary=defenses[defense_id]
	if d.occupant!=-1:personal(id,"Another dwarf is using this ballista.");return
	if p.position.distance_to(d.node.position)>3:return
	d.occupant=id
	broadcast("recv_mount",[id,defense_id,d.node.position+Vector3(0,0,1.2).rotated(Vector3.UP,d.node.rotation.y)])

func recv_mount(id:int,defense_id:int,pos:Vector3)->void:
	if not players.has(id):return
	var p:FortPlayer=players[id]
	p.mounted_ballista=defense_id
	p.position=pos;p.target_position=pos;p.velocity=Vector3.ZERO

func _fire_ballista(id:int,direction:Vector3)->void:
	var p:FortPlayer=players[id]
	if not defenses.has(p.mounted_ballista) or not direction.is_finite() or direction.length()<0.01 or not _allow(id,"ballista",0.9):return
	var d:Dictionary=defenses[p.mounted_ballista]
	var shot:=FortAim.solution(self,p,direction,true)
	if shot.enemy>=0:_damage_enemy(shot.enemy,130*(1.0+(int(d.get("level",1))-1)*0.4),direction.normalized())
	broadcast("recv_fx",[shot.origin,Color("#f3db99"),"bolt","shot",shot.point])
	FortBattlements.aim(d,direction)


func _tick_defenses()->void:
	for id in defenses.keys():
		if not defenses.has(id):continue
		var d:Dictionary=defenses[id]
		if FortConstruction.foundation(d):continue
		var power:float=1.0+(int(d.get("level",1))-1)*0.4
		if d.kind in ["Embercoil","GravityWell","Sunlance"]:
			FortAdvancedArsenal.tick_tower(self,d);continue
		if d.kind in ["StormSpire","FrostMortar"]:
			progression.tick_advanced(d)
			continue
		if d.kind=="Mender":
			battlements.heal(d,power)
		elif d.kind=="Watchtower":
			var enemy_id:=_nearest_enemy(d.node.position,GameData.defense_radius(d.kind,int(d.get("level",1))))
			if enemy_id>=0:
				var from:Vector3=d.node.position+Vector3.UP*2.9
				var to:Vector3=enemies[enemy_id].node.position+Vector3.UP
				var direction:Vector3=(to-from).normalized()
				FortBattlements.aim(d,direction)
				broadcast("recv_fx",[from,Color("#f4dc9d"),"bolt","shot",to])
				_damage_enemy(enemy_id,25*power,Vector3.ZERO,"field_turret_damage" if d.temporary else "tower_damage")

func _spawn_enemy(requested_kind:="",requested_angle:=INF)->bool:
	var raiders:=0
	for e in enemies.values():
		if int(e.get("camp",-1))<0 and not FortEncounters.is_wild(int(e.get("camp",-1))):raiders+=1
	if raiders>=raid_cap():return false
	var id:=next_enemy_id
	next_enemy_id+=1
	var angle:=randf()*TAU if not is_finite(requested_angle) else requested_angle
	# Raids approach the expanded construction zone instead of spawning inside it.
	var spawn_radius:=maxf(52,build_radius()+15)
	var pos:=Vector3(sin(angle)*spawn_radius,0,cos(angle)*spawn_radius)
	var kind:="Brute" if wave>=2 and id%6==0 else ("Sapper" if wave>=3 and id%5==0 else "Raider")
	if id%4==0:kind="EmberRunner"
	if wave>=2 and id%7==0:kind="Ashwing";pos.y=3.8
	if wave>=3 and id%11==0:kind="Cinderlobber";pos.y=0
	if wave>=4 and id%13==0:kind="Bombwing";pos.y=5.8
	if not requested_kind.is_empty():
		kind=requested_kind;pos.y=5.8 if kind=="Bombwing" else (3.8 if kind=="Ashwing" else 0.0)
	var hp:float=(135+wave*10 if kind=="Brute" else (40+wave*5 if kind=="Ashwing" else 55+wave*6))*(1.0+(hearth_level-1)*0.05)
	if kind=="Shieldguard":hp*=2.0
	if kind=="Hexer":hp*=1.3
	if kind=="Prowler":hp*=.8
	raid_spawned+=1
	broadcast("recv_enemy",[id,kind,pos,float(hp)])
	return true

func raid_cap()->int:
	return FortBalance.active_cap(wave,director.crew if director.active else maxi(1,players.size()))

func frontier_radius()->float:
	return [73.0,153.0,243.0][hearth_level-1] if hearth_level<=3 else 243.0+(hearth_level-3)*80.0

func build_radius()->float:
	return [23.0,65.0,115.0][hearth_level-1] if hearth_level<=3 else 115.0+(hearth_level-3)*45.0

func set_hearth_level(level:int)->void:
	level=clampi(level,1,GameData.MAX_HEARTH)
	# Levels only increase within a run; late unordered snapshots cannot undo an upgrade.
	if level<=hearth_level:return
	hearth_level=level
	fort_max_health=1000.0+(level-1)*500.0
	if is_instance_valid(frontier):frontier.expand(level)
	if progression:progression.unlock_zones(level)
	if encounters:encounters.unlock(level)

func _upgrade_hearth(id:int,expected_level:int)->void:
	if expected_level!=hearth_level or hearth_level>=GameData.MAX_HEARTH or is_night:return
	var p:FortPlayer=players[id]
	if p.position.length()>5.0 or not _allow(id,"hearth",1.0):return
	var cost:=FortExpedition.hearth_cost(hearth_level)
	for kind in cost:
		if shared[kind]<cost[kind]:personal(id,"Deposit more supplies before upgrading the hearth.");return
	for kind in cost:shared[kind]-=cost[kind]
	set_hearth_level(hearth_level+1)
	phase_time+=30
	fort_health=minf(fort_max_health,fort_health+500)
	# Full state creates newly unlocked resource nodes before applying their quantities.
	broadcast("recv_full",[full_state()])
	broadcast("recv_fx",[Vector3(0,1,0),Color("#98dfd0"),"HEARTH TIER %d"%hearth_level,"ability"])
	broadcast("recv_notice",["%s upgraded the hearth! Frontier expanded. Larger, stronger raids will follow."%p.display_name])

func recv_enemy(id:int,kind:String,pos:Vector3,hp:float,camp:=-1)->void:
	if enemies.has(id):return
	var body:=CharacterBody3D.new()
	body.name="Enemy_%d"%id
	body.set_meta("enemy_id",id)
	body.position=pos
	body.collision_layer=4
	body.collision_mask=1
	if kind in ["Ashwing","Bombwing"]:body.collision_mask=0
	body.floor_snap_length=0.3
	var col:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.35;capsule.height=1.6
	if kind=="Chieftain":capsule.radius=.6;capsule.height=3.2
	if kind=="Colossus":capsule.radius=.9;capsule.height=5.4
	if kind in FortEncounters.CREATURES:capsule.radius=.6;capsule.height=1.6
	if kind in FortEncounters.DRAGONS:capsule.radius=1.1;capsule.height=3.2
	col.shape=capsule;col.position.y=0.8
	if kind=="Chieftain":col.position.y=1.6
	if kind=="Colossus":col.position.y=2.7
	if kind in FortEncounters.DRAGONS:col.position.y=1.6
	body.add_child(col)
	var visual:=FortArt.make_enemy(kind)
	body.add_child(visual)
	enemy_root.add_child(body)
	var bar:=Visuals.label_3d("",Color("#f1ab80"),2.1 if kind!="Brute" else 2.8)
	bar.font_size=21
	if kind=="Chieftain":bar.position.y=3.8
	if kind=="Colossus":bar.position.y=6.1;bar.visibility_range_end=120
	if kind in FortEncounters.DRAGONS:bar.position.y=4.1;bar.visibility_range_end=70
	body.add_child(bar)
	enemies[id]={"node":body,"visual":visual,"label":bar,"kind":kind,"hp":hp,"max_hp":hp,"target":pos,"yaw":0.0,"attack":0.0,"stun":0.0,"taunt":-1,"speed":1.8 if kind=="Brute" else 2.7,"moving":false}
	if kind=="EmberRunner":enemies[id].speed=3.7
	if kind=="Prowler":enemies[id].speed=4.7
	if kind=="Shieldguard":enemies[id].speed=2.1
	enemies[id].merge({"camp":camp,"home":pos,"slow":0.0})
	if kind=="Chieftain":enemies[id].speed=2.0

func _nearest_enemy(pos:Vector3,radius:float)->int:
	var nearest:=-1
	for id in enemies:
		var distance:float=pos.distance_to(enemies[id].node.position)
		if distance<radius:nearest=int(id);radius=distance
	return nearest

func _simulate_enemies(delta:float)->void:
	# Local separation grid replaces all-pairs scans for the larger swarms.
	var buckets:Dictionary={}
	for other_id in enemies:
		var pos:Vector3=enemies[other_id].node.position
		var cell:=Vector2i(floori(pos.x/1.5),floori(pos.z/1.5))
		if not buckets.has(cell):buckets[cell]=[]
		buckets[cell].append(pos)
	for id in enemies.keys():
		if not enemies.has(id):continue
		var e:Dictionary=enemies[id]
		var body:CharacterBody3D=e.node
		e.attack=maxf(0,e.attack-delta)
		e.stun=maxf(0,e.stun-delta)
		e.slow=maxf(0,float(e.get("slow",0))-delta)
		var impulse:Vector3=e.get("impulse",Vector3.ZERO)
		if impulse.length()>.2:
			body.move_and_collide(impulse*delta);e.impulse=impulse.move_toward(Vector3.ZERO,14*delta)
		if e.stun>0:
			e.moving=false
			if FortEncounters.is_wild(int(e.get("camp",-1))):e.windup=0
			continue
		if expedition.simulate(e,delta):continue
		if encounters.simulate(e,delta):continue
		if raiders.simulate(int(id),e,delta):continue
		if int(e.get("camp",-1))>=0:
			_simulate_guard(e,delta)
			continue
		if e.kind=="Ashwing":
			_simulate_ashwing(e,delta)
			continue
		var target:=Vector3.ZERO
		var ally:FortPlayer=null
		var nearest:=8.0
		for p in players.values():
			if e.kind=="EmberRunner":break
			var distance:float=body.position.distance_to(p.position)
			if distance<nearest and p.health>0:
				nearest=distance;ally=p;target=p.position
		var siege_target:=FortSiege.priority(self,e)
		if siege_target>=0:target=defenses[siege_target].node.position;ally=null
		var block_id:int=int(e.get("breach",-1)) if defenses.has(int(e.get("breach",-1))) else siege_target
		if not defenses.has(block_id):block_id=-1
		if block_id>=0:
			var d:Dictionary=defenses[block_id]
			var strike_reach:float=FortPlacement.wall_width(d.kind)*.5+.9 if FortPlacement.is_wall(d.kind) else 2.3
			if body.position.distance_to(d.node.position)<strike_reach:FortSiege.strike(self,e,block_id);continue
		var to_target:Vector3=target-body.position
		to_target.y=0
		var reach:=1.6 if ally else 2.45
		if siege_target<0 and to_target.length()<reach:
			e.moving=false
			if e.kind=="Sapper":raiders.arm(e);continue
			if e.attack<=0:
				e.attack=1.2
				if ally and absf(ally.position.y-body.position.y)<2.5:
					_set_health(ally.peer_id,ally.health-(19 if e.kind=="Brute" else 9))
				elif not ally:
					damage_fort(24 if e.kind in ["Sapper","EmberRunner"] else 11)
					broadcast("recv_fx",[body.position+Vector3.UP,Color("#ef9a64"),"","hit"])
					if fort_health<=0:broadcast("recv_end",[false]);return
			continue
		# Route through one of four actual gaps instead of sliding through the walls.
		var radius:=Vector2(body.position.x,body.position.z).length()
		if radius>9.0 and target.length()<8:
			var axis:=Vector3(signf(body.position.x),0,0) if absf(body.position.x)>absf(body.position.z) else Vector3(0,0,signf(body.position.z))
			var portal:=axis*10.5
			if body.position.distance_to(portal)<1.7:portal=axis*6.5
			to_target=portal-body.position
			to_target.y=0
		var direction:=FortSiege.route(self,e,body.position+to_target)
		var separation:=Vector3.ZERO
		var cell:=Vector2i(floori(body.position.x/1.5),floori(body.position.z/1.5))
		for x in range(-1,2):
			for z in range(-1,2):
				for other_pos in buckets.get(cell+Vector2i(x,z),[]):
					var away:Vector3=body.position-other_pos
					if absf(away.y)>2:continue
					away.y=0
					if away.length_squared()>0.01 and away.length_squared()<0.8:separation+=away.normalized()*0.8
		direction=(direction+separation).normalized()
		body.velocity.x=direction.x*e.speed*(0.45 if e.slow>0 else 1.0)
		body.velocity.z=direction.z*e.speed*(0.45 if e.slow>0 else 1.0)
		body.velocity.y-=22*delta
		body.move_and_slide()
		body.rotation.y=lerp_angle(body.rotation.y,atan2(direction.x,direction.z),delta*8)
		e.moving=true

func _simulate_ashwing(e:Dictionary,delta:float)->void:
	var body:CharacterBody3D=e.node
	var target:=Vector3.ZERO
	var ally:FortPlayer=null
	var nearest:=9.0
	for p in players.values():
		var d:=Vector2(p.position.x-body.position.x,p.position.z-body.position.z).length()
		if p.health>0 and d<nearest:nearest=d;ally=p;target=p.position
	var offset:=Vector3(target.x-body.position.x,0,target.z-body.position.z)
	var reach:=1.5 if ally else 2.6
	if offset.length()<6 and e.attack<=1.0 and float(e.get("dive_at",0))==0:
		e.dive_at=clock+.65;broadcast("recv_fx",[target+Vector3.UP*.1,Color("#edbe7b"),"DIVE INCOMING","siege_warning"])
	var diving:bool=offset.length()<4.5 and e.attack<=1.0 and clock>=float(e.get("dive_at",INF))
	var height:float=target.y+0.55 if diving else maxf(3.8,target.y+3.0)+sin(clock*3.0+body.get_instance_id())*0.15
	body.velocity=offset.normalized()*3.5 if offset.length()>reach else Vector3.ZERO
	body.velocity.y=clampf((height-body.position.y)*4,-5,5)
	body.move_and_slide()
	if offset.length()>0.1:body.rotation.y=lerp_angle(body.rotation.y,atan2(offset.x,offset.z),delta*8)
	e.moving=true
	if offset.length()<reach+0.15 and absf(body.position.y-target.y)<1.1 and e.attack<=0:
		e.attack=2.8
		e.dive_at=0.0
		if ally:_set_health(ally.peer_id,ally.health-10)
		else:
			damage_fort(12)
			if fort_health<=0:broadcast("recv_end",[false])
		broadcast("recv_fx",[body.position,Color("#e5ae7a"),"DIVE","hit"])

func _simulate_guard(e:Dictionary,delta:float)->void:
	var body:CharacterBody3D=e.node
	var home:Vector3=FortProgression.SITES[e.camp].pos
	var target:FortPlayer=null
	var distance:=18.0
	for p in players.values():
		var d:=body.position.distance_to(p.position)
		if p.health>0 and p.position.distance_to(home)<24 and d<distance and (d<4 or FortSiege.clear(self,body.position,p.position)):distance=d;target=p
	if target and clock>float(e.get("alarm_until",0)):
		for guard in enemies.values():
			if int(guard.get("camp",-1))==int(e.camp):guard.alarm_until=clock+12;guard.investigate=target.position
		broadcast("recv_fx",[body.position+Vector3.UP*2,Color("#efb384"),"CAMP ALARM","siege_warning"])
	var patrol:Vector3=e.home+Vector3(sin(clock*.45+int(e.camp)*2)*2.5,0,cos(clock*.45+int(e.camp)*2)*2.5)
	var goal:Vector3=target.position if target else patrol
	if not target and clock<float(e.get("alarm_until",0)):goal=e.get("investigate",patrol)
	if float(e.get("slam_at",0))>clock:goal=body.position
	var offset:=goal-body.position;offset.y=0
	var reach:=3.4 if e.kind=="Chieftain" else 1.7
	if target and offset.length()<reach:
		e.moving=false
		if e.kind=="Chieftain":
			if e.attack<=0:
				e.attack=4.2;e.slam_at=clock+0.9
				broadcast("recv_fx",[body.position+Vector3.UP*0.15,Color("#ee985b"),"SLAM / MOVE!","ability"])
		elif e.attack<=0:e.attack=1.2;_set_health(target.peer_id,target.health-12)
	else:
		var direction:=offset.normalized() if offset.length()>1 else Vector3.ZERO
		direction=_steer_around_scenery(body,direction,body.get_instance_id(),e)
		body.velocity=direction*e.speed*(0.45 if e.slow>0 else 1.0)+Vector3(0,body.velocity.y-22*delta,0)
		body.move_and_slide();e.moving=direction.length()>0
		if direction.length()>0:body.rotation.y=lerp_angle(body.rotation.y,atan2(direction.x,direction.z),delta*8)
	if float(e.get("slam_at",0))>0 and clock>=float(e.slam_at):
		e.slam_at=0
		for p in players.values():
			if p.health>0 and p.position.distance_to(body.position)<4.8:_set_health(p.peer_id,p.health-32)
		broadcast("recv_fx",[body.position,Color("#ee985b"),"","hammer"])

func _steer_around_scenery(body:CharacterBody3D,direction:Vector3,id:int,enemy:Dictionary)->Vector3:
	if clock<float(enemy.get("avoid_until",0.0)):return enemy.avoid_direction
	if clock<float(enemy.get("clear_until",0.0)):return direction
	var start:=body.position+Vector3.UP*0.75
	var query:=PhysicsRayQueryParameters3D.create(start,start+direction*1.65,1)
	var state:=get_world_3d().direct_space_state
	if state.intersect_ray(query).is_empty():enemy.clear_until=clock+0.15;return direction
	var side:=1.0 if id%2==0 else -1.0
	for turn in [0.85,1.35,-0.85,-1.35,1.8]:
		var candidate:=direction.rotated(Vector3.UP,turn*side)
		query.to=start+candidate*1.8
		if state.intersect_ray(query).is_empty():
			enemy.avoid_until=clock+0.5
			enemy.avoid_direction=candidate
			return candidate
	return direction.rotated(Vector3.UP,side*PI*0.5)

func _animate_enemies(delta:float)->void:
	for id in enemies:
		var e:Dictionary=enemies[id]
		var body:Node3D=e.node
		if not multiplayer.is_server():
			e.moving=body.position.distance_to(e.target)>0.04
			body.position=body.position.lerp(e.target,1-exp(-14*delta))
			body.rotation.y=lerp_angle(body.rotation.y,e.yaw,1-exp(-14*delta))
		FortArt.animate_enemy(e.visual,clock+int(id)*0.3,e.attack>0.85,e.moving)
		e.label.text="%d"%ceili(e.hp) if e.hp<e.max_hp else ""
		if FortEncounters.is_wild(int(e.get("camp",-1))):e.label.text=e.kind+" / %d"%ceili(e.hp);e.label.visibility_range_end=38
	for d in defenses.values():
		var label:Label3D=d.node.get_node("Status")
		label.text="%s · %d%%"%[d.kind,int(d.hp/d.max_hp*100)]
		var p:=local_player()
		label.visible=false

func _damage_enemy(id:int,damage:float,knockback:=Vector3.ZERO,source:="player_damage",piercing:=false)->void:
	if not enemies.has(id):return
	var e:Dictionary=enemies[id]
	if e.kind=="Shieldguard" and source in ["tower_damage","field_turret_damage"] and not piercing:damage*=.7
	director.record(source,minf(e.hp,damage))
	e.hp-=damage
	var resistance:=.12 if e.kind=="Colossus" or e.kind in FortEncounters.DRAGONS else (.4 if e.kind in ["Brute","Chieftain","Shieldguard","Stonebear"] else 1.0)
	e.impulse=(e.get("impulse",Vector3.ZERO)+knockback*5.0*resistance).limit_length(22)
	broadcast("recv_enemy_hit",[id,e.hp,damage])
	if e.hp<=0:
		var boss:bool=e.kind=="Colossus"
		if int(e.get("camp",-1))<0 and not FortEncounters.is_wild(int(e.get("camp",-1))):director.record("killed",1)
		broadcast("recv_enemy_dead",[id])
		if boss:expedition.boss_killed()

func recv_enemy_hit(id:int,hp:float,amount:float)->void:
	if not enemies.has(id):return
	enemies[id].hp=hp
	recv_fx(enemies[id].node.position+Vector3.UP*1.5,Color("#f5d3a0"),str(int(amount)),"hit")
	var visual:Node3D=enemies[id].visual
	var anim:=FortPlayer.find_animation(visual)
	if anim and anim.has_animation("Hit"):anim.play("Hit",0.06)
	var tween:=create_tween()
	var original:Vector3=visual.scale
	tween.tween_property(visual,"scale",original*Vector3(1.12,0.88,1.12),0.07)
	tween.tween_property(visual,"scale",original,0.10)

func recv_enemy_dead(id:int)->void:
	if not enemies.has(id):return
	var body:Node3D=enemies[id].node
	var anim:=FortPlayer.find_animation(enemies[id].visual)
	if anim and anim.has_animation("Death"):anim.play("Death",0.08)
	enemies.erase(id)
	body.set_physics_process(false)
	if body is CollisionObject3D:body.collision_layer=0
	var tween:=create_tween().set_parallel()
	if not anim:tween.tween_property(body,"rotation:z",1.5,0.30)
	tween.tween_property(body,"scale",Vector3.ONE*0.03,0.35).set_delay(0.8)
	tween.chain().tween_callback(body.queue_free)

func _damage_defense(id:int,amount:float)->void:
	if not defenses.has(id):return
	director.record("building_damage",minf(defenses[id].hp,amount))
	defenses[id].hp-=amount
	broadcast("recv_fx",[defenses[id].node.position+Vector3.UP,Color("#d99564"),"","hit"])
	if defenses[id].hp<=0:broadcast("recv_remove_defense",[id])

func damage_fort(amount:float)->void:
	director.record("fort_damage",minf(fort_health,amount))
	fort_health=maxf(0,fort_health-amount)

func _set_health(id:int,value:float)->void:
	if not players.has(id):return
	var p:FortPlayer=players[id]
	if value<p.health and (p.invulnerable>0 or p.health<=0):return
	if value<p.health and p.armor:value=p.health-(p.health-value)*0.8
	value=clampf(value,0,p.max_health)
	if value<=0:
		p.down_time=18.0
		director.record("downs",1)
		if is_night and players.size()==1 and director.crew==1 and solo_rescue_wave!=wave:
			solo_rescue_wave=wave;p.down_time=8.0;director.record("fast_rescues",1)
		revive_progress[id]=0
		if p.mounted_ballista>=0:_mount(id,-1)
		broadcast("recv_notice",["%s is down! Hold E beside them to revive."%p.display_name])
		if players.size()==1:personal(id,"Emergency rescue in %d seconds. Your pack is safe."%int(p.down_time))
	broadcast("recv_health",[id,value,p.down_time])

func recv_health(id:int,value:float,down:float)->void:
	if not players.has(id):return
	var p:FortPlayer=players[id]
	if value<p.health and p.is_local_player():
		hud.damage.color.a=0.28
		sound.play("hurt",-10)
	p.health=value;p.down_time=down
	if value>0:p.visual_root.rotation.z=0

func _respawn(id:int)->void:
	var p:FortPlayer=players[id]
	# The pack is retained; a rescue costs time, not an unrecoverable resource loss.
	p.invulnerable=4.0
	broadcast("recv_teleport",[id,Vector3((p.class_id-1.5)*1.3,0.2,5)])
	broadcast("recv_health",[id,p.max_health*0.65,0.0])
	broadcast("recv_notice",["%s was rescued at the hearth."%p.display_name])

func recv_teleport(id:int,pos:Vector3)->void:
	if not players.has(id):return
	var p:FortPlayer=players[id]
	p.position=pos;p.target_position=pos;p.velocity=Vector3.ZERO
	p.invulnerable=4

func recv_fx(pos:Vector3,color:Color,message:String,sfx:String,end:=Vector3.INF)->void:
	if sfx.begins_with("wild_"):FortEncounters.fx(self,pos,end,color,message,sfx);return
	if sfx=="mend":FortBattlements.mend_fx(self,pos,end);return
	if sfx in ["enemy_shell","bomb_drop","blast","fuse","boss_slam"]:FortRaidcraft.fx(self,pos,end,sfx);return
	var p:=local_player()
	var nearby:=p==null or p.position.distance_to(pos)<22
	if nearby and not sfx.is_empty():sound.play(sfx,-15)
	if sfx=="construction":sound.play("hammer",-20)
	if sfx=="arc":FortArcFX.lightning(self,pos,end,color);return
	if sfx=="frost_shell":FortArcFX.shell(self,pos,end,color);return
	if message=="bolt":
		var bolt:=FortArt.asset("bolt")
		if sfx=="crossbow":bolt.scale*=0.55
		bolt.position=pos
		add_child(bolt)
		if pos.distance_to(end)>0.01:bolt.look_at(end)
		var tween:=create_tween()
		tween.tween_property(bolt,"position",end,0.16)
		tween.tween_callback(bolt.queue_free)
		return
	if not message.is_empty():
		var text:=Visuals.label_3d(message,color,0)
		text.position=pos
		text.font_size=28 if message.length()<6 else 24
		add_child(text)
		var tween:=create_tween().set_parallel()
		tween.tween_property(text,"position:y",pos.y+1.0,0.95)
		tween.tween_property(text,"modulate:a",0.0,0.95)
		tween.chain().tween_callback(text.queue_free)
	_ring(pos,color,4.0 if sfx=="ability" else 0.8,0.5)
	for i in 5:
		var chip:=Visuals.box(Vector3.ONE*0.10,color,pos)
		add_child(chip)
		var dest:=pos+Vector3(randf_range(-0.8,0.8),randf_range(0.3,1.1),randf_range(-0.8,0.8))
		var tween:=create_tween().set_parallel()
		tween.tween_property(chip,"position",dest,0.35)
		tween.tween_property(chip,"scale",Vector3.ONE*0.01,0.40)
		tween.chain().tween_callback(chip.queue_free)

func _ring(pos:Vector3,color:Color,radius:float,duration:float)->void:
	var mesh:=TorusMesh.new()
	mesh.inner_radius=0.9;mesh.outer_radius=1
	mesh.rings=24;mesh.ring_segments=6
	var node:=MeshInstance3D.new()
	node.mesh=mesh
	var mat:=Visuals.material(Color(color,0.7))
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override=mat
	node.position=pos+Vector3.UP*0.1
	node.scale=Vector3.ONE*0.2
	add_child(node)
	var tween:=create_tween().set_parallel()
	tween.tween_property(node,"scale",Vector3(radius,0.12,radius),duration)
	tween.tween_property(mat,"albedo_color:a",0.0,duration)
	tween.chain().tween_callback(node.queue_free)

func personal(id:int,message:String)->void:
	if id==multiplayer.get_unique_id():show_toast(message)
	elif get_parent().has_method("send_personal_event"):get_parent().send_personal_event(id,"notice",{"text":message})

func recv_notice(message:String)->void:
	show_toast(message,4)

func show_toast(message:String,duration:=3.0)->void:
	toast_text=message;toast_time=duration

func toggle_pause()->void:
	if hud.upgrade_menu.visible: hud.upgrade_menu.close_panel();return
	if hud.hearth_menu.visible:
		hud.hearth_menu.close_panel()
		return
	if forge_open:
		forge_open=false;menu_open=false;hud.forge.hide()
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		return
	menu_open=not menu_open
	hud.menu.visible=menu_open
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED

func open_forge()->void:
	if ended or menu_open:return
	forge_open=true;menu_open=true
	hud.forge.show();hud.menu.hide()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func objective_text()->String:
	for e in enemies.values():
		if e.kind=="Colossus":return "COLOSSUS / %d%% HEALTH\nDodge the slam. It does not retreat at dawn."%ceili(e.hp/e.max_hp*100)
	if is_night:return director.status()+"\n%d enemies / %d-dwarf pressure"%[enemies.size(),director.crew]
	if not expedition.event_name.is_empty():return expedition.event_name.to_upper()+" / "+expedition.event_description()
	if wave==0 and clock<35:return "Hold E at trees and rocks. Deposit at the stockpile. B opens building."
	if workshop_level<2:return "Deposit crystal for horses  %d / 8  ·  Enter when ready for night"%lifetime_crystal
	if workshop_level<3:return "Deposit crystal for jetpacks  %d / 20  ·  Enter when ready"%lifetime_crystal
	return "Workshop complete. Build, repair, and prepare for night. Enter when ready."

func context_prompt(p:FortPlayer)->String:
	if expedition.event_name=="Supply Caravan" and not expedition.event_claimed and p.position.distance_to(FortExpedition.CACHE_POS)<3:return "E / Claim caravan supplies for the crew"
	if p.mounted_ballista>=0:return "HOLD CLICK fire ballista   /   E dismount"
	for ally in players.values():
		if ally.health<=0 and p.position.distance_to(ally.position)<2.7:return "HOLD E   Revive "+ally.display_name
	if p.position.distance_to(Vector3(4.6,0,0))<3.2 and p.total_carried()>0:return "E   Deposit pack into SHARED stockpile"
	if p.position.distance_to(Vector3(-4.6,0,0))<3.2:return "E   Open WORKSHOP   /   Craft & equip weapons"
	var work_id:=construction.nearest(p)
	if work_id>=0:return "HOLD E   %s %d%%   /   Crew can help   /   G project"%[defenses[work_id].kind,int(FortConstruction.fraction(defenses[work_id])*100)]
	var chest:=progression.nearest(p.position)
	var wild_chest:=encounters.nearest(p.position)
	if wild_chest>=0:return "TREASURE CLAIMED BY CREW" if encounters.sites[wild_chest].phase=="claimed" else "E / Wilderness treasure — defeat guardians first (no key cost)"
	if chest>=0:return "E   Chest / 2 shared crystal   ·   Defeat guards first" if not progression.sites[chest].opened else "CHEST CLAIMED BY CREW"
	if _nearest_defense(p.position,"Ballista",3.0)>=0:return "E   Mount ballista   /   G upgrade   /   R repair"
	if _nearest_defense(p.position,"",4)>=0:return "G   Upgrade defense   /   R repair"
	if p.position.length()<5 and not is_night:return "U   Hearth upgrades / expand frontier   ·   R repair"
	var id:=nearest_resource(p.position)
	if id>=0:
		var r:Dictionary=resource_nodes[id]
		var requirement:=FortForestry.requirement(r,p)
		return requirement if not requirement.is_empty() else "HOLD E   %s / %s   ·   %d remaining"%[FortForestry.title(r),r.kind,r.amount]
	if _nearest_defense(p.position,"Ballista",3.0)>=0:return "E   Mount ballista   /   Hold R repair"
	if p.position.length()<9.5:return "HOLD R   Repair hearth   ·   1 shared wood"
	if _nearest_defense(p.position,"",3.5)>=0:return "HOLD R   Repair defense   ·   1 shared wood"
	return ""

func direction_to_home(p:FortPlayer)->String:
	if p.position.length()<10:return "Inside Hearthhold"
	var target:=Vector3(-p.position.x,0,-p.position.z).normalized()
	var forward:=p.aim_direction()
	var angle:=forward.signed_angle_to(target,Vector3.UP)
	if absf(angle)<0.45:return "Ahead"
	if absf(angle)>2.65:return "Behind you"
	return "Turn left" if angle>0 else "Turn right"

func build_description()->String:
	var kind:String=GameData.BUILD_ORDER[selected_build]
	var recipe:Dictionary=GameData.RECIPES[kind]
	var p:=local_player()
	var factor:=0.75 if p and p.class_id==2 else 1.0
	var cost:Dictionary={}
	for resource in GameData.RESOURCES:cost[resource]=ceili(int(recipe.get(resource,0))*factor)
	return "%s · %s\nBuild reach: %dm  ·  1–9 / 0 choose  ·  Q rotate\nCLICK place   B close   |   %s"%[kind,GameData.supplies_text(cost,true),int(build_radius()),"Valid placement" if preview_valid else "Blocked or missing resources"]

func recv_end(victory:bool)->void:
	if ended:return
	if multiplayer.is_server():director.finish()
	ended=true
	if forge_open:toggle_pause()
	local_build_mode=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var panel:=hud.panel(Vector2(350,220),Vector2(580,260))
	var stack:=VBoxContainer.new();stack.alignment=BoxContainer.ALIGNMENT_CENTER;stack.add_theme_constant_override("separation",20);panel.add_child(stack)
	var title:=Label.new();title.text="THE HEARTH ENDURES" if victory else "THE FORT HAS FALLEN";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",32);stack.add_child(title)
	var details:=Label.new();details.text="Ten nights survived. The crew brought everyone home." if victory else "Rally the crew. Build overlapping defenses and keep repairs going.";details.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;details.add_theme_font_size_override("font_size",16);stack.add_child(details)
	var button:=Button.new();button.text="Return to title";button.custom_minimum_size.y=50;button.pressed.connect(func():return_to_menu.emit("Ready for another expedition."));stack.add_child(button)
