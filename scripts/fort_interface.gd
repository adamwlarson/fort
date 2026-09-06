class_name FortInterface
extends RefCounted

const INK := Color("#14272a")
const GOLD := Color("#c9ab70")
const PAPER := Color("#eee2c8")
const MUTED := Color("#9fb6b0")

static func frame(active := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#203c3d") if active else Color(0.055,0.095,0.105,0.96)
	style.border_color = GOLD if active else Color("#52625c")
	style.set_border_width_all(1)
	style.border_width_top = 3 if active else 1
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0,0,0,0.28)
	style.shadow_size = 5
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	for kind in ["Label","Button","OptionButton","LineEdit","CheckButton"]:
		result.set_color("font_color",kind,PAPER)
		result.set_color("font_hover_color",kind,Color.WHITE)
		result.set_color("font_focus_color",kind,Color.WHITE)
	for kind in ["Button","OptionButton","LineEdit"]:
		for state in ["normal","hover","pressed","focus"]:
			var style := frame(state != "normal")
			style.set_content_margin_all(10)
			result.set_stylebox(state,kind,style)
	result.set_color("font_placeholder_color","LineEdit",MUTED)
	result.set_color("caret_color","LineEdit",GOLD)
	return result
