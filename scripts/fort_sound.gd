class_name FortSound
extends Node

var clips: Dictionary = {}
var enabled := true

func _ready() -> void:
	for kind in ["hit","chop","mine","build","deposit","ability","shot","hurt","night","dawn","step","hammer","crossbow","arc","frost_shell","fuse","blast"]:
		clips[kind] = _synthesize(kind)

func play(kind: String, volume := -13.0) -> void:
	if not enabled or DisplayServer.get_name() == "headless" or not clips.has(kind): return
	var player := AudioStreamPlayer.new()
	player.stream = clips[kind]
	player.volume_db = volume
	player.pitch_scale = randf_range(0.94,1.06)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _synthesize(kind: String) -> AudioStreamWAV:
	var durations := {"hit":0.15,"chop":0.17,"build":0.3,"deposit":0.55,"ability":0.6,"shot":0.25,"hurt":0.22,"night":1.8,"dawn":1.3,"step":0.07}
	durations["mine"]=0.22
	durations["hammer"]=0.35;durations["crossbow"]=0.18
	durations["arc"]=.22;durations["frost_shell"]=.5
	durations["fuse"]=1.5;durations["blast"]=.65
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
