# blender -b -P preview_many.py -- out_dir key:height[:yaw] ...   (front+side level ortho previews, prints bounds/span)
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rigkit
args = sys.argv[sys.argv.index("--") + 1:]
out = args[0]
for item in args[1:]:
    parts = item.split(":")
    key, height = parts[0], float(parts[1]); yaw = float(parts[2]) if len(parts) > 2 else -90.0
    rigkit.reset()
    obj = rigkit.import_raw(os.path.join(rigkit.ROOT, "art_source", "gen26", key + "_raw.glb"), height=height, yaw_deg=yaw)
    lo, hi = rigkit.bounds(obj)
    span = max(hi[0] - lo[0], hi[2] - lo[2], hi[1] - lo[1]) * 1.12
    rigkit.render_views(os.path.join(out, key), views=("front", "side"), target=(0, (lo[1] + hi[1]) * 0.5, hi[2] * 0.5), distance=span, res=900)
    print("BOUNDS", key, lo.round(3).tolist(), hi.round(3).tolist(), "SPAN", round(span, 4), "YC", round((lo[1] + hi[1]) * 0.5, 3))
