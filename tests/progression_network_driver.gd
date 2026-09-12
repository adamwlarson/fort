extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=9.0)->bool:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<end:await wait(.05)
	return test.call()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match()
		var w:FortWorld=main.world;var host:FortPlayer=w.local_player()
		w.shared={"wood":500,"stone":500,"crystal":500,"iron":500,"aether":500};w.set_hearth_level(3)
		for site in [1,2]:
			host.position=FortProgression.SITES[site].pos+Vector3(0,0,2);w.progression.interact(1)
			for id in w.enemies.keys():w.recv_enemy_dead(id)
			w.progression.interact(1)
		host.position=Vector3(0,0,4);w.shared.crystal=500
		w._spawn_defense("Watchtower",Vector3(0,0,22),0,false)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"three late joins load expanded world and relics")
		await wait(.5)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(-4.6,0,2)])
		verify(await until(func():return w.players.values().all(func(p):return p.peer_id==1 or p.backpack_level==2)),"all clients craft both backpack tiers")
		verify(w.shared.wood==380 and w.shared.crystal==482 and w.shared.iron==464,"duplicate remote backpack requests charge once per tier")
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(0,0,25)])
		verify(await until(func():return w.defenses[1].level==3),"concurrent clients upgrade one tower to level three")
		await wait(.4)
		verify(w.shared.wood==356 and w.shared.stone==474 and w.shared.iron==440 and w.shared.aether==495,"racing tower upgrades deduct each level exactly once")
		for resource in ["iron","aether"]:
			var node_id:=-1
			for id in w.resource_nodes:
				if w.resource_nodes[id].kind==resource:node_id=id;break
			for id in w.players:
				if id!=1:w.broadcast("recv_teleport",[int(id),w.resource_nodes[node_id].node.position+Vector3(1,0,0)])
			verify(await until(func():return w.players.values().all(func(p):return p.peer_id==1 or p.carrying.get(resource,0)>0)),"remote crew harvests "+resource)
			var expected:int=w.shared[resource]
			for p in w.players.values():expected+=int(p.carrying.get(resource,0)) if p.peer_id!=1 else 0
			for id in w.players:
				if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(4.6,0,2)])
			verify(await until(func():return w.players.values().all(func(p):return p.peer_id==1 or p.total_carried()==0)),"remote crew deposits "+resource)
			verify(w.shared[resource]==expected,"shared stock includes every remote "+resource+" deposit")
			host.position=Vector3.ZERO;await wait(.5)
		host.position=FortProgression.SITES[4].pos+Vector3(0,0,2);w.progression.interact(1)
		for id in w.enemies.keys():w.recv_enemy_dead(id)
		w.progression.interact(1);host.position=Vector3.ZERO
		await wait(2)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world) and main.world.players.size()>=2),"client loads world")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:FortPlayer=w.local_player()
		verify(await until(func():return w.hearth_level==3 and p.armor and "Embermaul" in p.relics),"late join receives hearth tiers, rare weapon, armor")
		verify(w.resource_nodes.keys().filter(func(id):return int(id)<10000).size()==234 and w.progression.sites[1].opened and w.progression.sites[2].opened,"late join sees new resource zones and claimed camps")
		await until(func():return p.position.distance_to(Vector3(-4.6,0,0))<3.2)
		for tier in 2:
			w.request_action("craft_pack",{"level":tier});w.request_action("craft_pack",{"level":tier})
			verify(await until(func():return p.backpack_level==tier+1),"remote pack tier %d replicates"%(tier+1))
		verify(p.carry_limit==(54 if p.class_id==3 else 46) and is_instance_valid(p.backpack_visual),"personal capacity and backpack model match class")
		await until(func():return p.position.distance_to(Vector3(0,0,22))<4)
		for level in [1,2]:
			w.request_action("upgrade_defense",{"id":1,"level":level});w.request_action("upgrade_defense",{"id":1,"level":level})
			for stroke in 12:
				if w.defenses[1].level>=level+1:break
				w.request_action("work_defense",{"id":1});await wait(.72)
			verify(await until(func():return w.defenses[1].level>=level+1),"remote tower level %d replicates"%(level+1))
		verify(is_equal_approx(w.defenses[1].max_hp,GameData.RECIPES.Watchtower.hp*2.3),"upgraded tower max health reaches every client")
		for resource in ["iron","aether"]:
			var node_id:=-1
			for id in w.resource_nodes:
				if w.resource_nodes[id].kind==resource:node_id=id;break
			await until(func():return p.position.distance_to(w.resource_nodes[node_id].node.position)<3)
			await wait(.75) # Normal held-E cadence, including the preceding stockpile interaction.
			w.request_action("interact",{})
			verify(await until(func():return p.carrying.get(resource,0)>0),"client receives gathered "+resource)
			await until(func():return p.position.distance_to(Vector3(4.6,0,0))<3.2)
			await wait(.8);w.request_action("interact",{})
			verify(await until(func():return p.total_carried()==0),"client pack clears on "+resource+" deposit")
		verify(await until(func():return "Stormstring" in p.relics and p.weapon_asset_key=="stormstring"),"live crew relic unlock equips rare crossbow remotely")
		verify(w.progression.sites[4].opened,"final camp claimed state reaches clients")
		await wait(.6)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
