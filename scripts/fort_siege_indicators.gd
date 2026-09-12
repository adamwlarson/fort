class_name FortSiegeIndicators
extends Control
## Read-only, locally ranked tactical information. No gameplay authority or extra rays.
const AMBER := Color("#efbd73")
const RED := Color("#ff8d77")
const TEAL := Color("#99d7c7")
const SPECIALS := {"Sapper":"BOMBER", "Bombwing":"BOMB FLYER", "Cinderlobber":"ARTILLERY", "Brute":"HEAVY", "Colossus":"BOSS", "EmberRunner":"HEARTH RUSHER"}
var world:FortWorld
var refresh_timer:=0.0
var threats:Array[Dictionary]=[]
var repairs:Array[Dictionary]=[]
var fronts:=[0,0,0,0]
var forecast:Array[int]=[]
var previous_hp:Dictionary={}
var last_hit:Dictionary={}
var fort_previous:=-1.0
var fort_hit_until:=0.0
var damaged_count:=0
var drawn_markers:=0
var marker_rects:Array[Rect2]=[]
var frame_style:StyleBoxFlat

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame_style=FortInterface.frame()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func sector(pos:Vector3)->int:
	return posmod(roundi(atan2(pos.x,pos.z)/(PI/2)),4)

func _process(delta:float)->void:
	refresh_timer-=delta
	if refresh_timer<=0:refresh_timer=.2;refresh()
	var p:=world.local_player()
	visible=p!=null and p.health>0 and not world.menu_open and not world.local_build_mode and not world.ended
	queue_redraw()

func refresh()->void:
	threats.clear();repairs.clear();fronts=[0,0,0,0];forecast.clear();damaged_count=0
	var p:=world.local_player()
	if not p:return
	var now:=Time.get_ticks_msec()*.001
	if fort_previous>=0 and world.fort_health<fort_previous:fort_hit_until=now+4
	fort_previous=world.fort_health
	if world.is_night and world.director.active:forecast=world.director.lanes()
	for id in previous_hp.keys():
		if not world.defenses.has(id):previous_hp.erase(id);last_hit.erase(id)
	for id in world.defenses:
		var d:Dictionary=world.defenses[id]
		if float(previous_hp.get(id,d.hp))>float(d.hp):last_hit[id]=now+4
		previous_hp[id]=d.hp
		if d.hp<=0 or d.hp>=d.max_hp or FortConstruction.pending(d):continue
		damaged_count+=1
		var fraction:float=clampf(d.hp/d.max_hp,0,1)
		var hit:bool=float(last_hit.get(id,0))>now
		var pos:Vector3=d.node.position
		repairs.append({"id":id,"pos":pos,"name":d.kind,"fraction":fraction,"hit":hit,"score":fraction-(1.0 if hit else 0.0),"distance":p.position.distance_to(pos)})
	repairs.sort_custom(func(a:Dictionary,b:Dictionary):return a.score<b.score if a.score!=b.score else a.id<b.id)
	if repairs.size()>2:repairs.resize(2)
	if world.fort_health<world.fort_max_health:
		repairs.push_front({"id":-1,"pos":Vector3(0,FortCastle.BASE,0),"name":"HEARTH","fraction":world.fort_health/world.fort_max_health,"hit":fort_hit_until>now,"distance":p.position.length()})
		if repairs.size()>2:repairs.resize(2)
	for id in world.enemies:
		var e:Dictionary=world.enemies[id]
		if e.hp<=0:continue
		var pos:Vector3=e.node.position
		var wild:bool=int(e.get("camp",-1))>=0 or FortEncounters.is_wild(int(e.get("camp",-1)))
		if not wild:fronts[sector(pos)]+=1
		if not SPECIALS.has(e.kind):continue
		var distance:=p.position.distance_to(pos)
		if distance>65 and (wild or Vector2(pos.x,pos.z).length()>world.build_radius()+25):continue
		if wild and distance>35:continue
		var armed:bool=float(e.get("fuse_at",0))>0 or bool(e.get("warning_armed",false))
		var priority:=0 if armed else (1 if e.kind in ["Sapper","Bombwing","Colossus"] else 2)
		threats.append({"id":id,"name":"LIT FUSE!" if armed else SPECIALS[e.kind],"pos":pos,"distance":distance,"priority":priority,"armed":armed})
	threats.sort_custom(func(a:Dictionary,b:Dictionary):return a.priority<b.priority if a.priority!=b.priority else (a.distance<b.distance if a.distance!=b.distance else a.id<b.id))
	if threats.size()>3:threats.resize(3)

func text_at(pos:Vector2,value:String,color:Color=FortInterface.PAPER,font_size:=13)->void:
	draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func has_alerts()->bool:
	return not forecast.is_empty() or fronts.max()>0 or not repairs.is_empty() or not threats.is_empty()

func reserves(rect:Rect2)->bool:
	if not visible or not has_alerts():return false
	if rect.intersects(Rect2(20,190,325,244)):return true
	for other in marker_rects:
		if rect.intersects(other):return true
	return false

func _draw()->void:
	drawn_markers=0;marker_rects.clear()
	var p:=world.local_player()
	if not p or not visible:return
	if not has_alerts():return
	draw_style_box(frame_style,Rect2(20,190,325,244))
	text_at(Vector2(34,214),"SIEGE WATCH",AMBER,16)
	text_at(Vector2(34,233),"Directions from hearth / numbers = live raiders",FortInterface.MUTED,11)
	# Fixed compass order: north, east, south, west; never camera-relative.
	for i in 4:
		var lane:int=[2,1,0,3][i]
		var active:bool=lane in forecast
		var box:=Rect2(34+i*76,243,70,34)
		draw_rect(box,Color("#35423b") if active else Color("#15282b"))
		if active:draw_line(box.position,box.position+Vector2(70,0),AMBER,2)
		text_at(box.position+Vector2(7,22),"%s  %d"%[FortBalance.FRONT_NAMES[lane].left(1),fronts[lane]],AMBER if active else FortInterface.MUTED,16)
	text_at(Vector2(34,293),"Gold edge = expected attack front",FortInterface.MUTED,11)
	text_at(Vector2(34,316),"FORT CONDITION",TEAL,12)
	if repairs.is_empty():text_at(Vector2(34,338),"No repairs needed",FortInterface.MUTED)
	for i in repairs.size():
		var r:Dictionary=repairs[i]
		var color:Color=RED if r.hit or r.fraction<=.35 else AMBER
		var heading:String="HEARTH" if r.id==-1 else FortBalance.FRONT_NAMES[sector(r.pos)]
		text_at(Vector2(34,338+i*29),"%s / %s %d%%"%[heading,str(r.name).to_snake_case().capitalize() if r.id!=-1 else "core",ceili(r.fraction*100)],color)
		text_at(Vector2(34,350+i*29),"%s / %dm away"%["UNDER ATTACK" if r.hit else ("CRITICAL / repair" if r.fraction<=.35 else "Needs repair"),r.distance],FortInterface.MUTED,11)
	text_at(Vector2(34,407),"%d damaged defenses / hold R nearby to repair"%damaged_count,FortInterface.MUTED,11)
	text_at(Vector2(34,422),"Priority markers: bombers, heavies and siege threats",FortInterface.MUTED,11)
	for t in threats:
		if not world.enemies.has(t.id):continue
		var e:Dictionary=world.enemies[t.id]
		marker(p,e.label.global_position+Vector3.UP*.7,t.name,RED if t.armed else AMBER)
	if not repairs.is_empty():
		var r:Dictionary=repairs[0]
		if r.hit or r.fraction<=.35:marker(p,r.pos+Vector3.UP*3,"REPAIR",TEAL)

func marker(p:FortPlayer,point:Vector3,title:String,color:Color)->void:
	var camera:=p.camera
	var bounds:=Rect2(385,194,490,312)
	var center:=bounds.get_center()
	var behind:=camera.is_position_behind(point)
	var projected:=camera.unproject_position(point) if not behind else center
	var offscreen:=behind or not bounds.has_point(projected)
	var direction:Vector2
	if behind:
		var local:=camera.global_transform.affine_inverse()*point
		direction=Vector2(local.x,-local.y)
		if direction.length()<.01:direction=Vector2.DOWN
	else:direction=projected-center
	direction=direction.normalized()
	if offscreen:
		var half:=bounds.size*.5
		var extent:=minf(half.x/maxf(absf(direction.x),.001),half.y/maxf(absf(direction.y),.001))
		projected=center+direction*extent
	if offscreen:
		var side:=direction.orthogonal()*5
		draw_colored_polygon(PackedVector2Array([projected+direction*10,projected-direction*3+side,projected-direction*3-side]),color)
	else:draw_arc(projected,6,0,TAU,16,color,2,true)
	var caption:="%s %dm%s"%[title,p.position.distance_to(point)," / BEHIND" if behind else ""]
	var width:=ThemeDB.fallback_font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+12
	var rect:=Rect2(projected+Vector2(-width*.5,13),Vector2(width,20))
	# Keep captions clear of the side HUD and action prompt. Spread clustered labels.
	rect.position.x=clampf(rect.position.x,350,965-width)
	for offset in [0,-30,30,-60,60,-90,90,-120,120]:
		var candidate:=Rect2(Vector2(rect.position.x,clampf(projected.y+13+offset,207,522)),rect.size)
		var clear:=true
		for other in marker_rects:
			if other.intersects(candidate.grow(3)):clear=false;break
		if clear:rect=candidate;break
	if rect.position.distance_to(projected+Vector2(-width*.5,13))>8:
		draw_line(projected,rect.get_center(),Color(color,.45),1,true)
	marker_rects.append(rect.grow(3))
	draw_rect(rect,Color(.035,.065,.07,.93))
	text_at(rect.position+Vector2(6,14),caption,color,12)
	drawn_markers+=1
