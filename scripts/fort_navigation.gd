class_name FortNavigation
extends RefCounted

# Local, body-width routes. Physics remains authoritative; this does not teleport actors.
const CELL:=1.25
const LIMIT:=144
static func width(body:CharacterBody3D)->float:
	var shape:=body.get_child(0) as CollisionShape3D
	return float(shape.shape.radius)+.12 if shape and shape.shape is CapsuleShape3D else .55
static func clear(w:FortWorld,a:Vector3,b:Vector3,radius:=.5)->bool:
	var offset:=b-a;offset.y=0
	var side:=Vector3(-offset.z,0,offset.x).normalized()*radius
	var space:=w.get_world_3d().direct_space_state
	for shift in [Vector3.ZERO,side,-side]:
		var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(a+shift+Vector3.UP*.65,b+shift+Vector3.UP*.65,1))
		if not hit.is_empty() and hit.normal.y<.7:return false
	return true
static func floor_point(w:FortWorld,anchor:Vector3,body:CharacterBody3D)->Vector3:
	var hit:=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(anchor+Vector3.UP*.85,anchor-Vector3.UP*1.5,1))
	if hit.is_empty() or hit.normal.y<cos(body.floor_max_angle):return Vector3.INF
	var result:Vector3=hit.position+Vector3.UP*.04
	# Reject destinations inside geometry, and ceilings too low for this actor.
	var shape:=body.get_child(0) as CollisionShape3D
	if shape:
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape.shape;query.transform=Transform3D(body.global_basis,result)*shape.transform;query.collision_mask=1;query.exclude=[body.get_rid()];query.margin=0
		if not w.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return Vector3.INF
	return result
static func budget(w:FortWorld)->bool:
	var frame:=Engine.get_physics_frames()
	if int(w.get_meta("nav_frame",-1))!=frame:w.set_meta("nav_frame",frame);w.set_meta("nav_searches",0)
	var count:=int(w.get_meta("nav_searches",0))
	if count>=2:return false
	w.set_meta("nav_searches",count+1);return true
static func path(w:FortWorld,body:CharacterBody3D,goal:Vector3)->Array:
	var start:=body.position;var radius:=width(body)
	var open:Array[Vector2i]=[Vector2i.ZERO];var points:={Vector2i.ZERO:start};var cost:={Vector2i.ZERO:0.0};var parents:Dictionary={};var closed:Dictionary={}
	var best:=Vector2i.ZERO;var distance:=start.distance_to(goal)
	for iteration in LIMIT:
		if open.is_empty():break
		var pick:=0;var score:=INF
		for i in open.size():
			var candidate:float=cost[open[i]]+points[open[i]].distance_to(goal)
			if candidate<score:score=candidate;pick=i
		var cell:Vector2i=open.pop_at(pick);var pos:Vector3=points[cell];closed[cell]=true
		if pos.distance_to(goal)<distance:best=cell;distance=pos.distance_to(goal)
		if pos.distance_to(goal)<2 or (cell!=Vector2i.ZERO and clear(w,pos,goal,radius)):best=cell;break
		for step in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var next:Vector2i=cell+step
			if closed.has(next) or absi(next.x)>10 or absi(next.y)>10:continue
			var target:=floor_point(w,Vector3(start.x+next.x*CELL,pos.y,start.z+next.y*CELL),body)
			if not target.is_finite() or not clear(w,pos,target,radius):continue
			var travel:float=cost[cell]+pos.distance_to(target)
			if travel>=float(cost.get(next,INF)):continue
			cost[next]=travel;points[next]=target;parents[next]=cell
			if next not in open:open.append(next)
	var result:Array=[]
	while best!=Vector2i.ZERO and parents.has(best):result.push_front(points[best]);best=parents[best]
	return result
static func direction(w:FortWorld,body:CharacterBody3D,state:Dictionary,goal:Vector3)->Vector3:
	var pos:=body.position;var radius:=width(body)
	var changed:bool=int(state.get("nav_revision",-1))!=w.navigation_revision or state.get("nav_goal",goal).distance_to(goal)>2
	if changed:state.nav_points=[];state.nav_until=0.0
	var route:Array=state.get("nav_points",[])
	while not route.is_empty() and Vector2(pos.x-route[0].x,pos.z-route[0].z).length()<.45:route.pop_front()
	if not route.is_empty() and w.clock<float(state.get("nav_until",0)):
		if clear(w,pos,route[0],radius):return (route[0]-pos).normalized()
		state.nav_points=[];state.nav_until=0.0
	if clear(w,pos,goal,radius):return (goal-pos).normalized()
	if w.clock>=float(state.get("nav_until",0)) and budget(w):
		state.nav_points=path(w,body,goal);state.nav_until=w.clock+2.5;state.nav_goal=goal;state.nav_revision=w.navigation_revision
		if not state.nav_points.is_empty():return (state.nav_points[0]-pos).normalized()
	return w._steer_around_scenery(body,(goal-pos).normalized(),body.get_instance_id(),state)
static func safe_home(w:FortWorld,body:CharacterBody3D)->Vector3:
	for radius in [2.0,3.0,4.0,6.0,8.0,12.0]:
		for i in 16:
			var point:=floor_point(w,Vector3(4.6+sin(i*TAU/16)*radius,FortCastle.BASE+.1,cos(i*TAU/16)*radius),body)
			if point.is_finite():return point
	return Vector3.INF
