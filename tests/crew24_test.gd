extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func wait()->void:await create_timer(.15).timeout
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await wait();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/crew24_"+name+".png"))
func run()->void:
	FortSave.test_directory="res://build/crew24_save_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24767;main._host()
	for i in range(1,8):main.player_info[i+1]={"name":"Long Dwarf Name %d"%i,"class":i,"ready":true}
	main._refresh_lobby();await wait()
	check(main.lobby_roster.get_child_count()==8 and main.lobby_roster.columns==2,"lobby displays eight numbered dwarf choices in two columns")
	check(main.lobby.get_global_rect().end.y<=720,"full host lobby including action buttons fits the viewport")
	await capture("lobby")
	var roster:Dictionary=main.player_info.duplicate(true)
	main.player_info={1:roster[1]}
	main._start_match();var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false)
	for i in range(1,8):w.add_network_player(i+1,roster[i+1])
	for dwarf in w.players.values():dwarf.set_physics_process(false)
	check(w.players.size()==8,"eight distinct slots instantiate")
	var positions:Array=[]
	for dwarf in w.players.values():
		check(dwarf.role_id==dwarf.class_id%4 and dwarf.health==GameData.class_data(dwarf.class_id).hp,"slot %d has correct ability role and health"%dwarf.class_id)
		check(dwarf.carry_limit==(26 if dwarf.role_id==3 else 18),"slot %d has correct carrying capacity"%dwarf.class_id)
		check(dwarf.animation_player.has_animation("Idle") and dwarf.animation_player.has_animation("Walk") and dwarf.animation_player.has_animation("Axe_Swing"),"slot %d retains authored skeletal animations"%dwarf.class_id)
		for pos in positions:check(pos.distance_to(dwarf.position)>.7,"spawn pads do not overlap")
		positions.append(dwarf.position)
		for mesh in dwarf.visual_root.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				var mat:Material=mesh.get_active_material(surface)
				if dwarf.class_id>=4 and mat.resource_name.get_slice(".",0) in ["FortArt2_red13","FortArt2_teal13","FortArt2_ochre13","FortArt2_green13"]:
					check(mat.albedo_color.is_equal_approx(GameData.class_data(dwarf.class_id).color.darkened(.12)),"variant headwear and cloak share the intended palette")
	var budgets:Array=[]
	for count in range(1,9):
		budgets.append(FortBalance.budget(10,4,count))
		if count>1:check(budgets[-1]>budgets[-2],"raid budget increases for crew %d"%count)
		check(FortBalance.active_cap(30,count)<=100 and FortBalance.fronts(30,count)<=4,"crew %d keeps bounded active enemies and real map fronts"%count)
	check(is_equal_approx(FortBalance.camp(3,8).boss_hp/FortBalance.camp(3,4).boss_hp,3.1/1.7),"eight-player camp boss scaling extends existing curve")
	check(FortBalance.colossus_multiplier(8)>FortBalance.colossus_multiplier(4) and FortBalance.wilderness_multiplier(8)>FortBalance.wilderness_multiplier(4),"large crews also scale colossi and wilderness encounters")
	w.wave=8;w.is_night=true;w.director.start();check(w.director.crew==8 and w.director.lane_count()==4,"raid director recognizes eight live or downed players")
	w.is_night=false
	w.hud._process(0);check(w.hud.crew_right.visible and w.hud.crew_right.text.contains("8 "),"compact HUD includes eighth dwarf")
	for dwarf in w.players.values():dwarf.position=Vector3(0,.7,5)
	w.hud.map.refresh();check(w.hud.map.crew.size()==7,"minimap retains all seven teammates")
	for i in w.hud.map.crew.size():
		for j in range(i+1,w.hud.map.crew.size()):check(w.hud.map.crew[i].pos.distance_to(w.hud.map.crew[j].pos)>=12,"co-located teammates have separate minimap markers")
	for dwarf in w.players.values():
		dwarf.position=Vector3((dwarf.class_id-3.5)*1.45,.7,8);dwarf.visual_root.rotation.y=0;dwarf.carrying.wood=dwarf.class_id+1
	var camera_parent:=p.camera.get_parent()
	p.camera.reparent(w);p.camera.position=Vector3(0,4,21);p.camera.look_at(Vector3(0,1.4,8));p.camera.current=true
	await capture("eight_dwarves")
	p.camera.reparent(camera_parent,false);p.camera.transform=Transform3D.IDENTITY
	check(FortSave.write_slot("slot1",w)=="","host saves all eight personal inventories")
	var saved:=FortSave.read_slot("slot1");check(saved.error=="" and saved.data.characters.size()==8,"checkpoint contains eight independent dwarf records")
	main._leave_game("eight-slot reload");await wait();main.port_edit.value=24767;main.load_expedition("slot1");main._start_match()
	w=main.world;w.set_process(false)
	for i in range(1,8):w.add_network_player(i+101,{"name":"Returned %d"%i,"class":i})
	for dwarf in w.players.values():
		dwarf.set_physics_process(false)
		check(dwarf.carrying.wood==dwarf.class_id+1,"slot %d restores its own pack with new peer ID"%dwarf.class_id)
	var old:Dictionary=saved.data.duplicate(true)
	for slot in range(4,8):old.characters.erase(slot)
	check(FortSave.validate(old)=="","older four-dwarf saves remain valid")
	old.characters[8]=old.characters[0].duplicate(true);check(FortSave.validate(old)!="","ninth saved slot rejected")
	await capture("restored_crew")
	await wait()
	main._leave_game("crew validation complete");await wait();main.queue_free();await create_timer(.5).timeout;print("CREW24_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
