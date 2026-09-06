extends SceneTree
var failures:=0

# Exercise the real director without rendering thousands of synthetic enemies.
# Turnover here is a test input, NOT a bot or a predicted player win rate.
class RaidSandbox extends FortWorld:
	var invalid:=false
	func broadcast(_method:String,_args:Array=[])->void:pass
	func _spawn_enemy(kind:="",angle:=INF)->bool:
		if enemies.size()>=raid_cap():return false
		var permitted:=false
		for lane in director.lanes():
			if absf(angle_difference(angle,lane*PI/2))<=.171:permitted=true
		if not permitted:invalid=true
		enemies[next_enemy_id]={"kind":kind,"camp":-1,"born":director.elapsed}
		next_enemy_id+=1;raid_spawned+=1;return true

func _initialize()->void:run.call_deferred()
func wait(t:float)->void:await create_timer(t).timeout
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func capture(key:String)->void:
	await wait(.2)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/"+key+".png"))

func matrix()->void:
	var valid:=true
	for night in range(1,11):
		for hearth in range(1,4):
			var previous:=0
			for crew in range(1,5):
				var budget:=FortBalance.budget(night,hearth,crew)
				valid=valid and budget>previous and FortBalance.active_cap(night,crew)<=100
				previous=budget
	check(valid,"all 120 night / hearth / crew combinations increase budget for every extra dwarf")
	var traces:=0;var specialists:=0;valid=true
	for night in [1,5,10]:
		for hearth in [1,2,3]:
			for crew in range(1,5):
				for turnover in [0,20]:
					var w:=RaidSandbox.new();w.wave=night;w.hearth_level=hearth;w.is_night=true;w.phase_time=w.night_length(night)
					for id in crew:w.players[id]={"health":0 if id==0 else 100}
					w.director=FortRaidDirector.new(w);var d:=w.director;d.rng.seed=800+night+crew;d.start()
					var previous_spent:=0
					for step in ceili(w.phase_time*4):
						if turnover>0:
							for id in w.enemies.keys():
								if d.elapsed-float(w.enemies[id].born)>=turnover:w.enemies.erase(id)
						previous_spent=d.spent;d.tick(.25)
						valid=valid and d.spent<=FortBalance.budget(night,hearth,crew) and d.pulse_spent<=d.allowance and w.enemies.size()<=FortBalance.active_cap(night,crew)
						if d.pulse<0 or d.elapsed>d.pulse_end(d.pulse) or d.elapsed>=d.cutoff:valid=valid and d.spent==previous_spent
						var counts:=d.population()
						for kind in ["Sapper","Brute","Ashwing","Bombwing","Cinderlobber"]:
							valid=valid and int(counts.get(FortBalance.category(kind),0))<=FortBalance.special_cap(kind,night,crew)
						if counts.get("Brute",0)>0:specialists+=1
					valid=valid and not w.invalid and d.spent>0 and d.crew==crew
					if hearth==1 and turnover==20:print("BALANCE_TRACE ",JSON.stringify({"night":night,"crew":crew,"budget":FortBalance.budget(night,hearth,crew),"spent":d.spent,"spawned":w.raid_spawned,"peak":d.metrics.peak_active,"turnover_seconds":turnover}))
					traces+=1;w.free()
	check(valid and traces==72 and specialists>0,"72 deterministic director traces obey budgets, front lanes, breather windows and specialist caps, including downed crews")

func run()->void:
	matrix()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main._host();main._start_match()
	var w:FortWorld=main.world;var p:FortPlayer=w.local_player();w.set_process(false);p.set_physics_process(false)
	check(w.phase_time==180,"solo first day includes 30 extra preparation seconds")
	w.shared={"wood":500,"stone":500,"crystal":500,"iron":500,"aether":500}
	for role in 4:
		p.class_id=role;p.position=Vector3(0,0,25)
		w._spawn_defense("Watchtower",Vector3(0,0,22),0,false);var id:int=w.next_defense_id-1
		w.construction.begin(id,1,{},"build")
		var strokes:=4 if role==2 else 8
		for stroke in strokes-1:w.clock+=.8;w.construction.work(1,id)
		check(FortConstruction.pending(w.defenses[id]),"solo class %d still needs final construction stroke"%role)
		w.clock+=.8;w.construction.work(1,id)
		check(not FortConstruction.pending(w.defenses[id]),"solo class %d completes tower in %d strokes"%[role,strokes])
		w.recv_remove_defense(id)
	p.class_id=0;p.position=Vector3(0,0,5)
	w._advance_phase();var d:=w.director;d.tick(3.1)
	check(d.active and d.crew==1 and d.pulse==0,"first assault starts with solo pressure")
	p.invulnerable=0;w._set_health(1,0);check(p.down_time==8 and w.solo_rescue_wave==1,"first solo knockdown gets 8-second rescue")
	w._respawn(1);p.invulnerable=0;w._set_health(1,0);check(p.down_time==18,"repeat knockdown cannot reuse emergency rescue")
	w._respawn(1)
	w.progression._activate(1);var boss_hp:=0.0;var guards:=0
	for e in w.enemies.values():
		if int(e.get("camp",-1))==1:
			guards+=1
			if e.kind=="Chieftain":boss_hp=e.max_hp
	check(guards==2 and is_equal_approx(boss_hp,487.5),"solo camp has one escort and a 65%-health chief")
	for id in [42,43,44]:w.recv_player(id,{"name":"Crew","class":id-41});w.players[id].set_physics_process(false)
	check(d.crew==1,"late join does not inflate the current assault")
	d.tick(d.pulse_start(1)-d.elapsed+.01)
	check(d.crew==4 and d.lane_count()==4,"next assault adopts four-player pressure and four fronts")
	w.players[42].invulnerable=0;w._set_health(42,0)
	check(w.players[42].down_time==18 and d.crew==4,"downed teammate does not lower pressure or grant a solo rescue")
	w.progression._activate(1);check(w.progression.sites[1].encounter_crew==1,"activated camp retains its original crew scaling")
	w.progression._activate(6);guards=0
	for e in w.enemies.values():
		if int(e.get("camp",-1))==6:guards+=1
	check(guards==5,"new four-player camp spawns four escorts and one chief")
	var remote:=FortRaidDirector.new(w);remote.receive(d.state());var state:=remote.state();var stale:=state.duplicate();stale.elapsed-=1;stale.crew=1;remote.receive(stale)
	check(remote.state()==state,"stale raid snapshot cannot rewind pressure or assault state")
	w.damage_fort(20);w._spawn_defense("Mender",Vector3(2,0,0),0,false);w.battlements.heal(w.defenses[w.next_defense_id-1],1)
	check(d.metrics.fort_damage==20 and d.metrics.mender_healing>=2 and d.metrics.downs==3 and d.metrics.fast_rescues==1,"night telemetry records actual damage, healing, knockdowns and solo rescue")
	w.hud._process(0);await capture("fort8_assault")
	d.tick(d.pulse_end(d.pulse)-d.elapsed+.1);w.hud._process(0);check(w.objective_text().contains("BREATHER"),"HUD clearly labels repair breaks");await capture("fort8_breather")
	for id in [42,43,44]:w.recv_remove_player(id)
	d.tick(d.pulse_start(2)-d.elapsed+.01);check(d.crew==1,"departed players stop contributing at the next assault")
	w._advance_phase();check(d.reports.size()==1 and not d.active,"dawn closes the combat report and director")
	w._advance_phase();p.invulnerable=0;w._set_health(1,0);check(p.down_time==8,"new night refreshes the solo rescue allowance")
	main._leave_game();await wait(.2);main.queue_free();await wait(.1)
	print("FORT8_TEST_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
