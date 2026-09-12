extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func capture(key:String)->void:
	await wait(.18)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.encounters.sites.size()==3,"new expedition starts with three additional exploration sites")
	w.expedition.configure(909);w.set_hearth_level(8)
	check(w.encounters.sites.size()==67 and w.progression.sites.size()==9,"full frontier has 67 new sites plus nine existing treasure sites")
	check(w.resource_nodes.keys().filter(func(id):return int(id)<10000).size()==594,"site clearings preserve all harvest nodes")
	check(FortEncounters.layout(909)==FortEncounters.layout(909) and FortEncounters.layout(909)!=FortEncounters.layout(911),"site layout is seeded, reproducible and varies between expeditions")
	var seeds_clear:=true
	for seed_value in range(40):
		var layout:=FortEncounters.layout(seed_value)
		for first in layout:
			for second in layout:
				if first.id!=second.id and first.pos.distance_to(second.pos)<29:seeds_clear=false
	check(seeds_clear,"forty world seeds keep encounter footprints separate")
	var spacing:=true;var reservations:=true
	for id in w.encounters.sites:
		var site:Dictionary=w.encounters.sites[id]
		for other in w.encounters.sites:
			if id!=other and site.spec.pos.distance_to(w.encounters.sites[other].spec.pos)<29:spacing=false
		if site.spec.tier<2:continue
		for r in w.resource_nodes.values():
			if r.node.position.distance_to(site.spec.pos)<site.spec.radius+1.9:reservations=false
	check(spacing,"exploration sites have separate footprints")
	check(reservations,"outer harvest resources do not intersect encounter clearings")
	for kind in FortEncounters.CREATURES:
		var model:=FortArt.asset(kind.to_lower());var anim:=FortPlayer.find_animation(model)
		check(anim!=null and anim.has_animation("Idle") and anim.has_animation("Walk") and anim.has_animation("Attack") and anim.has_animation("Death"),kind+" has authored animation clips")
		model.free()
	var camera:=Camera3D.new();w.add_child(camera);camera.current=true;w.hud.hide()
	w._update_lighting(1)
	for id in [100,101,102,203,204,305,405]:
		var site:Dictionary=w.encounters.sites[id];var pos:Vector3=site.spec.pos
		p.position=pos+Vector3(0,0,-12);w.encounters.next_check=0;w.encounters.tick()
		camera.position=pos+Vector3(18,13,-24);camera.look_at(pos+Vector3.UP*2)
		w.clock+=1;w._animate_enemies(.1)
		await capture("wilderness11_"+site.spec.type+str(id))
		if site.spec.type=="dragon":
			camera.position=pos+Vector3(8,4,11);camera.look_at(pos+Vector3.UP*1.7)
			await capture("wilderness11_dragon_close"+str(id))
		check(site.seen,"nearby landmark discovered "+str(id))
		# Pause active distant sites between galleries to stay within wildlife cap.
		for enemy_id in w.encounters.members(id):w.broadcast("recv_enemy_dead",[enemy_id])
		site.phase="sleeping"
	var camp:Dictionary=w.encounters.sites[102];p.position=camp.spec.pos
	w.encounters.activate(102);var crew:int=camp.crew
	check(w.encounters.members(102).size()==2 and crew==1,"solo camp gets two defenders")
	w.add_network_player(2,{"name":"Companion","class":1})
	check(camp.crew==1,"existing encounter does not rescale when another dwarf joins")
	w.encounters.activate(202)
	check(w.encounters.sites[202].crew==2 and w.encounters.members(202).size()==3,"new camp scales to the current two-player crew")
	for id in w.enemies.keys():w.broadcast("recv_enemy_dead",[id])
	w.remove_network_player(2)
	w.encounters.activate(100)
	var boar_id:int=w.encounters.members(100)[0];var boar:Dictionary=w.enemies[boar_id]
	var obstacle:=Node3D.new();w.add_child(obstacle);obstacle.position=boar.node.position+Vector3(0,0,3)
	FortArt.box_collider(obstacle,Vector3(6,4,.6),Vector3.UP*2)
	boar.strike_origin=boar.node.position;boar.strike_goal=boar.node.position+Vector3(0,0,8);boar.strike_shape="charge"
	p.position=boar.strike_goal;p.health=p.max_health;await wait(.1)
	w.encounters._strike(boar,w.encounters.sites[100])
	check(p.health==p.max_health and boar.node.position.z<obstacle.position.z,"razorback charge stops at walls and cannot damage through them")
	boar.windup=w.clock+1.4;boar.stun=1;w._simulate_enemies(.05)
	check(boar.windup==0,"stunning a guardian cancels its pending attack")
	obstacle.queue_free()
	for id in w.enemies.keys():w.broadcast("recv_enemy_dead",[id])
	var roost:Dictionary=w.encounters.sites[305];roost.phase="sleeping";w.encounters.activate(305)
	var dragon_id:int=w.encounters.members(305)[0];var dragon:Dictionary=w.enemies[dragon_id]
	check(dragon.kind=="Emberdrake" and dragon.max_hp==720,"first dragon has a solo-scaled health pool")
	# Run the breath fixture in the clear apron, not through the now-solid hoard.
	dragon.node.position=roost.spec.pos+Vector3(0,0,-10)
	p.position=dragon.node.position+Vector3(-10,0,0);p.health=p.max_health
	await wait(.1)
	w.encounters.simulate(dragon,.05)
	check(float(dragon.get("windup",0))>w.clock and p.health==p.max_health,"dragon telegraphs before applying damage")
	camera.position=dragon.node.position+Vector3(19,16,-12);camera.look_at(p.position)
	await capture("wilderness11_breath_warning")
	w.clock+=1.5;w.encounters.simulate(dragon,.05)
	await capture("wilderness11_breath_impact")
	check(p.health==p.max_health-38,"standing in breath cone deals expected damage")
	p.health=p.max_health;dragon.attack=0;w.encounters.simulate(dragon,.05)
	p.position=dragon.node.position+Vector3(12,0,0);w.clock+=1.5;w.encounters.simulate(dragon,.05)
	check(p.health==p.max_health,"sidestepping the marked breath cone avoids damage")
	check(not FortEncounters.in_strike(Vector3(0,5,5),Vector3.ZERO,Vector3(0,0,10),"cone"),"ground breath respects vertical dodge clearance")
	var fort_hp:=w.fort_health;p.position=Vector3.ZERO;w.clock+=2
	for i in 12:w.encounters.simulate(dragon,.05)
	check(w.fort_health==fort_hp,"dragon territory never targets hearth")
	dragon.node.position=roost.spec.pos+Vector3(60,0,0);dragon.hp=100;w.encounters.simulate(dragon,.05)
	check(dragon.node.position.distance_to(roost.spec.pos)<1 and dragon.hp==dragon.max_hp,"out-of-territory creature returns and resets instead of being kited home")
	w.is_night=true;w.wave=1;w._advance_phase()
	check(w.enemies.has(dragon_id),"wilderness guardian persists after dawn")
	p.position=roost.chest.global_position+Vector3(0,0,-2)
	var before:int=w.shared.wood;w.encounters.interact(1)
	check(w.shared.wood==before and roost.phase=="active","guarded treasure cannot be claimed early")
	w._damage_enemy(dragon_id,100000);w.encounters.interact(1)
	check(roost.phase=="claimed" and w.shared.wood==before+42,"dragon hoard grants shared supplies")
	check("Greatmaul" in p.owned_weapons and p.armor,"dragon hoard unlocks crew weapon and Ironheart armor")
	before=w.shared.wood;w.encounters.interact(1);w.encounters.interact(1)
	check(w.shared.wood==before,"repeated treasure requests never duplicate rewards")
	w.add_network_player(3,{"name":"Late explorer","class":2})
	check("Greatmaul" in w.players[3].owned_weapons and w.players[3].armor,"late joining dwarf inherits exploration loot")
	w.remove_network_player(3)
	var state:=w.encounters.state();w.encounters.receive({"seed":909,"revision":0,"sites":{305:{"phase":"sleeping","seen":false,"crew":0}},"unlocked":[]})
	check(roost.phase=="claimed" and "Greatmaul" in w.encounters.unlocked,"stale state cannot relock treasure or remove shared loot")
	check(state.sites[305].phase=="claimed" and state.seed==909,"discovery, cleared state and seed are replicated")
	var den:Dictionary=w.encounters.sites[100];den.phase="sleeping";w.encounters.activate(100)
	p.position=Vector3.ZERO;w.clock+=1;w.encounters.next_check=0
	# Move far enough away that the site may hibernate.
	p.position=Vector3(600,0,0);w.encounters.tick();w.clock+=31;w.encounters.next_check=0;w.encounters.tick()
	check(den.phase=="sleeping" and w.encounters.members(100).is_empty(),"abandoned uncleared encounters hibernate without rewarding loot")
	var live:=0
	for id in w.encounters.sites:w.encounters.activate(id)
	for e in w.enemies.values():
		if FortEncounters.is_wild(e.camp):live+=1
	check(live<=24,"active wilderness population is capped independently of night raids")
	check(w.director.population().all==0,"wilderness creatures do not consume the night raid population allowance")
	check(not w.encounters.guidance(Vector3(0,0,40)).is_empty(),"nearby exploration guidance provides a destination")
	w.hud.show();p.position=Vector3(0,0,40);camera.current=false;p.camera.current=true
	await capture("wilderness11_hud")
	main.queue_free();await wait(.3)
	print("WILDERNESS11_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
