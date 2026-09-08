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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24777
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();main.world.phase_time=1000;main.world.shared={"wood":100,"stone":100,"crystal":100,"iron":100,"aether":100}
		main.world.recv_defense(800,"Ballista",Vector3(20,.6,0),0,100,false);main.world.defenses[800].paid={"wood":20,"stone":10}
	else:main._join()
	verify(await until(func():return is_instance_valid(main.world)),"peer loads clearance run")
	if not is_instance_valid(main.world):quit(1);return
	var w:FortWorld=main.world;var p:=w.local_player();p.set_physics_process(false)
	if server:w.set_process(false)
	var rock:=FortLandscape.place(w,"moss_rock",Vector3(26,0,7));FortArt.box_collider(rock,Vector3.ONE,Vector3.UP*.5)
	w.scenery_keepouts.append({"pos":rock.position,"radius":1.25,"node":rock,"clearable":true})
	var target:={"x":1,"z":0,"floor":0};var initial:=FortCastleClearance.inspect(w.castle,target)
	verify(initial.resources.size()>0 and 800 in initial.defenses,"peers agree on occupied resource footprint and defense")
	if server:
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers connected before clearance")
		await wait(.5)
		for id in w.players:
			if w.players[id].class_id==1:w.broadcast("recv_mount",[int(id),800,Vector3(20,.6,1.2)])
		for id in w.players:
			if w.players[id].class_id!=1:w.broadcast("recv_teleport",[int(id),w.castle.rooms["0:0:0"].sign])
	else:
		if p.class_id==2:
			verify(await until(func():return p.position.distance_to(w.castle.rooms["0:0:0"].sign)<1),"remote architect reaches keep sign")
			var payload:={"from":"0:0:0","target":target,"kind":"Courtyard","revision":w.castle.revision,"clearance_token":"stale"}
			w.request_action("castle_plan",payload);await wait(.3)
			verify(w.defenses.has(800) and not w.castle.rooms.has("1:0:0"),"server rejects unconfirmed remote demolition")
			payload.clearance_token=FortCastleClearance.inspect(w.castle,target).token
			w.request_action("castle_plan",payload);w.request_action("castle_plan",payload)
	verify(await until(func():return w.castle.rooms.has("1:0:0") and not w.defenses.has(800)),"remote confirmed expansion removes defense and replicates blueprint")
	verify(await until(func():return w.shared.wood==110 and w.shared.stone==105),"duplicate packets credit only one exact shared refund")
	for id in initial.resources:verify(w.resource_nodes[id].amount==0 and not w.resource_nodes[id].node.visible,"cleared resources vanish for every peer")
	verify(not rock.visible and rock.find_children("*","CollisionObject3D",true,false)[0].collision_layer==0,"scenery clearance and disabled collision replicate")
	if p.class_id==1:verify(p.mounted_ballista==-1,"owning client is safely dismounted from removed ballista")
	if server:w.broadcast("recv_full",[w.full_state()]);await wait(3)
	else:await wait(.5)
	verify(w.shared.wood==110 and not w.defenses.has(800),"full resync does not repeat salvage or restore removed defense")
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
