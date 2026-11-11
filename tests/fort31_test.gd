extends SceneTree
# Fort 31 scaling and progression: raids that grow with the fort, elite raiders, one
# material per outer biome, and the hearth boons and upper upgrade levels they pay for.
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func tower(id:int,kind:String,at:Vector3,level:int)->void:
	w.recv_defense(id,kind,at,0.0,float(GameData.RECIPES[kind].hp),false);w.defenses[id].level=level
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24876;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	# --- raids grow with the fort
	check(FortBalance.strength(w)<60.0 and FortBalance.pressure(FortBalance.strength(w),1)==1.0,"a starting fort draws an ordinary raid")
	for i in 30:tower(500+i,"Watchtower",Vector3(14+(i%6)*3,0,14+(i/6)*3),3)
	var strong:=FortBalance.strength(w)
	check(strong>=590.0 and strong<=640.0,"thirty level-three watchtowers are worth about 600 strength (%d)"%roundi(strong))
	var power:=FortBalance.pressure(strong,1)
	check(power>2.0 and power<=2.25,"that fort more than doubles the raid at hearth 1 (x%.2f)"%power)
	check(FortBalance.pressure(strong,8)<power and FortBalance.pressure(99999.0,3)==2.25,"a higher hearth allows more fort for free, and the bonus is capped")
	for i in 20:tower(540+i,"CastleWall",Vector3(-20-i,0,20),1)
	check(FortBalance.strength(w)-strong==20.0,"walls count a point each")
	w.wave=5;w.is_night=true;w.phase_time=w.night_length(5)
	w.director.start()
	var base:=FortBalance.budget(5,1,1)
	check(w.director.power>2.0 and w.director.total==roundi(base*w.director.power),"the night's threat budget is multiplied by the fort's pressure")
	check(w.raid_cap()>FortBalance.active_cap(5,1) and w.raid_cap()<=140,"more raiders may be alive at once against a strong fort")
	check(w.director.status().contains("%") or w.director.pulse<0,"Siege Watch shows the bonus during an assault")
	w._spawn_enemy("Raider",1.0)
	var boosted:float=w.enemies[w.next_enemy_id-1].max_hp
	check(boosted>(55+5*6)*1.3,"raiders are tougher against a strong fort (%d health)"%roundi(boosted))
	var saved_state:=w.director.state();w.director.power=1.0;w.director.receive(saved_state)
	check(is_equal_approx(w.director.power,float(saved_state.power)) or w.director.revision>=int(saved_state.revision),"guests receive the raid's pressure")
	w.director.power=1.0;w.director.active=false
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	# --- elite raiders
	check(FortElites.chance(7,1.0)==0.0 and FortElites.chance(8,1.0)>0.0 and FortElites.chance(40,2.25)<=.3,"elites appear from night 8 and never dominate a wave")
	check(FortElites.cost("Raider")==22 and FortElites.cap(8,1)==2 and FortElites.cap(18,4)==7,"an elite costs more than twice the threat and has a head-count cap")
	w.wave=10
	w._spawn_enemy("Raider",0.5);var plain:Dictionary=w.enemies[w.next_enemy_id-1]
	w._spawn_enemy("Raider",0.5,"Ironhide");var iron:Dictionary=w.enemies[w.next_enemy_id-1]
	check(iron.get("elite","")=="Ironhide" and is_equal_approx(iron.max_hp,plain.max_hp*2.6),"an Ironhide has 2.6 times the health")
	check(iron.node.has_node("EliteCrest") and iron.node.has_node("EliteRing") and FortElites.title(iron)=="IRONHIDE RAIDER","it is marked with a crest, a ring and its name")
	w._spawn_enemy("Raider",0.5,"Frenzied");var frenzy:Dictionary=w.enemies[w.next_enemy_id-1]
	check(frenzy.speed>plain.speed*1.4 and float(frenzy.might)==1.5,"a Frenzied raider is faster and hits harder")
	w._spawn_enemy("Brute",0.5,"Warbanner");var banner:Dictionary=w.enemies[w.next_enemy_id-1];var banner_id:=w.next_enemy_id-1
	plain.node.position=banner.node.position+Vector3(3,0,0)
	var before:float=plain.hp;w._damage_enemy(w.enemies.find_key(plain),10.0)
	check(is_equal_approx(before-plain.hp,7.0),"raiders beside a Warbanner take 30% less damage")
	plain.node.position=banner.node.position+Vector3(30,0,0);before=plain.hp;w._damage_enemy(w.enemies.find_key(plain),10.0)
	check(is_equal_approx(before-plain.hp,10.0),"away from the banner they take full damage")
	check(w.full_state().swarm.any(func(row):return row.size()>=6 and row[5]=="Warbanner"),"elites travel with the world state")
	var crystal:=int(w.shared.crystal)
	w._damage_enemy(banner_id,999999.0)
	check(not w.enemies.has(banner_id) and int(w.shared.crystal)==crystal+2,"an elite pays the crew two crystal when it falls")
	w.recv_enemy(9900,"Raider",Vector3(30,0,30),100.0,-1,"Frenzied")
	check(w.enemies[9900].get("elite","")=="Frenzied" and w.enemies[9900].node.has_node("EliteCrest"),"a guest builds the same elite from the packet")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	for id in w.defenses.keys():w.recv_remove_defense(id,true)
	w.wave=20;w.is_night=true;w.phase_time=w.night_length(20);w.director.rng.seed=31;w.director.start()
	var spawned:=0
	for i in 700:
		w.director.tick(.35)
		for id in w.enemies.keys():
			if w.enemies[id].get("elite","")!="":spawned+=1
			w.recv_enemy_dead(id)
	check(spawned>0 and int(w.director.metrics.elites)==spawned and w.director.spent<=w.director.total,"a night-20 raid fields elites within its budget (%d of %d raiders)"%[spawned,int(w.director.metrics.spawned)])
	w.director.finish();w.is_night=false;w.wave=3
	# --- one material per outer biome
	var stock:=GameData.stock({"wood":1})
	check(stock.size()==10 and GameData.RESOURCES.size()==10 and GameData.RARE.size()==5,"ten materials: five everyday, five from the outer biomes")
	var ranks:Array=[]
	for rank in range(1,6):ranks.append(w.expedition.rare(rank))
	var sorted_ranks:=ranks.duplicate();sorted_ranks.sort();var all_rare:=GameData.RARE.duplicate();all_rare.sort()
	check(sorted_ranks==all_rare and w.expedition.rare_rank(ranks[2])==3,"each expedition orders the five materials by its own biomes")
	w.set_hearth_level(3)
	check(not w.expedition.has_rare(ranks[0]),"none is available before hearth 4")
	w.set_hearth_level(4)
	var found:=0;var node_id:=-1
	for id in w.resource_nodes:
		if w.resource_nodes[id].kind==ranks[0]:found+=1;node_id=id
	check(found==12 and w.expedition.has_rare(ranks[0]) and not w.expedition.has_rare(ranks[1]),"the hearth 4 biome grows twelve deposits of its own material")
	p.position=w.resource_nodes[node_id].node.position+Vector3(1,0,0);w.cooldowns.clear()
	w._gather(1,node_id)
	check(int(p.carrying.get(ranks[0],0))>=2,"it is gathered into the pack like anything else")
	w._deposit(1)
	check(int(w.shared[ranks[0]])>=2 and FortGlyphs.g(ranks[0]).length()==1 and FortGlyphs.g(ranks[0])!=ranks[0],"it is deposited into shared stock and has its own symbol")
	# --- what the materials buy
	tower(700,"Watchtower",Vector3(12,0,-12),4)
	var temper:Dictionary=w.progression.upgrade_cost(700)
	check(int(temper.get(ranks[0],0))==3,"reinforcing a tower past level 4 needs the first biome's material")
	w.defenses[700].level=6
	check(int(w.progression.upgrade_cost(700).get(ranks[2],0))==7,"each level above wants the next biome's")
	var next:Dictionary=w.expedition.upgrade_cost(4)
	check(int(next.get(ranks[0],0))==8 and not w.expedition.upgrade_cost(3).has(ranks[0]),"the hearth itself needs it to reach tier 5")
	w.shared=GameData.stock({"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000})
	p.position=Vector3(0,FortCastle.BASE,2);w.cooldowns.clear();w._upgrade_hearth(1,4)
	check(w.hearth_level==4,"the hearth will not rise to tier 5 without it")
	w.shared[ranks[0]]=40;w.cooldowns.clear();w._upgrade_hearth(1,4)
	check(w.hearth_level==5 and int(w.shared[ranks[0]])==32,"with eight of it, tier 5 opens")
	# --- hearth boons
	w.cooldowns.clear();FortAttune.request(w,1,ranks[4],0)
	check(FortAttune.rank(w,ranks[4])==0,"a boon cannot be bought from a biome the hearth has not reached")
	for kind in GameData.RARE:w.shared[kind]=100
	w.set_hearth_level(8)
	for kind in GameData.RARE:
		w.cooldowns.clear();FortAttune.request(w,1,kind,0)
	check(GameData.RARE.all(func(kind):return FortAttune.rank(w,kind)==1) and int(w.shared.resin)==94,"each material buys the first rank of its own boon for 6")
	check(is_equal_approx(FortAttune.repair_multiplier(w),1.25) and is_equal_approx(FortAttune.tower_multiplier(w),1.08) and is_equal_approx(FortAttune.gather_chance(w),.25),"repair, tower damage and gathering boons take effect")
	var hearth:=w.fort_health;w.damage_fort(100.0)
	check(is_equal_approx(hearth-w.fort_health,88.0),"Frostglass Ward shields the hearth")
	p.health=50.0;w.clock+=5.0;w.set_process(true);await process_frame;await process_frame;w.set_process(false)
	check(p.health>50.0,"Glowspore Salve mends dwarves over time")
	w.cooldowns.clear();FortAttune.request(w,1,"cinder",1);w.cooldowns.clear();FortAttune.request(w,1,"cinder",2);w.cooldowns.clear();FortAttune.request(w,1,"cinder",3)
	check(FortAttune.rank(w,"cinder")==3 and is_equal_approx(FortAttune.tower_multiplier(w),1.24),"boons stop at rank three")
	var carried:=w.expedition.state();w.expedition.attune={};w.expedition.receive(carried)
	check(FortAttune.rank(w,"cinder")==3,"boons travel with the expedition state")
	# --- saves
	var state:=FortSave.capture(w)
	check(FortSave.validate(state)=="","a checkpoint with biome materials and boons validates")
	for kind in GameData.RARE:state.world.shared.erase(kind)
	check(FortSave.validate(state)=="" and GameData.stock(state.world.shared).size()==10,"a checkpoint from before Fort 31 still loads, with the new materials at zero")
	print("FORT31_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
