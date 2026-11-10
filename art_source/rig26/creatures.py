"""Fort 26 enemy rigs and animation sets: bipeds, winged imps, quadrupeds and dragons.
Every clip set honours the game contract: Idle, Walk, Attack, Hit, Death."""
import math
import numpy as np
from rigkit import Animator, verts
import biped


def torso_y(obj, x_half, z0, z1):
    co = verts(obj)
    sel = co[(np.abs(co[:, 0]) < x_half) & (co[:, 2] > z0) & (co[:, 2] < z1)]
    return float((sel[:, 1].min() + sel[:, 1].max()) * 0.5) if len(sel) else 0.0


def biped_spec(obj, m, height):
    """m: front-view measurements {pelvis, spine, chest, neck, head, top, shoulder(x,z), elbow, wrist, hand, hip, knee, ankle}."""
    ty = torso_y(obj, height * 0.1, m["pelvis"], m["chest"])
    ay = ty + m.get("arm_y", -0.02 * height)
    fy = ty + m.get("foot_y", 0.0)
    p = {k: m[k] for k in ("pelvis", "spine", "chest", "neck", "head", "top")}
    p["y"] = ty
    p["head_y"] = ty + m.get("head_y", -0.02 * height)
    for k in ("shoulder", "elbow", "wrist", "hand"):
        p[k] = (m[k][0], ty if k == "shoulder" else ay, m[k][1])
    p["hip"] = (m["hip"][0], fy, m["hip"][1])
    p["knee"] = (m["knee"][0], fy - 0.01 * height, m["knee"][1])
    p["ankle"] = (m["ankle"][0], fy + 0.01 * height, m["ankle"][1])
    p["toe"] = (m["ankle"][0], fy - 0.13 * height, 0.02 * height)
    if "head_back" in m:
        p["head_back"] = ty + m["head_back"]
    for k in ("r", "arm_xmin", "leg_xmax"):
        if k in m:
            p[k] = m[k]
    return p


# ------------------------------------------------------------------ biped enemy clips

def enemy_clips(a: Animator, attack="swing", side="L", heavy=False, hunch=8.0, stride=1.0):
    """side: which bone suffix holds the main weapon ('L' is the model's -X hand)."""
    W, O = "." + side, (".R" if side == "L" else ".L")
    sg = 1.0 if side == "R" else -1.0          # sign for frontal-plane/yaw terms on the weapon side
    n_idle = 48 if heavy else 40
    a.clip("Idle", n_idle, {
        "spine": [(0, (hunch, 0, 0)), (n_idle // 2, (hunch + 3, 0, 2 * sg)), (n_idle, (hunch, 0, 0))],
        "chest": [(0, (hunch * 0.5, 0, 0)), (n_idle // 2, (hunch * 0.5 + 2.5, 0, 0)), (n_idle, (hunch * 0.5, 0, 0))],
        "head": [(0, (-hunch, 0, 0)), (n_idle // 3, (-hunch - 2, 0, -5 * sg)), (2 * n_idle // 3, (-hunch + 1, 0, 4 * sg)), (n_idle, (-hunch, 0, 0))],
        "upper_arm" + W: [(0, (-14, 6 * sg, 0)), (n_idle // 2, (-18, 8 * sg, 0)), (n_idle, (-14, 6 * sg, 0))],
        "upper_arm" + O: [(0, (-6, -6 * sg, 0)), (n_idle // 2, (-3, -8 * sg, 0)), (n_idle, (-6, -6 * sg, 0))],
        "forearm" + W: [(0, (-38, 0, 0)), (n_idle // 2, (-44, 0, 0)), (n_idle, (-38, 0, 0))],
        "forearm" + O: [(0, (-22, 0, 0)), (n_idle // 2, (-27, 0, 0)), (n_idle, (-22, 0, 0))],
        "thigh.R": [(0, (-10, 0, 0)), (n_idle, (-10, 0, 0))], "thigh.L": [(0, (-10, 0, 0)), (n_idle, (-10, 0, 0))],
        "shin.R": [(0, (20, 0, 0)), (n_idle // 2, (24, 0, 0)), (n_idle, (20, 0, 0))],
        "shin.L": [(0, (20, 0, 0)), (n_idle // 2, (24, 0, 0)), (n_idle, (20, 0, 0))],
        "foot.R": [(0, (-10, 0, 0)), (n_idle, (-10, 0, 0))], "foot.L": [(0, (-10, 0, 0)), (n_idle, (-10, 0, 0))],
    }, moves={"root": [(0, (0, 0, -0.02)), (n_idle // 2, (0, 0, -0.035)), (n_idle, (0, 0, -0.02))]})

    n = 30 if heavy else 22
    h, q = n // 2, n // 4
    leg = (24 if heavy else 32) * stride
    knee = 40 if heavy else 52
    arm = 14 if heavy else 24
    sway = 5 if heavy else 2.5
    a.clip("Walk", n, {
        "thigh.R": [(0, (-leg, 0, 0)), (q, (-4, 0, 0)), (h, (leg * 0.8, 0, 0)), (h + q, (-leg * 0.5, 0, 0)), (n, (-leg, 0, 0))],
        "thigh.L": [(0, (leg * 0.8, 0, 0)), (q, (-leg * 0.5, 0, 0)), (h, (-leg, 0, 0)), (h + q, (-4, 0, 0)), (n, (leg * 0.8, 0, 0))],
        "shin.R": [(0, (8, 0, 0)), (q, (14, 0, 0)), (h, (knee * 0.5, 0, 0)), (h + q, (knee, 0, 0)), (n, (8, 0, 0))],
        "shin.L": [(0, (knee * 0.5, 0, 0)), (q, (knee, 0, 0)), (h, (8, 0, 0)), (h + q, (14, 0, 0)), (n, (knee * 0.5, 0, 0))],
        "foot.R": [(0, (-14, 0, 0)), (q, (0, 0, 0)), (h, (14, 0, 0)), (n, (-14, 0, 0))],
        "foot.L": [(0, (14, 0, 0)), (h, (-14, 0, 0)), (h + q, (0, 0, 0)), (n, (14, 0, 0))],
        "upper_arm.R": [(0, (arm - 12, 0, 0)), (h, (-arm - 12, 0, 0)), (n, (arm - 12, 0, 0))],
        "upper_arm.L": [(0, (-arm - 12, 0, 0)), (h, (arm - 12, 0, 0)), (n, (-arm - 12, 0, 0))],
        "forearm.R": [(0, (-26, 0, 0)), (h, (-40, 0, 0)), (n, (-26, 0, 0))],
        "forearm.L": [(0, (-40, 0, 0)), (h, (-26, 0, 0)), (n, (-40, 0, 0))],
        "pelvis": [(0, (0, 0, 6)), (h, (0, 0, -6)), (n, (0, 0, 6))],
        "spine": [(0, (hunch + 6, sway, -7)), (h, (hunch + 6, -sway, 7)), (n, (hunch + 6, sway, -7))],
        "chest": [(0, (hunch * 0.5, 0, -5)), (h, (hunch * 0.5, 0, 5)), (n, (hunch * 0.5, 0, -5))],
        "head": [(0, (-hunch - 4, -sway, 8)), (h, (-hunch - 4, sway, -8)), (n, (-hunch - 4, -sway, 8))],
    }, moves={"root": [(0, (0, 0, -0.03)), (q, (0, 0, 0.0)), (h, (0, 0, -0.03)), (h + q, (0, 0, 0.0)), (n, (0, 0, -0.03))]})

    legs_brace = {
        "thigh" + W: [(0, (-10, 0, 0)), (8, (-30, 0, 0)), (20, (-10, 0, 0))],
        "shin" + W: [(0, (20, 0, 0)), (8, (40, 0, 0)), (20, (20, 0, 0))],
        "thigh" + O: [(0, (-10, 0, 0)), (8, (10, 0, 0)), (20, (-10, 0, 0))],
        "shin" + O: [(0, (20, 0, 0)), (8, (16, 0, 0)), (20, (20, 0, 0))],
    }
    lunge = {"root": [(0, (0, 0, -0.02)), (4, (0, 0.03, 0.0)), (8, (0, -0.1, -0.07)), (13, (0, -0.07, -0.05)), (20, (0, 0, -0.02))]}
    if attack == "swing":
        keys = {
            "upper_arm" + W: [(0, (-14, 6 * sg, 0)), (4, (-112, 6 * sg, 12 * sg)), (8, (-54, -10 * sg, 26 * sg)), (12, (-28, -12 * sg, 30 * sg)), (20, (-14, 6 * sg, 0))],
            "forearm" + W: [(0, (-38, 0, 0)), (4, (-100, 0, 0)), (8, (-14, 0, 0)), (20, (-38, 0, 0))],
            "hand" + W: [(0, (0, 0, 0)), (4, (24, 0, 0)), (8, (-26, 0, 0)), (20, (0, 0, 0))],
            "upper_arm" + O: [(0, (-6, -6 * sg, 0)), (4, (20, -16 * sg, 0)), (8, (-30, -8 * sg, 0)), (20, (-6, -6 * sg, 0))],
            "spine": [(0, (hunch, 0, 0)), (4, (-8, 0, -20 * sg)), (8, (22, 0, 24 * sg)), (13, (16, 0, 14 * sg)), (20, (hunch, 0, 0))],
            "chest": [(0, (hunch * 0.5, 0, 0)), (4, (-6, 0, -14 * sg)), (8, (12, 0, 16 * sg)), (20, (hunch * 0.5, 0, 0))],
            "head": [(0, (-hunch, 0, 0)), (4, (6, 0, 18 * sg)), (8, (-16, 0, -18 * sg)), (20, (-hunch, 0, 0))],
        }
    elif attack == "slam":
        keys = {
            "upper_arm.R": [(0, (-14, 6, 0)), (6, (-116, 14, -10)), (10, (-48, 6, -16)), (14, (-36, 6, -16)), (20, (-14, 6, 0))],
            "upper_arm.L": [(0, (-14, -6, 0)), (6, (-116, -14, 10)), (10, (-48, -6, 16)), (14, (-36, -6, 16)), (20, (-14, -6, 0))],
            "forearm.R": [(0, (-30, 0, 0)), (6, (-96, 0, 0)), (10, (-10, 0, 0)), (20, (-30, 0, 0))],
            "forearm.L": [(0, (-30, 0, 0)), (6, (-96, 0, 0)), (10, (-10, 0, 0)), (20, (-30, 0, 0))],
            "spine": [(0, (hunch, 0, 0)), (6, (-18, 0, 0)), (10, (32, 0, 0)), (14, (26, 0, 0)), (20, (hunch, 0, 0))],
            "chest": [(0, (hunch * 0.5, 0, 0)), (6, (-12, 0, 0)), (10, (18, 0, 0)), (20, (hunch * 0.5, 0, 0))],
            "head": [(0, (-hunch, 0, 0)), (6, (12, 0, 0)), (10, (-24, 0, 0)), (20, (-hunch, 0, 0))],
        }
        legs_brace = {
            "thigh.R": [(0, (-10, 0, 0)), (6, (-4, 0, 0)), (10, (-34, 0, 0)), (20, (-10, 0, 0))],
            "thigh.L": [(0, (-10, 0, 0)), (6, (-4, 0, 0)), (10, (-34, 0, 0)), (20, (-10, 0, 0))],
            "shin.R": [(0, (20, 0, 0)), (10, (54, 0, 0)), (20, (20, 0, 0))],
            "shin.L": [(0, (20, 0, 0)), (10, (54, 0, 0)), (20, (20, 0, 0))],
        }
        lunge = {"root": [(0, (0, 0, -0.02)), (6, (0, 0.02, 0.03)), (10, (0, -0.06, -0.13)), (14, (0, -0.05, -0.1)), (20, (0, 0, -0.02))]}
    elif attack == "shoot":
        # bow arm (weapon side) thrust out to the front, string hand draws back to the cheek then releases
        keys = {
            "upper_arm" + W: [(0, (-14, 6 * sg, 0)), (5, (-84, 0, -24 * sg)), (11, (-84, 0, -24 * sg)), (13, (-80, 0, -22 * sg)), (20, (-14, 6 * sg, 0))],
            "forearm" + W: [(0, (-38, 0, 0)), (5, (-6, 0, 0)), (13, (-6, 0, 0)), (20, (-38, 0, 0))],
            "upper_arm" + O: [(0, (-6, -6 * sg, 0)), (5, (-70, 0, 16 * sg)), (11, (-78, -10 * sg, -40 * sg)), (12, (-70, 0, 20 * sg)), (20, (-6, -6 * sg, 0))],
            "forearm" + O: [(0, (-22, 0, 0)), (5, (-30, 0, 0)), (11, (-112, 0, 0)), (12, (-40, 0, 0)), (20, (-22, 0, 0))],
            "spine": [(0, (hunch, 0, 0)), (5, (2, 0, -24 * sg)), (11, (-2, 0, -30 * sg)), (13, (4, 0, -22 * sg)), (20, (hunch, 0, 0))],
            "chest": [(0, (hunch * 0.5, 0, 0)), (5, (0, 0, -16 * sg)), (11, (0, 0, -20 * sg)), (20, (hunch * 0.5, 0, 0))],
            "head": [(0, (-hunch, 0, 0)), (5, (0, 0, 38 * sg)), (12, (0, 0, 46 * sg)), (20, (-hunch, 0, 0))],
        }
        lunge = {"root": [(0, (0, 0, -0.02)), (11, (0, 0.02, -0.03)), (13, (0, 0.04, -0.02)), (20, (0, 0, -0.02))]}
        legs_brace = {}
    elif attack == "cast":
        keys = {
            "upper_arm" + W: [(0, (-14, 6 * sg, 0)), (6, (-110, 16 * sg, 0)), (10, (-70, 4 * sg, 0)), (14, (-64, 4 * sg, 0)), (20, (-14, 6 * sg, 0))],
            "forearm" + W: [(0, (-38, 0, 0)), (6, (-40, 0, 0)), (10, (-8, 0, 0)), (20, (-38, 0, 0))],
            "upper_arm" + O: [(0, (-6, -6 * sg, 0)), (6, (-60, -40 * sg, 0)), (10, (-88, -6 * sg, 0)), (14, (-80, -6 * sg, 0)), (20, (-6, -6 * sg, 0))],
            "forearm" + O: [(0, (-22, 0, 0)), (6, (-80, 0, 0)), (10, (-6, 0, 0)), (20, (-22, 0, 0))],
            "spine": [(0, (hunch, 0, 0)), (6, (-12, 0, 0)), (10, (20, 0, 0)), (20, (hunch, 0, 0))],
            "head": [(0, (-hunch, 0, 0)), (6, (-18, 0, 0)), (10, (-12, 0, 0)), (20, (-hunch, 0, 0))],
        }
        lunge = {"root": [(0, (0, 0, -0.02)), (6, (0, 0, 0.04)), (10, (0, -0.03, -0.05)), (20, (0, 0, -0.02))]}
        legs_brace = {}
    elif attack == "lob":
        # bow deeply so the back-mounted mortar points at the target, recoil on firing
        keys = {
            "spine": [(0, (hunch, 0, 0)), (7, (46, 0, 0)), (10, (56, 0, 0)), (12, (40, 0, 0)), (20, (hunch, 0, 0))],
            "chest": [(0, (hunch * 0.5, 0, 0)), (7, (24, 0, 0)), (10, (28, 0, 0)), (12, (18, 0, 0)), (20, (hunch * 0.5, 0, 0))],
            "head": [(0, (-hunch, 0, 0)), (7, (-50, 0, 0)), (12, (-40, 0, 0)), (20, (-hunch, 0, 0))],
            "upper_arm.R": [(0, (-14, 6, 0)), (7, (-40, 20, 0)), (12, (-34, 22, 0)), (20, (-14, 6, 0))],
            "upper_arm.L": [(0, (-14, -6, 0)), (7, (-40, -20, 0)), (12, (-34, -22, 0)), (20, (-14, -6, 0))],
            "forearm.R": [(0, (-30, 0, 0)), (7, (-70, 0, 0)), (20, (-30, 0, 0))],
            "forearm.L": [(0, (-30, 0, 0)), (7, (-70, 0, 0)), (20, (-30, 0, 0))],
        }
        legs_brace = {
            "thigh.R": [(0, (-10, 0, 0)), (7, (-36, 0, 0)), (20, (-10, 0, 0))], "thigh.L": [(0, (-10, 0, 0)), (7, (-36, 0, 0)), (20, (-10, 0, 0))],
            "shin.R": [(0, (20, 0, 0)), (7, (56, 0, 0)), (20, (20, 0, 0))], "shin.L": [(0, (20, 0, 0)), (7, (56, 0, 0)), (20, (20, 0, 0))],
        }
        lunge = {"root": [(0, (0, 0, -0.02)), (7, (0, 0, -0.1)), (10, (0, 0.05, -0.14)), (13, (0, 0.02, -0.1)), (20, (0, 0, -0.02))]}
    else:  # claw: alternating double slash
        keys = {
            "upper_arm" + W: [(0, (-14, 6 * sg, 0)), (3, (-96, 30 * sg, 0)), (7, (-58, -8 * sg, 34 * sg)), (12, (-30, 0, 20 * sg)), (20, (-14, 6 * sg, 0))],
            "forearm" + W: [(0, (-38, 0, 0)), (3, (-80, 0, 0)), (7, (-12, 0, 0)), (20, (-38, 0, 0))],
            "upper_arm" + O: [(0, (-6, -6 * sg, 0)), (7, (-96, -30 * sg, 0)), (11, (-58, 8 * sg, -34 * sg)), (15, (-30, 0, -20 * sg)), (20, (-6, -6 * sg, 0))],
            "forearm" + O: [(0, (-22, 0, 0)), (7, (-80, 0, 0)), (11, (-12, 0, 0)), (20, (-22, 0, 0))],
            "spine": [(0, (hunch, 0, 0)), (3, (0, 0, -18 * sg)), (7, (20, 0, 22 * sg)), (11, (20, 0, -22 * sg)), (20, (hunch, 0, 0))],
            "chest": [(0, (hunch * 0.5, 0, 0)), (7, (10, 0, 12 * sg)), (11, (10, 0, -12 * sg)), (20, (hunch * 0.5, 0, 0))],
            "head": [(0, (-hunch, 0, 0)), (7, (-14, 0, -14 * sg)), (11, (-14, 0, 14 * sg)), (20, (-hunch, 0, 0))],
        }
    keys.update({k: v for k, v in legs_brace.items() if k not in keys})
    a.clip("Attack", 20, keys, loop=False, moves=lunge)

    a.clip("Hit", 9, {
        "spine": [(0, (hunch, 0, 0)), (3, (-16, 0, 10)), (9, (hunch, 0, 0))],
        "chest": [(0, (hunch * 0.5, 0, 0)), (3, (-10, 0, 8)), (9, (hunch * 0.5, 0, 0))],
        "head": [(0, (-hunch, 0, 0)), (3, (16, 0, -14)), (9, (-hunch, 0, 0))],
        "upper_arm.R": [(0, (-10, 6, 0)), (3, (-30, 34, 0)), (9, (-10, 6, 0))],
        "upper_arm.L": [(0, (-10, -6, 0)), (3, (-30, -34, 0)), (9, (-10, -6, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, -0.02)), (3, (0, 0.07, -0.04)), (9, (0, 0, -0.02))]})

    a.clip("Death", 19, {
        "root": [(0, (0, 0, 0)), (4, (-14, 0, 0)), (11, (-82, 0, 0)), (13, (-90, 0, 0)), (15, (-86, 0, 0)), (19, (-90, 0, 0))],
        "spine": [(0, (hunch, 0, 0)), (4, (-20, 0, 8)), (12, (-6, 0, 0)), (19, (-4, 0, 0))],
        "head": [(0, (-hunch, 0, 0)), (4, (26, 0, 0)), (12, (-10, 0, 14)), (19, (-10, 0, 16))],
        "upper_arm.R": [(0, (-10, 6, 0)), (5, (-70, 50, 0)), (12, (-20, 62, 0)), (19, (-10, 66, 0))],
        "upper_arm.L": [(0, (-10, -6, 0)), (5, (-80, -40, 0)), (12, (-30, -58, 0)), (19, (-16, -62, 0))],
        "forearm.R": [(0, (-30, 0, 0)), (12, (-20, 0, 0)), (19, (-14, 0, 0))],
        "forearm.L": [(0, (-30, 0, 0)), (12, (-40, 0, 0)), (19, (-30, 0, 0))],
        "thigh.R": [(0, (-10, 0, 0)), (6, (-40, 8, 0)), (13, (-12, 14, 0)), (19, (-6, 14, 0))],
        "thigh.L": [(0, (-10, 0, 0)), (6, (-20, -8, 0)), (13, (-30, -12, 0)), (19, (-22, -12, 0))],
        "shin.R": [(0, (20, 0, 0)), (6, (50, 0, 0)), (13, (10, 0, 0)), (19, (6, 0, 0))],
        "shin.L": [(0, (20, 0, 0)), (6, (30, 0, 0)), (13, (44, 0, 0)), (19, (36, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (4, (0, 0.06, 0.05)), (11, (0, 0.25, 0.12)), (13, (0, 0.3, 0.1)), (19, (0, 0.3, 0.1))]})


# ------------------------------------------------------------------ winged imps

def flyer_bones(m, wing_r=0.09):
    """m: body(z0,z1), head(z0,z1), y, wing root/mid/tip (x,z), wing_y, optional arm/leg/tail."""
    y = m.get("y", 0.0)
    wy = m.get("wing_y", y + 0.05)
    up, back = (0, -1, 0), (0, 1, 0)
    r = m.get("body_r", 0.2)
    bones = [
        {"name": "root", "head": (0, y, m["body"][0]), "tail": (0, y, m["body"][0] + 0.1), "roll": up, "weight": False},
        {"name": "body", "head": (0, y, m["body"][0]), "tail": (0, y, m["body"][1]), "parent": "root", "roll": up, "radius": r},
        {"name": "head", "head": (0, y, m["head"][0]), "tail": (0, y, m["head"][1]), "parent": "body", "roll": up, "radius": m.get("head_r", r * 0.9),
         "seg": ((0, y, m["head"][0] + 0.05), (0, y, m["head"][1] + 0.2))},
    ]
    for suffix, s in ((".R", 1), (".L", -1)):
        root, mid, tip = m["wing"]
        bones += [
            {"name": "wing_in" + suffix, "head": (s * root[0], wy, root[1]), "tail": (s * mid[0], wy, mid[1]), "parent": "body", "roll": back, "radius": wing_r,
             "side": s, "mask": (lambda co, s=s, x0=root[0] * 0.9: co[:, 0] * s > x0),
             "seg": ((s * root[0], wy, root[1] - 0.12), (s * mid[0], wy, mid[1] - 0.12))},
            {"name": "wing_out" + suffix, "head": (s * mid[0], wy, mid[1]), "tail": (s * tip[0], wy, tip[1]), "parent": "wing_in" + suffix, "roll": back, "radius": wing_r,
             "side": s, "mask": (lambda co, s=s, x0=mid[0] * 0.8: co[:, 0] * s > x0),
             "seg": ((s * mid[0], wy, mid[1] - 0.15), (s * tip[0], wy, tip[1] - 0.2))},
        ]
        if "arm" in m:
            a0, a1 = m["arm"]
            bones.append({"name": "arm" + suffix, "head": (s * a0[0], y - 0.03, a0[1]), "tail": (s * a1[0], y - 0.05, a1[1]), "parent": "body", "roll": back,
                          "radius": m.get("limb_r", 0.05), "side": s, "mask": (lambda co, s=s, wy=wy: co[:, 1] < wy - 0.03)})
        if "leg" in m:
            l0, l1 = m["leg"]
            bones.append({"name": "leg" + suffix, "head": (s * l0[0], y, l0[1]), "tail": (s * l1[0], y, l1[1]), "parent": "body", "roll": back,
                          "radius": m.get("limb_r", 0.05) * 1.2, "side": s})
    if "tail" in m:
        t0, t1 = m["tail"]
        bones.append({"name": "tail", "head": (0, y + 0.03, t0), "tail": (0, y + 0.03, t1), "parent": "body", "roll": back, "radius": 0.04})
    return bones


def flyer_clips(a: Animator, m, bomber=False):
    has = lambda b: b in a.rest
    def limbs(amount, n):
        k = {}
        for s, sg in ((".R", 1), (".L", -1)):
            if has("arm" + s):
                k["arm" + s] = [(0, (-10, 0, 0)), (n // 2, (-10 - amount, 6 * sg, 0)), (n, (-10, 0, 0))]
            if has("leg" + s):
                k["leg" + s] = [(0, (14, 0, 0)), (n // 2, (14 + amount, 0, 0)), (n, (14, 0, 0))]
        if has("tail"):
            k["tail"] = [(0, (10, 0, -8)), (n // 2, (22, 0, 8)), (n, (10, 0, -8))]
        return k

    def flap(name, n, up, down, bob, lean):
        h = n // 2
        k = {
            "wing_in.R": [(0, (0, -up, -8)), (h, (0, down, 6)), (n, (0, -up, -8))],
            "wing_in.L": [(0, (0, up, 8)), (h, (0, -down, -6)), (n, (0, up, 8))],
            "wing_out.R": [(0, (0, -up * 0.5, 0)), (h - 1, (0, -up * 0.2, 0)), (h + 2, (0, down * 0.9, 0)), (n, (0, -up * 0.5, 0))],
            "wing_out.L": [(0, (0, up * 0.5, 0)), (h - 1, (0, up * 0.2, 0)), (h + 2, (0, -down * 0.9, 0)), (n, (0, up * 0.5, 0))],
            "body": [(0, (lean, 0, 0)), (h, (lean + 5, 0, 0)), (n, (lean, 0, 0))],
            "head": [(0, (-lean, 0, 0)), (h, (-lean - 4, 0, 0)), (n, (-lean, 0, 0))],
        }
        k.update(limbs(8, n))
        a.clip(name, n, k, moves={"root": [(0, (0, 0, -bob)), (h, (0, 0, bob)), (n, (0, 0, -bob))]})

    flap("Idle", 14, 34, 30, 0.05, 6)
    flap("Walk", 10, 40, 36, 0.04, 24)
    # Attack: wings snap back, body dives forward (or bombers heave the bomb down), recover
    a.clip("Attack", 20, {
        "wing_in.R": [(0, (0, -20, 0)), (5, (0, -52, -30)), (9, (0, 30, 20)), (14, (0, -30, 0)), (20, (0, -20, 0))],
        "wing_in.L": [(0, (0, 20, 0)), (5, (0, 52, 30)), (9, (0, -30, -20)), (14, (0, 30, 0)), (20, (0, 20, 0))],
        "wing_out.R": [(0, (0, -10, 0)), (5, (0, -30, 0)), (9, (0, 34, 0)), (20, (0, -10, 0))],
        "wing_out.L": [(0, (0, 10, 0)), (5, (0, 30, 0)), (9, (0, -34, 0)), (20, (0, 10, 0))],
        "body": [(0, (6, 0, 0)), (5, (-22, 0, 0)), (9, (48 if not bomber else 30, 0, 0)), (14, (26, 0, 0)), (20, (6, 0, 0))],
        "head": [(0, (-6, 0, 0)), (5, (14, 0, 0)), (9, (-34, 0, 0)), (20, (-6, 0, 0))],
        **({"arm.R": [(0, (-10, 0, 0)), (5, (-70, 30, 0)), (9, (-96, -10, 0)), (20, (-10, 0, 0))],
            "arm.L": [(0, (-10, 0, 0)), (5, (-70, -30, 0)), (9, (-96, 10, 0)), (20, (-10, 0, 0))]} if has("arm.R") else {}),
        **({"leg.R": [(0, (14, 0, 0)), (9, (-50, 0, 0)), (20, (14, 0, 0))], "leg.L": [(0, (14, 0, 0)), (9, (-50, 0, 0)), (20, (14, 0, 0))]} if has("leg.R") else {}),
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (5, (0, 0.08, 0.1)), (9, (0, -0.2, -0.12)), (14, (0, -0.08, 0)), (20, (0, 0, 0))]})
    a.clip("Hit", 8, {
        "body": [(0, (6, 0, 0)), (3, (-26, 0, 14)), (8, (6, 0, 0))],
        "wing_in.R": [(0, (0, -20, 0)), (3, (0, 26, 30)), (8, (0, -20, 0))],
        "wing_in.L": [(0, (0, 20, 0)), (3, (0, -26, -30)), (8, (0, 20, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (3, (0, 0.12, -0.05)), (8, (0, 0, 0))]})
    a.clip("Death", 19, {
        "root": [(0, (0, 0, 0)), (8, (-80, 0, 60)), (19, (-170, 0, 150))],
        "wing_in.R": [(0, (0, -20, 0)), (6, (0, -70, 0)), (19, (0, -80, 0))],
        "wing_in.L": [(0, (0, 20, 0)), (6, (0, 60, 0)), (19, (0, 84, 0))],
        "wing_out.R": [(0, (0, -10, 0)), (8, (0, -60, 0)), (19, (0, -70, 0))],
        "wing_out.L": [(0, (0, 10, 0)), (8, (0, 50, 0)), (19, (0, 70, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (5, (0, 0.05, 0.1)), (19, (0, 0.2, -0.9))]})


# ------------------------------------------------------------------ quadrupeds and dragons

def quad_bones(m):
    """Side-view measurements, creature faces -Y. m: hips(y,z), chest(y,z), neck(y,z), head(y,z), nose(y,z),
    front leg: shoulder/elbow/paw (y,z) at x=fx; hind: hip/knee/paw at x=hx; tail: list of (y,z); radii; optional wings."""
    r = m.get("r", 0.2)
    up, back, down = (0, 0, 1), (0, 1, 0), (0, 1, 0)
    hy, hz = m["hips"]; cy, cz = m["chest"]; ny, nz = m["neck"]; ey, ez = m["head"]; sy, sz = m["nose"]
    my, mz = (hy + cy) * 0.5, (hz + cz) * 0.5
    bones = [
        {"name": "root", "head": (0, my, mz), "tail": (0, my, mz + r), "roll": (0, -1, 0), "weight": False},
        {"name": "hips", "head": (0, my, mz), "tail": (0, hy, hz), "parent": "root", "roll": up, "radius": r, "seg": ((0, my, mz), (0, hy + r * 0.3, hz))},
        {"name": "chest", "head": (0, my, mz), "tail": (0, cy, cz), "parent": "root", "roll": up, "radius": r * 1.05, "seg": ((0, my, mz), (0, cy, cz))},
        {"name": "neck", "head": (0, cy, cz), "tail": (0, ny, nz), "parent": "chest", "roll": up, "radius": m.get("neck_r", r * 0.7)},
        {"name": "head", "head": (0, ny, nz), "tail": (0, sy, sz), "parent": "neck", "roll": up, "radius": m.get("head_r", r * 0.7),
         "seg": ((0, ey, ez), (0, sy - r, sz))},
    ]
    lr = m.get("leg_r", r * 0.45)
    for suffix, s in ((".R", 1), (".L", -1)):
        fs, fe, fp = m["front"]; hs, hk, hp = m["hind"]
        fx, hx = s * m["fx"], s * m["hx"]
        bones += [
            {"name": "f_upper" + suffix, "head": (fx, fs[0], fs[1]), "tail": (fx, fe[0], fe[1]), "parent": "chest", "roll": back, "radius": lr * 1.25, "side": s, "zmax": fs[1] + lr},
            {"name": "f_lower" + suffix, "head": (fx, fe[0], fe[1]), "tail": (fx, fp[0], fp[1]), "parent": "f_upper" + suffix, "roll": back, "radius": lr, "side": s,
             "seg": ((fx, fe[0], fe[1]), (fx, fp[0], 0.0))},
            {"name": "h_upper" + suffix, "head": (hx, hs[0], hs[1]), "tail": (hx, hk[0], hk[1]), "parent": "hips", "roll": back, "radius": lr * 1.3, "side": s, "zmax": hs[1] + lr},
            {"name": "h_lower" + suffix, "head": (hx, hk[0], hk[1]), "tail": (hx, hp[0], hp[1]), "parent": "h_upper" + suffix, "roll": back, "radius": lr, "side": s,
             "seg": ((hx, hk[0], hk[1]), (hx, hp[0], 0.0))},
        ]
        if "wing" in m:
            w0, w1, w2 = m["wing"]  # (x, y, z) root / wrist / tip for the +X wing
            bones += [
                {"name": "wing_in" + suffix, "head": (s * w0[0], w0[1], w0[2]), "tail": (s * w1[0], w1[1], w1[2]), "parent": "chest", "roll": back, "radius": m.get("wing_r", r * 0.6),
                 "side": s, "mask": (lambda co, s=s, z0=m["wing_z"], x0=w0[0]: (co[:, 2] > z0) & (co[:, 0] * s > x0 * 0.6))},
                {"name": "wing_out" + suffix, "head": (s * w1[0], w1[1], w1[2]), "tail": (s * w2[0], w2[1], w2[2]), "parent": "wing_in" + suffix, "roll": back, "radius": m.get("wing_r", r * 0.6),
                 "side": s, "mask": (lambda co, s=s, z0=m["wing_z"], x0=w1[0]: (co[:, 2] > z0) & (co[:, 0] * s > x0 * 0.7)),
                 "seg": ((s * w1[0], w1[1], w1[2] - r), (s * w2[0], w2[1] + r, w2[2] - r * 2))},
            ]
    tail = m.get("tail", [])
    prev, parent = (hy, hz), "hips"
    for i, (ty, tz) in enumerate(tail):
        bones.append({"name": "tail%d" % (i + 1), "head": (0, prev[0], prev[1]), "tail": (0, ty, tz), "parent": parent, "roll": up,
                      "radius": m.get("tail_r", r * 0.4) * (1 - 0.18 * i), "mask": (lambda co, y0=hy: co[:, 1] > y0 - 0.05)})
        prev, parent = (ty, tz), "tail%d" % (i + 1)
    if "wing" in m:
        zlim, wx, wy = m["wing_z"], m["wing"][0][0] * 0.7, cy
        body_mask = lambda co: ~((co[:, 2] > zlim) & (abs(co[:, 0]) > wx) & (co[:, 1] > wy))
        for spec in bones:
            if spec["name"] in ("hips", "chest") or spec["name"].startswith(("f_", "h_", "tail")):
                if "mask" in spec:
                    old = spec["mask"]
                    spec["mask"] = lambda co, old=old: old(co) & body_mask(co)
                else:
                    spec["mask"] = body_mask
    return bones


def quad_clips(a: Animator, attack="bite", heavy=False, tails=1, wings=False, stride=1.0):
    has = lambda b: b in a.rest
    n_idle = 44
    def tailkeys(n, amp, base=0):
        k = {}
        for i in range(tails):
            ph = i * 3
            k["tail%d" % (i + 1)] = [(0, (base, 0, -amp)), (n // 2, (base, 0, amp)), (n, (base, 0, -amp))]
        return k
    def wingfold(n, breathe=4):
        if not wings:
            return {}
        return {
            "wing_in.R": [(0, (0, -8, 34)), (n // 2, (0, -8 - breathe, 36)), (n, (0, -8, 34))],
            "wing_in.L": [(0, (0, 8, -34)), (n // 2, (0, 8 + breathe, -36)), (n, (0, 8, -34))],
            "wing_out.R": [(0, (0, 20, 30)), (n, (0, 20, 30))],
            "wing_out.L": [(0, (0, -20, -30)), (n, (0, -20, -30))],
        }
    idle = {
        "chest": [(0, (0, 0, 0)), (n_idle // 2, (-2, 0, 0)), (n_idle, (0, 0, 0))],
        "neck": [(0, (0, 0, 0)), (n_idle // 2, (-5, 0, 5)), (n_idle, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (n_idle // 3, (4, 0, 8)), (2 * n_idle // 3, (2, 0, -6)), (n_idle, (0, 0, 0))],
    }
    idle.update(tailkeys(n_idle, 10))
    idle.update(wingfold(n_idle))
    a.clip("Idle", n_idle, idle, moves={"root": [(0, (0, 0, 0)), (n_idle // 2, (0, 0, -0.012)), (n_idle, (0, 0, 0))]})

    n = 26 if heavy else 18
    h, q = n // 2, n // 4
    sw = (20 if heavy else 28) * stride
    kn = 26 if heavy else 36
    def leg(upper, lower, phase):
        # phase 0 or 1 (half-cycle offset). x<0 = swing forward.
        f = lambda t: int(round((t + phase * 0.5) % 1.0 * n))
        pts_u = sorted([(f(0.0), (-sw, 0, 0)), (f(0.25), (0, 0, 0)), (f(0.5), (sw, 0, 0)), (f(0.75), (-sw * 0.3, 0, 0))])
        pts_l = sorted([(f(0.0), (4, 0, 0)), (f(0.25), (0, 0, 0)), (f(0.5), (kn * 0.4, 0, 0)), (f(0.75), (kn, 0, 0))])
        for pts in (pts_u, pts_l):
            if pts[0][0] != 0:
                pts.insert(0, (0, pts[-1][1]))
            if pts[-1][0] != n:
                pts.append((n, pts[0][1]))
        return {upper: pts_u, lower: pts_l}
    walk = {}
    walk.update(leg("f_upper.R", "f_lower.R", 0)); walk.update(leg("h_upper.L", "h_lower.L", 0))
    walk.update(leg("f_upper.L", "f_lower.L", 1)); walk.update(leg("h_upper.R", "h_lower.R", 1))
    walk.update({
        "chest": [(0, (0, 0, 4)), (h, (0, 0, -4)), (n, (0, 0, 4))],
        "hips": [(0, (0, 0, 4)), (h, (0, 0, -4)), (n, (0, 0, 4))],
        "neck": [(0, (4, 0, -3)), (q, (0, 0, 0)), (h, (4, 0, 3)), (h + q, (0, 0, 0)), (n, (4, 0, -3))],
        "head": [(0, (-3, 0, 0)), (q, (2, 0, 0)), (h, (-3, 0, 0)), (h + q, (2, 0, 0)), (n, (-3, 0, 0))],
    })
    walk.update(tailkeys(n, 14))
    walk.update(wingfold(n, 6))
    bob = 0.03 if heavy else 0.02
    a.clip("Walk", n, walk, moves={"root": [(0, (0, 0, -bob)), (q, (0, 0, bob * 0.4)), (h, (0, 0, -bob)), (h + q, (0, 0, bob * 0.4)), (n, (0, 0, -bob))]})

    if attack == "charge":      # boar: lower head, gore upward
        atk = {
            "neck": [(0, (0, 0, 0)), (5, (26, 0, 0)), (9, (-30, 0, 10)), (13, (-16, 0, -8)), (20, (0, 0, 0))],
            "head": [(0, (0, 0, 0)), (5, (18, 0, 0)), (9, (-26, 0, 14)), (13, (-10, 0, -10)), (20, (0, 0, 0))],
            "chest": [(0, (0, 0, 0)), (5, (10, 0, 0)), (9, (-10, 0, 0)), (20, (0, 0, 0))],
            "f_upper.R": [(0, (0, 0, 0)), (5, (18, 0, 0)), (9, (-26, 0, 0)), (20, (0, 0, 0))],
            "f_upper.L": [(0, (0, 0, 0)), (5, (18, 0, 0)), (9, (-26, 0, 0)), (20, (0, 0, 0))],
            "h_upper.R": [(0, (0, 0, 0)), (9, (22, 0, 0)), (20, (0, 0, 0))],
            "h_upper.L": [(0, (0, 0, 0)), (9, (22, 0, 0)), (20, (0, 0, 0))],
        }
        mv = {"root": [(0, (0, 0, 0)), (5, (0, 0.1, -0.05)), (9, (0, -0.3, 0.06)), (14, (0, -0.1, 0)), (20, (0, 0, 0))]}
    elif attack == "maul":      # bear: rear up, slam both forepaws
        atk = {
            "root": [(0, (0, 0, 0)), (7, (-38, 0, 0)), (11, (10, 0, 0)), (20, (0, 0, 0))],
            "neck": [(0, (0, 0, 0)), (7, (20, 0, 0)), (11, (-10, 0, 0)), (20, (0, 0, 0))],
            "head": [(0, (0, 0, 0)), (7, (14, 0, 0)), (11, (-14, 0, 0)), (20, (0, 0, 0))],
            "f_upper.R": [(0, (0, 0, 0)), (7, (-70, 14, 0)), (11, (-20, 0, 0)), (20, (0, 0, 0))],
            "f_upper.L": [(0, (0, 0, 0)), (7, (-70, -14, 0)), (11, (-20, 0, 0)), (20, (0, 0, 0))],
            "f_lower.R": [(0, (0, 0, 0)), (7, (-40, 0, 0)), (11, (0, 0, 0)), (20, (0, 0, 0))],
            "f_lower.L": [(0, (0, 0, 0)), (7, (-40, 0, 0)), (11, (0, 0, 0)), (20, (0, 0, 0))],
            "h_upper.R": [(0, (0, 0, 0)), (7, (30, 0, 0)), (11, (-6, 0, 0)), (20, (0, 0, 0))],
            "h_upper.L": [(0, (0, 0, 0)), (7, (30, 0, 0)), (11, (-6, 0, 0)), (20, (0, 0, 0))],
        }
        mv = {"root": [(0, (0, 0, 0)), (7, (0, 0.12, 0.12)), (11, (0, -0.12, -0.05)), (20, (0, 0, 0))]}
    elif attack == "breath":    # dragon: rear head back, thrust forward with open wings
        atk = {
            "neck": [(0, (0, 0, 0)), (6, (-34, 0, 0)), (10, (26, 0, 0)), (16, (20, 0, 0)), (22, (0, 0, 0))],
            "head": [(0, (0, 0, 0)), (6, (-20, 0, 0)), (10, (16, 0, 0)), (16, (12, 0, 0)), (22, (0, 0, 0))],
            "chest": [(0, (0, 0, 0)), (6, (-12, 0, 0)), (10, (8, 0, 0)), (22, (0, 0, 0))],
            "wing_in.R": [(0, (0, -8, 34)), (6, (0, -34, 0)), (10, (0, 10, -10)), (16, (0, 0, 0)), (22, (0, -8, 34))],
            "wing_in.L": [(0, (0, 8, -34)), (6, (0, 34, 0)), (10, (0, -10, 10)), (16, (0, 0, 0)), (22, (0, 8, -34))],
            "wing_out.R": [(0, (0, 20, 30)), (6, (0, -10, 0)), (16, (0, 0, 0)), (22, (0, 20, 30))],
            "wing_out.L": [(0, (0, -20, -30)), (6, (0, 10, 0)), (16, (0, 0, 0)), (22, (0, -20, -30))],
            "f_upper.R": [(0, (0, 0, 0)), (6, (10, 0, 0)), (10, (-14, 0, 0)), (22, (0, 0, 0))],
            "f_upper.L": [(0, (0, 0, 0)), (6, (10, 0, 0)), (10, (-14, 0, 0)), (22, (0, 0, 0))],
        }
        atk.update({"tail%d" % (i + 1): [(0, (0, 0, 0)), (6, (-12, 0, 10)), (10, (10, 0, -14)), (22, (0, 0, 0))] for i in range(tails)})
        mv = {"root": [(0, (0, 0, 0)), (6, (0, 0.14, 0.06)), (10, (0, -0.22, -0.08)), (16, (0, -0.16, -0.06)), (22, (0, 0, 0))]}
    else:                       # bite: wolf lunge
        atk = {
            "neck": [(0, (0, 0, 0)), (4, (-18, 0, 0)), (8, (22, 0, 0)), (12, (10, 0, 12)), (20, (0, 0, 0))],
            "head": [(0, (0, 0, 0)), (4, (-14, 0, 0)), (8, (14, 0, 0)), (11, (4, 0, -16)), (20, (0, 0, 0))],
            "chest": [(0, (0, 0, 0)), (4, (-8, 0, 0)), (8, (10, 0, 0)), (20, (0, 0, 0))],
            "f_upper.R": [(0, (0, 0, 0)), (4, (16, 0, 0)), (8, (-34, 0, 0)), (20, (0, 0, 0))],
            "f_upper.L": [(0, (0, 0, 0)), (4, (16, 0, 0)), (8, (-34, 0, 0)), (20, (0, 0, 0))],
            "h_upper.R": [(0, (0, 0, 0)), (4, (-14, 0, 0)), (8, (30, 0, 0)), (20, (0, 0, 0))],
            "h_upper.L": [(0, (0, 0, 0)), (4, (-14, 0, 0)), (8, (30, 0, 0)), (20, (0, 0, 0))],
        }
        mv = {"root": [(0, (0, 0, 0)), (4, (0, 0.12, -0.06)), (8, (0, -0.4, 0.08)), (13, (0, -0.15, 0)), (20, (0, 0, 0))]}
    length = 22 if attack == "breath" else 20
    a.clip("Attack", length, atk, loop=False, moves=mv)

    a.clip("Hit", 9, {
        "neck": [(0, (0, 0, 0)), (3, (-16, 0, 18)), (9, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (3, (-10, 0, 14)), (9, (0, 0, 0))],
        "chest": [(0, (0, 0, 0)), (3, (-6, 0, 8)), (9, (0, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (3, (0, 0.1, -0.04)), (9, (0, 0, 0))]})

    drop = a.arm.data.bones["root"].head_local[2] * 0.62
    death = {
        "root": [(0, (0, 0, 0)), (5, (0, -12, 0)), (13, (0, 78, 0)), (15, (0, 84, 0)), (19, (0, 82, 0))],
        "neck": [(0, (0, 0, 0)), (5, (-20, 0, 0)), (14, (10, 0, 20)), (19, (14, 0, 24))],
        "head": [(0, (0, 0, 0)), (5, (-14, 0, 0)), (14, (10, 0, 10)), (19, (12, 0, 12))],
        "f_upper.R": [(0, (0, 0, 0)), (8, (-30, 0, 0)), (19, (-20, 0, 0))], "f_upper.L": [(0, (0, 0, 0)), (8, (20, 0, 0)), (19, (26, 0, 0))],
        "h_upper.R": [(0, (0, 0, 0)), (8, (24, 0, 0)), (19, (18, 0, 0))], "h_upper.L": [(0, (0, 0, 0)), (8, (-20, 0, 0)), (19, (-24, 0, 0))],
    }
    death.update({"tail%d" % (i + 1): [(0, (0, 0, 0)), (19, (20, 0, 10))] for i in range(tails)})
    if wings:
        death.update({"wing_in.R": [(0, (0, -8, 34)), (8, (0, -40, 0)), (19, (0, 30, 40))], "wing_in.L": [(0, (0, 8, -34)), (8, (0, 40, 0)), (19, (0, 70, -20))],
                      "wing_out.R": [(0, (0, 20, 30)), (19, (0, 40, 40))], "wing_out.L": [(0, (0, -20, -30)), (19, (0, -10, -40))]})
    a.clip("Death", 19, death, loop=False, moves={"root": [(0, (0, 0, 0)), (5, (0, 0, 0.04)), (13, (0, 0, -drop)), (19, (0, 0, -drop))]})
