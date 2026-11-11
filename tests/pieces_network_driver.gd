extends SceneTree
# Four peers build with pieces: late join, concurrent placement, removal and pickups, damage, collapse.
const P:=preload("res://scripts/fort_pieces.gd")
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
		w.clock+=.05;w.pieces.tick(.05);w.broadcast("recv_snapshot",[w.snapshot()])
func until(test:Callable,seconds:=10.0)->bool:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:pump();await wait(.05)
	return test.call()
func phase(value:int)->void:
	w.shared.crystal=value;w.broadcast("recv_full",[w.full_state()])
func own(class_id:int)->int:return FortPieces.key(P.EZ,class_id-2,2,0)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24765
	server="--server" in OS.get_cmdline_user_args()
	var contested:=FortPieces.key(P.EX,-3,0,0);var hut_wall:=FortPieces.key(P.EX,2,-2,0);var hut_roof:=FortPieces.key(P.FILL,2,-2,1)
	if server:
		main._host();main._start_match();w=main.world;w.set_process(false);w.local_player().set_physics_process(false)
		var b:=w.pieces
		w.shared={"wood":1000,"stone":1000,"iron":1000,"crystal":1000,"aether":1000}
		b.starter()
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers join a fort that already has pieces")
		phase(1001)
		verify(await until(func():return b.pieces.has(own(1)) and b.pieces.has(own(2)) and b.pieces.has(own(3)) and b.pieces.has(contested)),"every client's wall and the contested wall arrive on the host")
		await wait(.6)
		verify(b.pieces.size()==16 and w.shared.wood==984,"three clients racing for one slot build it once and pay once")
		phase(1002)
		verify(await until(func():return not b.pieces.has(own(1)) and b.drops.size()==1),"a client removes its wall and the wood lands on the ground")
		var builder:=-1
		for id in w.players:
			if w.players[id].class_id==1:builder=int(id)
		var before:int=w.players[builder].total_carried()
		w.players[builder].position=b.drops.values()[0].pos
		verify(await until(func():return b.drops.is_empty()),"the host hands the pile to the dwarf standing on it")
		verify(w.players[builder].total_carried()==before+4,"the full wall cost went into that dwarf's pack")
		phase(1003);await wait(.6)
		b.damage(own(2),100.0);phase(1004);await wait(.6)
		b.damage(hut_wall,9999.0)
		verify(not b.pieces.has(hut_wall) and b.pieces.has(hut_roof),"one of two supporting walls falls and the roof holds")
		b.damage(FortPieces.key(P.EZ,2,-3,0),9999.0)
		verify(not b.pieces.has(hut_roof),"the second wall falls and the roof collapses")
		phase(1005);await wait(.8)
		var captured:=FortSave.capture(w)
		verify(FortSave.validate(captured)=="" and captured.world.pieces.data.size()==b.pieces.size()*3,"a multiplayer checkpoint with pieces validates")
		phase(1006);await wait(.6)
	else:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client connects to the building expedition")
		if not is_instance_valid(main.world):quit(1);return
		w=main.world;w.set_process(false);var p:=w.local_player();p.set_physics_process(false)
		var b:=w.pieces
		verify(await until(func():return b.pieces.size()>=12),"late join receives the existing pieces")
		verify(b.pieces.has(hut_roof) and b.pieces[hut_roof].kind=="ThatchCap" and b.unsupported().is_empty(),"the received fort is complete and supported")
		await until(func():return w.shared.crystal==1001)
		w.request_action("piece_place",{"kind":"WoodWall","key":own(p.class_id),"turn":0})
		await wait(.5)
		w.request_action("piece_place",{"kind":"WoodWall","key":contested,"turn":1})
		verify(await until(func():return b.pieces.has(own(1)) and b.pieces.has(own(2)) and b.pieces.has(own(3)) and b.pieces.has(contested)),"every peer sees all four new walls")
		verify(await until(func():return w.shared.crystal==1002),"removal phase arrives")
		verify(b.pieces.size()==16,"piece counts agree before removal")
		if p.class_id==1:w.request_action("piece_remove",{"key":own(1)})
		verify(await until(func():return not b.pieces.has(own(1))),"the removed wall disappears for everyone")
		verify(await until(func():return w.shared.crystal==1003),"pickup phase arrives")
		verify(b.drops.is_empty(),"the collected pile is gone for everyone")
		verify(await until(func():return w.shared.crystal==1004),"damage phase arrives")
		verify(is_equal_approx(b.pieces[own(2)].hp,250.0),"piece damage replicates")
		verify(await until(func():return w.shared.crystal==1005),"collapse phase arrives")
		verify(not b.pieces.has(hut_wall) and not b.pieces.has(hut_roof) and b.pieces.has(contested),"the collapse replicates and leaves the rest standing")
		await until(func():return w.shared.crystal==1006)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
