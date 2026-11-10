# blender -b -P build_pets.py -- [key ...] [--preview out_dir]
# Pack Badger, Copper Mole, Grove Sprite and the mountain pony, sculpted locally (see sculpt.py).
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, rigkit, creatures, sculpt
from rigkit import Animator
from sculpt import P, limb, hard

GREY, DARK, WHITE = "#7f838b", "#25262b", "#ece8dc"
COPPER, PINK, CLAW = "#a9653c", "#e6a892", "#f3ead8"
CHESTNUT, CREAM, HOOF = "#855636", "#e6dabd", "#2b2320"
LEATHER, LEATHER_DARK, TEAL, GOLD, BRASS = "#8a5a33", "#5a3a22", "#347c7a", "#d9aa4c", "#c9952f"


def badger():
    parts = [
        P((0, 0.05, 0.30), (0.215, 0.36, 0.19), GREY), P((0, 0.30, 0.30), (0.20, 0.21, 0.185), GREY),
        P((0, -0.22, 0.30), (0.195, 0.2, 0.18), "#70747c"), P((0, -0.40, 0.31), (0.15, 0.15, 0.145), WHITE),
        P((0, -0.54, 0.31), (0.135, 0.16, 0.125), WHITE), P((0, -0.69, 0.275), (0.075, 0.10, 0.065), WHITE),
        P((0.10, -0.50, 0.425), (0.05, 0.035, 0.055), DARK),
        P((0.15, -0.30, 0.035), (0.075, 0.10, 0.04), DARK), P((0.16, 0.30, 0.035), (0.075, 0.10, 0.04), DARK),
    ]
    parts += limb((0.14, -0.25, 0.23), (0.15, -0.27, 0.05), 0.075, 0.062, DARK)
    parts += limb((0.15, 0.30, 0.23), (0.16, 0.31, 0.05), 0.08, 0.064, DARK)
    parts += limb((0, 0.50, 0.30), (0, 0.69, 0.25), 0.075, 0.04, GREY)
    body, full = sculpt.skin("pet_badger", parts)
    stripe = lambda co: ((abs(abs(co[:, 0]) - 0.062) < 0.028) & (co[:, 1] < -0.40) & (co[:, 2] > 0.25)).astype(float)
    belly = lambda co: ((co[:, 2] < 0.2) & (co[:, 1] > -0.38)).astype(float) * 0.9
    back = lambda co: (abs(co[:, 0]) < 0.05) * (co[:, 1] > -0.3) * (co[:, 2] > 0.4) * 0.5
    sculpt.paint(body, full, markings=[(belly, DARK), (stripe, DARK), (back, "#a9adb3")])
    hard(body, "sphere", (0, -0.79, 0.285), (0.032, 0.03, 0.028), "#17171a")
    hard(body, "sphere", (0.062, -0.635, 0.34), (0.02, 0.02, 0.02), "#0d0d10", mirror=True)
    hard(body, "sphere", (0.066, -0.650, 0.347), (0.007, 0.007, 0.007), "#ffffff", mirror=True)
    # pack harness: blanket, strap, satchels and a bedroll
    hard(body, "box", (0, 0.06, 0.492), (0.17, 0.2, 0.012), TEAL, bevel=0.006)
    hard(body, "box", (0, 0.06, 0.40), (0.235, 0.03, 0.105), LEATHER_DARK, bevel=0.006)
    hard(body, "box", (0.262, 0.06, 0.345), (0.055, 0.15, 0.10), LEATHER, mirror=True, bevel=0.015)
    hard(body, "box", (0.292, 0.06, 0.40), (0.03, 0.155, 0.035), LEATHER_DARK, mirror=True, bevel=0.01)
    hard(body, "box", (0.325, 0.06, 0.37), (0.008, 0.022, 0.022), GOLD, mirror=True)
    hard(body, "cylinder", (0, 0.10, 0.545), (0.062, 0.062, 0.2), "#b9a171", rot=(0, 90, 0), segments=12)
    hard(body, "cylinder", (0.12, 0.10, 0.545), (0.066, 0.066, 0.012), LEATHER_DARK, rot=(0, 90, 0), mirror=True, segments=12)
    spec = dict(hips=(0.32, 0.32), chest=(-0.22, 0.32), neck=(-0.40, 0.32), head=(-0.46, 0.31), nose=(-0.78, 0.28),
                front=((-0.25, 0.24), (-0.26, 0.13), (-0.28, 0.02)), fx=0.145, hind=((0.30, 0.24), (0.31, 0.13), (0.32, 0.02)), hx=0.155,
                tail=[(0.69, 0.25)], r=0.2, leg_r=0.085, head_r=0.14, neck_r=0.15, tail_r=0.07)
    return body, spec, dict(attack="bite", stride=1.1)


def mole():
    parts = [
        P((0, 0.06, 0.275), (0.245, 0.37, 0.225), COPPER), P((0, 0.30, 0.27), (0.22, 0.2, 0.2), COPPER),
        P((0, -0.24, 0.275), (0.21, 0.2, 0.2), COPPER), P((0, -0.43, 0.27), (0.175, 0.2, 0.165), COPPER),
        P((0, -0.62, 0.24), (0.085, 0.125, 0.075), PINK),
        P((0.225, -0.31, 0.06), (0.115, 0.135, 0.05), PINK), P((0.18, 0.32, 0.035), (0.07, 0.10, 0.035), PINK),
    ]
    parts += limb((0.18, -0.25, 0.20), (0.21, -0.29, 0.09), 0.085, 0.075, COPPER)
    parts += limb((0.17, 0.30, 0.20), (0.18, 0.32, 0.06), 0.085, 0.07, COPPER)
    parts += limb((0, 0.44, 0.22), (0, 0.58, 0.18), 0.04, 0.022, PINK)
    body, full = sculpt.skin("pet_mole", parts)
    belly = lambda co: ((co[:, 2] < 0.16) & (abs(co[:, 0]) < 0.17) & (co[:, 1] > -0.5)).astype(float) * 0.8
    sheen = lambda co: (abs(co[:, 0]) < 0.07) * (co[:, 2] > 0.44) * 0.45
    sculpt.paint(body, full, markings=[(belly, "#cf9163"), (sheen, "#c98152")])
    hard(body, "sphere", (0, -0.745, 0.245), (0.038, 0.034, 0.034), "#f08a8a")
    for i, x in enumerate((0.15, 0.225, 0.30)):
        hard(body, "cone", (x, -0.455, 0.055), (0.022, 0.022, 0.06), CLAW, rot=(90, 0, (i - 1) * 12), mirror=True, segments=8)
    hard(body, "sphere", (0.085, -0.555, 0.335), (0.013, 0.013, 0.013), "#0d0d10", mirror=True)
    # brass goggles pushed up on the brow, a headlamp, and wicker panniers
    hard(body, "cylinder", (0.07, -0.50, 0.415), (0.048, 0.048, 0.02), BRASS, rot=(62, 0, 0), mirror=True, segments=12)
    hard(body, "sphere", (0.07, -0.512, 0.424), (0.036, 0.036, 0.012), "#8fd6d0", rot=(62, 0, 0), mirror=True)
    hard(body, "box", (0, -0.47, 0.405), (0.17, 0.014, 0.018), LEATHER_DARK, rot=(62, 0, 0))
    hard(body, "cylinder", (0, -0.36, 0.475), (0.04, 0.04, 0.03), BRASS, rot=(75, 0, 0), segments=10)
    hard(body, "sphere", (0, -0.392, 0.468), (0.03, 0.012, 0.03), "#ffe38f")
    hard(body, "box", (0, 0.10, 0.40), (0.262, 0.026, 0.108), LEATHER_DARK, bevel=0.006)
    hard(body, "box", (0.295, 0.10, 0.31), (0.06, 0.15, 0.10), "#b88c4c", mirror=True, bevel=0.012)
    hard(body, "box", (0.295, 0.10, 0.405), (0.066, 0.156, 0.012), "#8d6a37", mirror=True)
    hard(body, "sphere", (0.295, 0.06, 0.43), (0.04, 0.04, 0.03), "#9aa3ad", mirror=True)
    hard(body, "sphere", (0.3, 0.15, 0.425), (0.035, 0.035, 0.03), "#7d8791", mirror=True)
    spec = dict(hips=(0.34, 0.30), chest=(-0.20, 0.30), neck=(-0.30, 0.29), head=(-0.34, 0.28), nose=(-0.74, 0.24),
                front=((-0.25, 0.20), (-0.27, 0.12), (-0.30, 0.04)), fx=0.2, hind=((0.30, 0.20), (0.31, 0.12), (0.32, 0.03)), hx=0.175,
                tail=[(0.58, 0.18)], r=0.23, leg_r=0.09, head_r=0.17, neck_r=0.19, tail_r=0.04)
    return body, spec, dict(attack="bite", stride=0.9)


def sprite():
    leaf, leaf_light, skin_c, skin_light, bark = "#58a862", "#86cf7c", "#a3d98c", "#c3eaa8", "#6b4a2c"
    parts = [
        P((0, 0, 0.70), (0.165, 0.155, 0.19), skin_c), P((0, -0.01, 0.98), (0.205, 0.195, 0.185), skin_light),
        P((0, 0.0, 1.13), (0.215, 0.205, 0.10), bark), P((0, 0.0, 1.21), (0.12, 0.12, 0.07), bark),
        P((0, 0.04, 0.47), (0.075, 0.075, 0.13), leaf),
    ]
    parts += limb((0.16, -0.02, 0.78), (0.27, -0.06, 0.62), 0.048, 0.04, skin_c)
    parts += limb((0.07, 0, 0.55), (0.09, -0.02, 0.39), 0.052, 0.045, skin_c)
    body, full = sculpt.skin("pet_sprite", parts, voxel=0.016, target_faces=8000)
    cheeks = lambda co: (((abs(co[:, 0]) - 0.115) ** 2 + (co[:, 2] - 0.93) ** 2 < 0.0022) & (co[:, 1] < -0.1)).astype(float) * 0.65
    belly = lambda co: ((abs(co[:, 0]) < 0.09) & (co[:, 1] < -0.08) & (abs(co[:, 2] - 0.68) < 0.11)).astype(float) * 0.7
    sculpt.paint(body, full, markings=[(belly, "#e6f6c8"), (cheeks, "#f2a7a0")], variation=0.04)
    # two leaf wings a side, each with a darker midrib
    hard(body, "sphere", (0.38, 0.13, 1.0), (0.25, 0.018, 0.12), leaf, rot=(0, -24, -14), mirror=True)
    hard(body, "sphere", (0.38, 0.118, 1.0), (0.235, 0.012, 0.016), "#3f8a50", rot=(0, -24, -14), mirror=True)
    hard(body, "sphere", (0.31, 0.13, 0.74), (0.18, 0.016, 0.09), leaf_light, rot=(0, 22, -10), mirror=True)
    hard(body, "sphere", (0.31, 0.118, 0.74), (0.165, 0.011, 0.013), "#58a862", rot=(0, 22, -10), mirror=True)
    hard(body, "sphere", (0.085, -0.185, 1.0), (0.042, 0.03, 0.05), "#14231a", mirror=True)
    hard(body, "sphere", (0.097, -0.213, 1.02), (0.014, 0.01, 0.016), "#ffffff", mirror=True)
    hard(body, "cone", (0, 0.0, 1.31), (0.022, 0.022, 0.06), "#4c351f", segments=8)
    hard(body, "sphere", (0.02, 0.0, 1.36), (0.05, 0.012, 0.03), leaf, rot=(0, 30, 0))
    # a tiny woven seed pouch on a strap
    hard(body, "box", (0, -0.005, 0.74), (0.172, 0.158, 0.014), LEATHER_DARK, rot=(0, 28, 0))
    hard(body, "box", (-0.15, -0.06, 0.63), (0.05, 0.035, 0.055), "#b88c4c", bevel=0.012)
    m = dict(body=(0.52, 0.86), head=(0.88, 1.18), body_r=0.18, head_r=0.22, wing=((0.15, 0.93), (0.36, 0.99), (0.6, 1.06)), wing_y=0.13,
             arm=((0.16, 0.78), (0.27, 0.62)), leg=((0.07, 0.55), (0.09, 0.39)), limb_r=0.05)
    return body, m, dict(flyer=True)


def pony():
    coat, coat_dark = CHESTNUT, "#5c3b26"
    parts = [
        P((0, 0.05, 0.86), (0.275, 0.5, 0.27), coat), P((0, -0.40, 0.89), (0.255, 0.25, 0.275), coat), P((0, 0.48, 0.90), (0.275, 0.27, 0.275), coat),
        P((0, -0.90, 1.44), (0.125, 0.2, 0.135), coat, rot=(35, 0, 0)), P((0, -1.05, 1.33), (0.1, 0.13, 0.098), coat_dark, rot=(35, 0, 0)),
        P((0.08, -0.79, 1.60), (0.038, 0.032, 0.075), coat),
        P((0.16, -0.45, 0.13), (0.09, 0.095, 0.07), CREAM), P((0.17, 0.50, 0.13), (0.09, 0.095, 0.07), CREAM),
        P((0, -0.93, 1.60), (0.075, 0.085, 0.065), CREAM),
    ]
    parts += limb((0, -0.50, 0.98), (0, -0.80, 1.40), 0.2, 0.14, coat)
    parts += limb((0, -0.44, 1.22), (0, -0.74, 1.60), 0.075, 0.085, CREAM)        # mane along the crest
    parts += limb((0.16, -0.42, 0.75), (0.16, -0.44, 0.40), 0.105, 0.072, coat) + limb((0.16, -0.44, 0.40), (0.16, -0.45, 0.14), 0.066, 0.062, coat_dark)
    parts += limb((0.17, 0.50, 0.78), (0.17, 0.56, 0.42), 0.125, 0.078, coat) + limb((0.17, 0.56, 0.42), (0.17, 0.50, 0.14), 0.068, 0.062, coat_dark)
    parts += limb((0, 0.72, 0.98), (0, 0.97, 0.45), 0.09, 0.125, CREAM)
    body, full = sculpt.skin("horse", parts, voxel=0.026, target_faces=9000)
    blaze = lambda co: ((abs(co[:, 0]) < 0.04) & (co[:, 1] < -0.86) & (co[:, 2] > 1.34) & (co[:, 2] < 1.56)).astype(float)
    belly = lambda co: ((co[:, 2] < 0.68) & (co[:, 2] > 0.55) & (abs(co[:, 1]) < 0.5)).astype(float) * 0.35
    dapple = lambda co: (((co[:, 1] * 9).round() + (co[:, 2] * 9).round()) % 2 == 0) * (co[:, 1] > 0.2) * (co[:, 2] > 0.85) * 0.12
    sculpt.paint(body, full, markings=[(belly, "#b98250"), (dapple, "#b17a48"), (blaze, "#f4efe2")])
    hard(body, "cylinder", (0.16, -0.455, 0.05), (0.078, 0.082, 0.05), HOOF, mirror=True, segments=12)
    hard(body, "cylinder", (0.17, 0.50, 0.05), (0.078, 0.082, 0.05), HOOF, mirror=True, segments=12)
    hard(body, "sphere", (0.108, -0.93, 1.475), (0.024, 0.024, 0.026), "#0d0d10", mirror=True)
    hard(body, "sphere", (0.118, -0.945, 1.486), (0.008, 0.008, 0.008), "#ffffff", mirror=True)
    hard(body, "sphere", (0.045, -1.165, 1.27), (0.016, 0.012, 0.014), "#1b1412", mirror=True)
    # tack: blanket with gold trim, saddle, girth, saddlebags and a simple bridle
    hard(body, "box", (0, 0.04, 1.135), (0.30, 0.33, 0.016), TEAL, bevel=0.008)
    hard(body, "box", (0, 0.36, 1.137), (0.305, 0.022, 0.018), GOLD)
    hard(body, "box", (0, -0.28, 1.137), (0.305, 0.022, 0.018), GOLD)
    hard(body, "box", (0, 0.04, 1.165), (0.21, 0.25, 0.035), LEATHER, bevel=0.02)
    hard(body, "box", (0, -0.2, 1.205), (0.13, 0.04, 0.055), LEATHER_DARK, bevel=0.02)
    hard(body, "box", (0, 0.27, 1.21), (0.17, 0.035, 0.06), LEATHER_DARK, bevel=0.02)
    hard(body, "box", (0, 0.0, 0.87), (0.285, 0.035, 0.285), LEATHER_DARK, bevel=0.01)
    hard(body, "box", (0.315, 0.3, 0.97), (0.055, 0.14, 0.11), LEATHER, mirror=True, bevel=0.018)
    hard(body, "box", (0.345, 0.3, 1.04), (0.03, 0.145, 0.03), LEATHER_DARK, mirror=True, bevel=0.01)
    hard(body, "box", (0.377, 0.3, 1.0), (0.008, 0.022, 0.022), GOLD, mirror=True)
    hard(body, "box", (0, -1.02, 1.36), (0.112, 0.016, 0.105), LEATHER_DARK, rot=(35, 0, 0))
    hard(body, "box", (0, -0.86, 1.47), (0.136, 0.016, 0.14), LEATHER_DARK, rot=(35, 0, 0))
    spec = dict(hips=(0.55, 0.95), chest=(-0.42, 0.95), neck=(-0.78, 1.38), head=(-0.8, 1.42), nose=(-1.14, 1.3),
                front=((-0.42, 0.75), (-0.44, 0.40), (-0.45, 0.05)), fx=0.16, hind=((0.50, 0.78), (0.56, 0.42), (0.50, 0.05)), hx=0.17,
                tail=[(0.86, 0.75), (0.97, 0.45)], r=0.3, leg_r=0.105, head_r=0.17, neck_r=0.21, tail_r=0.12)
    return body, spec, dict(attack="bite", gallop=True, scale=0.9, heavy=True)


def scale_spec(spec, k):
    out = {}
    for key, value in spec.items():
        if isinstance(value, (int, float)):
            out[key] = value * k
        elif key == "tail":
            out[key] = [(y * k, z * k) for y, z in value]
        elif key in ("front", "hind"):
            out[key] = tuple((y * k, z * k) for y, z in value)
        else:
            out[key] = tuple(v * k for v in value)
    return out


def gallop(a):
    """Rolling canter for the mount: gathered -> hind drive -> reach -> fore landing."""
    def both(name, keys, lag=1, n=12):
        shifted = [((f + lag) % n, v) for f, v in keys if f < n]
        shifted.sort()
        if shifted[0][0] != 0:
            shifted.insert(0, (0, shifted[-1][1]))
        shifted.append((n, shifted[0][1]))
        return {name + ".R": keys, name + ".L": shifted}
    keys = {}
    keys.update(both("f_upper", [(0, (-44, 0, 0)), (3, (-8, 0, 0)), (6, (34, 0, 0)), (9, (6, 0, 0)), (12, (-44, 0, 0))]))
    keys.update(both("f_lower", [(0, (6, 0, 0)), (3, (0, 0, 0)), (6, (28, 0, 0)), (9, (82, 0, 0)), (12, (6, 0, 0))]))
    keys.update(both("h_upper", [(0, (30, 0, 0)), (3, (-4, 0, 0)), (6, (-30, 0, 0)), (9, (-8, 0, 0)), (12, (30, 0, 0))]))
    keys.update(both("h_lower", [(0, (22, 0, 0)), (3, (48, 0, 0)), (6, (14, 0, 0)), (9, (6, 0, 0)), (12, (22, 0, 0))]))
    keys.update({
        "root": [(0, (3, 0, 0)), (3, (0, 0, 0)), (6, (-3, 0, 0)), (9, (0, 0, 0)), (12, (3, 0, 0))],
        "neck": [(0, (10, 0, 0)), (6, (-8, 0, 0)), (12, (10, 0, 0))],
        "head": [(0, (-6, 0, 0)), (6, (6, 0, 0)), (12, (-6, 0, 0))],
        "tail1": [(0, (-34, 0, 0)), (6, (-48, 0, 6)), (12, (-34, 0, 0))],
        "tail2": [(0, (-18, 0, 0)), (4, (-30, 0, -8)), (9, (-12, 0, 8)), (12, (-18, 0, 0))],
    })
    a.clip("Gallop", 12, keys, moves={"root": [(0, (0, 0, -0.03)), (3, (0, 0, 0.02)), (6, (0, 0, 0.06)), (9, (0, 0, 0.0)), (12, (0, 0, -0.03))]})


BUILDERS = {"pet_badger": badger, "pet_mole": mole, "pet_sprite": sprite, "horse": pony}


def build(key, out=None):
    rigkit.reset()
    body, spec, opts = BUILDERS[key]()
    sculpt.material(body)
    k = opts.get("scale", 1.0)
    if k != 1.0:
        from mathutils import Matrix
        body.data.transform(Matrix.Scale(k, 4))
    lo, hi = rigkit.bounds(body)
    if opts.get("flyer"):
        bones = creatures.flyer_bones(spec)
        arm = rigkit.build_armature(key, bones)
        rigkit.skin(body, arm, bones)
        anim = Animator(arm)
        creatures.flyer_clips(anim, spec)
        shots = [("Idle", 1), ("Idle", 8), ("Walk", 6)]
    else:
        spec = scale_spec(spec, k)
        bones = creatures.quad_bones(spec)
        arm = rigkit.build_armature(key, bones)
        rigkit.skin(body, arm, bones)
        anim = Animator(arm)
        creatures.quad_clips(anim, attack=opts["attack"], heavy=opts.get("heavy", False), tails=len(spec.get("tail", [])), stride=opts.get("stride", 1.0))
        shots = [("Idle", 1), ("Walk", 1), ("Walk", 6)]
        if opts.get("gallop"):
            gallop(anim)
            shots += [("Gallop", 1), ("Gallop", 7)]
    if out:
        span = max(hi[2], hi[1] - lo[1]) * 1.5
        for clip, frame in shots:
            rigkit.render_views(os.path.join(out, "%s_%s%d" % (key, clip, frame)), views=("quarter", "side"), target=(0, (lo[1] + hi[1]) * 0.5, hi[2] * 0.5),
                                distance=span, res=460, frame=frame, track=clip, arm=arm, lift=1.2)
        for t in arm.animation_data.nla_tracks:
            t.mute = False
    path = rigkit.export([arm, body], key)
    rigkit.save_blend(key)
    print("BUILT", key, os.path.getsize(path), len(body.data.vertices), "verts", [round(v, 2) for v in lo], [round(v, 2) for v in hi])


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = None
    if "--preview" in args:
        i = args.index("--preview"); out = args[i + 1]; args = args[:i] + args[i + 2:]
    for key in (args or list(BUILDERS)):
        build(key, out)
