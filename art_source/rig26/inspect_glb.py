# blender -b -P inspect_glb.py -- a.glb b.glb ...   prints hierarchy, bounds and clips
import bpy, sys
for path in sys.argv[sys.argv.index("--") + 1:]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    lo = [9e9] * 3; hi = [-9e9] * 3; verts = 0
    for o in bpy.data.objects:
        if o.type == "MESH":
            verts += len(o.data.vertices)
            for v in o.data.vertices:
                w = o.matrix_world @ v.co
                for i in range(3): lo[i] = min(lo[i], w[i]); hi[i] = max(hi[i], w[i])
    print("GLB", path.split("/")[-1], "objects", len(bpy.data.objects), "verts", verts, "lo", [round(v, 2) for v in lo], "hi", [round(v, 2) for v in hi])
    print("  names", [o.name for o in bpy.data.objects if o.parent is None or o.type != "MESH"][:24])
    print("  actions", sorted(set(a.name.split("_")[1] if a.name.count("_") >= 2 else a.name for a in bpy.data.actions)), [round(a.frame_range[1]) for a in list(bpy.data.actions)[:3]])
