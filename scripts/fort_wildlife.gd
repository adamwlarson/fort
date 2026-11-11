class_name FortWildlife
extends RefCounted

# Fort 33: wildlife. Animals live in the same table as raiders so that weapons, hit
# effects, replication and saves all work on them, but they are marked `fauna`: raids,
# towers and the minimap ignore them and each follows its own temperament instead.
#
# Temperaments ("mind"):
#   skittish     bolts when a dwarf comes close, zig-zagging
#   herd         grazes in a group; when one is startled the whole herd runs
#   curious      trails dwarves at a distance and watches; runs if approached or hit
#   territorial  warns with a snort, then charges anyone who stays too close
#   stubborn     ignores dwarves until struck, then butts back for a while
#   placid       never runs; pulls into its shell when struck and shrugs off blows
#   aggressive   hunts any dwarf that comes near its ground
const CAMP := -9000
const SPECIES := {
	"Rabbit":{"title":"Rabbit","mind":"skittish","hp":18.0,"speed":2.0,"run":7.6,"alert":8.0,"radius":.2,"height":.45,"drops":{"meat":[1,1]},"call":"animal_rabbit","pitch":1.0,"big":false,"tier":1,"count":6,"group":[2,3]},
	"Deer":{"title":"Deer","mind":"herd","hp":55.0,"speed":2.2,"run":8.4,"alert":13.0,"radius":.35,"height":1.3,"drops":{"venison":[1,2]},"call":"animal_deer","pitch":1.0,"big":true,"tier":1,"count":4,"group":[3,4]},
	"Boar":{"title":"Wild Boar","mind":"territorial","hp":110.0,"speed":2.0,"run":6.4,"alert":6.5,"damage":14.0,"radius":.45,"height":.8,"drops":{"meat":[2,3]},"call":"animal_boar","pitch":1.0,"big":true,"tier":1,"count":2,"group":[1,1]},
	"Fox":{"title":"Fox","mind":"curious","hp":35.0,"speed":2.6,"run":7.8,"alert":4.0,"radius":.25,"height":.6,"drops":{"meat":[1,1]},"call":"animal_fox","pitch":1.0,"big":false,"tier":2,"count":3,"group":[1,1]},
	"Ram":{"title":"Hill Ram","mind":"stubborn","hp":90.0,"speed":1.9,"run":5.6,"alert":0.0,"damage":12.0,"radius":.4,"height":1.0,"drops":{"meat":[2,2]},"call":"animal_ram","pitch":1.0,"big":true,"tier":2,"count":4,"group":[2,3]},
	"Stag":{"title":"Stag","mind":"herd","hp":85.0,"speed":2.2,"run":8.6,"alert":15.0,"radius":.4,"height":1.5,"drops":{"venison":[2,3]},"call":"animal_stag","pitch":1.0,"big":true,"tier":2,"count":2,"group":[1,2]},
	"Yak":{"title":"Woolly Yak","mind":"stubborn","hp":260.0,"speed":1.5,"run":5.2,"alert":0.0,"damage":22.0,"radius":.7,"height":1.5,"drops":{"venison":[3,4]},"call":"animal_yak","pitch":1.0,"big":true,"tier":3,"count":4,"group":[2,3]},
	"Amberstag":{"title":"Amber Stag","mind":"herd","hp":130.0,"speed":2.3,"run":9.0,"alert":16.0,"radius":.45,"height":1.6,"drops":{"venison":[3,4],"resin":[1,1]},"call":"animal_stag","pitch":1.15,"big":true,"biome":"AMBERWOOD","count":5,"group":[2,3]},
	"Tortoise":{"title":"Sporeback Tortoise","mind":"placid","hp":320.0,"speed":1.0,"run":1.0,"alert":0.0,"radius":.8,"height":.9,"drops":{"glowcap":[2,3]},"call":"animal_tortoise","pitch":1.0,"big":true,"biome":"MYCELIUM HOLLOW","count":4,"group":[1,2]},
	"Salamander":{"title":"Cinder Salamander","mind":"aggressive","hp":130.0,"speed":2.4,"run":5.6,"alert":10.0,"damage":16.0,"radius":.5,"height":.4,"drops":{"embertail":[1,2]},"call":"animal_salamander","pitch":1.0,"big":true,"biome":"CINDER WASTES","count":5,"group":[2,3]},
	"Frosthare":{"title":"Frost Hare","mind":"skittish","hp":40.0,"speed":2.2,"run":8.8,"alert":10.0,"radius":.3,"height":.65,"drops":{"frostfat":[1,1]},"call":"animal_rabbit","pitch":.78,"big":false,"biome":"GLACIER REACH","count":6,"group":[2,4]},
	"Sunhorn":{"title":"Sunhorn","mind":"stubborn","hp":150.0,"speed":2.0,"run":6.0,"alert":0.0,"damage":16.0,"radius":.4,"height":1.0,"drops":{"sunmeat":[1,2]},"call":"animal_ram","pitch":1.25,"big":true,"biome":"ANCIENT GARDENS","count":5,"group":[2,3]},
}

var world:FortWorld
var rng:=RandomNumberGenerator.new()
var next_check:=1.5
var respawn:Dictionary={}
var next_herd:=1
## Automated fixtures place their own animals; the meadow stays empty unless they ask.
var enabled:=not "--fort-test" in OS.get_cmdline_user_args()

func _init(w:FortWorld)->void:
	world=w;rng.randomize()

static func is_fauna(kind:String)->bool:return SPECIES.has(kind)
static func title(e:Dictionary)->String:return str(SPECIES[e.kind].title) if SPECIES.has(e.kind) else str(e.kind)

## The ring of land a species lives in: [inner, outer], or an empty array while it is locked.
func band(kind:String)->Array:
	var spec:Dictionary=SPECIES[kind]
	if spec.has("biome"):
		for level in range(4,world.hearth_level+1):
			if str(world.expedition.biome(level).name)==str(spec.biome):return [247.0+(level-4)*80.0,319.0+(level-4)*80.0]
		return []
	var tier:int=spec.tier
	if tier>world.hearth_level:return []
	return [[34.0,minf(70.0,world.frontier_radius()-3.0)],[80.0,148.0],[158.0,238.0]][tier-1]

func alive(kind:String)->int:
	var total:=0
	for e in world.enemies.values():
		if e.kind==kind:total+=1
	return total

## A dry, open spot in a ring, away from camps and (unless the world is just starting) from dwarves.
func spot(range_m:Array,clear_of_dwarves:float)->Vector3:
	for attempt in 24:
		var angle:=rng.randf()*TAU
		var at:=Vector3(sin(angle),0,cos(angle))*sqrt(rng.randf_range(float(range_m[0])*float(range_m[0]),float(range_m[1])*float(range_m[1])))
		if FortGround._computed(at.x,at.z)<FortGround.WATER+.3:continue
		var open:=true
		for p in world.players.values():
			if FortGround.flat(p.position,at)<clear_of_dwarves:open=false;break
		if open:
			for keepout in world.scenery_keepouts:
				if FortGround.flat(at,keepout.pos)<float(keepout.radius)+3.0:open=false;break
		if open:return FortGround.on(at,.05)
	return Vector3.INF

## Host: put one group of a species into the world.
func spawn_group(kind:String,at:Vector3)->Array[int]:
	var spec:Dictionary=SPECIES[kind];var ids:Array[int]=[]
	var herd:=next_herd;next_herd+=1
	for i in rng.randi_range(int(spec.group[0]),int(spec.group[1])):
		var id:=world.next_enemy_id;world.next_enemy_id+=1
		var place:=FortGround.on(at+Vector3(rng.randf_range(-3,3),0,rng.randf_range(-3,3)),.05)
		world.broadcast("recv_enemy",[id,kind,place,float(spec.hp),CAMP])
		if world.enemies.has(id):
			world.enemies[id].merge({"herd":herd,"home":at,"mood":"graze","think_at":world.clock+rng.randf_range(0,3)},true)
			world.enemies[id].node.rotation.y=rng.randf()*TAU
			ids.append(id)
	return ids

## Host: keep each unlocked species near its numbers. New groups arrive by day, out of sight.
func tick()->void:
	if not enabled or world.clock<next_check:return
	var opening:=world.clock<6.0
	next_check=world.clock+2.0
	for kind in SPECIES:
		var range_m:=band(kind)
		if range_m.is_empty() or alive(kind)>=int(SPECIES[kind].count):continue
		if not opening and (world.is_night or world.clock<float(respawn.get(kind,0.0))):continue
		var at:=spot(range_m,14.0 if opening else 38.0)
		if not at.is_finite():continue
		spawn_group(kind,at)
		respawn[kind]=world.clock+(0.0 if opening else 28.0)

## What an animal leaves behind, as a pile to pick up, carry home and deposit.
func drop(e:Dictionary)->void:
	var spec:Dictionary=SPECIES[e.kind];var stock:Dictionary={}
	for kind in spec.drops:
		var amount:=rng.randi_range(int(spec.drops[kind][0]),int(spec.drops[kind][1]))
		if amount>0:stock[kind]=amount
	if not stock.is_empty():world.pieces.spawn_drop(FortGround.on(e.node.position),stock)

## Host: an animal was struck. `by` is the nearest dwarf, taken to be the one who did it.
func hurt(e:Dictionary)->void:
	var spec:Dictionary=SPECIES[e.kind]
	var by:=nearest_dwarf(e.node.position,40.0)
	e.threat=by.peer_id if by else -1
	match str(spec.mind):
		"skittish","herd","curious":alarm(e,5.0)
		"territorial","stubborn","aggressive":e.angry_until=world.clock+9.0;e.warned=true
		"placid":e.shell_until=world.clock+3.5

## One startled animal sets off the rest of its herd.
func alarm(e:Dictionary,seconds:float)->void:
	for other in world.enemies.values():
		if other.get("fauna",false) and int(other.get("herd",-1))==int(e.get("herd",-2)) and other.node.position.distance_to(e.node.position)<22.0:
			other.panic_until=maxf(float(other.get("panic_until",0.0)),world.clock+seconds+rng.randf_range(0,.6));other.threat=e.get("threat",-1)

func nearest_dwarf(at:Vector3,reach:float)->FortPlayer:
	var best:FortPlayer=null
	for p in world.players.values():
		var d:float=p.position.distance_to(at)
		if p.health>0 and d<reach:best=p;reach=d
	return best

## Host: one animal's turn. Returns true when this was an animal (so raid logic skips it).
func simulate(e:Dictionary,delta:float)->bool:
	if not e.get("fauna",false):return false
	var spec:Dictionary=SPECIES[e.kind];var body:CharacterBody3D=e.node;var mind:String=spec.mind
	var near:=nearest_dwarf(body.position,26.0)
	var distance:float=body.position.distance_to(near.position) if near else INF
	var direction:=Vector3.ZERO;var speed:float=spec.speed
	var home:Vector3=e.get("home",body.position)
	var panicking:bool=world.clock<float(e.get("panic_until",0.0))
	var angry:bool=world.clock<float(e.get("angry_until",0.0))
	if world.clock<float(e.get("shell_until",0.0)):
		e.moving=false;return true
	if mind in ["skittish","herd","curious"]:
		if near and distance<float(spec.alert) and not panicking:
			e.threat=near.peer_id;alarm(e,3.0);panicking=true
		if panicking:
			var from:Vector3=world.players[int(e.threat)].position if world.players.has(int(e.get("threat",-1))) else (near.position if near else home)
			direction=body.position-from;direction.y=0;direction=direction.normalized() if direction.length()>.1 else Vector3.FORWARD
			# Rabbits and hares jink from side to side as they run.
			if mind=="skittish":direction=direction.rotated(Vector3.UP,sin(world.clock*5.0+body.get_instance_id())*.7)
			speed=spec.run
		elif mind=="curious" and near and distance<17.0:
			# Trail the dwarf, then sit and watch from a safe way off.
			var toward:Vector3=near.position-body.position;toward.y=0
			if distance>8.0:direction=toward.normalized();speed=spec.speed*1.4
			else:e.face=atan2(toward.x,toward.z)
	elif mind=="territorial":
		if near and distance<float(spec.alert) and not angry:
			if not e.get("warned",false):
				# One snort of warning before the charge.
				e.warned=true;e.charge_at=world.clock+1.2
				world.broadcast("recv_fx",[body.position+Vector3.UP*.6,Color("#d9b08a"),"","animal_boar_charge"])
			if world.clock>=float(e.get("charge_at",INF)):e.angry_until=world.clock+7.0;e.threat=near.peer_id;angry=true
			var toward:Vector3=near.position-body.position;e.face=atan2(toward.x,toward.z)
		elif not near or distance>float(spec.alert)+5.0:
			if not angry:e.warned=false
	elif mind=="aggressive":
		if near and distance<float(spec.alert) and near.position.distance_to(home)<34.0:e.angry_until=world.clock+4.0;e.threat=near.peer_id;angry=true
	if angry and mind in ["territorial","stubborn","aggressive"]:
		var foe:FortPlayer=world.players.get(int(e.get("threat",-1)))
		if foe==null or foe.health<=0 or foe.position.distance_to(home)>46.0:e.angry_until=0.0
		else:
			var toward:Vector3=foe.position-body.position;toward.y=0
			if toward.length()<float(spec.radius)+1.1:
				e.face=atan2(toward.x,toward.z)
				if e.attack<=0:
					e.attack=1.6
					world._set_health(foe.peer_id,foe.health-float(spec.get("damage",10.0)))
					world.broadcast("recv_fx",[foe.position+Vector3.UP,Color("#e2a070"),"","hit"])
			else:direction=toward.normalized();speed=spec.run
	if direction==Vector3.ZERO and not e.has("face"):
		# Grazing: amble to a spot near home, stop a while, pick another.
		if world.clock>=float(e.get("think_at",0.0)):
			e.think_at=world.clock+rng.randf_range(3.0,8.0)
			e.goal=home+Vector3(rng.randf_range(-11,11),0,rng.randf_range(-11,11)) if rng.randf()<.7 else body.position
		var goal:Vector3=e.get("goal",body.position);var toward:Vector3=goal-body.position;toward.y=0
		if toward.length()>1.0:direction=toward.normalized()
	# The ward holds animals in as well as dwarves.
	if Vector2(body.position.x,body.position.z).length()>world.frontier_radius()-2.0:
		direction=-Vector3(body.position.x,0,body.position.z).normalized();e.panic_until=0.0
	if direction!=Vector3.ZERO:
		direction=world._steer_around_scenery(body,direction,body.get_instance_id(),e)
		body.velocity=direction*speed*(.45 if float(e.get("slow",0.0))>0 else 1.0)+Vector3(0,body.velocity.y-22*delta,0)
		FortGround.walk(body)
		body.rotation.y=lerp_angle(body.rotation.y,atan2(direction.x,direction.z),delta*(9.0 if speed>4.0 else 4.0))
		e.moving=true
	else:
		body.velocity=Vector3(0,body.velocity.y-22*delta,0);FortGround.walk(body);e.moving=false
		if e.has("face"):body.rotation.y=lerp_angle(body.rotation.y,float(e.face),delta*5.0)
	e.erase("face")
	return true
