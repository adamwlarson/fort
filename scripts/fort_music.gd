class_name FortMusic
extends Node

# Background music that never cuts: two players cross-fade between tracks (title, day,
# night) and a track cross-fades into its own beginning before it runs out.
const DIR:="res://assets/audio/music/"
var players:Array[AudioStreamPlayer]=[]
var gains:Array[float]=[0.0,0.0]
var levels:Array[float]=[-14.0,-14.0]
var active:=0
var track:=""
var fade:=4.0
var enabled:=true
var cache:Dictionary={}

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name()=="headless":return
	FortSound.ensure_buses()
	for i in 2:
		var player:=AudioStreamPlayer.new();player.bus="Music";player.volume_db=-80;add_child(player);players.append(player)

func stream(title:String)->AudioStream:
	if not cache.has(title):
		var path:=DIR+title+".ogg"
		cache[title]=load(path) if ResourceLoader.exists(path) else null
	return cache[title]

## Fade to another track over `seconds`. Asking for the track already playing does nothing.
func play(title:String,volume:=-14.0,seconds:=4.0)->void:
	if players.is_empty() or title==track:return
	track=title;fade=maxf(.2,seconds)
	if title=="" or stream(title)==null:return
	active=1-active
	players[active].stream=stream(title);players[active].play();gains[active]=0.0;levels[active]=volume

func _process(delta:float)->void:
	if players.is_empty():return
	for i in 2:
		var wanted:=1.0 if i==active and enabled and track!="" else 0.0
		gains[i]=move_toward(gains[i],wanted,delta/fade)
		players[i].volume_db=linear_to_db(maxf(gains[i]*gains[i],.00001))+levels[i]
		if gains[i]<=0.0 and i!=active and players[i].playing:players[i].stop()
	var current:=players[active]
	if track=="" or current.stream==null:return
	if not current.playing:current.play()
	# Hand over to a fresh copy of the same track a few seconds before the end.
	elif current.get_playback_position()>current.stream.get_length()-5.5:
		var level:=levels[active]
		active=1-active;fade=5.0
		players[active].stream=current.stream;players[active].play();gains[active]=0.0;levels[active]=level
