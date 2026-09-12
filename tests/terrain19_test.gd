extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func ray(w:Node3D,a:Vector3,b:Vector3)->Dictionary:
	return w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24789;main._host();main._start_match()
	var w:FortWorld=main.world;w.set_process(false);w.local_player().set_physics_process(false)
	w.expedition.configure(1919);w.encounters.unlock(1);w.set_hearth_level(2)
	await physics_frame;await physics_frame
	var center:=FortTerrain.origin(1919)
	print("TERRAIN_CENTER ",center)
	check(w.frontier.has_node("HollowbackRidge"),"hearth 2 creates the ridge")
	check(FortTerrain.origin(1919)==center,"terrain position is deterministic")
	var safe_layouts:=true
	for seed_value in 100:
		var p:=FortTerrain.origin(seed_value)
		for spec in FortEncounters.layout(seed_value):
			if p.distance_to(spec.pos)<float(spec.radius)+40:safe_layouts=false
	check(safe_layouts,"100 expedition seeds preserve encounter clearings")
	check(FortTerrain.safe_position(center+Vector3(0,1,0),1919).y==1,"safe relocation preserves a dwarf inside the cavern")
	check(FortTerrain.safe_position(center+Vector3(0,0,12),1919).y>5,"old ground-level positions inside the new hill move onto its surface")
	check(ray(w,center+Vector3(-28,1,0),center+Vector3(28,1,0)).is_empty(),"cavern entrance-to-exit centerline is clear")
	check(not ray(w,center+Vector3(0,1,0),center+Vector3(0,1,5)).is_empty(),"cavern side walls have collision")
	var ceiling:=ray(w,center+Vector3(0,1,0),center+Vector3(0,10,0))
	check(not ceiling.is_empty() and absf(ceiling.position.y-FortTerrain.ceiling_height(0))<.05,"cavern roof has an underside at the visible ceiling")
	var summit:=ray(w,center+Vector3(0,12,0),center+Vector3(0,6,0))
	check(not summit.is_empty() and absf(summit.position.y-8)<.05,"summit collision matches eight-unit hill surface")
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1;walker.floor_snap_length=.6
	var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.35
	var shape:=CollisionShape3D.new();shape.shape=capsule;shape.position.y=.8;walker.add_child(shape);w.add_child(walker)
	walker.position=center+Vector3(-28,.1,0)
	for i in 310:
		await physics_frame;walker.velocity=Vector3(12,walker.velocity.y-24/60.0,0);walker.move_and_slide()
	check(walker.position.x>center.x+27 and absf(walker.position.y)<.15,"dwarf-sized body walks all the way through the cavern")
	walker.position=center+Vector3(0,.1,-32);walker.velocity=Vector3.ZERO
	for i in 205:
		await physics_frame;walker.velocity=Vector3(0,walker.velocity.y-24/60.0,10);walker.move_and_slide()
	check(walker.position.y>7.4 and walker.position.z>center.z-5,"dwarf-sized body climbs the slope without jumping")
	var resource:Dictionary=w.resource_nodes[29000]
	check(resource.node.find_child("SolidGeometry",true,false).collision_layer==1,"new deposits are solid")
	w.recv_resource(29000,0,false)
	check(resource.node.find_child("SolidGeometry",true,false).collision_layer==0,"depleted deposit leaves no invisible collision")
	w.recv_resource(29000,6,false)
	check(resource.node.find_child("SolidGeometry",true,false).collision_layer==1,"respawning deposit restores collision")
	var approach:Vector3=resource.node.position+Vector3(0,0,1.8)
	check(FortSolids.harvest_reachable(w,approach,resource.node),"pet harvest sightline ignores the target deposit itself")
	var blocker:=Visuals.add_static_collision(w,BoxShape3D.new(),resource.node.position+Vector3(0,.7,.9))
	await physics_frame;await physics_frame
	check(not FortSolids.harvest_reachable(w,approach,resource.node),"pet cannot harvest through an intervening wall")
	blocker.queue_free()
	var all_solid:=true
	for key in FortSolids.KEYS:
		var model:=FortArt.asset(key)
		if model==null:print("MISSING SOLID ASSET ",key);all_solid=false;continue
		var body:=model.get_node_or_null("SolidGeometry")
		if body==null:all_solid=false
		else:
			var collision:Shape3D=body.get_child(0).shape
			if collision is ConcavePolygonShape3D and collision.get_faces().is_empty():all_solid=false
			if collision is ConvexPolygonShape3D and collision.points.size()<4:all_solid=false
		model.free()
	check(all_solid,"all audited solid prop and mineral assets have nonempty collision")
	var arch:=FortLandscape.place(w,"ruin_arch",Vector3(500,0,0))
	var chest:=FortLandscape.place(w,"treasure_chest",Vector3(510,0,0))
	await physics_frame;await physics_frame
	check(ray(w,Vector3(500,1.2,-3),Vector3(500,1.2,3)).is_empty(),"ruin arch opening remains traversable")
	check(not ray(w,Vector3(501.42,1.6,-3),Vector3(501.42,1.6,3)).is_empty(),"ruin arch pillar blocks movement and projectiles")
	check(not ray(w,Vector3(500,3.3,-3),Vector3(500,3.3,3)).is_empty(),"ruin arch overhead stones have collision")
	check(not ray(w,Vector3(508,.4,0),Vector3(512,.4,0)).is_empty(),"treasure chest has physical collision")
	arch.queue_free();chest.queue_free()
	var fire:=w.find_child("Campfire",true,false) as Node3D
	var logs:=fire.get_child(0) as Node3D;var bottom:=INF
	for vertex in FortSolids.vertices(logs):bottom=minf(bottom,(logs.global_transform*vertex).y)
	check(absf(bottom-FortCastle.BASE)<.01,"campfire coal bed sits on the castle floor")
	if DisplayServer.get_name()!="headless":
		w.hud.hide();var camera:=Camera3D.new();w.add_child(camera);camera.position=center+Vector3(40,29,43);camera.look_at(center+Vector3(0,2,0));camera.current=true
		await create_timer(.3).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/terrain19_ridge.png"))
		camera.position=center+Vector3(21,2.8,0);camera.look_at(center+Vector3(-6,2,0))
		await create_timer(.2).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/terrain19_cavern.png"))
		camera.position=Vector3(4,3.5,5);camera.look_at(Vector3(0,1,0))
		await create_timer(.2).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/terrain19_hearth.png"))
	var checkpoint:=FortSave.capture(w)
	checkpoint.world.expedition.erase("terrain_enabled")
	# Simulate a legacy checkpoint whose builder already occupied the new ridge.
	w.recv_defense(19019,"Watchtower",center,0,100,false);checkpoint=FortSave.capture(w);checkpoint.world.expedition.erase("terrain_enabled")
	main._leave_game("terrain compatibility check");await create_timer(.1).timeout;main.port_edit.value=24789;main.pending_save=checkpoint;main._host();main._start_match();w=main.world;w.set_process(false)
	check(not w.expedition.terrain_enabled and not w.frontier.has_node("HollowbackRidge") and w.defenses.has(19019),"older saves retain buildings instead of burying them in new terrain")
	check(w.full_state().expedition.terrain_enabled==false,"legacy terrain compatibility is synchronized to joining players")
	await create_timer(.3).timeout
	main.queue_free();await create_timer(.3).timeout;print("TERRAIN19_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
