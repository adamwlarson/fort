extends SceneTree

var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func capture(key:String)->void:
	await create_timer(0.3).timeout
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))

func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await capture("interface_title")
	main._on_class_selected(2)
	main._host()
	main._start_match()
	var w:FortWorld=main.world
	var p:FortPlayer=w.local_player()
	var hud:FortHUD=w.hud
	w.toast_time=0
	p.position=Vector3(4.6,0.1,2.0)
	p.carrying={"wood":6,"stone":4,"crystal":8}
	await capture("interface_stockpile")
	check(hud.stock_panel.visible,"stockpile panel opens on approach")
	check(hud.stock_action.text.contains("DEPOSIT ALL"),"stockpile clearly offers deposit all")
	check(hud.stock_contents.text.contains("YOUR PACK") and hud.stock_contents.text.contains("SHARED"),"personal and shared inventory distinguished")
	var wood:int=w.shared.wood
	w.player_interact(p)
	await create_timer(0.1).timeout
	check(p.total_carried()==0 and w.shared.wood==wood+6,"same E action deposits the full pack")
	check(hud.stock_action.text.contains("EMPTY") and hud.stock_progress.text.contains("JETPACKS"),"empty pack and next travel goal update")
	await capture("interface_deposited")
	p.position=Vector3(0,0.1,13)
	p.look_yaw=0
	w.toggle_build_mode()
	w.shared={"wood":18,"stone":8,"crystal":0}
	await capture("interface_build")
	check(hud.build_cards.size()==GameData.BUILD_ORDER.size() and hud.build_cards[0].visible,"B opens all illustrated recipe cards")
	check(hud.card_costs[0].text.contains("14 wood") and hud.card_costs[0].text.contains("6 stone"),"Engineer card uses real rounded discounts")
	check(hud.card_status[2].text.begins_with("Need"),"unaffordable recipe lists missing supplies")
	check(not hud.stock_panel.visible,"stockpile does not overlap construction")
	for i in 7:
		check(hud.card_status[i].get_minimum_size().x<191,"card status fits width "+str(i))
		check(hud.build_cards[i].position.x+hud.build_cards[i].size.x<=1280,"card fits viewport "+str(i))
	w.toggle_build_mode()
	w.toggle_pause()
	await capture("interface_camp_menu")
	check(hud.menu.visible,"camp menu still opens")
	w.toggle_pause()
	hud.hide()
	var camera:=Camera3D.new()
	w.add_child(camera);camera.current=true
	for rid in [48,49,50,72]:
		var node:Node3D=w.resource_nodes[rid].node
		var chunks:=node.find_children("HarvestChunk_*","Node3D",true,false)
		check(chunks.size()==6,"mineral has six removable chunks "+str(rid))
		camera.position=node.position+Vector3(2.8,2.0,3.5)
		camera.look_at(node.position+Vector3.UP*0.7)
		await capture("mineral_"+str(rid))
		w.recv_resource(rid,3 if rid==72 else 6,true)
		var visible_count:=0
		for chunk in chunks:
			if chunk.visible:visible_count+=1
		check(visible_count==3,"half mined geometry matches supply "+str(rid))
		await capture("mineral_mined_"+str(rid))
		w.recv_resource(rid,6 if rid==72 else 12,false)
		check(chunks.all(func(chunk):return chunk.visible),"regrowth restores all mineral chunks "+str(rid))
	main.multiplayer.multiplayer_peer.close()
	main.multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	main.queue_free()
	await create_timer(0.15).timeout
	print("INTERFACE_TEST_","OK" if failures==0 else "FAILED")
	quit(failures)
