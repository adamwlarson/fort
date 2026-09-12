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
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24764;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.toast_time=0
	var map:=w.hud.map
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	p.position=Vector3(0,.7,18);map.refresh()
	check(not map.resources_enabled and map.resources.is_empty(),"default minimap omits individual resource noise")
	check(map.point(p.position)==Vector2.ZERO and map.point(p.position+Vector3(0,0,-100))==Vector2(0,-80),"local player stays centered; fixed north-up 100m scale")
	check(map.rooms.size()==1,"finished starting keep provides subtle castle footprint")
	for i in 3:w.recv_player(50+i,{"name":"Map Dwarf","class":i+1});w.players[50+i].set_physics_process(false);w.players[50+i].position=p.position
	w.players[51].health=0;w.players[52].position=Vector3(500,.7,0)
	for i in 80:w.recv_enemy(23000+i,"Raider",Vector3(30+i*.08,.7,10),100)
	w.recv_enemy(23100,"Brute",Vector3(600,0,0),100)
	w.recv_enemy(23101,"Raider",Vector3(-60,0,18),100,0)
	for site in w.encounters.sites.values():site.seen=false
	map.refresh()
	check(map.crew.size()==3 and map.crew.any(func(c):return c.down) and map.crew.any(func(c):return c.outside),"all allies retained including downed and distant crew")
	check(map.threats.size()==1 and map.threats[0].count==80,"80 nearby raiders collapse into one threat group; far enemies and guards excluded")
	check(map.sites.is_empty(),"undiscovered encounters remain hidden")
	var index:=0
	for site in w.encounters.sites.values():site.seen=true;site.phase="sleeping";index+=1
	map.refresh();check(map.sites.size()>0 and map.sites.size()<=4,"discovered local sites shown with a four-marker cap")
	await create_timer(.2).timeout;await shot("minimap23_clean")
	var event:=InputEventKey.new();event.physical_keycode=KEY_M;event.pressed=true;root.push_input(event);await process_frame;map.refresh()
	check(map.resources_enabled and map.resources.size()>0 and map.resources.size()<=10,"M enables bounded resource patches through actual input")
	for patch in map.resources:check(map.inside(patch.pos),"resource patch remains inside circular map")
	var separated:=true
	for i in map.marker_bounds.size():
		for j in range(i+1,map.marker_bounds.size()):
			if map.marker_bounds[i].intersects(map.marker_bounds[j]):separated=false
	check(separated,"map markers avoid overlap")
	await create_timer(.2).timeout;await shot("minimap23_resources")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	w.recv_enemy(23200,"Raider",p.position+Vector3(.1,0,0),100);map.refresh()
	check(map.threats.size()==1,"point-blank enemy remains visible beside the player marker")
	for id in w.enemies.keys():w.recv_enemy_dead(id)
	for i in 8:w.recv_enemy(23300+i,"Raider",p.position+Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*8,100)
	map.refresh();check(map.threats.size()==8,"surrounded player retains all eight nearby threat directions")
	for badge in w.readability.badges.values():check(not badge.visible or not map.reserves(Rect2(badge.position,badge.size)),"world badges do not cover minimap")
	w.menu_open=true;map._process(.3);root.push_input(event);await process_frame
	check(not map.visible and map.resources_enabled,"menu hides map and prevents resource toggle")
	w.menu_open=false;w.local_build_mode=true;map._process(.3);check(not map.visible,"build cards do not overlap minimap");w.local_build_mode=false
	p.position=Vector3(400,.7,300);map.refresh()
	check(map.hearth_outside and is_equal_approx(map.hearth_point.length(),68) and map.hearth_point.x<0 and map.hearth_point.y<0,"distant home stays pinned toward the correct rim")
	check(map.threats.is_empty() and map.resources.is_empty(),"local map does not compress the entire world as player travels")
	map._process(.3);await create_timer(.2).timeout;await shot("minimap23_exploration")
	for site in w.encounters.sites.values():site.phase="claimed"
	p.position=Vector3(0,.7,18);map.refresh();check(map.sites.is_empty(),"claimed sites no longer clutter navigation")
	w.ended=true;map._process(.3);check(not map.visible,"end screen hides map")
	main.queue_free();await create_timer(.1).timeout
	print("MINIMAP23_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
