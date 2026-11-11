extends SceneTree
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func room(x:int,z:int,kind:String,floor_index:=0)->String:
	var key:=FortCastle.key(x,z,floor_index)
	w.castle.rooms[key]={"x":x,"z":z,"floor":floor_index,"kind":kind,"complete":true,"funded":{},"work":0.0,"total":0.0,"sign":Vector3(x*20-7,.6+floor_index*4,z*20-7),"walls":[],"task":"","resource":"wood"}
	w.castle.changed();return key
func finish(key:String)->void:
	p.position=w.castle.rooms[key].sign
	for i in 80:
		if w.castle.rooms[key].task=="":break
		w.clock+=.8;w.castle.work(1,key)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24825;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.shared={"wood":10000,"stone":10000,"crystal":10000,"iron":10000,"aether":10000,"gold":1000}
	check(not w.hud.hints.visible,"permanent controls removed from HUD")
	w.toggle_pause();w.hud.controls.open_panel();check(w.menu_open and w.hud.controls.visible and not w.hud.menu.visible,"Controls opens inside Camp Menu")
	w.toggle_pause();check(w.hud.menu.visible and not w.hud.controls.visible,"Escape returns from controls to camp")
	w.toggle_pause()
	p.owned_weapons=PackedStringArray(["Axe","Hammer","Crossbow"]);p.weapon="Axe"
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;p._unhandled_input(wheel)
	check(p.weapon=="Hammer","wheel down selects next owned weapon")
	w.clock+=.3;wheel.button_index=MOUSE_BUTTON_WHEEL_UP;p._unhandled_input(wheel)
	check(p.weapon=="Axe","wheel up selects previous owned weapon")
	w.local_build_mode=true;var before:=p.weapon;p._unhandled_input(wheel);check(p.weapon==before,"build wheel does not switch weapons");w.local_build_mode=false
	w.menu_open=true;p._unhandled_input(wheel);check(p.weapon==before,"menu wheel does not switch weapons");w.menu_open=false
	p.position=FortHearthGrowth.workshop(w);w.pets.recruit(1,0,w.pets.revision)
	var pet_id:int=w.pets.pets.keys()[0];var pet:Dictionary=w.pets.pets[pet_id];pet.cargo=5;pet.node.position=Vector3(100,0,100)
	var wood:int=w.shared.wood;w.pets.release(1,pet_id,pet.revision)
	check(w.pets.pets.is_empty() and w.shared.wood==wood+5,"release distant working pet returns cargo and frees slot")
	w.pets.release(1,pet_id,pet.revision);check(w.shared.wood==wood+5,"duplicate release cannot duplicate cargo")
	var camp:Dictionary=w.progression.sites[1];camp.active=true;camp.opened=true;camp.return_wave=2;w.wave=2;p.position=Vector3(-100,0,0)
	w.progression.tick();check(not camp.opened and not camp.active,"authored camp respawns after two dawns with crew away")
	var wild:Dictionary=w.encounters.sites[102];wild.phase="claimed";wild.return_wave=2;w.encounters.next_check=0;w.encounters.tick()
	check(wild.phase=="sleeping","wilderness camp respawns on schedule")
	wild.phase="claimed";wild.return_wave=2;p.position=wild.spec.pos;w.encounters.next_check=0;w.encounters.tick()
	check(wild.phase=="claimed","occupied camp does not respawn on players")
	var keep:Node3D=w.find_child("Hearthhold",true,false);var old_scale:Vector3=keep.get_node("Campfire").scale
	w.set_hearth_level(4)
	check(keep.get_node("Campfire").scale.y>old_scale.y and keep.has_node("HearthGrowth"),"upgraded hearth is larger and gains decorations")
	check(keep.get_node("Workshop").global_position.distance_to(FortHearthGrowth.workshop(w))<.01,"workshop interaction follows its new wall position")
	for prop in get_nodes_in_group("starter_dressing"):check(not prop.visible,"starter camp clutter clears on upgrade")
	room(1,0,"Stairs");room(-1,0,"Courtyard");room(0,1,"Courtyard");room(0,-1,"Courtyard");room(1,0,"Courtyard",1)
	check(w.castle.plan_reason("1:0:1",{"x":0,"z":0,"floor":1},"Courtyard").contains("open sky"),"upper floors above the hearth are rejected")
	var merchant:=room(0,2,"Merchant");p.position=w.castle.rooms[merchant].sign
	var stock:=w.shared.duplicate();FortMerchant.trade(w,1,merchant,"wood",true,w.castle.revision,w.wave)
	check(w.shared==stock,"trade request at room sign is rejected")
	p.position=FortMerchant.location(w.castle,merchant)+Vector3(2,0,0);var revision:=w.castle.revision
	FortMerchant.trade(w,1,merchant,"wood",true,revision,w.wave)
	check(w.shared.wood==stock.wood-5 and w.shared.gold==stock.gold+10,"selling supplies deposits shared gold")
	FortMerchant.trade(w,1,merchant,"wood",true,revision,w.wave);check(w.shared.wood==stock.wood-5,"stale trade revision cannot double sell")
	for resource in GameData.BASIC:check(FortMerchant.price(w,merchant,resource)>int(FortMerchant.SELL[resource]),"daily sale cannot create arbitrage for "+resource)
	var gold:int=w.shared.gold;var iron:int=w.shared.iron;var price:=FortMerchant.price(w,merchant,"iron")*5
	FortMerchant.trade(w,1,merchant,"iron",false,w.castle.revision,w.wave)
	check(w.shared.gold==gold-price and w.shared.iron==iron+5,"gold buys resources at advertised price")
	var gather:=room(2,0,"Gatherers");p.position=w.castle.rooms[gather].sign
	w.castle.begin_task(1,gather,"upgrade_room",w.castle.revision);finish(gather)
	check(FortCastleFeatures.level(w.castle.rooms[gather])==2,"room upgrade requires funded hand-built work")
	var gathered:=0;var resource_id:=0
	for id in w.resource_nodes:
		w.recv_resource(id,0,false)
		if w.resource_nodes[id].kind=="wood":resource_id=id
	var resource:Dictionary=w.resource_nodes[resource_id];resource.node.position=Vector3(55,0,0);w.recv_resource(resource_id,100,false)
	wood=w.shared.wood
	for i in 5:w.clock+=13;w.castle.tick()
	gathered=w.shared.wood-wood;check(gathered==12,"gatherer upgrade delivers exactly 20 percent extra over five ticks")
	var wall_room:Dictionary=w.castle.rooms["1:0:0"];w.castle.finish_walls(wall_room);w.castle.changed();await physics_frame
	var first_wall:int=wall_room.walls[0]
	check(w.defenses[first_wall].kind=="CastleWall","curtains use full-height wall geometry")
	var wall:Node3D=w.defenses[first_wall].node;var shape:CollisionShape3D=wall.find_child("*",true,false) as CollisionShape3D
	var hit:=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(wall.position+Vector3(0,3.4,-1),wall.position+Vector3(0,3.4,1),1))
	check(not hit.is_empty(),"wall blocks passage just below second floor")
	p.position=wall_room.sign;w.castle.begin_task(1,"1:0:0","edge:0:gate",w.castle.revision);finish("1:0:0");await physics_frame
	var gate_id:=-1
	for id in wall_room.walls:
		if w.defenses.has(id) and w.defenses[id].kind=="CastleGate":gate_id=id
	check(gate_id>=0,"player can build a floor-height doorway")
	if gate_id>=0:
		var gate:Dictionary=w.defenses[gate_id];p.position=gate.node.position+Vector3(0,0,3)
		w.gates.tick(3);check(FortGates.passable(gate),"door opens for nearby player")
		p.position=Vector3(-100,0,-100);w.gates.tick(3);check(not FortGates.passable(gate),"door closes when crew leaves")
		w.raiders.blast(gate.node.position,2,20,true);check(not w.defenses.has(gate_id),"bomber destroys fortified gate in one explosion")
	var sentry:=room(2,1,"Sentry");p.position=w.castle.rooms[sentry].sign
	w.castle.begin_task(1,sentry,"sentry_cannons",w.castle.revision);finish(sentry)
	check(w.castle.rooms[sentry].cannons.size()==4,"sentry room builds four outward-facing cannons")
	w.castle.finish_walls(w.castle.rooms[sentry]);var windows:=0
	for id in w.castle.rooms[sentry].walls:
		if w.defenses[id].kind=="CastleWindow":windows+=1
	check(windows==8,"sentry curtain walls preserve firing windows")
	w.recv_enemy(99001,"Raider",Vector3(100,0,0),100);w._damage_enemy(99001,5)
	check(w.enemies[99001].has("flash_until"),"weapon impact flashes enemy red")
	w.clock+=.2;FortFire.restore(w.enemies[99001],w.clock);check(not w.enemies[99001].has("flash_until"),"hit flash restores original materials")
	w._spawn_defense("Barricade",Vector3(110,0,0),0,false);var burn_id:=w.next_defense_id-1
	FortFire.ignite(w,burn_id,.29);check(w.defenses[burn_id].get("burning",0)>0,"wood ignites below 30 percent roll")
	var hp:float=w.defenses[burn_id].hp;FortFire.tick(w,1);check(w.defenses[burn_id].hp<hp,"burning structure takes damage over time")
	p.position=w.defenses[burn_id].node.position;w._repair(1);check(w.defenses[burn_id].burning==0,"repair extinguishes a burning structure")
	w._spawn_defense("MetalWall",Vector3(120,0,0),0,false);FortFire.ignite(w,w.next_defense_id-1,0);check(w.defenses[w.next_defense_id-1].get("burning",0)==0,"stone and metal structures do not ignite")
	w.recv_enemy(99002,"Sapper",Vector3(100,0,0),100);check(w.enemies[99002].speed==8.1,"ground bomber runs three times normal raider speed")
	w.recv_enemy(99003,"FireArcher",Vector3(100,0,0),100);check(FortBalance.pool(3).has("FireArcher"),"fire archers enter raid threat budget")
	check(w.build_block_reason("Watchtower",Vector3(400,0,0),0,true)=="","engineer turret bypasses permanent build radius")
	var hurt_room:Dictionary=w.castle.rooms[gather];FortCastleFeatures.damage_rooms(w.castle,FortCastle.position(hurt_room),4,2000)
	check(not FortCastleFeatures.healthy(hurt_room),"heavy attack can ruin a room")
	p.position=hurt_room.sign;w._repair(1);check(FortCastleFeatures.healthy(hurt_room),"repair restores ruined room services")
	p.position=w.castle.rooms["0:0:0"].sign;FortPerimeter.activate(w.castle,1,"0:0:0",w.castle.revision)
	check(w.castle.perimeter.get("enabled",false) and w.castle.perimeter.segments.size()>0,"outer wall upgrade creates perimeter")
	var bounds_before:Vector4i=w.castle.perimeter.bounds;var segment:Dictionary=w.castle.perimeter.segments["1:2"];var segment_id:int=segment.id
	w.defenses[segment_id].hp=123;var position_before:Vector3=w.defenses[segment_id].node.position
	room(3,0,"Courtyard");room(4,0,"Courtyard");room(5,0,"Courtyard")
	check(w.castle.perimeter.bounds.y>bounds_before.y and w.defenses[segment_id].node.position.x>position_before.x,"outer wall moves outward as castle expands")
	check(w.defenses[segment_id].hp==123,"moving perimeter preserves existing damage")
	var saved:=FortSave.capture(w);check(FortSave.validate(saved)=="","new rooms gold fire gates and perimeter pass save validation")
	check(saved.world.shared.gold==w.shared.gold and saved.world.castle.rooms[gather].level==2,"new progression values are included in save")
	print("IMPROVEMENTS25_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
