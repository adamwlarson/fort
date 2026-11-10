class_name FortFarms
extends RefCounted

# Outer-wall farms. Up to four plots sit just inside the corners of the expanding
# perimeter wall and move outward with it whenever the castle grows. Each plot
# delivers a trickle of one resource to the shared stockpile during the day.
const KINDS := {
	"wood":{"name":"Tree farm","cost":{"wood":40,"stone":30},"yield":3,"tier":3},
	"stone":{"name":"Rock mine","cost":{"wood":50,"stone":20},"yield":3,"tier":3},
	"crystal":{"name":"Crystal garden","cost":{"wood":40,"stone":60,"crystal":10},"yield":1,"tier":3},
	"iron":{"name":"Iron pit","cost":{"wood":60,"stone":60,"iron":12},"yield":2,"tier":4},
}
const MAX_PLOTS := 4

static func plots(c:FortCastle)->Array:
	return c.perimeter.get("farms",[])

static func position(c:FortCastle,index:int)->Vector3:
	var box:Vector4i=c.perimeter.get("bounds",Vector4i(0,0,0,0))
	if box.x>900:box=FortPerimeter.bounds(c)
	var left:=float(box.x*20-50)+9.0;var right:=float(box.y*20+50)-9.0
	var north:=float(box.z*20-50)+9.0;var south:=float(box.w*20+50)-9.0
	return [Vector3(right,0,south),Vector3(left,0,south),Vector3(left,0,north),Vector3(right,0,north)][index%4]

static func build(c:FortCastle,id:int,k:String,kind:String,expected:int)->void:
	if expected!=c.revision or k!="0:0:0" or not c.authorized(id,k) or not KINDS.has(kind):return
	var w:=c.world
	if not c.perimeter.get("enabled",false):w.personal(id,"Build the outer wall first. Farms sit inside its corners.");return
	if w.is_night:w.personal(id,"Farms can only be founded during the day.");return
	if w.hearth_level<int(KINDS[kind].tier):w.personal(id,"%s needs Hearth tier %d."%[KINDS[kind].name,KINDS[kind].tier]);return
	var list:Array=plots(c).duplicate()
	if list.size()>=MAX_PLOTS:w.personal(id,"All four farm plots are in use.");return
	var price:Dictionary=KINDS[kind].cost
	for resource in price:
		if int(w.shared.get(resource,0))<int(price[resource]):w.personal(id,"%s needs %s in the shared stockpile."%[KINDS[kind].name,FortGlyphs.cost(price)]);return
	for resource in price:w.shared[resource]=int(w.shared[resource])-int(price[resource])
	list.append(kind);c.perimeter.farms=list
	w.broadcast("recv_notice",["%s founded inside the outer wall. It delivers %d%s to the stockpile every 12 seconds of daylight."%[KINDS[kind].name,KINDS[kind].yield,FortGlyphs.g(kind)]])
	FortStats.award(w,id,25)
	c.changed()

## Host: daytime deliveries, called from the castle tick.
static func tick(c:FortCastle)->void:
	var list:=plots(c)
	for i in list.size():
		var kind:String=list[i];var amount:int=KINDS[kind].yield
		c.world.shared[kind]=int(c.world.shared.get(kind,0))+amount
		c.world.broadcast("recv_gain",[-1,position(c,i)+Vector3.UP*1.5,kind,amount,"FARM"])

## Everyone: rebuild the plot models from replicated perimeter state.
static func rebuild(c:FortCastle)->void:
	var stamp:=str([plots(c),c.perimeter.get("bounds")])
	var old:=c.root.get_node_or_null("PerimeterFarms")
	if old and old.get_meta("stamp","")==stamp:return
	if old:c.root.remove_child(old);old.queue_free()
	var root:=Node3D.new();root.name="PerimeterFarms";root.set_meta("stamp",stamp);c.root.add_child(root)
	var list:=plots(c)
	for i in list.size():
		var plot:=Node3D.new();plot.position=position(c,i);root.add_child(plot)
		var kind:String=list[i]
		# Fenced plot with a signpost.
		for side in 4:
			var rail:=Node3D.new();rail.rotation.y=side*PI/2;plot.add_child(rail)
			for x in [-5.0,-2.5,0.0,2.5,5.0]:rail.add_child(Visuals.box(Vector3(.16,1.0,.16),FortArt.WOOD,Vector3(x,.5,5)))
			rail.add_child(Visuals.box(Vector3(10,.1,.08),FortArt.WOOD.lightened(.1),Vector3(0,.8,5)))
			rail.add_child(Visuals.box(Vector3(10,.1,.08),FortArt.WOOD.lightened(.1),Vector3(0,.45,5)))
		plot.add_child(Visuals.box(Vector3(9.6,.06,9.6),Color("#4b3a2a") if kind=="wood" else Color("#5c5a56"),Vector3(0,.03,0)))
		var spots:=[Vector3(-2.6,0,-2.6),Vector3(2.6,0,-2.6),Vector3(-2.6,0,2.6),Vector3(2.6,0,2.6),Vector3(0,0,0)]
		for j in spots.size():
			var key:=""
			match kind:
				"wood":key=["pine_tree","birch_tree","elder_oak"][j%3]
				"stone":key=["stone_outcrop_a","stone_outcrop_b","stone_outcrop_c"][j%3]
				"crystal":key="crystal_vein"
				"iron":key="iron_ore"
			var model:=FortArt.asset(key)
			if not model:continue
			plot.add_child(model);model.position=spots[j];model.rotation.y=j*1.7
			model.scale=Vector3.ONE*(0.55 if kind=="wood" else 0.7)
			var animation:=FortPlayer.find_animation(model)
			if animation and animation.has_animation("Idle"):animation.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR;animation.play("Idle");animation.seek(j*.4)
		if kind in ["stone","iron"]:
			var portal:=FortArt.asset("mine_portal")
			if portal:plot.add_child(portal);portal.position=Vector3(0,0,-3.6);portal.scale=Vector3.ONE*.7
		var label:=Visuals.label_3d("%s\n+%d%s / 12s by day"%[str(KINDS[kind].name).to_upper(),KINDS[kind].yield,FortGlyphs.g(kind)],Color("#e7d39a"),3.0)
		label.font_size=26;label.pixel_size=.006;plot.add_child(label)
