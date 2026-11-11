class_name FortStats
extends RefCounted

# Fort 26 character progression. Dwarves earn experience from kills, building and
# gathering; each level grants one stat point. The host owns every value and
# replicates it in the regular player snapshot.
const STATS := ["health","damage","cooldown","speed","storage","mining_speed","mining_eff"]
const NAMES := {"health":"Health","damage":"Damage","cooldown":"Cooldown","speed":"Speed","storage":"Storage","mining_speed":"Mining Speed","mining_eff":"Mining Efficiency"}
const EFFECT := {
	"health":"+12 maximum health per point",
	"damage":"+6% weapon damage per point",
	"cooldown":"-4% attack and ability cooldown per point",
	"speed":"+3% movement speed per point",
	"storage":"+3 pack capacity per point",
	"mining_speed":"-5% time between gathering swings per point",
	"mining_eff":"+10% chance of a bonus resource per point",
}
const MAX_RANK := 10
const MAX_LEVEL := 60

static func need(level:int)->int:return 50+35*(level-1)
static func rank(p:Node,stat:String)->int:return clampi(int(p.stats.get(stat,0)),0,MAX_RANK)
static func health_bonus(p:Node)->float:return 12.0*rank(p,"health")
static func damage_multiplier(p:Node)->float:return 1.0+0.06*rank(p,"damage")
static func cooldown_multiplier(p:Node)->float:return 1.0-0.04*rank(p,"cooldown")
static func speed_multiplier(p:Node)->float:return 1.0+0.03*rank(p,"speed")
static func storage_bonus(p:Node)->int:return 3*rank(p,"storage")
static func gather_multiplier(p:Node)->float:return 1.0-0.05*rank(p,"mining_speed")
static func bonus_chance(p:Node)->float:return 0.10*rank(p,"mining_eff")

static func value_text(p:Node,stat:String)->String:
	match stat:
		"health":return "%d%s"%[int(p.max_health),FortGlyphs.g("hp")]
		"damage":return "x%.2f"%p.weapon_power(p.weapon)
		"cooldown":return "%d%%"%roundi(cooldown_multiplier(p)*100)
		"speed":return "%.1f m/s"%(float(GameData.class_data(p.class_id).speed)*speed_multiplier(p))
		"storage":return "%d slots"%p.carry_limit
		"mining_speed":return "%.2fs / swing"%(0.78*gather_multiplier(p))
		"mining_eff":return "+%d%% bonus"%roundi(bonus_chance(p)*100)
	return ""

## Host only. Grants experience and resolves level-ups.
static func award(world:Node,id:int,amount:int)->void:
	if amount<=0 or not world.multiplayer.is_server() or not world.players.has(id):return
	var p:Node=world.players[id]
	if p.level>=MAX_LEVEL:return
	p.xp+=amount
	var gained:=0
	while p.level<MAX_LEVEL and p.xp>=need(p.level):
		p.xp-=need(p.level);p.level+=1;p.stat_points+=1;gained+=1
	p.stats_revision+=1
	if gained>0:
		world.personal(id,"LEVEL %d!  +%d stat point%s. Press TAB to spend."%[p.level,gained,"" if gained==1 else "s"])
		world.broadcast("recv_fx",[p.position+Vector3.UP*1.2,Color("#7fe0c0"),"LEVEL %d"%p.level,"ability"])

## Shared kill experience for every living dwarf near the fight.
static func award_kill(world:Node,enemy:Dictionary)->void:
	var amount:=maxi(3,int(FortBalance.COST.get(enemy.kind,14))/2)
	if enemy.get("elite","")!="":amount*=3
	if enemy.kind=="Colossus" or enemy.kind in FortEncounters.DRAGONS:amount=90
	elif enemy.kind=="Chieftain":amount=45
	for id in world.players:
		var p:Node=world.players[id]
		if p.health>0 and p.position.distance_to(enemy.node.position)<34:award(world,int(id),amount)

static func spend(world:Node,id:int,stat:String)->void:
	if not world.players.has(id) or stat not in STATS:return
	var p:Node=world.players[id]
	if p.stat_points<=0:world.personal(id,"No stat points left. Earn experience by fighting, building and gathering.");return
	if rank(p,stat)>=MAX_RANK:world.personal(id,NAMES[stat]+" is already at its maximum of %d."%MAX_RANK);return
	p.stats[stat]=rank(p,stat)+1;p.stat_points-=1;p.stats_revision+=1
	p.apply_progression(p.backpack_level,p.relics,p.armor,p.progression_revision)
	if stat=="health":world._set_health(id,p.health+12)

static func state(p:Node)->Dictionary:
	return {"xp":p.xp,"level":p.level,"points":p.stat_points,"stats":p.stats.duplicate(),"stats_revision":p.stats_revision}

static func apply(p:Node,data:Dictionary)->void:
	if int(data.get("stats_revision",-1))<p.stats_revision:return
	var changed:bool=int(data.get("stats_revision",0))!=p.stats_revision
	p.xp=int(data.get("xp",0));p.level=clampi(int(data.get("level",1)),1,MAX_LEVEL);p.stat_points=maxi(0,int(data.get("points",0)))
	p.stats={}
	var raw:Dictionary=data.get("stats",{})
	for stat in STATS:
		if raw.has(stat):p.stats[stat]=clampi(int(raw[stat]),0,MAX_RANK)
	p.stats_revision=int(data.get("stats_revision",0))
	if changed:p.apply_progression(p.backpack_level,p.relics,p.armor,p.progression_revision)
