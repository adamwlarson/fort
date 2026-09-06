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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24617
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world
		w._advance_phase();w.director.tick(3.1)
		verify(w.director.crew==1,"host begins a solo assault before late join")
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four processes connect to balance session")
		# Snapshot transmission continues while progression is advanced explicitly.
		await wait(.5)
		verify(w.director.crew==1,"joining clients do not increase the current assault")
		w.director.tick(w.director.pulse_start(1)-w.director.elapsed+.01)
		w.progression._activate(1)
		var peer_id:=-1
		for id in w.players:
			if id!=1:peer_id=int(id);break
		w.players[peer_id].invulnerable=0;w._set_health(peer_id,0)
		verify(w.director.crew==4 and w.players[peer_id].down_time==18,"four-dwarf pressure includes downed teammate")
		await wait(2)
		w.director.tick(w.director.pulse_end(1)-w.director.elapsed+.1)
		await wait(2)
		w._advance_phase();await wait(2)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world)),"late client loads expedition")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world
		verify(await until(func():return w.director.active),"late join restores live director")
		verify(w.director.crew==1 and w.director.pulse==0,"late join sees original solo assault unchanged")
		verify(await until(func():return w.director.crew==4 and w.director.pulse==1),"next assault pressure and fronts replicate")
		verify(w.director.lanes().size()==4,"all peers see four warning directions")
		verify(await until(func():return w.enemies.has(100014)),"scaled camp chief replicates")
		verify(is_equal_approx(w.enemies[100014].max_hp,1275),"four-player camp chief has correct health")
		verify(await until(func():
			for p in w.players.values():
				if p.health<=0:return true
			return false),"teammate knockdown replicates without reducing crew pressure")
		verify(await until(func():return w.objective_text().contains("BREATHER")),"client HUD shows synchronized repair break")
		verify(await until(func():return not w.is_night and not w.director.active),"dawn reliably clears assault state")
		await wait(.3)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
