# blender -b -P render_strip.py -- key clip frames out_dir [span] [views]
# Renders evenly spaced frames of one clip from the saved rig scene (art_source/blender/<key>26.blend).
import bpy, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rigkit
args = sys.argv[sys.argv.index("--") + 1:]
key, clip, count, out = args[0], args[1], int(args[2]), args[3]
span = float(args[4]) if len(args) > 4 else 2.2
views = tuple(args[5].split(",")) if len(args) > 5 else ("side", "front")
bpy.ops.wm.open_mainfile(filepath=os.path.join(rigkit.ROOT, "art_source", "blender", key + "26.blend"))
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
length = 1
for t in arm.animation_data.nla_tracks:
    if t.name == clip: length = int(t.strips[0].action_frame_end - t.strips[0].action_frame_start)
lo, hi = rigkit.bounds([o for o in bpy.data.objects if o.type == "MESH"][0])
for i in range(count):
    frame = 1 + round(i * length / count)
    rigkit.render_views(os.path.join(out, "%s_%s_%02d" % (key, clip, i)), views=views, target=(0, 0, hi[2] * 0.48), distance=span, res=360, frame=frame, track=clip, arm=arm, lift=0.0)
print("STRIP", key, clip, length)
