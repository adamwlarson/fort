class_name FortIcon
extends Control

var kind := "Watchtower"
var tint := FortInterface.GOLD

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := minf(size.x,size.y)/64.0
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*s)
	var dark := Color("#45605a")
	match kind:
		"Gatehouse":
			for x in [6,46]:
				draw_rect(Rect2(x,12,12,44),tint)
				for dx in [0,8]:draw_rect(Rect2(x+dx,6,4,10),tint)
			draw_arc(Vector2(32,32),15,PI,TAU,18,tint,7,true)
			for x in [23,32,41]:draw_line(Vector2(x,30),Vector2(x,55),tint,3,true)
			for y in [35,47]:draw_line(Vector2(20,y),Vector2(44,y),tint,3,true)
		"Embercoil":
			draw_rect(Rect2(23,18,18,39),dark)
			for y in [29,39,49]:draw_arc(Vector2(32,y),13,0,TAU,20,tint,4,true)
			draw_colored_polygon(PackedVector2Array([Vector2(20,22),Vector2(31,4),Vector2(34,17),Vector2(45,10),Vector2(40,29)]),Color("#f5a559"))
		"GravityWell","Runestaff":
			draw_line(Vector2(32,57),Vector2(32,21),tint,5,true)
			draw_circle(Vector2(32,24),10,Color("#b391e4"))
			draw_arc(Vector2(32,24),19,0,TAU,24,tint,3,true)
		"Sunlance","Longrifle","Handcannon":
			draw_line(Vector2(14,54),Vector2(49,14),tint,kind.length()%5+6,true)
			draw_circle(Vector2(49,14),8,Color("#efb972"))
			draw_line(Vector2(40,5),Vector2(59,24),dark,3,true)
		"Greatmaul","Warpick":
			draw_line(Vector2(26,57),Vector2(32,19),tint,6,true)
			draw_rect(Rect2(6,7,52,24),tint)
			draw_rect(Rect2(24,10,14,17),Color("#b391e4"))
		"Runeblade","Cleaver":
			draw_line(Vector2(15,56),Vector2(45,12),tint,7,true)
			draw_colored_polygon(PackedVector2Array([Vector2(23,34),Vector2(43,5),Vector2(55,7),Vector2(37,39)]),Color("#bfced0"))
			draw_line(Vector2(14,31),Vector2(36,46),tint,5,true)
		"Pike":
			draw_line(Vector2(15,57),Vector2(43,14),tint,4,true)
			draw_colored_polygon(PackedVector2Array([Vector2(37,19),Vector2(53,4),Vector2(48,25)]),Color("#bacbd0"))
			draw_polyline(PackedVector2Array([Vector2(28,22),Vector2(31,31),Vector2(43,35),Vector2(49,29)]),tint,3,true)
		"Repeater":
			draw_line(Vector2(32,57),Vector2(32,6),tint,5,true)
			draw_polyline(PackedVector2Array([Vector2(8,32),Vector2(16,22),Vector2(48,22),Vector2(56,32)]),tint,4,true)
			draw_rect(Rect2(22,27,20,16),dark)
			for x in [25,32,39]:draw_line(Vector2(x,29),Vector2(x,40),Color("#c4a3f0"),3,true)
		"MetalWall":
			draw_rect(Rect2(8,12,48,42),tint)
			for x in [13,32,51]:draw_line(Vector2(x,16),Vector2(x,50),dark,3,true)
			for x in [18,45]:
				for y in [19,46]:draw_circle(Vector2(x,y),2,dark)
		"StormSpire":
			draw_line(Vector2(32,56),Vector2(32,26),dark,10,true)
			for y in [33,43]:draw_arc(Vector2(32,y),12,0,TAU,20,tint,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(34,3),Vector2(21,22),Vector2(31,22),Vector2(27,34),Vector2(44,14),Vector2(34,14)]),Color("#c3a1ed"))
		"FrostMortar":
			draw_line(Vector2(24,48),Vector2(42,19),tint,15,true)
			draw_circle(Vector2(43,17),9,dark)
			draw_rect(Rect2(12,50,40,7),tint)
			for angle in [0,PI/3,PI*2/3]:
				var axis:=Vector2(cos(angle),sin(angle))*9
				draw_line(Vector2(14,18)-axis,Vector2(14,18)+axis,Color("#a6e6ed"),2,true)
		"Axe":
			draw_line(Vector2(20,55),Vector2(39,12),tint,5,true)
			draw_colored_polygon(PackedVector2Array([Vector2(30,15),Vector2(50,9),Vector2(55,28),Vector2(36,31)]),tint)
		"Hammer":
			draw_line(Vector2(29,55),Vector2(33,20),tint,5,true)
			draw_rect(Rect2(12,10,41,19),tint)
			draw_line(Vector2(21,10),Vector2(21,29),dark,3,true)
			draw_line(Vector2(44,10),Vector2(44,29),dark,3,true)
		"Watchtower":
			for x in [17,43]: draw_line(Vector2(x,57),Vector2(x,23),tint,5,true)
			draw_line(Vector2(17,49),Vector2(43,28),dark,3,true)
			draw_rect(Rect2(11,21,40,8),tint)
			draw_colored_polygon(PackedVector2Array([Vector2(8,20),Vector2(31,5),Vector2(55,20)]),tint)
		"Barricade":
			for x in [15,31,47]:
				draw_colored_polygon(PackedVector2Array([Vector2(x-5,53),Vector2(x-5,19),Vector2(x,9),Vector2(x+5,19),Vector2(x+5,53)]),tint)
			draw_line(Vector2(7,37),Vector2(56,37),dark,6,true)
		"Ballista","Crossbow":
			draw_line(Vector2(32,54),Vector2(32,10),tint,4,true)
			draw_polyline(PackedVector2Array([Vector2(8,34),Vector2(15,23),Vector2(49,23),Vector2(56,34)]),tint,4,true)
			draw_line(Vector2(8,34),Vector2(56,34),dark,2,true)
			draw_line(Vector2(17,56),Vector2(32,41),tint,4,true)
			draw_line(Vector2(47,56),Vector2(32,41),tint,4,true)
		"Mender":
			draw_arc(Vector2(32,32),23,0,TAU,32,dark,3,true)
			draw_rect(Rect2(27,13,10,38),tint)
			draw_rect(Rect2(13,27,38,10),tint)
		"wood":
			for y in [23,43]:
				draw_line(Vector2(15,y),Vector2(46,y-7),tint,13,true)
				draw_circle(Vector2(15,y),7,Color("#e0bf83"))
				draw_arc(Vector2(15,y),4,0,TAU,16,dark,1.5,true)
		"iron":
			draw_colored_polygon(PackedVector2Array([Vector2(8,44),Vector2(17,23),Vector2(46,17),Vector2(57,37),Vector2(47,49),Vector2(18,54)]),tint)
			draw_polyline(PackedVector2Array([Vector2(17,23),Vector2(25,39),Vector2(57,37)]),Color("#f3d6ae"),3,true)
			draw_line(Vector2(25,39),Vector2(18,54),dark,3,true)
		"aether":
			draw_circle(Vector2(32,32),14,tint)
			draw_arc(Vector2(32,32),24,-.4,4.6,32,tint,3,true)
			draw_circle(Vector2(54,20),5,Color("#eee1ff"))
			draw_line(Vector2(32,8),Vector2(32,56),Color("#e8d7ff"),2,true)
		"Ironheart":
			draw_colored_polygon(PackedVector2Array([Vector2(20,9),Vector2(27,16),Vector2(37,16),Vector2(44,9),Vector2(58,22),Vector2(48,32),Vector2(46,56),Vector2(18,56),Vector2(16,32),Vector2(6,22)]),tint)
			draw_line(Vector2(32,21),Vector2(32,50),dark,4,true)
		"stone":
			draw_colored_polygon(PackedVector2Array([Vector2(7,47),Vector2(17,18),Vector2(37,10),Vector2(55,31),Vector2(49,51)]),tint)
			draw_polyline(PackedVector2Array([Vector2(17,18),Vector2(34,31),Vector2(55,31)]),dark,2,true)
			draw_line(Vector2(34,31),Vector2(28,50),dark,2,true)
		"crystal":
			draw_colored_polygon(PackedVector2Array([Vector2(32,5),Vector2(47,25),Vector2(43,47),Vector2(32,58),Vector2(20,47),Vector2(17,25)]),tint)
			draw_polyline(PackedVector2Array([Vector2(32,5),Vector2(29,29),Vector2(32,58)]),Color("#deead8"),2,true)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(8,14),Vector2(56,14),Vector2(52,43),Vector2(32,59),Vector2(12,43)]),dark)
			draw_polyline(PackedVector2Array([Vector2(8,14),Vector2(56,14),Vector2(52,43),Vector2(32,59),Vector2(12,43),Vector2(8,14)]),tint,2,true)
			draw_colored_polygon(PackedVector2Array([Vector2(23,42),Vector2(26,26),Vector2(32,33),Vector2(38,20),Vector2(42,42)]),tint)
