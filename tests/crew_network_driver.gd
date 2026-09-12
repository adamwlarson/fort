extends SceneTree
var failures:=0
var main:Node
var w:FortWorld
var server:=false
func _initialize()->void:run.call_deferred()
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func until(test:Callable,seconds:=15.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:
		if server and is_instance_valid(w):w.clock+=.05;w.gates.tick(.05);main.broadcast_snapshot(w.snapshot())
		await wait(.05)
	return test.call()
func phase(value:int)->void:w.shared.crystal=value;w.broadcast("recv_full",[w.full_state()])
func run()->void:
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24768
	server="--server" in OS.get_cmdline_user_args()
	var role:="server"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):role=arg.trim_prefix("--role=")
		if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
	main.name_edit.text=role;main.selected_class=0
	if role=="overflow":
		main._join();await wait(3)
		verify(not main.lobby_active and not is_instance_valid(main.world) and not main.transport_connected,"ninth connection cannot enter the full eight-player server")
		main._leave_game("capacity checked");main.queue_free();await wait(.1);print("NETWORK_RESULT CLIENT ","PASS" if failures==0 else "FAIL");quit(failures);return
	var location:=Vector3(0,.6,9.5)
	if server:
		main._host()
		verify(await until(func():return main.player_info.size()==8 and main._crew_ready()),"eight players ready in custom-port lobby")
		var classes:Array=[]
		for info in main.player_info.values():classes.append(info["class"])
		classes.sort();verify(classes==range(8),"duplicate character requests allocate all eight unique save slots")
		await wait(5);verify(main.player_info.size()==8,"capacity probe leaves original eight-player roster intact")
		main._start_match();w=main.world;w.set_process(false);w.local_player().set_physics_process(false)
		verify(await until(func():return main.ready_peers.size()==7),"all seven remote worlds acknowledge readiness")
		w.set_hearth_level(3);w.shared={"wood":1000,"stone":1000,"iron":1000,"crystal":1000,"aether":1000}
		for id in w.players:
			var p:FortPlayer=w.players[id];p.carrying.wood=p.class_id+1;w.broadcast("recv_teleport",[int(id),Vector3(4.6,.7,0)])
		w._deposit(1);phase(101)
		verify(await until(func():return w.shared.wood==1036),"eight packs deposit into shared stock without duplication")
		w._spawn_defense("Gatehouse",location,0,false)
		for id in w.players:w.broadcast("recv_teleport",[int(id),location+Vector3((w.players[id].class_id-3.5)*.3,0,3.4)])
		phase(102);verify(await until(func():return float(w.defenses[1].get("gate_open",1))==0),"seven remote gate requests produce a closed gate")
		verify(w.defenses[1].gate_revision==1,"only one command wins eight-player gate race")
		for i in 100:w.recv_enemy(24000+i,"Raider",Vector3(-30+(i%10)*2,0,30+int(i/10)*2),100)
		phase(103)
		verify(await until(func():return w.ready_votes.size()==7),"every client receives eight players and a 100-enemy snapshot")
		for p in w.players.values():p.carrying.iron=p.class_id+10;p.health=p.max_health-10
		FortSave.test_directory="res://build/crew24_network_%d"%OS.get_process_id()
		verify(FortSave.write_slot("slot1",w)=="" and FortSave.read_slot("slot1").data.characters.size()==8,"live eight-player expedition saves all inventories")
		phase(104)
		verify(await until(func():return w.players.size()==7),"disconnect frees eighth world slot")
		verify(await until(func():return w.players.size()==8 and main.ready_peers.size()==7),"eighth player reconnects to the running expedition")
		for p in w.players.values():verify(p.carrying.iron==p.class_id+10,"personal saved inventory stays with dwarf slot")
		w.wave=8;w.is_night=true;w.director.start();verify(w.director.crew==8,"live raid director counts eight participants")
		phase(105);await wait(2)
	else:
		main._join();verify(await until(func():return main.lobby_active),"client enters eight-player lobby")
		main._lobby_pressed();verify(await until(func():return is_instance_valid(main.world)),"host starts eight-player expedition")
		if not is_instance_valid(main.world):quit(1);return
		w=main.world;w.set_process(false);var p:=w.local_player();p.set_physics_process(false);var dwarf_slot:int=p.class_id
		verify(await until(func():return w.shared.crystal==101),"shared gathering fixture arrives")
		w.request_action("interact");w.request_action("interact")
		verify(await until(func():return w.shared.crystal==102),"all eight deposits synchronize")
		verify(w.shared.wood==1036 and p.total_carried()==0,"no double credit from repeated deposit requests")
		# The fixture teleported here immediately after depositing; real walking
		# would outlast the normal 0.65s interaction cooldown.
		await wait(.8)
		w.request_action("interact",{"gate":1,"gate_revision":0,"held":false})
		verify(await until(func():return w.shared.crystal==103 and w.enemies.size()>=100),"100 enemies and gate state reach client")
		verify(w.players.size()==8 and w.defenses[1].gate_revision==1 and w.defenses[1].gate_open==0,"eight-player roster and single gate result agree")
		w.hud.map.refresh();verify(w.hud.map.crew.size()==7,"client minimap retains all seven other dwarves")
		w.request_action("ready")
		verify(await until(func():return w.shared.crystal==104),"saved personal inventory fixture arrives")
		if role=="client7":
			main._leave_game("rejoin eighth slot");await wait(.8);main.selected_class=dwarf_slot;main._join()
			verify(await until(func():return is_instance_valid(main.world)),"eighth client rejoins without restarting game")
			w=main.world;w.set_process(false);p=w.local_player();p.set_physics_process(false)
		verify(await until(func():return w.shared.crystal==105),"eight-player raid state arrives after reconnect")
		verify(p.class_id==dwarf_slot and p.carrying.iron==dwarf_slot+10 and p.health==p.max_health-10,"own character, health and inventory survive reconnect")
		verify(w.director.crew==8 and w.players.size()==8,"all clients agree on eight-player raid pressure")
		await wait(.2)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
