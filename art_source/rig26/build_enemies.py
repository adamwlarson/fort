# blender -b -P build_enemies.py -- [key ...] [--preview out_dir]
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, rigkit, biped, creatures
from rigkit import Animator

GEN = os.path.join(rigkit.ROOT, "art_source", "gen26")
X = lambda limit: (lambda co: co[:, 0] < limit) if limit < 0 else (lambda co: co[:, 0] > limit)

# Front-view joint measurements (x, z) for the +X side of each A-posed mesh.
BIPEDS = {
    "raider": dict(height=1.55, attack="swing", side="L", r=1.0, forces=[(X(-0.56), "hand.L")], m=dict(
        pelvis=.52, spine=.62, chest=.76, neck=.98, head=1.03, top=1.5, shoulder=(.2, .9), elbow=(.39, .78), wrist=(.52, .67), hand=(.58, .58),
        hip=(.1, .52), knee=(.2, .33), ankle=(.29, .14), r={"head": .3, "torso": .2})),
    "emberrunner": dict(height=1.7, attack="claw", side="L", r=0.8, forces=[(X(-0.64), "hand.L"), (X(0.64), "hand.R")], stride=1.2, m=dict(
        pelvis=.66, spine=.78, chest=.95, neck=1.2, head=1.26, top=1.6, shoulder=(.16, 1.15), elbow=(.42, 1.0), wrist=(.59, .85), hand=(.66, .8),
        hip=(.09, .66), knee=(.22, .38), ankle=(.33, .12), r={"head": .26, "torso": .16})),
    "sapper7": dict(height=1.6, attack="slam", side="L", r=0.8, hunch=14, m=dict(
        pelvis=.5, spine=.6, chest=.75, neck=.93, head=1.0, top=1.3, shoulder=(.13, .9), elbow=(.36, .78), wrist=(.49, .66), hand=(.66, .52),
        hip=(.08, .5), knee=(.13, .3), ankle=(.2, .13), head_back=.14, r={"head": .26, "torso": .2})),
    "cinderlobber": dict(height=1.75, attack="lob", side="L", r=1.25, heavy=True, m=dict(
        pelvis=.5, spine=.65, chest=.85, neck=1.1, head=1.15, top=1.45, shoulder=(.36, 1.0), elbow=(.58, .84), wrist=(.66, .76), hand=(.87, .64),
        hip=(.15, .5), knee=(.22, .3), ankle=(.27, .12), head_back=.2, r={"head": .26, "torso": .3})),
    "firearcher": dict(height=1.6, attack="shoot", side="R", r=1.0, forces=[(lambda co: (co[:, 0] > 0.56) | ((co[:, 0] > 0.44) & ((co[:, 2] < 0.6) | (co[:, 2] > 0.95))), "hand.R")], m=dict(
        pelvis=.5, spine=.6, chest=.76, neck=.98, head=1.05, top=1.45, shoulder=(.24, .92), elbow=(.44, .84), wrist=(.6, .77), hand=(.7, .68),
        hip=(.13, .5), knee=(.25, .3), ankle=(.3, .14), r={"head": .28, "torso": .22})),
    "shieldguard": dict(height=1.7, attack="swing", side="L", r=1.2, heavy=True, forces=[(X(0.52), "forearm.R"), (X(-0.62), "hand.L")], m=dict(
        pelvis=.55, spine=.68, chest=.88, neck=1.15, head=1.2, top=1.55, shoulder=(.3, 1.1), elbow=(.5, .98), wrist=(.62, .9), hand=(.7, .84),
        hip=(.17, .55), knee=(.3, .4), ankle=(.36, .15), r={"head": .26, "torso": .28})),
    "prowler": dict(height=1.95, attack="claw", side="R", r=0.8, forces=[(X(-0.72), "hand.L"), (X(0.72), "hand.R")], stride=1.15, hunch=14, m=dict(
        pelvis=.72, spine=.9, chest=1.15, neck=1.5, head=1.56, top=1.9, shoulder=(.2, 1.46), elbow=(.51, 1.22), wrist=(.69, 1.0), hand=(.78, .85),
        hip=(.1, .72), knee=(.27, .59), ankle=(.42, .15), r={"head": .24, "torso": .17})),
    "hexer": dict(height=1.75, attack="cast", side="L", r=1.0, shift=(0.1, 0.0), forces=[(X(-0.55), "hand.L")], m=dict(
        pelvis=.5, spine=.62, chest=.82, neck=1.1, head=1.16, top=1.6, shoulder=(.28, 1.05), elbow=(.45, 1.0), wrist=(.6, .96), hand=(.7, .92),
        hip=(.13, .5), knee=(.25, .32), ankle=(.34, .13), r={"head": .3, "torso": .24})),
    "chieftain": dict(height=3.3, attack="swing", side="L", r=2.3, heavy=True, shift=(0.43, 0.0), forces=[(X(-1.38), "hand.L")], m=dict(
        pelvis=1.05, spine=1.3, chest=1.7, neck=2.3, head=2.4, top=3.0, shoulder=(.75, 2.15), elbow=(1.1, 1.8), wrist=(1.25, 1.52), hand=(1.32, 1.35),
        hip=(.3, 1.05), knee=(.5, .72), ankle=(.68, .3), r={"head": .22, "torso": .26})),
    "colossus": dict(height=5.6, attack="slam", side="L", r=3.9, heavy=True, hunch=4, m=dict(
        pelvis=1.9, spine=2.4, chest=3.1, neck=4.3, head=4.4, top=5.2, shoulder=(1.3, 4.0), elbow=(2.16, 3.15), wrist=(2.37, 2.45), hand=(2.3, 1.75),
        hip=(.55, 1.9), knee=(1.1, 1.2), ankle=(1.3, .45), arm_xmin=1.62, leg_xmax=1.7, r={"head": .18, "torso": .27, "arm": .14, "fore": .14, "hand": .14, "thigh": .15, "shin": .14, "foot": .14})),
    "brute": dict(height=2.5, attack="slam", side="L", r=1.9, heavy=True, hunch=12, m=dict(
        pelvis=.85, spine=1.05, chest=1.4, neck=1.85, head=1.9, top=2.4, shoulder=(.52, 1.66), elbow=(.93, 1.42), wrist=(1.07, 1.18), hand=(1.1, .82),
        hip=(.3, .85), knee=(.52, .6), ankle=(.62, .18), arm_xmin=.78, leg_xmax=.8, r={"head": .2, "torso": .3, "arm": .13, "fore": .14, "hand": .15})),
}

# Winged imps: front-view (x, z) measurements.
FLYERS = {
    "ashwing": dict(height=1.3, m=dict(body=(.55, .85), head=(.88, 1.15), body_r=.14, head_r=.2, wing=((.1, .85), (.43, 1.08), (.94, 1.17)),
                                        arm=((.12, .8), (.48, .57)), leg=((.08, .58), (.21, .22)), tail=(.5, .02), limb_r=.05)),
    "bombwing": dict(height=1.5, bomber=True, m=dict(body=(.15, .8), head=(.9, 1.3), body_r=.45, head_r=.34, wing=((.42, .95), (.62, 1.14), (1.1, .97)),
                                                     arm=((.45, .85), (.58, .78)), limb_r=.07)),
}

# Quadrupeds and dragons: side-view (y, z) measurements with the creature facing -Y.
QUADS = {
    "razorback": dict(height=1.5, attack="charge", m=dict(hips=(.55, .85), chest=(-.3, .85), neck=(-.5, .8), head=(-.6, .72), nose=(-1.05, .52),
        front=((-.35, .6), (-.38, .33), (-.4, .03)), fx=.22, hind=((.5, .6), (.5, .33), (.48, .03)), hx=.22, tail=[(.95, .5)], r=.36, tail_r=.08)),
    "direwolf": dict(height=1.35, attack="bite", stride=1.15, m=dict(hips=(.3, .82), chest=(-.5, .82), neck=(-.72, .98), head=(-.75, 1.0), nose=(-1.1, .96),
        front=((-.55, .6), (-.55, .32), (-.6, .03)), fx=.16, hind=((.3, .6), (.35, .33), (.2, .03)), hx=.17, tail=[(.7, .9), (1.1, .85)], r=.26, tail_r=.16, head_r=.2, neck_r=.22)),
    "stonebear": dict(height=1.9, attack="maul", heavy=True, m=dict(hips=(.75, 1.25), chest=(-.5, 1.3), neck=(-.8, 1.3), head=(-.85, 1.3), nose=(-1.3, 1.2),
        front=((-.65, .95), (-.7, .5), (-.75, .05)), fx=.42, hind=((.7, .9), (.75, .5), (.7, .05)), hx=.4, r=.55, head_r=.36, neck_r=.45, leg_r=.24)),
    "emberdrake": dict(height=3.6, attack="breath", heavy=True, span=7.5, m=dict(hips=(0.0, 1.25), chest=(-1.1, 1.3), neck=(-1.7, 2.0), head=(-1.75, 2.05), nose=(-2.36, 1.95),
        front=((-1.25, 1.0), (-1.45, .5), (-1.6, .05)), fx=.62, hind=((.1, 1.0), (.2, .5), (.05, .05)), hx=.55, tail=[(.9, 1.0), (1.7, .95), (2.35, .95)],
        wing=((.35, -.3, 1.7), (1.77, .24, 3.5), (2.3, .5, 2.56)), wing_z=1.75, r=.5, neck_r=.36, head_r=.36, tail_r=.3, leg_r=.25, wing_r=.4)),
    "frostwyrm": dict(height=3.6, attack="breath", heavy=True, span=7.0, m=dict(hips=(.1, 1.35), chest=(-1.0, 1.3), neck=(-1.55, 2.05), head=(-1.6, 2.1), nose=(-2.15, 1.9),
        front=((-1.1, 1.1), (-1.25, .55), (-1.4, .05)), fx=.6, hind=((.15, 1.1), (.3, .55), (.15, .05)), hx=.5, tail=[(.9, 1.15), (1.6, 1.05), (2.1, 1.25)],
        wing=((.3, -.4, 1.7), (1.83, .6, 3.5), (1.4, 1.2, 2.5)), wing_z=1.75, r=.42, neck_r=.3, head_r=.34, tail_r=.25, leg_r=.2, wing_r=.4)),
}

SHOTS = [("Idle", 1), ("Walk", 1), ("Walk", 8), ("Attack", 5), ("Attack", 9), ("Death", 19)]


def preview(arm, out, key, height, shots=SHOTS, views=("quarter",), span=None, target=None):
    for clip, frame in shots:
        rigkit.render_views(os.path.join(out, "%s_%s%d" % (key, clip, frame)), views=views, target=target or (0, 0, height * 0.45), distance=span or height * 1.75, res=380,
                            frame=frame, track=clip, arm=arm, lift=2.0)
    for t in arm.animation_data.nla_tracks:
        t.mute = False


def finish(key, arm, body):
    path = rigkit.export([arm, body], key)
    rigkit.save_blend(key)
    print("BUILT", key, os.path.getsize(path))


def build_biped(key, out=None):
    spec = BIPEDS[key]
    rigkit.reset()
    body = rigkit.import_raw(os.path.join(GEN, key + "_raw.glb"), height=spec["height"], name=key + "_Mesh", shift=spec.get("shift", (0.0, 0.0)), tex_size=spec.get("tex", 1024))
    p = creatures.biped_spec(body, spec["m"], spec["height"])
    bones = biped.biped_bones(p, scale_r=spec["r"])
    arm = rigkit.build_armature(key, bones)
    rigkit.skin(body, arm, bones, forces=spec.get("forces"))
    anim = Animator(arm)
    biped.setup_neutral(anim, p, out_deg=spec.get("hang", 18.0))
    creatures.enemy_clips(anim, attack=spec["attack"], side=spec["side"], heavy=spec.get("heavy", False), hunch=spec.get("hunch", 8.0), stride=spec.get("stride", 1.0))
    if out:
        preview(arm, out, key, spec["height"])
    finish(key, arm, body)


def build_flyer(key, out=None):
    spec = FLYERS[key]
    rigkit.reset()
    body = rigkit.import_raw(os.path.join(GEN, key + "_raw.glb"), height=spec["height"], name=key + "_Mesh", center="bbox")
    m = dict(spec["m"])
    m["y"] = creatures.torso_y(body, spec["height"] * 0.08, m["body"][0], m["body"][1])
    lo, hi = rigkit.bounds(body)
    m.setdefault("wing_y", m["y"] + 0.04)
    bones = creatures.flyer_bones(m)
    arm = rigkit.build_armature(key, bones)
    rigkit.skin(body, arm, bones)
    anim = Animator(arm)
    creatures.flyer_clips(anim, m, bomber=spec.get("bomber", False))
    if out:
        preview(arm, out, key, spec["height"], shots=[("Idle", 1), ("Idle", 8), ("Walk", 6), ("Attack", 6), ("Attack", 10), ("Death", 12)], span=spec["height"] * 2.2,
                target=(0, 0, spec["height"] * 0.5))
    finish(key, arm, body)


def build_quad(key, out=None):
    spec = QUADS[key]
    rigkit.reset()
    body = rigkit.import_raw(os.path.join(GEN, key + "_raw.glb"), height=spec["height"], name=key + "_Mesh", yaw_deg=spec.get("yaw", 0.0), center="bbox",
                             shift=spec.get("shift", (0.0, 0.0)), tex_size=spec.get("tex", 1024))
    bones = creatures.quad_bones(spec["m"])
    arm = rigkit.build_armature(key, bones)
    rigkit.skin(body, arm, bones)
    anim = Animator(arm)
    creatures.quad_clips(anim, attack=spec["attack"], heavy=spec.get("heavy", False), tails=len(spec["m"].get("tail", [])), wings="wing" in spec["m"], stride=spec.get("stride", 1.0))
    if out:
        preview(arm, out, key, spec["height"], views=("quarter",), span=spec.get("span", spec["height"] * 2.4), target=(0, 0, spec["height"] * 0.45))
    finish(key, arm, body)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = None
    if "--preview" in args:
        i = args.index("--preview"); out = args[i + 1]; args = args[:i] + args[i + 2:]
    for key in (args or list(BIPEDS) + list(FLYERS) + list(QUADS)):
        if key in BIPEDS:
            build_biped(key, out)
        elif key in FLYERS:
            build_flyer(key, out)
        elif key in QUADS:
            build_quad(key, out)
