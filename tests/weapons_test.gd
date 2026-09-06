extends SceneTree

var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func capture(key:String)->void:
	await wait(0.15)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))
func input_action(key:String)->void:
	var event:=InputEventAction.new();event.action=key;event.pressed=true;Input.parse_input_event(event)
	Input.flush_buffered_events()
	Input.action_release(key)

func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(main);main._host()
	main._start_match()
	var w:FortWorld=main.world
	var p:FortPlayer=w.local_player()
	await wait(0.2)
	check(p.weapon=="Axe" and p.owned_weapons==PackedStringArray(["Axe"]),"dwarves start with their original axe")
	check(FortEquipment.body_mesh.get_surface_count()>0 and FortEquipment.axe_mesh.get_surface_count()>0,"body and skinned tool are split without replacing original asset")
	var original:Node3D=load("res://assets/models/dwarf.glb").instantiate()
	var mesh:Mesh=original.find_children("*","MeshInstance3D",true,false)[0].mesh
	var original_count:=0
	var split_count:=0
	for i in mesh.get_surface_count():original_count+=mesh.surface_get_array_index_len(i)
	for part in [FortEquipment.body_mesh,FortEquipment.axe_mesh]:
		for i in part.get_surface_count():split_count+=part.surface_get_array_index_len(i)
	check(original_count==split_count,"equipment split retains every source triangle")
	original.free()
	w.shared={"wood":100,"stone":100,"crystal":20}
	w.server_action(1,"craft_weapon",{"weapon":"Hammer"})
	check(p.weapon=="Axe" and w.shared.wood==100,"crafting away from workshop is rejected")
	w.server_action(1,"equip_weapon",{"weapon":"Crossbow"})
	check(p.weapon=="Axe","unowned weapon cannot be equipped")
	p.position=Vector3(-4.6,0.1,2)
	w.toast_time=0
	input_action("interact")
	await wait(0.1)
	check(w.forge_open and w.menu_open and w.hud.forge.visible,"E beside workshop opens forge and frees cursor")
	await capture("forge_menu")
	w.hud.forge.buttons[1].pressed.emit()
	await wait(0.15)
	check(p.weapon=="Hammer" and "Hammer" in p.owned_weapons,"forge button crafts and equips hammer")
	check(w.shared=={"wood":86,"stone":82,"crystal":18},"hammer spends exact shared cost")
	w.server_action(1,"craft_weapon",{"weapon":"Hammer"})
	check(w.shared.wood==86,"repeated craft request cannot charge twice")
	input_action("cancel")
	await wait(0.1)
	check(not w.menu_open and not w.forge_open,"Escape closes forge")
	p.position=Vector3(0,0.1,18);p.look_yaw=0
	w.recv_enemy(900,"Brute",Vector3(0,0,15),300);w.enemies[900].stun=100
	w.server_action(1,"attack",{"direction":Vector3.FORWARD})
	w.server_action(1,"equip_weapon",{"weapon":"Axe"})
	check(p.weapon=="Hammer","cannot swap weapons during a pending hit")
	await wait(0.2)
	check(w.enemies[900].hp==300,"hammer has a visible windup before damage")
	await wait(0.55)
	check(w.enemies[900].hp==225,"Vanguard hammer impact deals its configured heavy damage")
	w.server_action(1,"attack",{"direction":Vector3.FORWARD})
	check(w.delayed_hits.is_empty(),"hammer cooldown prevents rapid attacks")
	await wait(0.60)
	w.recv_enemy_dead(900)
	p.position=Vector3(-4.6,0.1,2)
	w.server_action(1,"craft_weapon",{"weapon":"Crossbow"})
	check(p.weapon=="Crossbow" and p.owned_weapons.size()==3,"crossbow crafts as a second owned weapon")
	check(w.shared=={"wood":64,"stone":74,"crystal":14},"crossbow spends its exact fixed recipe")
	check(p.animation_player.has_animation("crossbow/Shoot"),"crossbow has its own authored runtime shoot clip")
	var old_revision:=p.loadout_revision
	w.recv_loadout(1,PackedStringArray(["Axe"]),"Axe",old_revision-1)
	check(p.weapon=="Crossbow","stale snapshots cannot undo a new loadout")
	p.position=Vector3(0,0.1,18);p.look_yaw=0
	w.recv_enemy(901,"Brute",Vector3(0,0,10),300);w.enemies[901].stun=100
	w.recv_enemy(902,"Brute",Vector3(0,0,7),300);w.enemies[902].stun=100
	await physics_frame
	w.server_action(1,"attack",{"direction":Vector3.FORWARD})
	await wait(0.25)
	check(w.enemies[901].hp==245 and w.enemies[902].hp==300,"crossbow hits only the nearest aimed enemy")
	check(p.animation_player.current_animation=="crossbow/Shoot","crossbow plays firing and reload motion")
	await wait(0.9)
	var wall_shape:=BoxShape3D.new();wall_shape.size=Vector3(4,3,0.4)
	var wall:=Visuals.add_static_collision(w,wall_shape,Vector3(0,1.5,14))
	await physics_frame
	w.server_action(1,"attack",{"direction":Vector3.FORWARD})
	await wait(0.3)
	check(w.enemies[901].hp==245,"world geometry blocks crossbow damage")
	wall.queue_free();w.recv_enemy_dead(901);w.recv_enemy_dead(902)
	await wait(0.85)
	p.position=w.resource_nodes[0].node.position+Vector3(1.5,0.1,0)
	input_action("interact")
	await wait(0.12)
	check(p.equipment.axe.visible and not p.weapon_visual.visible,"gathering temporarily restores the axe")
	await wait(0.85)
	check(not p.equipment.axe.visible and p.weapon_visual.visible,"equipped weapon returns after gathering")
	var camera:=Camera3D.new();w.add_child(camera);camera.current=true
	w.hud.hide();p.position=Vector3(0,0.1,16);p.velocity=Vector3.ZERO
	p.visual_root.rotation.y=0;p.look_yaw=PI
	camera.position=Vector3(2.2,1.65,19.2);camera.look_at(p.position+Vector3.UP*0.9);camera.fov=38
	await capture("crossbow_ready")
	check(p.weapon_visual.global_basis.z.normalized().dot(p.visual_root.global_basis.z.normalized())>0.95,"crossbow barrel faces the dwarf's aim direction")
	w.server_action(1,"attack",{"direction":Vector3.BACK})
	await capture("crossbow_firing")
	await wait(1.1)
	w.server_action(1,"equip_weapon",{"weapon":"Hammer"})
	await capture("hammer_ready")
	w.server_action(1,"attack",{"direction":Vector3.BACK})
	await capture("hammer_windup")
	await wait(0.4)
	await capture("hammer_impact")
	await wait(1.0)
	input_action("cycle_weapon")
	await wait(0.1)
	check(p.weapon=="Crossbow","C input cycles owned weapons outside menus")
	main.multiplayer.multiplayer_peer.close();main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free();await wait(0.15)
	print("WEAPONS_TEST_","OK" if failures==0 else "FAILED")
	quit(failures)
