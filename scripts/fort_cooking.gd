class_name FortCooking
extends RefCounted

# Fort 33: the cooking pot. Game from the wild is deposited like any other material, cooked
# at a pot into servings that sit in the shared stockpile, and eaten there to restore
# health and gain a boost that lasts a few minutes.
const REACH := 3.4
const DISHES := {
	"stew":{"name":"Hunter's Stew","needs":{"meat":2,"wood":1},"serves":2,"heal":60.0,"buff":"hearty","seconds":180.0,"text":"+2 health a second"},
	"roast":{"name":"Roast Haunch","needs":{"venison":2,"wood":1},"serves":2,"heal":80.0,"buff":"fleet","seconds":180.0,"text":"+15% movement speed"},
	"broth":{"name":"Glowcap Broth","needs":{"glowcap":1,"meat":1,"wood":1},"serves":2,"heal":50.0,"buff":"glowing","seconds":150.0,"text":"+4 health a second, and you glow in the dark"},
	"skewers":{"name":"Embertail Skewers","needs":{"embertail":1,"meat":1,"wood":1},"serves":2,"heal":50.0,"buff":"fiery","seconds":150.0,"text":"+25% weapon damage"},
	"hotpot":{"name":"Frost Hotpot","needs":{"frostfat":1,"venison":1,"wood":1},"serves":2,"heal":50.0,"buff":"thick","seconds":150.0,"text":"25% less damage taken"},
	"platter":{"name":"Sunhorn Platter","needs":{"sunmeat":1,"venison":1,"wood":1},"serves":2,"heal":50.0,"buff":"bountiful","seconds":180.0,"text":"+1 on every gather, 20% faster gathering"},
}
const BUFF_NAMES := {"hearty":"Hearty","fleet":"Fleet","glowing":"Glowing","fiery":"Fired up","thick":"Thick-skinned","bountiful":"Bountiful"}

## The finished cooking pot a dwarf is standing at, or -1.
static func nearest(world:FortWorld,at:Vector3)->int:
	var best:=-1;var reach:=REACH
	for id in world.defenses:
		var d:Dictionary=world.defenses[id]
		if d.kind!="CookingPot" or FortConstruction.foundation(d):continue
		var distance:float=at.distance_to(d.node.position)
		if distance<reach:best=int(id);reach=distance
	return best

static func has(p:Node,buff:String)->bool:
	return float(p.buffs.get(buff,0.0))>0.0

static func can_cook(world:FortWorld,dish:String)->bool:
	for kind in DISHES[dish].needs:
		if int(world.shared.get(kind,0))<int(DISHES[dish].needs[kind]):return false
	return true

## Host: turn ingredients from the shared stockpile into servings in the shared stockpile.
static func cook(world:FortWorld,id:int,dish:String)->void:
	if not DISHES.has(dish) or not world.players.has(id):return
	var p:FortPlayer=world.players[id];var pot:=nearest(world,p.position)
	if pot<0 or p.health<=0 or not world._allow(id,"cook",.45):return
	if not can_cook(world,dish):world.personal(id,"%s needs %s in the shared stockpile."%[DISHES[dish].name,GameData.supplies_text(DISHES[dish].needs,true)]);return
	for kind in DISHES[dish].needs:world.shared[kind]=int(world.shared[kind])-int(DISHES[dish].needs[kind])
	world.shared[dish]=int(world.shared.get(dish,0))+int(DISHES[dish].serves)
	var at:Vector3=world.defenses[pot].node.position+Vector3.UP*1.2
	world.broadcast("recv_fx",[at,GameData.resource_color(dish),"+%d %s"%[int(DISHES[dish].serves),str(DISHES[dish].name).to_upper()],"cook"])
	world.broadcast("recv_action",[id,"repair"])

## Host: eat one serving at the pot. Heals at once and starts (or renews) the dish's boost.
static func eat(world:FortWorld,id:int,dish:String)->void:
	if not DISHES.has(dish) or not world.players.has(id):return
	var p:FortPlayer=world.players[id]
	if nearest(world,p.position)<0 or p.health<=0 or not world._allow(id,"eat",1.2):return
	if int(world.shared.get(dish,0))<=0:world.personal(id,"No %s is ready. Cook some first."%DISHES[dish].name);return
	world.shared[dish]=int(world.shared[dish])-1
	world._set_health(id,minf(p.max_health,p.health+float(DISHES[dish].heal)))
	p.buffs[DISHES[dish].buff]=float(DISHES[dish].seconds)
	world.broadcast("recv_fx",[p.position+Vector3.UP*1.2,GameData.resource_color(dish),str(BUFF_NAMES[DISHES[dish].buff]).to_upper(),"eat"])
	world.personal(id,"%s: +%d health, then %s for %d seconds."%[DISHES[dish].name,int(DISHES[dish].heal),DISHES[dish].text,int(DISHES[dish].seconds)])

## Host, every frame: boosts run down, and the two healing ones mend their dwarf.
static func tick(world:FortWorld,p:FortPlayer,delta:float)->void:
	for buff in p.buffs.keys():
		p.buffs[buff]=float(p.buffs[buff])-delta
		if float(p.buffs[buff])<=0.0:p.buffs.erase(buff)

static func regeneration(p:Node)->float:
	return (2.0 if has(p,"hearty") else 0.0)+(4.0 if has(p,"glowing") else 0.0)

## Short text for the HUD: "Fleet 2:41  Fired up 1:05".
static func summary(p:Node)->String:
	var parts:=PackedStringArray()
	for buff in p.buffs:
		var left:=int(ceil(float(p.buffs[buff])))
		if left>0:parts.append("%s %d:%02d"%[BUFF_NAMES.get(buff,buff),left/60,left%60])
	return "   ".join(parts)

## The pot itself: an iron cauldron hung from a tripod over a small fire.
static func make_pot(collision:=true)->Node3D:
	var root:=Node3D.new()
	var iron:=Color("#2f3338");var wood:=FortArt.WOOD
	for i in 3:
		var angle:=i*TAU/3.0+.5
		FortArt.beam(root,Vector3(sin(angle)*.85,0,cos(angle)*.85),Vector3(sin(angle)*.06,2.05,cos(angle)*.06),.09,wood)
	root.add_child(Visuals.cylinder(.015,.62,Color("#1c1e21"),Vector3(0,1.62,0)))
	var bowl:=Visuals.sphere(.5,iron,Vector3(0,.86,0));bowl.scale=Vector3(1,.82,1);root.add_child(bowl)
	var rim:=TorusMesh.new();rim.inner_radius=.42;rim.outer_radius=.5;rim.rings=20;rim.ring_segments=6
	root.add_child(Visuals.mesh_node(rim,iron.lightened(.12),Vector3(0,1.14,0)))
	var stew:=Visuals.cylinder(.42,.05,Color("#9a5f2c"),Vector3(0,1.13,0));stew.name="Stew";root.add_child(stew)
	for spot in [Vector3(.14,1.165,.08),Vector3(-.16,1.165,-.05),Vector3(.02,1.165,-.2)]:
		root.add_child(Visuals.sphere(.06,Color("#c98d4a"),spot))
	for i in 7:
		var angle:=i*TAU/7.0
		var stone:=Visuals.sphere(.14,Color("#7d848b").darkened(.08*(i%3)),Vector3(sin(angle)*.62,.07,cos(angle)*.62));stone.scale=Vector3(1,.7,1);root.add_child(stone)
	for i in 3:
		var log_piece:=Visuals.cylinder(.06,.7,Color("#4a3423"),Vector3(0,.1,0));log_piece.rotation=Vector3(PI/2,i*TAU/3.0,0);root.add_child(log_piece)
	var flame:=Visuals.sphere(.2,Color("#ff9a3c"),Vector3(0,.26,0));flame.scale=Vector3(1,1.6,1);flame.name="Flame"
	flame.material_override=Visuals.material(Color("#ffb347"),.6,Color("#ff7a1e"));(flame.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;root.add_child(flame)
	var glow:=OmniLight3D.new();glow.light_color=Color("#ffb066");glow.light_energy=.7;glow.omni_range=6.0;glow.position=Vector3(0,.5,0);glow.name="Glow";root.add_child(glow)
	if DisplayServer.get_name()!="headless":
		var steam:=FortParticles.emitter("Steam",10,1.8,FortParticles.quad(Vector2(.3,.3)))
		steam.position=Vector3(0,1.25,0);steam.spread=18.0;steam.initial_velocity_min=.3;steam.initial_velocity_max=.7;steam.gravity=Vector3(0,.35,0)
		steam.color_ramp=FortParticles.ramp([Color(1,1,1,0),Color(1,1,1,.32),Color(1,1,1,0)]);steam.scale_amount_curve=FortParticles.curve([.5,1.2,1.9]);steam.emitting=true
		root.add_child(steam)
	if collision:FortArt.box_collider(root,Vector3(1.1,1.25,1.1),Vector3(0,.625,0))
	return root
