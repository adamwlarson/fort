extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24762;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	var ui:=w.hud.siege_indicators
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	p.position=Vector3(0,.7,18)
	p.camera.reparent(w);p.camera.global_position=Vector3(0,7,25);p.camera.look_at(Vector3(0,1,0));p.camera.current=true
	check(ui.sector(Vector3(0,0,-10))==2 and ui.sector(Vector3(10,0,0))==1 and ui.sector(Vector3(0,0,10))==0 and ui.sector(Vector3(-10,0,0))==3,"cardinal directions match raid director convention")
	ui.refresh();check(ui.threats.is_empty() and ui.repairs.is_empty(),"peaceful undamaged fort has no alerts")
	w.is_night=true;w.wave=6;w.director.start();w.director.lane_base=2
	w.recv_enemy(22000,"Sapper",Vector3(-4,.7,7),100)
	w.recv_enemy(22001,"Bombwing",Vector3(8,6,4),100)
	w.recv_enemy(22002,"Brute",Vector3(0,.7,35),200)
	w.recv_enemy(22003,"Cinderlobber",Vector3(45,0,10),100)
	w.recv_enemy(22004,"Sapper",Vector3(0,0,140),100,0)
	w.enemies[22000].fuse_at=1000
	w.recv_defense(22000,"Watchtower",Vector3(-12,.6,2),0,400,false)
	ui.refresh();w._damage_defense(22000,300);ui.refresh()
	check(ui.forecast==w.director.lanes() and ui.fronts[0]==2 and ui.fronts[1]==2,"expected fronts separate from live raid counts; distant camp excluded")
	check(ui.threats.size()==3 and ui.threats[0].armed and ui.threats[0].id==22000,"lit fuse is highest priority; marker budget capped at three threats")
	check(ui.repairs.size()==1 and ui.repairs[0].hit and is_equal_approx(ui.repairs[0].fraction,.25),"real building hit creates critical repair warning")
	var snapshot:=w.snapshot()
	check(snapshot.enemies[22000].armed,"armed Sapper state included in full and incremental snapshots")
	w.enemies[22000].warning_armed=false;w.recv_enemy_snapshot(snapshot.enemies)
	check(w.enemies[22000].warning_armed,"incremental receiver restores lit fuse for client indicator")
	w.enemies[22000].warning_armed=false;w.recv_snapshot(snapshot)
	check(w.enemies[22000].warning_armed,"full receiver restores lit fuse for late join")
	await create_timer(.3).timeout
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(ui.drawn_markers==4,"rendered UI bounds threat markers plus one urgent repair marker")
		for badge in w.readability.badges.values():check(not badge.visible or not ui.reserves(Rect2(badge.position,badge.size)),"resource badge does not cover siege information")
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/siege22_indicators.png"))
		w._update_lighting(1);await create_timer(.1).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/siege22_night.png"))
		for id in [22000,22001,22002]:w.enemies[id].node.position=Vector3(-35,.7,20)
		ui.refresh();await create_timer(.1).timeout;await RenderingServer.frame_post_draw
		for i in ui.marker_rects.size():
			for j in range(i+1,ui.marker_rects.size()):check(not ui.marker_rects[i].intersects(ui.marker_rects[j]),"clustered edge captions remain separated")
		for rect in ui.marker_rects:check(rect.position.x>=347 and rect.end.x<=968 and rect.end.y<=545,"edge captions avoid side panels and action prompts")
	w.menu_open=true;ui._process(.2);check(not ui.visible,"menus suppress tactical overlay")
	w.menu_open=false;w.local_build_mode=true;ui._process(.2);check(not ui.visible,"placement suppresses tactical overlay")
	w.local_build_mode=false;p.health=0;ui._process(.2);check(not ui.visible,"downed player has no distracting tactical overlay")
	p.health=p.max_health;w.ended=true;ui._process(.2);check(not ui.visible,"end screen suppresses overlay");w.ended=false
	w.defenses[22000].hp=400;ui.refresh();check(ui.repairs.is_empty(),"fully repaired building immediately clears warning")
	w.defenses[22000].hp=100;ui.refresh();w.recv_remove_defense(22000,true);ui.refresh()
	check(ui.repairs.is_empty() and not ui.previous_hp.has(22000),"removed or salvaged defenses leave no ghost repair alerts")
	w.damage_fort(750);ui.refresh();check(ui.repairs[0].id==-1 and ui.repairs[0].hit,"hearth damage gets its own urgent core warning")
	w.fort_health=w.fort_max_health
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w.is_night=false;ui.refresh();check(ui.threats.is_empty() and ui.forecast.is_empty() and ui.repairs.is_empty(),"dawn and cleared enemies remove obsolete warnings")
	main.queue_free();await create_timer(.1).timeout
	print("SIEGE22_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
