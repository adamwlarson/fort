"""Local procedural sculpting for Fort creatures (no external generation).

Soft parts are ellipsoids that get fused by a voxel remesh into one organic skin, then
painted per vertex from the part colours with soft blending, painted markings, a little
underside shading and hand-painted-style variation. Hard parts (eyes, claws, tack) are
added afterwards as crisp separate shells in the same mesh.
"""
import bpy, bmesh, math
import numpy as np
from mathutils import Vector, Matrix, Euler


def hex_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def to_linear(c):
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c)


def P(pos, size, color, rot=(0, 0, 0), blend=1.0):
    """Soft ellipsoid part: centre, radii, sRGB hex colour, XYZ euler degrees."""
    return {"pos": Vector(pos), "size": Vector(size), "color": hex_rgb(color) if isinstance(color, str) else color,
            "rot": Euler([math.radians(a) for a in rot], 'XYZ'), "blend": blend}


def limb(a, b, r0, r1, color, steps=None):
    """A tapered chain of ellipsoids from a to b (legs, necks, tails)."""
    a, b = Vector(a), Vector(b)
    length = (b - a).length
    steps = steps or max(2, int(length / (min(r0, r1) * 0.9)) + 1)
    out = []
    for i in range(steps + 1):
        t = i / steps
        r = r0 + (r1 - r0) * t
        out.append(P(a.lerp(b, t), (r, r, r), color))
    return out


def _matrix(part):
    return Matrix.Translation(part["pos"]) @ part["rot"].to_matrix().to_4x4() @ Matrix.Diagonal((*part["size"], 1.0))


def _add_sphere(bm, part, subdivisions=3):
    result = bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=1.0, matrix=_matrix(part))
    return result["verts"]


def skin(name, parts, voxel=0.022, smooth=6, target_faces=7000, mirror=True):
    """Fuse soft parts into one mesh object. With mirror, parts with x>0.001 are duplicated to -x."""
    full = list(parts)
    if mirror:
        for part in parts:
            if part["pos"].x > 0.001:
                twin = dict(part)
                twin["pos"] = Vector((-part["pos"].x, part["pos"].y, part["pos"].z))
                e = part["rot"]
                twin["rot"] = Euler((e.x, -e.y, -e.z), 'XYZ')
                full.append(twin)
    bm = bmesh.new()
    for part in full:
        _add_sphere(bm, part)
    mesh = bpy.data.meshes.new(name + "Mesh")
    bm.to_mesh(mesh); bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    for o in bpy.data.objects:
        o.select_set(o == obj)
    remesh = obj.modifiers.new("Fuse", 'REMESH')
    remesh.mode = 'VOXEL'; remesh.voxel_size = voxel; remesh.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    if smooth:
        mod = obj.modifiers.new("Soften", 'SMOOTH')
        mod.factor = 0.6; mod.iterations = smooth
        bpy.ops.object.modifier_apply(modifier=mod.name)
    faces = len(obj.data.polygons) * 2
    if faces > target_faces:
        dec = obj.modifiers.new("Reduce", 'DECIMATE')
        dec.ratio = target_faces / faces
        bpy.ops.object.modifier_apply(modifier=dec.name)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj, full


def paint(obj, parts, markings=(), sharpness=9.0, underside=0.22, variation=0.05, seed=3):
    """Vertex colours from the nearest soft parts. markings: list of (mask_fn(co)->0..1 array, hex colour)."""
    mesh = obj.data
    n = len(mesh.vertices)
    co = np.empty(n * 3); mesh.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    normals = np.empty(n * 3); mesh.vertices.foreach_get("normal", normals); normals = normals.reshape(-1, 3)
    weights = np.zeros((n, len(parts))); colors = np.zeros((len(parts), 3))
    for i, part in enumerate(parts):
        inv = np.array(_matrix(part).inverted())
        local = co @ inv[:3, :3].T + inv[:3, 3]
        d = np.linalg.norm(local, axis=1)              # 1.0 on the ellipsoid surface
        weights[:, i] = np.exp(-np.maximum(d - 1.0, -0.5) * sharpness * part["blend"])
        colors[i] = part["color"]
    weights /= np.maximum(weights.sum(1, keepdims=True), 1e-9)
    rgb = weights @ colors
    for mask_fn, color in markings:
        m = np.clip(mask_fn(co), 0.0, 1.0)[:, None]
        rgb = rgb * (1 - m) + np.array(hex_rgb(color) if isinstance(color, str) else color) * m
    # underside shading and gentle painterly blotches
    rgb *= (1.0 - underside * np.clip(-normals[:, 2], 0, 1))[:, None]
    rng = np.random.default_rng(seed)
    phase = rng.uniform(0, 6.28, 3)
    blotch = np.sin(co[:, 0] * 9 + phase[0]) * np.sin(co[:, 1] * 7 + phase[1]) * np.sin(co[:, 2] * 11 + phase[2])
    rgb *= (1.0 + variation * blotch)[:, None]
    rgb = np.clip(rgb, 0, 1)
    _write_colors(obj, rgb)
    return rgb


def _write_colors(obj, rgb, start=0):
    mesh = obj.data
    attr = mesh.color_attributes.get("Col") or mesh.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
    linear = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    data = np.ones((len(mesh.vertices), 4)); existing = np.empty(len(mesh.vertices) * 4)
    attr.data.foreach_get("color", existing); data[:] = existing.reshape(-1, 4)
    data[start:start + len(rgb), :3] = linear; data[start:start + len(rgb), 3] = 1.0
    attr.data.foreach_set("color", data.reshape(-1))
    mesh.color_attributes.active_color = attr
    mesh.color_attributes.render_color_index = list(mesh.color_attributes).index(attr)


def hard(obj, shape, pos, size, color, rot=(0, 0, 0), mirror=False, segments=10, bevel=0.0):
    """Add a crisp shell (sphere, box, cone, cylinder) to the mesh with a flat colour. Not remeshed."""
    placements = [(Vector(pos), rot)]
    if mirror:
        placements.append((Vector((-pos[0], pos[1], pos[2])), (rot[0], -rot[1], -rot[2])))
    mesh = obj.data
    for p, r in placements:
        bm = bmesh.new()
        m = Matrix.Translation(p) @ Euler([math.radians(a) for a in r], 'XYZ').to_matrix().to_4x4() @ Matrix.Diagonal((*size, 1.0))
        if shape == "sphere":
            bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0, matrix=m)
        elif shape == "box":
            bmesh.ops.create_cube(bm, size=2.0, matrix=m)
            if bevel:
                bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, affect='EDGES')
        elif shape == "cone":
            bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=1.0, radius2=0.0, depth=2.0, matrix=m)
        else:
            bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=1.0, radius2=1.0, depth=2.0, matrix=m)
        temp = bpy.data.meshes.new("part"); bm.to_mesh(temp); bm.free()
        temp_obj = bpy.data.objects.new("part", temp)
        bpy.context.scene.collection.objects.link(temp_obj)
        for poly in temp.polygons:
            poly.use_smooth = shape in ("sphere", "cylinder", "cone")
        start = len(mesh.vertices); count = len(temp.vertices)
        attr = temp.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
        c = to_linear(hex_rgb(color) if isinstance(color, str) else color)
        attr.data.foreach_set("color", np.tile(np.array([*c, 1.0]), count))
        for o in bpy.data.objects:
            o.select_set(o in (obj, temp_obj))
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.join()
        mesh = obj.data


def material(obj, name="Painted", roughness=0.9):
    mat = bpy.data.materials.new(name); mat.use_nodes = True
    nodes = mat.node_tree.nodes; bsdf = nodes["Principled BSDF"]
    attr = nodes.new("ShaderNodeVertexColor"); attr.layer_name = "Col"
    mat.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    obj.data.materials.clear(); obj.data.materials.append(mat)
    return mat
