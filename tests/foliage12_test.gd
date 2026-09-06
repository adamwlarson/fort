extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func capture(key:String)->void:
	if DisplayServer.get_name()=="headless":return
	await wait(.3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/foliage12_"+key+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24657;main._host();main._start_match();await wait(.2)
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.hud.hide()
	check(w.resource_nodes.size()==90,"starter economy keeps its original ninety deposits")
	var camera:=Camera3D.new();w.add_child(camera);camera.current=true;camera.far=180
	camera.position=Vector3(-23,3,40);camera.look_at(Vector3(-31,1,28));await capture("woodland")
	w.expedition.configure(909);w.set_hearth_level(8)
	var edge:=0;var amber:=0;var caps:=0;var original:=0
	for id in w.resource_nodes:
		if id<10000:original+=1
		elif id<20000:edge+=1
		else:
			var r:Dictionary=w.resource_nodes[id]
			if r.kind=="wood":amber+=1
			else:caps+=1
	check(original==594 and edge>70 and amber>150 and caps>150,"original deposits plus individually harvestable edge woods and two biome forests")
	check(w.resource_root.find_children("HarvestTree*","Node3D",true,false).size()==edge+amber+caps,"every added canopy has a registered harvest node")
	check(w.find_children("biome_amberwood_batch","MultiMeshInstance3D",true,false).is_empty(),"no unchoppable amber scenery remains")
	check(w.find_children("biome_mycelium_batch","MultiMeshInstance3D",true,false).is_empty(),"no unchoppable mushroom scenery remains")
	for species in ["amber","mooncap","starcap"]:
		var spec:Dictionary=FortForestry.SPECIES[species];var id:=-1
		for candidate in w.resource_nodes:
			if w.resource_nodes[candidate].get("species","")==spec.name:id=candidate;break
		check(id>=0,species+" exists naturally")
		if id<0:continue
		var r:Dictionary=w.resource_nodes[id];p.position=r.node.position+Vector3(0,0,2);p.carrying={};p.weapon_levels={}
		var stock:int=r.amount;w._gather(1,id)
		check(r.amount==stock and p.total_carried()==0,species+" rejects insufficient axe without consuming resources")
		check(w.context_prompt(p).contains("Requires"),"required axe upgrade is explained in the actual interaction prompt")
		p.weapon_levels.Axe=spec.axe;p.carry_limit=100
		for i in 20:w._gather(1,id)
		check(r.amount==0 and p.total_carried()==stock and p.carrying.get(spec.kind,0)==stock,species+" yields exactly its advertised material and capacity")
		check(r.node.get_node("TreeTrunk").collision_layer==0,species+" immediately clears its collision")
		await wait(1.95)
		check(not r.node.visible,species+" plays its falling animation and then hides")
		var snapshot:=w.full_state();check(snapshot.resources[id]==0,"late join state includes felled "+species)
		w.recv_resource(id,FortForestry.capacity(r),false)
		check(r.amount==spec.capacity and r.node.visible and r.node.get_node("TreeTrunk").collision_layer==1,species+" restores its correct capacity and collision")
		p.position=r.node.position+Vector3(0,0,7)
		w._gather(1,id);check(r.amount==spec.capacity,"remote out-of-reach gather is rejected")
		w.recv_resource(id,0,false);w._spawn_defense("Barricade",r.node.position,0,false)
		check(not w.resource_respawn_clear(r),"felled "+species+" cannot regrow inside construction")
		w.recv_remove_defense(w.next_defense_id-1)
		camera.position=r.node.position+Vector3(8,4,10);camera.look_at(r.node.position+Vector3.UP*1.8)
		w.recv_resource(id,spec.capacity,false);await capture(species)
		check(FortForestry.pet_can_harvest(r,8,643) and not FortForestry.pet_can_harvest(r,1,73),"pets respect workshop training and ward bounds")
	check(FortFoliage.clump_mesh().get_surface_count()==1,"curved five-blade grass clump has shared geometry")
	# Isolate the creature silhouettes for review; gameplay was exercised above.
	for r in w.resource_nodes.values():r.node.hide()
	for kind in ["emberdrake","frostwyrm"]:
		var model:=FortArt.asset(kind);w.add_child(model);model.position=Vector3(0,0,-18)
		var animator:=FortPlayer.find_animation(model)
		for clip in ["Idle","Walk","Attack","Hit","Death"]:
			check(animator!=null and animator.has_animation(clip),kind+" preserves "+clip)
			animator.play(clip);animator.seek(.35,true)
		animator.play("Idle");animator.seek(0,true)
		camera.position=model.position+Vector3(5,3.4,6);camera.look_at(model.position+Vector3(0,1.8,0));await capture(kind)
		model.queue_free();await wait(.05)
	if DisplayServer.get_name()!="headless":
		var patches:=w.find_children("GrassPatch","MultiMeshInstance3D",true,false)
		check(patches.size()>100 and patches[0].visibility_range_end==105,"grass is spatially batched with culling beyond the furthest faded blade")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();main.queue_free();await wait(.1)
	print("FOLIAGE12_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
