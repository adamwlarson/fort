extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func finish_project(w:FortWorld,id:int)->void:
	for i in 10:
		w.clock+=.8;w.server_action(1,"work_defense",{"id":id})
func capture(key:String)->void:
	await wait(.2)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player()
	w.set_process(false);p.set_physics_process(false);p.position=Vector3(0,0,18)
	w.shared={"wood":500,"stone":500,"crystal":100,"iron":100,"aether":100}
	check(FortWorld.FINAL_WAVE==10 and w.build_radius()==36,"ten-night campaign and castle-compatible starting construction radius")
	check(w.build_block_reason("Watchtower",Vector3(40,0,0),0).contains("36m"),"tier one rejects distant builds")
	check(w.build_block_reason("MetalWall",Vector3(15,0,0),0).contains("tier 2"),"iron construction requires tier two")
	p.position=Vector3(-4.6,0,2)
	w.server_action(1,"craft_pack",{"level":0});var stock:=w.shared.duplicate()
	w.server_action(1,"craft_pack",{"level":0})
	check(p.carry_limit==30 and p.backpack_level==1 and w.shared==stock,"trail pack adds 12 slots and duplicate request is free")
	w.server_action(1,"craft_pack",{"level":1});check(p.backpack_level==1,"iron pack gated until hearth two")
	w.set_hearth_level(2)
	check(w.build_radius()==65 and w.frontier_radius()==153,"tier two expands building and exploration")
	w.server_action(1,"craft_pack",{"level":1})
	check(p.carry_limit==46 and p.backpack_level==2 and is_instance_valid(p.backpack_visual),"expedition frame equips with 28 extra carry slots")
	w.recv_player(25,{"name":"Pack Scout","class":3});var scout:FortPlayer=w.players[25];scout.set_physics_process(false)
	scout.apply_progression(2,PackedStringArray(),false,1);check(scout.carry_limit==54,"Scout retains larger base backpack")
	p.apply_progression(0,PackedStringArray(),false,p.progression_revision-1);check(p.backpack_level==2,"stale progression cannot erase backpack")
	var iron_id:=-1
	for id in w.resource_nodes:
		if w.resource_nodes[id].kind=="iron":iron_id=id;break
	p.position=w.resource_nodes[iron_id].node.position+Vector3(1,0,0);w.clock+=2
	w.server_action(1,"interact",{});check(p.carrying.get("iron",0)>0,"Rustscar iron can be harvested")
	var iron:int=w.shared.iron;var carried:int=p.carrying.iron
	p.position=Vector3(4.6,0,2);w.clock+=2;w.server_action(1,"interact",{})
	check(p.total_carried()==0 and w.shared.iron==iron+carried,"iron deposits into crew stockpile")
	var build_at:=Vector3.ZERO
	for x in range(35,60,3):
		p.position=Vector3(x-3,0,0)
		if w.build_block_reason("MetalWall",Vector3(x,0,0),0).is_empty():build_at=Vector3(x,0,0);break
	check(w.build_block_reason("MetalWall",build_at,0).is_empty(),"new range offers real valid metal-wall placement")
	var count:=w.defenses.size();iron=w.shared.iron;w.server_action(1,"build",{"kind":"MetalWall","pos":build_at})
	check(w.defenses.size()==count+1 and w.shared.iron==iron-14,"metal wall spends iron and builds outside old range")
	w._spawn_defense("Watchtower",Vector3(0,0,22),0,false);var tower:int=w.next_defense_id-1
	p.position=Vector3(0,0,25);w.defenses[tower].hp-=30
	w.server_action(1,"upgrade_defense",{"id":tower,"level":1});stock=w.shared.duplicate()
	w.server_action(1,"upgrade_defense",{"id":tower,"level":1})
	finish_project(w,tower)
	check(w.defenses[tower].level==2 and w.shared==stock,"tower upgrades are authoritative and duplicate-safe")
	check(is_equal_approx(w.defenses[tower].max_hp,GameData.RECIPES.Watchtower.hp*1.65) and is_equal_approx(w.defenses[tower].max_hp-w.defenses[tower].hp,30),"tower gains health without erasing existing damage")
	w.hud.upgrade_menu.open_nearest();await capture("fort5_upgrade");check(w.hud.upgrade_menu.visible,"G menu opens beside tower");w.toggle_pause()
	w.set_hearth_level(3);check(w.build_radius()==115 and w.frontier_radius()==243 and w.resource_nodes.keys().filter(func(id):return int(id)<10000).size()==234,"tier three expands to 486m diameter with 234 resource nodes")
	w.server_action(1,"upgrade_defense",{"id":tower,"level":2});finish_project(w,tower);check(w.defenses[tower].level==3,"aether enables final tower upgrade")
	var aether_id:=-1
	for id in w.resource_nodes:
		if w.resource_nodes[id].kind=="aether":aether_id=id;break
	p.position=w.resource_nodes[aether_id].node.position+Vector3(1,0,0);w.clock+=2;w.server_action(1,"interact",{})
	check(p.carrying.get("aether",0)>0,"Stormglass aether is harvestable")
	var aether_model:Node3D=w.resource_nodes[aether_id].node
	check(aether_model.find_children("HarvestChunk_*","Node3D",true,false).size()==6,"new ore has removable mining chunks")
	# Guard encounter cannot be skipped by immediately using the chest.
	p.position=FortProgression.SITES[1].pos+Vector3(0,0,2)
	w.progression.interact(1);check(w.progression.guarded(1) and not w.progression.sites[1].opened,"approaching a camp spawns daytime guards and locks chest")
	var boss:Dictionary=w.enemies[100012]
	p.position=boss.node.position+Vector3(0,0,3);p.invulnerable=0
	var before_slam:=p.health;w._simulate_guard(boss,.016)
	check(boss.get("slam_at",0)>w.clock and p.health==before_slam,"chieftain telegraphs its slam before dealing damage")
	p.position+=Vector3(0,0,8);w.clock+=.91;w._simulate_guard(boss,.016)
	check(p.health==before_slam,"moving out of chieftain slam avoids damage")
	var hearth_hp:=w.fort_health
	p.position=Vector3.ZERO
	for i in 20:w._simulate_enemies(.05);w.clock+=.05
	check(w.fort_health==hearth_hp,"camp guards stay local and do not attack hearth by day")
	w.is_night=true;w.wave=1;w._advance_phase();check(w.progression.guarded(1),"daybreak preserves camp guards")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	p.position=FortProgression.SITES[1].pos+Vector3(0,0,2);w.progression.interact(1)
	check("Embermaul" in p.relics and "Embermaul" in scout.relics and p.weapon_asset_key=="embermaul","camp treasure grants rare hammer and model to the whole crew")
	stock=w.shared.duplicate();w.progression.interact(1);check(w.shared==stock,"claimed chest cannot be farmed")
	scout.health=0
	for site in [2,4]:
		p.position=FortProgression.SITES[site].pos+Vector3(0,0,2);w.progression.interact(1)
		for id in w.enemies.keys():w.recv_enemy_dead(id)
		w.progression.interact(1)
	check(p.armor and p.max_health==GameData.class_data(p.class_id).hp+40 and is_instance_valid(p.armor_visual),"Ironheart armor equips with added maximum health")
	check(scout.armor and scout.health==0,"crew armor reward does not accidentally revive downed players")
	check(p.weapon_asset_key=="stormstring","Stormstring rare crossbow has distinct authored model")
	p.invulnerable=0;var health:=p.health;w._set_health(1,health-50);check(is_equal_approx(p.health,health-40),"armor reduces incoming damage by twenty percent")
	w.recv_player(26,{"name":"Late Arrival","class":1});w.players[26].set_physics_process(false)
	check(w.players[26].relics.size()==3 and w.players[26].armor,"late-arriving crew inherits unlocked relics")
	p.position=FortProgression.SITES[0].pos+Vector3(0,0,2);var wood:int=w.shared.wood;w.progression.interact(1)
	check(w.shared.wood==wood+8 and w.progression.sites[0].opened,"hidden unguarded cache yields shared supplies")
	# New defenses target three nearby enemies and a delayed, dodgeable frost blast.
	p.position=Vector3(0,0,18)
	w._spawn_defense("StormSpire",Vector3(30,0,30),0,false);var spire:int=w.next_defense_id-1
	w._spawn_defense("FrostMortar",Vector3(24,0,30),0,false);var mortar:int=w.next_defense_id-1
	for i in 3:w.recv_enemy(950+i,"Raider",Vector3(30+i*2,0,39),400);w.enemies[950+i].stun=100
	w.progression.tick_advanced(w.defenses[spire])
	check(w.enemies[950].hp==356 and w.enemies[951].hp==365 and w.enemies[952].hp==374,"Storm Spire chains to three enemies with falling damage")
	w.progression.tick_advanced(w.defenses[mortar]);check(w.enemies[950].slow==0,"mortar damage waits for shell impact")
	w.clock+=.61;w.progression.tick()
	check(w.enemies[950].slow>3 and w.enemies[950].hp==318,"Frost Mortar blast damages and slows a group")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	# Exact reticle solver is also used by authoritative shots, including vertical aim and occlusion.
	p.position=Vector3(0,0,28);p.look_pitch=-.08;p.look_yaw=0;p.camera_pivot.rotation=Vector3(p.look_pitch,0,0)
	w.recv_enemy(980,"Ashwing",Vector3(0,4,18),400);w.enemies[980].stun=100
	await physics_frame
	var direction:Vector3=(w.enemies[980].node.position+Vector3.UP*.85-FortAim.origin(w,p)).normalized()
	check(FortAim.solution(w,p,direction).enemy==980,"aim solver targets elevated flyers")
	w._fire_crossbow(p,direction);check(w.enemies[980].hp==320,"rare crossbow deals its advertised damage")
	var shape:=BoxShape3D.new();shape.size=Vector3(4,8,.4);var wall:=Visuals.add_static_collision(w,shape,Vector3(0,4,24));await physics_frame
	check(FortAim.solution(w,p,direction).blocked,"aim cursor reports a wall blocking the shot")
	w._fire_crossbow(p,direction);check(w.enemies[980].hp==320,"wall blocks authoritative rare crossbow damage")
	wall.queue_free();w.recv_enemy_dead(980);await physics_frame
	p.position=Vector3(8,0,24);p.look_pitch=-.2;p.look_yaw=0;p.set_physics_process(true);Input.action_press("move_right")
	await capture("fort5_crossbow_walk")
	if DisplayServer.get_name()!="headless":check(not w.hud.combat_overlay.reticle_visible,"walking crossbow hides cursor without aim held")
	var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT;mouse.pressed=true;Input.parse_input_event(mouse);Input.flush_buffered_events()
	check(p.aiming(),"right mouse enters moving crossbow aim")
	await capture("fort5_crossbow_aim")
	if DisplayServer.get_name()!="headless":check(w.hud.combat_overlay.reticle_visible,"moving crossbow shows projected aim cursor while RMB held")
	mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT;mouse.pressed=false;Input.parse_input_event(mouse);Input.flush_buffered_events()
	Input.action_release("move_right");p.set_physics_process(false)
	p.position=Vector3(0,0,28);p.velocity=Vector3.ZERO;p.camera_pivot.rotation=Vector3(-.22,0,0)
	await capture("fort5_healthbars")
	if DisplayServer.get_name()!="headless":check(w.hud.combat_overlay.bar_count>0,"nearby damaged building shows small health bar")
	# Keep the targeting fixture in the flat gap beyond the new tier-two ridge.
	w._spawn_defense("Ballista",Vector3(0,0,160),0,false);var ballista:int=w.next_defense_id-1
	p.position=Vector3(0,0,162);w._mount(1,ballista)
	p.camera_pivot.rotation=Vector3(-.1,0,0)
	w.recv_enemy(985,"Ashwing",Vector3(0,4,149),500);await physics_frame
	direction=(w.enemies[985].node.position+Vector3.UP*.85-FortAim.origin(w,p)).normalized()
	w.clock+=2;w._fire_ballista(1,direction)
	check(w.enemies[985].hp==370,"mounted ballista uses three-dimensional targeting")
	await capture("fort5_ballista_aim")
	if DisplayServer.get_name()!="headless":check(w.hud.combat_overlay.reticle_visible,"mounted ballista has an aim cursor without RMB")
	w._mount(1,-1);w.recv_enemy_dead(985)
	p.position=Vector3(-4.6,0,2);w.player_interact(p);w.hud.forge.tabs.current_tab=1
	await capture("fort5_backpacks");check(w.hud.forge.visible,"workshop backpack and relic tab opens")
	check(w.hud.forge.position.y+w.hud.forge.size.y<=720,"workshop tabs and close button fit viewport");w.toggle_pause()
	w.local_build_mode=true;await capture("fort5_build_cards");w.local_build_mode=false
	# Asset gallery and actual upgraded-zone visuals.
	var camera:=Camera3D.new();w.add_child(camera);camera.current=true;w.hud.hide()
	for kind in ["metalwall","stormspire","frostmortar","treasure_chest","chieftain","embermaul","stormstring"]:
		var asset:=FortArt.asset(kind);w.add_child(asset);asset.position=Vector3(0,0,50)
		camera.position=Vector3(4,3,56);camera.look_at(asset.position+Vector3.UP*1.2)
		if kind=="chieftain":
			var anim:=FortPlayer.find_animation(asset)
			for clip in ["Idle","Walk","Attack","Hit","Death"]:check(anim!=null and anim.has_animation(clip),"Chieftain authored "+clip+" animation")
		await capture("fort5_asset_"+kind);asset.queue_free()
	for key in ["iron","aether","camp"]:
		var target:Vector3=w.resource_nodes[iron_id if key=="iron" else aether_id].node.position if key!="camp" else FortProgression.SITES[4].pos
		camera.position=target+Vector3(9,6,11);camera.look_at(target+Vector3.UP)
		await capture("fort5_zone_"+key)
	w.hud.show();p.camera.current=true
	w.is_night=true;w.wave=9;w._advance_phase();check(not w.ended,"ninth night does not end campaign")
	w._advance_phase();check(w.wave==10,"tenth night starts");w._advance_phase();check(not w.ended,"surviving tenth night continues the endless expedition")
	main._leave_game();await wait(.2);main.queue_free();await wait(.1)
	print("FORT5_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
