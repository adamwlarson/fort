"""Fort 26 character kit: turn a raw generated GLB into a rigged, animated game asset.

Run inside Blender (background):  blender -b -P build_x.py
Conventions: Blender Z up, character faces -Y, metres. Godot imports facing +Z.
Bones named *.R sit at +X to match the original Fort dwarf rig (weapon socket = hand.R).
"""
import bpy, math, os
import numpy as np
from mathutils import Vector, Matrix, Quaternion, Euler

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FPS = 24


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS


def import_raw(path, yaw_deg=-90.0, height=1.0, tex_size=1024, center="feet", name="Body", flip_x=False, shift=(0.0, 0.0)):
    """Import, face -Y, stand on z=0, scale to height. Returns mesh object."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    for o in bpy.data.objects:
        o.select_set(o in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    world = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    obj.data.transform(world)
    obj.data.transform(Matrix.Rotation(math.radians(yaw_deg), 4, 'Z'))
    if flip_x:
        obj.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
        obj.data.flip_normals()
    co = verts(obj)
    lo, hi = co.min(0), co.max(0)
    scale = height / (hi[2] - lo[2])
    obj.data.transform(Matrix.Scale(scale, 4))
    co = verts(obj)
    lo, hi = co.min(0), co.max(0)
    if center == "feet":
        low = co[co[:, 2] < lo[2] + 0.12 * (hi[2] - lo[2])]
        cx = (low[:, 0].min() + low[:, 0].max()) * 0.5
        cy = (low[:, 1].min() + low[:, 1].max()) * 0.5
    else:
        cx, cy = (lo[0] + hi[0]) * 0.5, (lo[1] + hi[1]) * 0.5
    obj.data.transform(Matrix.Translation((-cx - shift[0], -cy - shift[1], -lo[2])))
    for other in [o for o in bpy.data.objects if o not in before and o != obj]:
        bpy.data.objects.remove(other, do_unlink=True)
    obj.name = name
    obj.data.name = name + "Mesh"
    for poly in obj.data.polygons:
        poly.use_smooth = True
    for mat in obj.data.materials:
        if not mat or not mat.use_nodes:
            continue
        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE' and node.image and tex_size and node.image.size[0] > tex_size:
                node.image.scale(tex_size, tex_size)
                node.image.pack()
            if node.type == 'BSDF_PRINCIPLED':
                node.inputs['Roughness'].default_value = 0.88
                node.inputs['Metallic'].default_value = 0.0
    return obj


def verts(obj):
    co = np.empty(len(obj.data.vertices) * 3, dtype=np.float64)
    obj.data.vertices.foreach_get("co", co)
    return co.reshape(-1, 3)


def bounds(obj):
    co = verts(obj)
    return co.min(0), co.max(0)


def slice_stats(obj, z0, z1, xmin=-9, xmax=9):
    """Bounding info of the vertices inside a height band (optionally an X band)."""
    co = verts(obj)
    sel = co[(co[:, 2] >= z0) & (co[:, 2] <= z1) & (co[:, 0] >= xmin) & (co[:, 0] <= xmax)]
    if len(sel) == 0:
        return None
    return {"min": sel.min(0).round(3).tolist(), "max": sel.max(0).round(3).tolist(), "n": int(len(sel))}


# ---------------------------------------------------------------- armature

def build_armature(name, bones):
    """bones: list of dict(name, head, tail, parent=None, roll=(x,y,z) axis the bone Z should face,
    connect=False). Returns armature object."""
    data = bpy.data.armatures.new(name + "Rig")
    arm = bpy.data.objects.new(name + "_Rig", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    for spec in bones:
        b = data.edit_bones.new(spec["name"])
        b.head = Vector(spec["head"])
        b.tail = Vector(spec["tail"])
        if spec.get("parent"):
            b.parent = data.edit_bones[spec["parent"]]
        b.align_roll(Vector(spec.get("roll", (0, 1, 0))))
    bpy.ops.object.mode_set(mode='OBJECT')
    data.display_type = 'STICK'
    return arm


def skin(obj, arm, bones, smooth=3, power=5.0, max_influences=4, forces=None):
    """Capsule-distance skinning. Each bone spec may carry: radius (default .1), side (-1/+1 hard X mask),
    weight=False (helper bone, never skinned), zmin/zmax limits, seg=(a,b) custom segment for weighting."""
    co = verts(obj)
    n = len(co)
    names, scores = [], []
    for spec in bones:
        if spec.get("weight", True) is False:
            continue
        a, b = spec.get("seg", (spec["head"], spec["tail"]))
        a, b = np.array(a, float), np.array(b, float)
        ab = b - a
        t = np.clip(((co - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
        d = np.linalg.norm(co - (a + t[:, None] * ab), axis=1)
        nd = np.maximum(d / spec.get("radius", 0.1), 0.02)
        score = 1.0 / nd ** power
        side = spec.get("side", 0)
        if side:
            score = np.where(co[:, 0] * side < -spec.get("side_margin", 0.0), 0.0, score)
        if "zmin" in spec:
            score = np.where(co[:, 2] < spec["zmin"], 0.0, score)
        if "zmax" in spec:
            score = np.where(co[:, 2] > spec["zmax"], 0.0, score)
        if "mask" in spec:
            score = np.where(spec["mask"](co), score, 0.0)
        names.append(spec["name"])
        scores.append(score)
    w = np.stack(scores, 1)
    w /= np.maximum(w.sum(1, keepdims=True), 1e-12)
    # Laplacian smoothing over mesh edges softens creases at joints.
    edges = np.empty(len(obj.data.edges) * 2, dtype=np.int64)
    obj.data.edges.foreach_get("vertices", edges)
    edges = edges.reshape(-1, 2)
    # Weld coincident vertices (UV seams split them) so smoothing crosses seams.
    key = np.round(co * 2000).astype(np.int64)
    _, inverse = np.unique(key, axis=0, return_inverse=True)
    inverse = inverse.reshape(-1)
    groups = inverse.max() + 1
    for _ in range(smooth):
        gw = np.zeros((groups, w.shape[1]))
        gc = np.zeros(groups)
        np.add.at(gw, inverse, w)
        np.add.at(gc, inverse, 1)
        gw /= gc[:, None]
        acc = gw.copy()
        cnt = np.ones(groups)
        ea, eb = inverse[edges[:, 0]], inverse[edges[:, 1]]
        np.add.at(acc, ea, gw[eb])
        np.add.at(acc, eb, gw[ea])
        np.add.at(cnt, ea, 1)
        np.add.at(cnt, eb, 1)
        gw = acc / cnt[:, None]
        w = gw[inverse]
    # Rigid props (weapons, shields, staffs) follow exactly one bone.
    for mask_fn, bone_name in (forces or []):
        mask = mask_fn(co)
        w[mask] = 0.0
        w[mask, names.index(bone_name)] = 1.0
    # Keep the strongest influences only.
    order = np.argsort(-w, axis=1)[:, :max_influences]
    keep = np.zeros_like(w)
    rows = np.arange(n)[:, None]
    keep[rows, order] = w[rows, order]
    keep[keep < 0.02] = 0
    keep /= np.maximum(keep.sum(1, keepdims=True), 1e-12)
    for group in list(obj.vertex_groups):
        obj.vertex_groups.remove(group)
    for index, bone_name in enumerate(names):
        group = obj.vertex_groups.new(name=bone_name)
        column = keep[:, index]
        for value in np.unique(np.round(column[column > 0], 2)):
            ids = np.nonzero(np.round(column, 2) == value)[0]
            group.add(ids.tolist(), float(value), 'REPLACE')
    obj.parent = arm
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm
    return keep, names


# ---------------------------------------------------------------- animation

class Animator:
    """Author clips with intuitive world-axis rotations.

    rot(bone, x, y, z) rotates the bone about armature axes (degrees) relative to its
    neutral pose, carried by its parent:  X+ pitches forward/down for a standing figure
    is NOT assumed; use the right-hand rule on Blender axes (character faces -Y).
    Helper semantics are provided by subclasses/rig presets through `neutral`.
    """

    def __init__(self, arm):
        self.arm = arm
        self.rest = {b.name: b.matrix_local.to_quaternion() for b in arm.data.bones}
        self.neutral = {}  # bone -> world-axis quaternion applied before clip rotations
        arm.animation_data_create()
        for pb in arm.pose.bones:
            pb.rotation_mode = 'QUATERNION'
        self.clips = []

    def set_neutral(self, bone, x=0.0, y=0.0, z=0.0):
        self.neutral[bone] = Euler((math.radians(x), math.radians(y), math.radians(z)), 'XYZ').to_quaternion()

    def _carried(self, bone):
        """Neutral rotation accumulated from this bone's ancestors (they carry its frame)."""
        q = Quaternion()
        parent = self.arm.data.bones[bone].parent
        chain = []
        while parent is not None:
            chain.append(parent.name)
            parent = parent.parent
        for name in reversed(chain):
            q = q @ self.neutral.get(name, Quaternion())
        return q

    def _basis(self, bone, world_q):
        # Rotations are authored in armature axes as seen with the parents in their neutral pose
        # (e.g. an elbow bends straight forward once the A-posed arm hangs at the side).
        rest = self.rest[bone]
        carried = self._carried(bone)
        total = carried.inverted() @ (world_q @ self.neutral.get(bone, Quaternion())) @ carried
        return rest.inverted() @ total @ rest

    def clip(self, name, length, keys, loop=True, moves=None):
        """keys: {bone: [(frame, (x,y,z) degrees), ...]}; moves: {bone: [(frame,(dx,dy,dz))]} in armature axes.
        Unlisted bones hold their neutral pose. Frames are 0..length; loops repeat the first key."""
        arm = self.arm
        action = bpy.data.actions.new(name)
        arm.animation_data.action = action
        for pb in arm.pose.bones:
            pb.rotation_quaternion = self._basis(pb.name, Quaternion())
            pb.location = (0, 0, 0)
            pb.keyframe_insert("rotation_quaternion", frame=1)
        for bone, track in keys.items():
            pb = arm.pose.bones[bone]
            previous = None
            for frame, angles in track:
                q = Euler([math.radians(a) for a in angles], 'XYZ').to_quaternion()
                basis = self._basis(bone, q)
                if previous is not None and previous.dot(basis) < 0:
                    basis.negate()
                previous = basis.copy()
                pb.rotation_quaternion = basis
                pb.keyframe_insert("rotation_quaternion", frame=1 + frame)
        for bone, track in (moves or {}).items():
            pb = arm.pose.bones[bone]
            rest_inv = self.rest[bone].inverted()
            for frame, offset in track:
                pb.location = rest_inv @ Vector(offset)
                pb.keyframe_insert("location", frame=1 + frame)
        for fcurve in _fcurves(action):
            for point in fcurve.keyframe_points:
                point.interpolation = 'BEZIER'
                point.handle_left_type = point.handle_right_type = 'AUTO_CLAMPED'
            fcurve.update()
        track = arm.animation_data.nla_tracks.new()
        track.name = name
        strip = track.strips.new(name, 1, action)
        strip.action_frame_start = 1
        strip.action_frame_end = 1 + length
        arm.animation_data.action = None
        for pb in arm.pose.bones:
            pb.rotation_quaternion = Quaternion()
            pb.location = (0, 0, 0)
        self.clips.append(name)


def _fcurves(action):
    if hasattr(action, "fcurves") and len(getattr(action, "fcurves", [])):
        return list(action.fcurves)
    curves = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                curves.extend(bag.fcurves)
    return curves


# ---------------------------------------------------------------- output

def export(obj_list, key, folder="assets/models/fort"):
    path = os.path.join(ROOT, folder, key + ".glb")
    for o in bpy.data.objects:
        o.select_set(o in obj_list)
    bpy.context.view_layer.objects.active = obj_list[0]
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_animations=True,
                              export_animation_mode='NLA_TRACKS', export_force_sampling=True, export_yup=True,
                              export_image_format='JPEG', export_image_quality=88, export_skins=True,
                              export_optimize_animation_size=True)
    return path


def save_blend(key):
    path = os.path.join(ROOT, "art_source", "blender", key + "26.blend")
    bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)


def render_views(prefix, views=("front", "side"), target=(0, 0, 0.6), distance=3.4, res=640, frame=None, track=None, arm=None, lift=0.0):
    """Quick EEVEE previews for visual checks. If track is given, that NLA track is soloed."""
    scene = bpy.context.scene
    if not scene.camera:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
        scene.camera = cam
        sun = bpy.data.objects.new("PreviewSun", bpy.data.lights.new("PreviewSun", 'SUN'))
        sun.data.energy = 3.2
        sun.rotation_euler = (math.radians(50), 0, math.radians(-25))
        scene.collection.objects.link(sun)
        scene.world = bpy.data.worlds.new("PreviewWorld")
        scene.world.use_nodes = True
        bg = scene.world.node_tree.nodes["Background"]
        bg.inputs[0].default_value = (0.42, 0.45, 0.5, 1)
        bg.inputs[1].default_value = 1.1
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = scene.render.resolution_y = res
    scene.camera.data.type = 'ORTHO'
    scene.camera.data.ortho_scale = distance
    if arm is not None and arm.animation_data:
        for t in arm.animation_data.nla_tracks:
            t.is_solo = False
            t.mute = track is not None and t.name != track
        if track is None:
            for t in arm.animation_data.nla_tracks:
                t.mute = True
    if frame is not None:
        scene.frame_set(frame)
    angles = {"front": 0, "side": 90, "back": 180, "quarter": 35}
    out = []
    for view in views:
        yaw = math.radians(angles[view])
        t = Vector(target)
        scene.camera.location = t + Vector((math.sin(yaw) * 8, -math.cos(yaw) * 8, lift))
        direction = t - scene.camera.location
        scene.camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = prefix + "_" + view + ".png"
        bpy.ops.render.render(write_still=True)
        out.append(scene.render.filepath)
    return out
