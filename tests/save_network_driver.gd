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
	FortSave.test_directory="res://build/save_network_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24697
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;w.set_process(false)
		w.wave=7;w.phase_time=543;w.set_hearth_level(3);w.shared={"wood":1000,"stone":1000,"crystal":100,"iron":100,"aether":100}
		for id in w.resource_nodes:w.recv_resource(id,0,false);w.resource_nodes[id].respawn=1000
		var p:=w.local_player();p.set_physics_process(false);p.position=w.castle.rooms["0:0:0"].sign
		w.castle.plan(1,"0:0:0",{"x":1,"z":0,"floor":0},"Courtyard",w.castle.revision)
		p.position=w.castle.rooms["1:0:0"].sign;p.carrying={"wood":3};w.castle.fund(1,"1:0:0",false,w.castle.revision);p.position=Vector3(0,.6,4)
		for cls in range(1,4):
			w.add_network_player(100+cls,{"name":"Old dwarf","class":cls});var guest:FortPlayer=w.players[100+cls]
			guest.health=40+cls;guest.carrying={"iron":cls};guest.position=Vector3(cls*2,.7,5);guest.look_yaw=.25*cls;guest.fuel=30+cls
			guest.owned_weapons=PackedStringArray(["Axe","Crossbow"]);guest.equip_weapon("Crossbow");guest.loadout_revision=3;guest.apply_weapon_levels({"Crossbow":2},3);w.recv_remove_player(100+cls)
		verify(FortSave.write_slot("slot1",w)=="","host saves old disconnected player IDs")
		var checkpoint:Dictionary=FortSave.read_slot("slot1").data
		main._leave_game("resume test");await wait(.1);main.port_edit.value=24697;main.pending_save=checkpoint;main._host();main._start_match();w=main.world
		w.local_player().set_physics_process(false)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four players join a resumed expedition")
		verify(w.wave==7 and w.phase_time>510 and w.phase_time<543,"saved day clock continues without restarting")
		for id in w.players:
			if id==1:continue
			var guest:FortPlayer=w.players[id]
			verify(id>103 and guest.health==40+guest.class_id and guest.carrying.iron==guest.class_id,"new peer IDs inherit their saved class slot")
		await wait(1)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),w.castle.rooms["1:0:0"].sign+Vector3(0,.1,1)])
		verify(await until(func():return w.castle.rooms["1:0:0"].complete,15),"returning clients complete saved construction")
		verify(w.shared.wood==973 and w.shared.stone==945,"saved funding is charged only for its remaining materials")
		await wait(2)
	else:
		await wait(1.5)
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads resumed run")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:=w.local_player()
		verify(await until(func():return p.weapon=="Crossbow" and p.position.z>4),"saved equipment and local position arrive reliably")
		p.set_physics_process(false)
		verify(p.health==40+p.class_id and p.carrying.get("iron",0)==p.class_id and p.weapon_levels.get("Crossbow",0)==2,"client sees restored health, inventory and weapon upgrade")
		verify(is_equal_approx(p.look_yaw,.25*p.class_id) and absf(p.fuel-(30+p.class_id))<2,"client view direction and fuel restored")
		verify(FortSave.write_slot("slot1",w).contains("host"),"clients cannot write expedition checkpoints")
		verify(w.castle.rooms.has("1:0:0") and w.castle.rooms["1:0:0"].funded.wood==3,"unfinished castle ledger reaches every client")
		verify(await until(func():return p.position.distance_to(w.castle.rooms["1:0:0"].sign)<3.8),"returning dwarf reaches saved blueprint")
		for i in 17:
			if w.castle.rooms["1:0:0"].complete:break
			w.request_action("castle_fund",{"key":"1:0:0","shared":true,"revision":w.castle.revision});w.request_action("interact");await wait(.72)
		verify(w.castle.rooms["1:0:0"].complete,"saved project can be built by reconnected peers")
		await wait(.4)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
