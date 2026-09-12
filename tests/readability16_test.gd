extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func shot(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+name+".png"))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24737;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.hud.stock_icons.get_child_count()==5,"shared stock has five distinct resource icon counters")
	await create_timer(.1).timeout
	check(w.hud.stock_icons.global_position.y>110,"resource counters stay below the phase and hearth display")
	p.position=w.castle.rooms["0:0:0"].sign;w.castle.menu.open_nearest();await create_timer(.1).timeout
	check(w.castle.menu.guidance.text.contains("LOCKED") or w.castle.menu.guidance.text.contains("STEP 1"),"architect gives a persistent ready or blocked explanation")
	for id in w.resource_nodes:w.recv_resource(id,0,false)
	w.scenery_keepouts.clear();w.shared={"wood":1000,"stone":1000,"crystal":100,"iron":100,"aether":100};w.castle.menu.close_panel()
	w.castle.plan(1,"0:0:0",{"x":1,"z":0,"floor":0},"Courtyard",w.castle.revision);p.position=w.castle.rooms["1:0:0"].sign
	w.castle.menu.open_nearest();await create_timer(.1).timeout
	check(w.castle.menu.guidance.text.contains("STEP 2"),"placed blueprint explains the supply step rather than unexplained disabled choices")
	w.castle.fund(1,"1:0:0",true,w.castle.revision);await create_timer(.1).timeout
	check(w.castle.menu.guidance.text.contains("HOLD E") and w.castle.menu.guidance.text.contains("STEP 3"),"funded blueprint explicitly instructs holding E to finish")
	await shot("readability16_castle");w.castle.menu.close_panel()
	for i in 30:w.clock+=.7;w.castle.work(1,"1:0:0")
	p.position=Vector3(0,.7,15);p.look_yaw=0;p.look_pitch=-.2;p.camera.current=true
	# Resource models are arranged for a controlled readability screenshot.
	var index:=0
	for kind in GameData.RESOURCES:
		var chosen:=-1
		for id in w.resource_nodes:
			if w.resource_nodes[id].kind==kind:chosen=id;break
		if chosen<0:continue
		w.resource_nodes[chosen].node.position=Vector3(-6+index*3,0,7);w.recv_resource(chosen,6,false);index+=1
	var id:int=w.resource_nodes.keys()[0];w.resource_nodes[id].node.position=Vector3(0,0,12);w.recv_resource(id,10,false)
	p.position=Vector3(1,.1,12);w._gather(1,id)
	check(w.readability.gain_count==1 and w.readability.flying.size()==1,"real harvest emits one icon gain with its actual quantity")
	check(p.carrying.wood==2,"harvest receipt does not change authoritative harvest amount")
	await create_timer(.25).timeout
	check(w.readability.badges.size()>0,"nearby resources receive RTS icon badges")
	var camera:=Camera3D.new();w.add_child(camera);camera.position=Vector3(0,15,24);camera.look_at(Vector3(0,0,6));camera.current=true
	await create_timer(.1).timeout;await shot("readability16_resources")
	w.readability.loot("Test Dragon Hoard",{"wood":30,"stone":30,"crystal":12,"iron":12,"aether":12},["Greatmaul","Ironheart"],{})
	check(w.readability.receipt_count==1 and w.readability.last_loot.items.size()==2,"treasure receipt shows resources and gear separately")
	await create_timer(.2).timeout;await shot("readability16_loot")
	w.readability.receipt_time=0;w.readability.loot_queue.clear()
	p.position=FortProgression.SITES[0].pos+Vector3(1,0,0);var before:Dictionary=w.shared.duplicate();var count:=w.readability.receipt_count
	w.progression.interact(1);w.progression.interact(1)
	check(w.readability.receipt_count==count+1 and w.readability.last_loot.resources.crystal==8 and w.readability.last_loot.spent.crystal==2,"real chest emits exact gross rewards and separate lock cost once")
	check(w.shared.crystal==before.crystal+6,"receipt matches net shared stock change")
	w.readability.receipt_time=0;w.readability.loot_queue.clear();w.expedition.event_name="Supply Caravan";w.expedition.event_claimed=false;p.position=FortExpedition.CACHE_POS
	w.expedition.interact(1);check(w.readability.last_loot.resources.wood==12 and not w.readability.last_loot.resources.has("aether"),"caravan receipt includes only actually granted resources")
	w.readability.receipt_time=0;w.readability.loot_queue.clear()
	w.recv_enemy(800,"Raider",Vector3(-3,0,19),100);w.recv_enemy(801,"Brute",Vector3(3,0,19),200)
	w.recv_enemy_hit(800,50,50);p.position=Vector3(0,.7,26);p.look_yaw=0;p.look_pitch=-.2;p.camera.current=true
	# Use the player's camera, as the combat overlay does during play.
	p.camera.reparent(w);p.camera.global_position=Vector3(0,7,29);p.camera.look_at(Vector3(0,1,18))
	await create_timer(.2).timeout
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(w.hud.combat_overlay.enemy_bar_count==1,"only damaged enemies receive a health bar")
		await shot("readability16_enemies")
	w.enemies[800].hp=100;await create_timer(.1).timeout
	if DisplayServer.get_name()!="headless":check(w.hud.combat_overlay.enemy_bar_count==0,"enemy health bar disappears at full health")
	main.queue_free();await create_timer(.1).timeout
	print("READABILITY16_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
