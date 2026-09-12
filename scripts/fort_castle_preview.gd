class_name FortCastlePreview
extends RefCounted
static func shape(root:Node3D,size:Vector3,pos:Vector3,color:Color)->void:
	var box:=Visuals.box(size,color,pos)
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.no_depth_test=true;box.material_override=mat;box.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(box)
static func make(_c:FortCastle,r:Dictionary,kind:String,valid:bool)->Node3D:
	var root:=Node3D.new();root.position=FortCastle.position(r)
	var color:=Color("#72dfb8") if valid else Color("#ec8069")
	shape(root,Vector3(20,.08,20),Vector3(0,.1,0),Color(color,.13))
	for side in 4:
		var edge:=Node3D.new();root.add_child(edge);edge.rotation.y=side*PI/2
		for x in [-6.0,6.0]:shape(edge,Vector3(8,.13,.18),Vector3(x,.18,10),color)
		shape(edge,Vector3(3.8,.05,4),Vector3(0,.22,10),Color("#f2cf79",.45))
		var label:=Visuals.label_3d("ENTRY",Color("#f2cf79"),.45);label.position.z=10;label.font_size=20;label.pixel_size=.025;label.visibility_range_end=150;edge.add_child(label)
	if kind=="Stairs":
		var x:=6.0 if int(r.floor)%2==0 else -6.0
		for i in 12:shape(root,Vector3(3.8,(i+1)/3.0,.65),Vector3(x,(i+1)/6.0,-4+(i+.5)*8/12.0),Color(color,.45))
		shape(root,Vector3(5,.08,12),Vector3(x,.2,0),Color("#f2cf79",.25))
		var up:=Visuals.label_3d("STAIRS UP",Color("#f2cf79"),5);up.position.x=x;up.font_size=24;up.pixel_size=.025;up.visibility_range_end=150;root.add_child(up)
	elif kind in ["Merchant","Gatherers","Research"]:
		shape(root,Vector3(4,3,4),Vector3(0,1.5,4),Color(color,.22))
	elif kind=="Rampart":shape(root,Vector3(3,4,3),Vector3(5,2,5),Color(color,.3))
	if int(r.floor)>0:
		for x in [-9,9]:
			for z in [-9,9]:shape(root,Vector3(.25,4,.25),Vector3(x,-2,z),Color(color,.45))
	var heading:=Visuals.label_3d("20m × 20m / STOREY %d\n%s"%[int(r.floor)+1,FortCastle.TYPES[kind].name.to_upper()],color,8);heading.font_size=30;heading.pixel_size=.025;heading.visibility_range_end=150;root.add_child(heading)
	return root
