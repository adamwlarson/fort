class_name FortCastleFeatures
extends RefCounted

const SIDES:=["South","East","North","West"]
static func level(r:Dictionary)->int:return clampi(int(r.get("level",1)),1,4)
static func healthy(r:Dictionary)->bool:return float(r.get("health",1200.0))>0
static func max_health(r:Dictionary)->float:return 1200.0*(1+.2*(level(r)-1))
static func damage_rooms(c:FortCastle,pos:Vector3,radius:float,amount:float)->void:
	var changed:=false
	for r in c.rooms.values():
		if not r.complete or r.kind=="Keep":continue
		var delta:=pos-FortCastle.position(r)
		if absf(delta.y)>3 or maxf(absf(delta.x)-10,0)>radius or maxf(absf(delta.z)-10,0)>radius:continue
		r.health=maxf(0,float(r.get("health",max_health(r)))-amount);changed=true
	if changed:c.changed()
static func repair(c:FortCastle,id:int)->bool:
	var k:=c.nearest(c.world.players[id].position)
	if k=="" or c.rooms[k].kind=="Keep":return false
	var r:Dictionary=c.rooms[k];var maximum:=max_health(r)
	if float(r.get("health",maximum))>=maximum or c.world.shared.wood<1:return false
	c.world.shared.wood-=1;r.health=minf(maximum,float(r.get("health",maximum))+(96 if c.world.players[id].role_id==2 else 48));c.changed();return true
static func completion_reason(c:FortCastle,r:Dictionary)->String:
	if not str(r.task).begins_with("edge:"):return ""
	var parts:=str(r.task).split(":");var side:=int(parts[1])
	if parts[2]=="solid" and last_exit(c,FortCastle.key(r.x,r.z,r.floor),side):return "Each outer side of the castle needs at least one opening or gate. Open another doorway on this side first."
	var point:=FortCastle.position(r)+Vector3.BACK.rotated(Vector3.UP,side*PI/2)*9.8
	for actor in c.world.gates.actors():
		if actor.position.distance_to(point)<2.5:return "Someone is standing in this doorway. Move clear to finish the wall."
	return ""
static func upgrade_cost(r:Dictionary)->Dictionary:return {"wood":30*level(r),"stone":40*level(r),"iron":8*level(r)}
static func benefit(r:Dictionary)->String:
	var rank:=level(r)
	match r.kind:
		"Keep":return "Open sky above the hearth. Upgrade the hearth with U to improve the keep."
		"Gatherers":return "Harvests nearby nodes every 12s by day. +20%% output per upgrade (current +%d%%)."%((rank-1)*20)
		"Merchant":return "Buy and sell at the tent for shared gold. +5%% buying discount per upgrade (current %d%%)."%((rank-1)*5)
		"Research":return "Crew research projects. Each upgrade adds 5% crew construction speed and +2 pack capacity."
		"Stairs":return "Walk to the next storey. +10% movement in this stairwell per upgrade."
		"Courtyard":return "Open defense space. Each upgrade repairs nearby defenses by 4 health every 12s in daylight."
		"Rampart","Sentry":return "Defenses in this room deal +20% damage per upgrade. Sentry cannons fire outward through windows."
	return ""
static func inside(r:Dictionary,pos:Vector3)->bool:
	var d:=pos-FortCastle.position(r)
	return r.complete and healthy(r) and absf(d.x)<10 and absf(d.z)<10 and d.y>-.5 and d.y<FortCastle.HEIGHT
static func room_multiplier(c:FortCastle,pos:Vector3,kinds:Array,amount:float)->float:
	var bonus:=0.0
	for r in c.rooms.values():
		if r.kind in kinds and inside(r,pos):bonus=maxf(bonus,(level(r)-1)*amount)
	return 1.0+bonus
static func begin(c:FortCastle,id:int,k:String,task:String,expected:int)->bool:
	if not (task=="upgrade_room" or task.begins_with("edge:") or task=="sentry_cannons"):return false
	if expected!=c.revision or not c.authorized(id,k):return true
	var r:Dictionary=c.rooms[k]
	if not r.complete or r.task!="":return true
	if not healthy(r):c.world.personal(id,"This room is ruined. Hold R at its sign to repair it first.");return true
	if task=="upgrade_room":
		if r.kind=="Keep" or level(r)>=4:return true
		if c.world.hearth_level<level(r)+1:c.world.personal(id,"Room level cannot pass the hearth tier. Upgrade the hearth with U first.");return true
	elif task=="sentry_cannons":
		if r.kind!="Sentry":return true
		for cannon in r.get("cannons",[]):
			if c.world.defenses.has(cannon):c.world.personal(id,"This room already has its cannons.");return true
	else:
		var parts:=task.split(":")
		if parts.size()!=3 or not parts[1].is_valid_int() or int(parts[1]) not in range(4) or parts[2] not in ["open","gate","solid"]:return true
		var side:=int(parts[1])
		if parts[2]=="solid" and last_exit(c,k,side):c.world.personal(id,"Each outer side of the castle needs at least one opening or gate. Open another doorway on this side first.");return true
		var point:=FortCastle.position(r)+Vector3.BACK.rotated(Vector3.UP,side*PI/2)*9.8
		for p in c.world.players.values():
			if p.position.distance_to(point)<2.5:c.world.personal(id,"Someone is standing in this doorway. Move clear, then try again.");return true
	r.task=task;r.funded={};r.work=0.0;r.total=20.0;c.changed();return true
static func last_exit(c:FortCastle,k:String,side:int)->bool:
	var delta:=Vector3.BACK.rotated(Vector3.UP,side*PI/2)
	var current:Dictionary=c.rooms[k]
	if int(current.floor)>0:return false
	var neighbor:=FortCastle.key(current.x+roundi(delta.x),current.z+roundi(delta.z),0)
	if c.rooms.has(neighbor) and c.rooms[neighbor].complete:return false
	for other in c.rooms:
		var r:Dictionary=c.rooms[other]
		if other==k or not r.complete or int(r.floor)!=0:continue
		neighbor=FortCastle.key(r.x+roundi(delta.x),r.z+roundi(delta.z),0)
		if c.rooms.has(neighbor) and c.rooms[neighbor].complete:continue
		if r.get("portals",{}).get(side,"open")!="solid":return false
	return true
static func finish(c:FortCastle,r:Dictionary)->bool:
	if r.task=="upgrade_room":
		var old:=max_health(r);r.level=level(r)+1;r.health=float(r.get("health",old))+max_health(r)-old;return true
	if r.task=="sentry_cannons":
		r.cannons=[]
		for side in range(4):
			var yaw:=side*PI/2;var pos:=FortCastle.position(r)+Vector3.BACK.rotated(Vector3.UP,yaw)*8.7
			c.world._spawn_defense("SentryCannon",pos,yaw,false);r.cannons.append(c.world.next_defense_id-1)
		return true
	if not str(r.task).begins_with("edge:"):return false
	var parts:=str(r.task).split(":");var side:=int(parts[1])
	if not r.has("portals"):r.portals={}
	r.portals[side]=parts[2]
	# Shared boundary has one mechanism, with both signs reflecting its mode.
	var delta:=Vector3.BACK.rotated(Vector3.UP,side*PI/2)
	var neighbor:=FortCastle.key(r.x+roundi(delta.x),r.z+roundi(delta.z),r.floor)
	if c.rooms.has(neighbor):
		var other:Dictionary=c.rooms[neighbor]
		if not other.has("portals"):other.portals={}
		other.portals[(side+2)%4]=parts[2]
		remove_edge(c,other,(side+2)%4)
	make_edge(c,r,side)
	return true
static func remove_edge(c:FortCastle,r:Dictionary,side:int)->void:
	for id in r.get("edge_defenses",{}).get(side,[]):
		c.world.broadcast("recv_remove_defense",[id,true]);r.walls.erase(id)
static func make_edge(c:FortCastle,r:Dictionary,side:int)->void:
	remove_edge(c,r,side)
	if not r.has("edge_defenses"):r.edge_defenses={}
	r.edge_defenses[side]=[]
	var mode:String=r.get("portals",{}).get(side,"open")
	for offset in [-8.0,-4.0,0.0,4.0,8.0]:
		if offset==0 and mode=="open":continue
		var kind:="CastleGate" if offset==0 and mode=="gate" else ("CastleWindow" if r.kind=="Sentry" and absf(offset)==4 else "CastleWall")
		var pos:=FortCastle.position(r)+Vector3(offset,0,9.8).rotated(Vector3.UP,side*PI/2)
		c.world._spawn_defense(kind,pos,side*PI/2,false)
		var id:=c.world.next_defense_id-1;r.walls.append(id);r.edge_defenses[side].append(id)
		c.world.defenses[id].paid={"wood":2,"stone":6}
static func furnish(root:Node3D,r:Dictionary)->void:
	var rank:=level(r)
	if not healthy(r):
		for i in 7:root.add_child(Visuals.box(Vector3(1.5,.5,1.2),Color("#383838"),Vector3(-5+i*1.5,.25,5)))
		return
	if r.kind=="Stairs":
		for z in [-7.0,7.0]:
			FortCastleArt.model(root,"lantern",Vector3(-4,1.4,z))
			root.add_child(Visuals.box(Vector3(3,.35,1),FortArt.WOOD,Vector3(-5,.4,z)))
		FortCastleArt.model(root,"castle_research",Vector3(-6,0,0),Vector3.ONE*.65)
	for i in range(1,rank):
		var pos:=Vector3(-7+i*3,0,7)
		FortCastleArt.model(root,"castle_lodge" if r.kind=="Gatherers" else ("castle_research" if r.kind=="Research" else "lantern"),pos,Vector3.ONE*.65)
		root.add_child(Visuals.box(Vector3(1.6,.3,.8),FortArt.WOOD, pos+Vector3.UP*.55))
	if r.kind=="Sentry":
		for x in [-6,6]:FortCastleArt.model(root,"barrel",Vector3(x,0,6))
		var label:=Visuals.label_3d("SENTRY / BUILD WINDOW CANNONS AT SIGN",Color("#e5bf80"),2);label.position.z=6;root.add_child(label)
