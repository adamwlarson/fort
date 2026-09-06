extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func capture(key:String)->void:
	await wait(0.25)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	main.address_edit.text="";main._join()
	check(not main.connecting,"empty address no longer silently joins loopback")
	main.port_edit.value=24587;main._host()
	check(main.lobby_active and not is_instance_valid(main.world),"hosting opens lobby without starting the day")
	check(main.session_port==24587,"custom host port is used")
	await capture("fort4_lobby")
	main._start_match();await wait(0.2)
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player()
	w.set_process(false)
	check(w.resource_nodes.size()==90 and w.frontier_radius()==73,"tier 1 preserves all original resources and map")
	w.shared={"wood":200,"stone":200,"crystal":50}
	p.position=Vector3(0,0.1,3.5)
	w.hud.hearth_menu.open_panel();await capture("fort4_hearth_upgrade")
	check(w.hud.hearth_menu.visible and not w.hud.hearth_menu.upgrade.disabled,"hearth menu shows affordable upgrade and risk")
	w.hud.hearth_menu.upgrade.pressed.emit()
	check(w.hearth_level==2 and w.resource_nodes.size()==162 and w.frontier_radius()==153,"upgrade adds actual outer resources and expands travel boundary")
	check(w.shared.wood==150 and w.shared.stone==160 and w.shared.crystal==42,"shared upgrade cost deducted once")
	w.server_action(1,"upgrade_hearth",{"level":1})
	check(w.hearth_level==2 and w.shared.wood==150,"duplicate upgrade request cannot buy next tier")
	w.set_hearth_level(1)
	check(w.hearth_level==2,"stale state cannot revert hearth level")
	check(w.fort_max_health==1500 and w.fort_health==1500,"upgrade strengthens and heals hearth")
	w.toggle_pause();check(not w.menu_open and not w.hud.hearth_menu.visible,"Escape closes hearth menu")
	w.clock+=2;w.is_night=true
	w.server_action(1,"upgrade_hearth",{"level":2})
	check(w.hearth_level==2,"night upgrades are rejected")
	w.is_night=false;p.position=Vector3(30,0,0)
	w.server_action(1,"upgrade_hearth",{"level":2})
	check(w.hearth_level==2,"remote upgrades rejected")
	p.position=Vector3(0,0,3.5);w.clock+=2
	w.server_action(1,"upgrade_hearth",{"level":2})
	check(w.hearth_level==3 and w.resource_nodes.size()==234 and w.fort_max_health==2000,"tier 3 unlocks final resource ring")
	var outer:Dictionary=w.resource_nodes[1300]
	p.position=outer.node.position+Vector3(1.0,0.1,0)
	await wait(0.2)
	w.server_action(1,"interact",{})
	check(p.total_carried()>0,"outer frontier resource is harvestable")
	check(p.position.length()>100,"expanded frontier does not return player to fort")
	await capture("fort4_frontier")
	w.wave=2
	check(w.raid_cap()==FortBalance.active_cap(w.wave,w.players.size()),"hearth pressure uses budget rather than inflating the active cap")
	for i in 130:w._spawn_enemy()
	check(w.enemies.size()==w.raid_cap(),"large swarm obeys active enemy safety cap")
	var kinds:Array=[]
	for e in w.enemies.values():
		if e.kind not in kinds:kinds.append(e.kind)
	check("Ashwing" in kinds and "EmberRunner" in kinds and "Brute" in kinds,"spawn mix contains flyers, hearth runners and brutes")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	await wait(1)
	p.position=Vector3(35,0,35)
	w.recv_enemy(901,"Ashwing",Vector3(2,3.8,2),500)
	w.recv_enemy(902,"EmberRunner",Vector3(0,0,13),500)
	# Bait the runner from the side; it should continue toward the gate, not the dwarf.
	p.position=Vector3(3,0,13)
	var start:Vector3=w.enemies[902].node.position
	for i in 30:w._simulate_enemies(1.0/60);await physics_frame
	check(w.enemies[902].node.position.z<start.z-0.7,"runner ignores nearby bait and moves toward hearth")
	p.position=Vector3(35,0,35)
	var hp:=w.fort_health
	for i in 180:w._simulate_enemies(1.0/60);await physics_frame
	check(w.fort_health<hp,"flying enemy descends and damages hearth")
	w.enemies[901].node.position=Vector3(30,3.8,30);w.enemies[901].stun=100
	p.position=Vector3(30,0,32)
	w._resolve_hit(1,Vector3.FORWARD,"Axe")
	check(w.enemies[901].hp==500,"ground melee does not hit cruising flyers overhead")
	w._fire_crossbow(p,(w.enemies[901].node.position+Vector3.UP*.85-FortAim.origin(w,p)).normalized())
	check(w.enemies[901].hp==445,"crossbow can counter airborne enemies")
	# Close-up new enemy render, independent of world scenery.
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(30,3,39);camera.look_at(Vector3(30,2,30));camera.current=true
	w.enemies[901].node.position=Vector3(28,1.2,30);w.enemies[902].node.position=Vector3(32,0,30)
	w.enemies[902].stun=100
	for e in w.enemies.values():FortArt.animate_enemy(e.visual,0,false,true)
	w.hud.hide();await capture("fort4_enemies")
	for key in ["ashwing","emberrunner"]:
		var model:=FortArt.asset(key);var anim:=FortPlayer.find_animation(model)
		check(anim!=null,"Blender "+key+" has animation player")
		for clip in ["Idle","Walk","Attack","Hit","Death"]:check(anim.has_animation(clip),key+" has "+clip)
		model.free()
	main._leave_game();await wait(0.2)
	main._host();check(main.lobby_active and main.session_port==24587,"leaving closes socket and allows same-port rehosting")
	main._leave_game();await wait(0.1)
	main.address_edit.text="127.0.0.1";main._join()
	check(main.connecting and main.cancel_connection.visible,"connection shows cancellable pending state")
	main.connection_deadline=0;await wait(0.1)
	check(not main.connecting and main.status_label.text.contains("24587"),"timeout resets connection and identifies selected port")
	main.queue_free();await wait(0.2)
	print("FORT4_RESULT ","PASS" if failures==0 else "FAIL")
	quit(failures)
