class_name FortGlyphs
extends RefCounted

# Resource symbols as real font glyphs. A small bitmap font with private-use
# characters is added as a fallback to the default font, so every Label, Button,
# tooltip and Label3D can show "12[wood] 6[stone]" without naming the resource.
const KINDS := ["wood","stone","crystal","iron","aether","gold","hp","xp","resin","spore","cinder","frost","bloom"]
const BASE := 0xE000
const SIZE := 48
static var installed := false
static var font: FontFile
static var textures: Dictionary = {}

static func g(kind:String)->String:
	var index:=KINDS.find(kind)
	return char(BASE+index) if index>=0 else kind

## "12[wood] 6[stone]" for a cost / stock dictionary. Zero entries are skipped unless keep_zero.
static func cost(stock:Dictionary,keep_zero:=false,order:Array=GameData.RESOURCES)->String:
	var parts:=PackedStringArray()
	for kind in order:
		var amount:=int(stock.get(kind,0))
		if amount==0 and not keep_zero:continue
		parts.append("%d%s"%[amount,g(kind)])
	if stock.has("gold") and not "gold" in order and int(stock.gold)!=0:parts.append("%d%s"%[int(stock.gold),g("gold")])
	return "  ".join(parts) if not parts.is_empty() else "Free"

## Replaces {wood} style tokens: t("40{wood} 100{stone}").
static func t(text:String)->String:
	for kind in KINDS:text=text.replace("{"+kind+"}",g(kind))
	return text

static func texture(kind:String)->Texture2D:
	install()
	return textures.get(kind)

static func install()->void:
	if installed:return
	installed=true
	var atlas:=Image.create(SIZE*KINDS.size(),SIZE,false,Image.FORMAT_RGBA8)
	atlas.fill(Color(0,0,0,0))
	for i in KINDS.size():
		var tile:=_draw(KINDS[i])
		atlas.blit_rect(tile,Rect2i(0,0,SIZE,SIZE),Vector2i(i*SIZE,0))
		textures[KINDS[i]]=ImageTexture.create_from_image(tile)
	font=FontFile.new()
	font.fixed_size=SIZE
	font.fixed_size_scale_mode=TextServer.FIXED_SIZE_SCALE_ENABLED
	font.antialiasing=TextServer.FONT_ANTIALIASING_GRAY
	var key:=Vector2i(SIZE,0)
	font.set_cache_ascent(0,SIZE,SIZE*0.8)
	font.set_cache_descent(0,SIZE,SIZE*0.2)
	font.set_texture_image(0,key,0,atlas)
	for i in KINDS.size():
		var code:=BASE+i
		font.set_glyph_advance(0,SIZE,code,Vector2(SIZE*0.98,0))
		font.set_glyph_offset(0,key,code,Vector2(SIZE*0.02,-SIZE*0.86))
		font.set_glyph_size(0,key,code,Vector2(SIZE,SIZE))
		font.set_glyph_uv_rect(0,key,code,Rect2(i*SIZE,0,SIZE,SIZE))
		font.set_glyph_texture_idx(0,key,code,0)
	var base:Font=ThemeDB.fallback_font
	if base:
		var chain:Array[Font]=base.fallbacks
		chain.append(font)
		base.fallbacks=chain

# ------------------------------------------------------------ tiny rasteriser
static func _poly(image:Image,points:PackedVector2Array,color:Color)->void:
	var lo:=Vector2(SIZE,SIZE);var hi:=Vector2.ZERO
	for p in points:lo=lo.min(p);hi=hi.max(p)
	for y in range(maxi(0,int(lo.y)),mini(SIZE,int(hi.y)+2)):
		for x in range(maxi(0,int(lo.x)),mini(SIZE,int(hi.x)+2)):
			var hits:=0
			for sub in [Vector2(.25,.25),Vector2(.75,.25),Vector2(.25,.75),Vector2(.75,.75)]:
				if Geometry2D.is_point_in_polygon(Vector2(x,y)+sub,points):hits+=1
			if hits>0:
				var under:=image.get_pixel(x,y)
				var alpha:=color.a*hits/4.0
				image.set_pixel(x,y,Color(lerpf(under.r,color.r,alpha),lerpf(under.g,color.g,alpha),lerpf(under.b,color.b,alpha),maxf(under.a,alpha)) if under.a>0 else Color(color.r,color.g,color.b,alpha))

static func _disc(image:Image,center:Vector2,radius:Vector2,color:Color,segments:=28)->void:
	var points:=PackedVector2Array()
	for i in segments:points.append(center+Vector2(cos(i*TAU/segments)*radius.x,sin(i*TAU/segments)*radius.y))
	_poly(image,points,color)

static func _draw(kind:String)->Image:
	var image:=Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	var outline:=Color("#10181b")
	match kind:
		"wood":
			_poly(image,PackedVector2Array([Vector2(4,17),Vector2(36,9),Vector2(44,27),Vector2(12,37)]),outline)
			_poly(image,PackedVector2Array([Vector2(7,19),Vector2(35,12),Vector2(41,26),Vector2(13,34)]),Color("#b8733c"))
			_poly(image,PackedVector2Array([Vector2(9,22),Vector2(34,15.5),Vector2(35,18),Vector2(10,24.5)]),Color("#d6975a"))
			_disc(image,Vector2(38,19.5),Vector2(6.5,9.5),outline)
			_disc(image,Vector2(38,19.5),Vector2(4.6,7.6),Color("#f0c98a"))
			_disc(image,Vector2(38,19.5),Vector2(2.2,3.8),Color("#c78a4c"))
		"stone":
			_poly(image,PackedVector2Array([Vector2(4,34),Vector2(9,17),Vector2(22,8),Vector2(37,12),Vector2(45,28),Vector2(40,39),Vector2(10,40)]),outline)
			_poly(image,PackedVector2Array([Vector2(7,33),Vector2(11,19),Vector2(22,11),Vector2(35,14.5),Vector2(42,28),Vector2(38,37),Vector2(11,37.5)]),Color("#8f9aa6"))
			_poly(image,PackedVector2Array([Vector2(11,19),Vector2(22,11),Vector2(35,14.5),Vector2(26,22)]),Color("#c3ccd4"))
			_poly(image,PackedVector2Array([Vector2(26,22),Vector2(35,14.5),Vector2(42,28),Vector2(38,37),Vector2(27,37.5)]),Color("#6f7a86"))
		"crystal":
			_poly(image,PackedVector2Array([Vector2(24,3),Vector2(39,18),Vector2(24,45),Vector2(9,18)]),outline)
			_poly(image,PackedVector2Array([Vector2(24,7),Vector2(36,18.5),Vector2(24,41),Vector2(12,18.5)]),Color("#3fc6dc"))
			_poly(image,PackedVector2Array([Vector2(24,7),Vector2(24,41),Vector2(12,18.5)]),Color("#8ff0f6"))
			_poly(image,PackedVector2Array([Vector2(24,7),Vector2(29,18.5),Vector2(24,41),Vector2(19,18.5)]),Color("#62dcea"))
		"iron":
			_poly(image,PackedVector2Array([Vector2(3,36),Vector2(10,15),Vector2(38,15),Vector2(45,36)]),outline)
			_poly(image,PackedVector2Array([Vector2(7,33.5),Vector2(12,18),Vector2(36,18),Vector2(41,33.5)]),Color("#b9805a"))
			_poly(image,PackedVector2Array([Vector2(12,18),Vector2(36,18),Vector2(33,24),Vector2(15,24)]),Color("#e7b58c"))
			_poly(image,PackedVector2Array([Vector2(15,24),Vector2(33,24),Vector2(41,33.5),Vector2(7,33.5)]),Color("#a36b49"))
		"aether":
			_disc(image,Vector2(24,24),Vector2(19,19),outline)
			_disc(image,Vector2(24,24),Vector2(16.5,16.5),Color("#a66fe6"))
			_disc(image,Vector2(24,24),Vector2(11,11),Color("#cfa8f7"))
			_disc(image,Vector2(24,24),Vector2(5.5,5.5),Color("#f5e9ff"))
			_poly(image,PackedVector2Array([Vector2(24,2),Vector2(27,9),Vector2(24,12),Vector2(21,9)]),Color("#f5e9ff"))
		"gold":
			_disc(image,Vector2(24,24),Vector2(19,19),outline)
			_disc(image,Vector2(24,24),Vector2(16.5,16.5),Color("#e8b63d"))
			_disc(image,Vector2(24,24),Vector2(12.5,12.5),Color("#f8dc76"))
			_poly(image,PackedVector2Array([Vector2(24,13),Vector2(31,24),Vector2(24,35),Vector2(17,24)]),Color("#d49a26"))
		"hp":
			var heart:=PackedVector2Array([Vector2(24,42),Vector2(5,22),Vector2(5,13),Vector2(12,6),Vector2(19,7),Vector2(24,13),Vector2(29,7),Vector2(36,6),Vector2(43,13),Vector2(43,22)])
			_poly(image,heart,outline)
			var inner:=PackedVector2Array()
			for p in heart:inner.append(Vector2(24,22)+(p-Vector2(24,22))*0.84)
			_poly(image,inner,Color("#e2574c"))
			_disc(image,Vector2(15,15),Vector2(3.5,3.5),Color("#f7a79a"))
		"xp":
			var star:=PackedVector2Array()
			for i in 10:star.append(Vector2(24,25)+Vector2(sin(i*TAU/10),-cos(i*TAU/10))*(21.0 if i%2==0 else 9.5))
			_poly(image,star,outline)
			var core:=PackedVector2Array()
			for i in 10:core.append(Vector2(24,25)+Vector2(sin(i*TAU/10),-cos(i*TAU/10))*(17.0 if i%2==0 else 7.5))
			_poly(image,core,Color("#7fe0c0"))
		"resin":
			# A drop of amber.
			_poly(image,PackedVector2Array([Vector2(24,3),Vector2(38,26),Vector2(24,45),Vector2(10,26)]),outline)
			_disc(image,Vector2(24,29),Vector2(15,15),outline)
			_poly(image,PackedVector2Array([Vector2(24,8),Vector2(34,26),Vector2(14,26)]),Color("#e8a03a"))
			_disc(image,Vector2(24,29),Vector2(12,12),Color("#e8a03a"))
			_disc(image,Vector2(20,27),Vector2(4,6),Color("#f9d58a"))
		"spore":
			# A glowing mushroom cap.
			_disc(image,Vector2(24,20),Vector2(20,15),outline)
			_poly(image,PackedVector2Array([Vector2(17,22),Vector2(31,22),Vector2(33,45),Vector2(15,45)]),outline)
			_disc(image,Vector2(24,20),Vector2(17,12),Color("#5fcfae"))
			_poly(image,PackedVector2Array([Vector2(20,26),Vector2(28,26),Vector2(29.5,42),Vector2(18.5,42)]),Color("#d9f5e6"))
			for spot in [Vector2(16,17),Vector2(26,13),Vector2(33,21)]:_disc(image,spot,Vector2(3,3),Color("#d6fff0"))
		"cinder":
			# A coal with a burning heart.
			_poly(image,PackedVector2Array([Vector2(5,33),Vector2(11,14),Vector2(27,6),Vector2(42,17),Vector2(44,34),Vector2(30,43),Vector2(12,42)]),outline)
			_poly(image,PackedVector2Array([Vector2(8,32),Vector2(13,16),Vector2(27,9.5),Vector2(39,18.5),Vector2(41,33),Vector2(29.5,40),Vector2(13,39)]),Color("#4a3a38"))
			_poly(image,PackedVector2Array([Vector2(17,31),Vector2(23,17),Vector2(27,25),Vector2(32,20),Vector2(34,33),Vector2(25,37)]),Color("#e8603c"))
			_poly(image,PackedVector2Array([Vector2(22,31),Vector2(25,24),Vector2(29,31),Vector2(25,35)]),Color("#ffd27a"))
		"frost":
			# A shard of clear ice.
			_poly(image,PackedVector2Array([Vector2(18,3),Vector2(34,8),Vector2(42,30),Vector2(27,46),Vector2(9,34),Vector2(8,15)]),outline)
			_poly(image,PackedVector2Array([Vector2(19,7),Vector2(32,11),Vector2(38.5,29.5),Vector2(26.5,42),Vector2(12,32.5),Vector2(11,16.5)]),Color("#8fd0ef"))
			_poly(image,PackedVector2Array([Vector2(19,7),Vector2(32,11),Vector2(24,24),Vector2(11,16.5)]),Color("#dff4ff"))
			_poly(image,PackedVector2Array([Vector2(24,24),Vector2(38.5,29.5),Vector2(26.5,42)]),Color("#6bb4dc"))
		"bloom":
			# A sun-coloured flower.
			for i in 6:_disc(image,Vector2(24,24)+Vector2(sin(i*TAU/6),-cos(i*TAU/6))*12.0,Vector2(9.5,9.5),outline)
			for i in 6:_disc(image,Vector2(24,24)+Vector2(sin(i*TAU/6),-cos(i*TAU/6))*12.0,Vector2(7.2,7.2),Color("#f2d85a"))
			_disc(image,Vector2(24,24),Vector2(7.5,7.5),outline)
			_disc(image,Vector2(24,24),Vector2(5.5,5.5),Color("#e88f3a"))
	return image
