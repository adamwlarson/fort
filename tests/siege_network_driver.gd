extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=15.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:await wait(.05)
	return test.call()
func stream(main:Node,seconds:float)->void:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<deadline:
		main.broadcast_snapshot(main.world.snapshot());await wait(.08)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24763
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:main._host();main._start_match();main.world.set_process(false)
	else:main._join()
	verify(await until(func():return is_instance_valid(main.world)),"peer loads siege run")
	if not is_instance_valid(main.world):quit(1);return
	var w:FortWorld=main.world;w.set_process(false);w.local_player().set_physics_process(false)
	var ui:=w.hud.siege_indicators
	if server:
		verify(await until(func():return main.ready_peers.size()==3),"all remote worlds ready before siege events")
		for id in w.enemies.keys():w.broadcast("recv_enemy_dead",[int(id)])
		for id in w.players:w.broadcast("recv_teleport",[int(id),Vector3(0,.7,18)])
		w.is_night=true;w.wave=6;w.director.start();w.director.lane_base=2
		w.broadcast("recv_defense",[22000,"Watchtower",Vector3(-12,.6,2),0,400.0,false])
		w.broadcast("recv_enemy",[22000,"Sapper",Vector3(0,.6,10),100.0])
		await stream(main,1)
		w._damage_defense(22000,300);w.enemies[22000].fuse_at=1000
		await stream(main,2)
	verify(await until(func():return w.defenses.has(22000) and w.defenses[22000].hp==100 and (server or bool(w.enemies.get(22000,{}).get("warning_armed",false)))),"building damage and armed state arrive through batched snapshots")
	ui.refresh()
	verify(ui.threats.size()==1 and ui.threats[0].armed,"every peer ranks armed bomber first")
	verify(ui.repairs.size()==1 and ui.repairs[0].hit and ui.repairs[0].fraction==.25,"every peer displays critical under-attack building")
	verify(ui.fronts[0]==1 and ui.forecast==w.director.lanes() and 2 in ui.forecast,"live direction and expected fronts agree on all peers")
	var map:=w.hud.map;map.resources_enabled=w.local_player().class_id==1;map.refresh()
	verify(map.crew.size()==3 and map.point(w.local_player().position)==Vector2.ZERO,"local minimap centers each peer and retains all three allies")
	verify(map.threats.size()==1 and map.threats[0].count==1,"replicated bomber appears once on every local minimap")
	if server:
		w.broadcast("recv_full",[w.full_state()]);await stream(main,2)
	else:await wait(.4)
	ui.refresh();verify(ui.threats.size()==1 and ui.threats[0].armed,"full resync retains armed warning without duplicate markers")
	verify(map.resources_enabled==(w.local_player().class_id==1),"resource-layer choice stays local through full resync")
	if server:
		w.defenses[22000].hp=400;await stream(main,2)
	verify(await until(func():return w.defenses.has(22000) and w.defenses[22000].hp==400),"repair state reaches every peer")
	ui.refresh();verify(ui.repairs.is_empty(),"repaired building clears warning on all peers")
	if server:
		w.broadcast("recv_remove_defense",[22000,true]);w.broadcast("recv_enemy_dead",[22000]);w.is_night=false;w.director.active=false;w.director.revision+=1;await stream(main,2)
	verify(await until(func():return not w.enemies.has(22000) and not w.is_night),"death and dawn reach every peer")
	ui.refresh();verify(ui.threats.is_empty() and ui.repairs.is_empty() and ui.forecast.is_empty(),"all peers clear obsolete tactical alerts")
	map.refresh();verify(map.threats.is_empty(),"dead enemy disappears from every local minimap")
	await wait(2 if server else .5)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
