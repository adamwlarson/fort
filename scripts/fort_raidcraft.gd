class_name FortRaidcraft
extends RefCounted

var world:FortWorld
var projectiles:Array[Dictionary]=[]
var blast_count:=0
var warnings:Array[Dictionary]=[]

func visual_tick()->void:
	for warning in warnings.duplicate():
		if not is_instance_valid(warning.marker):warnings.erase(warning);continue
		if not world.enemies.has(warning.owner):warning.marker.hide();warning.label.hide();warnings.erase(warning);continue
		var point:Vector3=world.enemies[warning.owner].node.position
		warning.marker.position=point+Vector3.UP*.12;warning.label.position=point+Vector3.UP*2.6

func _init(owner_world:FortWorld)->void:world=owner_world

func target(e:Dictionary)->Vector3:
	var nearest:=INF;var goal:=Vector3.ZERO
	for d in world.defenses.values():
		var distance:float=e.node.position.distance_to(d.node.position)
		var score:=distance+(12.0 if FortPlacement.is_wall(d.kind) else 0.0)
		if score<nearest:nearest=score;goal=d.node.position
	return goal

func arm(e:Dictionary)->void:
	if float(e.get("fuse_at",0))>0:return
	e.fuse_at=world.clock+1.6;e.moving=false;e.node.velocity=Vector3.ZERO
	projectiles.append({"at":e.fuse_at,"pos":e.node.position,"radius":4.0,"damage":120.0,"owner":int(e.node.get_meta("enemy_id"))})
	world.broadcast("recv_fx",[e.node.position,Color("#ff693f"),"","fuse",Vector3(int(e.node.get_meta("enemy_id")),0,0)])

func simulate(_id:int,e:Dictionary,delta:float)->bool:
	if e.kind=="Sapper":return float(e.get("fuse_at",0))>0
	if e.kind not in ["Cinderlobber","Bombwing"]:return false
	var body:CharacterBody3D=e.node
	var goal:=target(e)
	var offset:Vector3=goal-body.position;offset.y=0
	var flying:bool=e.kind=="Bombwing"
	var reach:=6.0 if flying else 17.0
	if offset.length()<=reach:
		e.moving=false;body.velocity=Vector3.ZERO
		if e.attack<=0:
			e.attack=6.5 if flying else 4.8
			var duration:=1.2 if flying else .95
			projectiles.append({"at":world.clock+duration,"pos":goal,"radius":3.5 if flying else 2.8,"damage":50.0 if flying else 36.0,"owner":-1})
			world.broadcast("recv_fx",[body.position+Vector3.UP*(.2 if flying else 1.5),Color("#f29557"),"","bomb_drop" if flying else "enemy_shell",goal])
	else:
		var direction:Vector3=offset.normalized() if flying else FortSiege.route(world,e,goal)
		var breach:int=e.get("breach",-1)
		if not flying and world.defenses.has(breach) and body.position.distance_to(world.defenses[breach].node.position)<3:
			# A wall reached while routing is a valid ranged siege target too.
			if e.attack<=0:
				e.attack=4.8
				var point:Vector3=world.defenses[breach].node.position
				projectiles.append({"at":world.clock+.95,"pos":point,"radius":2.8,"damage":36.0,"owner":-1})
				world.broadcast("recv_fx",[body.position+Vector3.UP*1.5,Color("#f29557"),"","enemy_shell",point])
			body.velocity=Vector3.ZERO
		else:body.velocity=direction*(3.3 if flying else 2.25)*(0.45 if e.slow>0 else 1.0);e.moving=true
	if flying:body.velocity.y=(5.8+sin(world.clock*2)*.2-body.position.y)*3
	else:body.velocity.y-=22*delta
	body.move_and_slide()
	if offset.length()>.1:body.rotation.y=lerp_angle(body.rotation.y,atan2(offset.x,offset.z),delta*6)
	return true

func tick()->void:
	for shot in projectiles.duplicate():
		if world.clock<shot.at:continue
		projectiles.erase(shot)
		if int(shot.owner)>=0:
			# Killing an armed Sapper disarms its charge. Stuns do not stop a lit fuse.
			if not world.enemies.has(int(shot.owner)):continue
			shot.pos=world.enemies[int(shot.owner)].node.position
			world.broadcast("recv_enemy_dead",[int(shot.owner)])
		blast(shot.pos,shot.radius,shot.damage)

func blast(pos:Vector3,radius:float,damage:float)->void:
	blast_count+=1
	for id in world.defenses.keys():
		var d:Dictionary=world.defenses[id]
		if d.node.position.distance_to(pos)<radius:world._damage_defense(id,damage)
	for p in world.players.values():
		if p.health>0 and p.position.distance_to(pos)<radius:world._set_health(p.peer_id,p.health-damage*.33)
	if pos.length()<radius:
		world.damage_fort(damage*.7)
		if world.fort_health<=0:world.broadcast("recv_end",[false])
	world.broadcast("recv_fx",[pos,Color("#f7aa57"),"","blast",Vector3(radius,0,0)])

static func fx(parent:FortWorld,pos:Vector3,end:Vector3,kind:String)->void:
	var player:=parent.local_player()
	var audible:=player!=null and player.position.distance_to(pos)<30
	if kind=="blast":
		if audible:parent.sound.play("blast",-13)
		parent._ring(pos,Color("#ffae58"),end.x,.4)
		for i in 12:
			var chip:=Visuals.box(Vector3.ONE*.2,Color("#ef8946"),pos+Vector3.UP*.3);parent.add_child(chip)
			var destination:=pos+Vector3(sin(i*2.4)*end.x,1.0+(i%3)*.6,cos(i*2.4)*end.x)
			var tween:=parent.create_tween().set_parallel();tween.tween_property(chip,"position",destination,.5);tween.tween_property(chip,"scale",Vector3.ONE*.01,.6);tween.chain().tween_callback(chip.queue_free)
		return
	var point:=pos if kind in ["fuse","boss_slam"] else end
	if audible:parent.sound.play("fuse" if kind=="fuse" else "frost_shell",-18)
	var duration:=1.8 if kind=="boss_slam" else (1.6 if kind=="fuse" else (1.2 if kind=="bomb_drop" else .95))
	var radius:=6.0 if kind=="boss_slam" else (4.0 if kind=="fuse" else (3.5 if kind=="bomb_drop" else 2.8))
	var mesh:=TorusMesh.new();mesh.inner_radius=radius-.07;mesh.outer_radius=radius+.07;mesh.rings=48;mesh.ring_segments=4
	var marker:=Visuals.mesh_node(mesh,Color("#fc7048"),point+Vector3.UP*.12);parent.add_child(marker)
	marker.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var warning:=Visuals.label_3d("COLOSSUS SLAM / DODGE" if kind=="boss_slam" else ("LIT FUSE / SHOOT ME" if kind=="fuse" else "INCOMING"),Color("#ffc185"),0)
	warning.position=point+Vector3.UP*(2.6 if kind=="fuse" else .45);warning.font_size=20;parent.add_child(warning)
	var timer:=parent.create_tween();timer.tween_interval(duration);timer.tween_callback(marker.queue_free);timer.tween_callback(warning.queue_free)
	if kind=="fuse" and end.is_finite():parent.raiders.warnings.append({"owner":int(end.x),"marker":marker,"label":warning})
	if kind in ["fuse","boss_slam"]:return
	var bomb:=Visuals.mesh_node(SphereMesh.new(),Color("#d16b3f"),pos);bomb.scale=Vector3.ONE*.35;parent.add_child(bomb)
	var motion:=parent.create_tween();motion.tween_method(func(t:float):
		bomb.position=pos.lerp(point,t)+Vector3.UP*sin(t*PI)*(0.0 if kind=="bomb_drop" else 3.5),0.0,1.0,duration)
	motion.tween_callback(bomb.queue_free)
