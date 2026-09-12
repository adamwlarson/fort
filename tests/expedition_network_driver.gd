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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24627
	var server:bool="--server" in OS.get_cmdline_user_args();var role:="server"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):role=arg.trim_prefix("--role=")
	main.name_edit.text=role
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;w.expedition.configure(909);w.set_hearth_level(8)
		w.shared={"wood":1000,"stone":1000,"crystal":1000,"iron":1000,"aether":1000}
		var host:=w.local_player();host.position=Vector3(0,0,25)
		w._spawn_defense("Watchtower",Vector3(0,0,22),0,false);w.construction.begin(1,1,{"wood":18,"stone":8},"build")
		for i in 8:w.clock+=.8;w.construction.work(1,1)
		host.position=Vector3(0,0,4)
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers receive expanded seeded frontier")
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(-4.6,0,2)])
		verify(await until(func():return w.pets.pets.size()==3),"remote crew recruits exactly three shared pets")
		verify(await until(func():
			for pet in w.pets.pets.values():
				if pet.resource!="rest":return false
			return true),"remote pet assignments reach host")
		await wait(.6)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(0,0,25)])
		verify(await until(func():return not w.defenses.has(1)),"remote crew salvages a completed building")
		verify(w.shared.wood==924,"racing salvage requests refund original paid cost only once")
		w.wave=9;w._advance_phase();await wait(1.3);w._advance_phase();await wait(1.3)
		w._damage_enemy(900010,100000);await wait(2)
	else:
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client loads Fort 9")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world;var p:=w.local_player();var index:=int(role.trim_prefix("client"))-1
		verify(await until(func():return w.hearth_level==8 and w.resource_nodes.keys().filter(func(id):return int(id)<10000).size()==594),"late join receives all eight hearth tiers and resource nodes")
		var expected:=FortExpedition.new(w);expected.configure(909)
		verify(w.expedition.order==expected.order and w.resource_nodes[1400].kind==expected.biome(4).resources[0],"late join biome order and resource types match server seed")
		verify(w.defenses[1].paid.wood==18,"late join receives paid construction ledger")
		var build_revision:int=w.defenses[1].work_revision
		await until(func():return p.position.distance_to(Vector3(-4.6,0,2))<2)
		# Assigning a pet also advances the shared revision. Wait for the
		# preceding client's assignment, not just its recruitment snapshot,
		# before submitting the next deliberately duplicated transaction.
		verify(await until(func():
			if w.pets.pets.size()<index:return false
			for pet in w.pets.pets.values():
				if pet.resource!="rest":return false
			return true),"pet recruitment slot and preceding assignments are synchronized")
		w.request_action("recruit_pet",{"kind":index,"revision":w.pets.revision});w.request_action("recruit_pet",{"kind":index,"revision":w.pets.revision})
		verify(await until(func():return w.pets.pets.has(index+1)),"duplicate recruit request creates one pet")
		w.request_action("assign_pet",{"id":index+1,"resource":"rest","revision":w.pets.pets[index+1].revision})
		verify(await until(func():return w.pets.pets.size()==3),"all clients see all three companions")
		verify(await until(func():return w.pets.pets[index+1].resource=="rest"),"resource assignment replicates")
		await until(func():return p.position.distance_to(Vector3(0,0,25))<2)
		w.request_action("salvage_defense",{"id":1,"revision":build_revision});w.request_action("salvage_defense",{"id":1,"revision":build_revision})
		verify(await until(func():return not w.defenses.has(1)),"salvaged building disappears remotely")
		verify(await until(func():return w.enemies.has(900010)),"milestone boss replicates")
		verify(await until(func():return not w.is_night),"boss encounter reaches dawn without ending campaign")
		verify(w.enemies.has(900010) and not w.ended,"boss persists at dawn on client")
		verify(await until(func():return "Runeblade" in p.owned_weapons and w.expedition.bosses_defeated==1),"boss defeat rewards and counter replicate")
		await wait(.3)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
