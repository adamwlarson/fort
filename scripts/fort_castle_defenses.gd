class_name FortCastleDefenses
extends RefCounted

static func make(kind:String,collision:bool)->Node3D:
	var painted:=FortArt.staged(kind)
	if painted:
		# Painted model for the look; simple boxes for collision.
		painted.set_meta("castle_skin",true)
		var h:=FortCastle.HEIGHT
		if collision:
			match kind:
				"SentryCannon":FortArt.box_collider(painted,Vector3(1.8,1.6,1.8),Vector3(0,.8,0))
				"CastleGate":
					for x in [-1.75,1.75]:FortArt.box_collider(painted,Vector3(.5,h,.6),Vector3(x,h*.5,0))
					FortArt.box_collider(painted,Vector3(3.4,h-3.55,.6),Vector3(0,(h+3.55)*.5,0))
					FortGates.body(painted,"GateDoor",Vector3(3.4,3.5,.25),Vector3(0,1.75,0))
				"CastleWindow":
					FortArt.box_collider(painted,Vector3(4,1.3,.55),Vector3(0,.65,0))
					FortArt.box_collider(painted,Vector3(4,h-3.1,.55),Vector3(0,(h+3.1)*.5,0))
					for x in [-1.6,1.6]:FortArt.box_collider(painted,Vector3(.8,1.8,.55),Vector3(x,2.2,0))
				_:FortArt.box_collider(painted,Vector3(4,h,.55),Vector3(0,h*.5,0))
		return painted
	var root:=Node3D.new()
	root.set_meta("castle_skin",true)
	if kind=="SentryCannon":
		root.add_child(Visuals.box(Vector3(1.8,.7,1.8),FortArt.STONE,Vector3(0,.35,0)))
		var turret:=Node3D.new();turret.name="Turret";turret.position.y=1.8;root.add_child(turret)
		var barrel:=Visuals.cylinder(.23,2.8,Color("#38454a"));barrel.rotation.x=PI/2;turret.add_child(barrel)
		for x in [-.6,.6]:root.add_child(Visuals.box(Vector3(.25,1.2,.8),FortArt.TRIM,Vector3(x,1.2,0)))
		if collision:FortArt.box_collider(root,Vector3(1.8,1.6,1.8),Vector3(0,.8,0))
		return root
	if kind=="CastleGate":
		for x in [-1.85,1.85]:piece(root,Vector3(.3,FortCastle.HEIGHT,.6),Vector3(x,FortCastle.HEIGHT*.5,0),collision)
		piece(root,Vector3(3.4,FortCastle.HEIGHT-3.55,.6),Vector3(0,(FortCastle.HEIGHT+3.55)*.5,0),collision)
		var door:=Node3D.new();door.name="DoorLeaf";root.add_child(door)
		for x in [-.85,.85]:door.add_child(Visuals.box(Vector3(1.65,3.5,.2),FortArt.WOOD,Vector3(x,1.75,0)))
		for y in [.5,2.9]:door.add_child(Visuals.box(Vector3(3.35,.13,.26),FortArt.TRIM,Vector3(0,y,0)))
		if collision:FortGates.body(root,"GateDoor",Vector3(3.4,3.5,.25),Vector3(0,1.75,0))
	elif kind=="CastleWindow":
		piece(root,Vector3(4,1.3,.55),Vector3(0,.65,0),collision)
		piece(root,Vector3(4,FortCastle.HEIGHT-3.1,.55),Vector3(0,(FortCastle.HEIGHT+3.1)*.5,0),collision)
		for x in [-1.6,1.6]:piece(root,Vector3(.8,1.8,.55),Vector3(x,2.2,0),collision)
	else:piece(root,Vector3(4,FortCastle.HEIGHT,.55),Vector3(0,FortCastle.HEIGHT*.5,0),collision)
	return root
static func piece(root:Node3D,size:Vector3,pos:Vector3,collision:bool)->void:
	root.add_child(Visuals.box(size,FortArt.STONE,pos))
	if collision:FortArt.box_collider(root,size,pos)
	root.add_child(Visuals.box(Vector3(size.x,.08,size.z+.04),FortArt.TRIM,pos+Vector3.UP*(size.y*.5-.05)))
static func tick_cannon(w:FortWorld,d:Dictionary)->void:
	if w.clock<float(d.get("next_shot",0)):return
	var origin:Vector3=d.node.position+Vector3.UP*2.0
	var outward:=Vector3.BACK.rotated(Vector3.UP,d.node.rotation.y)
	var target:=-1;var distance:=38.0
	for id in w.enemies:
		var point:Vector3=w.enemies[id].node.position+Vector3.UP
		var offset:=point-origin
		if offset.length()<distance and offset.normalized().dot(outward)>.65 and FortSiege.clear(w,origin+outward*2,point):target=id;distance=offset.length()
	if target<0:return
	d.next_shot=w.clock+2.5
	var end:Vector3=w.enemies[target].node.position+Vector3.UP
	FortBattlements.aim(d,end-origin)
	w.broadcast("recv_fx",[origin,Color("#ffd28c"),"","shot",end])
	var power:=FortCastleFeatures.room_multiplier(w.castle,d.node.position,["Sentry","Rampart"],.2)*(1.0+.4*(int(d.get("level",1))-1))
	w._damage_enemy(target,100*power,Vector3.ZERO,"tower_damage")
