class_name FortCastleClearance
extends RefCounted

static func scenery_key(obstacle:Dictionary)->String:
	var p:Vector3=obstacle.pos
	return "%.3f/%.3f/%.3f"%[p.x,p.y,p.z]
static func overlaps(target:Dictionary,pos:Vector3,extent:Vector2)->bool:
	var center:=FortCastle.position(target)
	return absf(pos.y-center.y)<3 and absf(pos.x-center.x)<10+extent.x and absf(pos.z-center.z)<10+extent.y
static func scenery_overlap(target:Dictionary,obstacle:Dictionary)->bool:
	var center:=FortCastle.position(target)
	var edge:=Vector2(maxf(0,absf(obstacle.pos.x-center.x)-10),maxf(0,absf(obstacle.pos.z-center.z)-10))
	return int(target.floor)==0 and edge.length()<float(obstacle.radius)
static func refund(w:FortWorld,d:Dictionary)->Dictionary:
	if d.temporary:return {}
	var result:=w.construction.salvage_refund(d)
	if FortConstruction.pending(d):
		var unused:=w.construction.refund(d)
		for kind in unused:result[kind]=int(result.get(kind,0))+int(unused[kind])
	for kind in result.keys():
		if int(result[kind])<=0:result.erase(kind)
	return result
static func inspect(c:FortCastle,target:Dictionary)->Dictionary:
	var result:={"resources":[],"scenery":[],"defenses":[],"refund":{},"token":""};var ledger:Array=[]
	if int(target.floor)==0:
		var center:=FortCastle.position(target)
		for id in c.world.resource_nodes:
			var r:Dictionary=c.world.resource_nodes[id]
			if r.amount>0 and absf(r.node.position.x-center.x)<10.8 and absf(r.node.position.z-center.z)<10.8:result.resources.append(id)
		for obstacle in c.world.scenery_keepouts:
			if obstacle.get("clearable",false) and scenery_overlap(target,obstacle):result.scenery.append(scenery_key(obstacle))
	for id in c.world.defenses:
		var d:Dictionary=c.world.defenses[id];var extent:=Vector2.ONE*(2.7 if d.kind=="Watchtower" else 2.0)
		if FortPlacement.is_wall(d.kind):
			var yaw:float=d.node.rotation.y;var half:=FortPlacement.wall_width(d.kind)*.5
			var depth:=FortPlacement.wall_depth(d.kind)
			extent=Vector2(absf(cos(yaw))*half+absf(sin(yaw))*depth,absf(sin(yaw))*half+absf(cos(yaw))*depth)
		var touches:=overlaps(target,d.node.position,extent)
		if d.kind=="Gatehouse":touches=touches or overlaps(target,d.node.position+Vector3.UP*3.5,extent)
		if not touches:continue
		result.defenses.append(int(id));var returned:=refund(c.world,d)
		for kind in returned:result.refund[kind]=int(result.refund.get(kind,0))+int(returned[kind])
		var amounts:Array=[]
		for kind in GameData.RESOURCES:amounts.append(int(returned.get(kind,0)))
		ledger.append([int(id),d.kind,int(d.get("work_revision",0)),amounts])
	ledger.sort_custom(func(a,b):return a[0]<b[0])
	result.token=str([int(target.x),int(target.z),int(target.floor),ledger]).sha256_text()
	return result
static func summary(info:Dictionary)->String:
	return "AUTO-CLEAR / %d resources · %d scenery · %d defenses\nSalvage to shared stock: %s\nClearing happens on placement; canceling does not restore removed objects."%[info.resources.size(),info.scenery.size(),info.defenses.size(),GameData.supplies_text(info.refund,true)]
static func apply(c:FortCastle,info:Dictionary)->void:
	for id in info.resources:
		c.world.resource_nodes[id].respawn=65.0
		c.world.broadcast("recv_resource",[int(id),0,false])
	for key in info.scenery:c.cleared_scenery[key]=true
	for id in info.defenses:c.world.broadcast("recv_remove_defense",[int(id),true])
	for kind in info.refund:c.world.shared[kind]=int(c.world.shared.get(kind,0))+int(info.refund[kind])
	apply_scenery(c)
static func apply_scenery(c:FortCastle)->void:
	for obstacle in c.world.scenery_keepouts.duplicate():
		if not obstacle.get("clearable",false) or not c.cleared_scenery.has(scenery_key(obstacle)):continue
		var node:Node3D=obstacle.get("node")
		if is_instance_valid(node):
			node.hide()
			for body in node.find_children("*","CollisionObject3D",true,false):body.collision_layer=0;body.collision_mask=0
		for batch in obstacle.get("batches",[]):
			if is_instance_valid(batch):batch.multimesh.set_instance_transform(int(obstacle.index),Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
		c.world.scenery_keepouts.erase(obstacle)
