class_name FortCastlePlanner
extends PanelContainer

var menu:FortCastleMenu
var floors:OptionButton
var map:Control
var caption:Label
var support:Button
var cells:Dictionary={}
var regions:Dictionary={}
var floor_index:=0
var selected:=""
var required:=""
var marker:Label3D
var zoom:=1.0
var pan:=Vector2.ZERO
const COLORS:={"finished":Color("#486e69"),"project":Color("#9a743d"),"ready":Color("#397b51"),"locked":Color("#754e50")}

func _ready()->void:
	name="CastleFloorPlan";position=Vector2(650,295);size=Vector2(600,380);theme=FortInterface.theme()
	var style:=FortInterface.frame(true);style.set_content_margin_all(12);add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();add_child(stack)
	var row:=HBoxContainer.new();stack.add_child(row)
	floors=OptionButton.new();floors.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(floors)
	for i in 8:floors.add_item("STOREY %d%s"%[i+1," / GROUND" if i==0 else ""])
	floors.item_selected.connect(func(i):floor_index=i;zoom=1;pan=Vector2.ZERO;refresh())
	var locate:=Button.new();locate.text="Your sign";row.add_child(locate);locate.pressed.connect(func():select_room(menu.anchor))
	map=Control.new();map.custom_minimum_size=Vector2(560,160);map.clip_contents=true;map.mouse_filter=Control.MOUSE_FILTER_STOP;stack.add_child(map)
	map.draw.connect(draw_map);map.gui_input.connect(map_input)
	var legend:=Label.new();legend.text="Green + ready / red + locked / gold work / wheel zoom / middle-drag";legend.add_theme_font_size_override("font_size",12);stack.add_child(legend)
	caption=Label.new();caption.custom_minimum_size=Vector2(560,54);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.max_lines_visible=2;caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;caption.add_theme_font_size_override("font_size",14);stack.add_child(caption)
	support=Button.new();support.text="SHOW REQUIRED SUPPORT BELOW";stack.add_child(support);support.pressed.connect(show_support)
	var locate_sign:=Button.new();locate_sign.text="MARK SELECTED ROOM'S SIGN & RETURN TO PLAY";stack.add_child(locate_sign);locate_sign.pressed.connect(mark_sign)

func room_key(x:int,z:int)->String:return FortCastle.key(x,z,floor_index)
func refresh()->void:
	if not is_instance_valid(map):return
	floors.select(floor_index);cells.clear();regions.clear()
	var castle:=menu.castle;var kind:String=FortCastle.TYPES.keys()[menu.kinds.selected]
	for key in castle.rooms:
		var room:Dictionary=castle.rooms[key]
		if int(room.floor)==floor_index:cells[key]={"room":true,"data":room,"status":"project" if room.task!="" or not room.complete else "finished","from":key}
	for source in castle.rooms:
		for option in castle.candidates(source):
			if int(option.floor)!=floor_index:continue
			var reason:=castle.plan_reason(source,option,kind)
			if cells.has(option.key) and cells[option.key].get("reason","")=="":continue
			cells[option.key]={"room":false,"data":option,"status":"ready" if reason=="" else "locked","from":source,"reason":reason}
	# Show the full footprint, including rooms on other floors as faint context.
	for room in castle.rooms.values():
		var key:=room_key(room.x,room.z)
		if not cells.has(key):cells[key]={"room":false,"data":{"x":room.x,"z":room.z,"floor":floor_index},"status":"context","from":"","reason":"No connection on this floor. Start upstairs from a finished stairwell below."}
	if required!="" and not cells.has(required):
		var xyz:=required.split(":")
		if int(xyz[2])==floor_index:cells[required]={"room":false,"data":{"x":int(xyz[0]),"z":int(xyz[1]),"floor":floor_index},"status":"context","from":"","reason":"A supporting room is needed here. Expand toward this cell from a connected room on this floor."}
	caption.text="GREEN + available  /  RED + locked  /  GOLD building\nClick a room or + to inspect. White outline: selected; gold: your sign."
	if selected!="" and cells.has(selected):
		var cell:Dictionary=cells[selected]
		caption.text=("%s / grid (%d, %d)"%[str(cell.data.get("kind","Expansion")),cell.data.x,cell.data.z])+"\n"+(cell.get("reason","") if not cell.room else ("Completed room" if cell.status=="finished" else "Unfinished project / HOLD E at its sign"))
	if required!="" and selected==required:
		caption.text="REQUIRED SUPPORT / highlighted in coral\n"+("Finish this room: HOLD E at its sign." if castle.rooms.has(required) else "Build a connected room in this cell before adding the floor above.")
	support.visible=missing_support()!=""
	caption.tooltip_text=caption.text
	map.queue_redraw()

func missing_support()->String:
	if not cells.has(selected):return ""
	var c:Dictionary=cells[selected];var r:Dictionary=c.data
	if c.room or int(r.floor)==0:return ""
	var below:=FortCastle.key(r.x,r.z,int(r.floor)-1)
	if not menu.castle.rooms.get(below,{}).get("complete",false):return below
	return ""

func draw_map()->void:
	regions.clear();map.draw_rect(Rect2(Vector2.ZERO,map.size),Color("#10272b"))
	if cells.is_empty():return
	var lo:=Vector2i(0,0);var hi:=Vector2i(0,0)
	for cell in cells.values():lo=lo.min(Vector2i(cell.data.x,cell.data.z));hi=hi.max(Vector2i(cell.data.x,cell.data.z))
	var span:=hi-lo+Vector2i.ONE
	var scale:=minf(48,minf((map.size.x-12)/span.x,(map.size.y-12)/span.y))*zoom
	var origin:=(map.size-Vector2(span)*scale)*.5+pan
	var font:=ThemeDB.fallback_font
	for key in cells:
		var cell:Dictionary=cells[key];var rect:=Rect2(origin+Vector2(Vector2i(cell.data.x,cell.data.z)-lo)*scale,Vector2.ONE*scale).grow(-2)
		regions[key]=rect;map.draw_rect(rect,COLORS.get(cell.status,Color("#253b40")))
		if key==menu.anchor:map.draw_rect(rect,FortInterface.GOLD,false,2)
		if key==selected or key==required:map.draw_rect(rect.grow(1),Color("#ff987a") if key==required else Color("#f2ddd0"),false,2)
		var symbol:="+" if cell.status in ["ready","locked"] else ("?" if cell.status=="context" else ("K" if cell.data.kind=="Keep" else ("S" if cell.data.kind=="Stairs" else str(cell.data.kind).left(1))))
		if scale>=20:map.draw_string(font,rect.position+Vector2(6,rect.size.y*.65),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#eee3c7"))
		if cell.status=="project":
			var progress:float=clampf(float(cell.data.work)/maxf(1,float(cell.data.total)),0,1)
			map.draw_rect(Rect2(rect.position+Vector2(0,rect.size.y-4),Vector2(rect.size.x*progress,4)),FortInterface.GOLD)

func map_input(event:InputEvent)->void:
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_MIDDLE:pan+=event.relative;map.queue_redraw();accept_event();return
	if event is InputEventMouseMotion:
		map.tooltip_text=""
		for key in regions:
			if regions[key].has_point(event.position):
				var cell:Dictionary=cells[key];var r:Dictionary=cell.data
				map.tooltip_text="%s / storey %d / grid (%d, %d)\n%s"%[FortCastle.TYPES.get(r.get("kind",""),{}).get("name",r.get("kind","Expansion")),int(r.floor)+1,r.x,r.z,cell.get("reason",cell.status)];break
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		zoom=clampf(zoom*(1.3 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.3),1,12);map.queue_redraw();accept_event();return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for key in regions:
			if regions[key].has_point(event.position):select_cell(key);accept_event();return
func select_room(key:String)->void:
	if not menu.castle.rooms.has(key):return
	floor_index=int(menu.castle.rooms[key].floor);selected=key;required="";zoom=1;pan=Vector2.ZERO;menu.inspect_room(key);refresh()
func select_cell(key:String)->void:
	if not cells.has(key):return
	var cell:Dictionary=cells[key];selected=key;required=""
	if cell.room:menu.inspect_room(key)
	elif cell.from!="":
		menu.inspect_room(cell.from)
		for i in menu.options.size():
			if menu.options[i].key==key:menu.choices.select(i);break
		menu.refresh_preview();menu.update_guidance()
	else:menu.position_camera(FortCastle.position(cell.data))
	refresh()
func show_support()->void:
	var below:=missing_support()
	if below=="":return
	required=below;selected=below;floor_index=int(below.split(":")[2]);zoom=1;pan=Vector2.ZERO;refresh()
	if menu.castle.rooms.has(below):menu.inspect_room(below)
	elif cells[below].from!="":
		menu.inspect_room(cells[below].from)
		for i in menu.options.size():
			if menu.options[i].key==below:menu.choices.select(i);break
		menu.refresh_preview();menu.update_guidance()
	menu.position_camera(FortCastle.position(cells[below].data))
	caption.text="REQUIRED SUPPORT / highlighted in coral\n"+("Finish this room: HOLD E at its sign." if menu.castle.rooms.has(below) else "Build a connected room in this cell before adding the floor above.")
func mark_sign()->void:
	if not menu.castle.rooms.has(menu.target):return
	if is_instance_valid(marker):marker.queue_free()
	marker=Visuals.label_3d("BUILD HERE / K to plan / HOLD E to work",Color("#ffe1a1"),0);marker.font_size=26;marker.no_depth_test=true
	menu.castle.world.add_child(marker);marker.position=menu.castle.rooms[menu.target].sign+Vector3.UP*3
	marker.visibility_range_end=200
	var placed:=marker
	menu.castle.world.get_tree().create_timer(45).timeout.connect(func():if is_instance_valid(placed):placed.queue_free())
	menu.close_panel()
