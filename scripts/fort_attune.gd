class_name FortAttune
extends RefCounted

# Fort 31: hearth attunements. Each outer biome yields one material found nowhere else.
# Fed to the hearth, it grants the whole crew a permanent boon in three ranks, so every
# biome opened is something new to want. Ranks live in the expedition state.
const MAX_RANK := 3
const BOONS := {
	"resin":{"name":"Sealed Timber","each":"+25% repair, walls take 8% less damage"},
	"spore":{"name":"Glowspore Salve","each":"dwarves regenerate 1 health a second"},
	"cinder":{"name":"Cinderite Shot","each":"+8% tower damage"},
	"frost":{"name":"Frostglass Ward","each":"the hearth takes 12% less damage"},
	"bloom":{"name":"Sunbloom Harvest","each":"25% chance of +1 on every gather"},
}

static func rank(world:FortWorld,kind:String)->int:
	return int(world.expedition.attune.get(kind,0)) if world.expedition else 0

static func cost(kind:String,next_rank:int)->Dictionary:
	return {kind:[6,12,20][clampi(next_rank-1,0,2)],"aether":[4,8,14][clampi(next_rank-1,0,2)]}

## Host: spend the materials and raise one boon by a rank.
static func request(world:FortWorld,id:int,kind:String,expected:int)->void:
	if not BOONS.has(kind) or not world.players.has(id) or world.is_night:return
	var p:FortPlayer=world.players[id]
	if p.position.length()>5.0 or rank(world,kind)!=expected or expected>=MAX_RANK or not world._allow(id,"attune",.5):return
	if not world.expedition.has_rare(kind):world.personal(id,"This material comes from a biome the hearth has not reached yet.");return
	var price:=cost(kind,expected+1)
	for resource in price:
		if int(world.shared.get(resource,0))<int(price[resource]):world.personal(id,"%s needs %s in the shared stockpile."%[BOONS[kind].name,GameData.supplies_text(price,true)]);return
	for resource in price:world.shared[resource]=int(world.shared[resource])-int(price[resource])
	world.expedition.attune[kind]=expected+1
	world.broadcast("recv_fx",[Vector3(0,1.4,0),GameData.resource_color(kind),"%s %s"%[str(BOONS[kind].name).to_upper(),"I".repeat(expected+1)],"ability"])
	world.broadcast("recv_notice",["%s attuned the hearth: %s rank %d. %s."%[p.display_name,BOONS[kind].name,expected+1,str(BOONS[kind].each).capitalize()]])
	world.broadcast("recv_full",[world.full_state()])

static func repair_multiplier(world:FortWorld)->float:return 1.0+.25*rank(world,"resin")
static func wall_multiplier(world:FortWorld)->float:return 1.0-.08*rank(world,"resin")
static func tower_multiplier(world:FortWorld)->float:return 1.0+.08*rank(world,"cinder")
static func hearth_multiplier(world:FortWorld)->float:return 1.0-.12*rank(world,"frost")
static func gather_chance(world:FortWorld)->float:return .25*rank(world,"bloom")
static func regeneration(world:FortWorld)->float:return 1.0*rank(world,"spore")
