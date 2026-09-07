class_name FortCastleRemodel
extends RefCounted

static func inside(r:Dictionary,pos:Vector3,margin:=0.0)->bool:
	var center:=FortCastle.position(r)
	return absf(pos.y-center.y)<3.2 and absf(pos.x-center.x)<10+margin and absf(pos.z-center.z)<10+margin
static func refund(r:Dictionary)->Dictionary:
	var paid:Dictionary=r.get("paid",FortCastle.TYPES.get(r.kind,{}).get("cost",{}))
	var result:Dictionary={}
	for resource in paid:
		var amount:=int(paid[resource])
		# The terrace tower has its own salvage ledger; never refund it twice.
		if r.kind=="Rampart":amount=maxi(0,amount-int(GameData.RECIPES.Watchtower.get(resource,0)))
		result[resource]=floori(amount*.5)
	return result
static func reachable(layout:Dictionary)->Dictionary:
	var seen:Dictionary={"0:0:0":true};var queue:Array=["0:0:0"]
	while not queue.is_empty():
		var current:String=queue.pop_front();var r:Dictionary=layout[current]
		if not r.complete:continue
		for k in layout:
			if seen.has(k):continue
			var other:Dictionary=layout[k];var linked:=false
			if r.floor==other.floor:linked=absi(r.x-other.x)+absi(r.z-other.z)==1
			elif r.x==other.x and r.z==other.z:
				linked=(r.floor+1==other.floor and r.kind=="Stairs") or (other.floor+1==r.floor and other.kind=="Stairs")
			if linked:seen[k]=true;queue.append(k)
	return seen
static func reason(c:FortCastle,k:String,next_kind:String,id:=-1)->String:
	if not c.rooms.has(k) or k=="0:0:0":return "The central keep cannot be remodeled or dismantled"
	var r:Dictionary=c.rooms[k];var removing:=next_kind==""
	if not r.complete:return "Finish or cancel this blueprint first"
	if c.world.is_night:return "Remodeling and dismantling are daylight work"
	if not removing:
		if not FortCastle.TYPES.has(next_kind) or next_kind==r.kind:return "Choose a different room purpose"
		if c.world.hearth_level<int(FortCastle.TYPES[next_kind].tier):return "Upgrade the hearth for this room purpose"
	for other in c.rooms.values():
		if other.x==r.x and other.z==r.z and other.floor>r.floor and (removing or r.kind=="Stairs" or next_kind=="Stairs"):return "Remove upper rooms first: this floor or stairwell supports them"
	if removing:
		var layout:=c.rooms.duplicate();layout.erase(k)
		if reachable(layout).size()!=layout.size():return "This room is a connection to other wings. Remove outer rooms first"
		if r.floor==0 and c.completed_ground()<=4:
			for other in layout.values():
				if other.floor>0:return "Keep four ground wings while upper storeys exist"
	for d in c.world.defenses.values():
		if inside(r,d.node.position,.5):return "Salvage defenses and curtain walls in this room first"
	for e in c.world.enemies.values():
		if e.node.position.distance_to(FortCastle.position(r))<24:return "Clear nearby enemies before changing this room"
	for p in c.world.players.values():
		if inside(r,p.position) and (p.mounted_ballista>=0 or (p.peer_id!=id and (p.position.distance_to(r.sign)>4 or p.health<=0))):return "Ask other dwarves to leave the room or join you at its work sign"
	return ""
static func begin(c:FortCastle,id:int,k:String,next_kind:String,expected:int)->void:
	if expected!=c.revision or not c.authorized(id,k) or c.rooms[k].task!="":return
	var error:=reason(c,k,next_kind,id)
	if error!="":c.world.personal(id,error);return
	var r:Dictionary=c.rooms[k]
	r.task="dismantle" if next_kind=="" else "remodel";r.remodel_kind=next_kind;r.funded={};r.work=0.0;r.total=12.0 if next_kind=="" else float(FortCastle.TYPES[next_kind].work)
	c.changed()
static func finish(c:FortCastle,k:String)->void:
	var r:Dictionary=c.rooms[k];var returned:=refund(r)
	for resource in returned:c.world.shared[resource]+=int(returned[resource])
	if r.task=="dismantle":
		for p in c.world.players.values():
			if inside(r,p.position):c.world.broadcast("recv_teleport",[p.peer_id,Vector3(0,FortCastle.BASE+.1,7)])
		c.rooms.erase(k)
	else:
		r.kind=r.remodel_kind;r.paid=r.funded.duplicate();r.task="";r.work=0;r.total=0;r.funded={};r.erase("remodel_kind")
		if r.kind=="Rampart":
			c.world._spawn_defense("Watchtower",FortCastle.position(r)+Vector3(5,0,5),0,false)
			c.world.defenses[c.world.next_defense_id-1].paid={"wood":18,"stone":8}
	c.world.broadcast("recv_notice",["CASTLE / Work completed. Recovered "+GameData.supplies_text(returned,true)])
