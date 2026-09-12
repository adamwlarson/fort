extends SceneTree

var failures := 0

func _initialize()->void:
	run.call_deferred()

func check(ok:bool, message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func run()->void:
	var logs := FortArt.asset("campfire_logs")
	check(logs != null, "campfire logs load")
	if logs:
		check(logs.find_children("*","MeshInstance3D",true,false).size()>0,"campfire logs have geometry")
		logs.free()
	for key in ["hearthhold","stockpile","workshop","watchtower","barricade","ballista","mender","raider","brute","sapper","horse","jetpack","stone_deposit","crystal_deposit","lantern","bolt","barrel","supply_crate","pine_tree","birch_tree","fern","wildflowers","moss_rock","ruin_arch","waystone","quarry_cart","camp_tent","cliff_chunk"]:
		var model:=FortArt.asset(key)
		check(model!=null,key+" loads")
		if model==null:continue
		root.add_child(model)
		check(model.find_children("*","MeshInstance3D",true,false).size()>0,key+" has geometry")
		var anim:=FortPlayer.find_animation(model)
		if key in ["raider","brute","sapper","horse","pine_tree","birch_tree"]:
			check(anim!=null,key+" has animation player")
			if anim:
				print(key," clips: ",anim.get_animation_list())
				var expected:PackedStringArray=["Gallop"] if key=="horse" else (["Idle","Hit","Destruction"] if key.ends_with("_tree") else ["Idle","Walk","Attack","Hit","Death"])
				for clip in expected:
					check(anim.has_animation(clip),key+" has "+clip)
					if not anim.has_animation(clip):continue
					anim.play(clip)
					anim.seek(0.3,true)
					var motion:=anim.get_animation(clip)
					check(motion.get_track_count()>0,key+" "+clip+" has tracks")
					var changes:=false
					for track in motion.get_track_count():
						var first:Variant=motion.track_get_key_value(track,0)
						for frame in motion.track_get_key_count(track):
							var value:Variant=motion.track_get_key_value(track,frame)
							if value is Vector3 and first.distance_to(value)>0.001:changes=true
							if value is Quaternion and first.angle_to(value)>0.001:changes=true
					check(changes,key+" "+clip+" contains actual motion")
		model.free()
	for kind in ["Watchtower","Ballista"]:
		var defense:=FortArt.make_defense(kind)
		root.add_child(defense)
		check(defense.get_node_or_null("Turret")!=null,kind+" has aiming pivot")
		defense.free()
	print("ASSET_TEST_", "OK" if failures==0 else "FAILED")
	quit(failures)
