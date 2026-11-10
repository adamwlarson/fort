# blender -b -P build_dwarves.py -- [key ...] [--preview out_prefix]
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, rigkit, biped
from rigkit import Animator

GEN = os.path.join(rigkit.ROOT, "art_source", "gen26")
DWARVES = {
    "dwarf_vanguard": {"height": 1.45, "p": {
        "pelvis": 0.47, "spine": 0.60, "chest": 0.78, "neck": 1.0, "head": 1.06, "top": 1.30, "y": 0.0, "head_y": -0.03,
        "shoulder": (0.30, 0.0, 0.93), "elbow": (0.475, -0.01, 0.76), "wrist": (0.60, -0.03, 0.625), "hand": (0.70, -0.04, 0.52),
        "hip": (0.14, 0.0, 0.47), "knee": (0.20, -0.02, 0.28), "ankle": (0.22, 0.02, 0.11), "toe": (0.23, -0.20, 0.03)}},
    "dwarf_warden": {"height": 1.42, "kneel": 0.17, "p": {
        "pelvis": 0.42, "spine": 0.55, "chest": 0.74, "neck": 0.98, "head": 1.04, "top": 1.30, "y": 0.03, "head_y": 0.0,
        "shoulder": (0.24, 0.0, 0.94), "elbow": (0.38, -0.02, 0.81), "wrist": (0.52, -0.05, 0.68), "hand": (0.66, -0.08, 0.57),
        "hip": (0.13, 0.03, 0.42), "knee": (0.19, 0.01, 0.25), "ankle": (0.22, 0.04, 0.10), "toe": (0.22, -0.17, 0.03)}},
    "dwarf_engineer": {"height": 1.42, "kneel": 0.18, "p": {
        "pelvis": 0.44, "spine": 0.57, "chest": 0.76, "neck": 1.0, "head": 1.05, "top": 1.28, "y": 0.0, "head_y": -0.03, "head_back": 0.13,
        "shoulder": (0.25, 0.0, 0.95), "elbow": (0.36, -0.02, 0.83), "wrist": (0.51, -0.05, 0.70), "hand": (0.68, -0.08, 0.57),
        "hip": (0.14, 0.0, 0.44), "knee": (0.21, -0.02, 0.26), "ankle": (0.24, 0.02, 0.10), "toe": (0.24, -0.18, 0.03)}},
    "dwarf_ranger": {"height": 1.42, "kneel": 0.18, "p": {
        "pelvis": 0.45, "spine": 0.58, "chest": 0.76, "neck": 0.98, "head": 1.04, "top": 1.30, "y": 0.02, "head_y": 0.0,
        "shoulder": (0.24, 0.0, 0.93), "elbow": (0.37, -0.02, 0.80), "wrist": (0.535, -0.05, 0.645), "hand": (0.67, -0.07, 0.52),
        "hip": (0.14, 0.02, 0.45), "knee": (0.20, 0.0, 0.26), "ankle": (0.23, 0.03, 0.10), "toe": (0.23, -0.18, 0.03)}},
}

for _base in ("vanguard", "warden", "engineer", "ranger"):
    DWARVES["dwarf_%s_b" % _base] = dict(DWARVES["dwarf_" + _base], height=1.42)

def build(key, preview=None):
    spec = DWARVES[key]
    rigkit.reset()
    body = rigkit.import_raw(os.path.join(GEN, key + "_raw.glb"), height=spec["height"], yaw_deg=spec.get("yaw", -90.0), name="Dwarf_Mesh")
    p = spec["p"]
    bones = biped.biped_bones(p)
    arm = rigkit.build_armature("Dwarf", bones)
    rigkit.skin(body, arm, bones)
    anim = Animator(arm)
    biped.setup_neutral(anim, p)
    biped.hero_clips(anim, kneel_drop=spec.get("kneel", 0.2))
    if preview:
        shots = [("Idle", 1), ("Walk", 1), ("Run", 1), ("Axe_Swing", 6), ("Heavy_Swing", 13), ("Heavy_Swing", 17),
                 ("Aim", 1), ("Downed", 1)]
        for clip, frame in shots:
            rigkit.render_views(preview + "_" + clip + str(frame), views=("quarter",), target=(0, 0, 0.72), distance=2.1, res=480, frame=frame, track=clip, arm=arm, lift=2.0)
        for t in arm.animation_data.nla_tracks: t.mute = False
    path = rigkit.export([arm, body], key)
    rigkit.save_blend(key)
    print("BUILT", key, os.path.getsize(path), anim.clips)

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
preview = None
if "--preview" in args:
    i = args.index("--preview"); preview = args[i + 1]; args = args[:i] + args[i + 2:]
for key in (args or list(DWARVES)):
    build(key, preview + "_" + key if preview else None)
