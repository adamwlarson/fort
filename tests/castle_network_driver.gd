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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24677
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
		w.phase_time=1000;w.shared={"wood":1000,"stone":1000,"crystal":100,"iron":100,"aether":100}
		for id in w.resource_nodes:w.recv_resource(id,0,false);w.resource_nodes[id].respawn=1000
		p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",{"x":1,"z":0,"floor":0},"Courtyard",w.castle.revision)
		p.position=w.castle.rooms["1:0:0"].sign;p.carrying={"wood":3};w.castle.fund(1,"1:0:0",false,w.castle.revision);p.position=Vector3(0,.6,4)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers join an unfinished castle")
		await wait(.6)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),w.castle.rooms["1:0:0"].sign+Vector3(0,.1,1)])
		verify(await until(func():return w.castle.rooms["1:0:0"].complete,15),"remote dwarves fund and finish a shared wing")
		verify(w.shared.wood==973 and w.shared.stone==945,"racing donations charge exactly the remaining cost once")
		p.position=w.castle.rooms["0:0:0"].sign;w.castle.begin_task(1,"0:0:0","walls",w.castle.revision);w.castle.fund(1,"0:0:0",true,w.castle.revision)
		for i in 30:w.clock+=.7;w.castle.work(1,"0:0:0")
		verify(w.castle.rooms["0:0:0"].walls.size()==16,"host creates damageable curtain walls")
		w.broadcast("recv_full",[w.full_state()]);await wait(4)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads castle run")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:=w.local_player()
		verify(await until(func():return w.castle.rooms.has("1:0:0")),"late join restores wing blueprint")
		verify(w.castle.rooms["1:0:0"].funded.wood==3 and not w.castle.rooms["1:0:0"].complete,"late join restores partial material ledger")
		verify(await until(func():return p.position.distance_to(w.castle.rooms["1:0:0"].sign)<3.8),"remote dwarf reaches construction sign")
		for i in 17:
			if w.castle.rooms["1:0:0"].complete:break
			# Holding E alone funds from shared stock; repeated concurrent input must not overcharge.
			w.request_action("interact");w.request_action("interact");await wait(.72)
		verify(w.castle.rooms["1:0:0"].complete,"finished floor replaces scaffold on each client")
		verify(await until(func():return w.castle.rooms["0:0:0"].walls.size()==16),"curtain-wall layout replicates")
		verify(await until(func():return w.shared.wood==933 and w.shared.stone==845),"wing and curtain-wall costs replicate without duplicate charge")
		var skins:=0
		for id in w.castle.rooms["0:0:0"].walls:
			if w.defenses.has(id) and w.defenses[id].node.has_meta("castle_skin"):skins+=1
		verify(skins==16,"all network walls retain Blender castle models")
		await wait(.3)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
