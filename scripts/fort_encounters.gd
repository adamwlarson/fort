class_name FortEncounters
extends RefCounted

const CREATURES := ["Razorback","Direwolf","Stonebear","Emberdrake","Frostwyrm"]
const DRAGONS := ["Emberdrake","Frostwyrm"]
const TYPES := ["cache","beasts","camp","shrine","ruins","dragon"]
const TITLES := {"cache":"Lost Caravan","beasts":"Beast Den","camp":"Blackthorn Outpost","shrine":"Forgotten Shrine","ruins":"Starwatch Ruins","dragon":"Dragon Roost"}
const COLORS := {"cache":Color("#e9c56e"),"beasts":Color("#baaa77"),"camp":Color("#de986b"),"shrine":Color("#9bd6cb"),"ruins":Color("#c0b3db"),"dragon":Color("#f28c65")}
static var layouts: Dictionary = {}
var world: FortWorld
var sites: Dictionary = {}
var layout_seed := -1
var revision := 0
var unlocked: PackedStringArray = []
var next_check := 0.0

func _init(w: FortWorld) -> void: world = w
static func is_wild(camp: int) -> bool: return camp <= -1000
static func site_id(camp: int) -> int: return -camp - 1000
static func layout(seed_value: int) -> Array:
	if layouts.has(seed_value): return layouts[seed_value]
	var result: Array = []; var random := RandomNumberGenerator.new(); random.seed = seed_value + 110011
	for tier in range(1,9):
		var count := 3 if tier == 1 else (6 if tier == 2 else (8 if tier == 3 else 10))
		var radius: float = [0,55,113,201,283,363,443,523,603][tier]
		var rotation := random.randf_range(.15,.5)
		for i in count:
			var kind: String = TYPES[i % TYPES.size()]
			if tier == 1: kind = ["beasts","cache","camp"][i]
			if kind == "dragon" and tier < 3: kind = "ruins"
			var angle := rotation + i * TAU / count
			var pos := Vector3(sin(angle),0,cos(angle)) * radius
			if tier == 1: pos = [Vector3(-12,0,55),Vector3(8,0,-55),Vector3(48,0,-30)][i]
			# Keep authored villages, quarry ramps and other sites intact.
			for attempt in 24:
				var clear := not (tier == 2 and pos.x > 70 and absf(pos.z) < 48)
				for old in FortProgression.SITES:
					if pos.distance_to(old.pos)<30: clear=false
				for old in result:
					if pos.distance_to(old.pos)<30: clear=false
				if clear: break
				angle += .065; pos = Vector3(sin(angle),0,cos(angle)) * radius
			result.append({"id":tier*100+i,"tier":tier,"type":kind,"pos":pos,"radius":18.0 if kind=="dragon" else 12.0,
				"name":"%s %s" % [["Moss","Ash","Moon","Thorn","Frost","Sun","Rune","Star"][(i+tier)%8], TITLES[kind]]})
	layouts[seed_value]=result
	return result

static func reserved(pos: Vector3, tier: int, seed_value: int) -> bool:
	if tier==2 and FortTerrain.reserved(pos,seed_value,3):return true
	for spec in layout(seed_value):
		if spec.tier==tier and pos.distance_to(spec.pos)<spec.radius+2: return true
	return false

func unlock(level: int) -> void:
	if layout_seed != world.expedition.seed_value:
		for site in sites.values(): site.node.queue_free()
		sites.clear(); layout_seed=world.expedition.seed_value; revision=0; unlocked.clear()
		world.scenery_keepouts=world.scenery_keepouts.filter(func(k):return not k.get("wilderness",false))
	for spec in layout(layout_seed):
		if spec.tier>level or sites.has(spec.id): continue
		var root:=Node3D.new(); root.name="Wilderness%d"%spec.id; root.position=spec.pos; world.add_child(root)
		var chest:=FortArt.asset("treasure_chest"); chest.position=Vector3(0,0,-4); root.add_child(chest)
		var label:=Visuals.label_3d(spec.name, COLORS[spec.type],3.1); label.font_size=18; label.visibility_range_end=65; root.add_child(label)
		sites[spec.id]={"spec":spec,"node":root,"chest":chest,"label":label,"phase":"sleeping","seen":false,"crew":0,"away":0.0}
		_build_site(sites[spec.id])
		world.scenery_keepouts.append({"pos":spec.pos,"radius":spec.radius,"wilderness":true})

func _prop(root:Node3D,key:String,pos:Vector3,scale:=1.0) -> Node3D:
	var node:=FortLandscape.place(root,key,pos,0,scale)
	for mesh in node.find_children("*","GeometryInstance3D",true,false): mesh.visibility_range_end=170
	return node

func _build_site(site: Dictionary) -> void:
	var root:Node3D=site.node; var kind:String=site.spec.type
	# A dressed clearing, not just a chest in an otherwise empty field.
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array()
	for i in 96:
		var a:=i*TAU/96;var b:=(i+1)*TAU/96
		for pos in [Vector3.ZERO,Vector3(sin(a),0,cos(a))*(site.spec.radius+sin(a*7)*.7),Vector3(sin(b),0,cos(b))*(site.spec.radius+sin(b*7)*.7)]:
			vertices.append(pos+Vector3.UP*.06);normals.append(Vector3.UP)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
	var ground_mesh:=ArrayMesh.new();ground_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var floor_node:=MeshInstance3D.new();floor_node.mesh=ground_mesh;root.add_child(floor_node)
	var soil:Color=world.expedition.biome(site.spec.tier).color if site.spec.tier>=4 else (Color("#64704e") if site.spec.tier<=2 else Color("#7f8d95"))
	var ground:=ShaderMaterial.new();ground.shader=preload("res://assets/shaders/site_ground.gdshader");ground.set_shader_parameter("soil_color",soil);ground.set_shader_parameter("radius",site.spec.radius);floor_node.material_override=ground
	var key:String={"cache":"wrecked_caravan","beasts":"beast_den","camp":"bandit_totem","shrine":"forgotten_shrine","ruins":"ruined_observatory","dragon":"dragon_nest"}[kind]
	_prop(root,key,Vector3(0,0,3))
	if kind=="beasts":
		for x in [-3,3]: FortArt.box_collider(root,Vector3(1.4,2.8,2),Vector3(x,1.4,1.8))
		FortArt.box_collider(root,Vector3(5,1.1,2),Vector3(0,3,1.8))
	elif kind=="camp":
		for x in [-6,6]:
			var tent:=_prop(root,"camp_tent",Vector3(x,0,3),1.3); FortArt.box_collider(tent,Vector3(2,1.4,2),Vector3(0,.7,0))
		_prop(root,"supply_crate",Vector3(-6,0,-3));_prop(root,"supply_crate",Vector3(6,0,-3))
		FortArt.box_collider(root,Vector3(.6,6,.6),Vector3(0,3,3))
	elif kind in ["shrine","ruins"]:
		for x in [-3,3]:
			for z in ([0,6] if kind=="ruins" else [3]):FortArt.box_collider(root,Vector3(1,5,1),Vector3(x,2.5,z))
	elif kind=="cache":FortArt.box_collider(root,Vector3(2.5,1.8,4),Vector3(0,.9,3))
	for i in 8:
		var angle:=i*TAU/8; var pos:Vector3=Vector3(sin(angle),0,cos(angle))*(site.spec.radius-1)
		if absf(pos.x)<3:continue # Clear entrances.
		_prop(root,"moss_rock",pos,.7 if i%2 else 1.3)
		_prop(root,"fern",pos+Vector3(1,0,.5),1.5)
	var sign:=_prop(root,"trail_sign",Vector3(-3,0,-site.spec.radius+1))
	sign.rotation.y=PI
	var random:=RandomNumberGenerator.new();random.seed=int(site.spec.id)*721
	for i in 7:
		var distance:=float(site.spec.radius)+5+i*3.5
		_prop(root,"moss_rock",Vector3(random.randf_range(-.7,.7),0,-distance),.15)
	_visual(site)

func state() -> Dictionary:
	var list:Dictionary={}
	for id in sites:
		var s:Dictionary=sites[id]
		if s.seen or s.phase!="sleeping":list[id]={"phase":s.phase,"seen":s.seen,"crew":s.crew}
	return {"seed":layout_seed,"revision":revision,"sites":list,"unlocked":unlocked}

func receive(data:Dictionary) -> void:
	if data.is_empty() or int(data.seed)!=layout_seed or int(data.revision)<revision:return
	revision=data.revision;unlocked=PackedStringArray(data.get("unlocked",[]))
	for raw_id in data.sites:
		var id:=int(raw_id)
		if not sites.has(id):continue
		sites[id].merge(data.sites[raw_id],true);_visual(sites[id])

func _visual(site:Dictionary) -> void:
	var text:="HEARTH %d / %s"%[site.spec.tier,site.spec.name]
	if site.phase=="claimed":text="CLAIMED / "+site.spec.name
	elif site.phase=="cleared":text+="\nE / FREE CREW TREASURE"
	elif site.phase=="active":text+="\nDEFEAT THE ENCOUNTER"
	site.label.text=text
	var lid:Node3D=site.chest.find_child("Lid*",true,false)
	if lid:lid.rotation.x=-1.2 if site.phase=="claimed" else 0

func members(id:int) -> Array[int]:
	var result:Array[int]=[]
	for enemy_id in world.enemies:
		if int(world.enemies[enemy_id].get("camp",-1))==-1000-id:result.append(enemy_id)
	return result

func roster(spec:Dictionary,crew:int) -> Array[String]:
	var list:Array[String]=[]
	match spec.type:
		"cache":return list
		"dragon":list.append("Frostwyrm" if spec.tier%2==0 else "Emberdrake")
		"beasts":
			list.append("Razorback" if spec.tier==1 else "Stonebear")
			for i in 1+int(crew/2):list.append("Direwolf")
		"camp":
			for i in 1+crew:list.append("Shieldguard" if i==0 and spec.tier>=3 else "Raider")
		"shrine","ruins":
			list.append("Hexer" if spec.tier>=3 else "Raider")
			for i in crew:list.append("Stonebear" if i==0 and spec.tier>=4 else "Direwolf")
	return list

func activate(id:int) -> void:
	if not world.multiplayer.is_server() or not sites.has(id):return
	var site:Dictionary=sites[id]
	if site.phase!="sleeping":return
	var crew:=clampi(world.players.size(),1,GameData.MAX_PLAYERS);var list:=roster(site.spec,crew);var live:=0
	for enemy in world.enemies.values():
		if is_wild(int(enemy.get("camp",-1))):live+=1
	if live+list.size()>24:return
	site.crew=crew;site.phase="cleared" if list.is_empty() else "active";site.away=0;revision+=1
	for i in list.size():
		var kind:String=list[i];var tier:int=site.spec.tier
		var hp:float=(720+(tier-3)*260 if kind in DRAGONS else (130+tier*25 if kind in ["Stonebear","Shieldguard"] else 65+tier*14))*FortBalance.wilderness_multiplier(crew)
		world.broadcast("recv_enemy",[2000000+id*16+i,kind,site.spec.pos+Vector3((i-list.size()*.5)*2,0,-1),hp,-1000-id])
	_visual(site)

func tick() -> void:
	if world.clock<next_check:return
	next_check=world.clock+.35
	for id in sites:
		var site:Dictionary=sites[id];var distance:=INF
		for p in world.players.values():
			if p.health>0:distance=minf(distance,p.position.distance_to(site.spec.pos))
		if distance<48 and not site.seen:
			site.seen=true;revision+=1
			world.broadcast("recv_notice",["DISCOVERED / %s. %s"%[site.spec.name,"Dragon territory — bring your crew!" if site.spec.type=="dragon" else "Explore and claim shared treasure."]])
		if distance<28:activate(id)
		if site.phase=="active":
			if members(id).is_empty():site.phase="cleared";revision+=1;_visual(site)
			elif distance>80:
				if site.away==0:site.away=world.clock
				elif world.clock-site.away>30:
					for enemy_id in members(id):world.broadcast("recv_enemy_dead",[enemy_id])
					site.phase="sleeping";site.away=0;revision+=1;_visual(site)
			else:site.away=0

func nearest(pos:Vector3) -> int:
	for id in sites:
		if pos.distance_to(sites[id].chest.global_position)<3:return id
	return -1

func interact(player_id:int) -> bool:
	if not world.multiplayer.is_server() or not world.players.has(player_id):return false
	var p:FortPlayer=world.players[player_id];var id:=nearest(p.position)
	if id<0 or p.health<=0:return false
	var site:Dictionary=sites[id];activate(id)
	if site.phase=="active" and members(id).is_empty():site.phase="cleared"
	if site.phase!="cleared":
		world.personal(player_id,"Treasure already claimed." if site.phase=="claimed" else "Defeat this site's guardians first.");return true
	site.phase="claimed";site.seen=true;revision+=1
	var tier:int=site.spec.tier;var rare:bool=site.spec.type=="dragon"
	var received:Dictionary={};var new_items:Array=[]
	for resource in GameData.RESOURCES:
		if resource=="iron" and tier<2 or resource=="aether" and tier<3:continue
		var amount:=int((12+tier*3 if resource in ["wood","stone"] else 3+tier)*(2 if rare else 1))
		world.shared[resource]+=amount;received[resource]=amount
	var weapon:=""
	if rare:weapon="Greatmaul" if tier<=4 else ("Runestaff" if tier<=6 else "Runeblade")
	elif site.spec.type=="ruins" and tier>=2:weapon="Warpick" if tier<=3 else "Longrifle"
	if not weapon.is_empty() and weapon not in unlocked:unlocked.append(weapon);new_items.append(weapon)
	if rare and "Ironheart" not in world.progression.unlocked:world.progression.unlocked.append("Ironheart");new_items.append("Ironheart")
	for dwarf in world.players.values():world.progression.grant_loot(dwarf);grant_loot(dwarf)
	_visual(site)
	world.broadcast("recv_full",[world.full_state()])
	world.broadcast("recv_notice",[site.spec.name+" / Treasure deposited for the whole crew!"+(" Unlocked "+weapon+"." if not weapon.is_empty() else "")])
	world.broadcast("recv_fx",[site.chest.global_position+Vector3.UP,COLORS[site.spec.type],"CREW TREASURE","ability"])
	world.broadcast("recv_loot",[site.spec.name,received,new_items,{}])
	return true

func grant_loot(p:FortPlayer) -> void:
	var owned:=p.owned_weapons.duplicate();var changed:=false
	for weapon in unlocked:
		if weapon not in owned:owned.append(weapon);changed=true
	if changed:world.broadcast("recv_loadout",[p.peer_id,owned,p.weapon,p.loadout_revision+1])

func guidance(pos:Vector3) -> String:
	var closest:Dictionary={};var distance:=160.0
	for site in sites.values():
		var d:float=pos.distance_to(site.spec.pos)
		if site.phase!="claimed" and d<distance:closest=site;distance=d
	if closest.is_empty() or pos.length()<24:return ""
	var delta:Vector3=closest.spec.pos-pos
	var bearing:String=["N","NE","E","SE","S","SW","W","NW"][posmod(roundi(atan2(delta.x,-delta.z)/(PI/4)),8)]
	return "%s · %dm %s"%[closest.spec.name if closest.seen else "Unexplored landmark",int(distance),bearing]

func simulate(e:Dictionary,delta:float) -> bool:
	var camp:=int(e.get("camp",-1))
	if not is_wild(camp):return false
	var id:=site_id(camp)
	if not sites.has(id):return true
	var site:Dictionary=sites[id];var home:Vector3=site.spec.pos;var body:CharacterBody3D=e.node
	var target:FortPlayer=null;var nearest_distance:=34.0
	for p in world.players.values():
		if p.health<=0 or p.position.distance_to(home)>42:continue
		var d:float=p.position.distance_to(body.position)
		if d<nearest_distance and (d<5 or FortSiege.clear(world,body.position,p.position)):target=p;nearest_distance=d
	if body.position.distance_to(home)>48 or body.position.y < -5:
		body.position=home;e.windup=0;e.hp=e.max_hp;e.impulse=Vector3.ZERO;e.attack=3
		world.broadcast("recv_fx",[home,COLORS[site.spec.type],"RETREAT","ability"])
	var dragon:bool=e.kind in DRAGONS
	if float(e.get("windup",0))>0:
		e.moving=false
		if world.clock>=float(e.windup):
			e.windup=0
			if target:_strike(e,site)
		return true
	if target and e.attack<=0:
		var special:bool=dragon or e.kind in ["Razorback","Stonebear","Hexer"]
		var reach:=16.0 if dragon or e.kind=="Hexer" else (9.0 if e.kind=="Razorback" else 4.5)
		if special and nearest_distance<reach:
			e.attack=6.0 if dragon else 4.0;e.windup=world.clock+1.4;e.strike_origin=body.position;e.strike_goal=target.position
			e.strike_shape="cone" if e.kind=="Emberdrake" else ("charge" if e.kind=="Razorback" else "circle")
			if e.kind=="Stonebear":e.strike_goal=body.position
			world.broadcast("recv_fx",[e.strike_origin,Color("#e8aa63") if e.kind!="Frostwyrm" else Color("#9ae0eb"),"DODGE / "+e.kind,"wild_"+e.strike_shape,e.strike_goal])
			return true
		if not special and nearest_distance<1.8:
			e.attack=1.5;world._set_health(target.peer_id,target.health-(12 if e.kind=="Direwolf" else 15));return true
	# Patrol the site until alerted; never target the fort or chase homebound players.
	var goal:Vector3=target.position if target else home+Vector3(sin(world.clock*.18+id)*7,0,cos(world.clock*.18+id)*7)
	if dragon and target and nearest_distance<8:goal=body.position
	var offset:=goal-body.position;offset.y=0
	var direction:=world._steer_around_scenery(body,offset.normalized(),body.get_instance_id(),e) if offset.length()>1 else Vector3.ZERO
	var speed:=4.4 if e.kind=="Direwolf" else (2.3 if dragon else 2.8)
	body.velocity=direction*speed*(.45 if e.slow>0 else 1.0)+Vector3(0,body.velocity.y-22*delta,0)
	body.move_and_slide();e.moving=direction.length()>.1
	var facing:Vector3=target.position-body.position if target else offset
	if facing.length()>.1:body.rotation.y=lerp_angle(body.rotation.y,atan2(facing.x,facing.z),delta*5)
	return true

static func in_strike(point:Vector3,origin:Vector3,goal:Vector3,shape:String) -> bool:
	if shape=="circle":return point.distance_to(goal)<4.5
	var direction:=goal-origin;direction.y=0;direction=direction.normalized()
	var offset:=point-origin;offset.y=0
	if absf(point.y-origin.y)>3:return false
	if shape=="cone":return offset.length()<16 and direction.dot(offset.normalized())>cos(PI/5)
	var along:=offset.dot(direction)
	return along>=0 and along<origin.distance_to(goal)+2 and (offset-direction*along).length()<1.8

func _strike(e:Dictionary,site:Dictionary) -> void:
	var dragon:bool=e.kind in DRAGONS
	for p in world.players.values():
		if p.health<=0 or p.position.distance_to(site.spec.pos)>44:continue
		if in_strike(p.position,e.strike_origin,e.strike_goal,e.strike_shape) and FortSiege.clear(world,e.strike_origin,p.position):
			world._set_health(p.peer_id,p.health-(38 if dragon else 23))
	world.broadcast("recv_fx",[e.strike_origin,Color("#ee8744") if e.kind=="Emberdrake" else Color("#a4d5df"),"",("wild_fire" if e.kind=="Emberdrake" else "wild_ice") if dragon else "wild_impact",e.strike_goal])
	if e.strike_shape=="charge":e.node.move_and_collide((e.strike_goal-e.node.position).limit_length(7))

static func fx(w:FortWorld,origin:Vector3,goal:Vector3,color:Color,message:String,kind:String) -> void:
	if kind in ["wild_fire","wild_ice"]:
		var plume:=FortParticles.emitter("DragonBreath",75,.7,FortParticles.quad(Vector2(1.2,1.6),kind=="wild_fire"))
		plume.position=origin+Vector3.UP*1.8;plume.direction=(goal-origin).normalized();plume.spread=28
		plume.initial_velocity_min=12;plume.initial_velocity_max=21;plume.gravity=Vector3(0,.2,0)
		plume.color_ramp=FortParticles.ramp([Color("#fff2be"),color,Color(color,0)])
		plume.scale_amount_curve=FortParticles.curve([.3,1.3,1.9])
		plume.one_shot=true;plume.explosiveness=.65;plume.visibility_aabb=AABB(Vector3.ONE*-20,Vector3.ONE*40)
		w.add_child(plume);plume.emitting=true;w.create_tween().tween_callback(plume.queue_free).set_delay(1.5)
		w.recv_fx(goal,color,"","hammer");return
	if kind=="wild_impact":
		FortArcFX.lightning(w,origin+Vector3.UP,goal+Vector3.UP,color)
		w.recv_fx(goal,color,"","hammer")
		return
	var root:=Node3D.new();root.position=Vector3.ZERO;w.add_child(root);root.add_to_group("wilderness_warning")
	var direction:=goal-origin;direction.y=0;direction=direction.normalized()
	var vertices:=PackedVector3Array()
	if kind=="wild_circle":
		for i in 40:
			for p in [goal,goal+Vector3(sin(i*TAU/40),0,cos(i*TAU/40))*4.5,goal+Vector3(sin((i+1)*TAU/40),0,cos((i+1)*TAU/40))*4.5]:vertices.append(p+Vector3.UP*.1)
	elif kind=="wild_cone":
		for i in 24:
			for p in [origin,origin+direction.rotated(Vector3.UP,-PI/5+i*PI/60)*16,origin+direction.rotated(Vector3.UP,-PI/5+(i+1)*PI/60)*16]:vertices.append(p+Vector3.UP*.12)
	else:
		var side:=direction.cross(Vector3.UP)*1.8;var end:=goal+direction*2
		for p in [origin-side,origin+side,end+side,origin-side,end+side,end-side]:vertices.append(p+Vector3.UP*.1)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var view:=MeshInstance3D.new();view.mesh=mesh;root.add_child(view)
	var material:=StandardMaterial3D.new();material.albedo_color=Color(color,.38);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;view.material_override=material
	var label:=Visuals.label_3d(message,color,2);label.position+=goal;label.visibility_range_end=60;root.add_child(label)
	w.create_tween().tween_callback(root.queue_free).set_delay(1.4)
