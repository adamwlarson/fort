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
	FortSave.test_directory="res://build/clearance18_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24767;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.shared={"wood":100,"stone":100,"crystal":100,"iron":100,"aether":100}
	var target:={"x":1,"z":0,"floor":0};p.position=w.castle.rooms["0:0:0"].sign
	var ids:Array=[]
	for kind in ["wood","stone"]:
		for id in w.resource_nodes:
			if w.resource_nodes[id].kind==kind:w.resource_nodes[id].node.position=Vector3(18,0,2+ids.size()*3);ids.append(id);break
	var rock:=FortLandscape.place(w,"moss_rock",Vector3(26,0,7));FortArt.box_collider(rock,Vector3.ONE,Vector3.UP*.5)
	var obstacle:={"pos":rock.position,"radius":1.25,"node":rock,"clearable":true};w.scenery_keepouts.append(obstacle)
	check(w.castle.plan_reason("0:0:0",target,"Courtyard")=="","trees, minerals and loose scenery no longer block expansion")
	for spec in [[800,"Watchtower",Vector3(20,.6,0)],[801,"Ballista",Vector3(22,.6,4)],[802,"Mender",Vector3(24,.6,-5)],[803,"Barricade",Vector3(31,.6,2)],[804,"Watchtower",Vector3(20,4.6,0)],[805,"Watchtower",Vector3(40,.6,0)],[806,"Watchtower",Vector3(18,.6,-3)],[807,"Barricade",Vector3(16,.6,-4)]]:
		w.recv_defense(spec[0],spec[1],spec[2],0,100,spec[0]==806)
	w.defenses[800].paid={"wood":20,"stone":10};w.defenses[801].paid={"wood":40,"stone":20};w.defenses[801].hp=50
	w.defenses[802].paid={"wood":10,"crystal":8};w.defenses[802].merge({"work_total":8.0,"work":2.0,"work_cost":{"iron":20},"work_kind":"upgrade","work_revision":2})
	w.defenses[803].paid={"stone":8};w.defenses[806].paid={"wood":999}
	w.defenses[807].merge({"work_total":10.0,"work":5.0,"work_cost":{"wood":20},"work_kind":"build","work_revision":1})
	var info:=FortCastleClearance.inspect(w.castle,target)
	check(info.defenses.size()==6 and 803 in info.defenses and 804 not in info.defenses and 805 not in info.defenses,"clearance uses wall extents and preserves other floors and outside defenses")
	check(info.refund=={"wood":35,"stone":14,"crystal":4,"iron":15},"refund includes health-scaled paid costs and unused work, but not free turrets")
	w.is_night=true;check(w.castle.plan_reason("0:0:0",target,"Courtyard").contains("daylight"),"combat-night salvage protection remains");w.is_night=false
	var protected:={"pos":Vector3(20,0,0),"radius":5.0};w.scenery_keepouts.append(protected)
	check(w.castle.plan_reason("0:0:0",target,"Courtyard").contains("protected"),"encounter landmarks remain protected");w.scenery_keepouts.erase(protected)
	var revision:=w.castle.revision;w.castle.plan(1,"0:0:0",target,"Courtyard",revision)
	check(w.defenses.has(800) and not w.castle.rooms.has("1:0:0"),"server refuses defense removal without confirmation")
	w.defenses[800].hp=50;w.castle.plan(1,"0:0:0",target,"Courtyard",revision,info.token)
	check(w.defenses.has(800) and w.shared.wood==100,"stale refund confirmation cannot destroy or credit anything");w.defenses[800].hp=100
	w.recv_player(42,{"name":"Mounted tester","class":1});w.players[42].mounted_ballista=801;w.defenses[801].occupant=42
	w.castle.menu.open_nearest();w.castle.menu.place_selected()
	check(not w.castle.rooms.has("1:0:0") and w.castle.menu.plan_button.text.contains("CONFIRM"),"first UI click reviews destructive clearance without changing the world")
	await create_timer(.1).timeout;await shot("clearance18_preview")
	w.castle.menu.place_selected();w.castle.menu.close_panel()
	check(w.castle.rooms.has("1:0:0") and not w.castle.rooms["1:0:0"].complete,"confirmed expansion still creates a hand-built blueprint")
	check(w.shared.wood==135 and w.shared.stone==114 and w.shared.crystal==104 and w.shared.iron==115,"clearance credits exact refund to shared stock once")
	for id in ids:check(w.resource_nodes[id].amount==0 and not w.resource_nodes[id].node.visible and not w.resource_respawn_clear(w.resource_nodes[id]),"cleared resource vanishes and cannot respawn in blueprint")
	check(not rock.visible and rock.find_children("*","CollisionObject3D",true,false)[0].collision_layer==0,"loose rock loses both mesh visibility and collision")
	check(w.players[42].mounted_ballista==-1 and w.defenses.size()==2,"removed ballista safely dismounts its operator")
	check(w.castle.placement_reason(Vector3(20,.6,3),2)!="","new defenses cannot be built inside the unfinished footprint")
	w.castle.plan(1,"0:0:0",target,"Courtyard",revision,info.token)
	check(w.shared.wood==135,"duplicate plan packet cannot double the refund")
	check(FortSave.write_slot("slot1",w)=="","clearance checkpoint saves")
	var data:Dictionary=FortSave.read_slot("slot1").data
	check(FortCastleClearance.scenery_key(obstacle) in data.world.castle.cleared_scenery,"cleared scenery identity survives save serialization")
	main._leave_game("reload clearance");await create_timer(.1).timeout;main.port_edit.value=24767;main.load_expedition("slot1");main._start_match();w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.castle.rooms.has("1:0:0") and not w.defenses.has(800) and w.shared.wood==135,"reload retains clearance and refund without resurrecting removed towers")
	var replica:=FortLandscape.place(w,"moss_rock",obstacle.pos);FortArt.box_collider(replica,Vector3.ONE,Vector3.UP*.5)
	w.scenery_keepouts.append({"pos":obstacle.pos,"radius":1.25,"node":replica,"clearable":true});FortCastleClearance.apply_scenery(w.castle)
	check(not replica.visible,"saved cleared-scenery identity hides regenerated scenery")
	p.position=w.castle.rooms["1:0:0"].sign;w.castle.cancel(1,"1:0:0",w.castle.revision)
	check(w.shared.wood==135 and not w.defenses.has(800) and w.castle.cleared_scenery.has(FortCastleClearance.scenery_key(obstacle)),"canceling an unworked blueprint does not undo clearance or replay salvage")
	# Batched biome props remove only the selected instance, including its collider.
	var node:=Node3D.new();w.add_child(node);var poses:Array[Transform3D]=[Transform3D(Basis.IDENTITY,Vector3(20,0,0)),Transform3D(Basis.IDENTITY,Vector3(50,0,0))]
	var batches:=FortLandscape.instance_asset(node,"moss_rock",poses);var collider:=Node3D.new();node.add_child(collider)
	var batch_key:={"pos":Vector3(20,0,0),"radius":4.0,"node":collider,"clearable":true,"batches":batches,"index":0}
	w.scenery_keepouts.append(batch_key);w.castle.cleared_scenery[FortCastleClearance.scenery_key(batch_key)]=true;FortCastleClearance.apply_scenery(w.castle)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(batches[0].multimesh.get_instance_transform(0).basis.determinant()==0 and batches[0].multimesh.get_instance_transform(1).basis.determinant()!=0 and node.visible,"batched biome clearing changes only the selected instance")
	main.queue_free();await create_timer(.1).timeout;print("CLEARANCE18_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
