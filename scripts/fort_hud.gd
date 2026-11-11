class_name FortHUD
extends CanvasLayer

var world: Node3D
var phase: Label
var economy: Label
var crew: Label
var crew_right:Label
var objective: Label
var prompt: Label
var pack: Label
var ability: Label
var notice: Label
var build: Label
var vitals: ProgressBar
var hearth: ProgressBar
var menu: PanelContainer
var damage: ColorRect
var compass: Label
var map: FortMinimap
var build_cards: Array[PanelContainer] = []
var card_costs: Array[Label] = []
var card_status: Array[Label] = []
var stock_panel: PanelContainer
var stock_contents: Label
var stock_action: Label
var stock_progress: Label
var stock_meter: ProgressBar
var hints: Label
var menu_scrim: ColorRect
var stock_icons:HFlowContainer
var forge:FortForge
var weapon_label:Label
var hearth_menu:FortHearth
var upgrade_menu:FortUpgradeMenu
var combat_overlay:FortCombatOverlay
var siege_indicators:FortSiegeIndicators
var fps_toggle:CheckButton
var fps_counter:Label
var fps_refresh:=0.0
var controls:FortControls
var merchant:FortMerchant
var sheet:FortSheet
var down_banner:Label
var hp_text:Label
var xp_bar:ProgressBar
var stock_labels:Dictionary={}
static var test_settings_file:=""

static func fps_settings_path()->String:
	if "--fort-test" in OS.get_cmdline_user_args():return test_settings_file if test_settings_file!="" else "res://build/fps_settings_%d.cfg"%OS.get_process_id()
	return "user://display_settings.cfg"

func set_fps_display(enabled:bool)->void:
	fps_counter.visible=enabled;fps_refresh=0
	var config:=ConfigFile.new();config.load(fps_settings_path());config.set_value("display","show_fps",enabled)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fps_settings_path()).get_base_dir())
	if config.save(fps_settings_path())!=OK:world.show_toast("FPS display changed, but the preference could not be saved.")

func _ready() -> void:
	world=get_parent()
	# Fort 26 compact HUD: slim corner strips, text without boxes, nothing over the middle of the view.
	var top:=panel(Vector2(10,8),Vector2(352,58))
	phase=label(top,Vector2(10,4),15,Color("#f1ce8f"))
	hearth=bar(top,Vector2(152,9),Vector2(188,7),Color("#d9a865"))
	economy=label(top,Vector2(152,17),10,Color("#d5ddd6"))
	stock_icons=HFlowContainer.new();stock_icons.position=Vector2(9,33);stock_icons.size=Vector2(338,22);stock_icons.add_theme_constant_override("h_separation",9);top.get_node("Content").add_child(stock_icons)
	for kind in GameData.RESOURCES+["gold"]:
		var chip:=Label.new();chip.name=kind;chip.add_theme_font_size_override("font_size",13);chip.add_theme_color_override("font_color",FortInterface.PAPER)
		chip.tooltip_text=kind.capitalize()+" in the shared stockpile";chip.mouse_filter=Control.MOUSE_FILTER_PASS;stock_icons.add_child(chip);stock_labels[kind]=chip
	objective=label(null,Vector2(330,8),13,Color("#efe8d7"))
	objective.size=Vector2(620,20);objective.clip_text=true
	objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	down_banner=label(null,Vector2(330,29),15,Color("#ff9c87"))
	down_banner.size=Vector2(620,22);down_banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	crew=label(null,Vector2(-400,-400),12,Color("#c3d7cd"));crew.hide()
	crew_right=label(null,Vector2(-400,-400),12,Color("#c3d7cd"));crew_right.hide()
	var lower:=panel(Vector2(10,662),Vector2(262,50))
	hp_text=label(lower,Vector2(184,1),13,Color("#f3d7cf"))
	vitals=bar(lower,Vector2(10,8),Vector2(168,9),Color("#c76856"))
	pack=label(lower,Vector2(10,21),12,Color("#edce91"))
	xp_bar=bar(lower,Vector2(10,42),Vector2(242,3),Color("#7fe0c0"))
	ability=label(null,Vector2(340,698),12,Color("#bce0d7"))
	ability.size=Vector2(600,18);ability.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt=label(null,Vector2(340,612),16,Color("#fff1d1"))
	prompt.size=Vector2(600,26);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice=label(null,Vector2(340,56),15,Color("#f1ce8f"))
	notice.size=Vector2(600,60);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	build=label(null,Vector2(370,473),13,Color("#efd39f"))
	build.size=Vector2(530,75);build.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	compass=label(null,Vector2(1000,150),11,Color("#d1dfcd"))
	compass.size=Vector2(270,40);compass.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	hints=label(null,Vector2(920,618),13,Color("#c8d0c6"))
	hints.hide()
	damage=ColorRect.new();damage.color=Color(0.7,0.05,0.01,0);damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);damage.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(damage)
	map=FortMinimap.new();map.world=world;add_child(map)
	menu_scrim=ColorRect.new()
	menu_scrim.color=Color(0.015,0.035,0.04,0.6)
	menu_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_scrim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(menu_scrim);menu_scrim.hide()
	menu=panel(Vector2(430,70),Vector2(420,585))
	var menu_style:=FortInterface.frame(true)
	menu_style.set_content_margin_all(24)
	menu.add_theme_stylebox_override("panel",menu_style)
	menu.theme=FortInterface.theme()
	var camp_scroll:=ScrollContainer.new();camp_scroll.custom_minimum_size=Vector2(360,520);menu.add_child(camp_scroll)
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",10);camp_scroll.add_child(stack)
	var title:=Label.new();title.text="CAMP MENU";title.add_theme_font_size_override("font_size",28);stack.add_child(title)
	var resume:=Button.new();resume.text="Return to the crew";resume.custom_minimum_size.y=46;resume.pressed.connect(world.toggle_pause);stack.add_child(resume)
	controls=FortControls.new();controls.hud=self;add_child(controls)
	merchant=FortMerchant.new();merchant.world=world;add_child(merchant)
	sheet=FortSheet.new();sheet.world=world;add_child(sheet)
	var controls_button:=Button.new();controls_button.name="ControlsButton";controls_button.text="Controls";controls_button.pressed.connect(controls.open_panel);stack.add_child(controls_button)
	var unstuck:=Button.new();unstuck.name="UnstuckButton";unstuck.text="I'm stuck / move to safe ground";unstuck.custom_minimum_size.y=40
	unstuck.tooltip_text="Find clear ground nearby, or near the hearth if necessary. Keeps your pack and health. 15-second cooldown."
	unstuck.pressed.connect(func():world.request_action("unstuck");world.toggle_pause());stack.add_child(unstuck)
	var sensitivity:=Label.new();sensitivity.text="Mouse sensitivity";stack.add_child(sensitivity)
	var slider:=HSlider.new();slider.min_value=0.001;slider.max_value=0.005;slider.step=0.0001;slider.value=world.mouse_sensitivity;slider.value_changed.connect(func(value):world.mouse_sensitivity=value);stack.add_child(slider)
	var sound:=CheckButton.new();sound.text="Sound effects";sound.button_pressed=true;sound.toggled.connect(func(value):world.sound.enabled=value);stack.add_child(sound)
	var tunes:=CheckButton.new();tunes.text="Music";tunes.button_pressed=true;stack.add_child(tunes)
	tunes.toggled.connect(func(value):
		var music=world.get_parent().get("music")
		if music:music.enabled=value)
	for bus_title in ["Music","SFX","Voice","Ambience"]:
		var caption:=Label.new();caption.text={"Music":"Music volume","SFX":"Effects volume","Voice":"Voices volume","Ambience":"Ambience volume"}[bus_title];stack.add_child(caption)
		var level:=HSlider.new();level.min_value=0.0;level.max_value=1.0;level.step=.05;level.value=.8;stack.add_child(level)
		level.value_changed.connect(func(value):
			var bus:=AudioServer.get_bus_index(bus_title)
			if bus>=0:AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(value/.8,.0001)));AudioServer.set_bus_mute(bus,value<=0.0))
	fps_toggle=CheckButton.new();fps_toggle.text="Show FPS counter";fps_toggle.tooltip_text="Display this computer's frames per second. Saved locally.";stack.add_child(fps_toggle)
	var exit_button:=Button.new();exit_button.text="Leave fort";exit_button.custom_minimum_size.y=44;exit_button.pressed.connect(func():world.return_to_menu.emit("Returned to title."));stack.add_child(exit_button)
	if multiplayer.is_server():
		var save_button:=Button.new();save_button.text="Save expedition…";save_button.custom_minimum_size.y=40;stack.add_child(save_button);stack.move_child(save_button,stack.get_child_count()-2)
		save_button.pressed.connect(func():world.get_parent().save_menu.open_panel(true))
		var save_exit:=Button.new();save_exit.text="Save & return to title";save_exit.custom_minimum_size.y=40;stack.add_child(save_exit);stack.move_child(save_exit,stack.get_child_count()-2)
		save_exit.pressed.connect(world.get_parent().save_and_leave)
		exit_button.text="Leave without saving (click twice)"
		for connection in exit_button.pressed.get_connections():exit_button.pressed.disconnect(connection.callable)
		exit_button.pressed.connect(func():
			if not exit_button.has_meta("confirmed"):exit_button.set_meta("confirmed",true);exit_button.text="Confirm leave WITHOUT saving";return
			world.return_to_menu.emit("Left without a new save."))
	var note:=Label.new();note.text="The crew keeps playing while this menu is open.";note.add_theme_font_size_override("font_size",13);stack.add_child(note)
	menu.hide()
	_build_work_panels()
	forge=FortForge.new();forge.world=world;add_child(forge)
	hearth_menu=FortHearth.new();hearth_menu.world=world;add_child(hearth_menu)
	upgrade_menu=FortUpgradeMenu.new();upgrade_menu.world=world;add_child(upgrade_menu)
	combat_overlay=FortCombatOverlay.new();combat_overlay.world=world;add_child(combat_overlay)
	siege_indicators=FortSiegeIndicators.new();siege_indicators.world=world;add_child(siege_indicators)
	var piece_bar:=FortPieceBar.new();piece_bar.world=world;piece_bar.name="PieceBar";add_child(piece_bar)
	weapon_label=label(null,Vector2(-400,-400),12,FortInterface.GOLD);weapon_label.hide()
	fps_counter=label(null,Vector2(368,44),11,FortInterface.PAPER);fps_counter.size=Vector2(70,22);fps_counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var config:=ConfigFile.new();config.load(fps_settings_path());var preference:Variant=config.get_value("display","show_fps",false)
	fps_toggle.button_pressed=preference is bool and preference;fps_counter.visible=fps_toggle.button_pressed
	fps_toggle.toggled.connect(set_fps_display)
	stock_panel.scale=Vector2.ONE*.72;stock_panel.position=Vector2(460,500)
	for card in build_cards:
		card.scale=Vector2.ONE*.72;card.position=Vector2(1280-(1280-card.position.x)*.72,60+(card.position.y-174)*.72)

func icon(parent: Control, kind: String, pos: Vector2, extent := 48.0) -> void:
	var glyph := FortIcon.new()
	glyph.kind=kind;glyph.position=pos;glyph.size=Vector2.ONE*extent
	glyph.tint=GameData.resource_color(kind) if kind in ["wood","stone","crystal"] else FortInterface.GOLD
	parent.add_child(glyph)

func _build_work_panels() -> void:
	for i in GameData.BUILD_ORDER.size():
		var card := panel(Vector2(804+(i%2)*226,174+int((i%10)/2)*98),Vector2(216,96))
		label(card,Vector2(45,8),16,FortInterface.PAPER).text="%d  %s"%[(i+1)%10,GameData.BUILD_ORDER[i]]
		icon(card.get_node("Content"),GameData.BUILD_ORDER[i],Vector2(8,7),30)
		var cost:=label(card,Vector2(10,39),12,FortInterface.PAPER);cost.size=Vector2(198,42);cost.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card_costs.append(cost)
		card_status.append(label(card,Vector2(10,79),11,FortInterface.GOLD))
		card.tooltip_text=GameData.BUILD_DESCS[i]
		build_cards.append(card)
		card.hide()
	stock_panel=panel(Vector2(385,415),Vector2(500,227))
	label(stock_panel,Vector2(20,15),13,FortInterface.GOLD).text="HEARTHHOLD / SHARED STOCKPILE"
	stock_action=label(stock_panel,Vector2(20,40),24,FortInterface.PAPER)
	stock_contents=label(stock_panel,Vector2(20,80),15,FortInterface.MUTED)
	stock_progress=label(stock_panel,Vector2(20,170),13,FortInterface.GOLD)
	stock_meter=bar(stock_panel,Vector2(20,198),Vector2(460,7),Color("#74b5a6"))
	stock_panel.hide()

func panel(pos:Vector2,size:Vector2)->PanelContainer:
	var root:=PanelContainer.new();root.position=pos;root.size=size
	var style:=FortInterface.frame()
	root.add_theme_stylebox_override("panel",style);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
	return root

func label(parent:Node,pos:Vector2,size:int,color:Color)->Label:
	var item:=Label.new();item.position=pos;item.add_theme_font_size_override("font_size",size);item.add_theme_color_override("font_color",color);item.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8));item.add_theme_constant_override("shadow_offset_y",2);item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# PanelContainer would lay these out over one another; use a plain overlay.
	if parent:
		var overlay:Control=parent.get_node_or_null("Content")
		if not overlay:overlay=Control.new();overlay.name="Content";overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(overlay)
		overlay.add_child(item)
	else:add_child(item)
	return item

func bar(parent:Node,pos:Vector2,size:Vector2,color:Color)->ProgressBar:
	var item:=ProgressBar.new();item.position=pos;item.size=size;item.show_percentage=false;item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size",1)
	var bg:=StyleBoxFlat.new();bg.bg_color=Color("#27383a");bg.set_corner_radius_all(4);item.add_theme_stylebox_override("background",bg)
	var fill:=StyleBoxFlat.new();fill.bg_color=color;fill.set_corner_radius_all(4);item.add_theme_stylebox_override("fill",fill)
	var overlay:Control=parent.get_node("Content");overlay.add_child(item)
	item.size=size
	return item

func _process(delta:float)->void:
	if fps_counter.visible:
		fps_refresh-=delta
		if fps_refresh<=0:fps_counter.text="%d FPS"%Engine.get_frames_per_second();fps_refresh=.25
	damage.color.a=move_toward(damage.color.a,0,delta*0.8)
	if not is_instance_valid(world):return
	menu_scrim.visible=world.menu_open
	menu_scrim.color.a=.08 if world.castle and world.castle.menu.panel.visible else .6
	var p:FortPlayer=world.local_player()
	phase.text="%s %d  ·  %02d:%02d"%["NIGHT" if world.is_night else "DAY",world.wave if world.is_night else world.wave+1,maxi(0,int(world.phase_time))/60,maxi(0,int(world.phase_time))%60]
	hearth.value=world.fort_health/world.fort_max_health*100
	economy.text="HEARTH TIER %d   %d / %d"%[world.hearth_level,world.fort_health,world.fort_max_health]
	for kind in stock_labels:
		stock_labels[kind].text="%d%s"%[int(world.shared.get(kind,0)),FortGlyphs.g(kind)]
		stock_labels[kind].visible=kind in ["wood","stone","crystal"] or int(world.shared.get(kind,0))>0
	var downed:PackedStringArray=[]
	if p:
		weapon_label.text="[C] %s"%GameData.weapon_title(p)
		vitals.value=p.health/p.max_health*100
		hp_text.text="%d%s"%[int(p.health),FortGlyphs.g("hp")]
		xp_bar.value=100.0*p.xp/FortStats.need(p.level)
		pack.text="PACK %d/%d   %s"%[p.total_carried(),p.carry_limit,FortGlyphs.cost(p.carrying) if p.total_carried()>0 else "empty"]
		pack.size=Vector2(244,18);pack.clip_text=true
		ability.text="[F] %s %s   ·   [C] %s   ·   [TAB] LV %d%s"%[GameData.class_data(p.class_id).ability,("%.0fs"%ceilf(p.ability_cooldown)) if p.ability_cooldown>0 else "READY",GameData.weapon_title(p),p.level,"  +%d"%p.stat_points if p.stat_points>0 else ""]
		if p.travel_mode==2:ability.text+="   ·   Fuel %.1fs"%p.fuel
		ability.visible=not world.menu_open
		prompt.text=world.context_prompt(p)
		var direction:Vector3=-p.position
		compass.text="%s  ·  hearth %dm %s"%[world.expedition.region_name(p.position),int(direction.length()),world.direction_to_home(p)]
		var trail:String=world.encounters.guidance(p.position)
		if not trail.is_empty():compass.text+="\n"+trail
		compass.position=Vector2(1000,map.footprint_bottom()+4);compass.visible=map.mode<3 and not world.menu_open and not world.local_build_mode
		if p.health<=0:prompt.text="YOU ARE DOWN  ·  An ally can hold E to revive you  ·  Rescue in %ds"%ceili(p.down_time)
		for dwarf in world.players.values():
			if dwarf!=p and dwarf.health<=0:downed.append("Player \"%s\" down %dm"%[dwarf.display_name,int(p.position.distance_to(dwarf.position))])
		_update_work_panels(p)
	down_banner.text="     ".join(downed)
	down_banner.visible=not downed.is_empty() and not world.menu_open
	objective.text=world.objective_text()
	objective.visible=not world.menu_open
	notice.text=world.toast_text if world.toast_time>0 else ""
	build.position=Vector2(200,640);build.size=Vector2(880,20)
	build.text=""
	if world.local_build_mode:
		if world.build_tab>=2:build.position=Vector2(200,626);build.text=world.pieces.status()
		else:
			var reason:String=world.build_block_reason(GameData.BUILD_ORDER[world.selected_build],world.build_position,world.build_rotation)
			build.text="Tab category  ·  Wheel or 1-0 choose  ·  Q rotate  ·  Click place  ·  X salvage     "+("OK to build here" if reason.is_empty() else "CANNOT BUILD: "+reason)

func _update_work_panels(p: FortPlayer) -> void:
	var working:bool=world.local_build_mode and not world.menu_open and p.health>0
	hints.hide()
	for i in build_cards.size():
		var card:=build_cards[i]
		card.visible=working and i/10==world.build_tab
		if not card.visible:continue
		var selected:bool=i==world.selected_build
		if card.get_meta("selected",false)!=selected:
			card.add_theme_stylebox_override("panel",FortInterface.frame(selected))
			card.set_meta("selected",selected)
		var recipe:Dictionary=GameData.RECIPES[GameData.BUILD_ORDER[i]]
		var costs:PackedStringArray=[]
		var missing:PackedStringArray=[]
		for resource in GameData.RESOURCES:
			var cost:=ceili(int(recipe.get(resource,0))*(0.75 if p.role_id==2 else 1.0))
			if cost>0:costs.append("%d%s"%[cost,FortGlyphs.g(resource)])
			if int(world.shared.get(resource,0))<cost:missing.append("%d%s"%[cost-int(world.shared.get(resource,0)),FortGlyphs.g(resource)])
		card_costs[i].text="  ".join(costs)
		card_status[i].text=("ENGINEER PRICE" if p.role_id==2 else "READY TO BUILD") if missing.is_empty() else "Short by "+" ".join(missing)
		if world.hearth_level<int(recipe.get("tier",1)):card_status[i].text="NEEDS HEARTH TIER %d"%recipe.tier
		card_status[i].add_theme_color_override("font_color",FortInterface.GOLD if missing.is_empty() else Color("#f0a58b"))
	var nearby:bool=p.position.distance_to(Vector3(4.6,0,0))<3.2
	stock_panel.visible=nearby and not working and not world.menu_open and p.health>0
	prompt.visible=not stock_panel.visible and not world.menu_open
	prompt.position.y=405 if working else 612
	if stock_panel.visible:
		stock_action.text="[ E ]  HOLD TO DEPOSIT ALL" if p.total_carried()>0 else "YOUR PACK IS EMPTY"
		stock_contents.text="YOUR PACK     "+GameData.supplies_text(p.carrying,true)+"\nSHARED           "+GameData.supplies_text(world.shared,true)+"\nDeposited supplies pay for everyone's builds and repairs."
		stock_contents.size=Vector2(460,85);stock_contents.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var target:=8 if world.lifetime_crystal<8 else 20
		stock_progress.text="%s   /   %d of %d crystals deposited"%["HORSES" if target==8 else "JETPACKS",mini(world.lifetime_crystal,target),target]
		if world.lifetime_crystal>=20:stock_progress.text="CREW TRAVEL UNLOCKED   /   Press T to change gear"
		stock_meter.value=minf(100,float(world.lifetime_crystal)/target*100)
