extends SceneTree
# Fort 29 building pieces: lattice, placement rules, support and collapse, removal and
# ground pickups, damage, raiders breaching, doors, gables, sync state and the build tabs.
const P:=preload("res://scripts/fort_pieces.gd")
const ROW:=6
var failures:=0
var w:FortWorld
var p:FortPlayer
var b:FortPieces
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func put(kind:String,k:int,turn:=0)->String:
	p.position=FortPieces.place(k)+Vector3(3,9,3);w.cooldowns.clear()
	var why:=b.reason(kind,k,turn)
	if why!="":print("     refused: ",kind," / ",why)
	b.request_place(1,{"kind":kind,"key":k,"turn":turn})
	return why
func stock()->int:
	return int(w.shared.wood)+int(w.shared.stone)+int(w.shared.iron)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24869;main._host();main._start_match()
	w=main.world;p=w.local_player();b=w.pieces;w.set_process(false);p.set_physics_process(false)
	w.shared={"wood":1000,"stone":1000,"crystal":0,"iron":1000,"aether":0}
	check(b.pieces.is_empty(),"automated worlds start without the starter shell")
	# --- lattice
	var k:=FortPieces.key(P.EX,-7,12,3);var u:=FortPieces.unpack(k)
	check(u==[P.EX,-7,12,3],"slot keys pack and unpack")
	check(FortPieces.place(FortPieces.key(P.EX,2,0,0)).is_equal_approx(Vector3(10,.6,0)) and FortPieces.place(FortPieces.key(P.CORNER,2,2,1)).is_equal_approx(Vector3(10,5.6,10)),"edges and corners line up with the castle room border and storeys")
	check(not FortPieces.valid_key("WoodWall",FortPieces.key(P.DECK,0,0,0)) and FortPieces.valid_key("WoodWall",k),"a piece only fits its own kind of slot")
	# --- on the keep floor
	var keep_wall:=FortPieces.key(P.EX,2,2,0)
	var before:=stock()
	check(put("WoodWall",keep_wall)=="" and b.pieces.has(keep_wall),"a wall can stand straight on the castle floor")
	check(before-stock()==4,"placing spends the piece cost from the shared stockpile")
	check(put("WoodWall",keep_wall).contains("already here"),"an occupied slot is refused")
	check(b.reason("Foundation",FortPieces.key(P.DECK,1,1,0),0).contains("castle floor"),"foundations are not needed on castle floors")
	check(b.reason("WoodWall",FortPieces.key(P.EZ,0,0,0),0).contains("hearth"),"the hearth stays clear")
	# --- open ground
	var a:=10
	w.set_hearth_level(3)
	print("ground: ",b.reason("Foundation",FortPieces.key(P.DECK,a,0,0),0)," / ",b.reason("Foundation",FortPieces.key(P.DECK,a,3,0),0)," / ",b.reason("Foundation",FortPieces.key(P.DECK,a,6,0),0))
	check(b.reason("WoodWall",FortPieces.key(P.EX,a,0,0),0).contains("foundation"),"a wall needs a foundation or floor")
	check(b.reason("WoodFloor",FortPieces.key(P.DECK,a,0,0),0).contains("foundation"),"floors are not laid on the ground")
	for i in 5:check(put("Foundation",FortPieces.key(P.DECK,a+i,0,0))=="","foundation %d placed on open ground"%i)
	check(b.reason("Foundation",FortPieces.key(P.DECK,a,0,1),0)!="","foundations stay on the ground")
	check(put("StoneWall",FortPieces.key(P.EX,a-1,0,0))=="","stone wall on the foundation edge")
	check(put("WoodFloor",FortPieces.key(P.DECK,a,0,1))=="","a floor rests on the wall top")
	check(put("WoodFloor",FortPieces.key(P.DECK,a+1,0,1))=="" and put("WoodFloor",FortPieces.key(P.DECK,a+2,0,1))=="","floors reach two tiles from their support")
	check(b.reason("WoodFloor",FortPieces.key(P.DECK,a+3,0,1),0).contains("reach 2"),"a third unsupported tile is refused")
	check(put("WoodPost",FortPieces.key(P.CORNER,a+3,0,0))=="" and put("WoodFloor",FortPieces.key(P.DECK,a+3,0,1))=="","a post carries the floor further")
	check(put("StoneWall",FortPieces.key(P.EX,a-1,0,1))=="","walls stack on walls")
	check(put("Battlement",FortPieces.key(P.EX,a-1,0,2))=="","a battlement sits on the wall top")
	b.recv_piece_gone(FortPieces.key(P.EX,a-1,0,2),"")
	check(b.reason("WoodStairs",FortPieces.key(P.FILL,a+4,0,0),3).contains("both tiles"),"stairs need floor under both tiles")
	check(put("ThatchRidge",FortPieces.key(P.FILL,a,0,2),0)=="","a roof rests on the wall below it")
	check(b.reason("ThatchRidge",FortPieces.key(P.FILL,a+6,0,1),0).contains("Roofs rest"),"a roof with nothing under it is refused")
	# --- stairs occupy two tiles and the floor above the upper one
	for i in 2:put("Foundation",FortPieces.key(P.DECK,a+i,ROW,0))
	check(put("StoneStairs",FortPieces.key(P.FILL,a,ROW,0),3)=="","stairs placed across two foundations")
	check(b.reason("WoodFloor",FortPieces.key(P.DECK,a+1,ROW,1),0).contains("in the way"),"the stair opening stays clear")
	check(b.pieces[FortPieces.key(P.FILL,a,ROW,0)].node.rotation.y>4.6,"stairs turn to face the way they climb")
	# --- gables take the roof's outline
	var gable:=FortPieces.key(P.EX,a-1,0,2)
	check(put("WoodGable",gable)=="","a gable stands beside the roof")
	check(b.gable_variant(gable)[0]=="tri","a gable at the end of a ridge is a triangle")
	check(b.gable_variant(FortPieces.key(P.EZ,a,0,2))[0]=="tri" and b.gable_variant(FortPieces.key(P.EZ,a,0,2))[1]==-1,"eave sides fall back to the plain shape")
	b.recv_piece_gone(FortPieces.key(P.FILL,a,0,2),"");b.recv_piece(FortPieces.key(P.FILL,a,0,2),"SlateSlope",0,450.0)
	check(b.gable_variant(gable)[0]=="half","the same gable becomes a half triangle beside a slope")
	check(is_instance_valid(b.pieces[gable].node) and b.pieces[gable].node.get_parent()==b.root,"the gable was rebuilt in place")
	# --- sync
	var saved:Dictionary=b.state();var count:=b.pieces.size()
	check(FortPieces.validate(saved)=="" and saved.data.size()==count*3,"state is three integers per piece")
	check(w.full_state().has("pieces"),"pieces travel with the full world state")
	for key in b.pieces.keys():b.recv_piece_gone(key,"")
	check(b.pieces.is_empty() and b.occupied.is_empty(),"clearing leaves no occupied slots")
	b.receive(saved)
	check(b.pieces.size()==count and b.pieces.has(gable) and b.occupied.has(FortPieces.key(P.DECK,a+1,ROW,1)),"a snapshot rebuilds every piece and stair opening")
	check(b.unsupported().is_empty(),"everything rebuilt is still supported")
	# --- removal, collapse and pickups
	p.carrying={"wood":0,"stone":0,"crystal":0};var carried:=p.total_carried()
	p.position=FortPieces.place(FortPieces.key(P.CORNER,a+3,0,0))+Vector3(0,12,0);w.cooldowns.clear()
	b.request_remove(1,FortPieces.key(P.CORNER,a+3,0,0))
	check(not b.pieces.has(FortPieces.key(P.DECK,a+3,0,1)) and b.pieces.has(FortPieces.key(P.DECK,a+2,0,1)),"removing a post drops only the floor it was holding")
	var on_ground:=0
	for pile in b.drops.values():on_ground+=int(pile.stock.get("wood",0))
	check(on_ground==5,"the post and the fallen floor leave all their wood on the ground")
	var pile_pos:Vector3=b.drops.values()[0].pos
	check(pile_pos.y<1.0,"dropped materials land on the surface below")
	for pile in b.drops.values().duplicate():
		p.position=pile.pos;b.tick_drops()
	check(p.total_carried()-carried==5 and b.drops.is_empty(),"walking over a pile puts it in your pack")
	p.carrying={"wood":p.carry_limit,"stone":0,"crystal":0}
	b.spawn_drop(pile_pos,{"stone":3});b.tick_drops()
	check(b.drops.size()==1,"a full pack leaves the pile where it is")
	b.recv_drop(b.drops.keys()[0],Vector3.ZERO,{})
	# --- damage and repair
	var target:=FortPieces.key(P.EX,a-1,0,0)
	b.damage(target,400);check(is_equal_approx(b.pieces[target].hp,500),"raider damage lowers a piece's health")
	p.position=FortPieces.place(target)+Vector3(1,0,0);w.cooldowns.clear();var stone_before:=int(w.shared.stone)
	check(b.repair(p) and b.pieces[target].hp>500 and int(w.shared.stone)==stone_before-1,"R repairs a stone piece for one stone")
	b.damage(target,5000)
	check(not b.pieces.has(target) and not b.pieces.has(FortPieces.key(P.EX,a-1,0,1)) and not b.pieces.has(FortPieces.key(P.EX,a-1,0,2)),"a destroyed wall takes down the walls stacked on it")
	check(not b.pieces.has(FortPieces.key(P.DECK,a,0,1)) and not b.pieces.has(FortPieces.key(P.FILL,a,0,2)),"and the floors and roof that hung from it")
	check(b.unsupported().is_empty() and not b.drops.is_empty(),"nothing is left floating and the rubble can be collected")
	for id in b.drops.keys():b.recv_drop(id,Vector3.ZERO,{})
	# --- raiders break through
	var wall:=FortPieces.key(P.EX,a+4,0,0)
	put("WoodWall",wall);p.position=Vector3(0,.7,0)
	await physics_frame;await physics_frame
	w.recv_enemy(900,"Raider",FortPieces.place(wall)+Vector3(1.2,.1,0),60.0)
	var e:Dictionary=w.enemies[900];e.node.rotation.y=-PI*.5
	await physics_frame;await physics_frame
	var hp:float=b.pieces[wall].hp
	for i in 40:
		w.clock+=.2;e.attack=maxf(0,float(e.attack)-.2);b.siege(e,.2)
	check(int(e.get("piece_breach",-1))==wall,"a raider stalled against a wall picks it as a breach target")
	check(b.pieces.has(wall) and b.pieces[wall].hp<hp,"and hammers it down over time")
	w.recv_enemy_dead(900)
	# --- doors
	var door:=FortPieces.key(P.EX,a+1,0,0)
	put("WoodDoor",door);p.position=Vector3(0,.7,0)
	for i in 10:b.tick(.1)
	var body:Node=b.pieces[door].node.get_node("DoorBody")
	await physics_frame
	check(not (body.get_child(0) as CollisionShape3D).disabled,"a door is shut while no dwarf is near")
	p.position=FortPieces.place(door)+Vector3(1.5,0,0)
	for i in 10:b.tick(.1)
	await physics_frame;await physics_frame
	check((body.get_child(0) as CollisionShape3D).disabled,"and opens when a dwarf walks up")
	# --- castle walls take priority
	b.recv_piece(FortPieces.key(P.EX,2,0,0),"WoodWall",0,350.0);var wood:=int(w.shared.wood)
	w._spawn_defense("CastleWall",Vector3(10,.6,0),PI*.5,false)
	check(not b.pieces.has(FortPieces.key(P.EX,2,0,0)) and int(w.shared.wood)==wood+4 and b.pieces.has(keep_wall),"a castle wall replaces the piece in its slot and refunds it")
	# --- build menu
	w.select_tab(0);check(w.build_tabs().size()==6 and w.build_tab==0,"six build categories: two tower pages and four piece sets")
	w.select_tab(3);check(w.build_tab==3 and b.selected()=="WoodWall","Tab reaches the timber set")
	w.select_build_slot(3);check(b.selected()=="WoodDoor","number keys choose a piece in the open category")
	w.cycle_build(1);check(b.selected()=="WoodRailing","the wheel walks the open category")
	w.select_tab(6);check(w.build_tab==0,"categories wrap around")
	w.select_build(2);check(w.build_tab==0 and w.selected_build==2,"tower selection still works")
	var total:=0
	for tab in FortPieces.TABS:
		total+=tab.items.size()
		for item in tab.items:check(FortPieces.KINDS.has(item) and tab.items.size()<=10,"menu entry %s exists"%item)
	check(total==FortPieces.KINDS.size(),"every piece is in the menu exactly once")
	# --- aiming
	var choice:=b.pick("WoodWall",Vector3(41.7,.6,0.3),Vector3(1,-.3,0))
	check(choice[0]==FortPieces.key(P.EX,10,0,0) and choice[1]==0,"aiming east at a tile edge picks that edge, outer face away from the builder")
	choice=b.pick("WoodWall",Vector3(41.7,.6,0.3),Vector3(-1,-.3,0));check(choice[1]==1,"facing the other way flips the wall")
	choice=b.pick("WoodFloor",Vector3(40.5,4.4,.5),Vector3(1,0,0));check(choice[0]==FortPieces.key(P.DECK,10,0,1),"aiming high on a wall offers the floor above")
	b.lift=1;choice=b.pick("WoodFloor",Vector3(40.5,4.4,.5),Vector3(1,0,0));check(FortPieces.unpack(choice[0])[3]==2,"the storey keys raise the target");b.lift=0
	choice=b.pick("StoneStairs",Vector3(40,.6,12),Vector3(0,-.4,1));check(choice[1]==2,"stairs climb away from the builder")
	# --- shelter from flyers, and X on a defense
	b.recv_piece(FortPieces.key(P.DECK,a+1,0,1),"WoodFloor",0,300.0)
	check(not FortHearthGrowth.sky_open(w,FortPieces.place(FortPieces.key(P.DECK,a+1,0,0))+Vector3(0,.2,0)) and FortHearthGrowth.sky_open(w,Vector3(80,0,0)),"a floor overhead shelters a dwarf from flying raiders")
	w.recv_defense(7001,"Barricade",Vector3(0,.6,-8),0,320,false);w.defenses[7001].paid={"wood":12,"stone":3}
	w.is_night=false;p.position=Vector3(0,.6,-6);w.cooldowns.clear();var wood_then:=int(w.shared.wood)
	w.request_action("salvage_defense",{"id":7001,"revision":0})
	check(not w.defenses.has(7001) and int(w.shared.wood)==wood_then+6,"salvaging a defense still returns half to the stockpile")
	# --- starter shell
	for key in b.pieces.keys():b.recv_piece_gone(key,"")
	b.starter()
	check(b.pieces.size()==12 and b.unsupported().is_empty(),"the starter shell is twelve supported pieces")
	print("FORT29_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
