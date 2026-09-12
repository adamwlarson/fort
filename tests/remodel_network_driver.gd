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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24727
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
		w.phase_time=1000;w.set_hearth_level(2);w.shared={"wood":1000,"stone":1000,"crystal":100,"iron":100,"aether":100}
		for id in w.resource_nodes:w.recv_resource(id,0,false);w.resource_nodes[id].respawn=1000
		w.scenery_keepouts.clear();p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",{"x":1,"z":0,"floor":0},"Courtyard",w.castle.revision)
		p.position=w.castle.rooms["1:0:0"].sign;w.castle.fund(1,"1:0:0",true,w.castle.revision)
		for i in 30:w.clock+=.7;w.castle.work(1,"1:0:0")
		p.position=Vector3(0,.7,5)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers join a completed castle wing")
		await wait(.5)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),w.castle.rooms["1:0:0"].sign+Vector3(0,.1,1)])
		verify(await until(func():return w.castle.rooms["1:0:0"].kind=="Merchant"),"remote crew hand-builds a shared remodel")
		verify(w.shared.wood==920 and w.shared.stone==907 and w.shared.crystal==92,"duplicate remodel/fund packets refund the old room once")
		verify(await until(func():return not w.castle.rooms.has("1:0:0")),"remote crew dismantles completed addition")
		verify(w.shared.wood==952 and w.shared.stone==939 and w.shared.crystal==96,"demolition refunds only current room ledger once")
		for id in w.players:verify(w.players[id].position.distance_to(Vector3(0,.7,7))<5,"workers return safely to keep")
		await wait(1)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads remodel run")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
		verify(await until(func():return p.position.distance_to(Vector3(13,.6,-7))<3),"crew reaches project sign")
		if p.class_id==2:
			var payload:={"key":"1:0:0","kind":"Merchant","revision":w.castle.revision}
			w.request_action("castle_remodel",payload);w.request_action("castle_remodel",payload)
		verify(await until(func():return w.castle.rooms["1:0:0"].task=="remodel"),"remodel target replicates")
		for i in 25:
			if w.castle.rooms["1:0:0"].kind=="Merchant":break
			var payload:={"key":"1:0:0","shared":true,"revision":w.castle.revision}
			w.request_action("castle_fund",payload);w.request_action("castle_fund",payload);w.request_action("interact");await wait(.72)
		verify(w.castle.rooms["1:0:0"].kind=="Merchant","all workers see completed remodel")
		await wait(.5)
		if p.class_id==2:
			var payload:={"key":"1:0:0","kind":"","revision":w.castle.revision}
			w.request_action("castle_remodel",payload);w.request_action("castle_remodel",payload)
		verify(await until(func():return w.castle.rooms["1:0:0"].task=="dismantle"),"dismantling project replicates")
		for i in 18:
			if not w.castle.rooms.has("1:0:0"):break
			w.request_action("interact");await wait(.72)
		verify(not w.castle.rooms.has("1:0:0"),"demolished floor disappears on every client")
		verify(p.position.distance_to(Vector3(0,.7,7))<1,"local controlling dwarf is safely teleported")
		await wait(.3)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
