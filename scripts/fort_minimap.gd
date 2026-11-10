class_name FortMinimap
extends Control
## Fixed-scale local navigation. Siege Watch owns global assault information.
# M cycles: standard -> bigger -> biggest -> whole explored world -> closed.
const MODES:=[{"radius":62.0,"range":90.0,"name":"MAP"},{"radius":104.0,"range":170.0,"name":"WIDE MAP"},{"radius":160.0,"range":300.0,"name":"REGION MAP"},{"radius":300.0,"range":0.0,"name":"WORLD MAP"},{"radius":0.0,"range":0.0,"name":"MAP OFF"}]
var mode:=0
var RADIUS:=62.0
var RANGE:=90.0
var PANEL:=Rect2(-66,-66,132,132)
var world:FortWorld
var resources_enabled:=false
var refresh_time:=0.0
var origin:=Vector2.ZERO
var resources:Array[Dictionary]=[]
var threats:Array[Dictionary]=[]
var sites:Array[Vector2]=[]
var crew:Array[Dictionary]=[]
var rooms:Array[Rect2]=[]
var hearth_point:=Vector2.ZERO
var hearth_outside:=false
var marker_bounds:Array[Rect2]=[]
var frame_style:StyleBoxFlat

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame_style=FortInterface.frame()

func _unhandled_input(event:InputEvent)->void:
	if world.menu_open or world.local_build_mode or world.ended:return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_M or event.keycode==KEY_M):
		set_mode((mode+1)%MODES.size());get_viewport().set_input_as_handled()

func set_mode(value:int)->void:
	mode=clampi(value,0,MODES.size()-1)
	RADIUS=maxf(1.0,float(MODES[mode].radius))
	RANGE=float(MODES[mode].range) if float(MODES[mode].range)>0 else world.frontier_radius()+8.0
	# Bigger maps also show resource patches; the standard one stays clean.
	resources_enabled=mode in [1,2,3]
	PANEL=Rect2(-RADIUS-5,-RADIUS-5,RADIUS*2+10,RADIUS*2+10)
	position=Vector2(640,366) if mode==3 else Vector2(1280-RADIUS-12,RADIUS+14)
	refresh_time=0
	if world.hud and mode==4:world.show_toast("Map hidden. Press M to show it again.",2.0)

func footprint_bottom()->float:
	return 8.0 if mode>=3 else RADIUS*2+22

func _process(delta:float)->void:
	if position==Vector2.ZERO:set_mode(mode)
	if mode==3:RANGE=world.frontier_radius()+8.0
	visible=mode!=4 and world.local_player()!=null and not world.menu_open and not world.local_build_mode and not world.ended
	refresh_time-=delta
	if visible and refresh_time<=0:refresh_time=.2;refresh();queue_redraw()

func point(pos:Vector3)->Vector2:
	return (Vector2(pos.x,pos.z)-origin)*(RADIUS/RANGE)

func inside(pos:Vector2,margin:=7.0)->bool:return pos.length()<=RADIUS-margin

func reserve(pos:Vector2,radius:float)->bool:
	var rect:=Rect2(pos-Vector2.ONE*radius,Vector2.ONE*radius*2)
	for other in marker_bounds:
		if rect.intersects(other):return false
	marker_bounds.append(rect);return true

func refresh()->void:
	resources.clear();threats.clear();sites.clear();crew.clear();rooms.clear();marker_bounds.clear()
	var p:=world.local_player()
	if not p:return
	origin=Vector2.ZERO if mode==3 else Vector2(p.position.x,p.position.z)
	hearth_point=point(Vector3.ZERO);hearth_outside=not inside(hearth_point,12)
	if hearth_outside:hearth_point=hearth_point.normalized()*(RADIUS-12)
	elif hearth_point.length()<18:hearth_point=hearth_point.normalized()*18 if hearth_point.length()>.01 else Vector2(0,18)
	reserve(Vector2.ZERO,9);reserve(hearth_point,9)
	for other in world.players.values():
		if other==p:continue
		var pos:=point(other.position)
		var outside:=not inside(pos,12)
		if outside:pos=pos.normalized()*(RADIUS-12)
		# Separate crew from home and each other, including dwarves sharing a spawn.
		var chosen:=pos
		var placed:=false
		for offset in [Vector2.ZERO,Vector2(15,0),Vector2(-15,0),Vector2(0,15),Vector2(0,-15),Vector2(15,15),Vector2(-15,-15),Vector2(0,30),Vector2(0,-30)]:
			var candidate:Vector2=(pos+offset).limit_length(RADIUS-12)
			if reserve(candidate,6):chosen=candidate;placed=true;break
		if not placed:
			for radius in [22.0,38.0,54.0,68.0]:
				for slot in 16:
					var candidate:Vector2=(pos+Vector2.from_angle(slot*TAU/16)*radius).limit_length(RADIUS-12)
					if reserve(candidate,6):chosen=candidate;placed=true;break
				if placed:break
		crew.append({"pos":chosen,"class_id":other.class_id,"down":other.health<=0,"outside":outside})
	var groups:Dictionary={}
	for e in world.enemies.values():
		if e.hp<=0:continue
		var pos:=point(e.node.position)
		if not inside(pos):continue
		# No global enemy radar: guards appear only within 35m of the local dwarf.
		var guard:bool=int(e.get("camp",-1))>=0 or FortEncounters.is_wild(int(e.get("camp",-1)))
		if guard and pos.length()>35*RADIUS/RANGE:continue
		var sector:=posmod(roundi(pos.angle()/(TAU/8)),8)
		if not groups.has(sector):groups[sector]={"pos":pos,"count":0}
		groups[sector].count+=1
		if pos.length_squared()<groups[sector].pos.length_squared():groups[sector].pos=pos
	for group in groups.values():
		var pos:Vector2=group.pos
		var angle:=pos.angle()
		var placed:=false
		# Threats may be nudged to readable slots, never dropped underneath the crew.
		for radius in [clampf(pos.length(),22,68),38.0,54.0,68.0]:
			for turn in [0.0,-.22,.22,-.44,.44]:
				var candidate:Vector2=Vector2.from_angle(angle+turn)*radius
				if reserve(candidate,7):group.pos=candidate;threats.append(group);placed=true;break
			if placed:break
	var nearby:Array[Vector2]=[]
	for site in world.encounters.sites.values():
		if not site.seen or site.phase=="claimed":continue
		var pos:=point(site.spec.pos)
		if inside(pos):nearby.append(pos)
	nearby.sort_custom(func(a:Vector2,b:Vector2):return a.length_squared()<b.length_squared())
	for pos in nearby:
		if reserve(pos,6):sites.append(pos)
		if sites.size()>=4:break
	if world.castle:
		for room in world.castle.rooms.values():
			if int(room.floor)!=0 or not room.complete:continue
			var pos:=point(Vector3(room.x*FortCastle.CELL,0,room.z*FortCastle.CELL))
			var half:=FortCastle.CELL*RADIUS/RANGE*.5
			if pos.length()+half*sqrt(2)>RADIUS-3:continue
			rooms.append(Rect2(pos-Vector2.ONE*half,Vector2.ONE*half*2))
			if rooms.size()>=64:break
	if not resources_enabled:return
	var patches:Dictionary={}
	for r in world.resource_nodes.values():
		if r.amount<=0:continue
		var pos:=point(r.node.position)
		if not inside(pos):continue
		var cell:=Vector2i(floori(pos.x/18),floori(pos.y/18))
		# One representative per patch, preferring rarer materials over common timber.
		var rank:int=GameData.RESOURCES.find(r.kind)
		if not patches.has(cell) or rank>int(patches[cell].rank):patches[cell]={"pos":pos,"kind":r.kind,"rank":rank}
	var sorted:Array=patches.values()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary):return a.pos.length_squared()<b.pos.length_squared())
	for patch in sorted:
		if reserve(patch.pos,7):resources.append(patch)
		if resources.size()>=(10 if mode==0 else 60):break

func reserves(rect:Rect2)->bool:return visible and rect.intersects(Rect2(position+PANEL.position,PANEL.size))

func caption(pos:Vector2,value:String,color:Color=FortInterface.MUTED,font_size:=11)->void:
	draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func diamond(pos:Vector2,color:Color,extent:=4.0)->void:
	draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-extent),pos+Vector2(extent,0),pos+Vector2(0,extent),pos+Vector2(-extent,0)]),color)

func _draw()->void:
	var p:=world.local_player()
	if not p:return
	draw_style_box(frame_style,PANEL)
	draw_circle(Vector2.ZERO,RADIUS,Color(0.063,0.137,0.153,0.9 if mode<3 else 0.94))
	draw_arc(Vector2.ZERO,RADIUS,0,TAU,64,Color("#748b83"),1.2,true)
	caption(Vector2(-4,-RADIUS+15),"N",FortInterface.PAPER,11)
	draw_line(Vector2(0,-RADIUS),Vector2(0,-RADIUS+5),FortInterface.PAPER,2)
	for rect in rooms:
		draw_rect(rect,Color("#293c3b"));draw_rect(rect,Color("#40534b"),false,1)
	for patch in resources:draw_circle(patch.pos,2.6,GameData.resource_color(patch.kind).darkened(.15))
	for pos in sites:diamond(pos,FortInterface.GOLD)
	for group in threats:
		var radius:=3.0 if group.count==1 else 4.5
		draw_circle(group.pos,radius,Color("#ef9681"))
		if group.count>1:draw_arc(group.pos,radius+2,0,TAU,16,Color("#ad7064"),1,true)
	if hearth_outside:
		var dir:=hearth_point.normalized();var side:=dir.orthogonal()*4
		draw_colored_polygon(PackedVector2Array([hearth_point+dir*7,hearth_point-dir*3+side,hearth_point-dir*3-side]),FortInterface.GOLD)
	else:
		draw_rect(Rect2(hearth_point-Vector2(4,4),Vector2(8,8)),FortInterface.GOLD)
		draw_rect(Rect2(hearth_point-Vector2(2,2),Vector2(4,4)),Color("#102327"))
	for member in crew:
		var color:Color=Color("#ff9c87") if member.down else GameData.class_data(member.class_id).color.lightened(.35)
		draw_circle(member.pos,6,Color("#102327"))
		draw_arc(member.pos,6,0,TAU,16,color,1,true)
		caption(member.pos+Vector2(-3,4),"+" if member.down else str(member.class_id+1),color,11)
		if member.outside:draw_arc(member.pos,8,0,TAU,16,color.darkened(.25),1,true)
	# The bright arrow is always you; its nose follows your camera heading.
	var here:=point(p.position) if mode==3 else Vector2.ZERO
	var forward:=Vector2(-sin(p.look_yaw),-cos(p.look_yaw));var side:=forward.orthogonal()
	draw_circle(here,8,Color("#102327"))
	draw_colored_polygon(PackedVector2Array([here+forward*7,here-forward*5+side*4,here,here-forward*5-side*4]),Color("#f6f1e1"))
	caption(Vector2(-RADIUS+2,RADIUS+3),"[M] %s  %dm"%[MODES[mode].name,int(RANGE)],FortInterface.MUTED,10)
	if mode==3:
		for ring in [73.0,153.0,243.0]:
			if ring<RANGE:draw_arc(Vector2.ZERO,ring*RADIUS/RANGE,0,TAU,64,Color("#3e5a58"),1,true)
		caption(Vector2(-RADIUS+2,-RADIUS-6),"WHOLE EXPLORED WORLD  ·  gold: home and sites  ·  red: enemies  ·  dots: resources",FortInterface.PAPER,11)
