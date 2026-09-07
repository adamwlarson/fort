class_name FortHUD
extends CanvasLayer

var world: Node3D
var phase: Label
var economy: Label
var crew: Label
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
var map: Control
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

func _ready() -> void:
	world=get_parent()
	var top:=panel(Vector2(20,18),Vector2(345,156))
	phase=label(top,Vector2(18,10),24,Color("#f1ce8f"))
	hearth=bar(top,Vector2(18,50),Vector2(288,10),Color("#d9a865"))
	economy=label(top,Vector2(18,74),15,Color("#d5ddd6"))
	stock_icons=HFlowContainer.new();stock_icons.position=Vector2(18,96);stock_icons.size=Vector2(305,60);stock_icons.add_theme_constant_override("h_separation",5);stock_icons.add_theme_constant_override("v_separation",1);top.get_node("Content").add_child(stock_icons)
	for kind in GameData.RESOURCES:
		var chip:=FortReadability.chip(kind,"0");chip.name=kind;chip.custom_minimum_size.x=89;chip.tooltip_text=kind.capitalize()+" / shared stockpile";stock_icons.add_child(chip)
		chip.get_child(0).get_child(0).custom_minimum_size=Vector2(19,19)
	var middle:=panel(Vector2(370,18),Vector2(530,62))
	objective=label(middle,Vector2(14,10),16,Color("#efe8d7"))
	objective.size=Vector2(502,48);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var roster:=panel(Vector2(980,18),Vector2(280,144))
	crew=label(roster,Vector2(14,12),15,Color("#c3d7cd"))
	var lower:=panel(Vector2(20,593),Vector2(335,105))
	pack=label(lower,Vector2(16,12),16,Color("#edce91"))
	vitals=bar(lower,Vector2(16,67),Vector2(302,12),Color("#c76856"))
	ability=label(null,Vector2(440,664),18,Color("#bce0d7"))
	ability.size=Vector2(410,36);ability.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt=label(null,Vector2(355,552),19,Color("#fff1d1"))
	prompt.size=Vector2(570,42);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice=label(null,Vector2(378,97),20,Color("#f1ce8f"))
	notice.size=Vector2(530,80);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	build=label(null,Vector2(370,473),16,Color("#efd39f"))
	build.size=Vector2(530,75);build.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	compass=label(null,Vector2(985,175),15,Color("#d1dfcd"))
	hints=label(null,Vector2(920,618),13,Color("#c8d0c6"))
	hints.text="WASD move   Shift sprint   Space jump\nHold E gather   R repair   F ability\nB build   1–9 / 0 choose   Q rotate\nU hearth   G upgrade / salvage   T gear\nEnter ready for night   Esc menu"
	damage=ColorRect.new();damage.color=Color(0.7,0.05,0.01,0);damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);damage.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(damage)
	map=Control.new();map.position=Vector2(1130,302);map.size=Vector2(120,120);map.mouse_filter=Control.MOUSE_FILTER_IGNORE;map.draw.connect(_draw_map);add_child(map)
	menu_scrim=ColorRect.new()
	menu_scrim.color=Color(0.015,0.035,0.04,0.6)
	menu_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_scrim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(menu_scrim);menu_scrim.hide()
	menu=panel(Vector2(430,95),Vector2(420,535))
	var menu_style:=FortInterface.frame(true)
	menu_style.set_content_margin_all(24)
	menu.add_theme_stylebox_override("panel",menu_style)
	menu.theme=FortInterface.theme()
	var stack:=VBoxContainer.new();stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.offset_left=30;stack.offset_right=-30;stack.offset_top=25;stack.add_theme_constant_override("separation",10);menu.add_child(stack)
	var title:=Label.new();title.text="CAMP MENU";title.add_theme_font_size_override("font_size",28);stack.add_child(title)
	var resume:=Button.new();resume.text="Return to the crew";resume.custom_minimum_size.y=46;resume.pressed.connect(world.toggle_pause);stack.add_child(resume)
	var sensitivity:=Label.new();sensitivity.text="Mouse sensitivity";stack.add_child(sensitivity)
	var slider:=HSlider.new();slider.min_value=0.001;slider.max_value=0.005;slider.step=0.0001;slider.value=world.mouse_sensitivity;slider.value_changed.connect(func(value):world.mouse_sensitivity=value);stack.add_child(slider)
	var sound:=CheckButton.new();sound.text="Sound effects";sound.button_pressed=true;sound.toggled.connect(func(value):world.sound.enabled=value);stack.add_child(sound)
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
	weapon_label=label(null,Vector2(390,691),13,FortInterface.GOLD)
	weapon_label.size=Vector2(500,22);weapon_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func icon(parent: Control, kind: String, pos: Vector2, extent := 48.0) -> void:
	var glyph := FortIcon.new()
	glyph.kind=kind;glyph.position=pos;glyph.size=Vector2.ONE*extent
	glyph.tint=GameData.resource_color(kind) if kind in ["wood","stone","crystal"] else FortInterface.GOLD
	parent.add_child(glyph)

func _build_work_panels() -> void:
	for i in GameData.BUILD_ORDER.size():
		var card := panel(Vector2(804+(i%2)*226,174+int(i/2)*98),Vector2(216,96))
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
	damage.color.a=move_toward(damage.color.a,0,delta*0.8)
	if not is_instance_valid(world):return
	menu_scrim.visible=world.menu_open
	menu_scrim.color.a=.08 if world.castle and world.castle.menu.panel.visible else .6
	var p:FortPlayer=world.local_player()
	phase.text="%s %d  /  %02d:%02d"%["NIGHT" if world.is_night else "DAY",world.wave if world.is_night else world.wave+1,maxi(0,int(world.phase_time))/60,maxi(0,int(world.phase_time))%60]
	hearth.value=world.fort_health/world.fort_max_health*100
	economy.text="HEARTH T%d   %d / %d · SHARED"%[world.hearth_level,world.fort_health,world.fort_max_health]
	for kind in GameData.RESOURCES:stock_icons.get_node(kind+"/HBoxContainer/Text").text=str(world.shared.get(kind,0))
	if p:
		weapon_label.text="[C] %s   /   %s"%[GameData.weapon_title(p),"RMB aim / LMB fire" if GameData.ranged(p.weapon) else "Hold click to attack"]
		weapon_label.visible=not world.menu_open
		vitals.value=p.health/p.max_health*100
		pack.text="PACK %d / %d  |  %d HP%s\n%s"%[p.total_carried(),p.carry_limit,p.health," / IRONHEART" if p.armor else "",GameData.supplies_text(p.carrying,true)]
		pack.size=Vector2(306,54);pack.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		ability.text="[F] %s  %s"%[GameData.class_data(p.class_id).ability,("%.1fs"%p.ability_cooldown) if p.ability_cooldown>0 else "READY"]
		if p.travel_mode==2:ability.text+="   Fuel %.1fs"%p.fuel
		prompt.text=world.context_prompt(p)
		var direction:Vector3=-p.position
		compass.text="%s\nHEARTH %dm · %s"%[world.expedition.region_name(p.position),int(direction.length()),world.direction_to_home(p)]
		var trail:String=world.encounters.guidance(p.position)
		if not trail.is_empty():compass.text+="\n"+trail
		if p.health<=0:prompt.text="DOWNED · Ally hold E to revive · Rescue in %ds"%ceili(p.down_time)
		_update_work_panels(p)
	objective.text=world.objective_text()
	var entries:PackedStringArray=[]
	for dwarf in world.players.values():
		entries.append("%s  %s"%["●" if dwarf.health>0 else "✚",dwarf.display_name+"  "+str(int(dwarf.health))+" HP"])
	crew.text="THE CREW  /  %d of 4\n%s"%[entries.size(),"\n".join(entries)]
	notice.text=world.toast_text if world.toast_time>0 else ""
	build.position=Vector2(370,636);build.size=Vector2(880,25)
	build.text=""
	if world.local_build_mode:
		var reason:String=world.build_block_reason(GameData.BUILD_ORDER[world.selected_build],world.build_position,world.build_rotation)
		build.text="CLICK foundation / Q rotate / ends snap / HOLD E to build | "+("Clear placement" if reason.is_empty() else reason)
	map.queue_redraw()

func _update_work_panels(p: FortPlayer) -> void:
	var working:bool=world.local_build_mode and not world.menu_open and p.health>0
	hints.visible=not working
	for i in build_cards.size():
		var card:=build_cards[i]
		card.visible=working
		if not working:continue
		var selected:bool=i==world.selected_build
		if card.get_meta("selected",false)!=selected:
			card.add_theme_stylebox_override("panel",FortInterface.frame(selected))
			card.set_meta("selected",selected)
		var recipe:Dictionary=GameData.RECIPES[GameData.BUILD_ORDER[i]]
		var costs:PackedStringArray=[]
		var missing:PackedStringArray=[]
		for resource in GameData.RESOURCES:
			var cost:=ceili(int(recipe.get(resource,0))*(0.75 if p.class_id==2 else 1.0))
			if cost>0:costs.append("%d %s"%[cost,resource])
			if int(world.shared.get(resource,0))<cost:missing.append("%d%s"%[cost-int(world.shared.get(resource,0)),resource.left(1)])
		card_costs[i].text=" / ".join(costs)
		card_status[i].text=("ENGINEER PRICE" if p.class_id==2 else "SUPPLIES READY") if missing.is_empty() else "Need "+", ".join(missing)
		if world.hearth_level<int(recipe.get("tier",1)):card_status[i].text="REQUIRES HEARTH TIER %d"%recipe.tier
		card_status[i].add_theme_color_override("font_color",FortInterface.GOLD if missing.is_empty() else Color("#f0a58b"))
	var nearby:bool=p.position.distance_to(Vector3(4.6,0,0))<3.2
	stock_panel.visible=nearby and not working and not world.menu_open and p.health>0
	prompt.visible=not stock_panel.visible and not world.menu_open
	prompt.position.y=405 if working else 552
	if stock_panel.visible:
		stock_action.text="[ E ]  HOLD TO DEPOSIT ALL" if p.total_carried()>0 else "YOUR PACK IS EMPTY"
		stock_contents.text="YOUR PACK     %d wood   /   %d stone   /   %d crystal\nSHARED           %d wood   /   %d stone   /   %d crystal\nDeposited supplies pay for everyone's builds and repairs."%[p.carrying.wood,p.carrying.stone,p.carrying.crystal,world.shared.wood,world.shared.stone,world.shared.crystal]
		if world.hearth_level>1:stock_contents.text="YOUR PACK: "+GameData.supplies_text(p.carrying,true)+"\nSHARED: "+GameData.supplies_text(world.shared,true)
		stock_contents.size=Vector2(460,85);stock_contents.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var target:=8 if world.lifetime_crystal<8 else 20
		stock_progress.text="%s   /   %d of %d crystals deposited"%["HORSES" if target==8 else "JETPACKS",mini(world.lifetime_crystal,target),target]
		if world.lifetime_crystal>=20:stock_progress.text="CREW TRAVEL UNLOCKED   /   Press T to change gear"
		stock_meter.value=minf(100,float(world.lifetime_crystal)/target*100)

func _draw_map()->void:
	var map_scale:float=60.0/world.frontier_radius()
	map.draw_circle(Vector2.ZERO,64,Color(0.05,0.09,0.09,0.82))
	map.draw_arc(Vector2.ZERO,64,0,TAU,48,Color("#a38e69"),1.5,true)
	map.draw_rect(Rect2(-6,-6,12,12),Color("#e4b96f"),false,2)
	if world.is_night and world.director.active:
		for lane in world.director.lanes():
			var direction:=Vector2(sin(lane*PI/2),cos(lane*PI/2))
			var point:=direction*57
			var side:=direction.orthogonal()*4
			map.draw_colored_polygon(PackedVector2Array([point-direction*7,point+side,point-side]),Color("#ff9971"))
		map.draw_string(ThemeDB.fallback_font,Vector2(-4,-67),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#e4b96f"))
	for trail in FortLandscape.TRAILS:
		for i in range(trail.size()-1):map.draw_line(trail[i]*map_scale,trail[i+1]*map_scale,Color(0.75,0.65,0.42,0.55),1.2,true)
	for landmark in FortLandscape.LANDMARKS:
		var location:Vector3=landmark.pos
		var point:=Vector2(location.x,location.z)*map_scale
		map.draw_circle(point,5.0,Color("#17292b"))
		map.draw_arc(point,5.0,0,TAU,16,landmark.color,1.3,true)
		map.draw_string(ThemeDB.fallback_font,point+Vector2(-3,3.5),landmark.letter,HORIZONTAL_ALIGNMENT_LEFT,-1,9,landmark.color)
	for resource in world.resource_nodes.values():
		if resource.amount>0:
			var pos:Vector3=resource.node.position
			map.draw_circle(Vector2(pos.x,pos.z)*map_scale,1.7,GameData.resource_color(resource.kind).darkened(0.1))
	for enemy in world.enemies.values():
		if FortEncounters.is_wild(int(enemy.get("camp",-1))):continue
		var pos:Vector3=enemy.node.position
		map.draw_circle(Vector2(pos.x,pos.z)*map_scale,2,Color("#df7160"))
	for site in world.encounters.sites.values():
		if not site.seen:continue
		var point:=Vector2(site.spec.pos.x,site.spec.pos.z)*map_scale
		var color:Color=Color("#759689") if site.phase=="claimed" else FortEncounters.COLORS[site.spec.type]
		if site.phase=="claimed":map.draw_rect(Rect2(point-Vector2.ONE*2.5,Vector2.ONE*5),color,false,1)
		else:map.draw_rect(Rect2(point-Vector2.ONE*2.5,Vector2.ONE*5),color)
	for p in world.players.values():
		map.draw_circle(Vector2(p.position.x,p.position.z)*map_scale,3.4,GameData.class_data(p.class_id).color.lightened(0.3))
