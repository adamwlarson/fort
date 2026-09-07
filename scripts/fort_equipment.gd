class_name FortEquipment
extends RefCounted

static var body_mesh: ArrayMesh
static var axe_mesh: ArrayMesh
static var variants:Dictionary={}

# The source dwarf has a skinned axe merged into its body. Split only triangles
# fully weighted to hand.R and not using skin, leaving the original asset intact.
static func prepare(dwarf: Node3D) -> Dictionary:
	var skeleton:Skeleton3D=dwarf.find_children("*","Skeleton3D",true,false)[0]
	var source:MeshInstance3D=dwarf.find_children("*","MeshInstance3D",true,false)[0]
	var variant_key:=source.mesh.get_instance_id()
	if variants.has(variant_key):
		body_mesh=variants[variant_key][0];axe_mesh=variants[variant_key][1]
	else:
		body_mesh=ArrayMesh.new();axe_mesh=ArrayMesh.new()
		var hand_bind:=-1
		for i in source.skin.get_bind_count():
			if source.skin.get_bind_name(i)==&"hand.R":hand_bind=i
		assert(hand_bind>=0,"Dwarf hand binding is required for equipment")
		for surface in source.mesh.get_surface_count():
			var arrays:Array=source.mesh.surface_get_arrays(surface)
			var material:Material=source.mesh.surface_get_material(surface)
			var original:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var body_indices:=PackedInt32Array()
			var tool_indices:=PackedInt32Array()
			var bones:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			for triangle in range(0,original.size(),3):
				var tool:=not "Skin" in material.resource_name
				for corner in 3:
					var vertex:int=original[triangle+corner]
					var weight:=0.0
					for slot in 4:
						if bones[vertex*4+slot]==hand_bind:weight+=weights[vertex*4+slot]
					if weight<0.99:tool=false
				for corner in 3:
					if tool:tool_indices.append(original[triangle+corner])
					else:body_indices.append(original[triangle+corner])
			for pair in [[body_mesh,body_indices],[axe_mesh,tool_indices]]:
				if pair[1].is_empty():continue
				var mesh:ArrayMesh=pair[0]
				var part:=arrays.duplicate()
				part[Mesh.ARRAY_INDEX]=pair[1]
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,part)
				mesh.surface_set_material(mesh.get_surface_count()-1,material)
		variants[variant_key]=[body_mesh,axe_mesh]
	source.mesh=body_mesh
	var axe:=MeshInstance3D.new()
	axe.name="GatheringAxe";axe.mesh=axe_mesh;axe.skin=source.skin
	axe.skeleton=source.skeleton;axe.transform=source.transform
	source.get_parent().add_child(axe)
	var socket:=BoneAttachment3D.new()
	socket.name="WeaponHand";socket.bone_name="hand.R"
	skeleton.add_child(socket)
	return {"axe":axe,"socket":socket,"skeleton":skeleton}

static func pose_clips(player:AnimationPlayer) -> void:
	var library:=AnimationLibrary.new()
	for key in ["Aim","March","Shoot"]:
		var animation:Animation=player.get_animation("Walk" if key=="March" else "Idle").duplicate(true)
		if key=="Shoot":animation.length=1.05;animation.loop_mode=Animation.LOOP_NONE
		for track in animation.get_track_count():
			if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
			var bone:=str(animation.track_get_path(track)).get_slice(":",1)
			if not bone.begins_with("upper_arm") and not bone.begins_with("forearm"):continue
			var base:Quaternion=player.get_animation("Idle").track_get_key_value(track,0)
			var angle:=-1.0 if bone.begins_with("upper_arm") else -0.45
			for frame in range(animation.track_get_key_count(track)-1,-1,-1):animation.track_remove_key(track,frame)
			for time in [0.0,0.12,0.28,0.72,1.05] if key=="Shoot" else [0.0]:
				var recoil:=0.18 if key=="Shoot" and time==0.28 else 0.0
				if bone=="forearm.L" and time==0.72:recoil=0.6
				animation.track_insert_key(track,time,base*Quaternion(Vector3.RIGHT,angle+recoil))
		library.add_animation(key,animation)
	player.add_animation_library("crossbow",library)
	var pike_library:=AnimationLibrary.new()
	var thrust:Animation=library.get_animation("Aim").duplicate(true);thrust.length=.85;thrust.loop_mode=Animation.LOOP_NONE
	for track in thrust.get_track_count():
		if thrust.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
		var bone:=str(thrust.track_get_path(track)).get_slice(":",1)
		if not bone.begins_with("upper_arm") and not bone.begins_with("forearm"):continue
		var rest:Quaternion=thrust.track_get_key_value(track,0)
		for i in range(thrust.track_get_key_count(track)-1,-1,-1):thrust.track_remove_key(track,i)
		for pair in [[0.0,.25],[.23,-.35],[.4,-.2],[.85,0.0]]:thrust.track_insert_key(track,pair[0],rest*Quaternion(Vector3.RIGHT,pair[1]))
	pike_library.add_animation("Thrust",thrust);player.add_animation_library("pike",pike_library)
