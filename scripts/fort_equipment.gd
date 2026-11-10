class_name FortEquipment
extends RefCounted

# Fort 26 dwarves are textured, skinned characters without a baked-in tool.
# Hand tools hang from a grip node under the hand.R bone, so every weapon model
# (authored with its haft along +Y and its edge toward +X) sits in the palm and
# points forward like a held tool instead of extending the forearm.
const GRIP_OFFSET := Vector3(0, 0.085, -0.01)
const LOOPS := ["Idle","Walk","Run","Gather","Build","Aim","March","Air","Ride","Downed"]
static var body_mesh: Mesh
static var axe_mesh: Mesh

static func grip_basis() -> Basis:
	return Basis(Vector3.RIGHT, -2.0) * Basis(Vector3.UP, -PI / 2)

static func prepare(dwarf: Node3D) -> Dictionary:
	var skeleton: Skeleton3D = dwarf.find_children("*", "Skeleton3D", true, false)[0]
	var source: MeshInstance3D = dwarf.find_children("*", "MeshInstance3D", true, false)[0]
	body_mesh = source.mesh
	var hand := BoneAttachment3D.new()
	hand.name = "WeaponHand"; hand.bone_name = "hand.R"
	skeleton.add_child(hand)
	var grip := Node3D.new()
	grip.name = "Grip"; grip.position = GRIP_OFFSET; grip.basis = grip_basis().scaled(Vector3.ONE * 0.82)
	hand.add_child(grip)
	var axe: Node3D = FortArt.asset("weapon_axe")
	axe.name = "GatheringAxe"
	grip.add_child(axe)
	var axe_part: MeshInstance3D = axe.find_children("*", "MeshInstance3D", true, false)[0]
	axe_mesh = axe_part.mesh
	return {"axe": axe, "socket": grip, "hand": hand, "skeleton": skeleton}

static func pose_clips(player: AnimationPlayer) -> void:
	for clip in LOOPS:
		if player.has_animation(clip): player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for clip in ["Axe_Swing","Heavy_Swing","Cast","Shoot","Thrust","Hit","Fall"]:
		if player.has_animation(clip): player.get_animation(clip).loop_mode = Animation.LOOP_NONE
