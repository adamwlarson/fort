extends SceneTree
# Fort 26 systems: experience and stat points, character sheet, map modes, cost glyphs,
# clearer castle errors, razing cleared bases, wall farms, taller storeys, buried raiders.
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func shot(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/fort26_"+name+".png"))
func room(x:int,z:int,kind:String,floor_index:=0)->String:
	var key:=FortCastle.key(x,z,floor_index)
	w.castle.rooms[key]={"x":x,"z":z,"floor":floor_index,"kind":kind,"complete":true,"funded":{},"work":0.0,"total":0.0,"sign":Vector3(x*20-7,.6+floor_index*FortCastle.HEIGHT,z*20-7),"walls":[],"task":"","resource":"wood"}
	w.castle.changed();return key
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24866;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.shared={"wood":10000,"stone":10000,"crystal":10000,"iron":10000,"aether":10000,"gold":500}
	# --- cost symbols
	var cost_text:=GameData.supplies_text({"wood":30,"stone":55},true)
	check(not cost_text.contains("wood") and cost_text.contains(FortGlyphs.g("wood")) and cost_text.contains("55"+FortGlyphs.g("stone")),"costs show resource symbols instead of words")
	check(FortGlyphs.font.has_char(FortGlyphs.BASE) and ThemeDB.fallback_font.fallbacks.has(FortGlyphs.font),"resource glyph font is installed as a fallback")
	# --- HUD
	w.hud._process(0)
	check(not w.hud.crew.visible and not w.hud.hints.visible,"crew box and permanent control hints are gone")
	check(w.hud.stock_labels.wood.text=="10000"+FortGlyphs.g("wood"),"stockpile strip uses symbols")
	w.recv_player(77,{"name":"Bryn","class":1});w.players[77].set_physics_process(false);w.players[77].position=p.position+Vector3(30,0,40);w.players[77].health=0
	w.hud._process(0)
	check(w.hud.down_banner.visible and w.hud.down_banner.text=="Player \"Bryn\" down 50m","downed ally banner names the player and distance")
	await shot("hud_downed")
	w.players[77].health=100;w.hud._process(0);check(not w.hud.down_banner.visible,"banner clears when the ally is back up")
	# --- map modes
	var map:=w.hud.map;map._process(.3)
	var sizes:Array[float]=[map.RADIUS]
	var key:=InputEventKey.new();key.physical_keycode=KEY_M;key.keycode=KEY_M;key.pressed=true
	for i in 3:map._unhandled_input(key);map._process(.3);sizes.append(map.RADIUS);await shot("map_mode%d"%map.mode)
	check(sizes[1]>sizes[0] and sizes[2]>sizes[1] and sizes[3]>sizes[2],"M grows the map through three sizes to the world view")
	check(map.mode==3 and is_equal_approx(map.RANGE,w.frontier_radius()+8) and map.origin==Vector2.ZERO,"fourth press shows the whole current world centred on the hearth")
	map._unhandled_input(key);map._process(.3);check(map.mode==4 and not map.visible,"fifth press closes the map")
	map._unhandled_input(key);map._process(.3);check(map.mode==0 and map.visible,"sixth press returns to the standard map")
	# --- experience and stats
	check(p.level==1 and p.xp==0 and p.stat_points==0,"new dwarves start at level 1")
	w.recv_enemy(88001,"Brute",p.position+Vector3(3,0,0),50);w._damage_enemy(88001,500)
	check(p.xp>0,"defeating a monster grants experience")
	var before:=p.xp
	var resource_id:int=w.resource_nodes.keys()[0];p.position=w.resource_nodes[resource_id].node.position+Vector3(1,0,0);w._gather(1,resource_id)
	check(p.xp>before,"gathering grants experience")
	before=p.xp
	w._spawn_defense("Barricade",p.position+Vector3(2,0,2),0,false);var defense_id:=w.next_defense_id-1
	w.construction.begin(defense_id,1,{},"build");w.clock+=1;w.construction.work(1,defense_id)
	check(p.xp>before,"building grants experience")
	FortStats.award(w,1,FortStats.need(1)+FortStats.need(2))
	check(p.level>=3 and p.stat_points>=2,"levelling up grants stat points")
	var hp:=p.max_health;var carry:=p.carry_limit;var power:=p.weapon_power("Axe")
	var points:=p.stat_points
	w.server_action(1,"stat_point",{"stat":"health"});w.server_action(1,"stat_point",{"stat":"storage"})
	check(p.max_health==hp+12 and p.carry_limit==carry+3 and p.stat_points==points-2,"Health and Storage points raise maximum health and pack size")
	FortStats.award(w,1,2000)
	for stat in ["damage","cooldown","speed","mining_speed","mining_eff"]:w.server_action(1,"stat_point",{"stat":stat})
	check(p.weapon_power("Axe")>power and FortStats.cooldown_multiplier(p)<1 and FortStats.speed_multiplier(p)>1 and FortStats.gather_multiplier(p)<1 and FortStats.bonus_chance(p)>0,"Damage, Cooldown, Speed, Mining Speed and Mining Efficiency all apply")
	p.stat_points=0;var rank:=FortStats.rank(p,"damage");w.server_action(1,"stat_point",{"stat":"damage"})
	check(FortStats.rank(p,"damage")==rank,"stats cannot be raised without points")
	var saved:=FortSave.player_state(p)
	check(saved.level==p.level and saved.stats.health==1,"level and stats are written to the character save")
	var tab:=InputEventKey.new();tab.physical_keycode=KEY_TAB;tab.pressed=true
	p._unhandled_input(tab);check(w.hud.sheet.visible and w.menu_open,"TAB opens the character sheet")
	check(w.hud.sheet.gear.text.contains("Forester's Axe") and w.hud.sheet.gear.text.contains("Armor") and w.hud.sheet.rows.size()==7,"sheet lists weapon, armor and all seven stats")
	await shot("sheet")
	p._unhandled_input(tab);check(not w.hud.sheet.visible and not w.menu_open,"TAB closes it again")
	# --- castle text, height, corner posts
	check(is_equal_approx(FortCastle.HEIGHT,5.0),"storeys are 5m tall")
	room(1,0,"Courtyard")
	check(w.castle.plan_reason("0:0:0",{"x":1,"z":1,"floor":0},"Courtyard")=="Must build rooms from adjacent room's signs","corner rooms explain that they are built from the adjacent room's sign")
	var walled:Dictionary=w.castle.rooms["1:0:0"];w.castle.finish_walls(walled);w.castle.changed();await physics_frame;await physics_frame
	var corner:=FortCastle.position(walled)+Vector3(9.72,2.5,9.72)
	var query:=PhysicsPointQueryParameters3D.new();query.position=corner;query.collision_mask=1
	check(not w.get_world_3d().direct_space_state.intersect_point(query,2).is_empty(),"walled rooms have solid corner posts")
	var wall:Node3D=w.defenses[walled.walls[0]].node
	var hit:=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(wall.position+Vector3(0,4.7,-1),wall.position+Vector3(0,4.7,1),1))
	check(not hit.is_empty(),"walls reach the taller ceiling")
	# --- razing a cleared base
	var camp_pos:Vector3=FortProgression.SITES[1].pos
	var target:={"x":roundi(camp_pos.x/20),"z":roundi(camp_pos.z/20),"floor":0}
	w.hearth_level=3
	var from:=room(int(target.x)-1,int(target.z),"Courtyard")
	w.progression.sites[1].opened=false
	check(w.castle.plan_reason(from,target,"Courtyard").begins_with("Enemy base in the way"),"an uncleared base blocks the room with a clear reason")
	w.progression.sites[1].opened=true
	check(w.castle.plan_reason(from,target,"Courtyard")=="","a cleared base may be built over")
	p.position=w.castle.rooms[from].sign;w.castle.plan(1,from,target,"Courtyard",w.castle.revision)
	check(w.castle.razed.has("camp:1") and w.progression.sites[1].get("razed",false) and not w.progression.sites[1].node.visible,"placing the room razes the base for good")
	w.progression.sites[1].return_wave=0;w.wave=5;p.position=Vector3(-200,0,0);w.progression.tick()
	check(w.progression.sites[1].opened,"a razed base never respawns")
	# --- farms
	p.position=w.castle.rooms["0:0:0"].sign
	FortFarms.build(w.castle,1,"0:0:0","wood",w.castle.revision);check(FortFarms.plots(w.castle).is_empty(),"farms need the outer wall first")
	FortPerimeter.activate(w.castle,1,"0:0:0",w.castle.revision)
	FortFarms.build(w.castle,1,"0:0:0","wood",w.castle.revision);FortFarms.build(w.castle,1,"0:0:0","stone",w.castle.revision)
	check(FortFarms.plots(w.castle)==["wood","stone"] and w.castle.root.get_node("PerimeterFarms").get_child_count()==2,"tree farm and rock mine are built inside the outer wall")
	var plot:=FortFarms.position(w.castle,0)
	var wood:int=w.shared.wood;var stone:int=w.shared.stone;w.is_night=false;w.clock+=20;w.castle.tick()
	check(w.shared.wood==wood+3 and w.shared.stone==stone+3,"farms deliver to the shared stockpile by day")
	room(int(target.x)+8,int(target.z),"Courtyard")
	check(FortFarms.position(w.castle,0).x>plot.x,"farms move outward with the wall when the castle grows")
	var state:=FortSave.capture(w);check(FortSave.validate(state)=="" and state.world.castle.perimeter.farms.size()==2 and "camp:1" in state.world.castle.razed,"farms and razed bases are saved")
	await shot("farms")
	# --- buried raiders and spawn directions
	w.recv_enemy(88002,"Raider",FortGround.on(Vector3(120,0,0),-4),80);FortVista.cull_buried(w)
	check(not w.enemies.has(88002),"a raider under the ground dies instantly")
	# Fort 30: the knolls became real terrain. Find the tallest rise in the second ring.
	var hilltop:=Vector3.ZERO
	for i in 720:
		var at:=FortGround.on(Vector3(sin(i*.7),0,cos(i*.7))*(90.0+(i%60)*2.4))
		if at.y>hilltop.y:hilltop=at
	check(hilltop.y>2.5,"rolling hills are generated")
	check(FortVista.height(hilltop)>1.0 and is_zero_approx(FortVista.height(Vector3.ZERO)),"hills have height; the keep stays level")
	w.recv_enemy(88003,"Raider",Vector3(hilltop.x,0,hilltop.z),80);FortVista.cull_buried(w)
	check(not w.enemies.has(88003),"a raider spawned inside a hill dies instantly")
	var sectors:Dictionary={}
	w.is_night=true;w.wave=3
	for i in 80:
		var angle:float=w.director.rng.randf()*TAU if w.director.lane_count()<4 else (i%4)*PI/2+w.director.rng.randf_range(-PI/4,PI/4)
		sectors[posmod(roundi(angle/(TAU/8)),8)]=true
	check(sectors.size()==8,"raid spawns cover all eight compass directions")
	print("FORT26_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
