class_name FortArcFX
extends RefCounted

static func lightning(world:Node3D,start:Vector3,end:Vector3,color:Color)->void:
	var mesh:=ImmediateMesh.new()
	var material:=Visuals.material(color)
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
	var last:=start
	for i in range(1,10):
		var point:=start.lerp(end,i/9.0)
		if i<9:point+=Vector3(randf_range(-.22,.22),randf_range(-.22,.22),randf_range(-.22,.22))
		mesh.surface_add_vertex(last);mesh.surface_add_vertex(point);last=point
	mesh.surface_end()
	var node:=MeshInstance3D.new();node.mesh=mesh;world.add_child(node)
	world.create_tween().tween_callback(node.queue_free).set_delay(.22)

static func shell(world:Node3D,start:Vector3,end:Vector3,color:Color)->void:
	var node:=Visuals.box(Vector3.ONE*.3,color,start);world.add_child(node)
	var tween:=world.create_tween()
	tween.tween_method(func(t:float):
		node.position=start.lerp(end,t)+Vector3.UP*sin(t*PI)*5
		node.rotation+=Vector3(.12,.2,.08),0.0,1.0,.6)
	tween.tween_callback(func():
		world._ring(end,color,4.8,.5)
		for i in 12:
			var angle:=i*TAU/12
			var shard:=Visuals.box(Vector3(.13,.8,.13),color,end+Vector3(cos(angle),0,sin(angle))*randf_range(1,4))
			world.add_child(shard)
			var fade:=world.create_tween()
			fade.tween_property(shard,"scale",Vector3.ONE*.01,.65)
			fade.tween_callback(shard.queue_free)
		node.queue_free())
