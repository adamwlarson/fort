class_name FortSaveMenu
extends CanvasLayer
var main:Node
var panel:PanelContainer
var slots:VBoxContainer
var note:Label
var saving:=false
var confirm_slot:=""
var scrim:ColorRect
func _ready()->void:
	scrim=ColorRect.new();scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scrim.hide();add_child(scrim)
	layer=30;panel=PanelContainer.new();add_child(panel);panel.position=Vector2(240,125);panel.size=Vector2(800,510);panel.theme=FortInterface.theme()
	panel.visibility_changed.connect(func():scrim.visible=panel.visible)
	var style:=FortInterface.frame(true);style.set_content_margin_all(22);panel.add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",12);panel.add_child(stack)
	note=Label.new();note.custom_minimum_size=Vector2(745,65);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(note)
	slots=VBoxContainer.new();slots.add_theme_constant_override("separation",10);stack.add_child(slots)
	var close:=Button.new();close.text="BACK / ESC";close.pressed.connect(close_panel);stack.add_child(close);panel.hide()
func open_panel(save_mode:bool)->void:
	if save_mode and (not main.multiplayer.is_server() or not is_instance_valid(main.world)):return
	if not save_mode and (is_instance_valid(main.world) or main.lobby_active or main.connecting):return
	saving=save_mode;confirm_slot="";panel.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	scrim.color=Color(0,0,0,0 if saving else .45)
	if saving:main.world.menu_open=true;main.world.hud.menu.hide()
	refresh()
	panel.size.y=510 if not saving else 375
func refresh()->void:
	for child in slots.get_children():slots.remove_child(child);child.queue_free()
	note.text="SAVE EXPEDITION / HOST ONLY\nThe crew keeps playing. Click an occupied slot twice to overwrite it." if saving else "LOAD EXPEDITION\nOpens a host lobby. Select your previous dwarf class on the title screen."
	for i in FortSave.SLOTS.size():
		var slot:String=FortSave.SLOTS[i]
		if saving and i>=3:continue
		var result:=FortSave.read_slot(slot);var button:=Button.new();button.custom_minimum_size.y=56;slots.add_child(button)
		button.text=FortSave.LABELS[i]+" / "+("EMPTY" if result.error=="Empty slot" else result.error)
		if result.error=="":
			var data:Dictionary=result.data
			button.text="%s / %s %d / Hearth %d / %d rooms\n%s%s"%[FortSave.LABELS[i],"Night" if data.world.night else "Day",int(data.world.wave)+(0 if data.world.night else 1),data.world.hearth_level,data.world.castle.rooms.size(),data.saved_at," / BACKUP RECOVERY" if result.get("recovered",false) else ""]
		if confirm_slot==slot:button.text="CONFIRM OVERWRITE / "+FortSave.LABELS[i]
		button.disabled=not saving and result.error!=""
		button.pressed.connect(func():choose(slot))
func choose(slot:String)->void:
	if saving:
		if (FileAccess.file_exists(FortSave.path(slot)) or FileAccess.file_exists(FortSave.path(slot)+".bak")) and confirm_slot!=slot:confirm_slot=slot;refresh();return
		if main.world.save_expedition(slot):confirm_slot="";refresh();note.text=main.world.save_status
		else:note.text=main.world.save_status
	else:close_panel();main.load_expedition(slot)
func close_panel()->void:
	panel.hide()
	if saving and is_instance_valid(main.world):main.world.hud.menu.show();main.world.menu_open=true
func _unhandled_input(event:InputEvent)->void:
	if panel.visible and event.is_action_pressed("cancel"):
		close_panel();get_viewport().set_input_as_handled()
