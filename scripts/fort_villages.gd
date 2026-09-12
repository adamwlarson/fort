class_name FortVillages
extends RefCounted

static func build(parent:Node3D,tier:int)->void:
	# Authored houses have open doorways; matching wall colliders keep interiors explorable.
	for i in 3:
		var house:=FortLandscape.place(parent,"village_house",Vector3((i-1)*6.0,0,5.5),PI,1.0)
		for x in [-1.9,1.9]:FortArt.box_collider(house,Vector3(.22,2.8,3.25),Vector3(x,1.55,0))
		FortArt.box_collider(house,Vector3(3.9,2.8,.2),Vector3(0,1.55,-1.55))
		for x in [-1.32,1.32]:FortArt.box_collider(house,Vector3(1.25,2.8,.2),Vector3(x,1.55,1.55))
		# Floor flush with terrain; no hidden foundation step at the doorway.
		FortArt.box_collider(house,Vector3(4.0,.12,3.4),Vector3(0,-.06,0))
		FortLandscape.place(house,"supply_crate",Vector3(.9,0,-.5),.2,.6)
		FortLandscape.place(house,"barrel",Vector3(-1.0,0,-.6),0,.65)
	var well:=FortLandscape.place(parent,"village_well",Vector3(4,0,-3.5),0,1.0)
	FortArt.box_collider(well,Vector3(1.8,.9,1.8),Vector3(0,.45,0))
	for x in [-7,7]:FortArt.lantern(parent,Vector3(x,0,-2),false)
	FortLandscape.place(parent,"quarry_cart" if tier==2 else "waystone",Vector3(-4,0,-3),.5,.9)
	var board:=Visuals.label_3d("ABANDONED SETTLEMENT\nSearch the square / E to unlock crew supplies",Color("#d9bd8a"),1.7)
	board.font_size=16;board.position.z=-2.5;board.visibility_range_end=18;parent.add_child(board)
