class_name FortPets
extends RefCounted
const SPECS := [
	{"name":"Pack Badger","asset":"pet_badger","tier":1,"wood":35,"stone":10,"crystal":4,"capacity":8,"speed":6.0},
	{"name":"Copper Mole","asset":"pet_mole","tier":2,"wood":30,"stone":20,"crystal":6,"capacity":10,"speed":5.5},
	{"name":"Grove Sprite","asset":"pet_sprite","tier":3,"wood":20,"crystal":12,"aether":8,"capacity":6,"speed":7.5},
]
const HOME := Vector3(4.6,0,0)
var world:FortWorld
var pets:Dictionary={}
var revision:=0
var next_id:=1
func _init(w:FortWorld)->void:world=w
func at_workshop(id:int)->bool:
	return world.players.has(id) and world.players[id].health>0 and world.players[id].mounted_ballista<0 and world.players[id].position.distance_to(Vector3(-4.6,0,0))<3.2
func recruit(id:int,kind:int,expected:int)->void:
	if not at_workshop(id) or expected!=revision or pets.size()>=3 or kind<0 or kind>=SPECS.size():return
	var spec:Dictionary=SPECS[kind]
	if world.hearth_level<int(spec.tier):return
	for resource in GameData.RESOURCES:
		if int(world.shared.get(resource,0))<int(spec.get(resource,0)):return
	for resource in GameData.RESOURCES:world.shared[resource]-=int(spec.get(resource,0))
	_create(next_id,kind,HOME+Vector3(next_id,0,2));next_id+=1;revision+=1
	world.broadcast("recv_full",[world.full_state()]);world.personal(id,"Recruited "+spec.name+". Choose its resource in Gathering Pets.")
func assign(id:int,pet_id:int,resource:String,expected:int)->void:
	if not at_workshop(id) or not pets.has(pet_id) or expected!=int(pets[pet_id].revision):return
	if resource not in GameData.RESOURCES and resource!="rest":return
	if resource=="iron" and world.hearth_level<2 or resource=="aether" and world.hearth_level<3:return
	var p:Dictionary=pets[pet_id];p.resource=resource;p.revision+=1;revision+=1;p.target=-1;p.mode="RETURN";p.stuck=0
	world.broadcast("recv_full",[world.full_state()])
func release(id:int,pet_id:int,expected:int)->void:
	if not at_workshop(id) or not pets.has(pet_id):return
	var p:Dictionary=pets[pet_id]
	if int(p.revision)!=expected or p.resource!="rest" or p.cargo>0 or p.node.position.distance_to(HOME)>6:return
	p.node.queue_free();pets.erase(pet_id);revision+=1;world.broadcast("recv_full",[world.full_state()])
func _create(id:int,kind:int,pos:Vector3)->void:
	var body:=CharacterBody3D.new();body.name="GatherPet%d"%id;body.position=pos;body.collision_layer=0;body.collision_mask=1;body.floor_snap_length=.5
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=.7;shape.shape=capsule;shape.position.y=.36;body.add_child(shape)
	var model:=FortArt.asset(SPECS[kind].asset);body.add_child(model);world.add_child(body)
	var label:=Visuals.label_3d(SPECS[kind].name,Color("#d6e7b6"),1.4);label.font_size=14;label.visibility_range_end=18;body.add_child(label)
	pets[id]={"node":body,"model":model,"label":label,"kind":kind,"resource":"wood","cargo_kind":"wood","cargo":0,"target":-1,"mode":"RETURN","revision":0,"stuck":0.0,"last":pos,"check_at":0.0,"jump_at":0.0,"work_at":0.0,"skip":{},"net_pos":pos,"net_yaw":0.0}
func state()->Dictionary:
	var list:Array=[]
	for id in pets:
		var p:Dictionary=pets[id]
		list.append({"id":id,"kind":p.kind,"resource":p.resource,"cargo_kind":p.cargo_kind,"cargo":p.cargo,"mode":p.mode,"revision":p.revision,"pos":p.node.position,"yaw":p.node.rotation.y})
	return {"revision":revision,"list":list}
func receive(data:Dictionary)->void:
	if data.is_empty():return
	if int(data.revision)<revision:return
	revision=int(data.revision)
	var live:Array=[]
	for item in data.list:live.append(int(item.id))
	for id in pets.keys():
		if id not in live:pets[id].node.queue_free();pets.erase(id)
	for item in data.list:
		var id:int=item.id
		if not pets.has(id):_create(id,item.kind,item.pos)
		var p:Dictionary=pets[id]
		if int(item.revision)<int(p.revision):continue
		for key in ["resource","cargo_kind","cargo","mode","revision"]:p[key]=item[key]
		p.net_pos=item.pos;p.net_yaw=item.yaw
func pick_target(p:Dictionary)->int:
	var target:=-1;var score:=INF
	for id in world.resource_nodes:
		var r:Dictionary=world.resource_nodes[id]
		if r.kind!=p.resource or r.amount<=0 or world.clock<float(p.skip.get(id,0)):continue
		if not FortForestry.pet_can_harvest(r,world.hearth_level,world.frontier_radius()):continue
		var cost:float=p.node.position.distance_to(r.node.position)
		for other in pets.values():
			if other!=p and other.target==id:cost+=25
		if cost<score:target=id;score=cost
	return target
func tick(delta:float)->void:
	for p in pets.values():
		var body:CharacterBody3D=p.node;var spec:Dictionary=SPECS[p.kind]
		if not world.multiplayer.is_server():
			body.position=body.position.lerp(p.net_pos,1-exp(-12*delta));body.rotation.y=lerp_angle(body.rotation.y,p.net_yaw,1-exp(-12*delta))
		else:
			if world.is_night or p.resource=="rest":p.mode="RETURN"
			if p.mode=="IDLE" and not world.is_night and p.resource!="rest":p.mode="SEEK"
			if p.mode=="SEEK":
				p.target=pick_target(p)
				p.mode="GATHER" if p.target>=0 else "RETURN"
			var goal:Vector3=HOME+Vector3(int(p.kind)-1,0,2)
			if p.mode=="GATHER":
				if not world.resource_nodes.has(p.target) or world.resource_nodes[p.target].amount<=0:p.mode="SEEK";continue
				var r:Dictionary=world.resource_nodes[p.target];goal=r.node.position
				if body.position.distance_to(goal)<2.5 and FortSiege.clear(world,body.position,goal+(body.position-goal).normalized()*.7):
					body.velocity=Vector3.ZERO
					if world.clock>=float(p.work_at):
						p.work_at=world.clock+1.5
						var amount:=mini(int(r.amount),mini(int(spec.capacity)-int(p.cargo),2*world.expedition.gather_multiplier()))
						p.cargo_kind=r.kind;p.cargo+=amount;r.respawn=65
						world.broadcast("recv_resource",[p.target,int(r.amount)-amount,true])
						world.broadcast("recv_fx",[goal+Vector3.UP,GameData.resource_color(r.kind),"","hit"])
						world.broadcast("recv_gain",[-1,goal+Vector3.UP,r.kind,amount,"PET CARGO"])
						if p.cargo>=int(spec.capacity) or r.amount<=0:p.mode="RETURN"
					continue
			if p.mode=="RETURN" and body.position.distance_to(goal)<2.4:
				if p.cargo>0:
					world.shared[p.cargo_kind]+=int(p.cargo)
					if p.cargo_kind=="crystal":world.lifetime_crystal+=int(p.cargo);world.workshop_level=3 if world.lifetime_crystal>=20 else (2 if world.lifetime_crystal>=8 else 1)
					world.director.record("pet_deliveries",p.cargo);p.cargo=0
				p.mode="IDLE" if world.is_night or p.resource=="rest" else "SEEK";body.velocity=Vector3.ZERO
				if p.mode=="SEEK" and pick_target(p)<0:p.mode="IDLE";p.work_at=world.clock+3
				continue
			if p.mode=="IDLE":continue
			var offset:Vector3=goal-body.position;offset.y=0;var direction:=offset.normalized()
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(body.position+Vector3.UP*.5,body.position+Vector3.UP*.5+direction*1.6,1))
			if not hit.is_empty():
				# Grounded companions hop low walls; steering handles trunks and tall obstacles.
				if body.is_on_floor() and world.clock>=float(p.jump_at):body.velocity.y=12;p.jump_at=world.clock+1.4
				direction=world._steer_around_scenery(body,direction,body.get_instance_id(),p)
			body.velocity.x=direction.x*spec.speed;body.velocity.z=direction.z*spec.speed;body.velocity.y-=24*delta;body.move_and_slide()
			body.rotation.y=lerp_angle(body.rotation.y,atan2(offset.x,offset.z),delta*8)
			if world.clock>=float(p.check_at):
				p.check_at=world.clock+1
				p.stuck=float(p.stuck)+1 if body.position.distance_to(p.last)<.6 else maxf(0,float(p.stuck)-.5);p.last=body.position
				if p.stuck>=6 or body.position.y< -5:
					# Visible magical recall is the final escape for sealed construction or bad terrain.
					if p.target>=0:p.skip[p.target]=world.clock+30
					world.broadcast("recv_fx",[body.position,Color("#b8e8d1"),"RECALL","ability"])
					body.position=HOME+Vector3(0,1,3);body.velocity=Vector3.ZERO;p.mode="RETURN";p.target=-1;p.stuck=0
		p.label.text="%s / %s\n%d %s / %s"%[spec.name,str(p.resource).to_upper(),p.cargo,p.cargo_kind,p.mode]
		p.model.position.y=absf(sin(world.clock*9+int(p.kind)))*(.10 if p.mode in ["RETURN","GATHER"] else .025)
		FortArt.animate_enemy(p.model,world.clock,false,p.mode in ["RETURN","GATHER"])
