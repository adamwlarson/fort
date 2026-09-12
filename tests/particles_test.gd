extends SceneTree

var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures += 1

func run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main._host()
	main._start_match()
	var w: FortWorld = main.world
	for id in [0,1,2,3,48]: w.resource_nodes[id].respawn = 500
	await create_timer(0.1).timeout
	var fire := w.find_child("Campfire",true,false)
	check(fire != null, "fort has new campfire")
	if fire:
		for key in ["Flames","Embers","Smoke"]:
			var emitter: CPUParticles3D = fire.get_node(key)
			check(emitter.emitting and not emitter.one_shot, key+" emits continuously")
		check(fire.find_children("*","MeshInstance3D",true,false).size()>0,"campfire log asset loaded")
		var before: float = fire.fire_light.light_energy
		await create_timer(0.13).timeout
		check(absf(before-fire.fire_light.light_energy)>0.001,"hearth light flickers")
	w.recv_resource(0,10,true)
	check(w.tree_burst_count==0,"ordinary chop does not play destruction")
	for id in 3: w.recv_resource(id,0,true)
	check(w.tree_burst_count==3,"oak pine and birch emit destruction")
	check(get_nodes_in_group("tree_destruction_fx").size()==3,"bursts attached independently of trees")
	w.recv_resource(0,0,true)
	w.recv_resource(3,0,false)
	check(w.tree_burst_count==3,"duplicate depletion and late-join state do not replay bursts")
	w.recv_resource(48,0,true)
	check(w.tree_burst_count==3,"stone does not emit wood particles")
	await create_timer(2.0).timeout
	check(not w.resource_nodes[0].node.visible,"tree hides after destruction animation")
	check(get_nodes_in_group("tree_destruction_fx").size()==3,"leaves outlive hidden tree")
	await create_timer(1.3).timeout
	check(get_nodes_in_group("tree_destruction_fx").is_empty(),"one-shot effects clean up")
	w.recv_resource(0,12,false)
	w.recv_resource(0,0,true)
	check(w.tree_burst_count==4,"regrown trees emit again")
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free()
	await create_timer(0.1).timeout
	print("PARTICLES_TEST_", "OK" if failures==0 else "FAILED")
	quit(failures)
