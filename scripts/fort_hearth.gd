class_name FortHearth
extends PanelContainer

var world:FortWorld
var detail:Label
var upgrade:Button
var boons:Dictionary={}

func _ready()->void:
	position=Vector2(340,110);size=Vector2(600,500);theme=FortInterface.theme()
	var style:=FortInterface.frame(true);style.set_content_margin_all(25);add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",16);add_child(stack)
	var title:=Label.new();title.text="FEED THE HEARTH / EXPAND THE FRONTIER";title.add_theme_font_size_override("font_size",22);stack.add_child(title)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size=Vector2(540,145);stack.add_child(detail)
	upgrade=Button.new();upgrade.custom_minimum_size.y=46;upgrade.pressed.connect(func():world.request_action("upgrade_hearth",{"level":world.hearth_level}));stack.add_child(upgrade)
	# Fort 31: boons bought with each biome's own material.
	var heading:=Label.new();heading.name="BoonHeading";heading.text="ATTUNE THE HEARTH / permanent crew boons from biome materials";heading.add_theme_font_size_override("font_size",13);heading.add_theme_color_override("font_color",FortInterface.GOLD);stack.add_child(heading)
	var list:=VBoxContainer.new();list.add_theme_constant_override("separation",4);stack.add_child(list)
	for kind in GameData.RARE:
		var boon:=Button.new();boon.alignment=HORIZONTAL_ALIGNMENT_LEFT;boon.custom_minimum_size.y=30;boon.add_theme_font_size_override("font_size",12);list.add_child(boon);boons[kind]=boon
		boon.pressed.connect(func():world.request_action("attune",{"kind":kind,"rank":FortAttune.rank(world,kind)}))
	var close:=Button.new();close.text="BACK TO THE CREW";close.pressed.connect(close_panel);stack.add_child(close)
	hide()

func open_panel()->void:
	if world.menu_open or world.is_night or world.local_player().position.length()>5:return
	world.menu_open=true;show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func close_panel()->void:
	hide();world.menu_open=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _process(_delta:float)->void:
	if not visible:return
	var p:=world.local_player()
	if not world.menu_open or not p or p.health<=0 or p.position.length()>5 or world.is_night or world.ended:close_panel();return
	var level:=world.hearth_level
	for kind in boons:
		var boon:Button=boons[kind];var rank:=FortAttune.rank(world,kind)
		boon.visible=world.expedition.has_rare(kind) or rank>0 or int(world.shared.get(kind,0))>0
		var title:="%s  %s %s"%[FortGlyphs.g(kind),FortAttune.BOONS[kind].name,"I".repeat(rank) if rank>0 else ""]
		if rank>=FortAttune.MAX_RANK:boon.text=title+"   /   complete";boon.disabled=true;continue
		var price:=FortAttune.cost(kind,rank+1)
		boon.text="%s   /   each rank: %s   /   %s"%[title,FortAttune.BOONS[kind].each,GameData.supplies_text(price,true)]
		boon.disabled=false
		for resource in price:
			if int(world.shared.get(resource,0))<int(price[resource]):boon.disabled=true
	if level>=GameData.MAX_HEARTH:
		detail.text="TIER 8 / ETERNAL HEARTH\n4,500 health · 643m frontier · 340m build radius\nAll five randomized biomes revealed. Nights continue endlessly.\nPress G beside a defense to reinforce or salvage it."
		upgrade.text="HEARTH FULLY UPGRADED";upgrade.disabled=true;return
	var cost:=world.expedition.upgrade_cost(level)
	var region:String=["RUSTSCAR & ELDERWOOD","STORMGLASS & FROSTVEIN"][level-1] if level<3 else "UNEXPLORED RANDOM BIOME"
	var reach:float=[65,115][level-1] if level<3 else world.build_radius()+45
	detail.text="TIER %d → %d / %s\n+500 hearth health / Build radius %dm → %dm\n72 new resources; higher weapon and tower reinforcement.\nDanger: +10%% base raid allowance / +5%% base enemy health.\nRaids also grow with the fort you build (strength %d, raid +%d%%).\nCost  %s"%[level,level+1,region,world.build_radius(),reach,roundi(FortBalance.strength(world)),roundi((FortBalance.pressure(FortBalance.strength(world),level)-1.0)*100.0),GameData.supplies_text(cost,true)]
	upgrade.disabled=false
	detail.text+="\n+30 seconds daylight per upgrade; longer nights allow travel."
	for kind in cost:
		if int(world.shared.get(kind,0))<cost[kind]:upgrade.disabled=true
	upgrade.text="UPGRADE WITH SHARED SUPPLIES" if not upgrade.disabled else "DEPOSIT MORE SHARED SUPPLIES"
