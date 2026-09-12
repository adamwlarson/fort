extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);p.position=Vector3(0,0,100)
	for kind in ["Cleaver","Warpick","Greatmaul","Handcannon","Longrifle","Runestaff","Runeblade"]:
		for id in w.enemies.keys():w.recv_enemy_dead(id)
		await physics_frame
		p.equip_weapon(kind)
		for i in 3:w.recv_enemy(9500+i,"Raider",Vector3((i-1)*1.3,0,102.5),5000)
		await physics_frame;w._resolve_hit(1,Vector3.BACK,kind)
		var damaged:=0
		for e in w.enemies.values():
			if e.hp<5000:damaged+=1
		check(damaged>0,kind+" resolves real combat damage")
		if kind in ["Handcannon","Runestaff"]:check(damaged==3,kind+" damages secondary targets with its special effect")
		if kind in ["Warpick","Longrifle"]:check(damaged==1,kind+" remains single-target")
		p.play_action("attack");check(p.animation_player.is_playing(),kind+" plays an attack animation")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w.recv_enemy(9600,"Hexer",Vector3(0,0,110),500);w.recv_enemy(9601,"Raider",Vector3(1,0,110),500);w.enemies[9601].hp=300
	w.expedition.simulate(w.enemies[9600],.016);check(w.enemies[9601].hp==322,"Hexer actually heals wounded allies")
	w.recv_enemy(9602,"Shieldguard",Vector3(5,0,110),500);w._damage_enemy(9602,100,Vector3.ZERO,"tower_damage")
	check(w.enemies[9602].hp==430,"Shieldguard armor resists ordinary tower damage")
	w._damage_enemy(9602,100,Vector3.ZERO,"tower_damage",true);check(w.enemies[9602].hp==330,"Sunlance-style piercing ignores shield armor")
	w.progression.unlocked.append("Embermaul");w.expedition.bosses_defeated=1;w.recv_player(42,{"name":"Late Hero","class":1})
	check("Hammer" in w.players[42].owned_weapons and "Runeblade" in w.players[42].owned_weapons,"late join receives boss weapon without losing previous relic weapons")
	main._leave_game();await create_timer(.2).timeout;main.queue_free();await create_timer(.1).timeout
	print("ARSENAL9_TEST_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
