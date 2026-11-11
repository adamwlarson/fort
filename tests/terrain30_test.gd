extends SceneTree
# Fort 30 real terrain: one seeded height field, level shelves under every site, ground that
# matches what is drawn and collided with, scenery and resources seated on it, raiders and
# dwarves walking over it, and castle rooms and foundations levelling the land they stand on.
const P:=preload("res://scripts/fort_pieces.gd")
var failures:=0
var w:FortWorld
var p:FortPlayer
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
## Height of the terrain collider itself, looking past trees, tents and floors.
func ray(x:float,z:float)->float:
	var query:=PhysicsRayQueryParameters3D.create(Vector3(x,400,z),Vector3(x,-60,z),1);var skipped:Array[RID]=[]
	for attempt in 12:
		var hit:=w.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():return NAN
		if (hit.collider as Node).has_meta("terrain"):return float(hit.position.y)
		skipped.append(hit.rid);query.exclude=skipped
	return NAN
## Furthest any ordinary resource stands from the ground.
func floating()->float:
	var worst:=0.0
	for id in w.resource_nodes:
		var node:Node3D=w.resource_nodes[id].node
		var above:=node.position.y-FortGround.height(node.position.x,node.position.z)
		if int(id)>=29000 and int(id)<29010:continue # Hollowback Ridge keeps its own authored hill.
		if node.position.x>90 and node.position.x<150 and absf(above-roundf(above))<.5:continue # Quarry terraces.
		worst=maxf(worst,absf(above))
	return worst
func steps(count:int)->void:
	for i in count:await physics_frame
func run()->void:
	# Play on the real slopes close to the hearth, not the level ring other fixtures use.
	FortGround.home_override=FortGround.HOME
	var started:=Time.get_ticks_msec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24872;main._host();main._start_match()
	w=main.world;p=w.local_player()
	print("TERRAIN30 world ready in ",Time.get_ticks_msec()-started," ms")
	var seed_value:=w.expedition.seed_value
	await steps(3)
	# --- the height field
	check(FortGround.height(0,0)==0.0 and FortGround.height(20,-20)==0.0 and FortGround.height(18,24)==0.0,"Hearthhold stands on level ground")
	var low:=INF;var high:=-INF;var steepest:=0.0
	for x in range(-72,73,3):
		for z in range(-72,73,3):
			if Vector2(x,z).length()>72:continue
			var h:=FortGround.height(x,z);low=minf(low,h);high=maxf(high,h);steepest=maxf(steepest,FortGround.slope(x,z))
	print("TERRAIN30 first ring heights ",snappedf(low,.01)," .. ",snappedf(high,.01)," steepest ",snappedf(steepest,.01))
	check(high-low>1.5,"the first ring has real rises and hollows")
	check(steepest<.9,"every slope inside the first ward can be walked")
	started=Time.get_ticks_usec()
	for i in 100000:FortGround.height(-60+(i%200)*.6,-60+(i/200)*.24)
	print("TERRAIN30 100k height lookups ",(Time.get_ticks_usec()-started)/1000," ms")
	# --- what you stand on is what the lookup says
	var worst:=0.0
	var random:=RandomNumberGenerator.new();random.seed=30
	for i in 300:
		var a:=random.randf()*TAU;var d:=sqrt(random.randf())*100.0
		var x:=sin(a)*d;var z:=cos(a)*d
		worst=maxf(worst,absf(ray(x,z)-FortGround.height(x,z)))
	check(worst<.02,"collision matches the height lookup everywhere (worst %.3f m)"%worst)
	# --- sites sit on level shelves at their own height
	var shelf:=0.0;var spread:=0.0;var lowest:=INF;var highest:=-INF
	var places:Array=FortProgression.SITES.duplicate();places.append_array(FortLandscape.LANDMARKS);places.append_array(FortEncounters.layout(seed_value))
	for site in places:
		var at:Vector3=site.pos
		lowest=minf(lowest,at.y);highest=maxf(highest,at.y)
		shelf=maxf(shelf,absf(at.y-FortGround.height(at.x,at.z)))
		for corner in [Vector2(8,0),Vector2(-8,0),Vector2(0,8),Vector2(0,-8),Vector2(6,6)]:spread=maxf(spread,absf(FortGround.height(at.x+corner.x,at.z+corner.y)-at.y))
	check(shelf<.01 and spread<.01,"every camp, landmark and wilderness site stands on a level shelf")
	check(highest-lowest>4.0,"sites sit at different heights (%.1f m apart)"%(highest-lowest))
	for id in w.progression.sites:
		check(absf(w.progression.sites[id].node.position.y-FortProgression.SITES[id].pos.y)<.01,"treasure site %d is built at its shelf"%id)
	# --- resources and scenery follow the ground
	check(floating()<.5,"trees, rocks and crystals stand on the ground (worst %.2f m)"%floating())
	var rocks:=w.find_child("MarchlandsScenery",true,false).find_children("*","Node3D",false,false)
	var loose:=0.0;var counted:=0
	for rock in rocks:
		if rock is MultiMeshInstance3D or not rock.has_meta("grounded"):continue
		counted+=1;loose=maxf(loose,absf(rock.position.y-FortGround.height(rock.position.x,rock.position.z)))
	check(counted>20 and loose<1.6,"meadow scenery is seated on the hills")
	# --- a dwarf lands on a hillside and stays there
	var hill:=Vector2.ZERO;var tallest:=0.0
	for i in 72:
		var at:=Vector2(sin(i*TAU/72),cos(i*TAU/72))*62.0
		if absf(FortGround.height(at.x,at.y))>tallest and FortGround.slope(at.x,at.y)<.5:tallest=absf(FortGround.height(at.x,at.y));hill=at
	p.position=Vector3(hill.x,FortGround.height(hill.x,hill.y)+2.5,hill.y);p.velocity=Vector3.ZERO
	await steps(70)
	check(absf(p.position.y-FortGround.height(p.position.x,p.position.z))<.12 and p.is_on_floor(),"a dwarf dropped on a hillside lands on it (%.1f m up)"%FortGround.height(hill.x,hill.y))
	check(w.castle.floor_at(p.position)==FortGround.height(p.position.x,p.position.z),"open ground is a floor to build on")
	# --- raiders cross the hills to the hearth
	p.position=Vector3(0,FortCastle.BASE+.2,3);p.set_physics_process(false)
	var spawn:=FortGround.on(Vector3(hill.x,0,hill.y),.2)
	w.recv_enemy(77001,"Raider",spawn,400.0)
	var raider:CharacterBody3D=w.enemies[77001].node;var buried:=0.0;var from:=raider.position.length()
	for i in 420:
		await physics_frame
		if not w.enemies.has(77001):break
		buried=maxf(buried,FortGround.height(raider.position.x,raider.position.z)-raider.position.y)
	check(w.enemies.has(77001) and raider.position.length()<from-12.0,"a raider walks in over the hills (%.0f m closer)"%(from-raider.position.length()))
	check(buried<.3,"it never sinks into the ground")
	if w.enemies.has(77001):w.recv_enemy_dead(77001)
	w._spawn_enemy("Raider",1.1)
	var fresh:Dictionary=w.enemies[w.next_enemy_id-1]
	check(absf(fresh.node.position.y-FortGround.height(fresh.node.position.x,fresh.node.position.z))<.01,"raids spawn on the ground at the edge of the build zone")
	w.recv_enemy_dead(w.next_enemy_id-1)
	# --- towers stand on slopes
	w.shared={"wood":1000,"stone":1000,"crystal":100,"iron":1000,"aether":100};w.set_hearth_level(2)
	var slope_spot:=Vector3.ZERO
	for i in 900:
		var at:=FortGround.on(Vector3(sin(i*.37),0,cos(i*.37))*(42.0+(i%22)))
		if absf(at.y)>.5 and w.build_block_reason("Watchtower",at,0).is_empty():slope_spot=at;break
	check(slope_spot!=Vector3.ZERO,"a watchtower can be placed on sloping ground (%.1f m up)"%slope_spot.y)
	if slope_spot!=Vector3.ZERO:
		w._spawn_defense("Watchtower",slope_spot,0,false)
		check(absf(w.defenses[w.next_defense_id-1].node.position.y-slope_spot.y)<.01,"and it stands at ground height")
	# --- foundations level the land beneath them
	var cell:=-1;var cell_height:=0.0;var steep_cell:=-1
	for ix in range(-16,17):
		for iz in range(-16,17):
			var at:=FortPieces.place(FortPieces.key(P.DECK,ix,iz,0))
			if Vector2(at.x,at.z).length()>w.build_radius()-3:continue
			var h:=FortGround.height(at.x,at.z)
			if cell<0 and absf(h)>.35 and absf(h)<1.1 and w.pieces.reason("Foundation",FortPieces.key(P.DECK,ix,iz,0),0)=="":cell=FortPieces.key(P.DECK,ix,iz,0);cell_height=h
			if absf(h)>1.3:steep_cell=FortPieces.key(P.DECK,ix,iz,0)
	check(cell>=0,"a foundation can start on a gentle slope")
	if cell>=0:
		var at:=FortPieces.place(cell)
		w.pieces.recv_piece(cell,"Foundation",0,1200.0);FortGround.ensure(w)
		check(absf(FortGround.height(at.x,at.z))<.01 and absf(FortGround.height(at.x+2,at.z-2))<.01,"the ground is cut level under it (was %.2f m)"%cell_height)
		check(absf(ray(at.x+1,at.z+1)-FortPieces.place(cell).y)<.8,"collision follows the levelled ground")
		w.pieces.recv_piece_gone(cell,"");FortGround.ensure(w)
		check(absf(FortGround.height(at.x,at.z)-cell_height)<.01,"removing it lets the land return")
	if steep_cell>=0:check(w.pieces.reason("Foundation",steep_cell,0).contains("steep"),"a foundation is refused where the ground is too steep")
	# --- castle rooms level their plot
	var room:={"x":2,"z":1,"floor":0,"kind":"Courtyard","complete":true,"funded":{},"work":0.0,"total":0.0,"sign":Vector3(32,FortCastle.BASE,20),"walls":[],"task":"","resource":"wood"}
	var before:=FortGround.height(46,26)
	w.castle.rooms["2:1:0"]=room;w.castle.changed();FortGround.ensure(w)
	var flat:=0.0
	for x in range(31,50,3):
		for z in range(11,30,3):flat=maxf(flat,absf(FortGround.height(x,z)))
	check(flat<.01,"a castle room stands on levelled ground (corner was %.2f m)"%before)
	check(absf(ray(45,25)-FortCastle.BASE)<.5 or absf(ray(45,25))<.5,"and its floor can be walked")
	check(floating()<.5,"everything nearby settles onto the new ground")
	# --- the opened frontier
	started=Time.get_ticks_msec()
	w.set_hearth_level(3)
	print("TERRAIN30 hearth 3 opened in ",Time.get_ticks_msec()-started," ms")
	await steps(2)
	worst=0.0
	for i in 200:
		var a:=random.randf()*TAU;var d:=80.0+random.randf()*160.0
		worst=maxf(worst,absf(ray(sin(a)*d,cos(a)*d)-FortGround.height(sin(a)*d,cos(a)*d)))
	check(worst<.02,"the whole opened frontier is solid ground (worst %.3f m)"%worst)
	steepest=0.0;var steep_at:=Vector2.ZERO
	for i in 4000:
		var a:=random.randf()*TAU;var d:=40.0+random.randf()*200.0
		if FortGround.slope(sin(a)*d,cos(a)*d)>steepest:steepest=FortGround.slope(sin(a)*d,cos(a)*d);steep_at=Vector2(sin(a)*d,cos(a)*d)
	print("TERRAIN30 steepest frontier slope ",snappedf(steepest,.01)," at ",steep_at)
	check(steepest<1.0,"no slope inside the frontier is too steep to climb")
	check(floating()<.5,"frontier resources stand on the ground (worst %.2f m)"%floating())
	var ridge:=w.frontier.get_node_or_null("HollowbackRidge") as Node3D
	check(ridge!=null and absf(ridge.position.y-FortGround.height(ridge.position.x,ridge.position.z))<.01,"Hollowback Ridge stands on its shelf")
	var quarry:=w.frontier.get_node_or_null("RustscarQuarry") as Node3D
	check(quarry!=null and absf(quarry.position.y-FortGround.height(120,7))<.01 and absf(FortGround.height(100,-20)-FortGround.height(140,30))<.01,"Rustscar Quarry stands on one level shelf")
	# --- water: wadeable lakes in the hollows, never under a camp, a road or a tree
	var wet_points:=0;var deepest:=0.0;var surveyed:=0
	for i in 20000:
		var a:=random.randf()*TAU;var d:=sqrt(random.randf_range(40.0*40.0,640.0*640.0))
		var h:=FortGround._computed(sin(a)*d,cos(a)*d);surveyed+=1
		if h<FortGround.WATER-.05:wet_points+=1;deepest=maxf(deepest,FortGround.WATER-h)
	print("TERRAIN30 water covers ",snappedf(wet_points*100.0/surveyed,.1),"% of the land, deepest ",snappedf(deepest,.01)," m")
	check(wet_points>surveyed/200,"hollows hold lakes and ponds")
	check(deepest<=FortGround.WADE+.01,"every lake can be waded (deepest %.2f m)"%deepest)
	var drowned:=0
	for site in places:
		if site.pos.y<FortGround.WATER+.5:drowned+=1
	check(drowned==0,"no camp, landmark or wilderness site is under water")
	var soaked:=0
	for resource in w.resource_nodes.values():
		if FortGround._computed(resource.node.position.x,resource.node.position.z)<FortGround.WATER:soaked+=1
	check(soaked==0,"trees, rocks and ore moved to the shore instead of standing in a lake")
	var flooded:=0
	for step in range(40,640,3):
		for road in [Vector2(step,0),Vector2(-step,0),Vector2(0,step),Vector2(0,-step)]:
			if FortGround._computed(road.x,road.y)<FortGround.WATER+.2:flooded+=1
	check(flooded==0,"the four roads stay dry")
	# --- every machine rebuilds the same land from the seed
	var first:Array=[]
	for i in 40:first.append(FortGround.natural(-140+i*7.3,90-i*4.1))
	var site_before:Vector3=FortProgression.SITES[3].pos
	w.expedition.configure(seed_value+977);FortGround.ensure(w)
	var other:Array=[]
	for i in 40:other.append(FortGround.natural(-140+i*7.3,90-i*4.1))
	w.expedition.configure(seed_value);FortGround.ensure(w)
	var back:Array=[]
	for i in 40:back.append(FortGround.natural(-140+i*7.3,90-i*4.1))
	check(other!=back,"another expedition seed gives different land")
	check(back==first and FortProgression.SITES[3].pos.is_equal_approx(site_before),"the same seed rebuilds exactly the same land")
	check(floating()<.5,"after a seed change everything is re-seated on the new land")
	soaked=0
	for resource in w.resource_nodes.values():
		if FortGround._computed(resource.node.position.x,resource.node.position.z)<FortGround.WATER:soaked+=1
	check(soaked==0,"and nothing is left standing in the new lakes")
	FortGround.home_override=-1.0
	print("TERRAIN30_RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	main.queue_free();await process_frame;quit(0 if failures==0 else 1)
