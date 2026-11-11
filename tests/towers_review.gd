extends SceneTree
# Renders every defense at level 1 and at a high level for an art audit.
func _initialize()->void:run.call_deferred()
func run()->void:
	var main:Node=load("res://scenes/main.tscn").instantiate();root.add_child(main);main.port_edit.value=24868;main._host();main._start_match()
	var w:FortWorld=main.world;var p:=w.local_player();w.set_process(false);p.set_physics_process(false);w.hud.visible=false
	p.position=Vector3(0,.6,-8)
	var kinds:=["Watchtower","Barricade","Ballista","Mender","MetalWall","StormSpire","FrostMortar","Embercoil","GravityWell","Sunlance","CastleWall","CastleWindow","CastleGate","SentryCannon"]
	var base:=Vector3(60,0,60)
	var levels:=[1,3,6]
	for row in 3:
		for i in kinds.size():
			var pos:=base+Vector3((i%7-3)*4.6,0,-(i/7)*7.0)+Vector3(0,0,-row*60.0)
			w.recv_defense(7000+row*100+i,kinds[i],pos,PI if kinds[i].begins_with("Castle") else 0.0,300,false)
			var d:Dictionary=w.defenses[7000+row*100+i]
			d.level=levels[row];w.progression.defense_visual(d)
			if kinds[i]=="CastleGate" and row==1:d.gate_open=1.0;FortGates.pose(d)
			FortBattlements.aim(d,Vector3(.5,.1,1).normalized())
	var camera:=Camera3D.new();w.add_child(camera);camera.fov=36;camera.current=true
	for row in 3:
		camera.position=base+Vector3(0,10,17-row*60.0);camera.look_at(base+Vector3(0,1.6,-3.5-row*60.0))
		await create_timer(.5).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/towers_level%d.png"%levels[row]))
	main.queue_free();await process_frame;print("TOWERS_REVIEW_CAPTURED");quit()
