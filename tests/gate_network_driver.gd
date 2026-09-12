extends SceneTree
var failures:=0
var w:FortWorld
var server:=false
func _initialize()->void:run.call_deferred()
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func pump()->void:
	if server and is_instance_valid(w):
		w.clock+=.05;w.gates.tick(.05);w.broadcast("recv_snapshot",[w.snapshot()])
func until(test:Callable,seconds:=10.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:pump();await wait(.05)
	return test.call()
func phase(value:int)->void:
	w.shared.crystal=value;w.broadcast("recv_full",[w.full_state()])
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24765
	server="--server" in OS.get_cmdline_user_args()
	var location:=Vector3(0,.6,9.5)
	if server:
		main._host();main._start_match();w=main.world;w.set_process(false);w.local_player().set_physics_process(false)
		w.set_hearth_level(3);w.shared={"wood":1000,"stone":1000,"iron":1000,"crystal":1000,"aether":1000}
		w.local_player().position=location+Vector3.BACK*3.5
		w._build(1,{"kind":"Gatehouse","pos":location,"rotation":0.0})
		for i in 3:w.clock+=.8;w.construction.work(1,1)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers join gate construction in progress")
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),location+Vector3(float(w.players[id].class_id-2)*.65,0,-3.4)])
		phase(1001)
		verify(await until(func():return not FortConstruction.pending(w.defenses[1])),"remote dwarves finish the shared gatehouse")
		verify(w.shared.wood==960 and w.shared.stone==936,"concurrent construction only pays once")
		var d:Dictionary=w.defenses[1];w.clock+=1;w.gates.request(1,1,0)
		verify(await until(func():return d.gate_open==0),"host closes gate with clear passage")
		phase(1002)
		verify(await until(func():return w.ready_votes.size()==3),"all clients acknowledge closed collision before concurrent requests")
		phase(1003)
		verify(await until(func():return d.get("gate_target",0)==1),"remote operator opens host-owned gate")
		verify(await until(func():return d.gate_open==1),"animated open completes on host")
		verify(d.gate_revision==2,"simultaneous client commands produce exactly one accepted toggle")
		# Place every client in the passage before host tries to close it.
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),location+Vector3(float(w.players[id].class_id-2)*.5,0,0)])
		w.clock+=1;w.gates.request(1,1,d.gate_revision);phase(1004)
		verify(d.gate_target==1 and d.gate_blocked,"remote dwarves block host closure")
		await wait(1)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),location+Vector3(float(w.players[id].class_id-2)*.65,0,-3.4)])
		w.clock+=1;w.gates.request(1,1,d.gate_revision,true)
		w.is_night=true;w.wave=1
		verify(await until(func():return d.gate_open==0),"automatic dusk closure runs on authority")
		phase(1005);await wait(.8)
		w.is_night=false;w.clock+=1;w.progression.upgrade_defense(1,1,1);phase(1006)
		verify(await until(func():return d.level==2),"remote crew completes reinforcement")
		phase(1007);await wait(1)
		var captured:=FortSave.capture(w);verify(FortSave.validate(captured)=="","multiplayer closed gate checkpoint validates")
		var rev:int=d.work_revision;w.construction.salvage(1,1,rev);phase(1008);await wait(1)
		verify(not w.defenses.has(1),"host salvage removes completed gate")
	else:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client connects to gate expedition")
		if not is_instance_valid(main.world):quit(1);return
		w=main.world;w.set_process(false);var p:=w.local_player();p.set_physics_process(false)
		verify(await until(func():return w.defenses.has(1)),"gatehouse restored for late join")
		var d:Dictionary=w.defenses[1]
		verify(FortConstruction.foundation(d) and d.node.has_node("Worksite") and d.work>0,"late join has authored worksite and exact progress")
		await until(func():return w.shared.crystal==1001)
		for i in 12:
			if not FortConstruction.pending(d):break
			w.request_action("work_defense",{"id":1});await wait(.72)
		verify(not FortConstruction.pending(d),"shared construction completes on client")
		verify(await until(func():return w.shared.crystal==1002),"closed state reaches client before toggle race")
		verify(d.gate_open==0 and d.node.get_node("GateDoor").collision_layer==1,"closed gate collision replicated")
		var old_revision:int=d.gate_revision
		w.request_action("ready")
		await until(func():return w.shared.crystal==1003)
		w.request_action("gate",{"id":1,"revision":old_revision})
		verify(await until(func():return w.shared.crystal==1004),"all peers observe one open result")
		verify(d.gate_target==1 and d.gate_revision==old_revision+1 and d.gate_blocked,"concurrent commands and occupancy rejection agree on clients")
		verify(await until(func():return w.shared.crystal==1005),"night auto-close arrives")
		verify(d.gate_open==0 and d.gate_auto and d.node.get_node("GateDoor").collision_layer==1,"saved dusk option and solid gate match host")
		await until(func():return w.shared.crystal==1006)
		for i in 12:
			if not FortConstruction.pending(d):break
			w.request_action("work_defense",{"id":1});await wait(.72)
		verify(await until(func():return w.shared.crystal==1007),"completed reinforcement replicates")
		verify(d.level==2 and d.node.get_meta("gate_parts").tier2.visible and d.max_hp==1980,"remote gate shows reinforced art and health")
		verify(await until(func():return w.shared.crystal==1008),"salvage phase arrives")
		verify(not w.defenses.has(1) and w.shared.wood==974,"salvage and exact shared refund replicate")
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
