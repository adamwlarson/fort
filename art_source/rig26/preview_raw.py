# blender -b -P preview_raw.py -- raw.glb height out_prefix [yaw]
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rigkit
args = sys.argv[sys.argv.index("--") + 1:]
rigkit.reset()
obj = rigkit.import_raw(args[0], height=float(args[1]), yaw_deg=float(args[3]) if len(args) > 3 else -90.0)
lo, hi = rigkit.bounds(obj)
span = max(hi[0] - lo[0], hi[2] - lo[2], hi[1] - lo[1]) * 1.15
rigkit.render_views(args[2], views=("front", "side"), target=(0, 0, (hi[2]) * 0.5), distance=span, res=1000)
print("BOUNDS", lo.round(3).tolist(), hi.round(3).tolist(), "SPAN", round(span, 4))
