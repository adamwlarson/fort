extends SceneTree
var main:Node
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=12.0)->bool:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<end:await wait(0.1)
	return test.call()
func run()->void:
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	main.port_edit.value=24587
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host()
		verify(await until(func():return main.player_info.size()==4),"four players join custom-port lobby")
		verify(not is_instance_valid(main.world),"world stays stopped while crew prepares")
		verify(await until(func():return main.player_info.size()==3),"disconnected lobby slot is released")
		verify(await until(func():return main.player_info.size()==4),"client reconnects to the same lobby")
		verify(await until(func():return main._crew_ready()),"all clients ready up")
		var classes:Array=[]
		for info in main.player_info.values():
			verify(info["class"] not in classes,"each dwarf assigned a unique class");classes.append(info["class"])
		main._start_match()
		verify(await until(func():return main.ready_peers.size()==3),"all clients acknowledge world loading")
		var w:FortWorld=main.world
		w.shared={"wood":200,"stone":200,"crystal":50};w.local_player().position=Vector3(0,0,3.5)
		w.server_action(1,"upgrade_hearth",{"level":1})
		w.broadcast("recv_enemy",[990,"Ashwing",Vector3(35,3.8,35),200.0]);w.enemies[990].stun=100
		w.broadcast("recv_enemy",[991,"EmberRunner",Vector3(38,0,35),200.0]);w.enemies[991].stun=100
		await wait(3)
		verify(w.hearth_level==2 and w.resource_nodes.size()==162,"host creates upgraded world")
	else:
		main.address_edit.text="127.0.0.1"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
		main._join()
		verify(await until(func():return main.lobby_active),"client enters lobby on custom UDP port")
		verify(not is_instance_valid(main.world),"joining does not start world before host")
		if "--role=client3" in OS.get_cmdline_user_args():
			await wait(0.7)
			main._leave_game("Reconnect test")
			await wait(0.8)
			main._join()
			verify(await until(func():return main.lobby_active),"client can cancel and reconnect without restarting game")
		await wait(0.5)
		main._lobby_pressed()
		verify(await until(func():return is_instance_valid(main.world)),"host start loads client world")
		var w:FortWorld=main.world
		verify(await until(func():return w.hearth_level==2 and w.enemies.has(990) and w.enemies.has(991)),"upgrades and enemy types replicate")
		verify(w.resource_nodes.size()==162 and w.frontier_radius()==153,"client frontier matches host")
		verify(w.fort_max_health==1500,"client hearth maximum health matches")
		verify(w.enemies[990].node.position.y>3,"airborne position replicates")
		await wait(1)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free();await wait(0.1);quit(failures)
