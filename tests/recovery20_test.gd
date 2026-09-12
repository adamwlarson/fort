extends SceneTree
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func frames(count:int)->void:
	for i in count:await physics_frame;p.look_yaw=0;p._physics_process(1.0/60)
func box(pos:Vector3,size:Vector3)->StaticBody3D:
	var shape:=BoxShape3D.new();shape.size=size
	var body:=StaticBody3D.new();var col:=CollisionShape3D.new();col.shape=shape;body.add_child(col);w.add_child(body);body.position=pos;return body
func tap(key:Key)->void:
	var event:=InputEventKey.new();event.keycode=key;event.physical_keycode=key;event.pressed=true;root.push_input(event,true)
	event=event.duplicate();event.pressed=false;root.push_input(event,true);await create_timer(.08).timeout
func shot(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+name+".png"))
func complete(k:String)->void:
	p.position=w.castle.rooms[k].sign;w.castle.fund(1,k,true,w.castle.revision)
	for i in 100:
		if w.castle.rooms[k].task=="":break
		w.clock+=.7;w.castle.work(1,k)
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24809;main._host();main._start_match()
	w=main.world;p=w.local_player();w.set_process(false);p.set_physics_process(false);w.set_hearth_level(8)
	await create_timer(.1).timeout
	for start in [Vector3(0,2.5,0),Vector3(0,.65,0),Vector3(1.2,.65,0)]:
		p.position=start;p.velocity=Vector3.ZERO;await frames(30);Input.action_press("move_right");await frames(90);Input.action_release("move_right")
		print("FIRE_EXIT ",start," -> ",p.position)
		# Stockpile starts at x=3.45; reaching it means the hearth is behind us.
		check(p.position.x>2 and p.position.y<.7,"walk off campfire without jumping from "+str(start))
	for rune in w.find_children("HearthRune*","Node3D",true,false):
		for body in rune.find_children("*","StaticBody3D",true,false):check(body.collision_layer==0,"decorative hearth runes cannot trap players")
	# Controlled platform above scenery isolates step and recovery physics.
	var platform:=box(Vector3(0,15,0),Vector3(40,1,40))
	var ledge:=box(Vector3(3,15.6,0),Vector3(2,.2,4))
	p.position=Vector3(0,15.55,0);p.velocity=Vector3.ZERO;await frames(15);Input.action_press("move_right");await frames(50);Input.action_release("move_right")
	check(p.position.x>4,"dwarf steps across a low ledge without jumping")
	var wall:=box(Vector3(8,17,0),Vector3(1,3,8))
	p.position=Vector3(6,15.55,0);p.velocity=Vector3.ZERO;await frames(15);Input.action_press("move_right");await frames(170);Input.action_release("move_right")
	check(p.position.x<7.3 and p.position.x>6,"normal wall blocks movement without automatic teleport")
	check(not FortRecovery.occupied(w,p,p.position,true),"standing against a wall is not classified as embedded")
	var trap:=box(Vector3(0,16.5,0),Vector3(2,2,2));await physics_frame;await physics_frame
	p.position=Vector3(0,15.55,0);p.velocity=Vector3.ZERO;p.carrying={"wood":7,"stone":3};p.health=37;p.invulnerable=0
	check(FortRecovery.occupied(w,p,p.position,true),"true geometric overlap is detected")
	await tap(KEY_ESCAPE);var button:Button=w.hud.menu.find_child("UnstuckButton",true,false)
	check(w.hud.menu.visible and is_instance_valid(button),"Escape menu exposes recovery")
	await shot("recovery20_menu");button.grab_focus();await tap(KEY_ENTER)
	check(not w.menu_open and p.position.distance_to(Vector3(0,15.55,0))>1,"keyboard recovery moves player and returns to play")
	check(p.position.y>15 and not FortRecovery.occupied(w,p,p.position),"recovery finds clear ground on the same elevated floor")
	check(p.health==37 and p.invulnerable==0 and p.carrying=={"wood":7,"stone":3},"recovery preserves pack and health without granting invulnerability")
	var safe:=p.position;w.request_action("unstuck");check(p.position==safe,"duplicate recovery is rate limited")
	w.clock+=16;p.health=0;p.position=Vector3(0,15.55,0);w.request_action("unstuck")
	check(p.health==0 and not FortRecovery.occupied(w,p,p.position),"downed dwarf can escape without reviving")
	w.clock+=16;p.health=37;p.position=Vector3(0,15.55,0);w.request_action("unstuck_auto")
	check(not FortRecovery.occupied(w,p,p.position),"server accepts automatic recovery only for an embedded dwarf")
	w.clock+=16;safe=p.position;w.request_action("unstuck_auto");check(p.position==safe,"automatic request on clear ground does nothing")
	p.position=Vector3(0,-20,0);safe=FortRecovery.destination(w,p)
	check(safe.is_finite() and safe.y>0 and not FortRecovery.occupied(w,p,safe),"out-of-world recovery falls back to verified hearth ground")
	for node in [trap,wall,ledge,platform]:node.queue_free()
	await physics_frame;await physics_frame
	# Reproduce the staircase's progression lock through actual building actions.
	w.set_hearth_level(1);w.scenery_keepouts.clear();w.shared={"wood":5000,"stone":5000,"crystal":5000,"iron":5000,"aether":5000}
	var directions:=w.castle.candidates("0:0:0");var first:Dictionary=directions[0]
	p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",first,"Stairs",w.castle.revision);complete(first.key)
	var upper:={"x":first.x,"z":first.z,"floor":1}
	check(w.castle.completed_ground()==1 and w.castle.plan_reason(first.key,upper,"Courtyard").contains("1/4"),"finished stairwell alone explains exact 1/4 lock; keep does not count")
	p.position=w.castle.rooms[first.key].sign;w.castle.menu.open_nearest()
	var menu:=w.castle.menu
	for i in menu.options.size():
		if menu.options[i].label=="Upstairs":menu.choices.select(i);menu.choices.item_selected.emit(i);break
	check(menu.plan_button.disabled and menu.placement_status.text.contains("1/4") and menu.placement_status.text.contains("starting keep"),"upstairs shows visible actionable requirement next to disabled button")
	check(menu.choices.get_item_text(menu.choices.selected).contains("1/4"),"upstairs dropdown replaces vague Blocked with progress")
	await shot("recovery20_upstairs_locked");menu.close_panel()
	for i in range(1,4):
		p.position=w.castle.rooms["0:0:0"].sign;w.castle.plan(1,"0:0:0",directions[i],"Courtyard",w.castle.revision)
		if i==3:check(w.castle.plan_reason(first.key,upper,"Courtyard").contains("3/4"),"unfinished fourth blueprint does not unlock upstairs")
		complete(directions[i].key)
	check(w.castle.plan_reason(first.key,upper,"Courtyard")=="","four completed ground wings unlock upstairs at hearth one")
	p.position=w.castle.rooms[first.key].sign;menu.open_nearest();menu.refresh_preview();menu.update_guidance()
	check(not menu.plan_button.disabled and menu.placement_status.text.contains("READY TO PLACE"),"same upstairs choice enables after required construction")
	await shot("recovery20_upstairs_ready");menu.close_panel()
	w.castle.plan(1,first.key,upper,"Courtyard",w.castle.revision);complete(FortCastle.key(first.x,first.z,1))
	check(w.castle.rooms[FortCastle.key(first.x,first.z,1)].complete,"unlocked upstairs can actually be supplied and hand built")
	main.queue_free();await create_timer(.1).timeout;print("RECOVERY20_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
