class_name FortBattlements
extends RefCounted

var world:FortWorld
var range_ring:MeshInstance3D
var range_label:Label3D
var aim_timer:=0.0

func _init(owner_world:FortWorld)->void:world=owner_world

static func aim(d:Dictionary,direction:Vector3)->void:
	if not direction.is_finite() or direction.length_squared()<0.001:return
	d.aim=direction.normalized()
	pose(d)

static func pose(d:Dictionary)->void:
	var pivot:Node3D=d.node.get_node_or_null("Turret")
	if not pivot:return
	var direction:Vector3=d.get("aim",Vector3.FORWARD.rotated(Vector3.UP,d.node.rotation.y))
	pivot.rotation=Vector3(asin(clampf(direction.y,-.85,.85)),atan2(-direction.x,-direction.z)-d.node.rotation.y,0)

func tick(delta:float)->void:
	var p:=world.local_player()
	if not p:return
	aim_timer-=delta
	if p.mounted_ballista>=0 and not world.menu_open and p.health>0 and world.defenses.has(p.mounted_ballista):
		var direction:=p.shot_direction()
		aim(world.defenses[p.mounted_ballista],direction)
		if aim_timer<=0:
			aim_timer=.08;world.request_action("ballista_aim",{"direction":direction})
	var target:Dictionary={}
	if world.local_build_mode and not world.menu_open and is_instance_valid(world.preview) and world.preview.visible:
		target={"kind":world.preview_kind,"node":world.preview,"level":1}
	elif world.hud.upgrade_menu.visible and world.defenses.has(world.hud.upgrade_menu.target):
		target=world.defenses[world.hud.upgrade_menu.target]
	elif not world.menu_open:
		var id:=world._nearest_defense(p.position,"",4)
		if id>=0:target=world.defenses[id]
	var radius:=GameData.defense_radius(target.get("kind",""),int(target.get("level",1)))
	if radius<=0 or p.health<=0 or world.ended:
		if is_instance_valid(range_ring):range_ring.hide();range_label.hide()
		return
	if not is_instance_valid(range_ring):
		range_ring=MeshInstance3D.new();range_ring.name="TowerCoverage"
		var mesh:=TorusMesh.new();mesh.inner_radius=.996;mesh.outer_radius=1.004;mesh.rings=128;mesh.ring_segments=4
		range_ring.mesh=mesh;range_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;world.add_child(range_ring)
		range_label=Visuals.label_3d("",Color.WHITE,.4);range_label.font_size=18;world.add_child(range_label)
	var color:=Color("#79dbac") if target.kind=="Mender" else Color("#d7bd7a")
	if world.local_build_mode and not world.preview_valid:color=Color("#dd785e")
	var mat:=Visuals.material(Color(color,.52));mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	range_ring.material_override=mat;range_ring.position=target.node.position+Vector3.UP*.09;range_ring.scale=Vector3(radius,.25,radius);range_ring.show()
	range_label.text="%s / %dm %s"%[target.kind,radius,"HEALING" if target.kind=="Mender" else "RANGE"]
	range_label.position=target.node.position+Vector3(0,.3,1.5);range_label.modulate=color;range_label.show()

func heal(d:Dictionary,power:float)->void:
	var radius:=GameData.defense_radius(d.kind,int(d.get("level",1)))
	var source:Vector3=d.node.position+Vector3.UP*1.6
	var healed:Array[Vector3]=[]
	if d.node.position.length()<radius and world.fort_health<world.fort_max_health:
		world.director.record("mender_healing",minf(world.fort_max_health-world.fort_health,2*power))
		world.fort_health=minf(world.fort_max_health,world.fort_health+2*power);healed.append(Vector3.UP)
	for other in world.defenses.values():
		if other.node.position.distance_to(d.node.position)<radius and other.hp<other.max_hp:
			world.director.record("mender_healing",minf(other.max_hp-other.hp,3*power))
			other.hp=minf(other.max_hp,other.hp+3*power);healed.append(other.node.position+Vector3.UP)
	for p in world.players.values():
		if p.health>0 and p.health<p.max_health and p.position.distance_to(d.node.position)<radius:
			world.director.record("mender_healing",minf(p.max_health-p.health,2*power))
			p.health=minf(p.max_health,p.health+2*power);healed.append(p.position+Vector3.UP)
	# No idle particles or text spam; up to four target ribbons per healing pulse.
	for i in mini(4,healed.size()):world.broadcast("recv_fx",[source,Color("#7ee9b7"),"","mend",healed[i]])

static func mend_fx(parent:Node3D,source:Vector3,end:Vector3)->void:
	for i in 3:
		var mote:=Visuals.box(Vector3.ONE*.1,Color("#92ffd0"),source);parent.add_child(mote)
		var tween:=parent.create_tween();tween.tween_interval(i*.1);tween.tween_property(mote,"position",end,.5)
		tween.tween_property(mote,"scale",Vector3.ONE*.01,.12);tween.tween_callback(mote.queue_free)
	var halo:=Visuals.cylinder(.25,.025,Color("#75cfa8"),end-Vector3.UP*.7);parent.add_child(halo)
	var fade:=parent.create_tween();fade.tween_property(halo,"scale",Vector3.ONE*.01,.7);fade.tween_callback(halo.queue_free)
