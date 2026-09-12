extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24770;main.selected_class=6;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	w.shared={"wood":1000,"stone":1000,"iron":1000,"crystal":1000,"aether":1000}
	p.position=Vector3(-5,.6,-5);w._ability(1)
	check(w.defenses.size()==1 and w.defenses[1].temporary,"Jade Engineer deploys a real temporary field turret")
	if w.defenses.has(1):
		var d:Dictionary=w.defenses[1];d.hp=50;w._repair(1)
		check(d.hp==98 and w.shared.wood==999,"Jade Engineer repair grants 48 HP for one shared wood")
		w.construction.begin(1,1,{"wood":1},"upgrade");w.clock+=1;w.construction.work(1,1)
		check(d.work==2.5,"Jade Engineer receives engineer and solo construction bonuses")
	p.class_id=4;w.clock+=13
	w.recv_enemy(24700,"Raider",p.position+Vector3.BACK*3,200)
	w._ability(1)
	check(w.enemies[24700].hp==135 and w.enemies[24700].stun==2,"Copper Vanguard slam damages and stuns enemies")
	p.class_id=5;p.health=10;w.clock+=13;w._ability(1)
	check(p.health==55 and p.rally_time==6,"Amethyst Warden rally heals and hastens")
	p.class_id=7;w.clock+=13;w._ability(1)
	check(p.dash_time==.4,"Dusk Scout trailblaze grants local dash")
	var resource_id:=-1
	for id in w.resource_nodes:
		var r:Dictionary=w.resource_nodes[id]
		if r.kind=="wood" and r.amount>=6 and FortForestry.requirement(r,p).is_empty():resource_id=id;break
	check(resource_id>=0,"world has an available basic wood node")
	if resource_id>=0:
		p.position=w.resource_nodes[resource_id].node.position+Vector3.RIGHT*2
		var before:int=p.carrying.wood;w._gather(1,resource_id)
		check(p.carrying.wood==before+3,"Dusk Scout harvests three units per stroke")
	await create_timer(1.1).timeout
	main.queue_free();await create_timer(.2).timeout;print("CREW24_ROLES_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
