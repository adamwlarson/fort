extends SceneTree

var main:Node
var errors:Array[String]=[]
var seen_action:=false

func _initialize()->void:run.call_deferred()

func wait(t:float)->void:await create_timer(t).timeout

func verify(ok:bool,message:String)->void:
	if ok:print("PASS ",message)
	else:errors.append(message);push_error("NETWORK TEST FAILED: "+message)

func action(name:String)->void:
	var event:=InputEventAction.new();event.action=name;event.pressed=true
	Input.parse_input_event(event)

func run()->void:
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await wait(0.1)
	var server:bool="--server" in OS.get_cmdline_user_args()
	if server:
		main._host()
		main._start_match()
		var w:FortWorld=main.world
		w._spawn_defense("Watchtower",Vector3(15,0,0),0,false)
		w.recv_resource(0,0,false)
		w.resource_nodes[0].respawn=500
		w.recv_resource(48,6,false)
		w.recv_enemy(900,"Brute",Vector3(38,0,0),300)
		w.enemies[900].stun=500
		w.shared.wood=100
		var deadline:=Time.get_ticks_msec()+20000
		while (w.players.size()<4 or main.ready_peers.size()<3) and Time.get_ticks_msec()<deadline:await wait(0.1)
		verify(w.players.size()==4 and main.ready_peers.size()==3,"host receives all three world-ready clients")
		await wait(1)
		for id in w.players:
			if id==1:continue
			var p:FortPlayer=w.players[id]
			var rid:int=1+p.class_id
			w.broadcast("recv_teleport",[int(id),w.resource_nodes[rid].node.position+Vector3(1.5,0.1,0)])
		await wait(3.5)
		var total:=0
		for p in w.players.values():total+=p.total_carried()
		verify(total>=6,"client E inputs changed authoritative inventories")
		verify(w.resource_nodes[2].amount<12 and w.resource_nodes[3].amount<12 and w.resource_nodes[4].amount<12,"three remote gather locations changed")
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(4.6,0.1,2)])
		await wait(2)
		verify(w.shared.wood>100,"remote deposits increase shared stock")
		w.resource_nodes[5].respawn=500
		w.broadcast("recv_resource",[5,0,true])
		verify(w.tree_burst_count==1,"host plays tree destruction burst")
		for id in w.players:
			if id!=1:
				w.broadcast("recv_health",[int(id),0.0,10.0])
		await wait(0.7)
		for id in w.players:
			if id!=1:w._respawn(int(id))
		await wait(1.2)
		verify(w.players.size()==4,"crew remains connected after actions")
	else:
		main._join()
		var deadline:=Time.get_ticks_msec()+30000
		while (not is_instance_valid(main.world) or main.world.players.size()<4) and Time.get_ticks_msec()<deadline:await wait(0.1)
		verify(is_instance_valid(main.world),"join creates a world")
		if not is_instance_valid(main.world):quit(1);return
		var w:FortWorld=main.world
		await wait(0.6)
		verify(w.players.size()==4,"client sees four dwarves")
		var roles:Array=[]
		for p in w.players.values():roles.append(p.class_id)
		roles.sort()
		verify(roles==[0,1,2,3],"server assigns four distinct classes")
		verify(w.defenses.size()==1 and w.enemies.has(900) and w.resource_nodes[0].amount==0,"late join restores structures, enemy, depleted resource")
		verify(w.tree_burst_count==0,"late join does not replay historic tree destruction")
		var chunks:Array[Node]=w.resource_nodes[48].node.find_children("HarvestChunk_*","Node3D",true,false)
		var visible_chunks:=0
		for chunk in chunks:
			if chunk.visible:visible_chunks+=1
		verify(chunks.size()==6 and visible_chunks==3,"late join restores half-mined outcrop geometry")
		var p:FortPlayer=w.local_player()
		var rid:int=1+p.class_id
		while p.position.distance_to(w.resource_nodes[rid].node.position)>3 and Time.get_ticks_msec()<deadline:await wait(0.05)
		action("interact")
		await wait(0.20)
		verify(p.animation_player.current_animation=="Axe_Swing","remote action acknowledgment plays local swing")
		Input.action_release("interact")
		var observed:=false
		for i in 16:
			for other in w.players.values():
				if other.peer_id!=p.peer_id and other.action_time>0:observed=true
			await wait(0.025)
		verify(p.total_carried()>0,"client receives authoritative gathered pack")
		while p.position.distance_to(Vector3(4.6,0,2))>1 and Time.get_ticks_msec()<deadline:await wait(0.05)
		action("interact")
		await wait(0.4)
		Input.action_release("interact")
		verify(p.total_carried()==0 and w.shared.wood>100,"client receives deposit result")
		while p.health>0 and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(p.health==0,"client receives downed state")
		while p.health<=0 and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(p.health>0 and p.position.length()<8,"rescue teleports controlling client")
		verify(w.resource_nodes[5].amount==0 and w.tree_burst_count==1,"client receives tree destruction and plays one burst")
		await wait(2.0)
	print("NETWORK_RESULT ", "SERVER" if server else "CLIENT", " ", "PASS" if errors.is_empty() else "FAIL", " ",errors)
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free()
	await wait(0.15)
	quit(0 if errors.is_empty() else 1)
