extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=12.0)->bool:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<end:await wait(.05)
	return test.call()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24637
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world
		w.expedition.configure(911);w.set_hearth_level(4)
		w.shared={"wood":1000,"stone":1000,"crystal":1000,"iron":1000,"aether":1000}
		var host:=w.local_player();host.position=w.encounters.sites[101].chest.global_position+Vector3(0,0,-2)
		w.encounters.interact(1);host.position=Vector3.ZERO
		w.encounters.sites[305].seen=true;w.encounters.activate(305)
		var enemy_id:int=w.encounters.members(305)[0];w.enemies[enemy_id].hp=360;w.enemies[enemy_id].stun=100
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers join expanded wilderness")
		await wait(1)
		w.broadcast("recv_fx",[w.enemies[enemy_id].node.position,Color.ORANGE,"DODGE / Emberdrake","wild_cone",w.enemies[enemy_id].node.position+Vector3(0,0,10)])
		await wait(1.5)
		w._damage_enemy(enemy_id,100000)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),w.encounters.sites[305].chest.global_position+Vector3(0,0,-2)])
		verify(await until(func():return w.encounters.sites[305].phase=="claimed"),"remote explorers claim cleared dragon hoard")
		verify(w.shared.wood==1057,"racing treasure claims pay exactly once after earlier caravan cache")
		verify("Greatmaul" in w.encounters.unlocked and "Ironheart" in w.progression.unlocked,"dragon rewards enter shared unlock state")
		await wait(1.5)
	else:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
		if "--role=client3" in OS.get_cmdline_user_args():await wait(1)
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads wilderness world")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:FortPlayer=w.local_player()
		verify(await until(func():return w.hearth_level==4 and w.encounters.sites.size()==27),"late join restores all unlocked exploration sites")
		verify(w.encounters.layout_seed==911 and w.encounters.sites[305].spec.pos==FortEncounters.layout(911)[14].pos,"site positions match the host's seed")
		verify(w.encounters.sites[101].phase=="claimed","previously claimed cache stays open for late joiner")
		verify(await until(func():return w.encounters.members(305).size()==1),"active territorial dragon replicates")
		var enemy_id:int=w.encounters.members(305)[0]
		verify(w.enemies[enemy_id].kind=="Emberdrake" and w.enemies[enemy_id].hp==360,"late join preserves dragon type and remaining health")
		verify(await until(func():return get_nodes_in_group("wilderness_warning").size()>0),"dragon attack warning reaches remote clients")
		verify(await until(func():return p.position.distance_to(w.encounters.sites[305].chest.global_position)<3),"host moves explorers to cleared hoard")
		w.request_action("interact",{});w.request_action("interact",{})
		verify(await until(func():return w.encounters.sites[305].phase=="claimed"),"remote claim opens chest for every client")
		verify(await until(func():return "Greatmaul" in p.owned_weapons and p.armor),"every client receives dragon weapon and armor")
		verify(w.shared.wood==1057,"shared supplies replicate without duplicate payout")
		await wait(.3)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
