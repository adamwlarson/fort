class_name FortHearthGrowth
extends RefCounted

static func workshop(w:FortWorld)->Vector3:return Vector3(-4.6,0,0) if w.hearth_level<2 else Vector3(-8.2,FortCastle.BASE,-3)
static func apply(w:FortWorld)->void:
	var keep:=w.find_child("Hearthhold",true,false) as Node3D
	if not keep:return
	var rank:=w.hearth_level
	var fire:=keep.get_node_or_null("Campfire") as Node3D
	if fire:fire.scale=Vector3(1+.10*(rank-1),1+.25*(rank-1),1+.10*(rank-1))
	var bed:=keep.get_node_or_null("HearthFireCollision") as Node3D
	if bed:bed.scale=Vector3(1+.10*(rank-1),1,1+.10*(rank-1))
	var shop:=keep.get_node_or_null("Workshop") as Node3D
	if shop:shop.position=workshop(w)-keep.position;shop.rotation.y=PI/2 if rank>=2 else 0.0
	for prop in w.get_tree().get_nodes_in_group("starter_dressing"):
		prop.visible=rank<2
		for body in prop.find_children("*","StaticBody3D",true,false):body.collision_layer=1 if rank<2 else 0
	var old:=keep.get_node_or_null("HearthGrowth")
	if old:keep.remove_child(old);old.queue_free()
	var detail:=Node3D.new();detail.name="HearthGrowth";keep.add_child(detail)
	for tier in range(2,rank+1):
		var angle:=tier*TAU/7;var radius:=2.2+.05*tier
		var pos:=Vector3(sin(angle)*radius,.2,cos(angle)*radius)
		var stone:=Visuals.box(Vector3(.35,.6+tier*.22,.35),FortArt.STONE,pos+Vector3.UP*(.3+tier*.11));detail.add_child(stone)
		var rune:=Visuals.box(Vector3(.16,.32,.38),Color("#67dbd5") if tier<5 else Color("#e6b665"),pos+Vector3.UP*(.6+tier*.22));detail.add_child(rune)
		var ring:=TorusMesh.new();ring.inner_radius=radius-.05;ring.outer_radius=radius+.05;ring.rings=48;ring.ring_segments=6
		detail.add_child(Visuals.mesh_node(ring,Color("#b89b61"),Vector3(0,.08*tier,0)))
	if rank>=2:
		for z in [-6,6]:
			detail.add_child(Visuals.box(Vector3(3,.45,1.2),FortArt.STONE,Vector3(-7,.25,z)))
			FortCastleArt.model(detail,"lantern",Vector3(-7,1.0,z))
	if rank>=4:FortCastleArt.model(detail,"castle_research",Vector3(6,0,6),Vector3.ONE*.7)
	if rank>=6:
		for x in [-7,7]:FortCastleArt.model(detail,"waystone",Vector3(x,0,-7),Vector3.ONE*.8)
static func flight_height(w:FortWorld,pos:Vector3,goal:Vector3)->float:
	var height:=maxf(4.8,goal.y+3)
	for r in w.castle.rooms.values():
		if not r.complete:continue
		var center:=FortCastle.position(r)
		# Climb before reaching a facade, including diagonals and upper storeys.
		if absf(pos.x-center.x)<16 and absf(pos.z-center.z)<16:height=maxf(height,center.y+6)
	return height
static func sky_open(w:FortWorld,pos:Vector3)->bool:
	for r in w.castle.rooms.values():
		var center:=FortCastle.position(r)
		if r.complete and center.y>pos.y+1 and absf(center.x-pos.x)<10 and absf(center.z-pos.z)<10:return false
	return not (w.pieces and w.pieces.covered(pos))
