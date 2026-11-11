class_name FortCookMenu
extends PanelContainer

# The cooking pot's menu: every dish with what it needs, how many servings are ready, and
# buttons to cook a batch or eat one.
var world:FortWorld
var title:Label
var rows:VBoxContainer
var stamp:=""

func _ready()->void:
	position=Vector2(250,90);size=Vector2(780,530);theme=FortInterface.theme()
	var style:=FortInterface.frame(true);style.set_content_margin_all(22);add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",10);add_child(stack)
	title=Label.new();title.add_theme_font_size_override("font_size",16);stack.add_child(title)
	rows=VBoxContainer.new();rows.add_theme_constant_override("separation",6);stack.add_child(rows)
	var back:=Button.new();back.text="LEAVE THE POT / ESC";back.pressed.connect(close_panel);stack.add_child(back);hide()

func open_panel()->void:
	world.menu_open=true;stamp="";show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;refresh()

func close_panel()->void:
	hide();world.menu_open=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _process(_delta:float)->void:
	if not visible:return
	var p:=world.local_player()
	if not p or p.health<=0 or FortCooking.nearest(world,p.position)<0 or world.ended:close_panel();return
	refresh()

func refresh()->void:
	var p:=world.local_player()
	var boosts:=FortCooking.summary(p)
	title.text="COOKING POT\nGame from the shared stockpile becomes meals for the crew.%s"%("\nActive: "+boosts if boosts!="" else "")
	var next:=str([world.shared,int(p.health)/5])
	if stamp==next:return
	stamp=next
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	var pantry:=PackedStringArray()
	for kind in GameData.FOOD:
		if int(world.shared.get(kind,0))>0:pantry.append("%d%s"%[int(world.shared[kind]),FortGlyphs.g(kind)])
	var larder:=Label.new();larder.text="In the stockpile: "+("  ".join(pantry) if not pantry.is_empty() else "no game yet. Hunt, carry it home and deposit it.");larder.add_theme_font_size_override("font_size",13);rows.add_child(larder)
	for dish in FortCooking.DISHES:
		var spec:Dictionary=FortCooking.DISHES[dish]
		var known:bool=int(world.shared.get(dish,0))>0
		for kind in spec.needs:
			if kind in GameData.FOOD and kind not in ["meat","venison"] and int(world.shared.get(kind,0))>0:known=true
		# Dishes made from game the crew has never brought home stay a mystery.
		if not known and dish not in ["stew","roast"]:
			var hint:=Label.new();hint.text="??? / a dish from game you have not found yet";hint.add_theme_font_size_override("font_size",12);hint.modulate=Color(1,1,1,.5);rows.add_child(hint);continue
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);rows.add_child(row)
		var text:=Label.new();text.custom_minimum_size.x=500;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.clip_text=true;text.add_theme_font_size_override("font_size",13)
		text.text="%s %s   ready: %d\n%s  >  +%d%s, %s for %d:%02d"%[FortGlyphs.g(dish),spec.name,int(world.shared.get(dish,0)),GameData.supplies_text(spec.needs,true),int(spec.heal),FortGlyphs.g("hp"),spec.text,int(spec.seconds)/60,int(spec.seconds)%60]
		row.add_child(text)
		var cook:=Button.new();cook.text="COOK x%d"%int(spec.serves);cook.custom_minimum_size=Vector2(110,40);cook.disabled=not FortCooking.can_cook(world,dish);row.add_child(cook)
		cook.pressed.connect(func():world.request_action("cook",{"dish":dish}))
		var eat:=Button.new();eat.text="EAT";eat.custom_minimum_size=Vector2(90,40);eat.disabled=int(world.shared.get(dish,0))<=0;row.add_child(eat)
		eat.pressed.connect(func():world.request_action("eat",{"dish":dish}))
