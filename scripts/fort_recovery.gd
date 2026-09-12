class_name FortRecovery
extends RefCounted

static func capsule(radius:float,height:float)->CapsuleShape3D:
	var shape:=CapsuleShape3D.new();shape.radius=radius;shape.height=height;return shape

static func occupied(w:FortWorld,p:FortPlayer,pos:Vector3,tight:=false)->bool:
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule(.27 if tight else .36,1.35 if tight else 1.5)
	query.transform=Transform3D(Basis.IDENTITY,pos+Vector3.UP*.77)
	query.collision_mask=1 if tight else 7;query.exclude=[p.get_rid()];query.margin=0
	return not w.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

static func landing(w:FortWorld,p:FortPlayer,anchor:Vector3)->Vector3:
	if Vector2(anchor.x,anchor.z).length()>w.frontier_radius()-.8:return Vector3.INF
	var space:=w.get_world_3d().direct_space_state
	var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(anchor+Vector3.UP*.8,anchor-Vector3.UP*3,1))
	if hit.is_empty() or hit.normal.dot(Vector3.UP)<cos(p.floor_max_angle):return Vector3.INF
	var result:Vector3=hit.position+Vector3.UP*.06
	if occupied(w,p,result):return Vector3.INF
	# Reject tiny posts, cliff edges and narrow ledges that cannot support a dwarf.
	for offset in [Vector3(.27,0,0),Vector3(-.27,0,0),Vector3(0,0,.27),Vector3(0,0,-.27)]:
		var probe:=space.intersect_ray(PhysicsRayQueryParameters3D.create(result+offset+Vector3.UP*.2,result+offset-Vector3.UP*.45,1))
		if probe.is_empty() or probe.normal.dot(Vector3.UP)<cos(p.floor_max_angle):return Vector3.INF
	return result

static func destination(w:FortWorld,p:FortPlayer)->Vector3:
	# Prefer nearby ground on this storey; never assume the old fixed spawn is free.
	for radius in [1.5,2.5,4.0,6.0,8.0]:
		for i in 16:
			var point:Vector3=p.position+Vector3(sin(i*TAU/16),0,cos(i*TAU/16))*radius
			var safe:=landing(w,p,point)
			if safe.is_finite():return safe
	for radius in [4.5,7.0,10.0,14.0,18.0]:
		for i in 24:
			var point:=Vector3(sin(i*TAU/24)*radius,FortCastle.BASE+.1,cos(i*TAU/24)*radius)
			var safe:=landing(w,p,point)
			if safe.is_finite():return safe
	return Vector3.INF

static func request(w:FortWorld,id:int,automatic:=false,fallen:=false)->void:
	if not w.multiplayer.is_server() or w.ended or not w.players.has(id):return
	var p:FortPlayer=w.players[id]
	if fallen and p.position.y>= -5:return
	if automatic and not occupied(w,p,p.position,true):return
	var action:="fall_recovery" if fallen else "unstuck"
	if not w._allow(id,action,2 if fallen else 15):
		if not automatic:w.personal(id,"Recovery is cooling down. Try again in a few seconds.")
		return
	var safe:=destination(w,p)
	if not safe.is_finite():
		w.cooldowns.erase("%d/%s"%[id,action])
		w.personal(id,"No clear landing found. Ask a teammate to clear space near the hearth, then try again.")
		return
	if p.mounted_ballista>=0:w._mount(id,-1)
	w.broadcast("recv_teleport",[id,safe,false])
	w.personal(id,"Moved to clear ground. Your health, equipment and pack are unchanged.")

static func step_up(p:CharacterBody3D,motion:Vector3)->void:
	# Short, swept steps clear low rock lips/crates without passing through walls.
	if not p.is_on_floor() or p.velocity.y>0 or motion.length_squared()<.00001:return
	if not p.test_move(p.global_transform,motion):return
	var raised:=p.global_transform
	if p.test_move(raised,Vector3.UP*.3):return
	raised.origin.y+=.3
	if p.test_move(raised,motion):return
	raised.origin+=motion
	var collision:=KinematicCollision3D.new()
	if not p.test_move(raised,Vector3.DOWN*.34,collision):return
	if collision.get_normal().dot(Vector3.UP)<cos(p.floor_max_angle):return
	var height:=.3+collision.get_travel().y
	if height>.02 and height<=.3:p.position.y+=height+.005
