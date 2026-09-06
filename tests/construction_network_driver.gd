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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	main.port_edit.value=24597
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;var host:FortPlayer=w.local_player()
		w.set_hearth_level(2);w.shared={"wood":100,"stone":100,"crystal":100,"iron":100,"aether":100}
		host.position=Vector3(0,0,18);w._build(1,{"kind":"Watchtower","pos":Vector3(0,0,22)})
		host.position=Vector3(0,0,25)
		for i in 4:w.clock+=.8;w.server_action(1,"work_defense",{"id":1})
		host.position=Vector3(0,0,4)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four players share partially built project")
		await wait(.6)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(0,0,25)])
		verify(await until(func():return not FortConstruction.pending(w.defenses[1])),"remote crew completes shared foundation")
		verify(w.shared.wood==82 and w.shared.stone==92,"multiple workers never charge construction materials twice")
		await wait(.6)
		host.position=Vector3(0,0,35);w._build(1,{"kind":"Barricade","pos":Vector3(0,0,38)})
		w.server_action(1,"work_defense",{"id":2});host.position=Vector3(0,0,35)
		await wait(1.5)
		w.server_action(1,"cancel_construction",{"id":2,"revision":w.defenses[2].work_revision})
		verify(w.shared.wood==80 and w.shared.stone==91,"cancellation returns only unused shared materials")
		host.position=Vector3(0,0,4)
		w.broadcast("recv_enemy",[991,"Brute",Vector3(0,0,23.5),500.0])
		verify(await until(func():return w.defenses[1].hp<240),"siege brute damages finished structure on host")
		await wait(2)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads expedition")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:FortPlayer=w.local_player()
		verify(await until(func():return w.defenses.has(1) and is_equal_approx(w.defenses[1].get("work",0),5.0)),"late join restores exact solo-boosted construction progress")
		verify(w.defenses[1].work_visual_stage==1 and w.defenses[1].hp==72,"late join sees scaffold and foundation health")
		await until(func():return p.position.distance_to(Vector3(0,0,22))<3.8)
		for stroke in 10:
			if not FortConstruction.pending(w.defenses[1]):break
			w.request_action("work_defense",{"id":1});w.request_action("work_defense",{"id":1});await wait(.72)
		verify(not FortConstruction.pending(w.defenses[1]) and w.defenses[1].max_hp==240,"completed structure and full health replicate")
		verify(is_instance_valid(p.work_hammer),"remote work acknowledgment attaches construction hammer")
		verify(await until(func():return w.defenses.has(2)),"second project replicates before cancellation")
		verify(await until(func():return not w.defenses.has(2)),"cancelled scaffold disappears on clients")
		verify(await until(func():return w.shared.wood==80 and w.shared.stone==91),"unused-material refund replicates")
		verify(await until(func():return w.enemies.has(991) and w.defenses[1].hp<240),"siege attack and building damage replicate")
		await wait(.5)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
