class_name FortRaidDirector
extends RefCounted

var world:FortWorld
var rng:=RandomNumberGenerator.new()
var active:=false
var night:=0
var crew:=1
var hearth:=1
var duration:=0.0
var cutoff:=0.0
var pulses:=3
var pulse:=-1
var lane_base:=0
var elapsed:=0.0
var total:=0
var spent:=0
var allowance:=0
var pulse_spent:=0
var next_spawn:=0.0
var sequence:=0
var pending_kind:=""
var warning_pulse:=-1
var revision:=0
## Fort 31: raid multiplier from the size of the fort, fixed at dusk.
var power:=1.0
var fort_strength:=0.0
var metrics:Dictionary={}
var reports:Array[Dictionary]=[]

func _init(w:FortWorld)->void:
	world=w;rng.randomize()

func start()->void:
	active=true;night=world.wave;crew=clampi(world.players.size(),1,GameData.MAX_PLAYERS);hearth=world.hearth_level
	fort_strength=FortBalance.strength(world);power=FortBalance.pressure(fort_strength,hearth)
	duration=world.phase_time;elapsed=0;total=roundi(FortBalance.budget(night,hearth,crew)*power);spent=0
	if power>1.045:world.broadcast("recv_notice",["THE HORDE ANSWERS YOUR WALLS / fort strength %d / raid +%d%%"%[roundi(fort_strength),roundi((power-1.0)*100.0)]])
	pulses=3 if night<=3 else 4;pulse=-1;warning_pulse=-1;sequence=0;lane_base=rng.randi_range(0,3)
	# Leave even a slow Brute time to reach the central fort, plus a cleanup window.
	var travel:float=(maxf(52,world.build_radius()+15)-8)/1.8+4
	cutoff=maxf(25,duration-travel-8);next_spawn=0;allowance=0;pulse_spent=0;pending_kind="";revision+=1
	metrics={"night":night,"starting_crew":crew,"hearth":hearth,"planned_threat":total,"spent_threat":0,"spawned":0,"killed":0,"peak_active":0,"downs":0,"fast_rescues":0,"fort_damage":0.0,"building_damage":0.0,"repair_wood":0,"mender_healing":0.0,"player_damage":0.0,"tower_damage":0.0,"field_turret_damage":0.0,"fort_strength":roundi(fort_strength),"power":snappedf(power,.01),"elites":0}

func span()->float:return (cutoff-3)/(pulses-.3)
func pulse_start(index:int)->float:return 3+index*span()
func pulse_end(index:int)->float:return pulse_start(index)+span()*.7

func lane_count()->int:return FortBalance.fronts(night,crew)
func lanes()->Array[int]:
	var result:Array[int]=[]
	# Keep one defended side throughout an early solo night; rotate next night.
	for i in lane_count():result.append((lane_base+i)%4)
	return result

func heading()->String:
	var names:=PackedStringArray()
	for lane in lanes():names.append(FortBalance.FRONT_NAMES[lane])
	return " / ".join(names)

func tick(delta:float)->void:
	if not active:start()
	elapsed+=delta
	var next_index:=pulse+1
	if next_index<pulses and elapsed>=pulse_start(next_index)-3 and warning_pulse<next_index:
		warning_pulse=next_index
		world.broadcast("recv_notice",["ASSAULT %d / %d in 3 seconds. Prepare to defend!"%[next_index+1,pulses]])
	if next_index<pulses and elapsed>=pulse_start(next_index):
		# Joining/leaving changes only future assaults. Downed players still count.
		crew=clampi(world.players.size(),1,GameData.MAX_PLAYERS)
		world.broadcast("recv_notice",["DEFEND %s / %d-dwarf pressure"%[heading(),crew]])
		pulse=next_index;pulse_spent=0;next_spawn=elapsed;pending_kind=""
		var planned:=roundi(FortBalance.budget(night,hearth,crew)*power)
		allowance=int(planned/pulses)+(planned%pulses if pulse==pulses-1 else 0)
		total=spent+allowance+int(planned/pulses)*(pulses-pulse-1);revision+=1
	if pulse<0 or elapsed>pulse_end(pulse) or elapsed>=cutoff:return
	var counts:=population()
	metrics.peak_active=maxi(int(metrics.peak_active),int(counts.all))
	if elapsed<next_spawn:return
	next_spawn=elapsed+.35
	# Bound work per frame and spread each finite packet over its release window.
	var due:=mini(allowance,int(allowance*clampf((elapsed-pulse_start(pulse)+.35)/(span()*.7),0,1)))
	for i in 12:
		if counts.all>=world.raid_cap() or pulse_spent+10>due:break
		if not pending_kind.is_empty() and int(counts.get(FortBalance.category(pending_kind),0))>=FortBalance.special_cap(pending_kind,night,crew):pending_kind=""
		if pending_kind.is_empty():
			var candidates:Array[String]=[]
			for kind in FortBalance.pool(night):
				if int(FortBalance.COST[kind])>allowance-pulse_spent:continue
				if int(counts.get(FortBalance.category(kind),0))>=FortBalance.special_cap(kind,night,crew):continue
				candidates.append(kind)
			if candidates.is_empty():break
			pending_kind=candidates[rng.randi_range(0,candidates.size()-1)]
		# Save threat for the chosen specialist rather than spending every trickle on Raiders.
		if int(FortBalance.COST[pending_kind])>due-pulse_spent:break
		var kind:=pending_kind
		# A champion instead of a common raider, when the night is late enough and the budget allows.
		var elite:=""
		if kind in FortElites.HOSTS and int(counts.get("elite",0))<FortElites.cap(night,crew) and FortElites.cost(kind)<=due-pulse_spent and rng.randf()<FortElites.chance(night,power):elite=FortElites.pick(rng)
		var lane:int=lanes()[sequence%lane_count()];sequence+=1
		# Fort 26: raiders arrive from every direction; lanes only pace the pulses.
		var angle:=lane*PI/2+rng.randf_range(-PI/4,PI/4) if lane_count()>=4 else rng.randf()*TAU
		if not world._spawn_enemy(kind,angle,elite):break
		pending_kind=""
		var price:=FortElites.cost(kind) if elite!="" else int(FortBalance.COST[kind])
		pulse_spent+=price;spent+=price
		if elite!="":counts["elite"]=int(counts.get("elite",0))+1;metrics.elites=int(metrics.get("elites",0))+1
		counts.all+=1;var category:=FortBalance.category(kind);counts[category]=int(counts.get(category,0))+1
		metrics.spent_threat=spent;metrics.spawned+=1;metrics.peak_active=maxi(int(metrics.peak_active),int(counts.all))

func population()->Dictionary:
	var result:Dictionary={"all":0}
	for e in world.enemies.values():
		if int(e.get("camp",-1))>=0 or FortEncounters.is_wild(int(e.get("camp",-1))):continue
		result.all+=1;var category:=FortBalance.category(e.kind);result[category]=int(result.get(category,0))+1
		if e.get("elite","")!="":result["elite"]=int(result.get("elite",0))+1
	return result

func record(key:String,amount:float)->void:
	if active and world.is_night:metrics[key]=float(metrics.get(key,0))+amount

func finish()->void:
	if not active:return
	metrics["ending_crew"]=world.players.size();metrics["hearth_remaining"]=world.fort_health;metrics["seconds"]=elapsed
	reports.append(metrics.duplicate(true));print("FORT_BALANCE ",JSON.stringify(metrics))
	active=false;revision+=1

func state()->Dictionary:
	return {"active":active,"night":night,"crew":crew,"pulse":pulse,"pulses":pulses,"elapsed":elapsed,"cutoff":cutoff,"duration":duration,"lane_base":lane_base,"total":total,"spent":spent,"revision":revision,"power":power,"fort_strength":fort_strength}

func receive(data:Dictionary)->void:
	if data.is_empty() or int(data.get("revision",0))<revision:return
	if int(data.get("revision",0))==revision and float(data.get("elapsed",0))<elapsed:return
	active=data.active;night=data.night;crew=data.crew;pulse=data.pulse;pulses=data.pulses;elapsed=data.elapsed
	cutoff=data.cutoff;duration=data.duration;lane_base=data.lane_base;total=data.total;spent=data.spent;revision=data.revision
	power=float(data.get("power",1.0));fort_strength=float(data.get("fort_strength",0.0))

func status()->String:
	if not active:return ""
	if elapsed>=cutoff:return "FINAL PUSH / Hold until dawn"
	if pulse<0:return "Incoming: "+heading()+" / Prepare your defenses."
	if elapsed>pulse_end(pulse):return "BREATHER / Repair and regroup"
	return "ASSAULT %d / %d / %s"%[pulse+1,pulses,heading()]+(" / +%d%%"%roundi((power-1.0)*100.0) if power>1.045 else "")
