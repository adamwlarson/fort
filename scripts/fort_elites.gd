class_name FortElites
extends RefCounted

# Fort 31: elite raiders. From night 8 the raid director spends part of its budget on
# marked champions of ordinary raiders. They cost more than twice the threat, change how a
# wave has to be fought, and pay the crew when they fall.
const KINDS := {
	"Ironhide":{"title":"IRONHIDE","color":Color("#c3d0dc"),"hp":2.6,"speed":.9,"might":1.2,"hint":"Armoured. Soaks tower fire; focus it down."},
	"Frenzied":{"title":"FRENZIED","color":Color("#ff7a4a"),"hp":1.5,"speed":1.45,"might":1.5,"hint":"Fast and hits hard. Stop it before the wall."},
	"Warbanner":{"title":"WARBANNER","color":Color("#e2bd52"),"hp":2.0,"speed":1.0,"might":1.0,"hint":"Raiders near its banner take 30% less damage. Kill it first."},
}
const HOSTS := ["Raider","Brute","EmberRunner","Prowler","Shieldguard"]
const AURA := 9.0
const FIRST_NIGHT := 8

static func chance(night:int,power:float)->float:
	return 0.0 if night<FIRST_NIGHT else clampf(.05+.012*(night-FIRST_NIGHT)+.12*(power-1.0),0.0,.3)

static func cap(night:int,crew:int)->int:
	return crew+1+int(maxi(0,night-FIRST_NIGHT)/5)

static func cost(kind:String)->int:
	return int(int(FortBalance.COST[kind])*2.2)

static func pick(rng:RandomNumberGenerator)->String:
	return KINDS.keys()[rng.randi_range(0,KINDS.size()-1)]

static func title(e:Dictionary)->String:
	return "%s %s"%[KINDS[e.elite].title,str(e.kind).to_upper()] if KINDS.has(e.get("elite","")) else ""

## Marks an elite on every machine: larger, a glowing crest overhead and a ring at its feet.
static func dress(e:Dictionary)->void:
	var spec:Dictionary=KINDS[e.elite]
	e.speed=float(e.speed)*float(spec.speed);e.might=float(spec.might)
	var visual:Node3D=e.visual
	visual.scale*=1.22
	var body:Node3D=e.node
	var glow:=Visuals.material(spec.color,.9,spec.color)
	glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var crest:=MeshInstance3D.new();var prism:=PrismMesh.new();prism.size=Vector3(.34,.4,.34);crest.mesh=prism
	crest.material_override=glow;crest.rotation.x=PI;crest.position.y=3.0 if e.kind=="Brute" else 2.55;crest.name="EliteCrest";body.add_child(crest)
	var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.62;torus.outer_radius=.72;torus.rings=20;torus.ring_segments=4;ring.mesh=torus
	ring.material_override=glow;ring.position.y=.08;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;ring.name="EliteRing";body.add_child(ring)
	if e.elite=="Warbanner":
		# The standard stands behind one shoulder, clear of the face.
		var top:=crest.position.y+1.3
		body.add_child(Visuals.cylinder(.05,top,FortArt.WOOD,Vector3(.8,top*.5,-.55)))
		var flag:=Visuals.box(Vector3(.9,.7,.06),spec.color,Vector3(.8+.5,top-.4,-.55));flag.material_override=glow;body.add_child(flag)
	var label:Label3D=e.label
	label.modulate=spec.color;label.position.y+=.5;label.visibility_range_end=60

## True when a living Warbanner stands close enough to shield this raider.
static func shielded(world:FortWorld,e:Dictionary)->bool:
	if e.get("elite","")=="Warbanner":return false
	for other in world.enemies.values():
		if other.get("elite","")=="Warbanner" and other.hp>0 and other.node.position.distance_to(e.node.position)<AURA:return true
	return false

## Host only: what the crew earns for bringing one down.
static func reward(world:FortWorld,e:Dictionary)->void:
	var at:Vector3=e.node.position+Vector3.UP*1.4
	world.shared.crystal=int(world.shared.get("crystal",0))+2
	world.broadcast("recv_gain",[-1,at,"crystal",2,"ELITE"])
	if world.hearth_level>=4:
		var rare:=world.expedition.rare(world.hearth_level-3)
		var amount:=2 if e.elite=="Ironhide" else 1
		world.shared[rare]=int(world.shared.get(rare,0))+amount
		world.broadcast("recv_gain",[-1,at+Vector3.UP*.5,rare,amount,"ELITE"])
	world.broadcast("recv_fx",[at,KINDS[e.elite].color,"ELITE SLAIN","ability"])
