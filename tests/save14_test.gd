extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func run()->void:
	FortSave.test_directory="res://build/save14_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24687;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.set_hearth_level(4);w.shared={"wood":1000,"stone":1000,"crystal":100,"iron":100,"aether":100}
	for id in w.resource_nodes:w.recv_resource(id,0,false);w.resource_nodes[id].respawn=123.0
	w.scenery_keepouts.clear();p.position=w.castle.rooms["0:0:0"].sign
	w.castle.plan(1,"0:0:0",{"x":1,"z":0,"floor":0},"Research",w.castle.revision)
	p.position=w.castle.rooms["1:0:0"].sign;p.carrying={"wood":7};w.castle.fund(1,"1:0:0",false,w.castle.revision)
	w.castle.research=PackedStringArray(["Logistics"]);w.castle.revision+=1
	w.recv_defense(700,"Watchtower",Vector3(8,.6,0),.7,300,false)
	w.defenses[700].hp=117;w.defenses[700].level=2;w.next_defense_id=701
	p.owned_weapons=PackedStringArray(["Axe","Crossbow"]);p.equip_weapon("Crossbow");p.loadout_revision=5
	p.apply_progression(2,PackedStringArray(["Ironheart"]),true,4);p.apply_weapon_levels({"Crossbow":2},4)
	p.health=65;p.carrying={"wood":11,"iron":3};p.position=Vector3(2,.6,5);p.look_yaw=.4;p.fuel=45
	w.add_network_player(22,{"name":"Former guest","class":1});w.players[22].health=49;w.players[22].carrying={"stone":9};w.recv_remove_player(22)
	w.pets._create(1,0,Vector3(19,0,9));w.pets.pets[1].node.position=Vector3(21,0,10);w.pets.pets[1].cargo=6;w.pets.pets[1].resource="stone";w.pets.next_id=2
	w.wave=10;w.is_night=true;w.phase_time=87.5;w.clock=1234.0;w.director.start();w.director.elapsed=40;w.director.spent=55;w.director.reports.append({"night":9,"killed":80})
	w.recv_enemy(900,"Sapper",Vector3(70,0,2),150);w.enemies[900].hp=73;w.enemies[900].fuse_at=1235.0;w.next_enemy_id=901
	w.expedition.bosses_defeated=1;w.expedition.event_claimed=true
	var site_id:int=w.encounters.sites.keys()[0];w.encounters.sites[site_id].phase="claimed";w.encounters.sites[site_id].seen=true;w.encounters.revision+=1
	var seed_value:=w.expedition.seed_value;var rng_state:=w.director.rng.state
	check(FortSave.write_slot("slot1",w)=="","host writes a verified checkpoint")
	var first:=FortSave.read_slot("slot1");check(first.error=="","checkpoint reads with checksum and schema validation")
	if first.error!="":print(first);quit(1);return
	var invalid:Dictionary=first.data.duplicate(true);invalid.schema=999;check(FortSave.validate(invalid)!="","unsupported format rejected")
	invalid=first.data.duplicate(true);invalid.characters[0]=false;check(FortSave.validate(invalid)!="","malformed nested dwarf rejected without a crash")
	check(FortSave.read_slot("../outside").error!="","slot traversal rejected")
	w.shared.wood=888;check(FortSave.write_slot("slot1",w)=="","second save rotates a verified backup")
	check(FortSave.read_file(FortSave.path("slot1")+".bak").data.world.shared.wood==1000,"backup retains previous stockpile")
	var corrupt:=FileAccess.open(FortSave.path("slot1"),FileAccess.WRITE);corrupt.store_string("interrupted write");corrupt.close()
	var recovered:=FortSave.read_slot("slot1");check(recovered.error=="" and recovered.get("recovered",false),"damaged primary recovers the verified backup")
	main._leave_game("test reload");await create_timer(.1).timeout;main.port_edit.value=24687;main.load_expedition("slot1")
	check(main.lobby_active and not is_instance_valid(main.world),"loading opens a lobby without advancing the saved world")
	main._start_match();w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.hearth_level==4 and w.expedition.seed_value==seed_value,"hearth, map seed and biome ordering restored")
	check(w.is_night and w.wave==10 and is_equal_approx(w.phase_time,87.5) and is_equal_approx(w.clock,1234),"midnight clock restored without an opening-day reset")
	check(is_equal_approx(w.sun.light_energy,.23) and w.sky_material.sky_top_color.r>=0,"restored night lighting does not overshoot into invalid colors")
	check(w.director.spent==55 and w.director.elapsed==40 and w.director.rng.state==rng_state and w.director.reports.size()==1,"raid budget, random state and history resume")
	check(w.castle.rooms["1:0:0"].funded.wood==7 and not w.castle.rooms["1:0:0"].complete,"unfinished castle funding survives")
	check(w.castle.pack_bonus()==6 and p.carry_limit==52,"castle research and backpack capacity survive")
	check(w.defenses[700].hp==117 and w.defenses[700].level==2 and w.next_defense_id==701,"building health, upgrades and next ID survive")
	check(p.health==65 and p.weapon=="Crossbow" and p.weapon_levels.Crossbow==2 and p.armor and p.carrying.iron==3,"dwarf health, weapons, upgrades, armor and pack contents survive")
	check(p.position.is_equal_approx(Vector3(2,.6,5)) and is_equal_approx(p.look_yaw,.4) and p.fuel==45,"dwarf location, view and travel fuel survive")
	w.add_network_player(99,{"name":"Returning guest","class":1})
	check(w.players[99].health==49 and w.players[99].carrying.stone==9,"disconnected dwarf progress follows class, not network ID")
	w.recv_remove_player(99)
	check(w.pets.pets[1].cargo==6 and w.pets.pets[1].resource=="stone" and w.pets.pets[1].node.position.is_equal_approx(Vector3(21,0,10)),"pet assignment, cargo and actual location survive")
	check(w.enemies[900].hp==73 and w.enemies[900].fuse_at==0 and w.next_enemy_id==901,"enemy health survives and explosives must re-telegraph")
	check(w.encounters.sites[site_id].phase=="claimed" and w.expedition.event_claimed and w.expedition.bosses_defeated==1,"claimed treasures and boss history survive without duplicate rewards")
	var resource:Dictionary=w.resource_nodes.values()[0];check(resource.amount==0 and resource.respawn==123,"depleted resources retain their respawn timer")
	w.autosave_enabled=true;w._advance_phase();w.autosave_enabled=false
	check(FortSave.read_slot("autosave").error=="" and not FortSave.read_slot("autosave").data.world.night,"dawn creates a separate autosave")
	main.save_menu.open_panel(true);await create_timer(.1).timeout
	check(main.save_menu.panel.visible and main.save_menu.slots.get_child_count()==3,"host save menu shows three manual slots")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/save14_menu.png"))
	main.save_menu.choose("slot1")
	check(main.save_menu.confirm_slot=="slot1" and FortSave.read_slot("slot1").data.world.night,"occupied backup recovery slot requires overwrite confirmation")
	main.save_menu.choose("slot1")
	check(not FortSave.read_slot("slot1").data.world.night and FortSave.read_file(FortSave.path("slot1")+".bak").data.world.night,"confirmed overwrite replaces damaged primary without losing good backup")
	main.save_menu.close_panel();main.save_and_leave();await create_timer(.1).timeout
	check(not is_instance_valid(main.world) and FortSave.read_slot("exit").error=="","save and leave commits checkpoint before returning to title")
	main.save_menu.open_panel(false);await create_timer(.1).timeout
	check(main.save_menu.slots.get_child_count()==5,"load menu includes manual, dawn and exit checkpoints")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/save14_load.png"))
	main.queue_free();await create_timer(.1).timeout
	print("SAVE14_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
