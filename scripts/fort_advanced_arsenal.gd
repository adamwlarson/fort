class_name FortAdvancedArsenal
extends RefCounted
static func tick_tower(w:FortWorld,d:Dictionary)->void:
	if w.clock<float(d.get("next_shot",0)):return
	var radius:=GameData.defense_radius(d.kind,d.level);var origin:Vector3=d.node.position+Vector3.UP*2
	var nearest:=w._nearest_enemy(d.node.position,radius)
	if nearest<0:return
	var power:float=1.0+(int(d.level)-1)*.4
	d.next_shot=w.clock+(3.0 if d.kind=="GravityWell" else (2.6 if d.kind=="Sunlance" else 1.8))
	if d.kind=="Sunlance":
		var end:Vector3=w.enemies[nearest].node.position+Vector3.UP;FortBattlements.aim(d,end-origin)
		w.broadcast("recv_fx",[origin,Color("#fff0a0"),"","arc",end]);w._damage_enemy(nearest,150*power,Vector3.ZERO,"tower_damage",true)
	else:
		w.broadcast("recv_fx",[d.node.position,Color("#c89cf7") if d.kind=="GravityWell" else Color("#ffab63"),"","hammer"])
		for id in w.enemies.keys():
			var e:Dictionary=w.enemies[id];var offset:Vector3=d.node.position-e.node.position
			if offset.length()>radius:continue
			if d.kind=="GravityWell":e.slow=maxf(e.slow,3.0)
			w._damage_enemy(id,(14 if d.kind=="GravityWell" else 48)*power,offset.normalized()*1.6 if d.kind=="GravityWell" else Vector3.ZERO,"tower_damage")
static func ranged_effect(w:FortWorld,p:FortPlayer,kind:String,shot:Dictionary)->void:
	var data:Dictionary=GameData.WEAPONS[kind];var power:=p.weapon_power(kind)
	if data.has("splash"):
		w.broadcast("recv_fx",[shot.point,Color("#ffbc7c"),"","blast",Vector3(data.splash,0,0)])
		for id in w.enemies.keys():
			if id==shot.enemy:continue
			var e:Dictionary=w.enemies[id]
			if e.node.position.distance_to(shot.point)<float(data.splash) and FortSiege.clear(w,shot.point,e.node.position):w._damage_enemy(id,float(data.damage)*.65*power)
	if data.has("chain") and shot.enemy>=0:
		var hit:Array=[shot.enemy];var source:Vector3=shot.point
		for bounce in int(data.chain)-1:
			var next:=-1;var distance:=6.0
			for id in w.enemies:
				if id in hit:continue
				var e:Dictionary=w.enemies[id]
				if e.node.position.distance_to(source)<distance and FortSiege.clear(w,source,e.node.position):next=id;distance=e.node.position.distance_to(source)
			if next<0:break
			var end:Vector3=w.enemies[next].node.position+Vector3.UP;hit.append(next)
			w.broadcast("recv_fx",[source,Color("#bb9bff"),"","arc",end]);w._damage_enemy(next,float(data.damage)*pow(.8,bounce+1)*power);source=end
