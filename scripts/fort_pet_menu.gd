class_name FortPetMenu
extends VBoxContainer
var world:FortWorld
var recruit_buttons:Array[Button]=[]
var labels:Array[Label]=[]
var assignments:Array[OptionButton]=[]
var releases:Array[Button]=[]
func _ready()->void:
	add_theme_constant_override("separation",8)
	var text:=Label.new();text.text="THREE PETS SHARED BY THE CREW / Gather by day, return and deposit at night.\nAssignments may be changed here. Pets hop obstacles and recall if trapped.";text.add_theme_font_size_override("font_size",14);add_child(text)
	var row:=HBoxContainer.new();add_child(row)
	for i in FortPets.SPECS.size():
		var button:=Button.new();button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size.y=50;row.add_child(button);recruit_buttons.append(button)
		button.pressed.connect(func():world.request_action("recruit_pet",{"kind":i,"revision":world.pets.revision}))
	for i in 3:
		var line:=HBoxContainer.new();add_child(line)
		var label:=Label.new();label.custom_minimum_size=Vector2(455,42);line.add_child(label);labels.append(label)
		var option:=OptionButton.new();option.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		for resource in ["wood","stone","crystal","iron","aether","rest"]:option.add_item(resource.to_upper())
		line.add_child(option);assignments.append(option)
		var release:=Button.new();release.text="RELEASE";release.tooltip_text="Set REST and wait for the pet to return home empty. Frees the slot; no refund.";line.add_child(release);releases.append(release)
		release.pressed.connect(func():
			var ids:=world.pets.pets.keys()
			if i<ids.size():world.request_action("release_pet",{"id":ids[i],"revision":world.pets.pets[ids[i]].revision}))
		option.item_selected.connect(func(index):
			var ids:=world.pets.pets.keys()
			if i<ids.size():world.request_action("assign_pet",{"id":ids[i],"resource":["wood","stone","crystal","iron","aether","rest"][index],"revision":world.pets.pets[ids[i]].revision}))
func _process(_delta:float)->void:
	if not is_visible_in_tree():return
	for i in recruit_buttons.size():
		var spec:Dictionary=FortPets.SPECS[i];var allowed:bool=world.pets.pets.size()<3 and world.hearth_level>=spec.tier
		for resource in GameData.RESOURCES:
			if world.shared.get(resource,0)<spec.get(resource,0):allowed=false
		recruit_buttons[i].text="RECRUIT "+spec.name+"\nHearth %d / %s"%[spec.tier,GameData.supplies_text(spec,true)];recruit_buttons[i].disabled=not allowed
		recruit_buttons[i].add_theme_font_size_override("font_size",12)
	var ids:=world.pets.pets.keys()
	for i in 3:
		assignments[i].visible=i<ids.size()
		releases[i].visible=i<ids.size()
		if i>=ids.size():labels[i].text="EMPTY PET SLOT";continue
		var p:Dictionary=world.pets.pets[ids[i]]
		releases[i].disabled=p.resource!="rest" or p.cargo>0 or p.node.position.distance_to(FortPets.HOME)>6
		labels[i].text="%s / %s / %d %s in pack"%[FortPets.SPECS[p.kind].name,p.mode,p.cargo,p.cargo_kind]
		assignments[i].select(["wood","stone","crystal","iron","aether","rest"].find(p.resource))
		assignments[i].set_item_disabled(3,world.hearth_level<2);assignments[i].set_item_disabled(4,world.hearth_level<3)
