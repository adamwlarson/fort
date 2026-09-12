class_name FortUpgradeMenu
extends PanelContainer
var world:FortWorld
var target:=-1
var detail:Label
var upgrade:Button
var cancel:Button
var gate_auto:CheckButton
var gate_toggle:Button
var confirming:=false
func _ready()->void:
	position=Vector2(390,230);size=Vector2(500,255);theme=FortInterface.theme()
	var style:=FortInterface.frame(true);style.set_content_margin_all(24);add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",16);add_child(stack)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size=Vector2(450,125);stack.add_child(detail)
	upgrade=Button.new();upgrade.text="UPGRADE";upgrade.pressed.connect(func():
		if world.defenses.has(target):world.request_action("upgrade_defense",{"id":target,"level":world.defenses[target].get("level",1)}))
	stack.add_child(upgrade)
	gate_toggle=Button.new();stack.add_child(gate_toggle)
	gate_toggle.pressed.connect(func():
		if world.defenses.has(target):world.request_action("gate",{"id":target,"revision":world.defenses[target].get("gate_revision",0)}))
	gate_auto=CheckButton.new();gate_auto.text="Close automatically at dusk";stack.add_child(gate_auto)
	gate_auto.tooltip_text="Attempt closure at the next dusk. Occupied passages reopen safely; tap E again after clearing them. Manual opening overrides this for the current night."
	gate_auto.toggled.connect(func(value:bool):
		if world.defenses.has(target):world.request_action("gate",{"id":target,"revision":world.defenses[target].get("gate_revision",0),"auto":value}))
	cancel=Button.new();cancel.text="CANCEL PROJECT / REFUND UNUSED MATERIALS";stack.add_child(cancel)
	cancel.pressed.connect(func():
		if not confirming:confirming=true;return
		if world.defenses.has(target):world.request_action("cancel_construction" if FortConstruction.pending(world.defenses[target]) else "salvage_defense",{"id":target,"revision":world.defenses[target].get("work_revision",0)})
		confirming=false)
	var close:=Button.new();close.text="BACK / ESC";close.pressed.connect(close_panel);stack.add_child(close);hide()
func open_nearest()->void:
	if world.menu_open or world.ended:return
	target=world._nearest_defense(world.local_player().position,"",4)
	confirming=false
	if target<0:world.show_toast("Stand beside a defense and press G to upgrade.");return
	world.menu_open=true;show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func close_panel()->void:
	hide();world.menu_open=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _process(_delta:float)->void:
	if not visible:return
	var p:=world.local_player()
	if not world.defenses.has(target) or not p or p.health<=0 or p.position.distance_to(world.defenses[target].node.position)>4 or world.ended:close_panel();return
	var d:Dictionary=world.defenses[target];var level:int=d.get("level",1)
	gate_auto.visible=d.kind=="Gatehouse";gate_toggle.visible=gate_auto.visible
	gate_auto.disabled=FortConstruction.pending(d);gate_toggle.disabled=gate_auto.disabled
	gate_auto.set_pressed_no_signal(bool(d.get("gate_auto",false)))
	gate_toggle.text=("CLOSE GATE" if float(d.get("gate_target",1))>0 else "OPEN GATE")+" / "+FortGates.title(d)
	position.y=155 if gate_auto.visible else 230
	var cost:=world.progression.upgrade_cost(target)
	cancel.visible=not d.temporary
	cancel.disabled=p.peer_id not in [1,int(d.get("work_owner",0))] if FortConstruction.pending(d) else world.is_night
	cancel.text="CONFIRM CANCEL / RETURN UNUSED SUPPLIES" if confirming else "CANCEL PROJECT / REFUND UNUSED MATERIALS"
	if FortConstruction.pending(d):
		detail.text="%s / %s %d%%\nClose this panel and HOLD E to work.\nAny crew member can help. Engineers work twice as fast.\nUnused supplies: %s"%[d.kind,str(d.work_kind).to_upper(),int(FortConstruction.fraction(d)*100),GameData.supplies_text(world.construction.refund(d),true)]
		upgrade.text="WORK IN PROGRESS";upgrade.disabled=true;return
	cancel.text="CONFIRM SALVAGE / REMOVE BUILDING" if confirming else "SALVAGE / "+GameData.supplies_text(world.construction.salvage_refund(d),true)
	cancel.tooltip_text="Daylight only, no nearby enemies or mounted dwarf. Returns 50% of paid materials, scaled by remaining health."
	detail.text="%s / LEVEL %d\n%d / %d health\nUpgrade: +65%% base health, +40%% base effectiveness.\nRequires Hearth tier %d.\nShared cost: %s"%[d.kind,level,d.hp,d.max_hp,level+1,GameData.supplies_text(cost,true)]
	if FortPlacement.is_wall(d.kind):detail.text=detail.text.replace(", +40% base effectiveness","")
	else:detail.text+="\nCoverage: %dm > %dm"%[GameData.defense_radius(d.kind,level),GameData.defense_radius(d.kind,mini(GameData.MAX_GEAR_LEVEL,level+1))]
	if level>=GameData.MAX_GEAR_LEVEL:detail.text="%s / LEVEL %d\n%d / %d health\nFully reinforced. Hold R nearby to repair damage."%[d.kind,level,d.hp,d.max_hp]
	upgrade.disabled=level>=GameData.MAX_GEAR_LEVEL or d.temporary or world.hearth_level<level+1
	for kind in cost:
		if int(world.shared.get(kind,0))<cost[kind]:upgrade.disabled=true
	upgrade.text="MAXIMUM LEVEL" if level>=GameData.MAX_GEAR_LEVEL else ("TEMPORARY TURRET" if d.temporary else "UPGRADE WITH SHARED SUPPLIES")
