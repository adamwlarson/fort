class_name FortPieceBar
extends Control
## Build menu chrome: the category tabs for every build page and the cards for building pieces.
## Tower cards are still drawn by the HUD; this draws beside them in the same grid.
var world:FortWorld
var frame:StyleBoxFlat
var active:StyleBoxFlat
const LEFT:=937.0
const TOP:=60.0
const CARD:=Vector2(155,66)
const STEP:=Vector2(163,70.5)

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame=FortInterface.frame();active=FortInterface.frame(true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta:float)->void:
	var p:=world.local_player()
	visible=world.local_build_mode and not world.menu_open and not world.ended and p!=null and p.health>0
	if visible:queue_redraw()

func text(pos:Vector2,value:String,color:Color,size:int,width:=-1.0)->void:
	draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,width,size,color)

func _draw()->void:
	var tabs:=world.build_tabs();var width:=326.0/tabs.size()
	for i in tabs.size():
		var rect:=Rect2(LEFT+i*width,36,width-3,19)
		draw_style_box(active if i==world.build_tab else frame,rect)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(0,14),tabs[i],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,10,FortInterface.PAPER if i==world.build_tab else FortInterface.MUTED)
	if world.build_tab<2:return
	var items:Array=FortPieces.TABS[world.build_tab-2].items
	for i in items.size():
		var spec:Dictionary=FortPieces.KINDS[items[i]]
		var rect:=Rect2(Vector2(LEFT+(i%2)*STEP.x,TOP+int(i/2)*STEP.y),CARD)
		var chosen:bool=i==world.pieces.index
		draw_style_box(active if chosen else frame,rect)
		text(rect.position+Vector2(8,17),"%d  %s"%[i+1,spec.name],FortInterface.PAPER,12,CARD.x-12)
		text(rect.position+Vector2(8,36),FortGlyphs.cost(spec.cost),FortInterface.PAPER,12)
		var missing:PackedStringArray=[]
		for resource in spec.cost:
			var short:=int(spec.cost[resource])-int(world.shared.get(resource,0))
			if short>0:missing.append("%d%s"%[short,FortGlyphs.g(resource)])
		var note:="READY" if missing.is_empty() else "Short by "+" ".join(missing)
		if world.hearth_level<int(spec.get("tier",1)):note="NEEDS HEARTH TIER %d"%spec.tier
		text(rect.position+Vector2(8,55),note,FortInterface.GOLD if note=="READY" else Color("#f0a58b"),10)
	var chosen_spec:Dictionary=FortPieces.KINDS[world.pieces.selected()]
	var rows:=ceili(items.size()/2.0)
	var box:=Rect2(LEFT,TOP+rows*STEP.y+2,318,44)
	draw_style_box(frame,box)
	draw_multiline_string(ThemeDB.fallback_font,box.position+Vector2(8,15),chosen_spec.desc,HORIZONTAL_ALIGNMENT_LEFT,302,11,3,FortInterface.MUTED)
