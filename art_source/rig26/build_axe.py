# blender -b -P build_axe.py : Forester's Axe hand tool. Handle along +Z, blade toward +X (matches other Fort weapons).
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh, rigkit
from mathutils import Vector, Matrix
rigkit.reset()

def mat(name, color, rough=0.7, metal=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1); b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    return m

def obj_from(bm, name, material, smooth=True):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material)
    for p in me.polygons: p.use_smooth = smooth
    return o

wood = mat("AxeWood", (0.36, 0.2, 0.1), 0.8)
steel = mat("AxeSteel", (0.55, 0.6, 0.66), 0.35, 0.8)
edge = mat("AxeEdge", (0.85, 0.88, 0.92), 0.25, 0.9)
leather = mat("AxeLeather", (0.2, 0.12, 0.08), 0.9)
brass = mat("AxeBrass", (0.8, 0.58, 0.22), 0.4, 0.8)
parts = []
# handle: gently curved haft from z=-0.16 to 0.56
bm = bmesh.new()
rings = []
for i in range(13):
    t = i / 12.0; z = -0.16 + t * 0.72
    x = 0.022 * math.sin(t * math.pi * 1.2) - 0.008
    r = 0.024 + 0.006 * math.cos(t * math.pi * 2) + (0.008 if i == 0 else 0)
    ring = [bm.verts.new((x + math.cos(a) * r, math.sin(a) * r * 0.8, z)) for a in [k * math.tau / 10 for k in range(10)]]
    rings.append(ring)
for a, b in zip(rings, rings[1:]):
    for k in range(10): bm.faces.new((a[k], a[(k + 1) % 10], b[(k + 1) % 10], b[k]))
bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
parts.append(obj_from(bm, "AxeHaft", wood))
# leather grip wraps
for z in (-0.1, -0.05, 0.0, 0.05):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.031, radius2=0.031, depth=0.035, matrix=Matrix.Translation((-0.006, 0, z)))
    parts.append(obj_from(bm, "AxeGrip", leather))
# head: bearded blade profile extruded in Y with a thin cutting edge
profile = [(-0.05, 0.40), (-0.05, 0.54), (0.03, 0.55), (0.12, 0.60), (0.215, 0.62), (0.235, 0.47), (0.215, 0.30), (0.13, 0.36), (0.04, 0.41)]
thick = [0.034, 0.034, 0.03, 0.02, 0.003, 0.003, 0.003, 0.018, 0.03]
bm = bmesh.new()
front = [bm.verts.new((x, -t, z)) for (x, z), t in zip(profile, thick)]
back = [bm.verts.new((x, t, z)) for (x, z), t in zip(profile, thick)]
n = len(profile)
bm.faces.new(front); bm.faces.new(back[::-1])
for i in range(n): bm.faces.new((front[i], back[i], back[(i + 1) % n], front[(i + 1) % n]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
parts.append(obj_from(bm, "AxeHead", steel, smooth=False))
# bright edge strip
bm = bmesh.new()
ep = [(0.205, 0.625), (0.24, 0.47), (0.205, 0.295), (0.19, 0.31), (0.215, 0.47), (0.19, 0.61)]
f = [bm.verts.new((x, -0.006, z)) for x, z in ep]; b = [bm.verts.new((x, 0.006, z)) for x, z in ep]
bm.faces.new(f); bm.faces.new(b[::-1])
for i in range(6): bm.faces.new((f[i], b[i], b[(i + 1) % 6], f[(i + 1) % 6]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
parts.append(obj_from(bm, "AxeEdge", edge, smooth=False))
# brass collar + pommel
for z, r, d in ((0.385, 0.04, 0.03), (0.565, 0.036, 0.03), (-0.165, 0.036, 0.03)):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=r, radius2=r * 0.9, depth=d, matrix=Matrix.Translation((0.0, 0, z)))
    parts.append(obj_from(bm, "AxeCollar", brass))
for o in bpy.data.objects: o.select_set(o in parts)
bpy.context.view_layer.objects.active = parts[0]; bpy.ops.object.join()
axe = bpy.context.view_layer.objects.active; axe.name = "weapon_axe"
print("BUILT", rigkit.export([axe], "weapon_axe"))
rigkit.save_blend("weapon_axe")
