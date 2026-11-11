class_name FortSound
extends Node

# Fort 30 audio. Recorded effects (assets/audio/sfx) with the old synthesized tones as a
# fallback, played where they happen in the world; ambience that follows day, night, the
# lakes and the hearth; footsteps and wading; and the dwarves' own voices.
const DIR:="res://assets/audio/"
## What each sound the game asks for is made of. Several files means a random pick.
const FILES:={
	"hit":["hit_1","hit_2"],"chop":["chop_1","chop_2"],"mine":["mine_1","mine_2"],"crystal":["crystal_1"],
	"build":["hammer_1","hammer_2"],"construction":["hammer_1","hammer_2"],"hammer":["hit_2"],"build_done":["build_done_1"],
	"deposit":["deposit_1"],"ability":["ability_1"],"swing":["swing_1"],"shot":["ballista_1"],"crossbow":["crossbow_1"],
	"night":["raid_horn_1"],"dawn":["dawn_1"],"arc":["arc_1"],"frost_shell":["frost_1"],"fuse":["fuse_1"],"blast":["blast_1"],
	"gate_move":["gate_move_1"],"gate_stop":["gate_stop_1"],"mend":["heal_1"],"heal":["heal_1"],
	"step_grass":["step_grass_1","step_grass_2"],"step_stone":["step_stone_1","step_stone_2"],
	"splash_step":["splash_step_1","splash_step_2"],"splash_big":["splash_big_1"],"tree_fall":["tree_fall_1"],
	"enemy_hurt":["enemy_hurt_1"],"enemy_die":["enemy_die_1"],"brute_roar":["brute_roar_1"],"dragon_roar":["dragon_roar_1"],
	"wolf":["wolf_1"],"wings":["wings_1"],"slam":["slam_1"],"ui_click":["ui_click_1"],"level_up":["level_up_1"],
	"chest":["chest_1"],"hearth_up":["hearth_up_1"],
}
## Trim per sound, in dB, on top of what the caller asks for.
const GAIN:={"step_grass":-9.0,"step_stone":-8.0,"splash_step":-5.0,"ui_click":-8.0,"swing":-4.0,"hit":-3.0,"enemy_hurt":-5.0,"enemy_die":-4.0,"night":3.0,"level_up":-3.0,"build":-3.0,"construction":-6.0,"crystal":-4.0}
const LOOPS:={"amb_day":"Ambience","amb_night":"Ambience","amb_water":"Ambience","jetpack_loop":"SFX"}
const LINES:=["attack_1","attack_2","hurt_1","hurt_2","down","revive","ability","night","dawn","full","level","build"]

var clips:Dictionary={}
var tones:Dictionary={}
var voices:Dictionary={}
var enabled:=true
var last:Dictionary={}
var live:Dictionary={}
var loops:Dictionary={}
var loop_levels:Dictionary={}
var hearth_fire:AudioStreamPlayer3D
var speaking:=0
var shore:=0.0
var shore_check:=0.0
var was_full:=false
var known_level:=-1
var silent:=DisplayServer.get_name()=="headless"

static func ensure_buses()->void:
	for title in ["Music","Ambience","SFX","Voice"]:
		if AudioServer.get_bus_index(title)>=0:continue
		AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,title);AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")

func _ready()->void:
	for kind in ["hit","chop","mine","build","deposit","ability","shot","hurt","night","dawn","step","hammer","crossbow","arc","frost_shell","fuse","blast","gate_move","gate_stop"]:
		tones[kind]=_synthesize(kind)
	if silent:return
	ensure_buses()
	for kind in FILES:
		var list:Array=[]
		for file in FILES[kind]:
			var path:String=DIR+"sfx/"+file+".ogg"
			if ResourceLoader.exists(path):list.append(load(path))
		if not list.is_empty():clips[kind]=list
	for role in 4:
		for line in LINES:
			var path:="%svoice/%d_%s.ogg"%[DIR,role,line]
			if ResourceLoader.exists(path):voices["%d_%s"%[role,line]]=load(path)
	for title in LOOPS:
		var path:String=DIR+"sfx/"+title+".ogg"
		if not ResourceLoader.exists(path):continue
		var player:=AudioStreamPlayer.new();player.stream=_looped(load(path));player.bus=LOOPS[title];player.volume_db=-80
		add_child(player);player.play();loops[title]=player;loop_levels[title]=0.0
	var fire_path:=DIR+"sfx/fire_loop.ogg"
	if ResourceLoader.exists(fire_path):
		hearth_fire=AudioStreamPlayer3D.new();hearth_fire.stream=_looped(load(fire_path));hearth_fire.bus="Ambience"
		hearth_fire.unit_size=4.0;hearth_fire.max_distance=34.0;hearth_fire.volume_db=-7.0;hearth_fire.position=Vector3(0,1.2,0)
		add_child(hearth_fire);hearth_fire.play()
	# Every button in the game gets the same soft click.
	get_tree().node_added.connect(_wire)

func _exit_tree()->void:
	if not silent and get_tree().node_added.is_connected(_wire):get_tree().node_added.disconnect(_wire)

func _wire(node:Node)->void:
	if node is BaseButton and is_ancestor_of_world(node):(node as BaseButton).pressed.connect(func():play("ui_click",-12))

func is_ancestor_of_world(node:Node)->bool:
	var world:=get_parent()
	return world!=null and (world.is_ancestor_of(node) or (world.get_parent()!=null and world.get_parent().is_ancestor_of(node)))

static func _looped(source:AudioStream)->AudioStream:
	# These files are only ever used as loops, so the shared resource itself is marked.
	if source is AudioStreamOggVorbis:(source as AudioStreamOggVorbis).loop=true
	elif source is AudioStreamMP3:(source as AudioStreamMP3).loop=true
	return source

func _pick(kind:String)->AudioStream:
	if clips.has(kind):
		var list:Array=clips[kind]
		return list[randi()%list.size()]
	return tones.get(kind)

## Too many copies of one sound at once is noise, not information.
func _allow(kind:String)->bool:
	var now:=Time.get_ticks_msec()
	if now-int(last.get(kind,-1000))<55 or int(live.get(kind,0))>=5:return false
	last[kind]=now;live[kind]=int(live.get(kind,0))+1
	return true

func _release(kind:String,player:Node)->void:
	live[kind]=maxi(0,int(live.get(kind,1))-1);player.queue_free()

## A sound with no place: interface, your own actions, world events.
func play(kind:String,volume:=-13.0)->void:
	if not enabled or silent:return
	var source:=_pick(kind)
	if source==null or not _allow(kind):return
	var player:=AudioStreamPlayer.new()
	player.stream=source;player.bus="SFX"
	player.volume_db=volume+float(GAIN.get(kind,0.0))+(6.0 if clips.has(kind) else 0.0)
	player.pitch_scale=randf_range(0.94,1.06)
	add_child(player);player.finished.connect(_release.bind(kind,player));player.play()

## A sound that happens somewhere: it gets quieter with distance and sits left or right.
func play_at(kind:String,at:Vector3,volume:=-4.0,pitch:=1.0,reach:=62.0)->void:
	if not enabled or silent:return
	var source:=_pick(kind)
	if source==null:return
	var camera:=get_viewport().get_camera_3d()
	if camera and camera.global_position.distance_to(at)>reach:return
	if not _allow(kind):return
	var player:=AudioStreamPlayer3D.new()
	player.stream=source;player.bus="SFX";player.unit_size=7.0;player.max_distance=reach
	player.volume_db=volume+float(GAIN.get(kind,0.0));player.pitch_scale=pitch*randf_range(0.94,1.06)
	player.position=at;add_child(player);player.finished.connect(_release.bind(kind,player));player.play()

## One of a dwarf's spoken lines, from where they stand. Lines never talk over each other
## for the same dwarf, and at most two dwarves speak at once.
func voice(dwarf:FortPlayer,line:String,chance:=1.0)->void:
	if not enabled or silent or not is_instance_valid(dwarf) or randf()>chance:return
	if line in ["attack","hurt"]:line+="_%d"%(1+randi()%2)
	var key:="%d_%s"%[GameData.role(dwarf.class_id),line]
	var now:=Time.get_ticks_msec()
	if not voices.has(key) or speaking>=2 or now<int(dwarf.get_meta("voice_until",0)):return
	var source:AudioStream=voices[key]
	dwarf.set_meta("voice_until",now+int(source.get_length()*1000.0)+(2600 if line.begins_with("attack") or line.begins_with("hurt") else 700))
	var player:=AudioStreamPlayer3D.new()
	player.stream=source;player.bus="Voice";player.unit_size=9.0;player.max_distance=55.0;player.volume_db=-4.0
	# The second crew of four share the roles but not quite the voices.
	player.pitch_scale=1.07 if dwarf.class_id>=4 else 1.0
	player.position=Vector3(0,1.3,0);dwarf.add_child(player);speaking+=1
	player.finished.connect(func():speaking=maxi(0,speaking-1);player.queue_free())
	player.tree_exiting.connect(func():
		if player.playing:speaking=maxi(0,speaking-1))
	player.play()

func _process(delta:float)->void:
	if silent:return
	var world:=get_parent() as FortWorld
	if world==null:return
	var dwarf:=world.local_player()
	var night:=world.is_night
	# Ambience: birds and breeze by day, crickets and owls at night, water near a shore.
	shore_check-=delta
	if shore_check<=0.0 and dwarf:
		shore_check=.3;var wet:=0
		for i in 12:
			var reach:=5.0 if i<6 else 13.0
			if FortGround.wet(dwarf.position.x+sin(i*TAU/6.0)*reach,dwarf.position.z+cos(i*TAU/6.0)*reach):wet+=2 if i<6 else 1
		shore=clampf(wet/9.0,0.0,1.0)
	var jet:=dwarf!=null and dwarf.travel_mode==2 and dwarf.health>0 and not world.menu_open and Input.is_action_pressed("jump") and dwarf.fuel>0.0 and not dwarf.is_on_floor()
	var wanted:={"amb_day":0.0 if night else .9,"amb_night":.7 if night else 0.0,"amb_water":shore*.9,"jetpack_loop":.5 if jet else 0.0}
	for title in loops:
		var speed:=delta/(.18 if title=="jetpack_loop" else 3.0)
		loop_levels[title]=move_toward(float(loop_levels[title]),float(wanted[title]) if enabled else 0.0,speed)
		(loops[title] as AudioStreamPlayer).volume_db=linear_to_db(maxf(float(loop_levels[title]),.00001))-2.0
	if hearth_fire:hearth_fire.volume_db=-7.0 if enabled else -80.0
	# Music: mellow by day, tense at night, always faded between.
	var music:=world.get_parent().get("music") as FortMusic if world.get_parent() else null
	if music:
		if world.ended:music.play("title",-15.0,5.0)
		elif night:music.play("night",-11.0,3.5)
		else:music.play("day",-15.0,7.0)
	if dwarf==null:return
	# Things the local dwarf remarks on.
	var full:=dwarf.total_carried()>=dwarf.carry_limit
	if full and not was_full:voice(dwarf,"full")
	was_full=full
	var level:int=int(dwarf.get("level")) if dwarf.get("level")!=null else 0
	if known_level>=0 and level>known_level:
		play("level_up",-10);voice(dwarf,"level")
	known_level=level

func _synthesize(kind: String) -> AudioStreamWAV:
	var durations := {"hit":0.15,"chop":0.17,"build":0.3,"deposit":0.55,"ability":0.6,"shot":0.25,"hurt":0.22,"night":1.8,"dawn":1.3,"step":0.07}
	durations["mine"]=0.22
	durations["hammer"]=0.35;durations["crossbow"]=0.18
	durations["arc"]=.22;durations["frost_shell"]=.5
	durations["fuse"]=1.5;durations["blast"]=.65
	durations["gate_move"]=1.8;durations["gate_stop"]=.4
	var duration: float = durations[kind]
	var count := int(duration*22050)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var rng:=RandomNumberGenerator.new()
	rng.seed=kind.hash()
	for i in count:
		var t:=float(i)/22050
		var envelope:=pow(1.0-t/duration,2)*minf(t*120,1)
		var frequency:=120.0
		var noise:=0.0
		match kind:
			"gate_move":frequency=48+sin(t*7)*6;noise=rng.randf_range(-1,1)*(.12+.65*pow(maxf(0,sin(t*75)),14))
			"gate_stop":frequency=55+150*exp(-t*35);noise=rng.randf_range(-1,1)*.7*exp(-t*12)
			"fuse":frequency=650+t*650;noise=rng.randf_range(-1,1)*.7*(.5+.5*sin(t*80))
			"blast":frequency=42+110*exp(-t*16);noise=rng.randf_range(-1,1)*.9*exp(-t*7)
			"arc":frequency=1100*exp(-t*7)+sin(t*400)*160;noise=rng.randf_range(-1,1)*.4
			"frost_shell":frequency=180+500*t;noise=rng.randf_range(-1,1)*.3
			"hammer":frequency=65.0+120*exp(-t*28);noise=rng.randf_range(-1,1)*0.6*exp(-t*8)
			"crossbow":frequency=730*exp(-t*22);noise=rng.randf_range(-1,1)*0.25
			"mine":frequency=1100.0*exp(-t*3);noise=rng.randf_range(-1,1)*0.35*exp(-t*18)
			"hit","chop","hurt","step":
				frequency=90.0+(200.0 if kind=="chop" else 40.0)*exp(-t*35)
				noise=rng.randf_range(-1,1)*0.55
			"shot":frequency=500*exp(-t*20);noise=rng.randf_range(-1,1)*0.4
			"build":frequency=220 if t<0.12 else 330
			"deposit","dawn":frequency=[392.0,493.88,587.33,783.99][mini(3,int(t/duration*4))]
			"ability":frequency=160+t*550
			"night":frequency=98.0
		var sample:float=(sin(TAU*frequency*t)*0.45+sin(TAU*frequency*1.5*t)*0.13+noise)*envelope
		bytes.encode_s16(i*2,int(clampf(sample,-1,1)*22000))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.data=bytes
	return stream
