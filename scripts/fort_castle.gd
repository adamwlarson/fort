class_name FortCastle
extends RefCounted

const CELL:=20.0
const BASE:=.6
const HEIGHT:=5.0
const TYPES:={
	"Courtyard":{"name":"Open courtyard","cost":{"wood":30,"stone":55},"work":20,"tier":1,"desc":"Open floor for your own defenses. Expands the castle grid."},
	"Stairs":{"name":"Grand stairwell","cost":{"wood":35,"stone":75},"work":26,"tier":1,"desc":"Walkable stairs to the next storey. Finish four ground wings to build upward."},
	"Rampart":{"name":"Defensive terrace","cost":{"wood":65,"stone":90},"work":30,"tier":1,"desc":"A working watchtower plus space for crew-built defenses."},
	"Merchant":{"name":"Merchant hall","cost":{"wood":65,"stone":65,"crystal":8},"work":28,"tier":2,"desc":"Visit the tent to sell resources for shared gold and buy supplies. Rotating daily sale."},
	"Sentry":{"name":"Sentry room","cost":{"wood":75,"stone":100,"iron":25},"work":32,"tier":2,"desc":"Stackable gun room. Build outward-facing cannons at its sign; window walls keep firing ports open."},
	"Gatherers":{"name":"Gatherers' lodge","cost":{"wood":80,"stone":50,"crystal":10},"work":28,"tier":2,"desc":"Assign a resource. Workers harvest actual nearby nodes by day and deliver shared supplies."},
	"Research":{"name":"Rune research hall","cost":{"wood":60,"stone":90,"crystal":16,"iron":15},"work":34,"tier":3,"desc":"Fund and hand-build crew research: stronger towers, faster construction, bigger packs."},
}
const TECH:={"Masonry":{"cost":{"stone":60,"iron":15},"desc":"+15% crew construction work"},"Ballistics":{"cost":{"wood":60,"iron":25,"crystal":10},"desc":"+15% tower damage"},"Logistics":{"cost":{"wood":50,"crystal":15},"desc":"+6 carrying capacity for every dwarf"}}
var world:FortWorld
var rooms:Dictionary={}
var revision:=0
var root:Node3D
var visuals:Dictionary={}
var menu:FortCastleMenu
var research:PackedStringArray=[]
var next_tick:=0.0
var cleared_scenery:Dictionary={}
var perimeter:Dictionary={}
var razed:Dictionary={}

func _init(w:FortWorld)->void:
	world=w;root=Node3D.new();root.name="CastleWings";world.add_child(root)
	rooms["0:0:0"]={"x":0,"z":0,"floor":0,"kind":"Keep","complete":true,"funded":{},"work":0.0,"total":0.0,"sign":Vector3(0,BASE,7),"walls":[],"task":"","resource":"wood"}
	menu=FortCastleMenu.new();menu.castle=self;world.add_child(menu)
static func key(x:int,z:int,floor:int)->String:return "%d:%d:%d"%[x,z,floor]
static func position(r:Dictionary)->Vector3:return Vector3(int(r.x)*CELL,BASE+int(r.floor)*HEIGHT,int(r.z)*CELL)
func state()->Dictionary:return {"revision":revision,"rooms":rooms.duplicate(true),"research":research.duplicate(),"cleared_scenery":cleared_scenery.keys(),"perimeter":perimeter.duplicate(true),"razed":razed.keys()}
func receive(data:Dictionary)->void:
	if data.is_empty() or int(data.revision)<revision:return
	if int(data.revision)==revision and not visuals.is_empty():return
	cleared_scenery.clear()
	for key in data.get("cleared_scenery",[]):cleared_scenery[key]=true
	FortCastleClearance.apply_scenery(self)
	revision=int(data.revision);rooms=data.rooms.duplicate(true);research=PackedStringArray(data.research);rebuild()
	perimeter=data.get("perimeter",{}).duplicate(true)
	for key in data.get("razed",[]):razed[key]=true
	FortRaze.apply(self);FortFarms.rebuild(self)
	refresh_packs()
func changed()->void:
	FortPerimeter.sync(self)
	revision+=1;rebuild();refresh_packs();world.broadcast("recv_castle",[state()])
func refresh_packs()->void:
	for p in world.players.values():p.apply_progression(p.backpack_level,p.relics,p.armor,p.progression_revision)
func completed_ground()->int:
	var count:=0
	for r in rooms.values():
		if r.floor==0 and r.kind!="Keep" and r.complete:count+=1
	return count
func nearest(pos:Vector3)->String:
	var best:="";var distance:=3.8
	for k in rooms:
		var d:float=pos.distance_to(rooms[k].sign)
		if d<distance:best=k;distance=d
	return best
func candidates(from:String)->Array:
	var result:Array=[]
	if not rooms.has(from) or not rooms[from].complete or rooms[from].task!="":return result
	var r:Dictionary=rooms[from]
	for delta in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
		var x:int=r.x+delta.x;var z:int=r.z+delta.y;var k:=key(x,z,r.floor)
		if not rooms.has(k):result.append({"key":k,"x":x,"z":z,"floor":r.floor,"label":["East","West","South","North"][result_direction(delta)]})
	if r.kind=="Stairs" and not rooms.has(key(r.x,r.z,r.floor+1)):
		result.append({"key":key(r.x,r.z,r.floor+1),"x":r.x,"z":r.z,"floor":r.floor+1,"label":"Upstairs"})
	return result
static func result_direction(d:Vector2i)->int:return 0 if d.x>0 else (1 if d.x<0 else (2 if d.y>0 else 3))
func plan_reason(from:String,target:Dictionary,kind:String)->String:
	if not TYPES.has(kind):return "Unknown wing"
	if rooms.size()>=128:return "Castle capacity reached (128 rooms)"
	if world.hearth_level<int(TYPES[kind].tier):return "%s needs Hearth tier %d. Upgrade the hearth with U."%[TYPES[kind].name,TYPES[kind].tier]
	var valid:=false
	for c in candidates(from):
		if c.key==key(int(target.x),int(target.z),int(target.floor)):valid=true
	if not valid:return "Must build rooms from adjacent room's signs"
	if int(target.floor)>=mini(8,world.hearth_level+1):return "The hearth tier is too low for another floor. Upgrade the hearth with U."
	if int(target.floor)>0:
		if int(target.x)==0 and int(target.z)==0:return "The hearth needs open sky. Build upper floors around the keep, never above it."
		if completed_ground()<4:return "Ground wings: %d/4 complete. Finish %d more before building upstairs. The stairwell counts; the starting keep and unfinished blueprints do not. Close K and HOLD E at unfinished signs to build."%[completed_ground(),4-completed_ground()]
		var below:=key(target.x,target.z,target.floor-1)
		if not rooms.has(below) or not rooms[below].complete:return "Finish the supporting room below first: storey %d, grid (%d, %d). Build a ground wing there, then each floor beneath this one."%[int(target.floor),int(target.x),int(target.z)]
	var pos:=position(target)
	if Vector2(pos.x,pos.z).length()+CELL*.71>world.build_radius():return "Too far from the hearth. Upgrade the hearth with U to build further out."
	if target.floor==0:
		for obstacle in world.scenery_keepouts:
			if not obstacle.get("clearable",false) and FortCastleClearance.scenery_overlap(target,obstacle):
				var blocked:=FortRaze.reason(world,obstacle)
				if blocked!="":return blocked
	var clearance:=FortCastleClearance.inspect(self,target)
	if not clearance.defenses.is_empty():
		if world.is_night:return "Defenses are in the way. Build this room in daylight so they can be salvaged."
		for id in clearance.defenses:
			if world._nearest_enemy(world.defenses[id].node.position,12)>=0:return "Enemies are too close to the defenses in the way. Defeat them first."
	return ""
func authorized(id:int,k:String)->bool:
	return world.players.has(id) and rooms.has(k) and world.players[id].health>0 and world.players[id].mounted_ballista<0 and world.players[id].position.distance_to(rooms[k].sign)<4.0
func plan(id:int,from:String,target:Dictionary,kind:String,expected:int,clearance_token:="")->void:
	if expected!=revision or not authorized(id,from) or not target.has_all(["x","z","floor"]):return
	var reason:=plan_reason(from,target,kind)
	if not reason.is_empty():world.personal(id,reason);return
	var clearance:=FortCastleClearance.inspect(self,target)
	if not clearance.defenses.is_empty() and clearance_token!=clearance.token:
		world.personal(id,"Defenses are in the way. Open K again and confirm their removal and refund.");return
	var r:=target.duplicate();var pos:=position(r);var parent_pos:=position(rooms[from]);var upper:bool=r.floor>rooms[from].floor
	r.merge({"kind":kind,"complete":false,"funded":{},"work":0.0,"total":float(TYPES[kind].work),"sign":rooms[from].sign if upper else pos+(parent_pos-pos).normalized()*8,"walls":[],"task":"build","resource":"wood"},true)
	# An upstairs project uses the landing at the lower stair's foot until finished.
	if upper:r.sign=parent_pos+Vector3(4 if int(rooms[from].floor)%2==0 else -4,0,-5)
	rooms[key(r.x,r.z,r.floor)]=r
	FortCastleClearance.apply(self,clearance);FortRaze.raze_under(self,r);changed()
	world.broadcast("recv_full",[world.full_state()])
	if not clearance.defenses.is_empty():world.broadcast("recv_notice",["CASTLE CLEARANCE / %d defenses salvaged · %s returned to shared stock"%[clearance.defenses.size(),GameData.supplies_text(clearance.refund,true)]])
func cost(r:Dictionary)->Dictionary:
	if r.task=="upgrade_room":return FortCastleFeatures.upgrade_cost(r)
	if r.task=="sentry_cannons":return {"wood":40,"iron":32,"stone":20}
	if str(r.task).begins_with("edge:"):return {"wood":15,"stone":25,"iron":4}
	if r.task=="dismantle":return {}
	if r.task=="remodel":return TYPES[r.remodel_kind].cost
	if str(r.task).begins_with("tech:"):return TECH[str(r.task).trim_prefix("tech:")].cost
	if r.task=="walls":return {"wood":40,"stone":100}
	return TYPES[r.kind].cost if r.kind!="Keep" else {}
func remaining(r:Dictionary)->Dictionary:
	var result:Dictionary={}
	for kind in cost(r):result[kind]=maxi(0,int(cost(r)[kind])-int(r.funded.get(kind,0)))
	return result
func needs_supplies(r:Dictionary)->bool:
	for count in remaining(r).values():
		if count>0:return true
	return false
func fund(id:int,k:String,shared_stock:bool,expected:int,use_both:=false)->void:
	if expected!=revision or not authorized(id,k) or rooms[k].task=="":return
	var r:Dictionary=rooms[k];var moved:=0
	var bags:Array[Dictionary]=[world.shared if shared_stock else world.players[id].carrying]
	if use_both:bags.append(world.players[id].carrying if shared_stock else world.shared)
	# Fund one ledger atomically, taking only what is still missing from each source.
	for bag in bags:
		for kind in remaining(r):
			var amount:=mini(int(remaining(r)[kind]),int(bag.get(kind,0)))
			bag[kind]=int(bag.get(kind,0))-amount;r.funded[kind]=int(r.funded.get(kind,0))+amount;moved+=amount
	if moved>0:changed();world.personal(id,"Delivered %d supplies to this project"%moved)
	elif use_both:world.personal(id,"This project still needs "+GameData.supplies_text(remaining(r),true)+". Gather more, then hold E here again.")
	else:world.personal(id,"Nothing to deliver. Gather the listed materials or deposit them at the stockpile first.")
func work(id:int,k:String)->void:
	if not authorized(id,k) or rooms[k].task=="" or not world._allow(id,"castle_work",.65):return
	var r:Dictionary=rooms[k]
	if r.task in ["remodel","dismantle"]:
		var reason:=FortCastleRemodel.reason(self,k,r.get("remodel_kind",""),id)
		if reason!="":world.personal(id,reason);return
	if needs_supplies(r):fund(id,k,true,revision,true);return
	r.work=minf(r.total,r.work+(2 if world.players[id].role_id==2 else 1)*FortBalance.work_multiplier(world.players.size())*work_multiplier())
	FortStats.award(world,id,3)
	world.broadcast("recv_action",[id,"construct",r.sign]);world.broadcast("recv_fx",[r.sign+Vector3.UP,Color("#d9bd81"),"","construction"])
	if r.work>=r.total:
		var blocked:=FortCastleFeatures.completion_reason(self,r)
		if blocked!="":world.personal(id,blocked);return
		if r.task in ["remodel","dismantle"]:FortCastleRemodel.finish(self,k);changed();return
		if FortCastleFeatures.finish(self,r):pass
		elif r.task=="walls":finish_walls(r)
		elif str(r.task).begins_with("tech:"):
			var tech:=str(r.task).trim_prefix("tech:")
			if tech not in research:research.append(tech)
		else:
			r.paid=r.funded.duplicate()
			r.complete=true;r.sign=position(r)+Vector3(-7,0,-7)
			if r.kind=="Rampart":
				world._spawn_defense("Watchtower",position(r)+Vector3(5,0,5),0,false)
				world.defenses[world.next_defense_id-1].paid={"wood":18,"stone":8}
		r.task="";r.funded={};r.work=0;r.total=0
		world.broadcast("recv_notice",["CASTLE / "+("Keep" if r.kind=="Keep" else TYPES[r.kind].name)+" project completed"])
	changed()
func begin_task(id:int,k:String,task:String,expected:int)->void:
	if FortCastleFeatures.begin(self,id,k,task,expected):return
	if expected!=revision or not authorized(id,k) or not rooms[k].complete or rooms[k].task!="":return
	var r:Dictionary=rooms[k]
	if task=="walls":
		for defense_id in r.walls:
			if world.defenses.has(defense_id):world.personal(id,"This room already has walls. Change a side with the Open / Gate / Solid buttons.");return
	elif task.begins_with("tech:"):
		var tech:=task.trim_prefix("tech:")
		if r.kind!="Research" or not TECH.has(tech) or tech in research:return
		for other in rooms.values():
			if other.task==task:return
	else:return
	r.task=task;r.funded={};r.work=0;r.total=24.0;changed()
func cancel(id:int,k:String,expected:int)->void:
	if expected!=revision or not authorized(id,k) or rooms[k].task=="":return
	var r:Dictionary=rooms[k];var unused:=1.0-float(r.work)/maxf(1,r.total)
	for kind in r.funded:world.shared[kind]=int(world.shared.get(kind,0))+floori(int(r.funded[kind])*unused)
	if not r.complete:rooms.erase(k)
	else:r.task="";r.funded={};r.work=0;r.total=0;r.erase("remodel_kind")
	changed()
func finish_walls(r:Dictionary)->void:
	for id in r.walls:world.broadcast("recv_remove_defense",[id,true])
	r.walls=[]
	for side in 4:
		FortCastleFeatures.make_edge(self,r,side)
func trade(id:int,k:String,resource:String,expected:int)->void:
	FortMerchant.trade(world,id,k,resource,false,expected,world.wave)
func assign(id:int,k:String,resource:String,expected:int)->void:
	if expected!=revision or not authorized(id,k) or rooms[k].kind!="Gatherers" or not rooms[k].complete or resource not in GameData.RESOURCES:return
	if resource=="iron" and world.hearth_level<2:return
	if resource=="aether" and world.hearth_level<3:return
	rooms[k].resource=resource;changed()
func tick()->void:
	if perimeter.get("pending",false):
		FortPerimeter.sync(self)
		if not perimeter.get("pending",false):changed()
	if world.is_night or world.clock<next_tick:return
	next_tick=world.clock+12
	FortFarms.tick(self)
	var count:=0
	for r in rooms.values():
		if not FortCastleFeatures.healthy(r):continue
		if r.complete and r.kind=="Courtyard" and FortCastleFeatures.level(r)>1:
			for defense in world.defenses.values():
				if FortCastleFeatures.inside(r,defense.node.position):defense.hp=minf(defense.max_hp,defense.hp+4*(FortCastleFeatures.level(r)-1))
		if not r.complete or r.kind!="Gatherers":continue
		count+=1
		if count>4:continue # Four staffed lodges; additional halls still extend the castle.
		var best:=-1;var distance:=60.0
		for id in world.resource_nodes:
			var resource:Dictionary=world.resource_nodes[id];var d:float=resource.node.position.distance_to(position(r))
			if resource.kind==r.resource and resource.amount>0 and d<distance and FortForestry.pet_can_harvest(resource,world.hearth_level,world.frontier_radius()):best=id;distance=d
		if best<0:continue
		var quota:=2.0*(1.0+.2*(FortCastleFeatures.level(r)-1))+float(r.get("gather_fraction",0))
		var whole:=floori(quota+.00001)
		var resource:Dictionary=world.resource_nodes[best];var amount:=mini(whole,resource.amount);resource.respawn=65
		r.gather_fraction=maxf(0,quota-whole)
		world.shared[r.resource]+=amount;world.broadcast("recv_resource",[best,int(resource.amount)-amount,true])
		world.broadcast("recv_fx",[r.sign+Vector3.UP,GameData.resource_color(r.resource),"","deposit"])
		world.broadcast("recv_gain",[-1,r.sign+Vector3.UP,r.resource,amount,"SHARED STOCK"])
func work_multiplier()->float:
	var bonus:=0.0
	for r in rooms.values():
		if r.complete and FortCastleFeatures.healthy(r) and r.kind=="Research":bonus=maxf(bonus,.05*(FortCastleFeatures.level(r)-1))
	return (1.15 if "Masonry" in research else 1.0)+bonus
func tower_multiplier()->float:return 1.15 if "Ballistics" in research else 1.0
func pack_bonus()->int:
	var bonus:=0
	for r in rooms.values():
		if r.complete and FortCastleFeatures.healthy(r) and r.kind=="Research":bonus=maxi(bonus,2*(FortCastleFeatures.level(r)-1))
	return (6 if "Logistics" in research else 0)+bonus
func floor_at(pos:Vector3)->float:
	var height:=0.0
	for r in rooms.values():
		var p:=position(r)
		if not r.complete or absf(pos.x-p.x)>=10 or absf(pos.z-p.z)>=10 or p.y>pos.y+1.2:continue
		var below:=rooms.get(key(r.x,r.z,r.floor-1),{}) as Dictionary
		var stair_x:=6.0 if int(r.floor)%2==1 else -6.0
		if below.get("kind","")=="Stairs" and absf(pos.x-p.x-stair_x)<2 and pos.z-p.z>-4 and pos.z-p.z<4.6:continue
		height=maxf(height,p.y)
	return height
func placement_reason(pos:Vector3,clearance:=0.0,kind:="",yaw:=0.0)->String:
	for r in rooms.values():
		var p:=position(r)
		if not r.complete and absf(pos.y-p.y)<3 and absf(pos.x-p.x)<10+clearance and absf(pos.z-p.z)<10+clearance:return "Finish or cancel this castle blueprint before placing defenses inside it"
		if r.task in ["remodel","dismantle"] and FortCastleRemodel.inside(r,pos,clearance):return "Finish or cancel this remodeling project before placing defenses"
		if pos.distance_to(r.sign)<1.5:return "Keep the castle signpost clear"
		var stair_x:=6.0 if int(r.floor)%2==0 else -6.0
		if r.kind=="Stairs" and r.complete and absf(pos.y-p.y)<HEIGHT+.2 and absf(pos.x-p.x-stair_x)<2.5+clearance and absf(pos.z-p.z)<6+clearance:return "Keep the stairwell and landings clear"
		if r.complete and absf(pos.y-p.y)<2.8:
			for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
				var entry:Vector3=p+direction*10
				var local:Vector3=pos-entry
				if kind=="Gatehouse" and local.length()<.65 and absf(direction.dot(Vector3.BACK.rotated(Vector3.UP,yaw)))>.99:continue
				if absf(local.dot(direction))<2+clearance and absf(local.dot(Vector3(-direction.z,0,direction.x)))<2+clearance:return "Keep the marked room entrances clear"
	return ""
func blocks_resource(pos:Vector3)->bool:
	for r in rooms.values():
		var p:=position(r)
		if r.floor==0 and absf(pos.x-p.x)<10.8 and absf(pos.z-p.z)<10.8:return true
	return false
func approach(pos:Vector3,goal:Vector3)->Vector3:
	# Ground attackers must approach low platforms by an exposed stair, not an invisible ledge.
	if Vector2(goal.x,goal.z).length()>12:return goal
	for r in rooms.values():
		if not r.complete or r.floor!=0 or r.kind!="Stairs":continue
		var center:=position(r);var stair_x:=center.x+6
		if absf(pos.x-center.x)<10 and absf(pos.z-center.z)<5.5 and (pos.x-stair_x)*(goal.x-stair_x)<0 and absf(pos.x-stair_x)>1.9:
			return Vector3(stair_x+signf(pos.x-stair_x)*3,BASE,center.z-6)
	if pos.y>.4:return goal
	var best:=goal;var score:=INF
	for r in rooms.values():
		if not r.complete or r.floor!=0:continue
		var center:=position(r)
		if Vector2(center.x-pos.x,center.z-pos.z).length()>36:continue
		for delta in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var neighbor:=rooms.get(key(r.x+delta.x,r.z+delta.y,0),{}) as Dictionary
			if neighbor.get("complete",false):continue
			var axis:=Vector3(delta.x,0,delta.y);var entry:=center+axis*11.7;entry.y=0
			var distance:=pos.distance_to(entry)
			if distance<score:score=distance;best=center+axis*8.6 if distance<2.5 else entry
	return best
func travel_goal(pos:Vector3,goal:Vector3)->Vector3:
	# Enter raised ground through an entrance; use actual alternating stair lanes
	# when a target is on another completed storey.
	var level:=maxi(0,floori((pos.y-BASE+.3)/HEIGHT))
	var goal_level:=maxi(0,floori((goal.y-BASE+.3)/HEIGHT))
	if level==goal_level:return approach(pos,goal)
	var ascending:=goal.y>pos.y
	var elevated:=goal if ascending else pos
	var elevated_floor:=goal_level if ascending else level
	var on_castle:=false
	for room in rooms.values():
		var center:=position(room)
		if room.complete and int(room.floor)==elevated_floor and absf(elevated.x-center.x)<10 and absf(elevated.z-center.z)<10:on_castle=true;break
	if not on_castle:return approach(pos,goal)
	var stair_floor:=level if ascending else level-1
	var best:=Vector3.INF;var score:=INF
	for r in rooms.values():
		if not r.complete or r.task!="" or r.kind!="Stairs" or int(r.floor)!=stair_floor:continue
		if not rooms.get(key(r.x,r.z,stair_floor+1),{}).get("complete",false):continue
		var center:=position(r);var lane:=6.0 if stair_floor%2==0 else -6.0
		var foot:=center+Vector3(lane,0,-5.7);var top:=center+Vector3(lane,HEIGHT,5.7)
		var entry:=foot if ascending else top
		var distance:=pos.distance_to(entry)+entry.distance_to(goal)*.25
		if distance>=score:continue
		score=distance;best=entry
		if absf(pos.x-foot.x)<1.4 and pos.z>foot.z-.3 and pos.z<top.z+.8:best=top if ascending else foot
	return best if best.is_finite() else approach(pos,goal)
func rebuild()->void:
	world.navigation_revision+=1
	for k in visuals.keys():
		if not rooms.has(k):visuals[k].queue_free();visuals.erase(k)
	for k in rooms:
		var r:Dictionary=rooms[k];var stamp:=str([r.complete,r.kind,r.task,int(r.work/8),r.walls,r.get("level",1),FortCastleFeatures.healthy(r),rooms.get(key(r.x,r.z,r.floor-1),{}).get("kind","")])
		for id in r.walls:
			if world.defenses.has(id) and world.defenses[id].kind=="MetalWall" and not world.defenses[id].node.has_meta("castle_skin"):
				FortArt.replace_meshes(world.defenses[id].node,"castle_wall");world.defenses[id].node.set_meta("castle_skin",true)
				# Legacy curtains: extend both art and collision to the upper floor.
				world.defenses[id].node.scale=Vector3(1.44,HEIGHT/2.1,1.0)
		if visuals.has(k) and visuals[k].get_meta("stamp","")==stamp:
			FortCastleArt.update_sign(visuals[k],r,self);continue
		if visuals.has(k):root.remove_child(visuals[k]);visuals[k].queue_free()
		var node:=FortCastleArt.room(self,r);node.set_meta("stamp",stamp);root.add_child(node);visuals[k]=node
		FortCastleArt.update_sign(node,r,self)
	FortFarms.rebuild(self)
func prompt(p:FortPlayer)->String:
	var k:=nearest(p.position)
	if k.is_empty():return ""
	var r:Dictionary=rooms[k]
	if r.task!="":return "HOLD E   Deliver supplies (shared stockpile first, then your pack)" if needs_supplies(r) else "HOLD E   Build this project  %d%%      K   Details"%int(100*r.work/maxf(1,r.total))
	return "K   Castle plans: add rooms, walls and upgrades from this sign"
