class_name FortCombatOverlay
extends Control
var world:FortWorld
var reticle_visible:=false
var reticle_position:=Vector2.ZERO
var bar_count:=0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta:float)->void:queue_redraw()
func _draw()->void:
	reticle_visible=false;bar_count=0
	var p:=world.local_player()
	if not p or world.menu_open or p.health<=0 or world.ended:return
	var camera:=p.camera
	for d in world.defenses.values():
		var distance:float=p.position.distance_to(d.node.position)
		if distance>22 or (d.hp>=d.max_hp and distance>6 and not FortConstruction.pending(d)):continue
		var point:Vector3=d.node.position+Vector3.UP*(3.6 if d.kind=="Watchtower" else 2.5)
		if camera.is_position_behind(point):continue
		var screen:=camera.unproject_position(point)
		if not get_viewport_rect().has_point(screen):continue
		# Terrain/building occlusion keeps bars from showing through walls.
		var obstruction:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1))
		if not obstruction.is_empty():continue
		var rect:=Rect2(screen-Vector2(28,2),Vector2(56,4))
		draw_rect(Rect2(rect.position-Vector2(2,2),rect.size+Vector2(4,4)),Color(.025,.045,.04,.85))
		draw_rect(Rect2(rect.position,Vector2(56*clampf(d.hp/d.max_hp,0,1),4)),Color("#a8d3a2") if d.hp>d.max_hp*.35 else Color("#de956e"))
		bar_count+=1
		if FortConstruction.pending(d):draw_rect(Rect2(rect.position+Vector2(0,7),Vector2(56*FortConstruction.fraction(d),3)),Color("#e4bd78"))
	reticle_visible=not world.local_build_mode and (p.mounted_ballista>=0 or (GameData.ranged(p.weapon) and (p.aiming() or Vector2(p.velocity.x,p.velocity.z).length()<0.3)))
	if not reticle_visible:return
	var solution:=FortAim.solution(world,p,p.shot_direction(),p.mounted_ballista>=0)
	if camera.is_position_behind(solution.point):reticle_visible=false;return
	reticle_position=camera.unproject_position(solution.point)
	if not get_viewport_rect().has_point(reticle_position):reticle_visible=false;return
	var color:=Color("#f0c883") if solution.blocked else (Color("#ee967f") if solution.enemy>=0 else Color("#f4f1df"))
	var point:=reticle_position
	draw_arc(point,5,0,TAU,20,Color(0,0,0,.85),4,true)
	draw_arc(point,5,0,TAU,20,color,1.5,true)
	for axis in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		draw_line(point+axis*9,point+axis*15,Color(0,0,0,.8),4,true)
		draw_line(point+axis*9,point+axis*15,color,1.5,true)
