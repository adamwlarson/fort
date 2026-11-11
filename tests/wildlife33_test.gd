extends SceneTree
# Fort 33 wildlife and cooking: where each species lives, how each temperament behaves,
# what they drop and how it reaches the stockpile, the cooking pot, every dish and its
# timed boost, and that raids, towers and saves treat animals correctly.
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
## Run the host simulation for a while with the dwarf standing still.
func simulate(seconds:float)->void:
	var frames:=int(seconds*60.0)
	for i in frames:
		await physics_frame
		w.clock+=1.0/60.0;w._simulate_enemies(1.0/60.0)
func one(kind:String,at:Vector3)->Dictionary:
	w.wildlife.rng.seed=7
	var ids:=w.wildlife.spawn_group(kind,FortGround.on(at,.05))
	for i in range(1,ids.size()):w.recv_enemy_dead(ids[i])
	var e:Dictionary=w.enemies[ids[0]];e.node.position=FortGround.on(at,.05);e.home=e.node.position;e.think_at=w.clock+99.0;e.goal=e.node.position
	return e
func clear()->void:
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	p.health=p.max_health;p.invulnerable=0.0
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24879;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	await physics_frame;await physics_frame
	# --- materials
	check(GameData.FOOD.size()==6 and GameData.MEALS.size()==6 and GameData.stock().size()==22,"six kinds of game and six meals join the stockpile")
	check(GameData.FOOD.all(func(kind):return FortGlyphs.g(kind).length()==1) and GameData.MEALS.all(func(kind):return FortGlyphs.g(kind).length()==1),"each has its own symbol")
	check(not w.wildlife.enabled and w.enemies.is_empty(),"automated worlds start without wildlife")
	# --- where things live
	check(not w.wildlife.band("Rabbit").is_empty() and not w.wildlife.band("Deer").is_empty() and not w.wildlife.band("Boar").is_empty(),"rabbits, deer and boar live in the first ring")
	check(w.wildlife.band("Fox").is_empty() and w.wildlife.band("Yak").is_empty() and w.wildlife.band("Tortoise").is_empty(),"foxes, yaks and the exotic beasts are further out")
	w.wildlife.enabled=true;w.clock=2.0;w.wildlife.next_check=0.0
	for i in 12:w.wildlife.next_check=0.0;w.wildlife.tick()
	var counts:Dictionary={};var stray:=0;var wet:=0
	for e in w.enemies.values():
		counts[e.kind]=int(counts.get(e.kind,0))+1
		var r:=Vector2(e.node.position.x,e.node.position.z).length()
		if r<30.0 or r>76.0:stray+=1
		if FortGround.wet(e.node.position.x,e.node.position.z):wet+=1
	check(int(counts.get("Rabbit",0))>=6 and int(counts.get("Deer",0))>=4 and int(counts.get("Boar",0))>=2 and counts.size()==3,"the meadow fills with rabbits, deer and boar (%s)"%str(counts))
	check(stray==0 and wet==0,"they arrive inside their ring, on dry land")
	check(w.director.population().all==0 and w._nearest_enemy(Vector3.ZERO,400.0)<0,"raids do not count animals and towers do not target them")
	w.wildlife.enabled=false;clear()
	# --- temperaments
	var meadow:=Vector3(0,0,58)
	var rabbit:=one("Rabbit",meadow)
	check(rabbit.get("fauna",false) and int(rabbit.camp)==FortWildlife.CAMP and FortWildlife.title(rabbit)=="Rabbit" and (rabbit.node.get_child(0).shape as CapsuleShape3D).radius<.25,"a rabbit is a small, named animal")
	p.position=FortGround.on(meadow+Vector3(5,0,0),.1)
	await simulate(2.5)
	check(rabbit.node.position.distance_to(p.position)>14.0,"skittish: a rabbit bolts from a dwarf (%.0f m away)"%rabbit.node.position.distance_to(p.position))
	clear()
	p.position=FortGround.on(meadow+Vector3(40,0,0),.1)
	w.wildlife.rng.seed=11;var herd:=w.wildlife.spawn_group("Deer",FortGround.on(meadow,.05))
	check(herd.size()>=3,"deer come in a herd")
	w._damage_enemy(herd[0],5.0)
	var startled:=0
	for id in herd:
		if w.clock<float(w.enemies[id].get("panic_until",0.0)):startled+=1
	check(startled==herd.size(),"herd: striking one deer startles them all")
	var start:Vector3=w.enemies[herd[1]].node.position
	await simulate(2.0)
	check(w.enemies[herd[1]].node.position.distance_to(start)>8.0,"and the whole herd runs")
	check(w.enemies[herd[0]].hp<55.0,"animals take weapon damage")
	var before:float=w.enemies[herd[1]].hp;w._damage_enemy(herd[1],40.0,Vector3.ZERO,"tower_damage")
	check(w.enemies[herd[1]].hp==before,"towers never harm wildlife")
	clear()
	var boar:=one("Boar",meadow)
	p.position=FortGround.on(meadow+Vector3(5,0,0),.1)
	await simulate(.6)
	check(boar.get("warned",false) and p.health==p.max_health,"territorial: a boar snorts a warning first")
	await simulate(4.0)
	check(p.health<p.max_health,"then charges anyone who stays (dwarf at %d health)"%int(p.health))
	clear()
	var ram:=one("Ram",meadow)
	p.position=FortGround.on(meadow+Vector3(3,0,0),.1)
	await simulate(2.5)
	check(p.health==p.max_health and ram.node.position.distance_to(FortGround.on(meadow,.05))<2.0,"stubborn: a ram ignores a dwarf beside it")
	w._damage_enemy(w.enemies.find_key(ram),5.0)
	await simulate(3.0)
	check(p.health<p.max_health,"until it is struck, and then it butts back")
	clear()
	var tortoise:=one("Tortoise",meadow)
	p.position=FortGround.on(meadow+Vector3(3,0,0),.1)
	var shell_id:int=w.enemies.find_key(tortoise)
	w._damage_enemy(shell_id,40.0);var first:float=320.0-tortoise.hp
	w._damage_enemy(shell_id,40.0);var second:float=320.0-first-tortoise.hp
	check(is_equal_approx(first,40.0) and is_equal_approx(second,12.0),"placid: a struck tortoise pulls into its shell and shrugs off 70% of blows")
	await simulate(1.0)
	check(tortoise.node.position.distance_to(FortGround.on(meadow,.05))<.5 and p.health==p.max_health,"and neither runs nor fights")
	clear()
	var fox:=one("Fox",meadow)
	p.position=FortGround.on(meadow+Vector3(14,0,0),.1)
	await simulate(3.0)
	var gap:float=fox.node.position.distance_to(p.position)
	check(gap<11.0 and gap>5.0,"curious: a fox trails a dwarf and watches from a distance (%.1f m)"%gap)
	p.position=FortGround.on(fox.node.position+Vector3(2.5,0,0),.1)
	await simulate(1.5)
	check(fox.node.position.distance_to(p.position)>7.0,"and runs if the dwarf walks up to it")
	clear()
	var lizard:=one("Salamander",meadow)
	p.position=FortGround.on(meadow+Vector3(8,0,0),.1)
	await simulate(4.0)
	check(p.health<p.max_health,"aggressive: a cinder salamander hunts a dwarf on its ground")
	clear()
	# --- game is dropped, carried home and deposited
	var deer:=one("Deer",meadow);var deer_at:Vector3=deer.node.position
	p.position=FortGround.on(meadow+Vector3(30,0,0),.1)
	w._damage_enemy(w.enemies.find_key(deer),999.0)
	var pile:Dictionary={}
	for drop in w.pieces.drops.values():
		if drop.pos.distance_to(deer_at)<3.0:pile=drop
	check(not pile.is_empty() and int(pile.stock.get("venison",0))>=1,"a slain deer leaves venison on the ground")
	p.carrying={"wood":0,"stone":0,"crystal":0};p.position=pile.pos+Vector3(.5,0,0);w.pieces.tick_drops()
	check(int(p.carrying.get("venison",0))>=1,"walking over it puts it in the pack")
	var carried:=int(p.carrying.venison);w._deposit(1)
	check(int(w.shared.venison)==carried and p.total_carried()==0,"and it is deposited into shared stock like any other material")
	var exotic:=one("Amberstag",meadow);w._damage_enemy(w.enemies.find_key(exotic),9999.0)
	var amber:=false
	for drop in w.pieces.drops.values():
		if int(drop.stock.get("resin",0))>0:amber=true
	check(amber,"an amber stag also drops amber resin")
	# --- the cooking pot
	check("CookingPot" in GameData.BUILD_ORDER and w.build_tabs()[1]=="CAMP","the cooking pot is in the build menu")
	p.position=Vector3(0,FortCastle.BASE,4)
	check(FortCooking.nearest(w,p.position)<0,"there is no pot until one is built")
	w.shared=GameData.stock({"wood":200,"stone":200});w._spawn_defense("CookingPot",Vector3(14,0,14),0,false)
	var pot_id:=w.next_defense_id-1
	check(w.defenses.has(pot_id) and w.defenses[pot_id].node.has_node("Stew"),"a pot can be built on open ground")
	p.position=Vector3(15.5,0,14)
	check(FortCooking.nearest(w,p.position)==pot_id and w.context_prompt(p).contains("Cooking pot"),"a dwarf beside it is offered the pot")
	w.cooldowns.clear();FortCooking.cook(w,1,"stew")
	check(int(w.shared.stew)==0,"a dish cannot be cooked without its game")
	w.shared.meat=5;w.cooldowns.clear();FortCooking.cook(w,1,"stew")
	check(int(w.shared.stew)==2 and int(w.shared.meat)==3 and int(w.shared.wood)==199,"two game meat and a log make two servings of stew")
	p.health=40.0;w.cooldowns.clear();FortCooking.eat(w,1,"stew")
	check(is_equal_approx(p.health,100.0) and int(w.shared.stew)==1 and FortCooking.has(p,"hearty"),"eating restores 60 health and starts the boost")
	check(w.snapshot().players[1].buffs.has("hearty"),"boosts travel to every machine")
	w.set_process(true)
	for i in 80:await process_frame
	w.set_process(false)
	check(p.health>100.0 and float(p.buffs.hearty)<180.0,"Hearty mends the dwarf while it counts down (%d health)"%int(p.health))
	p.buffs.hearty=.01;w.set_process(true);await process_frame;await process_frame;w.set_process(false)
	check(not FortCooking.has(p,"hearty"),"and it ends")
	p.position=Vector3(40,0,40);w.cooldowns.clear();FortCooking.eat(w,1,"stew")
	check(int(w.shared.stew)==1,"meals are eaten at the pot, not in the field")
	p.position=Vector3(15.5,0,14)
	for kind in GameData.FOOD:w.shared[kind]=20
	for dish in FortCooking.DISHES:
		w.cooldowns.clear();FortCooking.cook(w,1,dish);w.cooldowns.clear();FortCooking.eat(w,1,dish)
	check(FortCooking.DISHES.keys().all(func(dish):return FortCooking.has(p,str(FortCooking.DISHES[dish].buff))),"all six dishes can be cooked and their boosts held at once")
	check(FortCooking.summary(p).contains("Fleet") and FortCooking.summary(p).contains(":"),"the HUD line lists boosts with their time left")
	var plain:=p.weapon_power("Axe");p.buffs.erase("fiery")
	check(is_equal_approx(plain,p.weapon_power("Axe")*1.25),"Embertail Skewers: +25% weapon damage")
	p.health=100.0;p.invulnerable=0.0;w._set_health(1,60.0)
	check(is_equal_approx(p.health,70.0),"Frost Hotpot: a 40-point blow lands for 30")
	var quick:=FortStats.gather_multiplier(p);p.buffs.erase("bountiful")
	check(is_equal_approx(quick,FortStats.gather_multiplier(p)*.8),"Sunhorn Platter: gathering is 20% faster")
	check(FortCooking.regeneration(p)==6.0,"Hunter's Stew and Glowcap Broth mend together")
	# --- unlocks and saves
	w.set_hearth_level(3)
	check(not w.wildlife.band("Fox").is_empty() and not w.wildlife.band("Yak").is_empty() and w.wildlife.band("Salamander").is_empty(),"foxes, rams, stags and yaks arrive with the second and third rings")
	w.set_hearth_level(8)
	check(["Amberstag","Tortoise","Salamander","Frosthare","Sunhorn"].all(func(kind):return not w.wildlife.band(kind).is_empty()),"each outer biome brings its own beast")
	one("Yak",Vector3(0,0,190))
	var state:=FortSave.capture(w)
	check(FortSave.validate(state)=="" and state.enemies.values().any(func(e):return e.kind=="Yak" and e.get("fauna",false)),"wildlife, meals and the pot are saved")
	print("WILDLIFE33_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
