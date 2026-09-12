extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func tap(key:Key)->void:
	var event:=InputEventKey.new();event.keycode=key;event.physical_keycode=key;event.pressed=true
	root.push_input(event,true);event=event.duplicate();event.pressed=false;root.push_input(event,true)
	await create_timer(.08).timeout
func run()->void:
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	print("ESCAPE_BINDING physical=",KEY_ESCAPE," mapped=",InputMap.action_has_event("cancel",escape))
	check(escape.is_action_pressed("cancel"),"physical Escape matches the cancel action")
	if failures>0:print("ESCAPE19_RESULT FAIL");quit(failures);return
	FortSave.test_directory="res://build/escape19_%d"%Time.get_ticks_usec()
	FortHUD.test_settings_file="res://build/fps19_%d.cfg"%Time.get_ticks_usec()
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24787;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false)
	await create_timer(.1).timeout;await tap(KEY_ESCAPE)
	check(w.menu_open and w.hud.menu.visible,"real Escape event opens the camp menu")
	check(not w.hud.fps_counter.visible and not w.hud.fps_toggle.button_pressed,"FPS counter is off by default")
	w.hud.fps_toggle.grab_focus();await tap(KEY_ENTER);await create_timer(.3).timeout
	check(w.hud.fps_counter.visible and w.hud.fps_counter.text.ends_with(" FPS"),"menu checkbox enables a live FPS counter through keyboard input")
	var config:=ConfigFile.new();check(config.load(FortHUD.fps_settings_path())==OK and config.get_value("display","show_fps",false)==true,"FPS preference is saved locally")
	var save_button:Button
	for button in w.hud.menu.find_children("*","Button",true,false):
		if button.text=="Save expedition…":save_button=button;break
	check(is_instance_valid(save_button),"host menu exposes Save expedition")
	if not is_instance_valid(save_button):quit(1);return
	save_button.grab_focus();await tap(KEY_ENTER)
	check(main.save_menu.panel.visible and main.save_menu.saving,"keyboard activation opens manual save slots")
	main.save_menu.slots.get_child(0).grab_focus();await tap(KEY_ENTER)
	check(FortSave.read_slot("slot1").error=="","keyboard save actually writes a readable checkpoint")
	await tap(KEY_ESCAPE)
	check(not main.save_menu.panel.visible and w.hud.menu.visible and w.menu_open,"Escape backs out of saving without also dismissing the camp menu")
	await tap(KEY_ESCAPE);check(not w.menu_open and not w.hud.menu.visible,"second Escape returns to play")
	w.toggle_build_mode();await tap(KEY_ESCAPE)
	check(not w.local_build_mode and not w.menu_open,"Escape first cancels an active build preview")
	await tap(KEY_ESCAPE);check(w.hud.menu.visible,"next Escape opens the menu after leaving build mode");await tap(KEY_ESCAPE)
	p.position=w.castle.rooms["0:0:0"].sign;w.castle.menu.open_nearest();await tap(KEY_ESCAPE)
	check(not w.castle.menu.panel.visible and not w.menu_open and p.camera.current,"Escape closes architect and restores the player camera")
	w.open_forge();await tap(KEY_ESCAPE);check(not w.forge_open and not w.menu_open,"Escape closes workshop")
	p.health=0;await tap(KEY_ESCAPE);check(w.hud.menu.visible,"downed host can still access the save menu")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/escape19_menu.png"))
	main._leave_game("FPS persistence check");await create_timer(.1).timeout;main.port_edit.value=24787;main._host();main._start_match();w=main.world;w.set_process(false);w.local_player().set_physics_process(false)
	check(w.hud.fps_toggle.button_pressed and w.hud.fps_counter.visible,"new expedition restores the saved FPS preference")
	await tap(KEY_ESCAPE);w.hud.fps_toggle.grab_focus();await tap(KEY_ENTER)
	check(not w.hud.fps_counter.visible,"FPS counter can be switched off again")
	config.load(FortHUD.fps_settings_path());check(config.get_value("display","show_fps",true)==false,"disabled FPS preference persists too")
	main.queue_free();await create_timer(.1).timeout;print("ESCAPE19_RESULT ","PASS" if failures==0 else "FAIL");quit(failures)
