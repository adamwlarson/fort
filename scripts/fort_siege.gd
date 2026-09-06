class_name FortSiege
extends RefCounted
static func priority(world:FortWorld,e:Dictionary)->int:
	if e.kind not in ["Brute","Sapper"]:return -1
	var best:=-1;var score:=INF
	for id in world.defenses:
		var d:Dictionary=world.defenses[id];var distance:float=e.node.position.distance_to(d.node.position)
		if distance>24:continue
		var candidate:=distance
		if e.kind=="Brute" and FortPlacement.is_wall(d.kind):candidate-=12
		if e.kind=="Sapper":candidate-=18 if FortConstruction.pending(d) else (10 if not FortPlacement.is_wall(d.kind) else 0)
		if candidate<score:score=candidate;best=id
	return best
static func obstacle_id(node:Node)->int:
	while node:
		if node.has_meta("defense_id"):return int(node.get_meta("defense_id"))
		node=node.get_parent()
	return -1
static func clear(world:FortWorld,a:Vector3,b:Vector3)->bool:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a+Vector3.UP*.7,b+Vector3.UP*.7,1)).is_empty()
static func route(world:FortWorld,e:Dictionary,goal:Vector3)->Vector3:
	var pos:Vector3=e.node.position
	if world.clock<float(e.get("route_until",0)) and e.get("route_goal",goal).distance_to(goal)<2:
		var waypoints:Array=e.get("route_points",[])
		while not waypoints.is_empty() and pos.distance_to(waypoints[0])<.65:waypoints.pop_front()
		if not waypoints.is_empty():return (waypoints[0]-pos).normalized()
		var breach:int=e.get("breach",-1)
		return ((world.defenses[breach].node.position if world.defenses.has(breach) else goal)-pos).normalized()
	e.route_until=world.clock+.8;e.route_goal=goal;e.breach=-1;e.route_points=[]
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3.UP*.7,goal+Vector3.UP*.7,1))
	if hit.is_empty():return (goal-pos).normalized()
	var blocker:=obstacle_id(hit.collider)
	if blocker<0:
		var direction:=world._steer_around_scenery(e.node,(goal-pos).normalized(),e.node.get_instance_id(),e)
		e.route_points=[pos+direction*1.5];e.route_until=world.clock+.4
		return direction
	if e.kind in ["Brute","Sapper"]:e.breach=blocker;return (world.defenses[blocker].node.position-pos).normalized()
	var best:Array=[];var score:float=pos.distance_to(goal)+14
	# Check exposed ends of the wall chain, not merely this one segment.
	for d in world.defenses.values():
		if not FortPlacement.is_wall(d.kind) or d.node.position.distance_to(pos)>20:continue
		var axis:=Vector3.RIGHT.rotated(Vector3.UP,d.node.rotation.y)
		var normal:=Vector3(-axis.z,0,axis.x)
		if (pos-d.node.position).dot(normal)<0:normal=-normal
		for side in [-1,1]:
			var end:Vector3=d.node.position+axis*side*(FortPlacement.wall_width(d.kind)*.5+.85)
			var near:=end+normal*.85;var far:=end-normal*.85
			var length:float=pos.distance_to(near)+near.distance_to(far)+far.distance_to(goal)
			if length>=score:continue
			if clear(world,pos,near) and clear(world,near,far) and clear(world,far,goal):best=[near,far];score=length
	if not best.is_empty():e.route_points=best;e.route_until=world.clock+4;return (best[0]-pos).normalized()
	e.breach=blocker
	return (world.defenses[blocker].node.position-pos).normalized()
static func strike(world:FortWorld,e:Dictionary,id:int)->void:
	if not world.defenses.has(id):return
	var d:Dictionary=world.defenses[id]
	var reach:=2.3 if not FortPlacement.is_wall(d.kind) else FortPlacement.wall_width(d.kind)*.5+.9
	if e.node.position.distance_to(d.node.position)>reach:return
	if e.kind=="Sapper":world.raiders.arm(e);return
	e.moving=false;e.node.velocity=Vector3.ZERO
	if int(e.get("strike_target",id))!=id:e.strike_at=0.0
	if e.attack<=0:
		e.attack=1.8;e.strike_at=world.clock+(.65 if e.kind=="Brute" else .4);e.strike_target=id
		world.broadcast("recv_fx",[e.node.position+Vector3.UP,Color("#efb384"),"BREACH" if e.kind=="Brute" else "","siege_warning"])
	if float(e.get("strike_at",0))>0 and world.clock>=float(e.strike_at):
		e.strike_at=0
		world._damage_defense(id,42 if e.kind=="Brute" else (28 if e.kind=="Sapper" else 10))
		world.broadcast("recv_fx",[d.node.position+Vector3.UP*.6,Color("#be9b75"),"","hammer"])
