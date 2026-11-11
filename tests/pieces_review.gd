extends SceneTree
# Renders a demo fort made of building pieces, the starter shell and a catalogue row.
const P:=preload("res://scripts/fort_pieces.gd")
var b:FortPieces
func _initialize()->void:run.call_deferred()
func add(kind:String,slot:int,ix:int,iz:int,level:=0,turn:=0)->void:
	b.recv_piece(FortPieces.key(slot,ix,iz,level),kind,turn,float(FortPieces.KINDS[kind].hp))
func snap(camera:Camera3D,from:Vector3,to:Vector3,name:String)->void:
	camera.position=from;camera.look_at(to)
	await create_timer(.5).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/pieces_%s.png"%name))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24870;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.hud.visible=false
	b=w.pieces;p.position=Vector3(0,.6,6)
	b.starter()
	# --- timber hall, three tiles wide and four long
	for x in range(14,17):
		for z in range(14,18):add("Foundation",P.DECK,x,z)
	for z in range(14,18):
		add("WoodWindow" if z in [15,16] else "WoodWall",P.EX,13,z,0,1)
		add("WoodWindow" if z==15 else "WoodWall",P.EX,16,z,0,0)
		add("ThatchSlope",P.FILL,14,z,1,3);add("ThatchPeak",P.FILL,15,z,1,1);add("ThatchSlope",P.FILL,16,z,1,1)
	for x in range(14,17):
		add("WoodWall",P.EZ,x,13,0,1)
		add("WoodDoor" if x==15 else "WoodWindow",P.EZ,x,17,0,0)
		add("WoodGable",P.EZ,x,13,1,1);add("WoodGable",P.EZ,x,17,1,0)
	add("Brazier",P.FILL,15,18,0)
	add("Foundation",P.DECK,15,18)
	# --- stone tower with a spire
	add("Foundation",P.DECK,19,14)
	for level in 3:
		add("StoneSlit" if level==2 else "StoneWall",P.EX,19,14,level,0);add("StoneSlit" if level==1 else "StoneWall",P.EX,18,14,level,1)
		add("StoneWall",P.EZ,19,13,level,1);add("StoneArch" if level==0 else "StoneWall",P.EZ,19,14,level,0)
		add("WoodFloor",P.DECK,19,14,level+1)
	add("SlateSpire",P.FILL,19,14,3)
	for edge in [[P.EX,19,14,0],[P.EX,18,14,1],[P.EZ,19,13,1],[P.EZ,19,14,0]]:add("Battlement",edge[0],edge[1],edge[2],3,edge[3])
	# --- curtain wall with a walk, a gate and stairs up
	for z in range(15,19):
		add("Foundation",P.DECK,19,z)
		add("StoneGate" if z==16 else "StoneWall",P.EX,19,z,0,0)
		add("StoneFloor",P.DECK,19,z,1);add("Battlement",P.EX,19,z,1,0)
		if z<18:add("WoodRailing",P.EX,18,z,1,1)
	add("Battlement",P.EZ,19,18,1,0)
	for x in [17,18]:add("Foundation",P.DECK,x,18)
	add("StoneStairs",P.FILL,17,18,0,3)
	add("StoneColumn",P.CORNER,18,18,0);add("BannerPole",P.CORNER,19,18,1)
	print("PIECES ",b.pieces.size()," unsupported=",b.unsupported().size())
	for k in b.unsupported():print("   loose ",b.pieces[k].kind," ",FortPieces.unpack(k))
	# --- catalogue
	var names:Array=FortPieces.KINDS.keys()
	for i in names.size():
		var kind:String=names[i];var spec:Dictionary=FortPieces.KINDS[kind];var x:=30+(i%10)*2;var z:=10+int(i/10)*3
		add("Foundation",P.DECK,x,z)
		if spec.get("shape","")=="stairs":add("Foundation",P.DECK,x,z-1)
		match str(spec.slot):
			"deck":
				if not spec.get("ground",false):add("WoodPost",P.CORNER,x,z,0);add(kind,P.DECK,x,z,1)
			"edge":add(kind,P.EZ,x,z,0,0)
			"corner":add(kind,P.CORNER,x,z,0)
			_:add(kind,P.FILL,x,z,0,0)
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=40;camera.current=true
	await snap(camera,Vector3(98,20,98),Vector3(66,3,64),"fort_south_east")
	await snap(camera,Vector3(40,16,88),Vector3(64,3,62),"fort_south_west")
	await snap(camera,Vector3(62,2.4,84),Vector3(64,4,62),"fort_eye_level")
	await snap(camera,Vector3(95,9,52),Vector3(74,6,64),"fort_tower")
	await snap(camera,Vector3(60,3.2,62),Vector3(60,3.4,70),"hall_inside")
	for row in 3:
		await snap(camera,Vector3(140,9,62+row*12.0),Vector3(140,1.5,40+row*12.0),"catalogue_%d"%row)
	await snap(camera,Vector3(22,14,26),Vector3(0,1,0),"starter")
	await snap(camera,Vector3(3,2.6,17),Vector3(0,2.2,0),"starter_eye")
	main.queue_free();await process_frame;print("PIECES_REVIEW_CAPTURED");quit()
