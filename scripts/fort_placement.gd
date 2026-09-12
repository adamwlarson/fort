class_name FortPlacement
extends RefCounted
static func is_wall(kind:String)->bool:return kind in ["Barricade","MetalWall","Gatehouse"]
static func wall_width(kind:String)->float:return 5.6 if kind=="Gatehouse" else (3.5 if kind=="Barricade" else 2.8)
static func wall_depth(kind:String)->float:return 1.35 if kind=="Gatehouse" else .20
static func snap(world:FortWorld,kind:String,pos:Vector3,yaw:float)->Vector3:
	if not is_wall(kind):return pos
	var best:=pos;var distance:=1.5
	if kind=="Gatehouse":
		for r in world.castle.rooms.values():
			if not r.complete:continue
			for side in range(4):
				var normal:=Vector3.BACK.rotated(Vector3.UP,side*PI/2)
				if absf(normal.dot(Vector3.BACK.rotated(Vector3.UP,yaw)))<.99:continue
				var candidate:=FortCastle.position(r)+normal*9.5
				if candidate.distance_to(pos)<distance:best=candidate;distance=candidate.distance_to(pos)
		if best!=pos:return best
	var axis:=Vector3.RIGHT.rotated(Vector3.UP,yaw)*wall_width(kind)*.5
	for d in world.defenses.values():
		if not is_wall(d.kind):continue
		var other_axis:=Vector3.RIGHT.rotated(Vector3.UP,d.node.rotation.y)*wall_width(d.kind)*.5
		for side in [-1,1]:
			for own_side in [-1,1]:
				var candidate:Vector3=d.node.position+other_axis*side+axis*own_side
				if candidate.distance_to(d.node.position)<1:continue
				if candidate.distance_to(pos)<distance:best=candidate;distance=candidate.distance_to(pos)
	return best
static func wall_overlap(a:Vector3,ay:float,ak:String,b:Vector3,by:float,bk:String)->bool:
	if a.y>b.y+(6.5 if bk=="Gatehouse" else 2.8) or b.y>a.y+(6.5 if ak=="Gatehouse" else 2.8):return false
	# Separating-axis test allows touching ends/corners but rejects crossing walls.
	var aa:=Vector2(cos(ay),-sin(ay));var ab:=Vector2(-aa.y,aa.x)
	var ba:=Vector2(cos(by),-sin(by));var bb:=Vector2(-ba.y,ba.x)
	var delta:=Vector2(b.x-a.x,b.z-a.z)
	if absf(aa.dot(ba))<.99:
		for side in [-1,1]:
			for other_side in [-1,1]:
				if (Vector2(a.x,a.z)+aa*wall_width(ak)*.5*side).distance_to(Vector2(b.x,b.z)+ba*wall_width(bk)*.5*other_side)<.08:return false
	for axis in [aa,ab,ba,bb]:
		var ra:=absf(axis.dot(aa))*wall_width(ak)*.5+absf(axis.dot(ab))*wall_depth(ak)
		var rb:=absf(axis.dot(ba))*wall_width(bk)*.5+absf(axis.dot(bb))*wall_depth(bk)
		if absf(delta.dot(axis))>=ra+rb-.08:return false
	return true
