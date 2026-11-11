class_name FortPieces
extends RefCounted
## Fort 29: free-form building. Pieces snap to a shared 4 m lattice that lines up with
## the castle rooms (20 m cells, 5 m storeys). The host is authoritative; clients mirror.
##
## Slots: a DECK is the floor of a cell, EX / EZ are the east / south edges of a cell,
## a CORNER is its south-east vertex and FILL is the space inside the cell (stairs, roofs).

const CELL:=4.0
const DECK:=0
const EX:=1
const EZ:=2
const CORNER:=3
const FILL:=4
const LIMIT:=1600
const MAX_LEVEL:=11
const REACH:=18.0
const DIRS:=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
const KINDS:={
	"Foundation":{"name":"Stone foundation","slot":"deck","ground":true,"cost":{"stone":4},"hp":1200.0,"mat":"stone","desc":"Level base on open ground. Everything else stands on these."},
	"WoodFloor":{"name":"Plank floor","slot":"deck","cost":{"wood":3},"hp":300.0,"mat":"wood","desc":"Upper floor or flat roof. Rests on walls or posts and reaches 2 tiles."},
	"StoneFloor":{"name":"Flagstone floor","slot":"deck","cost":{"wood":1,"stone":4},"hp":800.0,"mat":"stone","desc":"A heavier upper floor that raiders take far longer to break."},
	"WoodPost":{"name":"Timber post","slot":"corner","full":true,"cost":{"wood":2},"hp":300.0,"mat":"wood","desc":"Corner support for floors and roofs. Stack them to go higher."},
	"StoneColumn":{"name":"Stone column","slot":"corner","full":true,"cost":{"stone":4},"hp":900.0,"mat":"stone","desc":"A strong corner support for halls and towers."},
	"WoodStairs":{"name":"Timber stairs","slot":"fill","shape":"stairs","cost":{"wood":8},"hp":350.0,"mat":"wood","desc":"Climbs one storey across two tiles. Leave the floor above the top tile open."},
	"StoneStairs":{"name":"Stone stairs","slot":"fill","shape":"stairs","cost":{"wood":2,"stone":10},"hp":900.0,"mat":"stone","desc":"Solid steps up one storey across two tiles."},
	"Brazier":{"name":"Brazier","slot":"fill","shape":"prop","cost":{"wood":2,"stone":3},"hp":200.0,"mat":"stone","desc":"A standing fire that lights your halls at night."},
	"BannerPole":{"name":"Banner pole","slot":"corner","cost":{"wood":3},"hp":150.0,"mat":"wood","desc":"Fly the crew's colours from a corner."},
	"WoodWall":{"name":"Timber wall","slot":"edge","full":true,"cost":{"wood":4},"hp":350.0,"mat":"wood","desc":"Timber-framed wall. Cheap and quick; raiders break it sooner than stone."},
	"WoodWindow":{"name":"Timber window","slot":"edge","full":true,"cost":{"wood":4},"hp":300.0,"mat":"wood","desc":"A timber wall with a shuttered window."},
	"WoodDoorway":{"name":"Timber doorway","slot":"edge","full":true,"shape":"doorway","cost":{"wood":4},"hp":320.0,"mat":"wood","desc":"An open doorway. Raiders can walk through it too."},
	"WoodDoor":{"name":"Timber door","slot":"edge","full":true,"shape":"doorway","door":true,"cost":{"wood":7},"hp":320.0,"mat":"wood","desc":"Opens for dwarves and stays shut to raiders."},
	"WoodRailing":{"name":"Timber railing","slot":"edge","shape":"low","cost":{"wood":2},"hp":150.0,"mat":"wood","desc":"A waist-high rail for walkways and balconies."},
	"WoodGable":{"name":"Timber gable","slot":"edge","shape":"gable","cost":{"wood":3},"hp":250.0,"mat":"wood","desc":"Closes the end of a roof. It shapes itself to the roof beside it."},
	"StoneWall":{"name":"Stone wall","slot":"edge","full":true,"cost":{"wood":1,"stone":6},"hp":900.0,"mat":"stone","desc":"Coursed stone. The backbone of a real fortress."},
	"StoneSlit":{"name":"Arrow-slit wall","slot":"edge","full":true,"cost":{"wood":1,"stone":6},"hp":850.0,"mat":"stone","desc":"A stone wall with a narrow firing slit."},
	"StoneArch":{"name":"Stone archway","slot":"edge","full":true,"shape":"doorway","cost":{"wood":1,"stone":7},"hp":900.0,"mat":"stone","desc":"An open arch. Raiders can walk through it too."},
	"StoneGate":{"name":"Iron-bound gate","slot":"edge","full":true,"shape":"doorway","door":true,"tier":2,"cost":{"wood":6,"stone":7,"iron":4},"hp":1000.0,"mat":"stone","desc":"A stone arch with a heavy door that opens only for dwarves."},
	"Battlement":{"name":"Battlement","slot":"edge","shape":"low","cost":{"stone":4},"hp":500.0,"mat":"stone","desc":"Crenellated parapet for wall tops and tower roofs."},
	"StoneGable":{"name":"Stone gable","slot":"edge","shape":"gable","cost":{"stone":4},"hp":600.0,"mat":"stone","desc":"Closes the end of a roof. It shapes itself to the roof beside it."},
	"ThatchSlope":{"name":"Thatch slope","slot":"fill","shape":"slope","roof":true,"cost":{"wood":3},"hp":200.0,"mat":"wood","desc":"Half of a pitched roof. Put two back to back for a two-tile hall."},
	"ThatchRidge":{"name":"Thatch ridge","slot":"fill","shape":"ridge","roof":true,"cost":{"wood":3},"hp":200.0,"mat":"wood","desc":"A whole pitched roof for a one-tile-wide building."},
	"ThatchPeak":{"name":"Thatch peak","slot":"fill","shape":"peak","roof":true,"cost":{"wood":4},"hp":200.0,"mat":"wood","desc":"The raised middle of a three-tile hall, between two slopes."},
	"ThatchCap":{"name":"Thatch cap","slot":"fill","shape":"cap","roof":true,"cost":{"wood":4},"hp":200.0,"mat":"wood","desc":"A four-sided roof for a single tile, such as a hut or lookout."},
	"SlateSlope":{"name":"Slate slope","slot":"fill","shape":"slope","roof":true,"cost":{"wood":2,"stone":3},"hp":450.0,"mat":"stone","desc":"Half of a pitched slate roof."},
	"SlateRidge":{"name":"Slate ridge","slot":"fill","shape":"ridge","roof":true,"cost":{"wood":2,"stone":3},"hp":450.0,"mat":"stone","desc":"A whole pitched slate roof for a one-tile-wide building."},
	"SlatePeak":{"name":"Slate peak","slot":"fill","shape":"peak","roof":true,"cost":{"wood":2,"stone":4},"hp":450.0,"mat":"stone","desc":"The raised middle of a three-tile slate roof."},
	"SlateSpire":{"name":"Slate spire","slot":"fill","shape":"spire","roof":true,"cost":{"wood":3,"stone":5},"hp":450.0,"mat":"stone","desc":"A tall pointed tower roof with a gold finial."},
}
const TABS:=[
	{"name":"FRAME","items":["Foundation","WoodFloor","StoneFloor","WoodPost","StoneColumn","WoodStairs","StoneStairs","Brazier","BannerPole"]},
	{"name":"TIMBER","items":["WoodWall","WoodWindow","WoodDoorway","WoodDoor","WoodRailing","WoodGable"]},
	{"name":"STONE","items":["StoneWall","StoneSlit","StoneArch","StoneGate","Battlement","StoneGable"]},
	{"name":"ROOFS","items":["ThatchSlope","ThatchRidge","ThatchPeak","ThatchCap","SlateSlope","SlateRidge","SlatePeak","SlateSpire"]},
]
const GABLE_HEIGHT:={"tri":1.5,"half":3.0,"pent":4.5,"rect":3.0}

var world:FortWorld
var root:Node3D
var drop_root:Node3D
var pieces:Dictionary={}     # key -> {kind, turn, hp, max_hp, node}
## Bumped whenever a foundation appears or goes, so the terrain re-levels beneath them.
var ground_revision:=0
var occupied:Dictionary={}   # slot key -> owning piece key
var spans:Dictionary={}      # key -> tiles from direct support
var spans_dirty:=false
var doors:Array[int]=[]
var drops:Dictionary={}      # id -> {pos, stock, node}
var next_drop:=1
var drop_clock:=0.0
# Local build tool
var tab:=0
var index:=0
var turn:=0
var lift:=0
var ghost:Node3D
var ghost_stamp:=""
var target:=-1
var target_turn:=0
var target_reason:=""
var aimed:=-1
var marked:=-1
static var shapes:Dictionary={}
static var ghost_ok:StandardMaterial3D
static var ghost_bad:StandardMaterial3D
static var mark_material:StandardMaterial3D

func _init(w:FortWorld)->void:
	world=w
	root=Node3D.new();root.name="Pieces";world.add_child(root)
	drop_root=Node3D.new();drop_root.name="Drops";world.add_child(drop_root)

# ------------------------------------------------------------------ lattice
static func key(slot:int,ix:int,iz:int,level:int)->int:return (slot<<26)|(level<<22)|((ix+1024)<<11)|(iz+1024)
static func unpack(k:int)->Array:return [k>>26,((k>>11)&2047)-1024,(k&2047)-1024,(k>>22)&15]
static func level_y(level:int)->float:return FortCastle.BASE+level*FortCastle.HEIGHT
static func place(k:int)->Vector3:
	var u:=unpack(k);var slot:int=u[0]
	return Vector3(u[1]*CELL+(2.0 if slot in [EX,CORNER] else 0.0),level_y(u[3]),u[2]*CELL+(2.0 if slot in [EZ,CORNER] else 0.0))
static func yaw(k:int,t:int)->float:
	var slot:=k>>26
	if slot==EX:return PI*.5+PI*(t&1)
	if slot==EZ:return PI*(t&1)
	if slot==FILL:return (t&3)*PI*.5
	return 0.0
## Grid direction a tile piece faces (stairs climb this way, slopes rise this way).
static func facing(t:int)->Vector2i:return [Vector2i(0,-1),Vector2i(-1,0),Vector2i(0,1),Vector2i(1,0)][t&3]
static func valid_key(kind:String,k:int)->bool:
	if not KINDS.has(kind) or k<0:return false
	var u:=unpack(k);var slot:int=u[0]
	if slot>FILL or int(u[3])>MAX_LEVEL or absi(int(u[1]))>1000 or absi(int(u[2]))>1000:return false
	match str(KINDS[kind].slot):
		"deck":return slot==DECK
		"edge":return slot in [EX,EZ]
		"corner":return slot==CORNER
	return slot==FILL
static func slots(kind:String,k:int,t:int)->Array[int]:
	var result:Array[int]=[k]
	if KINDS[kind].get("shape","")=="stairs":
		var u:=unpack(k);var f:=facing(t)
		result.append(key(FILL,u[1]+f.x,u[2]+f.y,u[3]))
		result.append(key(DECK,u[1]+f.x,u[2]+f.y,u[3]+1))
	return result
static func edge_cells(k:int)->Array[Vector2i]:
	var u:=unpack(k)
	return [Vector2i(u[1],u[2]),Vector2i(u[1]+1,u[2]) if int(u[0])==EX else Vector2i(u[1],u[2]+1)]

func castle_room(ix:int,iz:int,level:int)->Dictionary:
	var k:=FortCastle.key(floori((ix*CELL+10.0)/FortCastle.CELL),floori((iz*CELL+10.0)/FortCastle.CELL),level)
	return world.castle.rooms.get(k,{}) if world.castle else {}
func castle_deck(ix:int,iz:int,level:int)->bool:
	return castle_room(ix,iz,level).get("complete",false)
func has_deck(ix:int,iz:int,level:int,live:Dictionary)->bool:
	return live.has(key(DECK,ix,iz,level)) or castle_deck(ix,iz,level)
func is_full(k:int,live:Dictionary)->bool:
	return live.has(k) and pieces.has(k) and KINDS[pieces[k].kind].get("full",false)
## A deck or roof here would rest directly on something.
func anchored(ix:int,iz:int,level:int,live:Dictionary)->bool:
	if level<=0:return false
	for k in [key(EX,ix,iz,level-1),key(EX,ix-1,iz,level-1),key(EZ,ix,iz,level-1),key(EZ,ix,iz-1,level-1),key(CORNER,ix,iz,level-1),key(CORNER,ix-1,iz,level-1),key(CORNER,ix,iz-1,level-1),key(CORNER,ix-1,iz-1,level-1)]:
		if is_full(k,live):return true
	for d in DIRS:
		if castle_deck(ix+d.x,iz+d.y,level):return true
	return false

## Tiles from direct support (0 = resting on something), or -1 when nothing holds it up.
func support(kind:String,k:int,t:int,live:Dictionary)->int:
	var spec:Dictionary=KINDS[kind];var u:=unpack(k);var ix:int=u[1];var iz:int=u[2];var level:int=u[3]
	match str(spec.slot):
		"deck":
			if level==0:return 0
			if anchored(ix,iz,level,live):return 0
			var best:=99
			for d in DIRS:
				var n:=key(DECK,ix+d.x,iz+d.y,level)
				if live.has(n):best=mini(best,int(live[n])+1)
			return best if best<=2 else -1
		"edge":
			for c in edge_cells(k):
				if has_deck(c.x,c.y,level,live):return 0
			return 0 if level>0 and is_full(key(int(u[0]),ix,iz,level-1),live) else -1
		"corner":
			for c in [Vector2i(ix,iz),Vector2i(ix+1,iz),Vector2i(ix,iz+1),Vector2i(ix+1,iz+1)]:
				if has_deck(c.x,c.y,level,live):return 0
			return 0 if level>0 and is_full(key(CORNER,ix,iz,level-1),live) else -1
	if spec.get("shape","")=="stairs":
		var f:=facing(t)
		return 0 if has_deck(ix,iz,level,live) and has_deck(ix+f.x,iz+f.y,level,live) else -1
	if spec.get("roof",false):
		if has_deck(ix,iz,level,live) or anchored(ix,iz,level,live):return 0
		var reach:=99
		for d in DIRS:
			var n:=key(FILL,ix+d.x,iz+d.y,level)
			if live.has(n) and pieces.has(n) and KINDS[pieces[n].kind].get("roof",false):reach=mini(reach,int(live[n])+1)
		return reach if reach<=3 else -1
	return 0 if has_deck(ix,iz,level,live) else -1

func live_spans()->Dictionary:
	if not spans_dirty:return spans
	spans_dirty=false;spans={}
	var changed:=true
	while changed:
		changed=false
		for k in pieces:
			var s:=support(pieces[k].kind,k,pieces[k].turn,spans)
			if s>=0 and s<int(spans.get(k,99)):spans[k]=s;changed=true
	return spans

func unsupported()->Array[int]:
	spans_dirty=true
	var live:=live_spans();var result:Array[int]=[]
	for k in pieces:
		if not live.has(k):result.append(k)
	return result

# ------------------------------------------------------------------ rules
static func cost(kind:String)->Dictionary:return KINDS[kind].cost
func can_afford(kind:String)->bool:
	for resource in cost(kind):
		if int(world.shared.get(resource,0))<int(cost(kind)[resource]):return false
	return true

func reason(kind:String,k:int,t:int)->String:
	if not valid_key(kind,k):return "Invalid location"
	var spec:Dictionary=KINDS[kind];var u:=unpack(k);var slot:int=u[0];var ix:int=u[1];var iz:int=u[2];var level:int=u[3]
	if world.hearth_level<int(spec.get("tier",1)):return "%s needs Hearth tier %d. Upgrade the hearth with U."%[spec.name,spec.tier]
	if pieces.size()>=LIMIT:return "The fort has reached its limit of %d pieces"%LIMIT
	var pos:=place(k)
	if Vector2(pos.x,pos.z).length()>world.build_radius():return "Build within %dm of the hearth (upgrade the hearth to expand)"%world.build_radius()
	for s in slots(kind,k,t):
		if occupied.has(s):
			var owner:Dictionary=pieces.get(occupied[s],{})
			if int(occupied[s])==s:return "%s is already here. Aim at it and press X to remove it."%KINDS[owner.kind].name
			return "%s is in the way of this piece"%KINDS[owner.kind].name
	for room in world.castle.rooms.values():
		if pos.distance_to(room.sign)<1.6:return "Keep the castle signpost clear"
	var blueprint:Dictionary=castle_room(roundi(pos.x/CELL),roundi(pos.z/CELL),level)
	if not blueprint.is_empty() and not blueprint.complete and slot in [DECK,FILL]:return "Finish or cancel the castle blueprint here first"
	if level==0 and slot!=DECK:
		if Vector2(pos.x,pos.z).length()<3.3 or pos.distance_to(Vector3(4.6,FortCastle.BASE,0))<2.4 or pos.distance_to(Vector3(-4.6,FortCastle.BASE,0))<2.4 or pos.distance_to(FortHearthGrowth.workshop(world))<2.4:return "Keep the hearth, stockpile and workshop clear"
	match str(spec.slot):
		"deck":
			if castle_deck(ix,iz,level):return "The castle floor is already here. Build straight onto it."
			if spec.get("ground",false):
				if level!=0:return "Foundations sit on the ground. Use a floor up here."
				if absf(FortGround.height(pos.x,pos.z))>1.2:return "The ground is too steep here. Start on gentler ground and build across."
				if world.hearth_level>=2 and world.expedition.terrain_enabled and FortTerrain.reserved(pos,world.expedition.seed_value,3):return "Too close to the cliffs and caverns"
				for obstacle in world.scenery_keepouts:
					if Vector2(pos.x-obstacle.pos.x,pos.z-obstacle.pos.z).length()<2.2+float(obstacle.radius):return "Keep scenery and camp supplies clear"
				for resource in world.resource_nodes.values():
					if resource.amount>0 and Vector2(pos.x-resource.node.position.x,pos.z-resource.node.position.z).length()<2.7:return "Clear the resource before building here"
				for d in world.defenses.values():
					var at:Vector3=d.node.position
					if at.y<1.0 and absf(at.x-pos.x)<2.9 and absf(at.z-pos.z)<2.9:return "A defense is standing here. Salvage it first (G)."
				for p in world.players.values():
					if p.position.y<FortCastle.BASE-.1 and absf(p.position.x-pos.x)<2.5 and absf(p.position.z-pos.z)<2.5:return "A dwarf is standing here"
				for e in world.enemies.values():
					if e.node.position.y<FortCastle.BASE and absf(e.node.position.x-pos.x)<2.6 and absf(e.node.position.z-pos.z)<2.6:return "A raider is standing here"
			else:
				if level==0:return "Floors rest on walls or posts. Use a foundation on the ground."
				for p in world.players.values():
					if p.position.y>pos.y-2.3 and p.position.y<pos.y-.05 and absf(p.position.x-pos.x)<2.3 and absf(p.position.z-pos.z)<2.3:return "A dwarf is in the way"
		"edge":
			var axis:=Vector3.RIGHT.rotated(Vector3.UP,yaw(k,0))
			for d in world.defenses.values():
				var offset:Vector3=d.node.position-pos
				if absf(offset.y)<4.0 and absf(offset.dot(axis))<(3.6 if FortPlacement.is_wall(d.kind) else 2.6) and absf(offset.dot(Vector3(-axis.z,0,axis.x)))<1.2:return "A defense is in the way"
			for p in world.players.values():
				var offset:Vector3=p.position-pos
				if offset.y>-1.6 and offset.y<4.9 and absf(offset.dot(axis))<2.2 and absf(offset.dot(Vector3(-axis.z,0,axis.x)))<.75:return "A dwarf is standing here"
		"corner":
			for d in world.defenses.values():
				if absf(d.node.position.y-pos.y)<4.0 and Vector2(d.node.position.x-pos.x,d.node.position.z-pos.z).length()<1.1:return "A defense is in the way"
			for p in world.players.values():
				if absf(p.position.y-pos.y-1.5)<3.2 and Vector2(p.position.x-pos.x,p.position.z-pos.z).length()<.8:return "A dwarf is standing here"
		"fill":
			if spec.get("roof",false):
				if level==0:return "Roofs go on top of walls or posts"
			else:
				var centres:Array[Vector3]=[pos]
				if spec.get("shape","")=="stairs":centres.append(pos+Vector3(facing(t).x,0,facing(t).y)*CELL)
				for c in centres:
					if level==0 and (Vector2(c.x,c.z).length()<4.4 or Vector2(c.x-4.6,c.z).length()<3.6 or Vector2(c.x+4.6,c.z).length()<3.6):return "Keep the hearth, stockpile and workshop clear"
					for d in world.defenses.values():
						if absf(d.node.position.y-c.y)<3.0 and absf(d.node.position.x-c.x)<2.4 and absf(d.node.position.z-c.z)<2.4:return "A defense is in the way"
	if support(kind,k,t,live_spans())<0:
		match str(spec.slot):
			"deck":return "Needs a wall or post underneath, or a supported floor beside it (floors reach 2 tiles)"
			"edge":return "Walls stand on a foundation or floor, or on top of another wall"
			"corner":return "Posts stand on a foundation or floor, or on another post"
		if spec.get("shape","")=="stairs":return "Stairs need a floor under both tiles"
		if spec.get("roof",false):return "Roofs rest on wall tops, posts or a floor (they reach 3 tiles)"
		return "Needs a floor underneath"
	return ""

# ------------------------------------------------------------------ host actions
func request_place(id:int,data:Dictionary)->void:
	var kind:String=str(data.get("kind",""));var k:int=int(data.get("key",-1));var t:int=int(data.get("turn",0))&3
	if not valid_key(kind,k) or not world._allow(id,"piece",.12):return
	var p:FortPlayer=world.players[id]
	if p.mounted_ballista>=0 or p.position.distance_to(place(k))>REACH:return
	var why:=reason(kind,k,t)
	if why!="":world.personal(id,why);return
	if not can_afford(kind):world.personal(id,"Not enough in the shared stockpile. Deposit more at the stockpile (hold E).");return
	for resource in cost(kind):world.shared[resource]=int(world.shared.get(resource,0))-int(cost(kind)[resource])
	world.broadcast("recv_piece",[k,kind,t,float(KINDS[kind].hp)])
	world.broadcast("recv_fx",[place(k)+Vector3.UP*.8,Color("#dcc296"),"","construction"])
	FortStats.award(world,id,1)

func request_remove(id:int,k:int)->void:
	if not pieces.has(k) or not world._allow(id,"piece_remove",.25):return
	var p:FortPlayer=world.players[id]
	if p.mounted_ballista>=0 or p.position.distance_to(place(k))>REACH:return
	var d:Dictionary=pieces[k]
	world.personal(id,"%s removed. Pick up %s from the ground."%[KINDS[d.kind].name,GameData.supplies_text(refund(k),true)])
	destroy(k,1.0,"")
	collapse()

func refund(k:int,share:=1.0)->Dictionary:
	var d:Dictionary=pieces[k];var result:Dictionary={}
	var fraction:float=clampf(float(d.hp)/maxf(1.0,float(d.max_hp)),0,1)*share
	for resource in cost(d.kind):
		var amount:=floori(int(cost(d.kind)[resource])*fraction+.001)
		if amount>0:result[resource]=amount
	return result

## Remove a piece on every machine and leave its share of materials on the ground.
func destroy(k:int,share:float,notice:String)->void:
	if not pieces.has(k):return
	var stock:=refund(k,share);var pos:=place(k);var exclude:Array[RID]=[]
	for body in pieces[k].node.find_children("*","StaticBody3D",true,false):exclude.append(body.get_rid())
	world.broadcast("recv_piece_gone",[k,notice])
	if stock.is_empty():return
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3.UP*.7,pos+Vector3.DOWN*60,1,exclude))
	spawn_drop(hit.position if not hit.is_empty() else FortGround.on(pos),stock)

## Anything left without support falls down and drops all of its materials.
func collapse()->void:
	for guard in 8:
		var loose:=unsupported()
		if loose.is_empty():return
		for k in loose:destroy(k,1.0,"COLLAPSED")

func damage(k:int,amount:float)->void:
	if not pieces.has(k):return
	var d:Dictionary=pieces[k]
	world.director.record("building_damage",minf(d.hp,amount))
	d.hp=float(d.hp)-amount
	if d.hp<=0:
		destroy(k,.5,"DESTROYED");collapse()
	else:world.broadcast("recv_piece_hp",[k,float(d.hp)])

func blast(pos:Vector3,radius:float,amount:float)->void:
	for k in pieces.keys():
		if pieces.has(k) and place(k).distance_to(pos)<radius+1.6:damage(k,amount*2.0)

func repair(p:FortPlayer)->bool:
	var best:=-1;var distance:=4.2
	for k in pieces:
		var d:Dictionary=pieces[k]
		if d.hp>=d.max_hp:continue
		var gap:=p.position.distance_to(place(k)+Vector3.UP*1.2)
		if gap<distance:best=k;distance=gap
	if best<0:return false
	var d:Dictionary=pieces[best];var resource:String="stone" if KINDS[d.kind].mat=="stone" else "wood"
	if int(world.shared.get(resource,0))<=0:world.personal(p.peer_id,FortGlyphs.t("Repairing this needs 1{%s} from the shared stockpile."%resource));return true
	world.shared[resource]-=1
	var amount:=180.0 if p.role_id==2 else 90.0
	d.hp=minf(d.max_hp,float(d.hp)+amount)
	world.broadcast("recv_piece_hp",[best,float(d.hp)])
	world.broadcast("recv_action",[p.peer_id,"repair"])
	world.broadcast("recv_fx",[place(best)+Vector3.UP,Color("#9fe4c7"),"+%d repair"%amount,"build"])
	return true

## Castle rooms and castle walls take priority: pieces in their way go back to the stockpile.
func clear_box(centre:Vector3,half:Vector3,basis:=Basis.IDENTITY)->void:
	var removed:=false
	for k in pieces.keys():
		var offset:Vector3=basis.inverse()*(place(k)-centre)
		if absf(offset.x)<half.x and absf(offset.y)<half.y and absf(offset.z)<half.z:
			var stock:=refund(k)
			for resource in stock:world.shared[resource]=int(world.shared.get(resource,0))+int(stock[resource])
			world.broadcast("recv_piece_gone",[k,""]);removed=true
	if removed:collapse()

## A small timber shell on the keep so a new crew starts with something to grow.
func starter()->void:
	for item in [["WoodWall",EX,2,2,0],["WoodWall",EX,2,-2,0],["WoodWall",EX,-3,2,1],["WoodWall",EX,-3,-2,1],["WoodWall",EZ,2,2,0],["WoodWall",EZ,-2,2,0],["WoodWindow",EZ,2,-3,1],["WoodWindow",EZ,-2,-3,1]]:
		recv_piece(key(item[1],item[2],item[3],0),item[0],item[4],float(KINDS[item[0]].hp))
	for cell in [Vector2i(2,-2),Vector2i(-2,-2)]:
		recv_piece(key(FILL,cell.x,cell.y,1),"ThatchCap",0,float(KINDS.ThatchCap.hp))
	for corner in [Vector2i(2,2),Vector2i(-3,2)]:
		recv_piece(key(CORNER,corner.x,corner.y,0),"BannerPole",0,float(KINDS.BannerPole.hp))

# ------------------------------------------------------------------ mirrored state
func recv_piece(k:int,kind:String,t:int,hp:float)->void:
	if pieces.has(k) or not valid_key(kind,k):return
	var node:=make(kind,k,t,true)
	node.name="Piece_%d"%k;node.set_meta("piece",k);node.position=place(k)
	root.add_child(node)
	var d:Dictionary={"kind":kind,"turn":t,"hp":hp,"max_hp":float(KINDS[kind].hp),"node":node}
	pieces[k]=d
	for s in slots(kind,k,t):occupied[s]=k
	if KINDS[kind].get("door",false):doors.append(k)
	if KINDS[kind].get("ground",false):ground_revision+=1
	spans_dirty=true;world.navigation_revision+=1
	if KINDS[kind].get("roof",false):reskin_around(k)

func recv_piece_gone(k:int,notice:String)->void:
	if not pieces.has(k):return
	var d:Dictionary=pieces[k]
	if notice!="":world.recv_fx(place(k)+Vector3.UP,FortArt.WOOD,notice,"hit")
	for s in slots(d.kind,k,d.turn):
		if int(occupied.get(s,-1))==k:occupied.erase(s)
	doors.erase(k)
	if marked==k:marked=-1
	d.node.queue_free();pieces.erase(k)
	if KINDS[d.kind].get("ground",false):ground_revision+=1
	spans_dirty=true;world.navigation_revision+=1
	if KINDS[d.kind].get("roof",false):reskin_around(k)

## Map positions of every foundation: the terrain is cut level under each one.
func ground_cells()->Array[Vector2]:
	var cells:Array[Vector2]=[]
	for k in pieces:
		if KINDS[pieces[k].kind].get("ground",false):
			var at:=place(k);cells.append(Vector2(at.x,at.z))
	return cells

func recv_piece_hp(k:int,hp:float)->void:
	if pieces.has(k):pieces[k].hp=hp

func state()->Dictionary:
	var names:PackedStringArray=[];var lookup:Dictionary={};var data:=PackedInt32Array()
	for k in pieces:
		var d:Dictionary=pieces[k]
		if not lookup.has(d.kind):lookup[d.kind]=names.size();names.append(d.kind)
		data.append(k);data.append(int(lookup[d.kind])|(int(d.turn)<<8));data.append(ceili(d.hp))
	var piles:Array=[]
	for id in drops:piles.append([id,drops[id].pos,drops[id].stock.duplicate()])
	return {"kinds":names,"data":data,"drops":piles,"next_drop":next_drop}

func receive(s:Dictionary)->void:
	if s.is_empty():return
	var names:PackedStringArray=s.get("kinds",PackedStringArray());var data:PackedInt32Array=s.get("data",PackedInt32Array())
	var seen:Dictionary={}
	for i in range(0,data.size()-2,3):
		var k:int=data[i];var which:int=data[i+1]&255
		if which>=names.size() or not valid_key(names[which],k):continue
		seen[k]=true
		if pieces.has(k) and pieces[k].kind!=names[which]:recv_piece_gone(k,"")
		if not pieces.has(k):recv_piece(k,names[which],data[i+1]>>8,float(data[i+2]))
		else:pieces[k].hp=float(data[i+2])
	for k in pieces.keys():
		if not seen.has(k):recv_piece_gone(k,"")
	var piles:Dictionary={}
	for pile in s.get("drops",[]):
		if pile is Array and pile.size()==3 and pile[1] is Vector3 and pile[2] is Dictionary:piles[int(pile[0])]=true;recv_drop(int(pile[0]),pile[1],pile[2])
	for id in drops.keys():
		if not piles.has(id):recv_drop(id,Vector3.ZERO,{})
	next_drop=maxi(next_drop,int(s.get("next_drop",1)))

static func validate(s:Variant)->String:
	if s==null:return ""
	if not s is Dictionary:return "Invalid building pieces"
	if not s.get("kinds",PackedStringArray()) is PackedStringArray or not s.get("data",PackedInt32Array()) is PackedInt32Array or not s.get("drops",[]) is Array:return "Invalid building pieces"
	if s.get("data",PackedInt32Array()).size()>LIMIT*3+3 or s.get("drops",[]).size()>600:return "Save exceeds supported building limits"
	return ""

# ------------------------------------------------------------------ dropped materials
func spawn_drop(pos:Vector3,stock:Dictionary)->void:
	for id in drops:
		var pile:Dictionary=drops[id]
		if pile.pos.distance_to(pos)<2.6:
			var merged:Dictionary=pile.stock.duplicate()
			for resource in stock:merged[resource]=int(merged.get(resource,0))+int(stock[resource])
			world.broadcast("recv_drop",[id,pile.pos,merged]);return
	next_drop+=1
	world.broadcast("recv_drop",[next_drop-1,pos,stock.duplicate()])

func recv_drop(id:int,pos:Vector3,stock:Dictionary)->void:
	if stock.is_empty():
		if drops.has(id):drops[id].node.queue_free();drops.erase(id)
		return
	if not drops.has(id):
		var node:=Node3D.new();node.position=pos;drop_root.add_child(node)
		var label:=Visuals.label_3d("",Color("#f1dfae"),1.25);label.name="Label";label.font_size=30;label.pixel_size=.006;node.add_child(label)
		drops[id]={"pos":pos,"stock":{},"node":node}
	var pile:Dictionary=drops[id];pile.stock=stock.duplicate()
	var node:Node3D=pile.node
	for child in node.get_children():
		if child.name!="Label":node.remove_child(child);child.queue_free()
	var slot:=0
	for resource in GameData.RESOURCES:
		var amount:=int(stock.get(resource,0))
		for i in mini(4,ceili(amount/3.0)):
			var angle:=slot*2.4;var radius:=.18+.14*slot;slot+=1
			var size:=Vector3(.62,.2,.22) if resource=="wood" else Vector3(.36,.28,.34)
			var bit:=Visuals.box(size,GameData.resource_color(resource).darkened(.12*(i%2)),Vector3(cos(angle)*radius,.12+.05*(slot%3),sin(angle)*radius))
			bit.rotation=Vector3(0,angle*1.7,.15*(i%2));node.add_child(bit)
	(node.get_node("Label") as Label3D).text=FortGlyphs.cost(stock)

func tick_drops()->void:
	for id in drops.keys():
		var pile:Dictionary=drops[id]
		for p in world.players.values():
			if p.health<=0 or p.position.distance_to(pile.pos)>2.3:continue
			var space:int=p.carry_limit-p.total_carried()
			if space<=0:
				if world._allow(p.peer_id,"pack_full",5.0):world.personal(p.peer_id,"Your pack is full. Deposit at the stockpile, then come back for the rest.")
				continue
			var left:Dictionary=pile.stock.duplicate();var took:=0
			for resource in pile.stock:
				var amount:=mini(space-took,int(pile.stock[resource]))
				if amount<=0:continue
				p.carrying[resource]=int(p.carrying.get(resource,0))+amount;took+=amount
				left[resource]=int(left[resource])-amount
				if int(left[resource])<=0:left.erase(resource)
				world.broadcast("recv_gain",[p.peer_id,pile.pos+Vector3.UP,resource,amount,"PACK"])
			if took>0:
				world.broadcast("recv_drop",[id,pile.pos,left])
				if left.is_empty():break
				pile=drops[id]

# ------------------------------------------------------------------ raiders
## Ground raiders that are walled out pick the piece in front of them and break it.
func siege(e:Dictionary,delta:float)->bool:
	if pieces.is_empty():return false
	var body:CharacterBody3D=e.node;var pos:=body.position
	var k:=int(e.get("piece_breach",-1))
	if k>=0 and (not pieces.has(k) or world.clock>float(e.get("piece_until",0))):
		e.piece_breach=-1;k=-1;e.stall_at=world.clock+1.0;e.stall_pos=pos
	if k<0:
		if world.clock<float(e.get("stall_at",0)):return false
		var moved:float=pos.distance_to(e.get("stall_pos",pos+Vector3.ONE*9))
		e.stall_pos=pos;e.stall_at=world.clock+1.4
		if moved>.6:return false
		var forward:=Vector3(sin(body.rotation.y),0,cos(body.rotation.y))
		var space:=world.get_world_3d().direct_space_state
		for angle in [0.0,.5,-.5]:
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3.UP*.7,pos+Vector3.UP*.7+forward.rotated(Vector3.UP,angle)*2.6,1,[body.get_rid()]))
			if hit.is_empty():continue
			var found:=piece_of(hit.collider)
			if found>=0:e.piece_breach=found;e.piece_until=world.clock+14.0;e.piece_point=hit.position;k=found;break
		if k<0:return false
	var point:Vector3=e.get("piece_point",place(k))
	var gap:=Vector3(point.x-pos.x,0,point.z-pos.z)
	if gap.length()>1.7:
		var direction:=gap.normalized()
		body.velocity.x=direction.x*e.speed;body.velocity.z=direction.z*e.speed;body.velocity.y-=22*delta
		FortGround.walk(body);body.rotation.y=lerp_angle(body.rotation.y,atan2(direction.x,direction.z),delta*8);e.moving=true
		return true
	e.moving=false;body.velocity=Vector3.ZERO
	if gap.length()>.05:body.rotation.y=lerp_angle(body.rotation.y,atan2(gap.x,gap.z),delta*8)
	if e.kind=="Sapper":world.raiders.arm(e);return true
	if e.attack<=0:
		e.attack=1.5
		world.broadcast("recv_fx",[point+Vector3.UP*.3,Color("#be9b75"),"","hammer"])
		damage(k,38.0 if e.kind=="Brute" else 13.0)
	return true

## A built floor or roof overhead shelters a dwarf from flying raiders.
func covered(pos:Vector3)->bool:
	var ix:=roundi(pos.x/CELL);var iz:=roundi(pos.z/CELL)
	for level in range(1,MAX_LEVEL+1):
		if level_y(level)<pos.y+1:continue
		if occupied.has(key(DECK,ix,iz,level)) and pieces.has(key(DECK,ix,iz,level)):return true
		if pieces.has(key(FILL,ix,iz,level)) and KINDS[pieces[key(FILL,ix,iz,level)].kind].get("roof",false):return true
	return false

static func piece_of(node:Node)->int:
	while node:
		if node.has_meta("piece"):return int(node.get_meta("piece"))
		node=node.get_parent()
	return -1

# ------------------------------------------------------------------ models
## The gable beside a roof takes that roof's outline. Returns [variant, forced turn or -1].
func gable_variant(k:int)->Array:
	var u:=unpack(k);var cells:=edge_cells(k);var along:=Vector2i(0,1) if int(u[0])==EX else Vector2i(1,0)
	for i in 2:
		var roof_key:=key(FILL,cells[i].x,cells[i].y,u[3])
		if not pieces.has(roof_key):continue
		var f:=facing(int(pieces[roof_key].turn));var outward:Vector2i=cells[1-i]-cells[i]
		match str(KINDS[pieces[roof_key].kind].get("shape","")):
			"slope":
				if f==along or f==-along:return ["half",(0 if f==Vector2i(0,-1) else 1) if int(u[0])==EX else (0 if f==Vector2i(1,0) else 1)]
				if f==outward:return ["rect",-1]
			"ridge":
				if f==along or f==-along:return ["tri",-1]
			"peak":
				return ["pent",-1] if f==along or f==-along else ["rect",-1]
	return ["tri",-1]

func make(kind:String,k:int,t:int,solid:bool)->Node3D:
	var spec:Dictionary=KINDS[kind];var node:=Node3D.new();var variant:=""
	if spec.get("shape","")=="gable":
		var fit:=gable_variant(k);variant=str(fit[0])
		if int(fit[1])>=0:t=int(fit[1])
	node.rotation.y=yaw(k,t)
	var art:=FortArt.asset("piece_"+kind.to_lower()+("" if variant=="" else "_"+variant))
	if art:art.name="Art";node.add_child(art)
	else:fallback(node,spec,variant)
	if solid:
		collide(node,spec,variant)
		if spec.get("shape","")=="prop":
			var glow:=OmniLight3D.new();glow.position.y=1.5;glow.light_color=Color("#ffb46a");glow.light_energy=1.6;glow.omni_range=11.0;glow.shadow_enabled=false;node.add_child(glow)
	return node

func remake(k:int)->void:
	var d:Dictionary=pieces[k];var old:Node3D=d.node
	var node:=make(d.kind,k,d.turn,true);node.name=old.name;node.set_meta("piece",k);node.position=old.position
	old.name="Old";old.queue_free();root.add_child(node);d.node=node

func reskin_around(k:int)->void:
	var u:=unpack(k)
	for e in [key(EX,u[1],u[2],u[3]),key(EX,u[1]-1,u[2],u[3]),key(EZ,u[1],u[2],u[3]),key(EZ,u[1],u[2]-1,u[3])]:
		if pieces.has(e) and KINDS[pieces[e].kind].get("shape","")=="gable":remake(e)

static func fallback(node:Node3D,spec:Dictionary,variant:String)->void:
	var color:=Color("#8b919c") if spec.mat=="stone" else Color("#8c5f3c")
	match str(spec.slot):
		"deck":node.add_child(Visuals.box(Vector3(4,.6 if spec.get("ground",false) else .4,4),color,Vector3(0,-.3 if spec.get("ground",false) else -.2,0)))
		"edge":
			var height:float=GABLE_HEIGHT.get(variant,1.3 if spec.get("shape","")=="low" else 5.0)
			node.add_child(Visuals.box(Vector3(4,height,.4),color,Vector3(0,height*.5,0)))
		"corner":node.add_child(Visuals.box(Vector3(.5,5,.5),color,Vector3(0,2.5,0)))
		_:node.add_child(Visuals.box(Vector3(3.6,1.2,3.6),color,Vector3(0,.6,0)))

static func hull(name:String,points:PackedVector3Array)->Shape3D:
	if not shapes.has(name):
		var shape:=ConvexPolygonShape3D.new();shape.points=points;shapes[name]=shape
	return shapes[name]

func collide(node:Node3D,spec:Dictionary,variant:String)->void:
	var shape:String=spec.get("shape","")
	match str(spec.slot):
		"deck":
			if spec.get("ground",false):
				# A battered plinth: the sloped skirt lets dwarves and raiders walk up without a ramp.
				Visuals.add_static_collision(node,hull("plinth",PackedVector3Array([Vector3(-2,0,-2),Vector3(2,0,-2),Vector3(2,0,2),Vector3(-2,0,2),Vector3(-2.72,-.62,-2.72),Vector3(2.72,-.62,-2.72),Vector3(2.72,-.62,2.72),Vector3(-2.72,-.62,2.72),Vector3(-2.72,-1.6,-2.72),Vector3(2.72,-1.6,-2.72),Vector3(2.72,-1.6,2.72),Vector3(-2.72,-1.6,2.72)])))
			else:FortArt.box_collider(node,Vector3(4,.4,4),Vector3(0,-.2,0))
		"edge":
			if shape=="doorway":
				for x in [-1.6,1.6]:FortArt.box_collider(node,Vector3(.8,5,.5),Vector3(x,2.5,0))
				FortArt.box_collider(node,Vector3(2.4,1.4,.5),Vector3(0,4.3,0))
				if spec.get("door",false):
					var body:=Visuals.add_static_collision(node,BoxShape3D.new(),Vector3(0,1.8,0));body.name="DoorBody"
					((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).size=Vector3(2.4,3.6,.24)
			elif shape=="low":FortArt.box_collider(node,Vector3(4,1.3,.4),Vector3(0,.65,0))
			elif shape=="gable":
				var height:float=GABLE_HEIGHT.get(variant,1.5)
				FortArt.box_collider(node,Vector3(4,height*.6,.3),Vector3(0,height*.3,0))
			else:FortArt.box_collider(node,Vector3(4,5,.5),Vector3(0,2.5,0))
		"corner":FortArt.box_collider(node,Vector3(.62,5,.62) if spec.get("full",false) else Vector3(.3,5,.3),Vector3(0,2.5,0))
		"fill":
			match shape:
				"stairs":Visuals.add_static_collision(node,hull("stairs",PackedVector3Array([Vector3(-1.8,0,2),Vector3(1.8,0,2),Vector3(-1.8,0,-6),Vector3(1.8,0,-6),Vector3(-1.8,5,-6),Vector3(1.8,5,-6)])))
				"slope":Visuals.add_static_collision(node,hull("slope",PackedVector3Array([Vector3(-2,0,2.3),Vector3(2,0,2.3),Vector3(-2,0,-2),Vector3(2,0,-2),Vector3(-2,3,-2),Vector3(2,3,-2)])))
				"ridge":Visuals.add_static_collision(node,hull("ridge",PackedVector3Array([Vector3(-2,0,2.3),Vector3(2,0,2.3),Vector3(-2,0,-2.3),Vector3(2,0,-2.3),Vector3(-2,1.6,0),Vector3(2,1.6,0)])))
				"peak":Visuals.add_static_collision(node,hull("peak",PackedVector3Array([Vector3(-2,0,2),Vector3(2,0,2),Vector3(-2,0,-2),Vector3(2,0,-2),Vector3(-2,3,2),Vector3(2,3,2),Vector3(-2,3,-2),Vector3(2,3,-2),Vector3(-2,4.6,0),Vector3(2,4.6,0)])))
				"cap":Visuals.add_static_collision(node,hull("cap",PackedVector3Array([Vector3(-2.2,0,2.2),Vector3(2.2,0,2.2),Vector3(-2.2,0,-2.2),Vector3(2.2,0,-2.2),Vector3(0,3,0)])))
				"spire":Visuals.add_static_collision(node,hull("spire",PackedVector3Array([Vector3(-2.2,0,2.2),Vector3(2.2,0,2.2),Vector3(-2.2,0,-2.2),Vector3(2.2,0,-2.2),Vector3(0,6,0)])))
				_:FortArt.box_collider(node,Vector3(1.1,1.2,1.1),Vector3(0,.6,0))

# ------------------------------------------------------------------ every frame
func tick(delta:float)->void:
	for k in doors:
		var d:Dictionary=pieces[k];var pos:Vector3=d.node.position;var wanted:=0.0
		for p in world.players.values():
			if p.health>0 and absf(p.position.y-pos.y-1.0)<2.6 and Vector2(p.position.x-pos.x,p.position.z-pos.z).length()<3.3:wanted=1.0;break
		var amount:float=move_toward(float(d.get("open",0.0)),wanted,delta*3.2);d.open=amount
		if not d.has("leaf") or not is_instance_valid(d.leaf):d.leaf=d.node.find_child("Door",true,false)
		if d.leaf:(d.leaf as Node3D).rotation.y=-amount*1.85
		var shut:bool=amount<.45
		if bool(d.get("shut",true))!=shut:
			d.shut=shut
			var body:Node=d.node.get_node_or_null("DoorBody")
			if body:(body.get_child(0) as CollisionShape3D).set_deferred("disabled",not shut)
			if world.multiplayer.is_server():world.navigation_revision+=1
	if not world.multiplayer.is_server() or world.ended:return
	drop_clock-=delta
	if drop_clock<=0:drop_clock=.3;tick_drops()

# ------------------------------------------------------------------ local build tool
func selected()->String:
	var items:Array=TABS[tab].items
	return items[clampi(index,0,items.size()-1)]
func select(tab_index:int,item:int)->void:
	tab=clampi(tab_index,0,TABS.size()-1);index=clampi(item,0,TABS[tab].items.size()-1)
func cycle(step:int)->void:
	index=posmod(index+step,TABS[tab].items.size())
func hide()->void:
	if is_instance_valid(ghost):ghost.hide()
	mark(-1);target=-1;aimed=-1

func mark(k:int)->void:
	if marked==k:return
	if pieces.has(marked):
		for mesh in pieces[marked].node.find_children("*","MeshInstance3D",true,false):mesh.material_overlay=null
	marked=k if pieces.has(k) else -1
	if marked<0:return
	if not mark_material:
		mark_material=Visuals.material(Color(1,.42,.3,.3));mark_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mark_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for mesh in pieces[marked].node.find_children("*","MeshInstance3D",true,false):mesh.material_overlay=mark_material

## Where the crosshair points: [point, piece key under it or -1, view direction].
func aim()->Array:
	var p:=world.local_player();var camera:=world.get_viewport().get_camera_3d()
	if not p or not camera:return []
	var direction:=-camera.global_basis.z;var origin:=camera.global_position
	origin+=direction*maxf(0,(p.global_position+Vector3.UP*1.2-origin).dot(direction)-.4)
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+direction*16,1,[p.get_rid()]))
	if not hit.is_empty():return [hit.position,piece_of(hit.collider),direction,hit.collider]
	var point:=origin+direction*9.0
	if direction.y<-.08:point=origin+direction*minf(16,(p.position.y-origin.y)/direction.y)
	else:point.y=p.position.y
	return [point,-1,direction,null]

## Choose the lattice slot for this piece nearest to the aimed point. Returns [key, turn].
func pick(kind:String,point:Vector3,direction:Vector3)->Array:
	var spec:Dictionary=KINDS[kind];var flat:=Vector3(direction.x,0,direction.z)
	flat=flat.normalized() if flat.length()>.01 else Vector3.FORWARD
	var heading:=posmod(roundi(atan2(-flat.x,-flat.z)/(PI*.5)),4)
	var near:=point-flat*.2
	var standing:=maxi(0,floori((point.y-FortCastle.BASE+.5)/FortCastle.HEIGHT))
	var above:=maxi(1,roundi((point.y-FortCastle.BASE)/FortCastle.HEIGHT))
	match str(spec.slot):
		"deck":
			var level:=0 if spec.get("ground",false) else clampi(above+lift,1,MAX_LEVEL)
			return [key(DECK,roundi(near.x/CELL),roundi(near.z/CELL),level),0]
		"edge":
			var a:=Vector2(roundi((point.x-2)/CELL),roundi(point.z/CELL));var b:=Vector2(roundi(point.x/CELL),roundi((point.z-2)/CELL))
			var score_a:float=Vector2(point.x-a.x*CELL-2,point.z-a.y*CELL).length()-1.1*absf(flat.x)
			var score_b:float=Vector2(point.x-b.x*CELL,point.z-b.y*CELL-2).length()-1.1*absf(flat.z)
			var slot:=EX if score_a<score_b else EZ;var cell:=a if slot==EX else b
			var level:=standing
			if is_full(key(slot,int(cell.x),int(cell.y),level),live_spans()) and point.y>level_y(level)+2.5:level+=1
			level=clampi(level+lift,0,MAX_LEVEL)
			var k:=key(slot,int(cell.x),int(cell.y),level)
			# The outer face looks away from the builder; Q flips it.
			var flip:=0 if Vector3.BACK.rotated(Vector3.UP,yaw(k,0)).dot(flat)>0 else 1
			return [k,(flip+turn)&1]
		"corner":
			var cx:=roundi((point.x-2)/CELL);var cz:=roundi((point.z-2)/CELL);var level:=standing
			if is_full(key(CORNER,cx,cz,level),live_spans()) and point.y>level_y(level)+2.5:level+=1
			return [key(CORNER,cx,cz,clampi(level+lift,0,MAX_LEVEL)),0]
	var storey:=clampi((above if spec.get("roof",false) else standing)+lift,1 if spec.get("roof",false) else 0,MAX_LEVEL)
	return [key(FILL,roundi(near.x/CELL),roundi(near.z/CELL),storey),(heading+turn)&3]

func update_preview()->void:
	var view:=aim()
	if view.is_empty():hide();return
	var kind:=selected();var choice:=pick(kind,view[0],view[2])
	target=choice[0];target_turn=choice[1];aimed=view[1]
	mark(aimed)
	target_reason=reason(kind,target,target_turn)
	var fits:bool=target_reason=="" and can_afford(kind)
	var stamp:="%s/%s"%[kind,str(gable_variant(target)) if KINDS[kind].get("shape","")=="gable" else ""]
	if not is_instance_valid(ghost) or ghost_stamp!=stamp:
		if is_instance_valid(ghost):ghost.queue_free()
		ghost=make(kind,target,target_turn,false);ghost_stamp=stamp;world.add_child(ghost)
	ghost.show();ghost.position=place(target)
	if KINDS[kind].get("shape","")!="gable":ghost.rotation.y=yaw(target,target_turn)
	else:
		var fit:=gable_variant(target);ghost.rotation.y=yaw(target,int(fit[1]) if int(fit[1])>=0 else target_turn)
	if not ghost_ok:
		ghost_ok=Visuals.material(Color(.3,.9,.68,.5));ghost_bad=Visuals.material(Color(.95,.28,.2,.5))
		for material in [ghost_ok,ghost_bad]:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	world._override_material(ghost,ghost_ok if fits else ghost_bad)

func place_selected()->void:
	if target<0:return
	var kind:=selected()
	if target_reason!="":world.show_toast(target_reason);return
	if not can_afford(kind):world.show_toast(FortGlyphs.t("Not enough in the shared stockpile. %s costs %s."%[KINDS[kind].name,GameData.supplies_text(cost(kind),true)]));return
	world.request_action("piece_place",{"kind":kind,"key":target,"turn":target_turn})

## X in build mode: take down the piece under the crosshair, or salvage the defense there.
func remove_aimed()->void:
	var view:=aim()
	if view.is_empty():return
	if pieces.has(int(view[1])):world.request_action("piece_remove",{"key":int(view[1])});return
	var id:=FortSiege.obstacle_id(view[3]) if view[3] else -1
	if not world.defenses.has(id):world.show_toast("Aim at a building piece or a defense, then press X to take it down.");return
	var d:Dictionary=world.defenses[id]
	if world.is_night or FortConstruction.pending(d) or d.temporary:world.show_toast("Defenses can be salvaged by day once they are finished. Pieces can come down any time.");return
	if world.local_player().position.distance_to(d.node.position)>4:world.show_toast("Stand next to the %s to salvage it."%d.kind);return
	world.request_action("salvage_defense",{"id":id,"revision":int(d.get("work_revision",0))})

func status()->String:
	var kind:=selected();var spec:Dictionary=KINDS[kind]
	var line:="%s   %s   ·   "%[spec.name,GameData.supplies_text(cost(kind),true)]
	if target_reason!="":line+="CANNOT BUILD: "+target_reason
	elif not can_afford(kind):line+="NOT ENOUGH IN THE STOCKPILE"
	else:line+="Click to build"
	line+="\nTab category  ·  Wheel / 1-9 piece  ·  Q turn  ·  ↑ ↓ storey%s"%(" (%+d)"%lift if lift!=0 else "")
	if pieces.has(aimed):
		var d:Dictionary=pieces[aimed]
		line+="  ·  X remove %s (%d%%, returns %s)"%[KINDS[d.kind].name,ceili(100.0*float(d.hp)/float(d.max_hp)),GameData.supplies_text(refund(aimed),true)]
	else:line+="  ·  X remove the piece you aim at"
	return line
