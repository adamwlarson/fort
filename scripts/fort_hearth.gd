class_name FortHearth
extends PanelContainer

var world:FortWorld
var detail:Label
var upgrade:Button

func _ready()->void:
	position=Vector2(340,200);size=Vector2(600,310);theme=FortInterface.theme()
	var style:=FortInterface.frame(true);style.set_content_margin_all(25);add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",16);add_child(stack)
	var title:=Label.new();title.text="FEED THE HEARTH / EXPAND THE FRONTIER";title.add_theme_font_size_override("font_size",22);stack.add_child(title)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size=Vector2(540,145);stack.add_child(detail)
	upgrade=Button.new();upgrade.custom_minimum_size.y=46;upgrade.pressed.connect(func():world.request_action("upgrade_hearth",{"level":world.hearth_level}));stack.add_child(upgrade)
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
	if level>=GameData.MAX_HEARTH:
		detail.text="TIER 8 / ETERNAL HEARTH\n4,500 health · 643m frontier · 340m build radius\nAll five randomized biomes revealed. Nights continue endlessly.\nPress G beside a defense to reinforce or salvage it."
		upgrade.text="HEARTH FULLY UPGRADED";upgrade.disabled=true;return
	var cost:=FortExpedition.hearth_cost(level)
	var region:String=["RUSTSCAR & ELDERWOOD","STORMGLASS & FROSTVEIN"][level-1] if level<3 else "UNEXPLORED RANDOM BIOME"
	var reach:float=[65,115][level-1] if level<3 else world.build_radius()+45
	detail.text="TIER %d → %d / %s\n+500 hearth health / Build radius %dm → %dm\n72 new resources; higher weapon and tower reinforcement.\nDanger: +10%% base raid allowance / +5%% base enemy health.\nShared cost: %s"%[level,level+1,region,world.build_radius(),reach,GameData.supplies_text(cost,true)]
	upgrade.disabled=false
	detail.text+="\n+30 seconds daylight per upgrade; longer nights allow travel."
	for kind in cost:
		if world.shared[kind]<cost[kind]:upgrade.disabled=true
	upgrade.text="UPGRADE WITH SHARED SUPPLIES" if not upgrade.disabled else "DEPOSIT MORE SHARED SUPPLIES"
