extends SceneTree
# Build mode with a piece category open: tabs, cards, ghost preview and the status line.
const P:=preload("res://scripts/fort_pieces.gd")
func _initialize()->void:run.call_deferred()
func shot(name:String)->void:
	await create_timer(.6).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/pieces_hud_%s.png"%name))
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24871;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player()
	w.shared={"wood":120,"stone":3,"crystal":0,"iron":0,"aether":0}
	w.pieces.starter()
	p.position=Vector3(2,.7,4);p.look_yaw=PI*1.25;p.look_pitch=-.28
	await create_timer(.5).timeout
	w.select_tab(3);await shot("timber")
	w.select_tab(4);w.select_build_slot(4);await shot("stone_short")
	w.select_tab(2);w.select_build_slot(5);p.look_pitch=-.5;await shot("stairs")
	w.select_tab(5);w.select_build_slot(0);p.look_yaw=PI*.75;p.look_pitch=.25;await shot("roof")
	w.select_tab(0);await shot("towers")
	print("AIM ",w.pieces.aimed," TARGET ",w.pieces.target," ",w.pieces.target_reason)
	main.queue_free();await process_frame;print("PIECES_HUD_CAPTURED");quit()
