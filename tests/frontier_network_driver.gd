extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=10.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:await wait(.05)
	return test.call()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24607
	var server:bool="--server" in OS.get_cmdline_user_args()
	var role:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):role=arg.trim_prefix("--role=")
	main.name_edit.text=role
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;var host:FortPlayer=w.local_player()
		w.set_hearth_level(3);w.shared={"wood":500,"stone":500,"crystal":500,"iron":500,"aether":500}
		host.position=Vector3(-4.6,0,2);w._craft_weapon(1,"Repeater");w._upgrade_weapon(1,"Repeater",1);w.clock+=1;w._upgrade_weapon(1,"Repeater",2)
		w._spawn_defense("Ballista",Vector3(0,0,100),0,false)
		w._spawn_defense("Mender",Vector3(5,0,100),0,false);w.defenses[2].level=3;w.progression.defense_visual(w.defenses[2])
		w._spawn_defense("MetalWall",Vector3(5,0,106),0,false)
		w._spawn_defense("Watchtower",Vector3(12,0,106),0,false)
		host.position=Vector3(0,0,4)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four-player frontier session connected")
		await wait(.7)
		var gunner:=-1
		for id in w.players:
			if w.players[id].display_name=="client1":gunner=int(id)
		verify(gunner>0,"designated remote gunner found")
		if gunner<0:quit(1);return
		w.broadcast("recv_teleport",[gunner,Vector3(0,0,102)])
		await wait(.3);w._mount(gunner,1)
		verify(await until(func():return absf(w.defenses[1].get("aim",Vector3.FORWARD).x)>.5),"continuous remote ballista aim reaches server without firing")
		await wait(1.3)
		w._mount(gunner,-1)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(-4.6,0,2)])
		verify(await until(func():
			for p in w.players.values():
				if p.peer_id!=1 and int(p.weapon_levels.get("Repeater",1))<2:return false
			return true),"three clients craft and reinforce their own Repeater")
		await wait(.5)
		w.broadcast("recv_enemy",[991,"Cinderlobber",Vector3(12,0,119),500.0])
		w.broadcast("recv_enemy",[992,"Bombwing",Vector3(12,5.8,111),500.0])
		verify(await until(func():return w.defenses[4].hp<240),"ranged siege enemies damage a tower on host")
		await wait(2)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads Fort 7")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:FortPlayer=w.local_player()
		verify(await until(func():return w.defenses.has(2) and w.defenses[2].get("level",1)==3),"late join receives level three Mender")
		verify(w.defenses[2].node.has_node("Tier2") and w.defenses[2].node.has_node("Tier3"),"late join sees iron armor and aether crown")
		verify(w.players[1].weapon_power("Repeater")==1.5,"late join restores host masterwork weapon")
		verify(w.progression.sites.has(8),"all unlocked villages replicate")
		if role=="client1":
			verify(await until(func():return p.mounted_ballista==1),"remote dwarf mounts ballista")
			p.look_yaw=-PI/2;p.look_pitch=-.12
		verify(await until(func():return absf(w.defenses[1].node.get_node("Turret").rotation.y)>1),"other clients see ballista tracking the remote gunner")
		verify(await until(func():return p.mounted_ballista<0 and p.position.distance_to(Vector3(-4.6,0,2))<2),"crew reaches workshop")
		w.request_action("craft_weapon",{"weapon":"Repeater"})
		verify(await until(func():return p.weapon=="Repeater"),"remote forge craft acknowledged")
		w.request_action("upgrade_weapon",{"weapon":"Repeater","level":1});w.request_action("upgrade_weapon",{"weapon":"Repeater","level":1})
		verify(await until(func():return int(p.weapon_levels.get("Repeater",1))==2),"weapon reinforcement replicates despite duplicate request")
		verify(await until(func():return w.enemies.has(991) and w.enemies.has(992)),"both new enemy kinds replicate")
		verify(await until(func():return w.defenses[4].hp<240),"ranged building damage replicates to clients")
		await wait(.5)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
