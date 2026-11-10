class_name FortPerimeter
extends RefCounted

static func bounds(c:FortCastle)->Vector4i:
	var result:=Vector4i(0,0,0,0)
	for r in c.rooms.values():
		if r.floor!=0:continue
		result.x=mini(result.x,int(r.x));result.y=maxi(result.y,int(r.x));result.z=mini(result.z,int(r.z));result.w=maxi(result.w,int(r.z))
	# At least two cells of clearance. Step outward around protected landmarks.
	for attempt in 24:
		var before:=result
		for obstacle in c.world.scenery_keepouts:
			if obstacle.get("clearable",false) or obstacle.get("knoll",false):continue
			var p:Vector3=obstacle.pos;var radius:=float(obstacle.radius)+3
			if p.z>result.z*20-50-radius and p.z<result.w*20+50+radius:
				if absf(p.x-(result.x*20-50))<radius:result.x-=1
				if absf(p.x-(result.y*20+50))<radius:result.y+=1
			if p.x>result.x*20-50-radius and p.x<result.y*20+50+radius:
				if absf(p.z-(result.z*20-50))<radius:result.z-=1
				if absf(p.z-(result.w*20+50))<radius:result.w+=1
		if result==before:break
	return result
static func activate(c:FortCastle,id:int,k:String,expected:int)->void:
	if expected!=c.revision or k!="0:0:0" or not c.authorized(id,k) or c.world.hearth_level<3 or c.world.is_night:return
	if c.perimeter.get("enabled",false):return
	var cost:={"wood":120,"stone":300,"iron":60}
	for resource in cost:
		if c.world.shared.get(resource,0)<cost[resource]:c.world.personal(id,"Outer wall needs "+FortGlyphs.t("120{wood}  300{stone}  60{iron}")+" in the shared stockpile.");return
	for resource in cost:c.world.shared[resource]-=cost[resource]
	c.perimeter={"enabled":true,"segments":{},"bounds":Vector4i(999,999,999,999)};c.changed()
static func sync(c:FortCastle)->void:
	if not c.world.multiplayer.is_server() or not c.perimeter.get("enabled",false):return
	var box:=bounds(c)
	if c.perimeter.get("bounds")==box:return
	var old:Dictionary=c.perimeter.get("segments",{});var next:Dictionary={}
	var left:=float(box.x*20-50);var right:=float(box.y*20+50);var north:=float(box.z*20-50);var south:=float(box.w*20+50)
	for actor in c.world.gates.actors():
		var pos:Vector3=actor.position
		if pos.y>4:continue
		if ((absf(pos.x-left)<2 or absf(pos.x-right)<2) and pos.z>north-2 and pos.z<south+2) or ((absf(pos.z-north)<2 or absf(pos.z-south)<2) and pos.x>left-2 and pos.x<right+2):
			c.perimeter.pending=true;return
	c.perimeter.pending=false
	for side in range(4):
		var horizontal:bool=side%2==0
		var start:=left if horizontal else north;var end:=right if horizontal else south
		var count:=roundi((end-start)/4)
		for i in count:
			var along:=start+2+i*4;var corner:bool=horizontal and i in [0,count-1]
			var gate:bool=corner or i==count/2
			var kind:="CastleGate" if gate else "CastleWall"
			var point:=Vector3(along,0,south if side==0 else north) if horizontal else Vector3(right if side==1 else left,0,along)
			point.y=FortVista.height(point) # the wall rides over hills
			for resource_id in c.world.resource_nodes:
				var resource:Dictionary=c.world.resource_nodes[resource_id]
				if resource.amount>0 and resource.node.position.distance_to(point)<3:
					resource.respawn=65;c.world.broadcast("recv_resource",[resource_id,0,false])
			for obstacle in c.world.scenery_keepouts:
				if obstacle.get("clearable",false) and obstacle.pos.distance_to(point)<float(obstacle.radius)+2:c.cleared_scenery[FortCastleClearance.scenery_key(obstacle)]=true
			var slot:="%d:%d"%[side,i];var record:Dictionary=old.get(slot,{})
			if not record.is_empty() and c.world.defenses.has(int(record.id)) and c.world.defenses[int(record.id)].kind==kind:
				var d:Dictionary=c.world.defenses[int(record.id)];d.node.position=point;d.node.rotation.y=side*PI/2;next[slot]=record
			elif not record.is_empty() and not c.world.defenses.has(int(record.id)):
				# Destroyed segments stay breached as the perimeter moves.
				next[slot]={"id":record.id,"pos":point,"kind":kind,"yaw":side*PI/2}
			else:
				var ratio:=1.0
				if not record.is_empty():
					var d:Dictionary=c.world.defenses[int(record.id)];ratio=float(d.hp)/float(d.max_hp);c.world.broadcast("recv_remove_defense",[int(record.id),true])
				c.world._spawn_defense(kind,point,side*PI/2,false)
				var id:=c.world.next_defense_id-1;c.world.defenses[id].hp*=ratio;c.world.defenses[id].perimeter=true
				next[slot]={"id":id,"pos":point,"kind":kind,"yaw":side*PI/2}
			next[slot].pos=point;next[slot].kind=kind;next[slot].yaw=side*PI/2
	for slot in old:
		if not next.has(slot):c.world.broadcast("recv_remove_defense",[int(old[slot].id),true])
	c.perimeter.segments=next;c.perimeter.bounds=box
	FortCastleClearance.apply_scenery(c)
	c.world.navigation_revision+=1
static func repair_breach(c:FortCastle,p:FortPlayer)->bool:
	for record in c.perimeter.get("segments",{}).values():
		if c.world.defenses.has(int(record.id)) or p.position.distance_to(record.pos)>4:continue
		else:
			for actor in c.world.gates.actors():
				if actor.position.distance_to(record.pos)<2:c.world.personal(p.peer_id,"Move clear of the breach to rebuild it.");return true
			if c.world.shared.stone<6 or c.world.shared.wood<2:c.world.personal(p.peer_id,"Rebuilding this breach needs "+FortGlyphs.t("6{stone}  2{wood}")+" in the shared stockpile.");return true
			c.world.shared.stone-=6;c.world.shared.wood-=2;c.world._spawn_defense(record.kind,record.pos,record.yaw,false)
			record.id=c.world.next_defense_id-1;c.world.defenses[record.id].hp=c.world.defenses[record.id].max_hp*.2;c.world.defenses[record.id].perimeter=true;c.changed();return true
	return false
