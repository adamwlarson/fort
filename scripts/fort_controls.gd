class_name FortControls
extends PanelContainer

var hud:FortHUD
func _ready()->void:
	name="ControlsPanel";position=Vector2(300,80);size=Vector2(680,560);theme=FortInterface.theme()
	var box:=VBoxContainer.new();add_child(box)
	var title:=Label.new();title.text="CONTROLS";title.add_theme_font_size_override("font_size",24);box.add_child(title)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(640,450);box.add_child(scroll)
	var text:=Label.new();text.custom_minimum_size.x=610;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.text="CHARACTER & MAP
TAB: character sheet (gear, level, spend stat points)
M: map size (standard, wide, region, whole world, off)

MOVE\nWASD: walk   Mouse: camera / aim   Shift: sprint\nSpace: jump / hold for jetpack   T: cycle travel gear\n\nCOMBAT\nHold left click: attack / fire   Right click: aim ranged weapons\nMouse wheel or C: switch owned weapons   F: class ability\nE at ballista: mount / dismount   Left click: fire\n\nGATHER & BUILD\nHold E: gather, deposit, revive, supply and build projects\nHold R: repair nearby defenses or hearth\nB: build mode   1–9 / 0: select   Page Up/Down: build page\nMouse wheel in build mode: select defense   Q: rotate\nLeft click: place   Esc: cancel placement\nG near a defense: upgrade, salvage or gate options\n\nCASTLE & SERVICES\nK beside a sign: rooms, upgrades, walls and floor plans\nCastle map: wheel to zoom, middle mouse to pan\nE at workshop: weapons, packs and pets\nE at merchant tent: buy / sell resources for shared gold\nU beside hearth: upgrade   E at chest: claim treasure\nDoors open automatically for nearby crew and pets\nM: toggle resource patches on minimap\n\nEXPEDITION\nEnter: vote to begin night   Esc: camp menu / close menu\nCamp menu: save (host), settings, controls and safe recovery"
	scroll.add_child(text)
	var back:=Button.new();back.text="BACK TO CAMP MENU / ESC";back.pressed.connect(close_panel);box.add_child(back);hide()
func open_panel()->void:show();hud.menu.hide()
func close_panel()->void:hide();hud.menu.show()
