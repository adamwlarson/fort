class_name FortSave
extends RefCounted

const FORMAT:=2
const LIMIT:=32*1024*1024
const SLOTS:=["slot1","slot2","slot3","autosave","exit"]
const LABELS:=["Manual slot 1","Manual slot 2","Manual slot 3","Dawn autosave","Save & exit"]
static var test_directory:=""
static func directory()->String:
	if not test_directory.is_empty():return test_directory
	return "res://build/disabled_test_saves" if "--fort-test" in OS.get_cmdline_user_args() else "user://expeditions"
static func path(slot:String)->String:return directory()+"/"+slot+".fortsave"
static func clean(value:Variant)->Variant:
	if value is Object or value is Callable or value is Signal:return null
	if value is Dictionary:
		var result:Dictionary={}
		for k in value:
			if value[k] is Object or value[k] is Callable or value[k] is Signal:continue
			result[k]=clean(value[k])
		return result
	if value is Array:
		var result:Array=[]
		for v in value:result.append(clean(v))
		return result
	return value
static func player_state(p:FortPlayer)->Dictionary:
	var data:Dictionary={"class":p.class_id,"name":p.display_name,"position":p.position,"yaw":p.visual_root.rotation.y}
	for k in ["health","carrying","travel_mode","ability_cooldown","attack_cooldown","rally_time","down_time","look_yaw","look_pitch","fuel","weapon","owned_weapons","loadout_revision","backpack_level","relics","armor","progression_revision","weapon_levels","weapon_revision"]:data[k]=clean(p.get(k))
	return data
static func capture(w:FortWorld)->Dictionary:
	var data:Dictionary={"schema":FORMAT,"saved_at":Time.get_datetime_string_from_system(),"build":"24","world":w.full_state(),"clock":w.clock,"characters":w.saved_characters.duplicate(true),"enemies":{},"defenses":{},"resources":{},"pet_runtime":{},"director":{}}
	data.world.players={};data.world.enemies={};data.world.defenses={}
	for p in w.players.values():data.characters[p.class_id]=player_state(p)
	for id in w.enemies:
		data.enemies[id]=clean(w.enemies[id]);data.enemies[id]["position"]=w.enemies[id].node.position
	for id in w.defenses:
		var d:Dictionary=w.defenses[id];data.defenses[id]=clean(d)
		data.defenses[id]["position"]=d.node.position;data.defenses[id]["rotation"]=d.node.rotation.y
		data.defenses[id]["owner_class"]=w.players[d.get("work_owner",0)].class_id if w.players.has(d.get("work_owner",0)) else d.get("owner_class",-1)
	for id in w.resource_nodes:data.resources[id]={"amount":w.resource_nodes[id].amount,"respawn":w.resource_nodes[id].respawn}
	for id in w.pets.pets:
		data.pet_runtime[id]=clean(w.pets.pets[id])
		data.pet_runtime[id].net_pos=w.pets.pets[id].node.position;data.pet_runtime[id].net_yaw=w.pets.pets[id].node.rotation.y
	for k in ["active","night","crew","hearth","duration","cutoff","pulses","pulse","lane_base","elapsed","total","spent","allowance","pulse_spent","next_spawn","sequence","pending_kind","warning_pulse","revision","metrics","reports"]:data.director[k]=clean(w.director.get(k))
	data.director["rng"]=w.director.rng.state;data["expedition_rng"]=w.expedition.rng.state
	data["castle_tick"]=w.castle.next_tick;data["encounter_tick"]=w.encounters.next_check
	data["next_enemy"]=w.next_enemy_id;data["next_defense"]=w.next_defense_id;data["next_pet"]=w.pets.next_id
	return data
static func validate(data:Variant)->String:
	if not data is Dictionary or data.get("schema",-1) not in [1,FORMAT]:return "Unsupported save format"
	if not data.has_all(["saved_at","clock","castle_tick","encounter_tick","next_enemy","next_defense","next_pet","expedition_rng"]):return "Incomplete checkpoint"
	if not data.saved_at is String:return "Invalid save date"
	for k in ["clock","castle_tick","encounter_tick","next_enemy","next_defense","next_pet","expedition_rng"]:
		if not number(data[k]):return "Invalid checkpoint timer / ID"
	for k in ["world","characters","enemies","defenses","resources","director","pet_runtime"]:
		if not data.get(k) is Dictionary:return "Missing save section: "+k
	var s:Dictionary=data.world
	for k in ["expedition","pets","progression","encounters","castle","shared"]:
		if not s.get(k) is Dictionary:return "Missing world section: "+k
	if not s.has_all(["hearth_level","wave","night","time","fort","level","crystals","ended","victory","raid_spawned","solo_rescue_wave"]):return "Incomplete expedition state"
	for k in ["hearth_level","wave","time","fort","level","crystals","raid_spawned","solo_rescue_wave"]:
		if not number(s[k]):return "Invalid expedition value"
	if int(s.hearth_level)<1 or int(s.hearth_level)>GameData.MAX_HEARTH or int(s.wave)<0:return "Invalid expedition tier / day"
	if s.ended or float(s.fort)<=0:return "This expedition has already ended"
	if not s.castle.get("rooms") is Dictionary or not s.castle.rooms.has("0:0:0") or s.castle.rooms.size()>128:return "Invalid castle layout"
	if not s.castle.has_all(["revision","research"]) or not s.expedition.has_all(["seed","event","revision","time","claimed","boss_night","bosses_defeated"]):return "Incomplete castle / world seed"
	if data.characters.size()>GameData.MAX_PLAYERS or data.enemies.size()>2000 or data.defenses.size()>10000 or data.resources.size()>20000:return "Save exceeds supported world limits"
	for id in data.characters:
		if not id is int or not data.characters[id] is Dictionary:return "Invalid dwarf slot"
		var p:Dictionary=data.characters[id]
		if int(id)<0 or int(id)>=GameData.MAX_PLAYERS or not p.has_all(["position","weapon","owned_weapons","weapon_levels","health","carrying","backpack_level","relics","armor","progression_revision","loadout_revision","weapon_revision"]):return "Invalid dwarf slot"
		if not p.position is Vector3 or not p.position.is_finite() or not GameData.WEAPONS.has(p.weapon):return "Invalid dwarf location / equipment"
		if not p.get("yaw") is float or not p.carrying is Dictionary or not p.weapon_levels is Dictionary or not strings(p.owned_weapons) or not strings(p.relics):return "Invalid dwarf equipment data"
		for k in ["health","backpack_level","progression_revision","loadout_revision","weapon_revision"]:
			if not number(p[k]):return "Invalid dwarf stats"
	for id in data.defenses:
		if not id is int or not data.defenses[id] is Dictionary:return "Invalid defense record"
		var d:Dictionary=data.defenses[id]
		if not d.has_all(["kind","position","rotation","hp","max_hp","level","temporary"]) or not GameData.RECIPES.has(d.kind):return "Invalid saved defense"
		if not d.position is Vector3 or not d.position.is_finite():return "Invalid defense location"
		if d.kind=="Gatehouse":
			for k in ["gate_open","gate_target"]:
				if not number(d.get(k,1.0)) or float(d.get(k,1))<0 or float(d.get(k,1))>1:return "Invalid gate mechanism position"
			if not d.get("gate_auto",false) is bool or not number(d.get("gate_revision",0)):return "Invalid gate settings"
	for id in data.enemies:
		if not id is int or not data.enemies[id] is Dictionary:return "Invalid enemy record"
		var e:Dictionary=data.enemies[id]
		if not e.has_all(["kind","position","hp","max_hp","camp"]):return "Invalid saved enemy"
		if e.kind not in ["Raider","Brute","Sapper","Ashwing","EmberRunner","Chieftain","Cinderlobber","Bombwing","Shieldguard","Hexer","Colossus","Prowler","Razorback","Direwolf","Stonebear","Emberdrake","Frostwyrm"]:return "Unknown enemy type"
		if not e.position is Vector3 or not e.position.is_finite():return "Invalid enemy position"
	for id in data.resources:
		var r:Variant=data.resources[id]
		if not id is int or not r is Dictionary or not r.has_all(["amount","respawn"]):return "Invalid resource record"
		if not number(r.amount) or not number(r.respawn) or r.amount<0:return "Invalid resource amount"
	for key in s.castle.rooms:
		var r:Variant=s.castle.rooms[key]
		if not r is Dictionary or not r.has_all(["x","z","floor","kind","complete","funded","work","total","sign","walls","task","resource"]):return "Invalid castle room"
		if not number(r.x) or not number(r.z) or not number(r.floor) or r.floor<0 or r.floor>=8:return "Invalid castle storey"
		if key!=FortCastle.key(r.x,r.z,r.floor) or (r.kind!="Keep" and not FortCastle.TYPES.has(r.kind)):return "Invalid castle room type"
		if not r.funded is Dictionary or not r.walls is Array or not r.sign is Vector3:return "Invalid castle project ledger"
		if r.task=="remodel" and not FortCastle.TYPES.has(r.get("remodel_kind","")):return "Invalid room remodeling project"
	if not strings(s.castle.research):return "Invalid research"
	if not strings(s.castle.get("cleared_scenery",[])) or s.castle.get("cleared_scenery",[]).size()>4096:return "Invalid cleared scenery"
	if not s.pets.get("list") is Array or s.pets.list.size()>3 or not number(s.pets.get("revision")):return "Invalid pets"
	for p in s.pets.list:
		if not p is Dictionary or not p.has_all(["id","kind","resource","cargo_kind","cargo","mode","revision","pos","yaw"]):return "Invalid pet record"
		if not number(p.kind) or p.kind<0 or p.kind>=FortPets.SPECS.size() or not p.pos is Vector3:return "Invalid pet type / location"
	for k in ["active","night","crew","hearth","duration","cutoff","pulses","pulse","lane_base","elapsed","total","spent","allowance","pulse_spent","next_spawn","sequence","pending_kind","warning_pulse","revision","metrics","reports","rng"]:
		if not data.director.has(k):return "Incomplete raid director"
	if not data.director.metrics is Dictionary or not data.director.reports is Array:return "Invalid raid history"
	for report in data.director.reports:
		if not report is Dictionary:return "Invalid raid report"
	for k in GameData.RESOURCES:
		if not s.shared.has(k) or int(s.shared[k])<0:return "Invalid shared stockpile"
	return ""
static func number(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value))
static func strings(value:Variant)->bool:
	if value is PackedStringArray:return true
	if not value is Array:return false
	for item in value:
		if not item is String:return false
	return true
static func read_file(filename:String)->Dictionary:
	if not FileAccess.file_exists(filename):return {"error":"Empty slot"}
	var file:=FileAccess.open(filename,FileAccess.READ)
	if not file:return {"error":"Cannot read save"}
	if file.get_length()<40 or file.get_length()>LIMIT:return {"error":"Truncated or oversized save"}
	var magic:=file.get_buffer(8).get_string_from_ascii();var checksum:=file.get_buffer(32);var bytes:=file.get_buffer(file.get_length()-40);file.close()
	if magic!="FORTSAVE":return {"error":"Not a Fort save"}
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	if hash.finish()!=checksum:return {"error":"Save checksum failed"}
	var data:Variant=bytes_to_var(bytes) # Objects are never decoded / instantiated.
	var error:=validate(data)
	return {"data":data,"error":""} if error=="" else {"error":error}
static func read_slot(slot:String)->Dictionary:
	if slot not in SLOTS:return {"error":"Unknown slot"}
	var result:=read_file(path(slot))
	if result.error!="":
		var backup:=read_file(path(slot)+".bak")
		if backup.error=="":backup["recovered"]=true;return backup
	return result
static func write_slot(slot:String,w:FortWorld)->String:
	if slot not in SLOTS:return "Unknown slot"
	if not w.multiplayer.is_server():return "Only the host can save this expedition"
	if w.ended:return "Cannot save an ended expedition"
	var data:=capture(w);var error:=validate(data)
	if error!="":return error
	var folder:=ProjectSettings.globalize_path(directory())
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:return "Cannot create save folder"
	var filename:=ProjectSettings.globalize_path(path(slot));var temporary:=filename+".tmp";var backup:=filename+".bak"
	var bytes:=var_to_bytes(data)
	if bytes.size()>LIMIT-40:return "Expedition exceeds the save size limit"
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if not file:return "Cannot write save: "+error_string(FileAccess.get_open_error())
	file.store_buffer("FORTSAVE".to_ascii_buffer());file.store_buffer(hash.finish());file.store_buffer(bytes);file.flush();var write_error:=file.get_error();file.close()
	if write_error!=OK or read_file(temporary).error!="":return "Could not verify the new save; previous save preserved"
	# Only rotate a verified old primary; never replace a good backup with corrupt bytes.
	if FileAccess.file_exists(filename) and read_file(filename).error=="":
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup)!=OK:return "Cannot rotate save backup"
		if DirAccess.rename_absolute(filename,backup)!=OK:return "Cannot back up the previous save"
	elif FileAccess.file_exists(filename):
		if DirAccess.remove_absolute(filename)!=OK:return "Cannot replace damaged primary save"
	if DirAccess.rename_absolute(temporary,filename)!=OK:return "Cannot finish save; previous checkpoint remains in backup"
	return ""
static func restore(w:FortWorld,data:Dictionary)->void:
	var s:Dictionary=data.world
	w.clock=float(data.clock);w.saved_characters=data.characters.duplicate(true)
	w.expedition.receive(s.expedition)
	# Never bury buildings from a pre-terrain checkpoint. This compatibility flag
	# is saved and sent to peers, so everyone reconstructs the same world.
	if not s.expedition.has("terrain_enabled"):
		for d in data.defenses.values():
			if FortTerrain.reserved(d.position,w.expedition.seed_value,5):w.expedition.terrain_enabled=false
		for r in s.castle.rooms.values():
			if FortTerrain.reserved(FortCastle.position(r),w.expedition.seed_value,15):w.expedition.terrain_enabled=false
	w.set_hearth_level(s.hearth_level)
	w.progression.receive(s.progression);w.encounters.unlock(w.hearth_level);w.encounters.receive(s.encounters)
	w.shared=s.shared.duplicate();w.workshop_level=s.level;w.lifetime_crystal=s.crystals;w.fort_health=s.fort
	w.is_night=s.night;w.wave=s.wave;w.phase_time=s.time;w.raid_spawned=s.raid_spawned;w.solo_rescue_wave=s.solo_rescue_wave
	for id in data.resources:
		if w.resource_nodes.has(id):w.recv_resource(id,data.resources[id].amount,false);w.resource_nodes[id].respawn=data.resources[id].respawn
	for id in data.defenses:
		var saved:Dictionary=data.defenses[id];w.recv_defense(id,saved.kind,saved.position,saved.rotation,saved.max_hp,saved.temporary)
		var d:Dictionary=w.defenses[id]
		for k in saved:
			if k not in ["position","rotation","visual_level","work_visual_stage","occupant","work_owner"]:d[k]=saved[k]
		d.occupant=-1;d.work_owner=1;w.construction.visual(d);w.progression.defense_visual(d);FortBattlements.pose(d)
	w.castle.receive(s.castle);w.castle.rebuild();w.castle.next_tick=data.castle_tick
	for id in data.enemies:
		var saved:Dictionary=data.enemies[id];w.recv_enemy(id,saved.kind,saved.position,saved.max_hp,saved.camp)
		var e:Dictionary=w.enemies[id];e.merge(saved,true)
		# Resume ongoing enemies, but re-telegraph attacks instead of invisible saved projectiles.
		for k in ["windup","slam_at","strike_at","dive_at","fuse_at"]:e[k]=0.0
		e.attack=maxf(2.0,e.attack);e.taunt=-1;e.route_until=0;e.route_points=[]
		e.node.rotation.y=float(e.get("yaw",0))
	w.pets.receive(s.pets);w.pets.next_id=data.next_pet
	for id in w.pets.pets:
		var p:Dictionary=w.pets.pets[id]
		if data.pet_runtime.has(id):p.merge(data.pet_runtime[id],true)
		p.node.position=p.net_pos;p.node.rotation.y=p.net_yaw;p.target=-1;p.mode="RETURN" if p.cargo>0 else "SEEK"
	for k in data.director:
		if k=="reports":w.director.reports.assign(data.director.reports)
		elif k!="rng":w.director.set(k,data.director[k])
	w.director.rng.state=data.director.rng;w.expedition.rng.state=data.expedition_rng
	w.encounters.next_check=data.encounter_tick;w.next_enemy_id=data.next_enemy;w.next_defense_id=data.next_defense
	w._update_lighting(100)
static func restore_player(w:FortWorld,p:FortPlayer)->void:
	if not w.saved_characters.has(p.class_id):return
	var saved:Dictionary=w.saved_characters[p.class_id]
	p.apply_progression(saved.backpack_level,PackedStringArray(saved.relics),saved.armor,saved.progression_revision)
	w.recv_loadout(p.peer_id,PackedStringArray(saved.owned_weapons),saved.weapon,saved.loadout_revision)
	p.apply_weapon_levels(saved.weapon_levels,saved.weapon_revision)
	for k in ["health","carrying","ability_cooldown","attack_cooldown","rally_time","down_time","look_yaw","look_pitch","fuel"]:
		if saved.has(k):p.set(k,clean(saved[k]))
	p.set_travel_mode(int(saved.get("travel_mode",0)));p.position=saved.position;p.target_position=p.position
	if w.hearth_level>=2 and w.expedition.terrain_enabled and FortTerrain.reserved(p.position,w.expedition.seed_value):
		p.position=FortTerrain.safe_position(p.position,w.expedition.seed_value);p.target_position=p.position
	p.visual_root.rotation.y=saved.yaw;p.target_yaw=saved.yaw;p.invulnerable=3.0
	for d in w.defenses.values():
		if d.get("owner_class",-1)==p.class_id:d.work_owner=p.peer_id
