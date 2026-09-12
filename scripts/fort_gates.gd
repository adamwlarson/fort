class_name FortGates
extends RefCounted

# The server owns requests, movement and obstruction decisions. Clients only pose
# the replicated mechanism. Collision is enabled only after a safe, complete close.
var world:FortWorld
func _init(w:FortWorld)->void:world=w
static func state(d:Dictionary)->Dictionary:
	if d.kind!="Gatehouse":return {}
	var result:Dictionary={}
	for key in ["gate_open","gate_target","gate_auto","gate_revision","gate_sequence","gate_blocked","gate_wave"]:
		result[key]=d.get(key,1.0 if key in ["gate_open","gate_target"] else (false if key in ["gate_auto","gate_blocked"] else 0))
	return result
static func body(root:Node3D,name:String,size:Vector3,pos:Vector3)->StaticBody3D:
	var shape:=BoxShape3D.new();shape.size=size
	var b:=Visuals.add_static_collision(root,shape,pos);b.name=name;return b
static func make(collision:bool)->Node3D:
	var root:=Node3D.new();var model:=FortArt.asset("gatehouse");root.add_child(model);model.name="GateArt"
	var parts:Dictionary={}
	for name in ["Portcullis","Winch","WeightL","WeightR"]:parts[name]=model.find_child(name,true,false)
	for i in range(2,GameData.MAX_GEAR_LEVEL+1):
		var trim:=model.find_child("Upgrade_%02d"%i,true,false)
		if trim:trim.visible=false;parts["tier%d"%i]=trim
	root.set_meta("gate_parts",parts)
	if collision:
		for side in [-1,1]:
			for face in [-1,1]:
				var lamp:=OmniLight3D.new();lamp.name="GateLantern";lamp.position=Vector3(side*2.34,1.55,face*1.65);lamp.light_color=Color("#ffc980");lamp.light_energy=.5;lamp.omni_range=3.4;lamp.shadow_enabled=false;root.add_child(lamp)
		for side in [-1,1]:
			body(root,"PierL" if side<0 else "PierR",Vector3(.9,5.65,2.65),Vector3(side*2.34,2.825,0))
			body(root,"ArchShoulderL" if side<0 else "ArchShoulderR",Vector3(.55,.9,2.36),Vector3(side*1.7,3.3,0))
		body(root,"Crown",Vector3(3.9,1.9,2.65),Vector3(0,4.6,0))
		var door:=body(root,"GateDoor",Vector3(3.86,3.3,.44),Vector3(0,1.65,0));door.collision_layer=0;door.collision_mask=0
	pose({"kind":"Gatehouse","node":root,"gate_open":1.0,"level":1})
	return root
static func pose(d:Dictionary)->void:
	if d.kind!="Gatehouse":return
	var parts:Dictionary=d.node.get_meta("gate_parts",{})
	var amount:=clampf(float(d.get("gate_open",1)),0,1)
	if is_instance_valid(parts.get("Portcullis")):parts.Portcullis.position.y=amount*3.15
	if is_instance_valid(parts.get("Winch")):parts.Winch.rotation.x=amount*2.8
	for name in ["WeightL","WeightR"]:
		if is_instance_valid(parts.get(name)):parts[name].position.y=3.4-amount*1.8
	for i in range(2,GameData.MAX_GEAR_LEVEL+1):
		if is_instance_valid(parts.get("tier%d"%i)):parts["tier%d"%i].visible=int(d.get("level",1))>=i
	var door:StaticBody3D=d.node.get_node_or_null("GateDoor")
	if door:
		var solid:=not FortConstruction.foundation(d) and amount<=.001 and float(d.get("gate_target",1))<=0
		door.collision_layer=1 if solid else 0;door.collision_mask=door.collision_layer
static func passable(d:Dictionary)->bool:
	return d.kind=="Gatehouse" and (FortConstruction.foundation(d) or float(d.get("gate_open",1))>.001 or float(d.get("gate_target",1))>0)
static func title(d:Dictionary)->String:
	if d.get("gate_blocked",false):return "PASSAGE OCCUPIED / reopened safely"
	var a:=float(d.get("gate_open",1));var t:=float(d.get("gate_target",1))
	if not is_equal_approx(a,t):return "OPENING" if t>0 else "CLOSING"
	return "OPEN" if t>0 else "CLOSED"
func actors()->Array:
	var result:Array=world.players.values()
	for e in world.enemies.values():result.append(e.node)
	for pet in world.pets.pets.values():result.append(pet.node)
	return result
static func local_point(pos:Vector3,origin:Vector3,yaw:float)->Vector3:return (pos-origin).rotated(Vector3.UP,-yaw)
func occupied(d:Dictionary,frame:=false)->bool:
	for actor in actors():
		if not is_instance_valid(actor):continue
		var p:=local_point(actor.position,d.node.position,d.node.rotation.y)
		if p.y< -2 or p.y>6.4:continue
		if frame:
			if absf(p.x)<3.25 and absf(p.z)<1.95 and (absf(p.x)>1.4 or p.y>1.9):return true
		elif p.y<3.5 and absf(p.x)<2.1 and absf(p.z)<1.65:return true
	return false
func request(player_id:int,id:int,revision:int,auto_value:Variant=null)->void:
	if not world.multiplayer.is_server() or not world.players.has(player_id) or not world.defenses.has(id):return
	var d:Dictionary=world.defenses[id];var p:FortPlayer=world.players[player_id]
	if d.kind!="Gatehouse" or FortConstruction.pending(d) or d.hp<=0 or p.health<=0 or p.mounted_ballista>=0 or p.position.distance_to(d.node.position)>4:return
	if revision!=int(d.get("gate_revision",0)) or not world._allow(player_id,"gate",.4):return
	if auto_value!=null:
		if not auto_value is bool:return
		d.gate_auto=auto_value;d.gate_revision=int(d.get("gate_revision",0))+1
		# Enabling during a night starts next dusk; it never surprises the operator.
		d.gate_wave=world.wave
	else:
		var close:=float(d.get("gate_target",1))>0
		if close and occupied(d):
			d.gate_blocked=true;d.gate_sequence=int(d.get("gate_sequence",0))+1;world.personal(player_id,"Passage occupied. Move clear before closing the gate.");return
		d.gate_target=0.0 if close else 1.0;d.gate_blocked=false;d.gate_revision=int(d.get("gate_revision",0))+1
		world.navigation_revision+=1
	d.gate_sequence=int(d.get("gate_sequence",0))+1
	world.broadcast("recv_full",[world.full_state()])
func tick(delta:float)->void:
	for d in world.defenses.values():
		if d.kind!="Gatehouse":continue
		var old_amount:=float(d.get("gate_open",1))
		var before:=state(d)
		if world.multiplayer.is_server() and not world.ended and not FortConstruction.foundation(d):
			if d.get("gate_auto",false) and world.is_night and int(d.get("gate_wave",0))<world.wave:
				d.gate_wave=world.wave;d.gate_target=0.0;d.gate_blocked=false;d.gate_revision=int(d.get("gate_revision",0))+1
			var was:=passable(d)
			if float(d.get("gate_target",1))<=0 and float(d.get("gate_open",1))>0 and occupied(d):
				d.gate_target=1.0;d.gate_blocked=true;d.gate_revision=int(d.get("gate_revision",0))+1
			d.gate_open=move_toward(float(d.get("gate_open",1)),float(d.get("gate_target",1)),delta*.48)
			if was!=passable(d):world.navigation_revision+=1
			if state(d)!=before:d.gate_sequence=int(d.get("gate_sequence",0))+1
		# Predict only the visual fraction between snapshots. The server still
		# decides occupancy, target and revision; never predict a completed close.
		elif not world.multiplayer.is_server() and not FortConstruction.foundation(d):
			var target:=float(d.get("gate_target",1))
			if target>0:d.gate_open=move_toward(old_amount,target,delta*.48)
			elif old_amount>.001:d.gate_open=maxf(.002,move_toward(old_amount,target,delta*.48))
		pose(d)
		var was_moving:bool=d.node.get_meta("gate_moving",false)
		var moving:=absf(float(d.get("gate_open",1))-float(d.get("gate_target",1)))>.002 and not FortConstruction.foundation(d)
		var p:=world.local_player()
		if moving!=was_moving and p and p.position.distance_to(d.node.position)<28:
			world.sound.play("gate_move" if moving else "gate_stop",-10-p.position.distance_to(d.node.position)*.6)
		d.node.set_meta("gate_moving",moving)
		for lamp in d.node.get_children():
			if lamp is OmniLight3D:lamp.light_energy=.75 if world.is_night else .12
func nearest(pos:Vector3)->int:return world._nearest_defense(pos,"Gatehouse",4)
func interact(id:int,held:bool,expected_gate:int,expected_revision:int)->bool:
	var gate:=nearest(world.players[id].position)
	if gate<0 or FortConstruction.pending(world.defenses[gate]):return false
	if not held and gate==expected_gate:request(id,gate,expected_revision)
	return true
static func placement_reason(w:FortWorld,pos:Vector3,yaw:float)->String:
	# Check the entire tall frame, including upper rooms and low terrain ceilings.
	for r in w.castle.rooms.values():
		var center:=FortCastle.position(r)
		if center.y>pos.y+.3 and center.y<pos.y+6.5 and absf(pos.x-center.x)<13 and absf(pos.z-center.z)<13:return "Gatehouse needs 6.5m headroom; an upper room is above it"
	for r in w.resource_nodes.values():
		var p:=local_point(r.node.position,pos,yaw)
		if r.amount>0 and absf(p.y)<6.5 and absf(p.x)<3.7 and absf(p.z)<2.7:return "Clear resources from the full gatehouse footprint"
	for actor in w.gates.actors():
		var p:=local_point(actor.position,pos,yaw)
		if p.y> -1.8 and p.y<6.4 and absf(p.x)<3.25 and absf(p.z)<1.95:return "Move dwarves, pets and enemies clear of the gatehouse footprint"
	var shape:=BoxShape3D.new();shape.size=Vector3(5.5,6.3,2.6)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,yaw),pos+Vector3.UP*3.25);query.collision_mask=1;query.margin=0
	if not w.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return "Gatehouse frame needs clear ground and overhead space"
	return ""
