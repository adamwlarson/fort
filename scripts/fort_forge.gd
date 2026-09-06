class_name FortForge
extends PanelContainer

var world:FortWorld
var supply:Label
var feedback:Label
var buttons:Array[Button]=[]
var costs:Array[Label]=[]
var pack_buttons:Array[Button]=[]
var relic_label:Label
var tabs:TabContainer
var weapon_upgrade_buttons:Array[Button]=[]

func _ready()->void:
	position=Vector2(185,80);size=Vector2(910,440)
	theme=FortInterface.theme()
	var style:=FortInterface.frame(true)
	style.set_content_margin_all(22)
	add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",12);add_child(stack)
	var heading:=Label.new();heading.text="THE WORKSHOP  /  WEAPONS & EQUIPMENT";heading.add_theme_font_size_override("font_size",25);stack.add_child(heading)
	supply=Label.new();supply.add_theme_color_override("font_color",FortInterface.GOLD);stack.add_child(supply)
	tabs=TabContainer.new();stack.add_child(tabs)
	var weapon_tabs:=TabContainer.new();weapon_tabs.name="Weapons";tabs.add_child(weapon_tabs)
	var row:HBoxContainer
	for kind in GameData.WEAPON_ORDER:
		if GameData.WEAPON_ORDER.find(kind)%3==0:
			row=HBoxContainer.new();row.name=["Field Tools","Iron Arsenal","Siege Weapons","Runic Arsenal"][int(GameData.WEAPON_ORDER.find(kind)/3)];row.add_theme_constant_override("separation",14);weapon_tabs.add_child(row)
		var recipe:Dictionary=GameData.WEAPONS[kind]
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(278,270);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var card_style:=FortInterface.frame();card_style.set_content_margin_all(14);card.add_theme_stylebox_override("panel",card_style);row.add_child(card)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",8);card.add_child(content)
		var icon:=FortIcon.new();icon.kind=kind;icon.custom_minimum_size=Vector2(48,48);content.add_child(icon)
		var title:=Label.new();title.text=recipe.name;title.add_theme_font_size_override("font_size",19);content.add_child(title)
		var desc:=Label.new();desc.text=recipe.desc;desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.custom_minimum_size.y=78;desc.add_theme_font_size_override("font_size",13);desc.modulate=FortInterface.MUTED;content.add_child(desc)
		var cost:=Label.new();cost.add_theme_font_size_override("font_size",13);cost.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cost.custom_minimum_size.y=34;content.add_child(cost);costs.append(cost)
		var button:=Button.new();button.custom_minimum_size.y=40;content.add_child(button);buttons.append(button)
		button.pressed.connect(func():
			var p:=world.local_player()
			if p:world.request_action("equip_weapon" if kind in p.owned_weapons else "craft_weapon",{"weapon":kind}))
		var reinforce:=Button.new();reinforce.custom_minimum_size.y=36;content.add_child(reinforce);weapon_upgrade_buttons.append(reinforce)
		reinforce.pressed.connect(func():
			var p:=world.local_player()
			if p:world.request_action("upgrade_weapon",{"weapon":kind,"level":int(p.weapon_levels.get(kind,1))}))
	var packs:=VBoxContainer.new();packs.name="Backpacks and Relics";packs.add_theme_constant_override("separation",16);tabs.add_child(packs)
	for i in 2:
		var spec:Dictionary=GameData.BACKPACKS[i]
		var desc:=Label.new();desc.text="%s / +%d carry slots\nShared cost: %s"%[spec.name,spec.bonus,GameData.supplies_text(spec,true)];packs.add_child(desc)
		var button:=Button.new();button.custom_minimum_size.y=46;button.pressed.connect(func():world.request_action("craft_pack",{"level":i}));packs.add_child(button);pack_buttons.append(button)
	relic_label=Label.new();relic_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;relic_label.custom_minimum_size=Vector2(820,80);packs.add_child(relic_label)
	var pets:=FortPetMenu.new();pets.name="Gathering Pets";pets.world=world;tabs.add_child(pets)
	feedback=Label.new();feedback.custom_minimum_size.y=22;feedback.add_theme_font_size_override("font_size",13);feedback.modulate=FortInterface.GOLD;stack.add_child(feedback)
	var close:=Button.new();close.text="RETURN TO THE CREW   /   ESC";close.pressed.connect(world.toggle_pause);stack.add_child(close)
	hide()

func _process(_delta:float)->void:
	if not visible:return
	var p:=world.local_player()
	if not p:return
	if p.health<=0 or p.position.distance_to(Vector3(-4.6,0,0))>3.5:
		world.toggle_pause();return
	supply.text="SHARED: "+GameData.supplies_text(world.shared,true)
	for i in 2:
		var spec:Dictionary=GameData.BACKPACKS[i]
		var allowed:bool=p.backpack_level==i and (i==0 or world.hearth_level>=2)
		for resource in GameData.RESOURCES:
			if int(world.shared.get(resource,0))<int(spec.get(resource,0)):allowed=false
		pack_buttons[i].disabled=not allowed
		pack_buttons[i].text="OWNED" if p.backpack_level>i else ("CRAFT & EQUIP" if allowed else "NEED PREVIOUS PACK / SUPPLIES / HEARTH")
	relic_label.text="CREW RELICS: "+(", ".join(p.relics) if not p.relics.is_empty() else "Discover guarded camps and hidden chests.")+"\nEmbermaul: +28 hammer damage / longer stun. Stormstring: 80 bolt damage.\nIronheart: +40 maximum health and 20% damage reduction.\nRelics stay for this run and are awarded to every crew member."
	feedback.text=world.toast_text if world.toast_time>0 else "Fixed weapon prices for every class. Press C outside the workshop to switch owned weapons."
	for i in GameData.WEAPON_ORDER.size():
		var kind:String=GameData.WEAPON_ORDER[i]
		var recipe:Dictionary=GameData.WEAPONS[kind]
		var owned:bool=kind in p.owned_weapons
		var missing:PackedStringArray=[]
		for resource in GameData.RESOURCES:
			if int(world.shared.get(resource,0))<int(recipe.get(resource,0)):missing.append("%d %s"%[int(recipe.get(resource,0))-int(world.shared.get(resource,0)),resource])
		costs[i].text="OWNED / No cost to re-equip" if owned else GameData.supplies_text(recipe,true)
		buttons[i].text="EQUIPPED" if p.weapon==kind else ("EQUIP" if owned else ("CRAFT & EQUIP" if missing.is_empty() else "NEED SUPPLIES"))
		buttons[i].tooltip_text="Missing "+", ".join(missing) if not owned and not missing.is_empty() else ""
		buttons[i].disabled=p.weapon==kind or (not owned and not missing.is_empty())
		if not owned and world.hearth_level<int(recipe.get("tier",1)):
			buttons[i].text="HEARTH TIER %d REQUIRED"%int(recipe.tier);buttons[i].disabled=true
		var level:int=p.weapon_levels.get(kind,1)
		var cost:=GameData.weapon_upgrade_cost(level)
		var allowed:bool=owned and level<GameData.MAX_GEAR_LEVEL and world.hearth_level>=level+1
		for resource in cost:
			if int(world.shared.get(resource,0))<int(cost[resource]):allowed=false
		weapon_upgrade_buttons[i].disabled=not allowed
		weapon_upgrade_buttons[i].text="LEVEL 8 / MASTERWORK" if level>=GameData.MAX_GEAR_LEVEL else "REINFORCE TO LEVEL %d"%[level+1]
		weapon_upgrade_buttons[i].tooltip_text="+25%% base damage per level. Requires owned weapon, Hearth tier %d and %s"%[level+1,GameData.supplies_text(cost,true)]
