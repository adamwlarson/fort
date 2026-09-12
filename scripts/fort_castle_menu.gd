class_name FortCastleMenu
extends CanvasLayer
var castle:FortCastle
var panel:PanelContainer
var detail:Label
var choices:OptionButton
var kinds:OptionButton
var stack:VBoxContainer
var target:=""
var anchor:=""
var planner:FortCastlePlanner
var options:Array=[]
var ghost:Node3D
var last_revision:=-1
var services:VBoxContainer
var plan_button:Button
var fund_button:Button
var wall_button:Button
var cancel_button:Button
var confirming_cancel:=false
var mode:OptionButton
var remodel_button:Button
var confirmation:=""
var overview:Camera3D
var previous_camera:Camera3D
var refresh_clock:=0.0
var guidance:Label
var placement_status:Label
func _ready()->void:
	layer=12;panel=PanelContainer.new();add_child(panel);panel.position=Vector2(30,75);panel.size=Vector2(550,600);panel.theme=FortInterface.theme()
	var style:=FortInterface.frame(true);style.set_content_margin_all(20);panel.add_theme_stylebox_override("panel",style)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(550,560);panel.add_child(scroll)
	stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",10);scroll.add_child(stack)
	detail=Label.new();detail.custom_minimum_size=Vector2(510,160);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(detail)
	mode=OptionButton.new();stack.add_child(mode)
	for text in ["EXPAND / Add a connected room","REMODEL / Change this room","DISMANTLE / Remove this room"]:mode.add_item(text)
	mode.item_selected.connect(func(_i):confirmation="";refresh_preview();update_guidance())
	choices=OptionButton.new();stack.add_child(choices);kinds=OptionButton.new();stack.add_child(kinds)
	for kind in FortCastle.TYPES:kinds.add_item(FortCastle.TYPES[kind].name)
	choices.item_selected.connect(func(_i):confirmation="";refresh_preview();update_guidance());kinds.item_selected.connect(func(_i):confirmation="";refresh_preview();update_guidance())
	placement_status=Label.new();placement_status.name="PlacementStatus";placement_status.custom_minimum_size.x=510;placement_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(placement_status)
	plan_button=button(stack,"PLACE SELECTED WING BLUEPRINT",place_selected)
	remodel_button=button(stack,"BEGIN REMODELING PROJECT",func():
		var next_kind:String="" if mode.selected==2 else FortCastle.TYPES.keys()[kinds.selected]
		var token:=str([target,next_kind,castle.revision])
		if confirmation!=token:confirmation=token;remodel_button.text="CONFIRM / START HAND-BUILT PROJECT";return
		send("castle_remodel",{"kind":next_kind});confirmation="")
	fund_button=button(stack,"ADD SUPPLIES FROM SHARED STOCKPILE",func():send("castle_fund",{"shared":true}))
	wall_button=button(stack,"ADD CURTAIN WALL PROJECT / 40 wood, 100 stone",func():send("castle_task",{"task":"walls"}))
	services=VBoxContainer.new();stack.add_child(services)
	cancel_button=button(stack,"CANCEL PROJECT / REFUND UNUSED MATERIALS",func():
		if not confirming_cancel:confirming_cancel=true;cancel_button.text="CONFIRM CANCEL / REFUND UNUSED MATERIALS";return
		send("castle_cancel");confirming_cancel=false)
	button(stack,"RETURN TO BUILD / HOLD E AT THE SIGN",close_panel)
	var help_panel:=PanelContainer.new();help_panel.name="CastleHelp";help_panel.position=Vector2(650,90);help_panel.size=Vector2(600,115);help_panel.theme=FortInterface.theme();add_child(help_panel)
	var help_style:=FortInterface.frame(true);help_style.set_content_margin_all(12);help_panel.add_theme_stylebox_override("panel",help_style)
	guidance=Label.new();guidance.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;guidance.custom_minimum_size=Vector2(565,80);help_panel.add_child(guidance)
	panel.visibility_changed.connect(func():help_panel.visible=panel.visible)
	planner=FortCastlePlanner.new();planner.menu=self;add_child(planner)
	panel.visibility_changed.connect(func():planner.visible=panel.visible)
	panel.hide()
func button(parent:Node,title:String,action:Callable)->Button:
	var b:=Button.new();b.text=title;parent.add_child(b);b.pressed.connect(action);return b
func place_selected()->void:
	if plan_button.disabled:return
	if choices.selected<0 or choices.selected>=options.size():return
	var option:Dictionary=options[choices.selected];var kind:String=FortCastle.TYPES.keys()[kinds.selected]
	var info:=FortCastleClearance.inspect(castle,option)
	var token:=str(["clear",target,kind,castle.revision,info.token])
	if not info.defenses.is_empty() and confirmation!=token:
		confirmation=token;refresh_preview();return
	send("castle_plan",{"from":target,"target":option,"kind":kind,"clearance_token":info.token});confirmation=""
func send(action:String,data:Dictionary={})->void:
	if not at_selected_sign():castle.world.show_toast("Walk to this room's sign first. Use MARK SELECTED ROOM'S SIGN to find it.");return
	var payload:=data.duplicate(true);payload.merge({"key":target,"revision":castle.revision},true);castle.world.request_action(action,payload)
func open_nearest()->void:
	var w:=castle.world;var p:=w.local_player()
	if w.menu_open or w.ended or not p:return
	target=castle.nearest(p.position)
	if target=="":w.show_toast("Stand beside a castle signpost and press K.");return
	anchor=target;planner.floor_index=int(castle.rooms[target].floor);planner.selected=target;planner.required=""
	w.menu_open=true;panel.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;last_revision=-1;confirming_cancel=false;confirmation="";mode.select(0)
	previous_camera=w.get_viewport().get_camera_3d();overview=Camera3D.new();w.add_child(overview);overview.far=800;overview.current=true;refresh()
func close_panel()->void:
	panel.hide();castle.world.menu_open=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(ghost):ghost.queue_free();ghost=null
	if is_instance_valid(overview):overview.queue_free();overview=null
	if is_instance_valid(previous_camera):previous_camera.current=true
func _process(delta:float)->void:
	if not panel.visible:return
	panel.size.y=minf(600,castle.world.get_viewport().get_visible_rect().size.y-95)
	(panel.get_child(0) as ScrollContainer).custom_minimum_size.y=panel.size.y-40
	var p:=castle.world.local_player()
	if not p or not castle.rooms.has(anchor) or p.health<=0 or p.position.distance_to(castle.rooms[anchor].sign)>4 or castle.world.ended:close_panel();return
	if not castle.rooms.has(target):target=anchor
	if last_revision!=castle.revision:confirmation="";refresh()
	refresh_clock+=delta
	if refresh_clock>.5:refresh_clock=0;refresh_preview();update_guidance()
func refresh()->void:
	var old_choice:=choices.selected
	last_revision=castle.revision;options=castle.candidates(target);choices.clear()
	for option in options:choices.add_item(option.label)
	if not options.is_empty():choices.select(clampi(old_choice,0,options.size()-1))
	for child in services.get_children():services.remove_child(child);child.queue_free()
	var r:Dictionary=castle.rooms[target]
	fund_button.disabled=r.task=="" or not castle.needs_supplies(r)
	wall_button.disabled=not r.complete or r.task!=""
	for id in r.walls:
		if castle.world.defenses.has(id):wall_button.disabled=true
	cancel_button.disabled=r.task=="";cancel_button.text="CANCEL PROJECT / REFUND UNUSED MATERIALS";confirming_cancel=false
	if r.complete and r.kind=="Merchant":
		for resource in ["wood","stone","iron","crystal"]:
			var prices:={"wood":"8 stone > 5 wood","stone":"8 wood > 5 stone","iron":"20 wood + 10 stone > 2 iron","crystal":"15 wood + 15 stone > 2 crystal"}
			button(services,"TRADE / "+prices[resource],func():send("castle_trade",{"resource":resource}))
	if r.complete and r.kind=="Gatherers":
		var choice:=OptionButton.new();services.add_child(choice)
		for resource in GameData.RESOURCES:choice.add_item("GATHER / "+resource)
		choice.select(GameData.RESOURCES.find(r.resource));choice.item_selected.connect(func(i):send("castle_assign",{"resource":GameData.RESOURCES[i]}))
	if r.complete and r.kind=="Research":
		for tech in FortCastle.TECH:
			if tech not in castle.research:
				var b:=button(services,tech+" / "+GameData.supplies_text(FortCastle.TECH[tech].cost,true),func():send("castle_task",{"task":"tech:"+tech}));b.tooltip_text=FortCastle.TECH[tech].desc;b.disabled=r.task!=""
	refresh_preview()
	update_guidance()
func update_guidance()->void:
	if not castle.rooms.has(target):return
	var r:Dictionary=castle.rooms[target]
	guidance.modulate=Color("#f0d59d")
	if r.task!="":
		if castle.needs_supplies(r):guidance.text="STEP 2 / SUPPLY THIS PROJECT\nStill needed: "+GameData.supplies_text(castle.remaining(r),true)+"\nClose K and HOLD E: uses shared stock first, then your pack. Keep holding to build."
		else:guidance.text="STEP 3 / BUILD IT — THE BLUEPRINT IS NOT FINISHED\nClose this menu and HOLD E beside this project's sign until 100%. Other choices unlock when this project is finished or canceled."
		return
	if mode.selected!=0:guidance.text="CHANGE A COMPLETED ROOM\nClear its defenses first. Select the new purpose, confirm twice, then supply and HOLD E at the sign to perform the work.";return
	if options.is_empty():guidance.text="NO OPEN CONNECTION AT THIS SIGN\nWalk to the sign on a completed OUTER room and press K to expand from there. Upper rooms need a stairwell below.";return
	var kind:String=FortCastle.TYPES.keys()[kinds.selected]
	for i in kinds.item_count:
		var spec:Dictionary=FortCastle.TYPES[FortCastle.TYPES.keys()[i]]
		kinds.set_item_text(i,spec.name+(" / HEARTH %d"%spec.tier if castle.world.hearth_level<int(spec.tier) else ""))
	for i in options.size():
		var why:=castle.plan_reason(target,options[i],kind)
		var status:="READY" if why=="" else "LOCKED - see requirement below"
		if why!="" and options[i].floor>0 and castle.completed_ground()<4:status="%d/4 ground wings complete"%castle.completed_ground()
		choices.set_item_text(i,options[i].label+" / "+status);choices.set_item_tooltip(i,why)
	var reason:=castle.plan_reason(target,options[choices.selected],kind) if choices.selected>=0 else "Choose a direction"
	if reason!="":
		guidance.modulate=Color("#f3a58b");guidance.text="WHY THIS OPTION IS LOCKED\n"+reason+"\nTrees and loose rocks clear automatically; protected sites and structural limits still apply."
	else:guidance.text="STEP 1 / PLACE A BLUEPRINT\nTrees and loose scenery clear automatically. Review the salvage summary before confirming defense removal. Then HOLD E at the new sign to supply and build."
func refresh_preview()->void:
	_refresh_preview()
	if not at_selected_sign():
		for b in [plan_button,remodel_button,fund_button,wall_button,cancel_button]:b.disabled=true
		for child in services.get_children():if child is BaseButton:child.disabled=true
		placement_status.show();placement_status.text+="\nINSPECTING REMOTELY / Walk to this room's sign to build or change it. Use the map's MARK SIGN button."
	planner.refresh()
func at_selected_sign()->bool:
	return castle.authorized(castle.world.multiplayer.get_unique_id(),target)
func inspect_room(key:String)->void:
	if not castle.rooms.has(key):return
	target=key;confirmation="";mode.select(0);choices.select(-1);refresh()
func _refresh_preview()->void:
	if is_instance_valid(ghost):ghost.queue_free();ghost=null
	var r:Dictionary=castle.rooms[target]
	plan_button.disabled=true
	placement_status.hide();placement_status.text=""
	detail.text="CASTLE ARCHITECT / STOREY %d\n%d rooms / %d completed ground wings (4 unlock upstairs)\nChoose a direction and purpose. Supply the sign, then HOLD E to build.\n"%[int(r.floor)+1,castle.rooms.size(),castle.completed_ground()]
	if r.task!="":detail.text+="PROJECT: %s / %d%%\nStill needed: %s\n"%[r.task,int(100*r.work/maxf(1,r.total)),GameData.supplies_text(castle.remaining(r),true)]
	if r.task!="":detail.text+="Delivered: "+GameData.supplies_text(r.funded,true)+"\n"
	if r.kind=="Gatherers":detail.text+="First 4 lodges staffed: 2 nearby resources / 12s in daylight.\n"
	choices.visible=mode.selected==0;kinds.visible=mode.selected!=2;plan_button.visible=mode.selected==0;remodel_button.visible=mode.selected!=0
	var focus:=FortCastle.position(r)
	mode.disabled=r.task!="";services.visible=r.task==""
	if r.task!="":
		choices.hide();kinds.hide();plan_button.hide();remodel_button.hide()
		var planned_kind:String=r.get("remodel_kind",r.kind)
		if planned_kind in FortCastle.TYPES:
			detail.text+="Target: "+FortCastle.TYPES[planned_kind].name+"\n"
			ghost=FortCastlePreview.make(castle,r,planned_kind,true);castle.world.add_child(ghost)
		if r.task in ["remodel","dismantle"]:
			detail.text+="Recovery on completion: "+GameData.supplies_text(FortCastleRemodel.refund(r),true)+"\n"
			var blocked:=FortCastleRemodel.reason(castle,target,r.get("remodel_kind",""),castle.world.multiplayer.get_unique_id())
			if blocked!="":detail.text+="WORK PAUSED: "+blocked
		position_camera(focus);return
	if mode.selected!=0:
		var next_kind:String="" if mode.selected==2 else FortCastle.TYPES.keys()[kinds.selected]
		var why:=FortCastleRemodel.reason(castle,target,next_kind,castle.world.multiplayer.get_unique_id())
		if r.task!="":why="Finish or cancel the current project first"
		remodel_button.disabled=why!=""
		remodel_button.text="CONFIRM / START HAND-BUILT PROJECT" if confirmation!="" else ("BEGIN DISMANTLING PROJECT" if next_kind=="" else "BEGIN REMODELING PROJECT")
		detail.text+="Recovered AFTER completion: "+GameData.supplies_text(FortCastleRemodel.refund(r),true)+"\n"
		if next_kind!="":detail.text+="New room cost: "+GameData.supplies_text(FortCastle.TYPES[next_kind].cost,true)+"\n"
		detail.text+=("READY / Daylight work. Dismantling returns the worker to the keep." if why=="" else why)
		if next_kind!="":ghost=FortCastlePreview.make(castle,r,next_kind,why=="");castle.world.add_child(ghost)
		position_camera(focus);return
	position_camera(focus)
	if choices.selected<0 or choices.selected>=options.size():return
	var kind:String=FortCastle.TYPES.keys()[kinds.selected];var data:Dictionary=FortCastle.TYPES[kind];var option:Dictionary=options[choices.selected]
	var reason:=castle.plan_reason(target,option,kind)
	var info:=FortCastleClearance.inspect(castle,option)
	var token:=str(["clear",target,kind,castle.revision,info.token])
	plan_button.text="CONFIRM / CLEAR DEFENSES & PLACE WING" if not info.defenses.is_empty() and confirmation==token else ("REVIEW CLEARANCE & PLACE WING" if not info.defenses.is_empty() else "PLACE WING / AUTO-CLEAR RESOURCES")
	plan_button.disabled=reason!=""
	placement_status.show();placement_status.modulate=Color("#a9d99a") if reason=="" else Color("#f3a58b")
	placement_status.text="READY TO PLACE" if reason=="" else "REQUIRED BEFORE PLACING\n"+reason
	if int(option.floor)>0 and reason=="":placement_status.text+="\nGround wings: %d/4 complete (keep excluded). Finished support below verified."%castle.completed_ground()
	detail.text+=data.desc+"\nCost: "+GameData.supplies_text(data.cost,true)
	if not info.defenses.is_empty() or not info.resources.is_empty() or not info.scenery.is_empty():detail.text+="\n"+FortCastleClearance.summary(info)
	ghost=FortCastlePreview.make(castle,option,kind,reason=="");castle.world.add_child(ghost);position_camera(FortCastle.position(option))
func position_camera(focus:Vector3)->void:
	if not is_instance_valid(overview):return
	overview.position=focus+Vector3(-12,31,23);overview.look_at(focus+Vector3(-12,0,0))
