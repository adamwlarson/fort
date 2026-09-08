extends Node

const WorldScript = preload("res://scripts/world.gd")
const InternetScript = preload("res://scripts/fort_internet.gd")
const BUILD_VERSION := "19"

var menu:Control
var status_label:Label
var address_edit:LineEdit
var name_edit:LineEdit
var class_picker:OptionButton
var class_description:Label
var world:Node
var player_info:Dictionary = {}
var selected_class := 0
var ready_peers: Dictionary = {}
var preview_holder: Node3D
var preview_dwarf: Node3D
var port_edit: SpinBox
var connection_buttons: HBoxContainer
var cancel_connection: Button
var lobby: PanelContainer
var lobby_roster: VBoxContainer
var lobby_action: Button
var session_port := 24567
var connecting := false
var connection_deadline := 0
var lobby_active := false
var returning_to_menu := false
var internet: FortInternet
var internet_toggle: CheckBox
var internet_label: Label
var public_copy: Button
var transport_connected := false
var pending_save:Dictionary={}
var save_menu:FortSaveMenu

func _process(_delta: float) -> void:
	if connecting and Time.get_ticks_msec() > connection_deadline:
		_on_connection_failed()

func _ready() -> void:
	internet = InternetScript.new()
	add_child(internet)
	internet.changed.connect(_refresh_internet)
	# Every game RPC goes through the host; no peer-to-peer relay is needed.
	multiplayer.server_relay = false
	get_window().title = "FORT — Hold the Hearth"
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_build_menu()
	save_menu=FortSaveMenu.new();save_menu.main=self;add_child(save_menu)
	get_tree().auto_accept_quit=false
	if "--autohost" in OS.get_cmdline_user_args():
		_host.call_deferred()
	elif "--autojoin" in OS.get_cmdline_user_args():
		_join.call_deferred()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_preview.call_deferred()

func _capture_preview()->void:
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://build/preview.png"))
	get_tree().quit()

func _notification(what:int)->void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(world) and multiplayer.is_server() and not world.ended and world.autosave_enabled:
			if not world.save_expedition("exit"):return
		if internet:internet.stop()
		get_tree().quit()

func load_expedition(slot:String)->void:
	if is_instance_valid(world) or lobby_active or connecting:return
	var result:=FortSave.read_slot(slot)
	if result.error!="":status_label.text="Load failed: "+result.error;return
	pending_save=result.data
	_host()
	if not lobby_active:pending_save={};return
	if result.get("recovered",false):internet_label.text+="\nRecovered the previous backup checkpoint."

func save_and_leave()->void:
	if not is_instance_valid(world) or not multiplayer.is_server():return
	if world.save_expedition("exit"):_leave_game("Expedition saved. Load 'Save & exit' to continue.")

func _build_menu() -> void:
	preview_holder=null
	preview_dwarf=null
	if is_instance_valid(menu): menu.queue_free()
	menu = Control.new()
	menu.theme = FortInterface.theme()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = Color("#101e22")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)
	var glow := ColorRect.new()
	glow.color = Color("#193235")
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = 0
	glow.offset_top = 410
	menu.add_child(glow)
	var crest:=FortIcon.new()
	crest.kind="crest";crest.position=Vector2(74,61);crest.size=Vector2(72,72)
	menu.add_child(crest)
	var rule:=ColorRect.new()
	rule.color=FortInterface.GOLD.darkened(0.4);rule.position=Vector2(74,181);rule.size=Vector2(1120,1)
	menu.add_child(rule)
	var title := Label.new()
	title.text = "F O R T"
	title.position = Vector2(158, 48)
	title.add_theme_font_size_override("font_size", 74)
	title.add_theme_color_override("font_color", Color("f6c563"))
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "HOLD THE HEARTH.  BRING EVERYONE HOME."
	subtitle.position = Vector2(82, 144)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("a9bac3"))
	menu.add_child(subtitle)

	var panel := PanelContainer.new()
	panel.position = Vector2(72, 205)
	panel.size = Vector2(500, 465)
	panel.add_theme_stylebox_override("panel", _panel_style(FortInterface.INK, Color("#6b735f")))
	menu.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	var prompt := Label.new()
	prompt.text = "01  /  MUSTER YOUR CREW"
	prompt.add_theme_font_size_override("font_size", 22)
	stack.add_child(prompt)
	var identity:=Label.new()
	identity.text="YOUR NAME & DWARF CLASS";identity.add_theme_font_size_override("font_size",12);identity.modulate=FortInterface.MUTED
	stack.add_child(identity)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Dwarf name"
	name_edit.text = "Dwarf %d" % randi_range(10, 99)
	stack.add_child(name_edit)
	class_picker = OptionButton.new()
	for entry in GameData.CLASSES: class_picker.add_item(entry.name)
	class_picker.item_selected.connect(_on_class_selected)
	stack.add_child(class_picker)
	class_description = Label.new()
	class_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	class_description.custom_minimum_size.y = 48
	stack.add_child(class_description)
	_on_class_selected(0)
	var connection:=Label.new()
	connection.text="02  /  HOST A FORT OR JOIN BY IP";connection.add_theme_font_size_override("font_size",13);connection.modulate=FortInterface.GOLD
	stack.add_child(connection)
	address_edit = LineEdit.new()
	address_edit.placeholder_text = "Host IP or IP:port (LAN / public)"
	if "--fort-test" in OS.get_cmdline_user_args(): address_edit.text = "127.0.0.1"
	var endpoint := HBoxContainer.new()
	stack.add_child(endpoint)
	address_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	endpoint.add_child(address_edit)
	port_edit = SpinBox.new()
	port_edit.update_on_text_changed = true
	port_edit.min_value = 1; port_edit.max_value = 65535; port_edit.value = GameData.network_port()
	port_edit.prefix = "UDP "
	port_edit.custom_minimum_size.x = 145
	endpoint.add_child(port_edit)
	internet_toggle = CheckBox.new()
	internet_toggle.text = "Internet hosting: request router UDP mapping (UPnP)"
	internet_toggle.add_theme_font_size_override("font_size", 12)
	internet_toggle.button_pressed = not "--fort-test" in OS.get_cmdline_user_args()
	internet_toggle.tooltip_text = "When hosting, asks your router to forward only the selected UDP port. Removes the mapping on normal exit. Does not change Windows Firewall. Uncheck for LAN-only / manual forwarding."
	stack.add_child(internet_toggle)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	connection_buttons = row
	stack.add_child(row)
	var host_button := _button("HOST FORT", Color("c48a3a"))
	host_button.pressed.connect(_host)
	row.add_child(host_button)
	var join_button := _button("JOIN CREW", Color("337b83"))
	join_button.pressed.connect(_join)
	row.add_child(join_button)
	status_label = Label.new()
	status_label.text = "FORT %s / Both players need the same version and port.\nHost opens a lobby. 127.0.0.1 only works on this PC." % BUILD_VERSION
	status_label.add_theme_font_size_override("font_size",13)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("a9bac3"))
	stack.add_child(status_label)
	cancel_connection = Button.new()
	cancel_connection.text = "Cancel connection"
	cancel_connection.pressed.connect(func(): _leave_game("Connection cancelled."))
	stack.add_child(cancel_connection)
	cancel_connection.hide()

	var guide := Label.new()
	guide.position = Vector2(650, 563)
	guide.size = Vector2(530, 120)
	guide.text="GATHER / BUILD / DEFEND / RETURN\nSaved dwarves are restored by class. Select your previous\nclass, then load an expedition to open its host lobby."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 16)
	guide.add_theme_color_override("font_color", Color("d8e3e5"))
	guide.add_theme_constant_override("line_spacing", 5)
	menu.add_child(guide)
	var load_button:=Button.new();load_button.text="LOAD EXPEDITION";load_button.position=Vector2(650,648);load_button.size=Vector2(530,40);menu.add_child(load_button)
	load_button.pressed.connect(func():save_menu.open_panel(false))
	var preview_frame:=PanelContainer.new()
	preview_frame.position=Vector2(642,202);preview_frame.size=Vector2(541,341)
	preview_frame.add_theme_stylebox_override("panel",FortInterface.frame(true));menu.add_child(preview_frame)
	_build_class_preview()

func _build_class_preview()->void:
	var container:=SubViewportContainer.new()
	container.position=Vector2(645,205)
	container.size=Vector2(535,335)
	container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	menu.add_child(container)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(535,335)
	viewport.own_world_3d=true
	container.add_child(viewport)
	preview_holder=Node3D.new()
	viewport.add_child(preview_holder)
	var camera:=Camera3D.new()
	camera.position=Vector3(2.3,1.7,3.6)
	preview_holder.add_child(camera)
	camera.look_at(Vector3(0,0.9,0))
	camera.fov=40
	camera.current=true
	var env:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color("#192a2d")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("#9fbccc")
	settings.ambient_light_energy=0.5
	env.environment=settings
	preview_holder.add_child(env)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-45,-35,0)
	light.light_color=Color("#ffe2b3")
	light.light_energy=0.85
	light.shadow_enabled=true
	preview_holder.add_child(light)
	preview_holder.add_child(Visuals.cylinder(1.3,0.1,Color("#58645d"),Vector3(0,-0.05,0)))
	_replace_preview_dwarf()

func _replace_preview_dwarf()->void:
	if not is_instance_valid(preview_holder):return
	if is_instance_valid(preview_dwarf):
		preview_holder.remove_child(preview_dwarf)
		preview_dwarf.queue_free()
	preview_dwarf=preload("res://assets/models/dwarf.glb").instantiate()
	preview_holder.add_child(preview_dwarf)
	FortArt.tint_dwarf(preview_dwarf,selected_class)
	var anim:=FortPlayer.find_animation(preview_dwarf)
	if anim:
		anim.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR
		anim.play("Idle")

func _panel_style(color:Color, border:Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(22)
	return style

func _button(label:String, color:Color) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := _panel_style(color.darkened(0.18), color)
	normal.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover",_panel_style(color.darkened(0.05),FortInterface.PAPER))
	button.add_theme_stylebox_override("pressed",_panel_style(color.darkened(0.35),FortInterface.GOLD))
	button.add_theme_font_size_override("font_size", 16)
	return button

func _on_class_selected(index:int) -> void:
	selected_class = index
	var data := GameData.class_data(index)
	class_description.text = "%s — %s\n%s" % [data.ability, data.name, data.desc]
	class_description.add_theme_color_override("font_color", data.color.lightened(0.22))
	_replace_preview_dwarf()

func _host() -> void:
	if is_instance_valid(world) or lobby_active or connecting:return
	session_port = int(port_edit.value)
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip("*")
	var error := peer.create_server(session_port, GameData.MAX_PLAYERS - 1)
	if error != OK:
		status_label.text = "Could not host on UDP %d: %s. Try another port." % [session_port, error_string(error)]
		return
	multiplayer.multiplayer_peer = peer
	player_info = {1:{"name":_safe_name(), "class":selected_class, "ready":true}}
	lobby_active = true
	transport_connected = false
	_show_lobby()
	if internet_toggle.button_pressed: internet.start(session_port)
	else: internet.stop()
	print("FORT_NET listening UDP ", session_port, " build ", BUILD_VERSION)

static func parse_endpoint(text: String, fallback_port: int) -> Dictionary:
	var address := text.strip_edges()
	var port := fallback_port
	if address.begins_with("["):
		var closing := address.find("]")
		if closing < 0: return {}
		var suffix := address.substr(closing + 1)
		if not suffix.is_empty():
			if not suffix.begins_with(":") or not suffix.substr(1).is_valid_int(): return {}
			port = int(suffix.substr(1))
		address = address.substr(1, closing - 1)
	elif address.count(":") == 1:
		var parts := address.split(":")
		if not parts[1].is_valid_int(): return {}
		port = int(parts[1]); address = parts[0]
	if not address.is_valid_ip_address() or port < 1 or port > 65535: return {}
	return {"address": address, "port": port}

func _join() -> void:
	if is_instance_valid(world) or lobby_active or connecting:return
	var endpoint := parse_endpoint(address_edit.text, int(port_edit.value))
	if endpoint.is_empty():
		status_label.text = "Enter a valid host IP or IP:port. Use [IPv6]:port for IPv6, and 127.0.0.1 only on this PC."
		return
	var address: String = endpoint.address
	session_port = int(endpoint.port)
	address_edit.text = address; port_edit.value = session_port
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, session_port)
	if error != OK:
		status_label.text = "Could not start connection: %s" % error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	connecting = true
	transport_connected = false
	connection_deadline = Time.get_ticks_msec() + 15000
	connection_buttons.hide(); cancel_connection.show()
	status_label.text = "Contacting %s : UDP %d (15s timeout)...\nHost must be in a lobby or game running Fort %s." % [address, session_port, BUILD_VERSION]
	print("FORT_NET contacting ", address, " UDP ", session_port, " build ", BUILD_VERSION)

func lan_endpoints() -> PackedStringArray:
	var addresses := PackedStringArray()
	var preferred := PackedStringArray()
	for adapter in IP.get_local_interfaces():
		for address in adapter.addresses:
			if ":" in address or address.begins_with("127.") or address.begins_with("169.254."):continue
			var entry := "%s  —  %s" % [address, adapter.friendly]
			if adapter.friendly in ["Ethernet","Wi-Fi","WiFi"]:preferred.append(entry)
			else:addresses.append(entry)
	preferred.append_array(addresses)
	return preferred

func _show_lobby() -> void:
	if is_instance_valid(lobby): lobby.queue_free()
	for child in menu.get_children():
		if child is Control and child.position.y>=190:child.hide()
	lobby = PanelContainer.new()
	lobby.position = Vector2(64,194); lobby.size = Vector2(1130,494)
	lobby.add_theme_stylebox_override("panel", _panel_style(FortInterface.INK, FortInterface.GOLD))
	menu.add_child(lobby)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6); lobby.add_child(stack)
	var title := Label.new(); title.text = "CREW LOBBY  /  FORT " + BUILD_VERSION; title.add_theme_font_size_override("font_size",28); stack.add_child(title)
	var address := Label.new()
	address.add_theme_font_size_override("font_size",15)
	if multiplayer.is_server():
		address.text = "HOSTING ON UDP %d · Same network: use your Ethernet / Wi-Fi IP below.\nDifferent networks: use the public IP and check router status below." % session_port
		if lan_endpoints().is_empty():address.text += "\nNo LAN IPv4 address found. Check your network connection."
	else: address.text = "CONNECTED TO %s  /  UDP %d\nChoose Ready. The host starts when the crew is ready." % [address_edit.text, session_port]
	stack.add_child(address)
	if multiplayer.is_server() and not lan_endpoints().is_empty():
		var address_row := HBoxContainer.new();stack.add_child(address_row)
		var picker := OptionButton.new();picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		for entry in lan_endpoints():picker.add_item(entry)
		address_row.add_child(picker)
		var copy := Button.new();copy.text="COPY IP";address_row.add_child(copy)
		copy.pressed.connect(func():DisplayServer.clipboard_set(picker.get_item_text(picker.selected).get_slice("  —  ",0)))
	internet_label = null; public_copy = null
	if multiplayer.is_server():
		var internet_row := HBoxContainer.new(); stack.add_child(internet_row)
		internet_label = Label.new()
		internet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		internet_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		internet_label.add_theme_font_size_override("font_size", 13)
		internet_row.add_child(internet_label)
		public_copy = Button.new(); public_copy.text = "COPY PUBLIC IP"
		public_copy.pressed.connect(func():
			if FortInternet.public_ipv4(internet.external_address): DisplayServer.clipboard_set(internet.external_address))
		internet_row.add_child(public_copy)
		var retry := Button.new(); retry.text = "RETRY UPnP"
		retry.tooltip_text = "Ask the router again to map this UDP port for internet hosting."
		retry.pressed.connect(func(): internet.start(session_port))
		internet_row.add_child(retry)
		_refresh_internet()
	lobby_roster = VBoxContainer.new(); lobby_roster.add_theme_constant_override("separation",8); stack.add_child(lobby_roster)
	var note := Label.new()
	note.text = "Allow THIS Fort.exe in Windows Firewall. Router mapping does not bypass the firewall.\nPublic-IP tests need a player on another internet connection. No relay / CGNAT bypass."
	note.add_theme_font_size_override("font_size",13); note.modulate = FortInterface.MUTED; stack.add_child(note)
	var row := HBoxContainer.new(); stack.add_child(row)
	lobby_action = _button("", Color("337b83")); row.add_child(lobby_action)
	lobby_action.pressed.connect(_lobby_pressed)
	var leave := _button("LEAVE LOBBY", Color("755348")); row.add_child(leave)
	leave.pressed.connect(func(): _leave_game("Left the lobby."))
	_refresh_lobby()

func _refresh_internet() -> void:
	if is_instance_valid(internet_label): internet_label.text = internet.status
	if is_instance_valid(public_copy): public_copy.disabled = not FortInternet.public_ipv4(internet.external_address)
	print("FORT_NET router: ", internet.status)

func _refresh_lobby() -> void:
	if not is_instance_valid(lobby_roster):return
	for child in lobby_roster.get_children():lobby_roster.remove_child(child);child.queue_free()
	for i in GameData.MAX_PLAYERS:
		var label := Label.new(); label.custom_minimum_size.y = 35
		if i < player_info.size():
			var id: int = player_info.keys()[i]
			var info: Dictionary = player_info[id]
			label.text = "%02d   %s%s   /   %s   /   %s" % [i+1, info.name, " (HOST)" if id==1 else "", GameData.class_data(info["class"]).name, "READY" if info.get("ready",false) else "PREPARING"]
			label.modulate = GameData.class_data(info["class"]).color.lightened(0.3)
		else: label.text = "%02d   Waiting for a dwarf…" % (i+1); label.modulate = FortInterface.MUTED
		lobby_roster.add_child(label)
	if multiplayer.is_server():
		lobby_action.text = "START EXPEDITION (%d / 4)" % player_info.size()
		if not pending_save.is_empty():lobby_action.text="RESUME DAY %d (%d / 4)"%[int(pending_save.world.wave)+ (0 if pending_save.world.night else 1),player_info.size()]
		lobby_action.disabled = not _crew_ready()
	else:
		lobby_action.text = "NOT READY" if player_info.get(multiplayer.get_unique_id(),{}).get("ready",false) else "READY UP"

func _crew_ready() -> bool:
	if player_info.is_empty():return false
	for info in player_info.values():
		if not info.get("ready",false):return false
	return true

func _lobby_pressed() -> void:
	if multiplayer.is_server():_start_match()
	else: set_lobby_ready.rpc_id(1, not player_info.get(multiplayer.get_unique_id(),{}).get("ready",false))

@rpc("any_peer", "call_remote", "reliable")
func set_lobby_ready(value: bool) -> void:
	if not multiplayer.is_server() or not lobby_active:return
	var id := multiplayer.get_remote_sender_id()
	if not player_info.has(id):return
	player_info[id].ready = value
	_sync_lobby()

func _sync_lobby() -> void:
	_refresh_lobby()
	for id in player_info:
		if id != 1: receive_lobby.rpc_id(id, player_info)

@rpc("authority", "call_remote", "reliable")
func receive_lobby(roster: Dictionary) -> void:
	connecting = false
	player_info = roster
	if not lobby_active:
		lobby_active = true; _show_lobby()
	else:_refresh_lobby()

func _start_match() -> void:
	if not multiplayer.is_server() or not lobby_active or not _crew_ready() or is_instance_valid(world):return
	lobby_active = false
	_start_world()
	var resuming:=not pending_save.is_empty()
	if resuming:FortSave.restore(world,pending_save);pending_save={}
	world.add_network_player(1, player_info[1])
	for id in player_info:
		if id == 1:continue
		world.prepare_network_player(id, player_info[id])
		begin_remote.rpc_id(id, player_info)
	if not resuming:world.configure_opening_day()

func _safe_name() -> String:
	var value := name_edit.text.strip_edges().left(18)
	return value if not value.is_empty() else "Nameless Dwarf"

func _on_connected() -> void:
	transport_connected = true
	connection_deadline = Time.get_ticks_msec() + 15000
	status_label.text = "Host reached. Waiting for Fort %s lobby registration..." % BUILD_VERSION
	print("FORT_NET transport connected; registering lobby")
	register_player.rpc_id(1, _safe_name(), selected_class)

func _on_peer_connected(_peer_id:int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func register_player(display_name:String, class_id:int) -> void:
	if not multiplayer.is_server(): return
	var peer_id := multiplayer.get_remote_sender_id()
	if player_info.has(peer_id):return
	if player_info.size() >= GameData.MAX_PLAYERS:
		connection_rejected.rpc_id(peer_id)
		return
	var taken:Array=[]
	class_id = clampi(class_id,0,3)
	for info in player_info.values():taken.append(int(info["class"]))
	if class_id in taken:
		for candidate in 4:
			if candidate not in taken:class_id=candidate;break
	var info := {"name":display_name.strip_edges().left(18), "class":class_id, "ready":false}
	if info.name.is_empty():info.name = "Nameless Dwarf"
	player_info[peer_id] = info
	if is_instance_valid(world):
		world.prepare_network_player(peer_id, info)
		begin_remote.rpc_id(peer_id, player_info)
	else:_sync_lobby()

@rpc("any_peer","call_remote","reliable")
func client_world_ready()->void:
	if not multiplayer.is_server():return
	var peer_id:=multiplayer.get_remote_sender_id()
	if is_instance_valid(world):
		if not player_info.has(peer_id):return
		for other_id in _connected_ready():
			deliver_world.rpc_id(int(other_id),"recv_player",[peer_id,player_info[peer_id]])
		deliver_world.rpc_id(peer_id,"recv_full",[world.full_state()])
		var p:FortPlayer=world.players[peer_id]
		if world.saved_characters.has(p.class_id):
			deliver_world.rpc_id(peer_id,"recv_teleport",[peer_id,p.position])
			personal_event.rpc_id(peer_id,"resume_dwarf",{"yaw":p.look_yaw,"pitch":p.look_pitch,"fuel":p.fuel})
		ready_peers[peer_id]=true

@rpc("authority", "call_remote", "reliable")
func begin_remote(roster:Dictionary) -> void:
	if is_instance_valid(world):return
	connecting = false; lobby_active = false
	player_info = roster
	_start_world()
	for raw_id in roster:
		world.add_network_player(int(raw_id), roster[raw_id])
	client_world_ready.rpc_id(1)

@rpc("authority","call_remote","reliable")
func connection_rejected()->void:
	_leave_game("That fort already has four dwarves.")

func _start_world() -> void:
	if is_instance_valid(menu):
		menu.hide()
	world = WorldScript.new()
	world.name = "World"
	add_child(world)
	world.return_to_menu.connect(_leave_game)

func _on_peer_disconnected(peer_id:int) -> void:
	ready_peers.erase(peer_id)
	player_info.erase(peer_id)
	if is_instance_valid(world): world.remove_network_player(peer_id)
	elif multiplayer.is_server() and lobby_active:_sync_lobby()

func _on_connection_failed() -> void:
	var reason := "Host not reached on UDP %d. Check host router mapping, matching IP/port and this Fort.exe's firewall permission." % session_port
	if transport_connected:
		reason = "Host reached, but lobby registration timed out. Both PCs must run Fort %s. Check the host log for RPC errors." % BUILD_VERSION
	print("FORT_NET ", reason)
	_leave_game(reason)

func _on_server_disconnected() -> void:
	_leave_game("The host closed the fort.")

func _leave_game(reason:="Returned to title.") -> void:
	if returning_to_menu:return
	returning_to_menu=true
	pending_save={}
	if save_menu:save_menu.panel.hide()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	connecting = false; lobby_active = false
	transport_connected = false
	internet.stop()
	var old_address := address_edit.text if is_instance_valid(address_edit) else ""
	player_info.clear()
	lobby = null; lobby_roster = null
	ready_peers.clear()
	if is_instance_valid(world):
		world.queue_free()
		world = null
	if multiplayer.multiplayer_peer:multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	# Finish disposing the old preview viewport before instantiating shared meshes again.
	if is_instance_valid(menu):menu.hide();menu.queue_free();menu=null
	await get_tree().process_frame
	if not is_inside_tree():return
	_build_menu()
	address_edit.text = old_address; port_edit.value = session_port
	status_label.text = reason
	returning_to_menu=false

func broadcast_world(method:String,args:Array)->void:
	if not multiplayer.is_server() or not is_instance_valid(world):return
	world.receive(method,args)
	for id in _connected_ready():deliver_world.rpc_id(id,method,args)

func broadcast_snapshot(state:Dictionary)->void:
	var swarm:Dictionary=state.enemies
	var base:=state.duplicate()
	base.enemies={}
	var packet:=var_to_bytes(base).compress(FileAccess.COMPRESSION_GZIP)
	for id in _connected_ready():deliver_snapshot.rpc_id(id,packet)
	var batch:Dictionary={}
	for enemy_id in swarm:
		batch[enemy_id]=swarm[enemy_id]
		if batch.size()>=8:
			_send_enemy_batch(batch)
			batch={}
	if not batch.is_empty():_send_enemy_batch(batch)

func _send_enemy_batch(batch:Dictionary)->void:
	var packet:=var_to_bytes(batch).compress(FileAccess.COMPRESSION_GZIP)
	for id in _connected_ready():deliver_enemy_snapshot.rpc_id(id,packet)

func _connected_ready()->Array[int]:
	var result:Array[int]=[]
	if not multiplayer.multiplayer_peer is ENetMultiplayerPeer:return result
	var peer:ENetMultiplayerPeer=multiplayer.multiplayer_peer
	for id in ready_peers:
		if id not in multiplayer.get_peers():continue
		var remote:=peer.get_peer(int(id))
		if remote and remote.get_state()==ENetPacketPeer.STATE_CONNECTED:result.append(int(id))
	return result

@rpc("authority","call_remote","reliable")
func deliver_world(method:String,args:Array)->void:
	if is_instance_valid(world):world.receive(method,args)

@rpc("authority","call_remote","unreliable_ordered",1)
func deliver_snapshot(packet:PackedByteArray)->void:
	var state:Variant=bytes_to_var(packet.decompress_dynamic(262144,FileAccess.COMPRESSION_GZIP))
	if is_instance_valid(world) and state is Dictionary:world.recv_snapshot(state)

@rpc("authority","call_remote","unreliable",2)
func deliver_enemy_snapshot(packet:PackedByteArray)->void:
	var state:Variant=bytes_to_var(packet.decompress_dynamic(65536,FileAccess.COMPRESSION_GZIP))
	if is_instance_valid(world) and state is Dictionary:world.recv_enemy_snapshot(state)

@rpc("any_peer","call_remote","reliable")
func submit_action(kind:String,data:Dictionary)->void:
	if multiplayer.is_server() and is_instance_valid(world):
		world.server_action(multiplayer.get_remote_sender_id(),kind,data)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func submit_movement(pos:Vector3,yaw:float,motion:Vector3)->void:
	if multiplayer.is_server() and is_instance_valid(world):
		world.accept_movement(multiplayer.get_remote_sender_id(),pos,yaw,motion)

func send_personal_event(id:int,kind:String,data:Dictionary)->void:
	if ready_peers.has(id):personal_event.rpc_id(id,kind,data)

@rpc("authority","call_remote","reliable")
func personal_event(kind:String,data:Dictionary)->void:
	if not is_instance_valid(world):return
	if kind=="notice":world.show_toast(data.text)
	elif kind=="resume_dwarf" and world.local_player():
		world.local_player().look_yaw=data.yaw;world.local_player().look_pitch=data.pitch;world.local_player().fuel=data.fuel
	elif kind=="dash" and world.local_player():world.local_player().dash_time=0.40
