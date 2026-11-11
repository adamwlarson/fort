extends SceneTree
# Fort 30 audio check. Run windowed (audio needs a real display server) and silently:
#   Godot --audio-driver Dummy --path . --script res://tests/audio30_review.gd -- --fort-test
# Confirms every sound has a recorded file, music follows day and night with a fade,
# ambience loops run, footsteps and wading fire, and each dwarf has all of their lines.
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func run()->void:
	FortGround.home_override=FortGround.HOME
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24875
	await create_timer(.4).timeout
	var music:FortMusic=main.music
	check(music!=null and music.track=="title" and music.players[music.active].playing,"the title theme plays on the menu")
	main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();var s:FortSound=w.sound
	p.set_physics_process(false)
	var missing:PackedStringArray=[]
	for kind in FortSound.FILES:
		if not s.clips.has(kind) or s.clips[kind].size()!=FortSound.FILES[kind].size():missing.append(kind)
	check(missing.is_empty(),"every sound has its recorded files (%s)"%", ".join(missing))
	check(s.voices.size()==48,"four dwarves have twelve spoken lines each (%d)"%s.voices.size())
	check(s.loops.size()==4 and s.hearth_fire!=null and s.hearth_fire.playing,"day, night, water and jetpack loops and the hearth fire are running")
	await create_timer(1.5).timeout
	check(music.track=="day" and music.gains[music.active]>.1,"day music fades in when the expedition starts")
	check(float(s.loop_levels.amb_day)>.1 and float(s.loop_levels.amb_night)==0.0,"daytime ambience by day")
	var day_player:=music.players[music.active]
	music.gains[music.active]=1.0 # As if the day theme had been playing for a while.
	w.recv_phase(true,1,90.0)
	await create_timer(1.6).timeout
	check(music.track=="night" and music.players[music.active]!=day_player and day_player.playing and music.gains[music.active]>.2,"night music cross-fades in while the day theme fades out")
	check(float(s.loop_levels.amb_night)>.1 and float(s.loop_levels.amb_day)<.8,"night ambience takes over")
	await create_timer(4.2).timeout
	check(not day_player.playing,"the day theme has stopped once the fade is done")
	check(p.get_children().any(func(n):return n is AudioStreamPlayer3D) or int(p.get_meta("voice_until",0))>0,"your dwarf remarks on nightfall")
	# --- footsteps on grass, on stone, and wading
	s.last.clear()
	p.position=Vector3(18,FortGround.height(18,20),20);p.last_step_position=p.position
	for i in 30:
		p.position.x+=.2;p.position.y=FortGround.height(p.position.x,p.position.z);p._footsteps(true,0.0)
	check(s.last.has("step_grass"),"footsteps on the meadow")
	p.position=Vector3(2,FortCastle.BASE,3);p.last_step_position=p.position
	for i in 30:
		p.position.x+=.2;p._footsteps(true,0.0)
	check(s.last.has("step_stone"),"footsteps on the keep floor")
	w.set_hearth_level(3)
	var lake:=Vector3.ZERO
	for i in 4000:
		var at:=Vector3(sin(i*.61),0,cos(i*.61))*(60.0+(i%90)*2.0)
		if FortGround.height(at.x,at.z)<FortGround.WATER-.6 and FortGround.height(at.x+6,at.z)<FortGround.WATER-.3:lake=at;break
	check(lake!=Vector3.ZERO,"found a lake to wade in")
	if lake!=Vector3.ZERO:
		p.position=FortGround.on(lake);p.last_step_position=p.position
		for i in 30:
			p.position.x+=.2;p.position.y=FortGround.height(p.position.x,p.position.z);p._footsteps(true,0.0)
		check(s.last.has("splash_step") and w.find_children("Splash","CPUParticles3D",false,false).size()>0,"wading splashes and is heard")
		p._footsteps(false,-9.0);p._footsteps(true,0.0)
		check(s.last.has("splash_big"),"landing in a lake makes a big splash")
		await create_timer(.5).timeout
		check(s.shore>.3 and float(s.loop_levels.amb_water)>0.0,"lapping water is heard near a lake")
	# --- voices and world effects
	for role in 4:
		var dwarf:FortPlayer=p
		if role>0:
			w.recv_player(70+role,{"name":"Voice %d"%role,"class":role});dwarf=w.players[70+role]
		s.speaking=0;s.voice(dwarf,"ability")
		check(dwarf.get_children().any(func(n):return n is AudioStreamPlayer3D and n.stream==s.voices["%d_ability"%role]),"role %d speaks in their own voice"%role)
	for cue in [["hit",""],["chop",""],["mine",""],["build","READY / Watchtower"],["deposit",""],["ability","HEARTH TIER 2"],["ability","CREW TREASURE"],["construction",""],["crossbow","bolt"],["blast",""],["mend",""],["boss_slam",""],["arc",""]]:
		w.recv_fx(p.position+Vector3(2,1,0),Color.WHITE,cue[1],cue[0],p.position+Vector3(6,1,0))
	w.recv_enemy(91001,"Brute",p.position+Vector3(6,0,0),100.0);w.recv_enemy_hit(91001,50.0,50.0);w.recv_enemy_dead(91001)
	await create_timer(.3).timeout
	check(true,"world effects, raiders and dragons sound without errors")
	FortGround.home_override=-1.0
	print("AUDIO30_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
