class_name FortProgression
extends RefCounted

const SITES := [
	{"name":"Fern Hollow Cache","pos":Vector3(-49,0,15),"tier":1,"guards":false,"reward":"Supplies"},
	{"name":"Redfang Camp","pos":Vector3(46,0,15),"tier":1,"guards":true,"reward":"Embermaul"},
	{"name":"Rustscar Stronghold","pos":Vector3(112,0,-18),"tier":2,"guards":true,"reward":"Ironheart"},
	{"name":"Elderwood Cache","pos":Vector3(-115,0,-24),"tier":2,"guards":false,"reward":"Supplies"},
	{"name":"Stormglass Sanctum","pos":Vector3(-35,0,-207),"tier":3,"guards":true,"reward":"Stormstring"},
	{"name":"Frostvein Cache","pos":Vector3(45,0,210),"tier":3,"guards":false,"reward":"Supplies"},
	{"name":"Bramblewick Village","pos":Vector3(-56,0,-12),"tier":1,"guards":true,"reward":"Supplies","village":true},
	{"name":"Coppercross Hamlet","pos":Vector3(102,0,65),"tier":2,"guards":true,"reward":"Supplies","village":true},
	{"name":"Starfall Refuge","pos":Vector3(-153,0,-119),"tier":3,"guards":true,"reward":"Supplies","village":true},
]
var world:FortWorld
var sites:Dictionary={}
var unlocked:PackedStringArray=[]
var shells:Array[Dictionary]=[]

func _init(owner_world:FortWorld)->void:world=owner_world

func unlock_zones(level:int)->void:
	for i in SITES.size():
		var spec:Dictionary=SITES[i]
		if spec.tier>level or sites.has(i):continue
		var node:=Node3D.new();node.name="TreasureSite%d"%i;node.position=spec.pos;world.add_child(node)
		var chest:=FortArt.asset("treasure_chest");node.add_child(chest)
		FortArt.box_collider(node,Vector3(1.3,.8,.8),Vector3(0,.4,0))
		if spec.get("village",false):FortVillages.build(node,int(spec.tier))
		elif spec.guards:
			for side in [-1,1]:
				var tent:=FortLandscape.place(node,"camp_tent",Vector3(side*4,0,3),side*.3,1.2)
				FortArt.box_collider(tent,Vector3(2,1.4,2),Vector3(0,.7,0))
			FortLandscape.place(node,"supply_crate",Vector3(-3,0,-2),0,0.85)
			FortLandscape.place(node,"ruin_arch",Vector3(0,0,5),0,0.8)
		else:
			FortLandscape.place(node,"moss_rock",Vector3(-1.8,0,0),1.3,1.5)
			FortLandscape.place(node,"fern",Vector3(1.2,0,1.0),0,1.8)
		var label:=Visuals.label_3d(spec.name,Color("#e8ca87"),1.7);label.font_size=18;node.add_child(label)
		label.visibility_range_end=24
		sites[i]={"node":node,"chest":chest,"label":label,"active":false,"opened":false}
		world.scenery_keepouts.append({"pos":spec.pos,"radius":13.0 if spec.get("village",false) else 6.0})

func tick()->void:
	for shell in shells.duplicate():
		if world.clock<shell.at:continue
		shells.erase(shell)
		for enemy_id in world.enemies.keys():
			var enemy:Dictionary=world.enemies[enemy_id]
			if enemy.node.position.distance_to(shell.pos)<4.8:
				enemy.slow=3.5;world._damage_enemy(enemy_id,shell.damage,Vector3.ZERO,"tower_damage")
	for id in sites:
		var site:Dictionary=sites[id]
		var near:=false
		for p in world.players.values():
			if p.health>0 and p.position.distance_to(SITES[id].pos)<24:near=true;break
		if near and not site.active and SITES[id].guards:_activate(id)

func _activate(id:int)->void:
	var site:Dictionary=sites[id]
	if site.active:return
	site.active=true
	var encounter:=FortBalance.camp(int(SITES[id].tier),world.players.size())
	site["encounter_crew"]=encounter.crew
	for i in int(encounter.escorts)+1:
		var boss:bool=i==int(encounter.escorts)
		var kind:="Chieftain" if boss else "Raider"
		var pos:Vector3=SITES[id].pos+Vector3((i-float(encounter.escorts)*.5)*2.3,0,-4)
		world.broadcast("recv_enemy",[100000+id*10+i,kind,pos,float(encounter.boss_hp if boss else encounter.guard_hp),id])
	world.broadcast("recv_notice",["%s discovered. Defeat its guards to unlock the chest."%SITES[id].name])

func guarded(id:int)->bool:
	for e in world.enemies.values():
		if int(e.get("camp",-1))==id:return true
	return false

func nearest(pos:Vector3)->int:
	for id in sites:
		if pos.distance_to(SITES[id].pos)<3:return int(id)
	return -1

func interact(player_id:int)->bool:
	var p:FortPlayer=world.players[player_id]
	var id:=nearest(p.position)
	if id<0:return false
	var site:Dictionary=sites[id]
	if site.opened:world.personal(player_id,"This chest has already been claimed by the crew.");return true
	if SITES[id].guards and not site.active:_activate(id)
	if guarded(id):world.personal(player_id,"Defeat the camp guards before opening this chest.");return true
	if int(world.shared.get("crystal",0))<2:world.personal(player_id,"The lock needs 2 crystals from the shared stockpile.");return true
	world.shared.crystal-=2
	site.opened=true
	var reward:String=SITES[id].reward
	var received:Dictionary={};var new_items:Array=[]
	if reward=="Supplies":
		for kind in ["wood","stone","crystal"]:world.shared[kind]=int(world.shared.get(kind,0))+8
		for kind in ["wood","stone","crystal"]:received[kind]=8
		if SITES[id].tier>=2:world.shared.iron=int(world.shared.get("iron",0))+8
		if SITES[id].tier>=3:world.shared.aether=int(world.shared.get("aether",0))+6
		if SITES[id].tier>=2:received.iron=8
		if SITES[id].tier>=3:received.aether=6
	else:
		if reward not in unlocked:unlocked.append(reward);new_items.append(reward)
		for dwarf in world.players.values():grant_loot(dwarf)
	world.broadcast("recv_full",[world.full_state()])
	world.broadcast("recv_notice",["%s unlocked %s for the WHOLE CREW!"%[p.display_name,reward]])
	world.broadcast("recv_fx",[SITES[id].pos+Vector3.UP,Color("#d0a2f0"),reward,"ability"])
	world.broadcast("recv_loot",[SITES[id].name,received,new_items,{"crystal":2}])
	return true

func grant_loot(p:FortPlayer)->void:
	var items:=p.relics.duplicate()
	for reward in unlocked:
		if reward not in items:items.append(reward)
	var has_armor:bool="Ironheart" in items
	var fresh_armor:bool=has_armor and not p.armor
	p.apply_progression(p.backpack_level,items,has_armor,p.progression_revision+1)
	if fresh_armor and p.health>0:p.health=minf(p.max_health,p.health+40)
	for pair in [["Embermaul","Hammer"],["Stormstring","Crossbow"]]:
		if pair[0] in items and pair[1] not in p.owned_weapons:
			p.owned_weapons.append(pair[1]);world.broadcast("recv_loadout",[p.peer_id,p.owned_weapons,pair[1],p.loadout_revision+1])

func state()->Dictionary:
	var opened:Array=[];var active:Array=[]
	for id in sites:
		if sites[id].opened:opened.append(id)
		if sites[id].active:active.append(id)
	return {"opened":opened,"active":active,"unlocked":unlocked}

func receive(state:Dictionary)->void:
	for item in state.get("unlocked",[]):
		if item not in unlocked:unlocked.append(item)
	for id in state.get("active",[]):
		if sites.has(id):sites[id].active=true
	for id in state.get("opened",[]):
		if not sites.has(id):continue
		sites[id].opened=true
		var lid:Node3D=sites[id].chest.find_child("Lid*",true,false)
		if lid:lid.rotation.x=-1.2
		sites[id].label.text="CLAIMED / "+SITES[id].name

func craft_pack(id:int,expected:int)->void:
	var p:FortPlayer=world.players[id]
	if p.backpack_level!=expected or expected>=2 or expected<0 or p.position.distance_to(Vector3(-4.6,0,0))>3.2:return
	if expected==1 and world.hearth_level<2:world.personal(id,"Upgrade the hearth to reach iron first.");return
	var cost:Dictionary=GameData.BACKPACKS[expected]
	for kind in GameData.RESOURCES:
		if int(world.shared.get(kind,0))<int(cost.get(kind,0)):return
	for kind in GameData.RESOURCES:world.shared[kind]=int(world.shared.get(kind,0))-int(cost.get(kind,0))
	p.apply_progression(expected+1,p.relics,p.armor,p.progression_revision+1)
	world.broadcast("recv_full",[world.full_state()])
	world.personal(id,"Crafted %s. Pack capacity: %d."%[cost.name,p.carry_limit])

func upgrade_cost(id:int)->Dictionary:
	if not world.defenses.has(id):return {}
	var level:int=world.defenses[id].get("level",1)
	return {"wood":12,"stone":10,"iron":8,"aether":0} if level==1 else {"wood":12+(level-2)*6,"stone":16+(level-2)*8,"iron":16+(level-2)*10,"aether":5+(level-2)*5}

func upgrade_defense(player_id:int,id:int,expected:int)->void:
	if not world.defenses.has(id):return
	var d:Dictionary=world.defenses[id];var p:FortPlayer=world.players[player_id]
	if d.temporary or d.get("level",1)!=expected or expected>=GameData.MAX_GEAR_LEVEL or p.position.distance_to(d.node.position)>4:return
	if FortConstruction.pending(d):return
	if world.hearth_level<expected+1:world.personal(player_id,"Upgrade your hearth before reinforcing this defense.");return
	var cost:=upgrade_cost(id)
	for kind in cost:
		if int(world.shared.get(kind,0))<cost[kind]:world.personal(player_id,"More shared supplies needed for this upgrade.");return
	for kind in cost:world.shared[kind]=int(world.shared.get(kind,0))-cost[kind]
	world.construction.begin(id,player_id,cost,"upgrade")
	world.personal(player_id,"Upgrade reserved. Hold E beside the structure; anyone can help.")

func defense_visual(d:Dictionary)->void:
	if d.kind=="Gatehouse":FortGates.pose(d);return
	var level:int=d.get("level",1)
	if int(d.get("visual_level",1))==level:return
	d.visual_level=level
	for i in range(2,level+1):
		if d.node.has_node("Tier%d"%i):continue
		if i>3:
			var rank:=Visuals.label_3d("✦ "+str(i),Color("#ffd58a"),3.1+(i-4)*.25);rank.name="Tier%d"%i;rank.font_size=16;d.node.add_child(rank);continue
		var trim:=FortArt.asset("upgrade_iron" if i==2 else "upgrade_aether")
		trim.name="Tier%d"%i
		if FortPlacement.is_wall(d.kind):trim.scale=Vector3(1.5,.8,.3)
		elif d.kind=="Watchtower":
			trim.scale.y=1.3
			if i==3:trim.position.y=1.25
		d.node.add_child(trim)

func tick_advanced(d:Dictionary)->void:
	if world.clock<float(d.get("next_shot",0.0)):return
	var radius:=GameData.defense_radius(d.kind,int(d.get("level",1)))
	var target_id:=world._nearest_enemy(d.node.position,radius)
	if target_id<0:return
	var level:int=d.get("level",1)
	var factor:=1.0+(level-1)*0.4
	var target:Vector3=world.enemies[target_id].node.position
	d.next_shot=world.clock+(1.6 if d.kind=="StormSpire" else 3.2)
	var origin:Vector3=d.node.position+Vector3.UP*2.4
	if d.kind=="StormSpire":
		var hit:Array=[];var source:=origin
		for bounce in 3:
			var next:=-1;var distance:float=radius if bounce==0 else 6.0
			for id in world.enemies:
				if id in hit:continue
				var pos:Vector3=world.enemies[id].node.position+Vector3.UP
				if source.distance_to(pos)<distance:next=id;distance=source.distance_to(pos)
			if next<0:break
			var end:Vector3=world.enemies[next].node.position+Vector3.UP
			hit.append(next);world.broadcast("recv_fx",[source,Color("#c496f3"),"","arc",end])
			world._damage_enemy(next,(44-bounce*9)*factor,Vector3.ZERO,"tower_damage");source=end
	else:
		world.broadcast("recv_fx",[origin,Color("#a6e6ed"),"","frost_shell",target])
		shells.append({"at":world.clock+.6,"pos":target,"damage":38*factor})
