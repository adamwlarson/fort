class_name FortMerchant
extends PanelContainer

const SELL:={"wood":2,"stone":3,"crystal":8,"iron":6,"aether":16}
const BUY:={"wood":4,"stone":6,"crystal":14,"iron":11,"aether":28}
var world:FortWorld
var target:=""
var title:Label
var rows:VBoxContainer
var stamp:=""
static func location(c:FortCastle,k:String)->Vector3:return FortCastle.position(c.rooms[k])+Vector3(0,0,4)
static func nearest(w:FortWorld,pos:Vector3)->String:
	for k in w.castle.rooms:
		var r:Dictionary=w.castle.rooms[k]
		if r.kind=="Merchant" and r.complete and FortCastleFeatures.healthy(r) and pos.distance_to(location(w.castle,k))<3.5:return k
	return ""
static func price(w:FortWorld,k:String,resource:String)->int:
	var level:=int(w.castle.rooms[k].get("level",1))
	var sale:bool=GameData.BASIC[posmod(w.wave,GameData.BASIC.size())]==resource
	return maxi(int(SELL[resource])+1,ceili(float(BUY[resource])*(1.0-.05*(level-1))*(.75 if sale else 1.0)))
static func trade(w:FortWorld,id:int,k:String,resource:String,sell:bool,revision:int,day:int)->void:
	if not w.multiplayer.is_server() or not w.players.has(id) or revision!=w.castle.revision or day!=w.wave:return
	var p:FortPlayer=w.players[id]
	if p.health<=0 or p.mounted_ballista>=0 or k=="" or nearest(w,p.position)!=k or not SELL.has(resource):return
	if resource=="iron" and w.hearth_level<2 or resource=="aether" and w.hearth_level<3:return
	var amount:=5
	if sell:
		if int(w.shared.get(resource,0))<amount:w.personal(id,"Selling needs 5 "+resource+" in shared stock.");return
		w.shared[resource]-=amount;w.shared.gold=int(w.shared.get("gold",0))+int(SELL[resource])*amount
	else:
		var payment:=price(w,k,resource)*amount
		if int(w.shared.get("gold",0))<payment:w.personal(id,"Not enough shared gold.");return
		w.shared.gold-=payment;w.shared[resource]+=amount
	w.castle.changed();w.broadcast("recv_full",[w.full_state()])
func _ready()->void:
	name="MerchantTrade";position=Vector2(350,125);size=Vector2(580,450);theme=FortInterface.theme()
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",12);add_child(stack)
	title=Label.new();title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size=Vector2(550,80);stack.add_child(title)
	rows=VBoxContainer.new();stack.add_child(rows)
	var back:=Button.new();back.text="LEAVE TRADER / ESC";back.pressed.connect(close_panel);stack.add_child(back);hide()
func open_panel(k:String)->void:
	target=k;world.menu_open=true;stamp="";show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;refresh()
func close_panel()->void:hide();world.menu_open=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _process(_delta:float)->void:
	if not visible:return
	var p:=world.local_player()
	if not p or p.health<=0 or nearest(world,p.position)!=target:close_panel();return
	refresh()
func refresh()->void:
	var next:=str([world.castle.revision,world.wave,world.shared])
	if stamp==next:return
	stamp=next
	title.text="MERCHANT / SHARED GOLD: %d\nToday's sale: %s at 25%% off. Sell or buy 5 at a time.\nPrices include this hall's upgrade discount."%[int(world.shared.get("gold",0)),GameData.RESOURCES[posmod(world.wave,5)].capitalize()]
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	for resource in GameData.BASIC:
		var row:=HBoxContainer.new();rows.add_child(row)
		var text:=Label.new();text.text="%s  %d"%[FortGlyphs.g(resource),int(world.shared.get(resource,0))];text.custom_minimum_size.x=170;row.add_child(text)
		for sell in [true,false]:
			var b:=Button.new();b.text=("Sell 5 / +%d gold"%(5*int(SELL[resource]))) if sell else "Buy 5 / %d gold"%(5*price(world,target,resource));row.add_child(b)
			b.disabled=(resource=="iron" and world.hearth_level<2) or (resource=="aether" and world.hearth_level<3)
			var day:=world.wave;var revision:=world.castle.revision
			b.pressed.connect(func():world.request_action("merchant_trade",{"key":target,"resource":resource,"sell":sell,"revision":revision,"day":day}))
