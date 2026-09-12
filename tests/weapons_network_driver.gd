extends SceneTree

var errors:Array[String]=[]
func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func verify(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:errors.append(message)
func action(key:String)->void:
	var event:=InputEventAction.new();event.action=key;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events();Input.action_release(key)

func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	var server:bool="--server" in OS.get_cmdline_user_args()
	var deadline:=Time.get_ticks_msec()+24000
	if server:
		main._host()
		main._start_match()
		var w:FortWorld=main.world
		w.shared={"wood":100,"stone":100,"crystal":30}
		w.local_player().position=Vector3(-4.6,0.1,2)
		w.server_action(1,"craft_weapon",{"weapon":"Hammer"})
		for i in 3:
			w.recv_enemy(901+i,"Brute",Vector3(-1.5+i*1.5,0,20),300)
			w.enemies[901+i].stun=500
		while w.players.size()<4 and Time.get_ticks_msec()<deadline:await wait(0.1)
		verify(w.players.size()==4,"weapon host receives three clients")
		await wait(1)
		for id in w.players:
			if id!=1:w.broadcast("recv_teleport",[int(id),Vector3(-4.6,0.1,2)])
		var crafted:=false
		while not crafted and Time.get_ticks_msec()<deadline:
			crafted=true
			for p in w.players.values():
				if p.peer_id!=1 and p.weapon!="Crossbow":crafted=false
			await wait(0.1)
		verify(crafted,"three remote forge buttons craft authoritative crossbows")
		verify(w.shared=={"wood":20,"stone":58,"crystal":16},"concurrent crafts charge each recipe exactly once")
		await wait(0.5)
		for id in w.players:
			if id!=1:
				var role:int=w.players[id].class_id
				w.broadcast("recv_teleport",[int(id),Vector3(-1.5+(role-1)*1.5,0.1,26)])
		var fired:=false
		while not fired and Time.get_ticks_msec()<deadline:
			fired=true
			for enemy in w.enemies.values():
				if enemy.hp!=245:fired=false
			await wait(0.1)
		verify(fired,"all three remote shots damage their aimed targets once")
		var switched:=false
		while not switched and Time.get_ticks_msec()<deadline:
			switched=true
			for p in w.players.values():
				if p.peer_id!=1 and p.weapon!="Axe":switched=false
			await wait(0.1)
		verify(switched,"remote C switching reaches the host")
		for id in w.players:
			if id!=1:w.broadcast("recv_health",[int(id),0.0,10.0])
		await wait(1)
		for id in w.players:
			if id!=1:w._respawn(int(id))
		await wait(2)
	else:
		main._join()
		while (not is_instance_valid(main.world) or main.world.players.size()<4) and Time.get_ticks_msec()<deadline:await wait(0.1)
		if not is_instance_valid(main.world):verify(false,"client world exists");quit(1);return
		var w:FortWorld=main.world
		var p:FortPlayer=w.local_player()
		await wait(0.4)
		verify(w.players[1].weapon=="Hammer" and is_instance_valid(w.players[1].weapon_visual),"late join sees host's crafted weapon and model")
		while p.position.distance_to(Vector3(-4.6,0,0))>3.2 and Time.get_ticks_msec()<deadline:await wait(0.05)
		action("interact");await wait(0.15)
		verify(w.forge_open,"remote E opens workshop UI")
		w.hud.forge.buttons[2].pressed.emit()
		w.request_action("craft_weapon",{"weapon":"Crossbow"}) # Duplicate request must be harmless.
		while p.weapon!="Crossbow" and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(p.weapon=="Crossbow" and "Crossbow" in p.owned_weapons,"client receives ownership and equipped model")
		while p.position.z<24 and Time.get_ticks_msec()<deadline:await wait(0.05)
		await wait(0.15)
		verify(not w.forge_open and not w.menu_open,"moving away closes forge without trapping controls")
		# Aim the actual offset third-person camera at this client's target.
		var target:int=900+p.class_id
		var offset:Vector3=w.enemies[target].node.position+Vector3.UP*.85-(p.position+Vector3.UP*1.3)
		var planar:=Vector2(offset.x,offset.z).length()
		p.look_yaw=atan2(-offset.x,-offset.z)+asin(.85/planar)
		p.look_pitch=atan2(offset.y,sqrt(planar*planar-.85*.85))
		await wait(.4)
		verify(FortAim.solution(w,p,p.shot_direction()).enemy==target,"camera cursor points at intended target")
		action("attack");await wait(0.25)
		verify(p.animation_player.current_animation=="crossbow/Shoot","remote acknowledgment starts crossbow animation")
		while w.enemies[target].hp==300 and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(w.enemies[target].hp==245,"client receives authoritative crossbow damage")
		await wait(1.0);action("cycle_weapon")
		while p.weapon!="Axe" and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(p.weapon=="Axe" and p.equipment.axe.visible,"C returns to visible axe on client")
		while p.health>0 and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(p.health==0,"weapon test client receives downed state")
		while p.health<=0 and Time.get_ticks_msec()<deadline:await wait(0.05)
		verify(p.health>0 and "Crossbow" in p.owned_weapons,"crafted equipment survives rescue")
		await wait(1)
	print("NETWORK_RESULT ","SERVER" if server else "CLIENT"," ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free();await wait(0.1);quit(0 if errors.is_empty() else 1)
