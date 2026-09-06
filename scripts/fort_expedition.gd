class_name FortExpedition
extends RefCounted

const BIOMES := [
	{"name":"AMBERWOOD","color":Color("#987a38"),"asset":"biome_amberwood","resources":["wood","wood","crystal","iron"]},
	{"name":"MYCELIUM HOLLOW","color":Color("#756293"),"asset":"biome_mycelium","resources":["wood","aether","crystal","aether"]},
	{"name":"CINDER WASTES","color":Color("#805546"),"asset":"biome_cinder","resources":["iron","stone","iron","aether"]},
	{"name":"GLACIER REACH","color":Color("#8eaeb5"),"asset":"biome_glacier","resources":["crystal","iron","crystal","stone"]},
	{"name":"ANCIENT GARDENS","color":Color("#61745c"),"asset":"biome_gardens","resources":["aether","wood","stone","crystal"]},
]
var world:FortWorld
var seed_value:=0
var order:Array[int]=[]
var rng:=RandomNumberGenerator.new()
var event_name:=""
var event_revision:=0
var event_time:=0.0
var event_claimed:=false
var event_node:Node3D
var boss_night:=0
var bosses_defeated:=0
const CACHE_POS:=Vector3(14,0,-14)

func _init(w:FortWorld)->void:
	world=w;rng.randomize();seed_value=rng.randi();configure(seed_value)
func configure(value:int)->void:
	seed_value=value;rng.seed=value;order=[0,1,2,3,4]
	for i in range(4,0,-1):
		var j:=rng.randi_range(0,i);var old:=order[i];order[i]=order[j];order[j]=old
func state()->Dictionary:
	return {"seed":seed_value,"event":event_name,"revision":event_revision,"time":event_time,"claimed":event_claimed,"boss_night":boss_night,"bosses_defeated":bosses_defeated}
func receive(data:Dictionary)->void:
	if data.is_empty():return
	if seed_value!=int(data.seed):configure(int(data.seed))
	if int(data.revision)<event_revision:return
	event_revision=data.revision;event_name=data.event;event_time=data.time;event_claimed=data.claimed
	boss_night=data.boss_night;bosses_defeated=data.bosses_defeated;event_visual()
func biome(level:int)->Dictionary:return BIOMES[order[clampi(level-4,0,4)]]
func region_name(pos:Vector3)->String:
	var distance:=Vector2(pos.x,pos.z).length()
	return FortLandscape.region_name(pos) if distance<=243 else biome(clampi(4+int((distance-243)/80),4,8)).name
func build_ring(parent:Node3D,level:int)->void:
	var spec:=biome(level);var outer:=243.0+(level-3)*80;var inner:=outer-80
	var grove:=Node3D.new();grove.name="BiomeTier%d"%level;parent.add_child(grove)
	var vertices:=PackedVector3Array();var colors:=PackedColorArray();var normals:=PackedVector3Array()
	for i in 128:
		var a:=Vector3(sin(i*TAU/128),0,cos(i*TAU/128));var b:=Vector3(sin((i+1)*TAU/128),0,cos((i+1)*TAU/128))
		for point in [a*inner,a*outer,b*outer,a*inner,b*outer,b*inner]:vertices.append(point+Vector3.UP*.025);colors.append(spec.color);normals.append(Vector3.UP)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_NORMAL]=normals
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var mat:=ShaderMaterial.new();mat.shader=preload("res://assets/shaders/biome_ground.gdshader");mat.set_shader_parameter("soil_color",spec.color)
	var surface:=MeshInstance3D.new();surface.mesh=mesh;surface.material_override=mat;grove.add_child(surface)
	var random:=RandomNumberGenerator.new();random.seed=seed_value+level*91
	for i in 72:
		var angle:float=(i+.5)*TAU/72;var position:=Vector3(sin(angle),0,cos(angle))*random.randf_range(inner+12,outer-12)
		for attempt in 48:
			if not FortEncounters.reserved(position,level,seed_value):break
			position=position.rotated(Vector3.UP,.025)
		var kind:String=spec.resources[i%4];var node:=Node3D.new();node.position=position;world.resource_root.add_child(node)
		var model:=FortArt.asset({"wood":"pine_tree","stone":"stone_outcrop_b","crystal":"crystal_vein","iron":"iron_ore","aether":"aether_geode"}[kind]);node.add_child(model);node.rotation.y=angle
		var animator:=FortPlayer.find_animation(model)
		if animator and animator.has_animation("Idle"):animator.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR;animator.play("Idle")
		if kind=="wood":
			var trunk:=StaticBody3D.new();trunk.name="TreeTrunk";node.add_child(trunk)
			var shape:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new();cylinder.radius=.24;cylinder.height=1.8;shape.shape=cylinder;shape.position.y=.9;trunk.add_child(shape)
		world.resource_nodes[1000+level*100+i]={"kind":kind,"amount":6 if kind in ["crystal","aether"] else 12,"node":node,"animation":animator,"respawn":0.0}
	var transforms:Array[Transform3D]=[]
	for i in 112:
		var angle:=i*TAU/112;var point:=Vector3(sin(angle),0,cos(angle))*random.randf_range(inner+10,outer-10)
		if absf(point.x)<5 or absf(point.z)<5:continue
		if FortEncounters.reserved(point,level,seed_value):continue
		var clear:=true
		for r in world.resource_nodes.values():
			if r.node.position.distance_to(point)<6:clear=false;break
		if clear:transforms.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*random.randf_range(.8,1.4)),point))
	FortLandscape.instance_asset(grove,spec.asset,transforms)
	for pose in transforms:
		var obstacle:=Node3D.new();obstacle.transform=pose;grove.add_child(obstacle)
		world.scenery_keepouts.append({"pos":pose.origin,"radius":4.0})
		if spec.name=="ANCIENT GARDENS":
			for x in [-2,2]:FortArt.box_collider(obstacle,Vector3(.8,4.2,.8),Vector3(x,2.1,0))
			FortArt.box_collider(obstacle,Vector3(5,.5,.9),Vector3(0,4.1,0))
		elif spec.name in ["AMBERWOOD","MYCELIUM HOLLOW"]:
			FortArt.box_collider(obstacle,Vector3(.65,3,.65),Vector3(0,1.5,0))
			FortArt.box_collider(obstacle,Vector3(.6,2,.6),Vector3(-1.8,1,-.5))
			FortArt.box_collider(obstacle,Vector3(.6,2,.6),Vector3(1.6,1,.4))
		else:FortArt.box_collider(obstacle,Vector3(3.8,2.8,3.8),Vector3(0,1.4,0))
	var rubble:Array[Transform3D]=[];var shrubs:Array[Transform3D]=[]
	vertices=PackedVector3Array();colors=PackedColorArray()
	for i in 14000:
		var angle:=random.randf()*TAU;var point:=Vector3(sin(angle),0,cos(angle))*sqrt(random.randf_range(inner*inner,outer*outer))
		if absf(point.x)<3.5 or absf(point.z)<3.5:continue
		if i%45==0:rubble.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*random.randf_range(.18,.65)),point))
		if i%65==0:shrubs.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*random.randf_range(.6,1.6)),point))
		var side:=Vector3(cos(angle),0,sin(angle))*.09;var color:Color=spec.color.lightened(random.randf_range(.05,.25))
		for vertex in [point-side+Vector3.UP*.03,point+Vector3.UP*random.randf_range(.25,.65),point+side+Vector3.UP*.03]:vertices.append(vertex);colors.append(color)
	FortLandscape.instance_asset(grove,"moss_rock",rubble)
	FortLandscape.instance_asset(grove,"fern" if spec.name in ["AMBERWOOD","ANCIENT GARDENS","MYCELIUM HOLLOW"] else "wildflowers",shrubs)
	arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors
	var grass_mesh:=ArrayMesh.new();grass_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var grass:=MeshInstance3D.new();grass.mesh=grass_mesh;var grass_mat:=ShaderMaterial.new();grass_mat.shader=preload("res://assets/shaders/meadow_grass.gdshader");grass.material_override=grass_mat;grove.add_child(grass)
	for i in 4:
		var point:=Vector3(sin(i*PI/2),0,cos(i*PI/2))*(inner+40)
		var label:=Visuals.label_3d(spec.name+" / HEARTH %d"%level,Color("#e2cf9c"),4);label.position+=point;label.visibility_range_end=70;grove.add_child(label)
static func hearth_cost(level:int)->Dictionary:
	if level<=2:return FortFrontier.COSTS[level-1]
	return {"wood":90+(level-2)*35,"stone":70+(level-2)*30,"crystal":18+(level-2)*8,"iron":30+(level-3)*25,"aether":12+(level-3)*12}
func day_start()->void:
	event_revision+=1;event_time=0;event_claimed=false;event_name=""
	if world.wave>0 and rng.randf()<.55:event_name=["Bountiful Dawn","Supply Caravan","Warband Scouts"][rng.randi_range(0,2)]
	if (world.wave+1)%10==0:world.broadcast("recv_notice",["DAY %d / A Colossus approaches tonight. Prepare heavy weapons!"%(world.wave+1)])
	elif not event_name.is_empty():world.broadcast("recv_notice",["DAY EVENT / "+event_name+". "+event_description()])
	event_visual()
func event_description()->String:
	match event_name:
		"Bountiful Dawn":return "Double gathering until dusk. Send your pets out!"
		"Supply Caravan":return "Supplies delivered to the crew." if event_claimed else "E at the golden chest northeast of the hearth for shared supplies."
		"Warband Scouts":return "The warband has arrived. Defend the hearth." if event_claimed else "Warband from the east in %ds. Prepare!"%maxi(0,ceili(30-event_time))
	return ""
func night_start()->void:
	event_name="";event_revision+=1;event_visual()
	if world.wave%10!=0 or boss_night==world.wave:return
	for e in world.enemies.values():
		if e.kind=="Colossus":return
	boss_night=world.wave
	var hp:float=1800.0*[.8,1.25,1.7,2.2][clampi(world.players.size(),1,4)-1]*(1.0+.3*(world.wave/10-1))*(1+.22*(world.hearth_level-1))
	world.broadcast("recv_enemy",[900000+world.wave,"Colossus",Vector3(0,0,maxf(52,world.build_radius()+18)),hp,-10])
	world.broadcast("recv_notice",["NIGHT %d / THE RUNEFORGED COLOSSUS. It will not retreat at dawn!"%world.wave])
func event_visual()->void:
	var visible_cache:=event_name=="Supply Caravan" and not event_claimed
	if visible_cache and not is_instance_valid(event_node):
		event_node=FortArt.asset("treasure_chest");world.add_child(event_node);event_node.position=CACHE_POS
		var label:=Visuals.label_3d("CARAVAN / E FOR SHARED SUPPLIES",Color("#ffdb82"),2);event_node.add_child(label)
	if is_instance_valid(event_node):event_node.visible=visible_cache
func interact(id:int)->bool:
	if event_name!="Supply Caravan" or event_claimed or world.players[id].position.distance_to(CACHE_POS)>3:return false
	event_claimed=true;event_revision+=1
	for resource in GameData.RESOURCES:world.shared[resource]+=12 if resource in ["wood","stone"] else (4 if resource=="crystal" or world.hearth_level>=3 else 0)
	world.broadcast("recv_full",[world.full_state()]);world.broadcast("recv_notice",["Caravan supplies delivered to the shared stockpile."]);event_visual();return true
func gather_multiplier()->int:return 2 if event_name=="Bountiful Dawn" and not world.is_night else 1
func tick(delta:float)->void:
	if world.is_night:return
	event_time+=delta
	if event_name=="Warband Scouts" and not event_claimed and event_time>=30:
		event_claimed=true;event_revision+=1
		for i in 3+world.players.size():world._spawn_enemy("Prowler" if i%3==0 else "Raider",PI/2+i*.035)
		world.broadcast("recv_notice",["WAR BAND / Raiders approaching from the east!"])
func boss_killed()->void:
	bosses_defeated+=1;event_revision+=1
	world.shared.iron+=25;world.shared.aether+=12;world.shared.crystal+=10
	for p in world.players.values():
		if "Runeblade" not in p.owned_weapons:
			var owned:PackedStringArray=p.owned_weapons.duplicate();owned.append("Runeblade")
			world.broadcast("recv_loadout",[p.peer_id,owned,p.weapon,p.loadout_revision+1])
	world.broadcast("recv_notice",["COLOSSUS DEFEATED / Dawnbreaker unlocked for the crew, plus iron, crystal and aether!"])
	world.broadcast("recv_full",[world.full_state()])
func simulate(e:Dictionary,delta:float)->bool:
	if e.kind=="Hexer" and world.clock>=float(e.get("heal_at",0)):
		e.heal_at=world.clock+7
		for ally in world.enemies.values():
			if ally!=e and ally.node.position.distance_to(e.node.position)<8 and ally.hp<ally.max_hp:
				ally.hp=minf(ally.max_hp,ally.hp+22);world.broadcast("recv_fx",[e.node.position+Vector3.UP,Color("#ba9bea"),"","mend",ally.node.position+Vector3.UP])
	if e.kind!="Colossus":return false
	var body:CharacterBody3D=e.node
	var goal:=world.raiders.target(e);var offset:Vector3=goal-body.position;offset.y=0
	if world.clock<float(e.get("slam_at",0)):
		e.moving=false;return true
	if float(e.get("slam_at",0))>0:
		e.slam_at=0;world.raiders.blast(e.get("slam_pos",body.position),6,150);e.attack=4.5
	if offset.length()<5:
		e.moving=false
		if e.attack<=0:
			e.slam_at=world.clock+1.8;e.slam_pos=goal
			world.broadcast("recv_fx",[goal,Color("#ffbd6b"),"","boss_slam"])
	else:
		var direction:=FortSiege.route(world,e,goal);var breach:int=e.get("breach",-1)
		if world.defenses.has(breach) and body.position.distance_to(world.defenses[breach].node.position)<5:
			if e.attack<=0:e.slam_at=world.clock+1.8;e.slam_pos=world.defenses[breach].node.position;world.broadcast("recv_fx",[e.slam_pos,Color("#ffbd6b"),"","boss_slam"])
		else:
			body.velocity=direction*2.5;body.velocity.y=-3;body.move_and_slide();e.moving=true
	if offset.length()>.1:body.rotation.y=lerp_angle(body.rotation.y,atan2(offset.x,offset.z),delta*3)
	return true
