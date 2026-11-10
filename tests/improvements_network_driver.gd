extends SceneTree
var failures:=0
var server:=false
var main:Node
var w:FortWorld
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=15.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:
		if server and is_instance_valid(w):w.clock+=.05;w.gates.tick(.05);main.broadcast_snapshot(w.snapshot())
		await wait(.05)
	return test.call()
func room(x:int,z:int,kind:String)->void:
	w.castle.rooms[FortCastle.key(x,z,0)]={"x":x,"z":z,"floor":0,"kind":kind,"complete":true,"funded":{},"work":0.0,"total":0.0,"sign":Vector3(x*20-7,.6,z*20-7),"walls":[],"task":"","resource":"wood","level":2};w.castle.changed()
func phase(value:int)->void:w.shared.crystal=value;w.broadcast("recv_full",[w.full_state()])
func run()->void:
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24826
	server="--server" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
	if server:main._host();main._start_match();w=main.world;w.set_process(false)
	else:main._join()
	verify(await until(func():return is_instance_valid(main.world)),"peer loads Fort 25")
	if not is_instance_valid(main.world):quit(1);return
	w=main.world;var p:=w.local_player();p.set_physics_process(false)
	if server:
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four players connected")
		w.set_hearth_level(4);w.shared={"wood":1000,"stone":1000,"iron":1000,"aether":1000,"crystal":1000,"gold":0};room(1,0,"Merchant");phase(101)
		for id in w.players:w.broadcast("recv_teleport",[int(id),FortMerchant.location(w.castle,"1:0:0")+Vector3(2,0,0)])
	verify(await until(func():return w.castle.rooms.has("1:0:0") and w.shared.crystal==101),"room upgrade and merchant replicated")
	verify(w.castle.rooms["1:0:0"].get("level",1)==2,"remote room retains upgrade level")
	if not server and p.class_id==2:
		verify(await until(func():return FortMerchant.nearest(w,p.position)=="1:0:0"),"remote trader reaches tent")
		var data:={"key":"1:0:0","resource":"wood","sell":true,"revision":w.castle.revision,"day":w.wave}
		w.request_action("merchant_trade",data);w.request_action("merchant_trade",data)
	verify(await until(func():return int(w.shared.get("gold",0))==10),"one remote sale deposits gold exactly once")
	if server:
		p.position=FortHearthGrowth.workshop(w);w.pets.recruit(1,0,w.pets.revision)
		var pet:Dictionary=w.pets.pets[1];pet.cargo=3;pet.cargo_kind="stone";pet.node.position=Vector3(100,0,100)
		phase(102)
		for id in w.players:w.broadcast("recv_teleport",[int(id),FortHearthGrowth.workshop(w)+Vector3(2,0,0)])
	verify(await until(func():return w.shared.crystal==102 and w.pets.pets.has(1)),"remote pet cargo and distant position replicated")
	if not server and p.class_id==3:
		verify(await until(func():return w.pets.at_workshop(p.peer_id)),"pet owner reaches moved workshop")
		var data:={"id":1,"revision":w.pets.pets[1].revision};w.request_action("release_pet",data);w.request_action("release_pet",data)
	verify(await until(func():return w.pets.pets.is_empty() and w.shared.stone==1003),"remote release frees slot and returns cargo once")
	if server:
		w._spawn_defense("CastleGate",Vector3(0,.6,9.8),0,false);phase(103)
		for id in w.players:w.broadcast("recv_teleport",[int(id),Vector3(0,.6,12.8)])
	verify(await until(func():return w.shared.crystal==103 and w.defenses.has(1) and FortGates.passable(w.defenses[1])),"automatic floor door opens for remote crew")
	if server:
		await wait(1)
		for id in w.players:w.broadcast("recv_teleport",[int(id),Vector3(0,.6,7)])
		p.position=w.castle.rooms["0:0:0"].sign;FortPerimeter.activate(w.castle,1,"0:0:0",w.castle.revision)
		phase(104)
	verify(await until(func():return w.shared.crystal==104 and w.castle.perimeter.get("enabled",false)),"perimeter replicated to all peers")
	var id:int=w.castle.perimeter.segments["1:2"].id
	var original:Vector3=w.defenses[id].node.position
	if server:
		await wait(1.5);w.defenses[id].hp=123;room(4,0,"Courtyard");phase(105)
	verify(await until(func():return w.shared.crystal==105 and w.defenses.has(id) and w.defenses[id].node.position.x>original.x and w.defenses[id].hp==123),"moving wall position and damage replicate together")
	if server:
		await wait(1.5)
		w.broadcast("recv_full",[w.full_state()]);await wait(1.5)
	else:await wait(.5)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
