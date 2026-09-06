class_name GameData
extends RefCounted

const PORT := 24567
const MAX_PLAYERS := 4
const MAX_HEARTH := 8
const MAX_GEAR_LEVEL := 8
const RESOURCES := ["wood","stone","crystal","iron","aether"]

static func network_port()->int:
	# Automated worlds must not interrupt a player's running Fort session.
	return PORT+10 if "--fort-test" in OS.get_cmdline_user_args() else PORT
const CLASSES := [
	{"name":"Iron Vanguard", "color":Color("d94b3d"), "ability":"Ground Slam", "desc":"150 health • heavy axe • slam stuns and damages a crowd", "hp":150.0, "speed":6.0},
	{"name":"Stone Warden", "color":Color("4c83c3"), "ability":"Rally", "desc":"120 health • heals and hastens nearby allies", "hp":120.0, "speed":6.2},
	{"name":"Forge Engineer", "color":Color("e6a43b"), "ability":"Field Turret", "desc":"110 health • repairs twice as fast • deploys a free mini-turret", "hp":110.0, "speed":6.0},
	{"name":"Wild Scout", "color":Color("56ad68"), "ability":"Trailblaze", "desc":"100 health • fast gatherer • dashes and carries more", "hp":100.0, "speed":7.3},
]
const RECIPES := {
	"Watchtower":{"wood":18,"stone":8,"crystal":0,"hp":240.0},
	"Barricade":{"wood":12,"stone":3,"crystal":0,"hp":320.0},
	"Ballista":{"wood":24,"stone":14,"crystal":2,"hp":260.0},
	"Mender":{"wood":16,"stone":12,"crystal":4,"hp":220.0},
	"MetalWall":{"wood":4,"stone":8,"crystal":0,"iron":14,"hp":850.0,"tier":2},
	"StormSpire":{"wood":8,"stone":16,"crystal":4,"iron":12,"aether":8,"hp":340.0,"tier":3},
	"FrostMortar":{"wood":12,"stone":18,"crystal":2,"iron":16,"aether":6,"hp":380.0,"tier":3},
	"Embercoil":{"wood":20,"stone":25,"iron":28,"crystal":8,"aether":10,"hp":460.0,"tier":4},
	"GravityWell":{"wood":12,"stone":40,"iron":32,"crystal":15,"aether":22,"hp":550.0,"tier":5},
	"Sunlance":{"wood":30,"stone":35,"iron":50,"crystal":20,"aether":35,"hp":650.0,"tier":6},
}
const BUILD_ORDER := ["Watchtower", "Barricade", "Ballista", "Mender", "MetalWall", "StormSpire", "FrostMortar", "Embercoil", "GravityWell", "Sunlance"]
const BUILD_DESCS := ["Automatic ranged defense\n17m range / upgrades extend reach","A sturdy obstacle\nSlow the approaching swarm","Crew-operated heavy weapon\nE mount / click fire","Repairs nearby defenses\nHeals dwarves and hearth","Iron-plated fortification\n850 health / Hearth tier 2","Chains lightning to 3 targets\nAether / Hearth tier 3","Area frost shells slow crowds\nAether / Hearth tier 3","Scorches every nearby enemy\nClose-range area control / tier 4","Pulls and slows enemies\nCombine with area towers / tier 5","Long-range beam pierces armor\nBoss hunter / Hearth tier 6"]
const BACKPACKS := [{"name":"Trail Pack","wood":16,"stone":0,"crystal":2,"iron":0,"bonus":12},{"name":"Expedition Frame","wood":24,"stone":0,"crystal":4,"iron":12,"bonus":28}]

static func supplies_text(stock:Dictionary,compact:=false)->String:
	var parts:=PackedStringArray()
	for kind in RESOURCES:
		if compact and int(stock.get(kind,0))==0:continue
		parts.append("%d %s"%[int(stock.get(kind,0)),kind])
	return " / ".join(parts) if not parts.is_empty() else "Empty"

static func weapon_title(p:Node)->String:
	var title:String=WEAPONS[p.weapon].name
	if p.weapon=="Crossbow" and "Stormstring" in p.relics:title="Stormstring [RARE]"
	if p.weapon=="Hammer" and "Embermaul" in p.relics:title="Embermaul [RARE]"
	var level:int=p.weapon_levels.get(p.weapon,1)
	return title+(" +%d"%(level-1) if level>1 else "")
const WEAPON_ORDER := ["Axe", "Hammer", "Crossbow", "Pike", "Repeater", "Cleaver", "Warpick", "Greatmaul", "Handcannon", "Longrifle", "Runestaff", "Runeblade"]
const WEAPONS := {
	"Cleaver":{"name":"Ironbark Cleaver","wood":18,"iron":14,"crystal":3,"tier":2,"damage":42.0,"cooldown":.65,"windup":.22,"range":3.3,"targets":6,"desc":"Fast broad sweeps hit up to six enemies.\nA crowd weapon for guarding gateways."},
	"Warpick":{"name":"Breach Pick","wood":12,"iron":24,"crystal":6,"tier":3,"damage":100.0,"cooldown":1.0,"windup":.42,"range":3.1,"targets":1,"desc":"Focused heavy strikes. Breaks shieldguard armor.\nSingle-target damage with a brief stagger."},
	"Greatmaul":{"name":"Mountainfall Maul","wood":24,"stone":32,"iron":32,"aether":8,"tier":4,"damage":110.0,"cooldown":1.6,"windup":.85,"range":4.2,"targets":6,"knockback":4.5,"desc":"Huge sweeping blows launch smaller enemies.\nSlow windup; giants resist displacement."},
	"Handcannon":{"name":"Scattershot Cannon","wood":18,"iron":34,"crystal":8,"aether":10,"tier":4,"damage":72.0,"cooldown":1.65,"windup":.28,"range":18.0,"splash":3.0,"desc":"Impact burst damages enemies in a 3m area.\nReusable shells; aim with right mouse."},
	"Longrifle":{"name":"Farwatch Longrifle","wood":25,"iron":42,"crystal":12,"aether":16,"tier":5,"damage":145.0,"cooldown":1.7,"windup":.3,"range":48.0,"desc":"Slow, powerful long-range precision shots.\nIntercept siege monsters and bosses."},
	"Runestaff":{"name":"Stormcaller Staff","wood":30,"iron":20,"crystal":25,"aether":28,"tier":6,"damage":65.0,"cooldown":1.25,"windup":.25,"range":30.0,"chain":4,"desc":"Lightning leaps to four targets within 6m.\nA magical answer to clustered raiders."},
	"Runeblade":{"name":"Dawnbreaker","wood":28,"iron":48,"crystal":24,"aether":35,"tier":7,"damage":125.0,"cooldown":.85,"windup":.28,"range":4.5,"targets":4,"knockback":1.8,"desc":"Long sweeping rune blade with heavy stagger.\nAlso awarded to the crew for defeating a Colossus."},
	"Pike":{"name":"Ironthorn Pike","wood":16,"stone":0,"crystal":2,"iron":10,"tier":2,"damage":48.0,"cooldown":0.85,"windup":0.23,"range":5.2,"desc":"Long, narrow thrusts pierce up to 3 enemies.\nIron weapon / Hearth tier 2. Keep a little distance."},
	"Repeater":{"name":"Aether Repeater","wood":18,"stone":0,"crystal":6,"iron":16,"aether":6,"tier":3,"damage":34.0,"cooldown":0.42,"windup":0.08,"range":29.0,"desc":"Rapid single bolts for intercepting flying threats.\nHearth tier 3. Hold right mouse to aim; hold left to fire."},
	"Axe":{"name":"Forester's Axe","wood":0,"stone":0,"crystal":0,"damage":32.0,"cooldown":0.75,"windup":0.23,"range":3.0,"desc":"Quick sweeping strikes. Your original gathering tool.\nHits up to 3 enemies. Always available."},
	"Hammer":{"name":"Hearthbreaker","wood":14,"stone":18,"crystal":2,"damage":62.0,"cooldown":1.25,"windup":0.68,"range":3.5,"desc":"A slow, heavy sweep with knockback and a brief stun.\nHits up to 5 enemies. Protect your crew's front line."},
	"Crossbow":{"name":"Trailguard Crossbow","wood":22,"stone":8,"crystal":4,"damage":55.0,"cooldown":1.05,"windup":0.12,"range":24.0,"desc":"Aimed single-target bolts. Reloads between shots.\nReusable ammunition; walls and obstacles block shots."},
}

static func class_data(index:int) -> Dictionary:
	return CLASSES[clampi(index, 0, CLASSES.size() - 1)]

static func ranged(kind:String)->bool:
	return kind in ["Crossbow","Repeater","Handcannon","Longrifle","Runestaff"]

static func defense_radius(kind:String,level:=1)->float:
	var base:float={"Watchtower":17.0,"Ballista":35.0,"Mender":7.0,"StormSpire":22.0,"FrostMortar":28.0,"Embercoil":9.0,"GravityWell":13.0,"Sunlance":42.0}.get(kind,0.0)
	return base+float(level-1)*(1.0 if kind=="Mender" else 2.0) if base>0 else 0.0

static func weapon_upgrade_cost(level:int)->Dictionary:
	return {"iron":8,"crystal":3} if level==1 else {"iron":16+(level-2)*10,"aether":6+(level-2)*5,"crystal":5+(level-2)*3}

static func resource_color(kind:String) -> Color:
	return {"wood":Color("c78245"),"stone":Color("a9b0bb"),"crystal":Color("54d8e8"),"iron":Color("bca07c"),"aether":Color("c191ed")}.get(kind, Color.WHITE)
