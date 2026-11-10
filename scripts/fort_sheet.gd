class_name FortSheet
extends Control

# TAB character sheet: gear on the left, level / experience and the seven stats on the right.
var world:FortWorld
var panel:PanelContainer
var gear:Label
var summary:Label
var xp_bar:ProgressBar
var rows:Dictionary={}
var points:Label

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	theme=FortInterface.theme()
	panel=PanelContainer.new();panel.position=Vector2(250,150);panel.size=Vector2(780,330)
	var style:=FortInterface.frame(true);style.set_content_margin_all(18);panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",22);panel.add_child(columns)
	var left:=VBoxContainer.new();left.custom_minimum_size.x=300;left.add_theme_constant_override("separation",8);columns.add_child(left)
	var title:=Label.new();title.text="CHARACTER";title.add_theme_font_size_override("font_size",20);title.add_theme_color_override("font_color",FortInterface.GOLD);left.add_child(title)
	summary=Label.new();summary.add_theme_font_size_override("font_size",14);left.add_child(summary)
	xp_bar=ProgressBar.new();xp_bar.custom_minimum_size=Vector2(290,10);xp_bar.show_percentage=false
	var bg:=StyleBoxFlat.new();bg.bg_color=Color("#27383a");bg.set_corner_radius_all(4);xp_bar.add_theme_stylebox_override("background",bg)
	var fill:=StyleBoxFlat.new();fill.bg_color=Color("#7fe0c0");fill.set_corner_radius_all(4);xp_bar.add_theme_stylebox_override("fill",fill)
	left.add_child(xp_bar)
	var gear_title:=Label.new();gear_title.text="GEAR";gear_title.add_theme_font_size_override("font_size",15);gear_title.add_theme_color_override("font_color",FortInterface.GOLD);left.add_child(gear_title)
	gear=Label.new();gear.add_theme_font_size_override("font_size",13);gear.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;gear.custom_minimum_size.x=290;left.add_child(gear)
	var hint:=Label.new();hint.text="Earn experience by defeating enemies, building and gathering.\nTAB or Esc closes this sheet.";hint.add_theme_font_size_override("font_size",11);hint.add_theme_color_override("font_color",FortInterface.MUTED)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.custom_minimum_size.x=290;left.add_child(hint)
	var right:=VBoxContainer.new();right.custom_minimum_size.x=420;right.add_theme_constant_override("separation",5);columns.add_child(right)
	points=Label.new();points.add_theme_font_size_override("font_size",16);points.add_theme_color_override("font_color",FortInterface.GOLD);right.add_child(points)
	for stat in FortStats.STATS:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);right.add_child(row)
		var text:=VBoxContainer.new();text.custom_minimum_size.x=250;text.add_theme_constant_override("separation",0);row.add_child(text)
		var name_label:=Label.new();name_label.add_theme_font_size_override("font_size",14);text.add_child(name_label)
		var effect:=Label.new();effect.text=FortStats.EFFECT[stat];effect.add_theme_font_size_override("font_size",10);effect.add_theme_color_override("font_color",FortInterface.MUTED);text.add_child(effect)
		var value:=Label.new();value.custom_minimum_size.x=96;value.add_theme_font_size_override("font_size",13);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(value)
		var plus:=Button.new();plus.text="+";plus.custom_minimum_size=Vector2(34,30);plus.tooltip_text="Spend one stat point on "+FortStats.NAMES[stat]
		plus.pressed.connect(func():world.request_action("stat_point",{"stat":stat}))
		row.add_child(plus)
		rows[stat]={"name":name_label,"value":value,"plus":plus}
	hide()

func open_panel()->void:
	if world.menu_open or world.ended or not world.local_player():return
	world.menu_open=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;show();refresh()

func close_panel()->void:
	if not visible:return
	hide();world.menu_open=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func toggle()->void:
	if visible:close_panel()
	else:open_panel()

func _process(_delta:float)->void:
	if visible:refresh()

func refresh()->void:
	var p:=world.local_player()
	if not p:return
	var data:Dictionary=GameData.class_data(p.class_id)
	summary.text="%s  /  %s\nLEVEL %d     %d / %d %s"%[p.display_name,data.name,p.level,p.xp,FortStats.need(p.level),FortGlyphs.g("xp")]
	xp_bar.value=100.0*p.xp/FortStats.need(p.level)
	var lines:PackedStringArray=[]
	lines.append("Weapon:  "+GameData.weapon_title(p))
	var weapon:Dictionary=GameData.WEAPONS[p.weapon]
	lines.append("   %d damage  /  %.2fs cooldown  /  %dm reach"%[roundi(float(weapon.damage)*p.weapon_power(p.weapon)),float(weapon.cooldown)*FortStats.cooldown_multiplier(p),int(weapon.range)])
	var owned:PackedStringArray=[]
	for kind in p.owned_weapons:
		if kind!=p.weapon:owned.append(GameData.WEAPONS[kind].name)
	lines.append("Also carried:  "+(", ".join(owned) if not owned.is_empty() else "nothing else"))
	lines.append("Armor:  "+("Ironheart plate  (+40%s)"%FortGlyphs.g("hp") if p.armor else "Travelling clothes  (no armor)"))
	lines.append("Backpack:  "+(GameData.BACKPACKS[p.backpack_level-1].name+"  (+%d slots)"%GameData.BACKPACKS[p.backpack_level-1].bonus if p.backpack_level>0 else "Belt pouches"))
	lines.append("Relics:  "+(", ".join(p.relics) if not p.relics.is_empty() else "none found yet"))
	lines.append("Ability [F]:  "+str(data.ability))
	gear.text="\n".join(lines)
	points.text="STATS    %d point%s to spend"%[p.stat_points,"" if p.stat_points==1 else "s"]
	for stat in FortStats.STATS:
		var row:Dictionary=rows[stat];var rank:=FortStats.rank(p,stat)
		row.name.text="%s   %d / %d"%[FortStats.NAMES[stat],rank,FortStats.MAX_RANK]
		row.value.text=FortStats.value_text(p,stat)
		row.plus.disabled=p.stat_points<=0 or rank>=FortStats.MAX_RANK
