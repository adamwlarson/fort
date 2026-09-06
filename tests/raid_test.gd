extends SceneTree
var failures:Array[String]=[]
func _initialize()->void:run.call_deferred()
func wait(seconds:float)->void:await create_timer(seconds).timeout
func check(ok:bool,message:String)->void:
	if ok:print("PASS ",message)
	else:failures.append(message);push_error("RAID FAIL: "+message)

func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await wait(0.1)
	main._host()
	main._start_match()
	await wait(0.2)
	var w:FortWorld=main.world
	var p:FortPlayer=w.local_player()
	p.position=Vector3(45,0.1,45)
	# Raiders approaching diagonal wall segments must use actual portals.
	for i in 4:
		var angle:=PI/4+i*PI/2
		w.recv_enemy(100+i,"Raider",Vector3(sin(angle)*13,0,cos(angle)*13),500)
	Engine.time_scale=3
	await wait(14)
	check(w.fort_health<1000,"raiders navigate gateways and damage the hearth")
	var reached:=0
	for e in w.enemies.values():
		if e.node.position.length()<4:reached+=1
	check(reached>=3,"raiders from several quadrants reach the interior")
	for id in w.enemies.keys():w.recv_enemy_dead(int(id))
	await wait(0.5)
	w._spawn_defense("Watchtower",Vector3(15,0,0),0,false)
	w.recv_enemy(201,"Raider",Vector3(20,0,0),200)
	w.enemies[201].stun=30
	var before:float=w.enemies[201].hp
	await wait(1)
	check(not w.enemies.has(201) or w.enemies[201].hp<before,"watchtower fires and damages enemies in range")
	# Fort 7 removes both the visual stairs and their old invisible ramp.
	p.position=Vector3(15,0.1,3.8)
	p.velocity=Vector3.ZERO
	p.look_yaw=0
	Input.action_press("move_forward")
	await wait(0.72)
	Input.action_release("move_forward")
	await wait(0.15)
	check(p.position.y<.5,"watchtower approach has no leftover invisible stair ramp")
	print("TOWER_PLAYER_POSITION ",p.position)

	# Revive another network-shaped actor using the actual server interaction.
	w.recv_player(22,{"name":"Fallen Warden","class":1})
	var ally:FortPlayer=w.players[22]
	ally.position=Vector3(35,0.05,35);ally.target_position=ally.position
	p.position=Vector3(36,0.05,35);p.velocity=Vector3.ZERO
	w._set_health(22,0)
	for i in 3:
		w.server_action(1,"interact",{})
		await wait(0.8)
	check(ally.health>0,"three held interactions revive a teammate")
	p.health=60
	w.server_action(22,"ability",{})
	check(p.health>60 and p.rally_time>0,"Warden ability heals and hastens another dwarf")
	# Temporary turret and ability rate limit.
	w.recv_player(23,{"name":"Engineer","class":2})
	var engineer:FortPlayer=w.players[23]
	engineer.position=Vector3(0,0,18);engineer.target_position=engineer.position
	w.server_action(23,"ability",{})
	var built:=w.defenses.size()
	w.server_action(23,"ability",{})
	check(w.defenses.size()==built and built==2,"Engineer field turret obeys server cooldown")
	w.wave=FortWorld.FINAL_WAVE-1
	w.is_night=false
	w._advance_phase()
	check(w.wave==10 and w.is_night,"tenth raid begins")
	w._advance_phase()
	check(not w.ended and not w.is_night and w.enemies.has(900010),"tenth dawn continues the expedition and preserves its boss")
	Engine.time_scale=1
	print("RAID_RESULT ","PASS" if failures.is_empty() else "FAIL"," ",failures)
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free()
	await wait(0.1)
	quit(0 if failures.is_empty() else 1)
