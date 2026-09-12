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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24811
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:main._host();main._start_match();main.world.phase_time=1000
	else:main._join()
	verify(await until(func():return is_instance_valid(main.world)),"peer loads recovery test")
	if not is_instance_valid(main.world):quit(1);return
	var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
	if server:w.set_process(false)
	var trap:=StaticBody3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2,2,2)
	var col:=CollisionShape3D.new();col.shape=shape;trap.add_child(col);w.add_child(trap);trap.position=Vector3(0,1.6,4)
	verify(await until(func():return w.players.size()==4),"four peers connected")
	var rescued:=-1
	for id in w.players:
		if w.players[id].class_id==1:rescued=id
	if server:
		verify(await until(func():return main.ready_peers.size()==3),"all clients acknowledge world readiness before recovery events")
		await wait(.3)
		w.broadcast("recv_health",[rescued,37.0,0.0]);w.broadcast("recv_teleport",[rescued,Vector3(0,.65,4),false])
	if p.class_id==1:
		verify(await until(func():return p.position.distance_to(Vector3(0,.65,4))<.05 and p.health==37),"owning client reaches controlled stuck position")
		p.carrying={"wood":7};p.invulnerable=0
		# Payload cannot choose another player or arbitrary destination.
		w.request_action("unstuck",{"id":1,"position":Vector3(999,999,999)})
		verify(await until(func():return p.position.distance_to(Vector3(0,.65,4))>1),"remote recovery request teleports its owning client")
		verify(p.health==37 and p.invulnerable==0 and p.carrying.wood==7,"remote recovery does not heal, protect or clear the pack")
		var safe:=p.position;w.request_action("unstuck");await wait(.3)
		verify(p.position==safe,"server cooldown rejects duplicate remote request")
	else:
		verify(await until(func():return w.players[rescued].health==37 and w.players[rescued].target_position.distance_to(Vector3(0,.65,4))>1),"host and observers receive recovered target")
	await wait(.5)
	var target:FortPlayer=w.players[rescued]
	verify(not FortRecovery.occupied(w,target,target.target_position),"replicated destination is clear")
	verify(w.players[1].position.distance_to(Vector3(-.9,.7,4.8))<2,"forged target cannot move host")
	if server:verify(w.cooldowns.has("%d/unstuck"%rescued) and not w.cooldowns.has("1/unstuck"),"server attributes cooldown to actual requesting peer")
	# Exercise the new owner-to-host fall recovery, not merely direct local teleport.
	if server:
		w.clock+=3;w.broadcast("recv_teleport",[rescued,Vector3(0,-6,0),false])
		verify(await until(func():return w.cooldowns.has("%d/fall_recovery"%rescued) and w.players[rescued].position.y>0),"host validates and resolves remote fall-through recovery")
		w.broadcast("recv_defense",[21999,"Barricade",Vector3(80,0,80),0.0,100.0,false])
	elif p.class_id==1:
		verify(await until(func():return p.position.y< -5),"owning client receives controlled below-world position")
		p._physics_process(1.0/60)
		verify(await until(func():return p.position.y>0),"local fall detection requests and receives a host-selected safe landing")
		verify(p.health==37 and p.invulnerable==0 and p.carrying.wood==7,"remote fall recovery preserves health and inventory")
	verify(await until(func():return w.defenses.has(21999)),"all peers observe completed authoritative fall recovery")
	verify(w.players.has(rescued) and w.players[rescued].target_position.y>0 and not FortRecovery.occupied(w,w.players[rescued],w.players[rescued].target_position),"fall landing is clear and synchronized for every peer")
	# Keep the recovered peer alive while the observers inspect its replicated state.
	await wait(1)
	if server:await wait(2)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
