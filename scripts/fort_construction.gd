class_name FortConstruction
extends RefCounted
var world:FortWorld
var range_ring:MeshInstance3D
func _init(w:FortWorld)->void:world=w
static func pending(d:Dictionary)->bool:return float(d.get("work_total",0))>0
static func foundation(d:Dictionary)->bool:return pending(d) and d.get("work_kind","")=="build"
static func fraction(d:Dictionary)->float:return clampf(float(d.get("work",0))/maxf(1,float(d.get("work_total",1))),0,1)
static func state(d:Dictionary)->Dictionary:
	var result:Dictionary={}
	for key in ["work","work_total","work_kind","work_cost","work_owner","work_revision","paid"]:
		result[key]=d.get(key,{ } if key in ["work_cost","paid"] else ("" if key=="work_kind" else 0))
	return result
func begin(id:int,owner_id:int,cost:Dictionary,kind:String)->void:
	var d:Dictionary=world.defenses[id]
	d.merge({"work":0.0,"work_total":6.0 if d.kind in ["Barricade","MetalWall"] else 10.0,"work_kind":kind,"work_cost":cost.duplicate(),"work_owner":owner_id,"work_revision":int(d.get("work_revision",0))+1},true)
	if kind=="upgrade":d.work_total=8.0
	else:d.max_hp=float(GameData.RECIPES[d.kind].hp)*.3;d.hp=d.max_hp
	world.broadcast("recv_full",[world.full_state()])
func nearest(p:FortPlayer)->int:
	var nearest_id:=-1;var distance:=3.8
	for id in world.defenses:
		var d:Dictionary=world.defenses[id]
		if pending(d) and p.position.distance_to(d.node.position)<distance:
			nearest_id=id;distance=p.position.distance_to(d.node.position)
	return nearest_id
func work(player_id:int,id:int)->void:
	if not world.defenses.has(id):return
	var d:Dictionary=world.defenses[id];var p:FortPlayer=world.players[player_id]
	if not pending(d) or p.health<=0 or p.mounted_ballista>=0 or p.position.distance_to(d.node.position)>3.8 or not world._allow(player_id,"construction",.65):return
	d.work=minf(d.work_total,d.work+(2.0 if p.class_id==2 else 1.0)*FortBalance.work_multiplier(world.players.size()));d.work_revision+=1
	visual(d)
	world.broadcast("recv_action",[player_id,"construct",d.node.position])
	world.broadcast("recv_fx",[d.node.position+Vector3.UP*.65,Color("#dcc296"),"","construction"])
	if d.work>=d.work_total:
		if not d.has("paid"):d.paid={}
		for resource in d.work_cost:d.paid[resource]=int(d.paid.get(resource,0))+int(d.work_cost[resource])
		var missing:float=d.max_hp-d.hp
		if d.work_kind=="upgrade":d.level+=1
		d.max_hp=float(GameData.RECIPES[d.kind].hp)*(1+.65*(int(d.level)-1));d.hp=maxf(1,d.max_hp-missing)
		d.work_total=0.0;d.work_kind="";d.work_cost={}
		world.broadcast("recv_full",[world.full_state()])
		world.broadcast("recv_fx",[d.node.position+Vector3.UP,Color("#a8dabd"),"READY / "+d.kind,"build"])
func refund(d:Dictionary)->Dictionary:
	var result:Dictionary={}
	for resource in d.get("work_cost",{}):result[resource]=floori(int(d.work_cost[resource])*(1-fraction(d)))
	return result
func salvage_refund(d:Dictionary)->Dictionary:
	var result:Dictionary={}
	for resource in d.get("paid",{}):result[resource]=floori(int(d.paid[resource])*.5*clampf(d.hp/d.max_hp,0,1))
	return result
func salvage(player_id:int,id:int,revision:int)->void:
	if not world.defenses.has(id):return
	var d:Dictionary=world.defenses[id];var p:FortPlayer=world.players[player_id]
	if world.is_night or pending(d) or d.temporary or int(d.get("work_revision",0))!=revision or p.health<=0 or p.position.distance_to(d.node.position)>4:return
	for ally in world.players.values():
		if ally.mounted_ballista==id:world.personal(player_id,"Dismount the ballista before salvaging it.");return
	if world._nearest_enemy(d.node.position,12)>=0:world.personal(player_id,"Clear nearby enemies before salvaging.");return
	var returned:=salvage_refund(d)
	for resource in returned:world.shared[resource]+=int(returned[resource])
	world.broadcast("recv_remove_defense",[id,true]);world.broadcast("recv_full",[world.full_state()])
	world.personal(player_id,"Building salvaged. Returned "+GameData.supplies_text(returned,true))
func cancel(player_id:int,id:int,revision:int)->void:
	if not world.defenses.has(id):return
	var d:Dictionary=world.defenses[id];var p:FortPlayer=world.players[player_id]
	if not pending(d) or int(d.work_revision)!=revision or p.position.distance_to(d.node.position)>4 or player_id not in [1,int(d.work_owner)]:return
	var returned:=refund(d)
	for resource in returned:world.shared[resource]=int(world.shared.get(resource,0))+returned[resource]
	if foundation(d):world.broadcast("recv_remove_defense",[id,true])
	else:d.work_total=0.0;d.work_kind="";d.work_cost={};d.work_revision+=1
	world.broadcast("recv_full",[world.full_state()])
	world.personal(player_id,"Project cancelled. Returned "+GameData.supplies_text(returned,true))
func visual(d:Dictionary)->void:
	var stage:=-1 if not pending(d) else (3 if not foundation(d) else mini(2,int(fraction(d)*3)))
	if int(d.get("work_visual_stage",-2))==stage:return
	d.work_visual_stage=stage
	var previous:Node=d.node.get_node_or_null("Worksite")
	if previous:d.node.remove_child(previous);previous.queue_free()
	for child in d.node.get_children():
		if child is Node3D and child.name!="Status":child.visible=not foundation(d)
	for shape in d.node.find_children("*","CollisionShape3D",true,false):shape.set_deferred("disabled",foundation(d))
	if stage<0:return
	var site:=Node3D.new();site.name="Worksite";d.node.add_child(site)
	var width:=FortPlacement.wall_width(d.kind) if FortPlacement.is_wall(d.kind) else 2.4
	site.add_child(Visuals.box(Vector3(width,.18,1.5),Color("#8d806c"),Vector3(0,.09,0)))
	if foundation(d):FortArt.box_collider(site,Vector3(width,.8,.7),Vector3(0,.4,0))
	if stage>=1:
		var scaffold:=FortArt.asset("construction_scaffold")
		if scaffold:site.add_child(scaffold);scaffold.scale.x=width/2.8
	if stage==2:
		var partial:=FortArt.make_defense(d.kind,false);partial.scale.y=.55;site.add_child(partial)
	if stage==0:
		for x in [-1,1]:site.add_child(Visuals.box(Vector3(.1,1,.1),Color("#eac585"),Vector3(x*width*.5,.5,.5)))
func draw_range()->void:
	if not is_instance_valid(range_ring):
		var mesh:=TorusMesh.new();mesh.inner_radius=.998;mesh.outer_radius=1.002;mesh.rings=160;mesh.ring_segments=4
		range_ring=Visuals.mesh_node(mesh,Color("#d9c388"));world.add_child(range_ring);range_ring.position.y=.07
		(range_ring.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	range_ring.visible=world.local_build_mode and not world.menu_open
	range_ring.scale=Vector3(world.build_radius(),.12,world.build_radius())
