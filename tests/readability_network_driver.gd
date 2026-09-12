extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=12.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:await wait(.05)
	return test.call()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24747
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:main._host();main._start_match();main.world.phase_time=1000;main.world.shared.crystal=100
	else:main._join()
	verify(await until(func():return is_instance_valid(main.world)),"peer loads feedback run")
	if not is_instance_valid(main.world):quit(1);return
	var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
	if server:
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers connected")
		for id in w.players:w.broadcast("recv_teleport",[int(id),FortProgression.SITES[0].pos+Vector3(2,0,0)])
	else:
		verify(await until(func():return p.position.distance_to(FortProgression.SITES[0].pos)<4),"crew reaches cache")
		if p.class_id==2:w.request_action("interact");w.request_action("interact")
	verify(await until(func():return w.readability.receipt_count==1),"remote chest opens one shared icon receipt")
	verify(w.readability.last_loot.resources.get("crystal",0)==8 and w.readability.last_loot.spent.get("crystal",0)==2,"all peers see actual reward and separate lock cost")
	verify(await until(func():return w.shared.crystal==106),"shared stock reflects the net reward exactly once")
	if server:
		await wait(.5)
		var resource_id:int=w.resource_nodes.keys()[0];var pos:Vector3=w.resource_nodes[resource_id].node.position
		for id in w.players:w.broadcast("recv_teleport",[int(id),pos+Vector3(1,0,0)])
		await wait(.5)
		w._gather(1,resource_id)
		w.broadcast("recv_enemy",[8800,"Raider",Vector3(0,0,25),100]);w.broadcast("recv_enemy_hit",[8800,50,50])
	verify(await until(func():return w.readability.gain_count==1),"nearby crew receives one harvest icon event")
	verify(await until(func():return w.enemies.has(8800) and w.enemies[8800].hp==50),"damaged enemy health replicates for client bars")
	if server:
		w.broadcast("recv_full",[w.full_state()]);await wait(3)
	else:await wait(.6)
	verify(w.readability.receipt_count==1 and w.readability.gain_count==1,"full snapshots do not replay reward notifications")
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
