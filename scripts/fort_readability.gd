class_name FortReadability
extends CanvasLayer

var world:FortWorld
var badges:Dictionary={}
var flying:Array[Dictionary]=[]
var scan_time:=0.0
var receipt:PanelContainer
var receipt_rows:VBoxContainer
var receipt_time:=0.0
var receipt_count:=0
var last_loot:Dictionary={}
var loot_queue:Array[Dictionary]=[]
var gain_count:=0
static func item_name(kind:String)->String:
	return GameData.WEAPONS[kind].name if GameData.WEAPONS.has(kind) else kind.capitalize()
static func icon_kind(kind:String)->String:
	return "Hammer" if kind=="Embermaul" else ("Crossbow" if kind=="Stormstring" else kind)
static func chip(kind:String,text:String)->PanelContainer:
	var panel:=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new();style.bg_color=Color("#14262b");style.border_color=GameData.resource_color(kind) if kind in GameData.RESOURCES else FortInterface.GOLD;style.set_border_width_all(1);style.set_corner_radius_all(5);style.content_margin_left=5;style.content_margin_right=7;style.content_margin_top=3;style.content_margin_bottom=3;panel.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.name="HBoxContainer";row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
	var icon:=FortIcon.new();icon.kind=icon_kind(kind);icon.tint=style.border_color;icon.custom_minimum_size=Vector2(24,24);row.add_child(icon)
	var label:=Label.new();label.name="Text";label.text=text;label.add_theme_font_size_override("font_size",14);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(label)
	return panel
func _ready()->void:
	layer=4
	receipt=PanelContainer.new();receipt.position=Vector2(740,280);receipt.size=Vector2(510,160);receipt.theme=FortInterface.theme();receipt.mouse_filter=Control.MOUSE_FILTER_IGNORE;receipt.z_index=3;add_child(receipt)
	var style:=FortInterface.frame(true);style.set_content_margin_all(14);receipt.add_theme_stylebox_override("panel",style)
	receipt_rows=VBoxContainer.new();receipt_rows.add_theme_constant_override("separation",7);receipt.add_child(receipt_rows);receipt.hide()
func _process(delta:float)->void:
	var p:=world.local_player();var camera:=world.get_viewport().get_camera_3d()
	if not p or not camera:return
	scan_time-=delta
	if scan_time<=0:scan_time=.2;scan_resources(p)
	var occupied:Array[Rect2]=[]
	for id in badges:
		var badge:Control=badges[id]
		if not world.resource_nodes.has(id):badge.hide();continue
		var r:Dictionary=world.resource_nodes[id];var point:Vector3=r.node.position+Vector3.UP*(3 if FortForestry.is_tree(r) else 1.7)
		badge.visible=r.amount>0 and (not world.menu_open or world.castle.menu.panel.visible) and not camera.is_position_behind(point)
		if badge.visible:
			var screen:=camera.unproject_position(point);badge.position=screen-Vector2(badge.size.x*.5,20)
			badge.visible=Rect2(15,170,1250,405).has_point(screen) and (not world.castle.menu.panel.visible or screen.x>630)
			if badge.visible:
				var bounds:=Rect2(badge.position,badge.size)
				for other in occupied:
					if bounds.intersects(other):badge.visible=false;break
				if badge.visible:occupied.append(bounds.grow(3))
	for item in flying.duplicate():
		item.age+=delta
		if item.age>1.5:item.node.queue_free();flying.erase(item);continue
		var point:Vector3=item.pos+Vector3.UP*item.age*.8
		item.node.visible=not world.menu_open and not camera.is_position_behind(point)
		if item.node.visible:
			var screen:=camera.unproject_position(point)
			item.node.position=screen-Vector2(item.node.size.x*.5,95+item.age*35)
			item.node.modulate.a=minf(1,(1.5-item.age)*2)
			item.node.visible=Rect2(15,175,1250,385).encloses(Rect2(item.node.position,item.node.size))
	if not world.menu_open:
		receipt_time=maxf(0,receipt_time-delta)
		if receipt_time<=0 and not loot_queue.is_empty():show_loot(loot_queue.pop_front())
	receipt.visible=receipt_time>0 and not world.menu_open and not world.ended
func scan_resources(p:FortPlayer)->void:
	var origin:=p.position;var planning:=world.castle.menu.panel.visible and is_instance_valid(world.castle.menu.ghost)
	if planning:origin=world.castle.menu.ghost.position
	var nearby:Array=[]
	for id in world.resource_nodes:
		var r:Dictionary=world.resource_nodes[id]
		if r.amount>0 and r.node.position.distance_to(origin)<(18 if planning else 24):nearby.append(id)
	nearby.sort_custom(func(a,b):return world.resource_nodes[a].node.position.distance_squared_to(origin)<world.resource_nodes[b].node.position.distance_squared_to(origin))
	nearby=nearby.slice(0,20 if planning else 12)
	for id in badges.keys():
		if id not in nearby:badges[id].queue_free();badges.erase(id)
	for id in nearby:
		var r:Dictionary=world.resource_nodes[id]
		if not badges.has(id):badges[id]=chip(r.kind,"");add_child(badges[id])
		var locked:=FortForestry.requirement(r,p)!=""
		var label:Label=badges[id].get_node("HBoxContainer/Text")
		label.text="%s %d%s"%[str(r.kind).to_upper(),r.amount," / AXE +%d"%int(r.get("axe",1)) if locked else ""]
		label.modulate=Color("#f1b07d") if locked else Color.WHITE
func gain(actor:int,pos:Vector3,kind:String,amount:int,destination:String)->void:
	if kind not in GameData.RESOURCES or amount<=0:return
	var p:=world.local_player()
	if not p or p.position.distance_to(pos)>30:return
	gain_count+=1
	if flying.size()>=18:var oldest:Dictionary=flying.pop_front();oldest.node.queue_free()
	var where:=destination
	if destination=="PACK":where="YOUR PACK" if actor==p.peer_id else "CREW PACK"
	var badge:=chip(kind,"+%d %s · %s"%[amount,kind.capitalize(),where]);badge.z_index=2;add_child(badge)
	flying.append({"node":badge,"pos":pos,"age":0.0})
func loot(title:String,resources:Dictionary,items:Array,spent:Dictionary={})->void:
	var data:={"title":title,"resources":resources.duplicate(),"items":items.duplicate(),"spent":spent.duplicate()}
	receipt_count+=1;last_loot=data
	if receipt_time>0:
		if loot_queue.size()<8:loot_queue.append(data)
	else:show_loot(data)
func show_loot(data:Dictionary)->void:
	for child in receipt_rows.get_children():receipt_rows.remove_child(child);child.queue_free()
	var heading:=Label.new();heading.text="CREW TREASURE / "+str(data.title);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;heading.custom_minimum_size.x=475;receipt_rows.add_child(heading)
	if not data.resources.is_empty():
		var caption:=Label.new();caption.text="Added to SHARED STOCKPILE";receipt_rows.add_child(caption)
		var row:=HFlowContainer.new();row.custom_minimum_size.x=475;receipt_rows.add_child(row)
		for kind in data.resources:
			if int(data.resources[kind])>0:row.add_child(chip(kind,"+%d %s"%[data.resources[kind],kind.capitalize()]))
	for kind in data.items:receipt_rows.add_child(chip(kind,"NEW CREW GEAR / "+item_name(kind)))
	for kind in data.spent:receipt_rows.add_child(chip(kind,"LOCK COST / −%d %s"%[data.spent[kind],kind.capitalize()]))
	receipt_time=8;receipt.size.y=0
