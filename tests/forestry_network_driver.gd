extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAILED ")+message)
	if not ok:failures+=1
func until(test:Callable,seconds:=15.0)->bool:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<end:await wait(.05)
	return test.call()
func amber_id(w:FortWorld)->int:
	for id in w.resource_nodes:
		if w.resource_nodes[id].get("species","")=="Amberwood":return id
	return -1
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24647
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host();main._start_match();var w:FortWorld=main.world;w.expedition.configure(909);w.set_hearth_level(8)
		var id:=amber_id(w);var r:Dictionary=w.resource_nodes[id]
		w.broadcast("recv_resource",[id+1,0,false]);w.resource_nodes[id+1].respawn=100
		verify(await until(func():return w.players.size()==4 and main.ready_peers.size()==3),"four peers join seeded harvestable forests")
		for peer in w.players:
			if peer==1:continue
			var p:FortPlayer=w.players[peer];p.weapon_levels.Axe=2;p.weapon_revision+=1
			w.broadcast("recv_teleport",[int(peer),r.node.position+Vector3(0,0,2)])
		verify(await until(func():return r.amount==0),"remote dwarves cooperatively fell the same amber tree")
		var total:=0
		for p in w.players.values():total+=p.total_carried()
		print("FORESTRY_PACK_AUDIT ",total," ",w.players.values().map(func(p):return {"class":p.class_id,"pack":p.carrying,"pos":p.position}))
		verify(total==24,"concurrent chopping never duplicates or loses timber")
		verify(r.node.get_node("TreeTrunk").collision_layer==0,"host collision clears immediately")
		await wait(.8)
		w.broadcast("recv_resource",[id,FortForestry.capacity(r),false]);await wait(1.0)
	else:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--join-ip="):main.address_edit.text=arg.trim_prefix("--join-ip=")
		if "--role=client3" in OS.get_cmdline_user_args():await wait(1)
		main._join();verify(await until(func():return is_instance_valid(main.world)),"client enters forest expedition")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world
		verify(await until(func():return w.hearth_level==8),"all eight rings restore on late join")
		var id:=amber_id(w);var r:Dictionary=w.resource_nodes[id];var p:=w.local_player()
		verify(w.resource_nodes[id+1].amount==0 and not w.resource_nodes[id+1].node.visible,"previously felled grove tree remains absent on late join")
		verify(await until(func():return p.position.distance_to(r.node.position)<2.7 and int(p.weapon_levels.get("Axe",1))>=2),"axe upgrade and harvest position replicate")
		for i in 18:
			if r.amount<=0:break
			w.request_action("interact",{});await wait(.45)
		verify(r.amount==0 and r.node.get_node("TreeTrunk").collision_layer==0,"tree depletion and cleared collision replicate to clients")
		verify(await until(func():return r.amount==24),"regrowth replicates the species-specific capacity")
		verify(r.node.visible and r.node.get_node("TreeTrunk").collision_layer==1,"regrowth restores visible trunk collision on every peer")
		await wait(.2)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if failures==0 else "FAIL")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1);quit(failures)
