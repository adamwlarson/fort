class_name FortCastleArt
extends RefCounted
static var paving:ShaderMaterial

static func slab(root:Node3D,size:Vector3,pos:Vector3)->void:
	if not paving:paving=ShaderMaterial.new();paving.shader=preload("res://assets/shaders/castle_stone.gdshader")
	var stone:=Visuals.box(size,Color("#68727b"),pos);stone.material_override=paving;root.add_child(stone)
	FortArt.box_collider(root,size,pos)
static func model(root:Node3D,key:String,pos:Vector3,scale:=Vector3.ONE)->Node3D:
	var node:=FortArt.asset(key)
	if not node:node=Node3D.new()
	root.add_child(node);node.position=pos;node.scale=scale;return node
static func ramp(root:Node3D,width:float,length:float,height:float,pos:Vector3,yaw:=0.0)->void:
	var node:=Node3D.new();root.add_child(node);node.position=pos;node.rotation.y=yaw
	var points:=PackedVector3Array([Vector3(-width/2,0,-length/2),Vector3(width/2,0,-length/2),Vector3(-width/2,0,length/2),Vector3(width/2,0,length/2),Vector3(-width/2,height,length/2),Vector3(width/2,height,length/2)])
	var shape:=ConvexPolygonShape3D.new();shape.points=points;Visuals.add_static_collision(node,shape)
	var steps:=maxi(3,ceili(height/.2))
	for i in steps:
		var h:=height*(i+1)/steps
		node.add_child(Visuals.box(Vector3(width,h,length/steps+.02),FortArt.STONE.lightened(.06*(i%2)),Vector3(0,h/2,-length/2+length*(i+.5)/steps)))
static func foundation(root:Node3D,r:Dictionary,castle:FortCastle)->void:
	var hole:bool=r.floor>0 and castle.rooms.get(FortCastle.key(r.x,r.z,r.floor-1),{}).get("kind","")=="Stairs"
	if hole:
		var side:=1.0 if int(r.floor)%2==1 else -1.0
		slab(root,Vector3(14,.4,20),Vector3(-3*side,-.2,0))
		slab(root,Vector3(2,.4,20),Vector3(9*side,-.2,0))
		slab(root,Vector3(4,.4,6),Vector3(6*side,-.2,-7))
		slab(root,Vector3(4,.4,5.4),Vector3(6*side,-.2,7.3))
	else:slab(root,Vector3(20,.4,20),Vector3(0,-.2,0))
	for x in [-9.5,9.5]:
		for z in [-9.5,9.5]:model(root,"castle_pier",Vector3(x,0,z))
	for side in 4:
		var rim:=Visuals.box(Vector3(20,.13,.08),FortArt.TRIM,Vector3(0,-.08,9.93).rotated(Vector3.UP,side*PI/2));rim.rotation.y=side*PI/2;root.add_child(rim)
	if r.floor==0:
		for side in 4:
			var offset:=Vector3(0,-FortCastle.BASE,-11).rotated(Vector3.UP,side*PI/2)
			ramp(root,6,2,FortCastle.BASE,offset,side*PI/2)
	else:
		for x in [-9.4,9.4]:
			for z in [-9.4,9.4]:model(root,"castle_pier",Vector3(x,-4,z),Vector3(1,2.5,1))
static func make_keep(parent:Node3D)->void:
	var fort:=Node3D.new();fort.name="Hearthhold";parent.add_child(fort);fort.position.y=FortCastle.BASE
	for key in ["stockpile","workshop"]:
		var pos:=Vector3(4.6 if key=="stockpile" else -4.6,0,0)
		var obj:=model(fort,key,pos);obj.name=key.capitalize()
		FortArt.box_collider(obj,Vector3(2.3,1.1,1.3),Vector3(0,.55,0))
		var label:=Visuals.label_3d("STOCKPILE / HOLD E" if key=="stockpile" else "WORKSHOP / E",Color("#edca89"),3.2)
		label.font_size=28;label.pixel_size=.006;obj.add_child(label)
	fort.add_child(FortCampfire.new());FortArt.box_collider(fort,Vector3(2.7,.65,2.7),Vector3(0,.3,0))
static func room(castle:FortCastle,r:Dictionary)->Node3D:
	var root:=Node3D.new();root.position=FortCastle.position(r)
	if r.complete:
		foundation(root,r,castle)
		if r.kind=="Stairs":
			var stair_x:=6.0 if int(r.floor)%2==0 else -6.0
			ramp(root,3.8,8,4,Vector3(stair_x,0,0))
			for x in [stair_x-2.1,stair_x+2.1]:FortArt.beam(root,Vector3(x,1,-4),Vector3(x,5,4),.12,FortArt.TRIM)
		if r.kind=="Merchant":model(root,"castle_merchant",Vector3(0,0,4))
		if r.kind=="Gatherers":model(root,"castle_lodge",Vector3(0,0,4))
		if r.kind=="Research":model(root,"castle_research",Vector3(0,0,4))
		if r.kind in ["Merchant","Gatherers","Research"]:
			var npc:=model(root,"dwarf_engineer" if r.kind=="Merchant" else ("dwarf_ranger" if r.kind=="Gatherers" else "dwarf_warden"),Vector3(1,0,4),Vector3.ONE*.9)
			var gear:=FortEquipment.prepare(npc);gear.axe.hide()
			var animation:=FortPlayer.find_animation(npc)
			if animation:animation.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR;animation.play("Idle")
			FortArt.box_collider(root,Vector3(1.5,1.5,1.5),Vector3(0,.75,4))
	if r.task!="":
		for x in [-9.5,9.5]:
			for z in [-9.5,9.5]:
				FortArt.beam(root,Vector3(x,0,z),Vector3(x,2.5,z),.16,FortArt.WOOD)
		for side in 4:
			var edge:=Node3D.new();root.add_child(edge);edge.rotation.y=side*PI/2
			FortArt.beam(edge,Vector3(-9.5,1,9.5),Vector3(9.5,1,9.5),.08,FortArt.TRIM)
		if r.work>0:
			for i in mini(10,int(r.work/3)+1):root.add_child(Visuals.box(Vector3(1.2,.4,.8),FortArt.STONE,Vector3(-5+i%4*1.4,.2+(i/4)*.4,4)))
	var sign:=model(root,"castle_sign",r.sign-root.position);sign.name="ProjectSign"
	var label:=Visuals.label_3d("",Color("#ecd29b"),2.2);label.name="Caption";label.font_size=25;label.pixel_size=.006;label.visibility_range_end=26;sign.add_child(label)
	var meter:=Node3D.new();meter.name="WorkMeter";meter.position=Vector3(0,1.75,0);sign.add_child(meter)
	meter.add_child(Visuals.box(Vector3(1.8,.1,.1),Color("#293b40")))
	var fill:=Visuals.box(Vector3(1.8,.1,.12),Color("#75d5b1"));fill.name="Fill";meter.add_child(fill)
	return root
static func update_sign(root:Node3D,r:Dictionary,castle:FortCastle)->void:
	var sign:=root.get_node("ProjectSign") as Node3D;sign.position=r.sign-root.position
	var label:=sign.get_node("Caption") as Label3D
	label.text="CASTLE ARCHITECT / K" if r.kind=="Keep" else str(FortCastle.TYPES[r.kind].name).to_upper()+" / K"
	var meter:=sign.get_node("WorkMeter") as Node3D;meter.visible=r.task!=""
	if r.task!="":
		var needed:=0;var total:=0
		for amount in castle.cost(r).values():total+=int(amount)
		for amount in castle.remaining(r).values():needed+=int(amount)
		var fraction:=float(total-needed)/maxi(1,total) if needed>0 else float(r.work)/maxf(1,r.total)
		var fill:=meter.get_node("Fill") as MeshInstance3D;fill.scale.x=maxf(.001,fraction);fill.position.x=-.9*(1-fraction)
		label.text+="\n%s / %s"%[str(r.task).to_upper(),"SUPPLIES %d / %d"%[total-needed,total] if needed>0 else "WORK %d%%"%int(100*fraction)]
		label.text+="\nNEED: "+GameData.supplies_text(castle.remaining(r),true) if needed>0 else "\nHOLD E / WORK · K / DETAILS"
