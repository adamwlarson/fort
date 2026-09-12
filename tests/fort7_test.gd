extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func capture(key:String)->void:
	await wait(.15)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.shared={"wood":500,"stone":500,"crystal":200,"iron":200,"aether":200}
	check(w.night_length(1)==85 and w.night_length(10)==130,"nights lengthen five seconds per wave")
	w.set_hearth_level(3);check(w.night_length(10)==160,"expanded hearth adds travel time without a large damage multiplier")
	check(w.progression.sites.size()==9,"three guarded villages join the six original treasure sites")
	for kind in ["watchtower7","upgrade_iron","upgrade_aether","weapon_pike","weapon_repeater","sapper7","cinderlobber","bombwing","village_house","village_well"]:
		var asset:=FortArt.asset(kind);check(asset!=null,"Blender asset loads: "+kind);asset.free()
	for kind in ["Sapper","Cinderlobber","Bombwing"]:
		var asset:=FortArt.make_enemy(kind);var animator:=FortPlayer.find_animation(asset)
		check(animator!=null and animator.has_animation("Walk") and animator.has_animation("Attack"),kind+" has working animation clips");asset.free()
	# A staged pad avoids tying feature tests to resource/scenery layout.
	w._spawn_defense("Ballista",Vector3(0,0,100),.4,false);var gun:Dictionary=w.defenses[1]
	p.position=Vector3(0,0,102);w._mount(1,1)
	var direction:=Vector3(.7,.35,-.5).normalized();w.server_action(1,"ballista_aim",{"direction":direction})
	check(gun.has("aim") and gun.aim.is_equal_approx(direction),"mounted ballista accepts aim without firing")
	var turret:Node3D=gun.node.get_node("Turret")
	check(turret.find_children("*","MeshInstance3D",true,false).size()>0 and absf(turret.rotation.x)>.1 and absf(turret.rotation.y)>.1,"visible ballista pivot rotates in yaw and elevation")
	check(w.snapshot().defenses[1].aim==direction,"ballista aim is included in network snapshots")
	w.recv_player(42,{"name":"Visitor","class":1});var visitor:FortPlayer=w.players[42];visitor.set_physics_process(false)
	w.server_action(42,"ballista_aim",{"direction":Vector3.RIGHT});check(gun.aim==direction,"unmounted peers cannot rotate someone else's ballista")
	w._interact(1)
	for i in 3:
		w._spawn_defense("Watchtower",Vector3((i-1)*4,0,110),0,false)
		var d:Dictionary=w.defenses[w.next_defense_id-1];d.level=i+1;w.progression.defense_visual(d)
		check(i==0 or d.node.has_node("Tier%d"%(i+1)),"tower level %d has its own visible silhouette"%(i+1))
		for shape in d.node.find_children("*","CollisionShape3D",true,false):check(not shape.shape is ConvexPolygonShape3D,"watchtower no longer has a stair ramp")
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(10,6,120);camera.look_at(Vector3(0,1.6,110));camera.current=true
	await capture("fort7_tower_tiers")
	w._spawn_defense("Mender",Vector3(0,0,90),0,false);var mend:Dictionary=w.defenses[w.next_defense_id-1]
	w._spawn_defense("MetalWall",Vector3(5,0,90),0,false);var wall_id:int=w.next_defense_id-1;var wall:Dictionary=w.defenses[wall_id];wall.hp=700
	p.position=Vector3(0,0,96.5);p.health=80;visitor.position=Vector3(0,0,99);visitor.health=80
	w.battlements.heal(mend,1);check(wall.hp==703 and p.health==82 and visitor.health==80,"Mender heals structures and dwarves within the same 7m boundary")
	w.local_build_mode=true;w.preview_kind="Mender";w.preview=FortArt.make_defense("Mender",false);w.add_child(w.preview);w.preview.position=mend.node.position;w.preview_valid=true;w.battlements.tick(.1)
	check(w.battlements.range_ring.visible and w.battlements.range_ring.scale.x==7,"placement ring matches healing radius")
	camera.position=Vector3(12,12,104);camera.look_at(Vector3(0,0,90));w.battlements.heal(mend,1);await capture("fort7_mender_coverage")
	w.local_build_mode=false;w.preview.hide();w.battlements.tick(.1)
	# Lobbers and bomb flyers damage a tower only after a visible warning.
	w.recv_enemy(701,"Cinderlobber",Vector3(5,0,105),500);var lobber:Dictionary=w.enemies[701]
	w.raiders.simulate(701,lobber,.016);check(not w.raiders.projectiles.is_empty(),"ranged siege monster launches a delayed building attack")
	var shot:Dictionary=w.raiders.projectiles[0];var damage_before:float=0
	for d in w.defenses.values():damage_before+=d.hp
	w.raiders.tick();var damage_now:=0.0
	for d in w.defenses.values():damage_now+=d.hp
	check(damage_now==damage_before,"projectile does not deal instant damage")
	w.clock=shot.at+.01;w.raiders.tick();damage_now=0
	for d in w.defenses.values():damage_now+=d.hp
	check(damage_now<damage_before,"ranged projectile damages defenses at impact")
	w.recv_enemy(702,"Bombwing",wall.node.position+Vector3(1,5.8,0),300);w.raiders.simulate(702,w.enemies[702],.016)
	check(not w.raiders.projectiles.is_empty(),"Bombwing drops a telegraphed bomb on buildings")
	w.clock+=1.3;w.raiders.tick()
	w.recv_enemy(703,"Sapper",wall.node.position+Vector3(0,0,1.5),150);var sapper:Dictionary=w.enemies[703]
	check(FortSiege.priority(w,sapper)>=0,"Sapper selects defenses instead of only the hearth")
	FortSiege.strike(w,sapper,wall_id);var hp:float=wall.hp
	check(sapper.get("fuse_at",0)>w.clock and wall.hp==hp,"Sapper lights a 1.6 second fuse before exploding")
	w.clock+=1.7;w.raiders.tick();check(not w.enemies.has(703) and wall.hp<hp,"Sapper consumes itself and damages nearby defenses")
	w.recv_enemy(704,"Sapper",wall.node.position+Vector3(0,0,1),50);w.raiders.arm(w.enemies[704]);hp=wall.hp
	w._damage_enemy(704,100);w.clock+=2;w.raiders.tick();check(wall.hp==hp,"killing a lit Sapper disarms the explosion")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	# Forge progression is host-authoritative and stale purchases cannot double-charge.
	p.position=Vector3(-4.6,0,2);w.clock+=2;w.server_action(1,"craft_weapon",{"weapon":"Pike"});w.clock+=1;w.server_action(1,"craft_weapon",{"weapon":"Repeater"})
	check("Pike" in p.owned_weapons and "Repeater" in p.owned_weapons,"new iron and aether weapons can be crafted")
	w.server_action(1,"upgrade_weapon",{"weapon":"Repeater","level":1});var stock:=w.shared.duplicate()
	w.clock+=1;w.server_action(1,"upgrade_weapon",{"weapon":"Repeater","level":1});check(w.shared==stock and p.weapon_power("Repeater")==1.25,"weapon upgrade adds damage and rejects duplicate purchase")
	w.server_action(1,"upgrade_weapon",{"weapon":"Repeater","level":2});check(p.weapon_power("Repeater")==1.5,"masterwork upgrade gives 50 percent extra base damage")
	var levels:=p.weapon_levels.duplicate();p.apply_weapon_levels({},0);check(p.weapon_levels==levels,"stale snapshots cannot downgrade weapon reinforcement")
	w.open_forge();await capture("fort7_forge");check(w.hud.forge.buttons.size()==GameData.WEAPON_ORDER.size(),"forge exposes every weapon in paged arsenal tabs")
	check(w.hud.forge.get_global_rect().end.x<=1280 and w.hud.forge.get_global_rect().end.y<=720,"expanded forge fits 1280 by 720 viewport")
	w.hud.forge.tabs.get_child(0).current_tab=1;await capture("fort7_frontier_arsenal");w.toggle_pause()
	p.position=Vector3(0,0,100);w.recv_enemy(705,"Brute",Vector3(0,0,94),500);await physics_frame
	var hp_before:float=w.enemies[705].hp;w._fire_crossbow(p,Vector3.FORWARD,"Repeater")
	check(is_equal_approx(hp_before-w.enemies[705].hp,51),"masterwork Repeater applies real upgraded projectile damage")
	w.clock+=2;w._equip_weapon(1,"Pike");p.play_action("attack");check(p.animation_player.current_animation=="pike/Thrust","Pike uses its thrust animation")
	p.animation_player.play("crossbow/Aim");p.animation_player.advance(0)
	await process_frame
	check(p.weapon_visual.global_basis.y.normalized().dot(p.visual_root.global_basis.z.normalized())>.95,"Pike tip points in the dwarf's forward attack direction")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	var village:Dictionary=w.progression.sites[6];p.position=FortProgression.SITES[6].pos+Vector3(0,0,-2)
	w.progression.tick();check(w.progression.guarded(6),"approaching a village activates its treasure guards")
	var crystals:int=w.shared.crystal;w.progression.interact(1);check(w.shared.crystal==crystals and not village.opened,"guarded village chest cannot be looted early")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w.progression.interact(1);check(village.opened and w.shared.crystal==crystals+6,"cleared village awards shared supplies and spends lock crystals")
	camera.position=FortProgression.SITES[6].pos+Vector3(18,10,-18);camera.look_at(FortProgression.SITES[6].pos+Vector3(0,1,2));camera.current=true;await capture("fort7_village")
	# Doorway ray crosses the actual open front, not an invisible whole-house box.
	var origin:Vector3=FortProgression.SITES[6].pos+Vector3(0,1,1.5)
	await physics_frame
	var doorway:=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+Vector3(0,0,4.5),1))
	check(doorway.is_empty(),"village house doorway is physically open")
	w.hud.hide()
	var gallery:Array[Node3D]=[]
	for i in 3:
		var model:=FortArt.make_enemy(["Sapper","Cinderlobber","Bombwing"][i]);w.add_child(model);model.position=Vector3((i-1)*3.2,1.0 if i==2 else 0.0,145);gallery.append(model)
		FortArt.animate_enemy(model,0,false,true)
	camera.position=Vector3(7,3.8,155);camera.look_at(Vector3(0,1.25,145));await capture("fort7_siege_enemies")
	for model in gallery:model.queue_free()
	p.position=Vector3(0,0,145);p.visual_root.rotation=Vector3.ZERO;p.showing_tool=false;p.action_time=0;p._update_equipment_visibility()
	camera.position=Vector3(2.8,2.0,149);camera.look_at(p.position+Vector3.UP);camera.fov=42
	await capture("fort7_pike_ready")
	w.clock+=2;w._equip_weapon(1,"Repeater");await capture("fort7_repeater_ready")
	print("FORT7_RESULT ","PASS" if failures==0 else "FAIL"," ",failures)
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(0 if failures==0 else 1)
