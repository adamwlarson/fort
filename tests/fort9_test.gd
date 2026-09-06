extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func capture(key:String)->void:
	await wait(.18)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func finish(w:FortWorld,id:int)->void:
	for i in 12:
		if not FortConstruction.pending(w.defenses[id]):return
		w.clock+=.8;w.construction.work(1,id)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.expedition.configure(909)
	w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	for key in ["pet_badger","pet_mole","pet_sprite","shieldguard","prowler","hexer","colossus"]:
		var art:=FortArt.asset(key);var animation:=FortPlayer.find_animation(art)
		check(animation!=null and animation.has_animation("Walk") and animation.has_animation("Attack"),key+" has authored Blender animation clips");art.free()
	var original_seed:=w.expedition.seed_value;var order:=w.expedition.order.duplicate()
	var replica:=FortExpedition.new(w);replica.receive(w.expedition.state());check(replica.order==order,"seed synchronizes biome order before expansion")
	var permutations:Dictionary={}
	for seed_value in range(12):replica.configure(seed_value);permutations[str(replica.order)]=true
	check(permutations.size()>6,"new runs produce varied biome orders")
	p.position=Vector3.ZERO;var old_time:=w.phase_time;w._upgrade_hearth(1,1)
	check(w.hearth_level==2 and w.phase_time==old_time+30 and w.day_length()==180,"hearth upgrade adds daylight immediately and to future days")
	for level in range(3,9):w.set_hearth_level(level)
	check(w.frontier_radius()==643 and w.build_radius()==340 and w.resource_nodes.size()==594,"eight hearth tiers expand the map to 1286m with 594 resources")
	check(w.expedition.seed_value==original_seed and w.expedition.order==order,"upgrades preserve the session biome seed")
	check(w.day_length()==360 and w.night_length(30)>w.night_length(10) and FortBalance.budget(40,8,4)>FortBalance.budget(30,8,4),"daylight, later nights and threat scale past night ten")
	for level in range(4,9):check(w.frontier.has_node("BiomeTier%d"%level),"random biome ring %d exists"%level)
	var camera:=Camera3D.new();w.add_child(camera);camera.current=true;camera.position=Vector3(289,22,30);camera.look_at(Vector3(280,2,0));w.hud.hide();await capture("fort9_biome")
	for level in range(4,9):
		var grove:=w.frontier.get_node("BiomeTier%d"%level);var batches:=grove.find_children("*_batch","MultiMeshInstance3D",false,false)
		var point:Vector3=batches[0].multimesh.get_instance_transform(0).origin
		camera.position=point+Vector3(13,6,15);camera.look_at(point+Vector3.UP*2);await capture("fort9_biome_%d"%level)
	# Accurate salvage: reserve build and upgrade costs, complete, then remove once.
	p.position=Vector3(0,0,25);w._spawn_defense("Watchtower",Vector3(0,0,22),0,false);var id:int=w.next_defense_id-1
	w.construction.begin(id,1,{"wood":18,"stone":8},"build");finish(w,id)
	var d:Dictionary=w.defenses[id];check(w.construction.salvage_refund(d).wood==9,"completed building retains its actual paid-material refund")
	w.progression.upgrade_defense(1,id,1);finish(w,id)
	check(d.paid.wood==30 and w.construction.salvage_refund(d).wood==15,"completed upgrades contribute only paid materials to salvage")
	d.hp=d.max_hp*.5;check(w.construction.salvage_refund(d).wood==7,"damaged buildings return proportionally less salvage")
	var wood:int=w.shared.wood;w.is_night=true;w.construction.salvage(1,id,d.work_revision);check(w.defenses.has(id),"nighttime salvage is rejected")
	w.is_night=false;w.construction.salvage(1,id,d.work_revision);w.construction.salvage(1,id,d.work_revision)
	check(not w.defenses.has(id) and w.shared.wood==wood+7,"salvage removes building and refunds exactly once")
	# Rotated wall footprint and cleared respawn permission.
	var resource:Dictionary=w.resource_nodes.values()[0];var resource_pos:Vector3=resource.node.position
	w._spawn_defense("MetalWall",resource_pos,PI/2,false);id=w.next_defense_id-1
	check(not w.resource_respawn_clear(resource),"tree respawn is deferred inside a rotated wall")
	w.recv_remove_defense(id);check(w.resource_respawn_clear(resource),"resource respawn resumes when the obstructing building is removed")
	# Collision-aware knockback moves over several physics frames, not through walls.
	w.recv_enemy(9901,"Raider",Vector3(0,0,102),1000);p.position=Vector3(0,0,100)
	w._resolve_hit(1,Vector3.BACK,"Greatmaul");var enemy:Dictionary=w.enemies[9901]
	check(enemy.hp<1000 and enemy.impulse.length()>15,"Greatmaul delivers damage and a substantial knockback impulse")
	w._spawn_defense("MetalWall",Vector3(0,0,105),0,false);await physics_frame
	for i in 40:w.clock+=1.0/60;w._simulate_enemies(1.0/60);await physics_frame
	check(enemy.node.position.z>102.4 and enemy.node.position.z<105,"hammer knockback moves the enemy but cannot tunnel through a wall")
	for eid in w.enemies.keys():w.recv_enemy_dead(eid)
	for did in w.defenses.keys():w.recv_remove_defense(did)
	# Weapons craft, equip, and reinforce through the same authority path.
	p.position=Vector3(-4.6,0,2)
	for kind in GameData.WEAPON_ORDER:
		w.clock+=1;w._craft_weapon(1,kind)
		check(kind in p.owned_weapons,"workshop crafts "+kind)
		w._equip_weapon(1,kind);check(kind=="Axe" or is_instance_valid(p.weapon_visual),kind+" has a visible equipped model")
	for level in range(1,8):w.clock+=1;w._upgrade_weapon(1,"Greatmaul",level)
	check(p.weapon_levels.Greatmaul==8 and is_equal_approx(p.weapon_power("Greatmaul"),2.75),"weapons reinforce through level eight")
	w.hud.show();p.camera.current=true;w.open_forge();w.hud.forge.tabs.current_tab=0;await capture("fort9_forge");w.toggle_pause()
	# Three distinct towers perform damage/control.
	for i in 3:
		var kind:String=["Embercoil","GravityWell","Sunlance"][i]
		w._spawn_defense(kind,Vector3(i*8,0,100),0,false);id=w.next_defense_id-1
		w.recv_enemy(9910+i,"Shieldguard",Vector3(i*8,0,105),1000);var target:Dictionary=w.enemies[9910+i]
		FortAdvancedArsenal.tick_tower(w,w.defenses[id]);check(target.hp<1000,kind+" attacks its target")
		if kind=="GravityWell":check(target.slow>0 and target.impulse.length()>0,"GravityWell pulls and slows enemies")
		p.position=Vector3(i*8,0,102);for level in range(1,8):w.clock+=1;w.progression.upgrade_defense(1,id,level);finish(w,id)
		check(w.defenses[id].level==8 and w.defenses[id].node.has_node("Tier8"),kind+" upgrades to level eight with a visible rank")
	camera.current=true;w.hud.hide();camera.position=Vector3(26,8,117);camera.look_at(Vector3(8,1.5,100));await capture("fort9_towers")
	for eid in w.enemies.keys():w.recv_enemy_dead(eid)
	for did in w.defenses.keys():w.recv_remove_defense(did)
	# Boss persists at dawn; duplicate death cannot duplicate rewards.
	w.wave=9;w.is_night=false;w._advance_phase()
	check(w.enemies.has(900010),"night ten summons the giant boss")
	w._advance_phase();check(not w.ended and w.enemies.has(900010),"campaign and boss continue after tenth dawn")
	var boss:Dictionary=w.enemies[900010];boss.node.position=Vector3(0,0,18);w._spawn_defense("MetalWall",Vector3(0,0,21),0,false)
	w.expedition.simulate(boss,.016);check(float(boss.get("slam_at",0))>w.clock,"Colossus telegraphs its area slam")
	var health:float=w.defenses[w.next_defense_id-1].hp;w.clock+=1.9;w.expedition.simulate(boss,.016)
	check(w.defenses[w.next_defense_id-1].hp<health,"Colossus slam damages a nearby building")
	camera.position=Vector3(10,6,28);camera.look_at(Vector3(0,2.4,18));await capture("fort9_colossus")
	var iron:int=w.shared.iron;w._damage_enemy(900010,100000);w._damage_enemy(900010,100000)
	check(w.expedition.bosses_defeated==1 and w.shared.iron==iron+25 and "Runeblade" in p.owned_weapons,"boss reward is shared and paid once")
	w._advance_phase();check(w.wave==11 and not w.ended,"night eleven starts normally")
	w._advance_phase();w.expedition.event_name="Supply Caravan";w.expedition.event_claimed=false;w.expedition.event_visual();p.position=FortExpedition.CACHE_POS
	wood=w.shared.wood;w.expedition.interact(1);w.expedition.interact(1)
	check(w.shared.wood==wood+12,"random caravan chest is claimable exactly once")
	w.expedition.event_name="Bountiful Dawn";check(w.expedition.gather_multiplier()==2,"bountiful daylight doubles gathering")
	w.expedition.event_name="Warband Scouts";w.expedition.event_claimed=false;w.expedition.event_time=29;w.expedition.tick(2)
	check(w.enemies.size()>0 and w.expedition.event_claimed,"warned daytime warband event actually spawns enemies")
	w.expedition.event_name="";for eid in w.enemies.keys():w.recv_enemy_dead(eid)
	for did in w.defenses.keys():w.recv_remove_defense(did)
	# Recruit and assignment security; actual pathing and a delivery tested separately.
	p.position=Vector3(-4.6,0,2)
	for kind in 3:w.pets.recruit(1,kind,w.pets.revision)
	wood=w.shared.wood;w.pets.recruit(1,0,w.pets.revision)
	check(w.pets.pets.size()==3 and w.shared.wood==wood,"shared three-pet limit rejects an extra purchase without charge")
	w.pets.assign(1,1,"stone",0);w.pets.assign(1,1,"aether",0)
	check(w.pets.pets[1].resource=="stone","stale assignment cannot overwrite a newer pet command")
	for pet_id in [2,3]:w.pets.assign(1,pet_id,"rest",0)
	w.hud.show();p.camera.current=true;w.open_forge();w.hud.forge.tabs.current_tab=2;await capture("fort9_pets_menu");w.toggle_pause()
	var pet:Dictionary=w.pets.pets[1];pet.node.position=Vector3(0,.1,18);pet.mode="GATHER"
	var resource_id:=-1
	for rid in w.resource_nodes:
		if w.resource_nodes[rid].kind=="stone":resource_id=rid;break
	var stone:Dictionary=w.resource_nodes[resource_id];stone.node.position=Vector3(0,0,26);stone.amount=12;pet.target=resource_id;pet.last=pet.node.position;pet.check_at=w.clock+1
	w._spawn_defense("Barricade",Vector3(0,0,21),0,false)
	var stock:int=w.shared.stone;var jumped:=false;var harvested:=false
	for step in 1500:
		w.clock+=1.0/60;w.pets.tick(1.0/60);await physics_frame
		jumped=jumped or pet.node.position.y>.7;harvested=harvested or pet.cargo>0
		if w.shared.stone>stock:break
	check(jumped and harvested,"pet jumps/routes around a real barricade and gathers its assigned resource")
	check(w.shared.stone>stock,"pet physically returns and deposits into shared stockpile")
	# A trapped pet recovers without losing or minting its carried resources.
	pet.mode="RETURN";pet.cargo=3;pet.cargo_kind="stone";pet.node.position=Vector3(100,-8,100);pet.check_at=0;pet.stuck=6
	w.clock+=1;w.pets.tick(.016);check(pet.node.position.distance_to(FortPets.HOME)<6 and pet.cargo==3,"recall rescues trapped pet without duplicating or losing its pack")
	w.pets.tick(.016);w.pets.assign(1,1,"rest",pet.revision);w.pets.tick(.016)
	w.pets.release(1,1,pet.revision);check(w.pets.pets.size()==2,"rested pet can be released to free a slot")
	camera.current=true;w.hud.hide();camera.position=Vector3(10,3,8);camera.look_at(Vector3(5,0.5,2));await capture("fort9_pets")
	main._leave_game();await wait(.2);main.queue_free();await wait(.1)
	print("FORT9_TEST_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
