extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func wait()->void:await create_timer(.12).timeout
func run()->void:
	FortSave.test_directory="res://build/gate24_saves_%d"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24766;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.set_hearth_level(3)
	w.shared={"wood":1000,"stone":1000,"iron":1000,"crystal":1000,"aether":1000}
	var location:=Vector3(0,.6,9.5);p.position=location+Vector3.BACK*3.5
	w._build(1,{"kind":"Gatehouse","pos":location,"rotation":0.0});var d:Dictionary=w.defenses[1]
	var start:float=d.work;p.position=location+Vector3(2.34,0,0);w.clock+=1;w.construction.work(1,1)
	check(d.work==start,"work cannot materialize a pier around a dwarf")
	p.position=location+Vector3.BACK*3.5
	for i in 3:w.clock+=.8;w.construction.work(1,1)
	check(d.work_visual_stage==1 and d.node.get_node("Worksite").find_children("*","MeshInstance3D",true,false).size()<=6,"middle worksite is a bounded, batched authored asset")
	check(FortSave.write_slot("slot1",w)=="","partly built gate writes a real checkpoint")
	main._leave_game("gate checkpoint reload");await wait();main.port_edit.value=24766;main.load_expedition("slot1");main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);d=w.defenses[1]
	check(d.work_visual_stage==1 and d.work==3.75 and d.node.has_node("Worksite"),"partly built gate survives full world reload with correct art")
	for i in 5:w.clock+=.8;w.construction.work(1,1)
	check(not FortConstruction.pending(d),"restored gate can be finished")
	await wait();p.position=location+Vector3(0,.08,2.1)
	var collision:=p.move_and_collide(Vector3.FORWARD*4.2)
	check(collision==null and p.position.z<location.z-2,"real dwarf capsule traverses the open arch")
	p.position=location+Vector3.BACK*3.5;w.clock+=1;w.gates.request(1,1,0);w.gates.tick(4);await wait()
	p.position=location+Vector3(0,.08,2.1);collision=p.move_and_collide(Vector3.FORWARD*4.2)
	check(collision!=null and p.position.z>location.z,"real dwarf capsule is stopped by closed portcullis")
	p.position=location+Vector3.BACK*3.5;w.clock+=1;w.gates.request(1,1,d.gate_revision,true)
	check(FortSave.write_slot("slot2",w)=="","closed gate and dusk option save")
	main._leave_game("closed gate reload");await wait();main.port_edit.value=24766;main.load_expedition("slot2");main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);d=w.defenses[1];await wait()
	check(d.gate_auto and d.gate_open==0 and d.node.get_node("GateDoor").collision_layer==1,"closed gate reload restores solid collision and auto setting")
	w.clock+=1;w.gates.request(1,1,d.gate_revision);w.gates.tick(.8)
	var fraction:float=d.gate_open
	check(FortSave.write_slot("slot3",w)=="","moving mechanism can be checkpointed")
	main._leave_game("moving gate reload");await wait();main.port_edit.value=24766;main.load_expedition("slot3");main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);d=w.defenses[1]
	check(is_equal_approx(d.gate_open,fraction) and d.gate_target==1,"mid-animation fraction and direction survive reload")
	w.gates.tick(4);check(d.gate_open==1 and is_equal_approx(d.node.get_meta("gate_parts").Portcullis.position.y,3.15),"restored mechanism finishes opening")
	var newest:=w.snapshot();newest.defenses[1].gate_revision=d.gate_revision-1;newest.defenses[1].gate_target=0.0;w.recv_snapshot(newest)
	check(d.gate_target==1,"old unreliable gate snapshot cannot override newer command")
	d.level=GameData.MAX_GEAR_LEVEL;FortGates.pose(d)
	check(d.node.get_meta("gate_parts").tier8.visible,"all eight upgrade levels have authored visual geometry")
	p.position=location+Vector3.BACK*3.5;w.clock+=1;w.gates.request(1,1,d.gate_revision);w.gates.tick(4);await wait()
	# A straight approach to a wall can divert through a nearby open gate.
	w.recv_defense(2,"MetalWall",location+Vector3(4.2,0,0),0,850,false)
	w.recv_defense(3,"MetalWall",location+Vector3(7,0,0),0,850,false)
	w.recv_enemy(24001,"Raider",location+Vector3(4,.02,5),100)
	d.gate_open=1.0;d.gate_target=1.0;FortGates.pose(d);w.navigation_revision+=1;await wait()
	var enemy:Dictionary=w.enemies[24001];FortSiege.route(w,enemy,location+Vector3(0,0,-3))
	check(enemy.breach==-1 and not enemy.route_points.is_empty(),"ordinary raider routes through open gate instead of attacking curtain wall")
	w.recv_enemy_dead(24001)
	w.recv_remove_defense(1,true);w.recv_remove_defense(2,true);w.recv_remove_defense(3,true);await wait()
	var roof:=Node3D.new();w.add_child(roof);FortGates.body(roof,"LowRoof",Vector3(7,.4,4),location+Vector3.UP*4.5);await wait()
	check(FortGates.placement_reason(w,location,0).contains("overhead"),"physics placement detects a low ceiling across the full frame")
	roof.queue_free();await wait()
	check(FortGates.placement_reason(w,location,0)=="","removing obstruction restores valid gate footprint")
	main.queue_free();await wait();print("GATE24_EDGE_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
