class_name FortAim
extends RefCounted

static func origin(world:FortWorld,p:FortPlayer)->Vector3:
	if world.defenses.has(p.mounted_ballista):return world.defenses[p.mounted_ballista].node.position+Vector3.UP*1.4
	return p.position+Vector3.UP*1.05

static func solution(world:FortWorld,p:FortPlayer,direction:Vector3,ballista:=false,weapon_kind:="")->Dictionary:
	var start:=origin(world,p)
	var kind:=weapon_kind if not weapon_kind.is_empty() else (p.weapon if GameData.ranged(p.weapon) else "Crossbow")
	var reach:float=GameData.defense_radius("Ballista",int(world.defenses[p.mounted_ballista].get("level",1))) if ballista and world.defenses.has(p.mounted_ballista) else float(GameData.WEAPONS[kind].range)
	var end:=start+direction.normalized()*reach
	var space:=world.get_world_3d().direct_space_state
	var direct:=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,5))
	if not direct.is_empty():
		var collider:Node=direct.collider
		if collider.has_meta("enemy_id"):
			return {"origin":start,"point":direct.position,"enemy":int(collider.get_meta("enemy_id")),"blocked":false}
	var best:=-1;var nearest:=reach
	for id in world.enemies:
		var point:Vector3=world.enemies[id].node.position+Vector3.UP*(1.6 if world.enemies[id].kind=="Chieftain" else .85)
		var offset:=point-start
		if offset.length()<nearest and direction.normalized().dot(offset.normalized())>(0.985 if ballista else 0.992):
			best=id;nearest=offset.length();end=point
	var query:=PhysicsRayQueryParameters3D.create(start,end,1)
	var obstacle:=world.get_world_3d().direct_space_state.intersect_ray(query)
	if not obstacle.is_empty():end=obstacle.position;best=-1
	return {"origin":start,"point":end,"enemy":best,"blocked":not obstacle.is_empty()}

static func camera_direction(world:FortWorld,p:FortPlayer)->Vector3:
	var center:=p.get_viewport().get_visible_rect().size/2
	var start:=p.camera.project_ray_origin(center)
	var end:=start+p.camera.project_ray_normal(center)*300
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,5))
	if not hit.is_empty():end=hit.position
	return (end-origin(world,p)).normalized()
