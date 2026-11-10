"""Biped skeleton preset and shared humanoid animation sets for Fort 26."""
import math
from rigkit import Animator


def mirror(v):
    return (-v[0], v[1], v[2])


def biped_bones(p, scale_r=1.0, extra=None):
    """p: measured joints for the +X side (bone suffix .R) of an A-posed figure facing -Y.
    Required: pelvis(z), spine(z), chest(z), neck(z), head(z), top(z), y (torso depth centre),
    shoulder, elbow, wrist, hand (xyz), hip, knee, ankle, toe (xyz). Optional radii overrides in p['r']."""
    r = {"torso": 0.22, "head": 0.2, "arm": 0.085, "fore": 0.08, "hand": 0.07, "thigh": 0.11, "shin": 0.1, "foot": 0.1}
    r.update(p.get("r", {}))
    r = {k: v * scale_r for k, v in r.items()}
    y = p.get("y", 0.0)
    hy = p.get("head_y", y)
    up = (0, -1, 0)
    back = (0, 1, 0)
    bones = [
        {"name": "root", "head": (0, y, 0), "tail": (0, y, p["pelvis"] * 0.5), "roll": up, "weight": False},
        {"name": "pelvis", "head": (0, y, p["pelvis"]), "tail": (0, y, p["spine"]), "parent": "root", "roll": up, "radius": r["torso"],
         "seg": ((0, y, p["pelvis"] - 0.04), (0, y, p["spine"]))},
        {"name": "spine", "head": (0, y, p["spine"]), "tail": (0, y, p["chest"]), "parent": "pelvis", "roll": up, "radius": r["torso"]},
        {"name": "chest", "head": (0, y, p["chest"]), "tail": (0, y, p["neck"]), "parent": "spine", "roll": up, "radius": r["torso"] * 1.08},
        {"name": "neck", "head": (0, y, p["neck"]), "tail": (0, hy, p["head"]), "parent": "chest", "roll": up, "radius": r["head"] * 0.55},
        {"name": "head", "head": (0, hy, p["head"]), "tail": (0, hy, p["top"]), "parent": "neck", "roll": up, "radius": r["head"],
         "seg": ((0, hy, p["head"] + r["head"] * 0.5), (0, hy, p["top"] + 0.3))},
    ]
    if "head_back" in p:
        limit = p["head_back"]
        for spec in bones:
            if spec["name"] in ("head", "neck"):
                spec["mask"] = lambda co, limit=limit: co[:, 1] < limit
    for suffix, flip in ((".R", False), (".L", True)):
        m = mirror if flip else (lambda v: tuple(v))
        side = -1 if flip else 1
        bones += [
            {"name": "upper_arm" + suffix, "head": m(p["shoulder"]), "tail": m(p["elbow"]), "parent": "chest", "roll": back, "radius": r["arm"]},
            {"name": "forearm" + suffix, "head": m(p["elbow"]), "tail": m(p["wrist"]), "parent": "upper_arm" + suffix, "roll": back, "radius": r["fore"]},
            {"name": "hand" + suffix, "head": m(p["wrist"]), "tail": m(p["hand"]), "parent": "forearm" + suffix, "roll": back, "radius": r["hand"],
             "seg": (m(p["wrist"]), m(tuple(p["wrist"][i] + (p["hand"][i] - p["wrist"][i]) * 2.5 for i in range(3))))},
            {"name": "thigh" + suffix, "head": m(p["hip"]), "tail": m(p["knee"]), "parent": "pelvis", "roll": back, "radius": r["thigh"], "side": side},
            {"name": "shin" + suffix, "head": m(p["knee"]), "tail": m(p["ankle"]), "parent": "thigh" + suffix, "roll": back, "radius": r["shin"], "side": side},
            {"name": "foot" + suffix, "head": m(p["ankle"]), "tail": m(p["toe"]), "parent": "shin" + suffix, "roll": (0, 0, 1), "radius": r["foot"], "side": side,
             "seg": (m((p["ankle"][0], p["ankle"][1], p["ankle"][2] * 0.4)), m((p["toe"][0], p["toe"][1], 0.0)))},
        ]
    if "arm_xmin" in p:
        limit = p["arm_xmin"]
        for spec in bones:
            if spec["name"].startswith(("forearm", "hand")):
                spec["mask"] = lambda co, limit=limit, zmin=p["knee"][2] * 0.92: (abs(co[:, 0]) > limit) & (co[:, 2] > zmin)
    if extra:
        bones += extra
    return bones


def arm_hang(p, out_deg=16.0):
    """Degrees to rotate the +X upper arm about Y so the A-pose arm hangs `out_deg` from vertical."""
    dx = p["elbow"][0] - p["shoulder"][0]
    dz = p["elbow"][2] - p["shoulder"][2]
    return math.degrees(math.atan2(dx, -dz)) - out_deg


def setup_neutral(anim, p, out_deg=8.0, elbow=22.0):
    hang = arm_hang(p, out_deg)
    anim.set_neutral("upper_arm.R", 0, hang, 0)
    anim.set_neutral("upper_arm.L", 0, -hang, 0)
    # relaxed elbows: forearms a touch forward and inward
    anim.set_neutral("forearm.R", -elbow, -4, 0)
    anim.set_neutral("forearm.L", -elbow, 4, 0)
    anim.set_neutral("hand.R", -14, -10, 0)
    anim.set_neutral("hand.L", -14, 10, 0)
    return hang


# Rotation helpers (degrees, world axes, character faces -Y):
#   limbs hang down: x<0 swings forward, x>0 back; y rotates in the frontal plane
#   torso points up: x>0 leans forward; z yaws (z>0 turns toward +X / the .R side)

def hero_clips(a: Animator, stride=1.0, kneel_drop=0.2):
    """Player dwarf animation set. `a` must have neutral arms set."""
    s = stride
    # ---------------- Idle: breathing, weight shift, beard-settling head nod
    a.clip("Idle", 48, {
        "spine": [(0, (1.5, 0, 0)), (24, (3.0, 0, 1.2)), (48, (1.5, 0, 0))],
        "chest": [(0, (0, 0, 0)), (24, (2.2, 0, 1.0)), (48, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (20, (-2.5, 0, -2.0)), (48, (0, 0, 0))],
        "upper_arm.R": [(0, (0, 0, 0)), (24, (3, 2.5, 0)), (48, (0, 0, 0))],
        "upper_arm.L": [(0, (0, 0, 0)), (24, (3, -2.5, 0)), (48, (0, 0, 0))],
        "forearm.R": [(0, (-6, 0, 0)), (26, (-11, 0, 0)), (48, (-6, 0, 0))],
        "forearm.L": [(0, (-6, 0, 0)), (26, (-11, 0, 0)), (48, (-6, 0, 0))],
        "thigh.R": [(0, (0, 0, 0)), (24, (-1.5, 0, 0)), (48, (0, 0, 0))],
        "thigh.L": [(0, (0, 0, 0)), (24, (-1.5, 0, 0)), (48, (0, 0, 0))],
        "shin.R": [(0, (0, 0, 0)), (24, (3, 0, 0)), (48, (0, 0, 0))],
        "shin.L": [(0, (0, 0, 0)), (24, (3, 0, 0)), (48, (0, 0, 0))],
    }, moves={"root": [(0, (0, 0, 0)), (24, (0, 0, -0.012)), (48, (0, 0, 0))]})

    # ---------------- Locomotion
    # Dwarves cover ground fast on short legs, so the cycles are quick, bouncy trots:
    # heel strike -> weight drop -> passing -> push-off, with a high knee on the swing leg,
    # bent pumping elbows, counter-rotating hips and chest, and a head that stays level.
    def cyc(n, points, offset=0.0):
        """Periodic Catmull-Rom through (phase 0..1, (x,y,z)) control points, sampled every frame."""
        pts = sorted(((ph + offset) % 1.0, v) for ph, v in points)
        m = len(pts)
        def sample(t):
            k = 0
            while k < m and pts[k][0] <= t:
                k += 1
            i1 = (k - 1) % m; i2 = k % m; i0 = (i1 - 1) % m; i3 = (i2 + 1) % m
            t1 = pts[i1][0] - (1.0 if k == 0 else 0.0); t2 = pts[i2][0] + (1.0 if k == m else 0.0)
            u = 0.0 if t2 - t1 < 1e-6 else (t - t1) / (t2 - t1)
            out = []
            for c in range(3):
                p0, p1, p2, p3 = pts[i0][1][c], pts[i1][1][c], pts[i2][1][c], pts[i3][1][c]
                out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3))
            return tuple(out)
        keys = [(f, sample(f / n)) for f in range(n)]
        keys.append((n, keys[0][1]))
        return keys

    def legs(n, fwd, back, knee, bob, sway, hip_twist):
        """Leg, foot, pelvis and root tracks for one stride cycle. Phase 0 = right heel strike."""
        fwd *= s; back *= s
        thigh = [(0.0, (-fwd, 0, 0)), (0.12, (-fwd * 0.62, 0, 0)), (0.25, (2, 0, 0)), (0.4, (back * 0.8, 0, 0)), (0.5, (back, 0, 0)),
                 (0.62, (back * 0.25, 0, 0)), (0.75, (-fwd * 0.62, 0, 0)), (0.9, (-fwd * 1.08, 0, 0))]
        shin = [(0.0, (6, 0, 0)), (0.12, (26, 0, 0)), (0.25, (12, 0, 0)), (0.4, (10, 0, 0)), (0.5, (34, 0, 0)),
                (0.62, (knee, 0, 0)), (0.75, (knee * 0.92, 0, 0)), (0.9, (30, 0, 0))]
        foot = [(0.0, (-22, 0, 0)), (0.12, (-4, 0, 0)), (0.25, (0, 0, 0)), (0.4, (12, 0, 0)), (0.5, (32, 0, 0)),
                (0.62, (26, 0, 0)), (0.75, (4, 0, 0)), (0.9, (-16, 0, 0))]
        keys = {
            "thigh.R": cyc(n, thigh), "thigh.L": cyc(n, thigh, 0.5),
            "shin.R": cyc(n, shin), "shin.L": cyc(n, shin, 0.5),
            "foot.R": cyc(n, foot), "foot.L": cyc(n, foot, 0.5),
            # hips swing with the leading leg and dip toward the swing side
            "pelvis": cyc(n, [(0.0, (0, sway, -hip_twist)), (0.25, (0, -sway * 0.4, 0)), (0.5, (0, -sway, hip_twist)), (0.75, (0, sway * 0.4, 0))]),
        }
        # lowest just after each heel strike, highest at each passing position
        root = cyc(n, [(0.0, (0, 0, -bob * 0.5)), (0.11, (0, 0, -bob)), (0.3, (0, 0, bob * 0.55)), (0.5, (0, 0, -bob * 0.5)), (0.61, (0, 0, -bob)), (0.8, (0, 0, bob * 0.55))])
        return keys, {"root": root}

    def gait(name, n, fwd, back, knee, arm, elbow, lean, twist, bob, sway):
        keys, moves = legs(n, fwd, back, knee, bob, sway, twist * 0.9)
        # the right arm swings forward with the left leg (phase 0.5), elbows fold on the forward swing
        upper = [(0.0, (arm * 0.9, 0, 0)), (0.25, (0, 4, 0)), (0.5, (-arm, 6, 0)), (0.75, (-4, 4, 0))]
        fore = [(0.0, (-elbow * 0.55, 0, 0)), (0.25, (-elbow * 0.8, 0, 0)), (0.5, (-elbow * 1.15, 0, 0)), (0.75, (-elbow * 0.8, 0, 0))]
        mirror_y = lambda pts: [(ph, (v[0], -v[1], v[2])) for ph, v in pts]
        keys.update({
            "upper_arm.R": cyc(n, upper), "upper_arm.L": cyc(n, mirror_y(upper), 0.5),
            "forearm.R": cyc(n, fore), "forearm.L": cyc(n, fore, 0.5),
            "hand.R": cyc(n, [(0.0, (8, 0, 0)), (0.5, (-10, 0, 0))]), "hand.L": cyc(n, [(0.0, (8, 0, 0)), (0.5, (-10, 0, 0))], 0.5),
            "spine": cyc(n, [(0.0, (lean, sway * 0.5, twist)), (0.12, (lean + 3, sway * 0.3, twist * 0.7)), (0.25, (lean - 1, 0, 0)),
                             (0.5, (lean, -sway * 0.5, -twist)), (0.62, (lean + 3, -sway * 0.3, -twist * 0.7)), (0.75, (lean - 1, 0, 0))]),
            "chest": cyc(n, [(0.0, (lean * 0.4, 0, twist * 0.8)), (0.25, (lean * 0.4, 0, 0)), (0.5, (lean * 0.4, 0, -twist * 0.8)), (0.75, (lean * 0.4, 0, 0))]),
            # the head undoes the lean and twist so the eyes stay on the path, with a small nod on each landing
            "neck": cyc(n, [(0.0, (-lean * 0.35, 0, -twist * 0.5)), (0.5, (-lean * 0.35, 0, twist * 0.5))]),
            "head": cyc(n, [(0.0, (-lean * 0.55, -sway * 0.3, -twist * 0.9)), (0.12, (-lean * 0.55 + 4, 0, -twist * 0.6)), (0.25, (-lean * 0.55, 0, 0)),
                            (0.5, (-lean * 0.55, sway * 0.3, twist * 0.9)), (0.62, (-lean * 0.55 + 4, 0, twist * 0.6)), (0.75, (-lean * 0.55, 0, 0))]),
        })
        a.clip(name, n, keys, moves=moves)

    gait("Walk", 14, fwd=44, back=30, knee=78, arm=34, elbow=46, lean=9, twist=9, bob=0.03, sway=3.5)
    gait("Run", 11, fwd=58, back=38, knee=104, arm=52, elbow=70, lean=19, twist=13, bob=0.045, sway=4.5)

    # ---------------- Axe_Swing: one-handed diagonal chop, contact at frame 9
    a.clip("Axe_Swing", 28, {
        "upper_arm.R": [(0, (0, 0, 0)), (5, (-112, -8, -14)), (9, (-58, 14, -24)), (13, (-24, 16, -30)), (20, (-8, 6, -8)), (28, (0, 0, 0))],
        "forearm.R": [(0, (-6, 0, 0)), (5, (-104, 0, 0)), (9, (-18, 0, 0)), (13, (-12, 0, 0)), (28, (-6, 0, 0))],
        "hand.R": [(0, (0, 0, 0)), (5, (25, 0, 0)), (9, (-28, 0, 0)), (16, (-6, 0, 0)), (28, (0, 0, 0))],
        "upper_arm.L": [(0, (0, 0, 0)), (5, (24, -14, 0)), (9, (-26, -6, 0)), (16, (-10, -3, 0)), (28, (0, 0, 0))],
        "forearm.L": [(0, (-6, 0, 0)), (5, (-48, 0, 0)), (9, (-58, 0, 0)), (20, (-20, 0, 0)), (28, (-6, 0, 0))],
        "spine": [(0, (1.5, 0, 0)), (5, (-12, 0, 22)), (9, (15, 0, -26)), (14, (11, 0, -18)), (28, (1.5, 0, 0))],
        "chest": [(0, (0, 0, 0)), (5, (-5, 0, 16)), (9, (10, 0, -18)), (14, (6, 0, -10)), (28, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (5, (4, 0, -22)), (9, (-10, 0, 20)), (16, (-4, 0, 8)), (28, (0, 0, 0))],
        "pelvis": [(0, (0, 0, 0)), (5, (0, 0, 9)), (9, (4, 0, -10)), (16, (2, 0, -4)), (28, (0, 0, 0))],
        "thigh.R": [(0, (0, 0, 0)), (5, (8, 0, 0)), (9, (-22, 0, 0)), (16, (-12, 0, 0)), (28, (0, 0, 0))],
        "shin.R": [(0, (0, 0, 0)), (9, (20, 0, 0)), (16, (12, 0, 0)), (28, (0, 0, 0))],
        "thigh.L": [(0, (0, 0, 0)), (9, (14, 0, 0)), (16, (8, 0, 0)), (28, (0, 0, 0))],
        "shin.L": [(0, (0, 0, 0)), (9, (10, 0, 0)), (28, (0, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (5, (0, 0.02, 0.01)), (9, (0, -0.07, -0.05)), (16, (0, -0.04, -0.03)), (28, (0, 0, 0))]})

    # ---------------- Heavy_Swing: two-handed overhead slam, contact at frame 16
    a.clip("Heavy_Swing", 34, {
        "upper_arm.R": [(0, (0, 0, 0)), (7, (-96, 6, -16)), (12, (-114, 6, -18)), (16, (-56, 4, -22)), (20, (-40, 4, -22)), (34, (0, 0, 0))],
        "upper_arm.L": [(0, (0, 0, 0)), (7, (-96, -6, 16)), (12, (-114, -6, 18)), (16, (-56, -4, 22)), (20, (-40, -4, 22)), (34, (0, 0, 0))],
        "forearm.R": [(0, (-6, 0, 0)), (7, (-80, 0, 0)), (12, (-112, 0, 0)), (16, (-14, 0, 0)), (34, (-6, 0, 0))],
        "forearm.L": [(0, (-6, 0, 0)), (7, (-80, 0, 0)), (12, (-112, 0, 0)), (16, (-14, 0, 0)), (34, (-6, 0, 0))],
        "hand.R": [(0, (0, 0, 0)), (12, (30, 0, 0)), (16, (-30, 0, 0)), (24, (-8, 0, 0)), (34, (0, 0, 0))],
        "spine": [(0, (1.5, 0, 0)), (12, (-22, 0, 0)), (16, (26, 0, 0)), (21, (20, 0, 0)), (34, (1.5, 0, 0))],
        "chest": [(0, (0, 0, 0)), (12, (-12, 0, 0)), (16, (16, 0, 0)), (21, (10, 0, 0)), (34, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (12, (10, 0, 0)), (16, (-20, 0, 0)), (22, (-10, 0, 0)), (34, (0, 0, 0))],
        "thigh.R": [(0, (0, 0, 0)), (12, (4, 0, 0)), (16, (-30, 0, 0)), (22, (-22, 0, 0)), (34, (0, 0, 0))],
        "thigh.L": [(0, (0, 0, 0)), (12, (4, 0, 0)), (16, (-30, 0, 0)), (22, (-22, 0, 0)), (34, (0, 0, 0))],
        "shin.R": [(0, (0, 0, 0)), (16, (48, 0, 0)), (22, (36, 0, 0)), (34, (0, 0, 0))],
        "shin.L": [(0, (0, 0, 0)), (16, (48, 0, 0)), (22, (36, 0, 0)), (34, (0, 0, 0))],
        "foot.R": [(0, (0, 0, 0)), (16, (-18, 0, 0)), (34, (0, 0, 0))],
        "foot.L": [(0, (0, 0, 0)), (16, (-18, 0, 0)), (34, (0, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (12, (0, 0.03, 0.03)), (16, (0, -0.05, -0.1)), (22, (0, -0.04, -0.07)), (34, (0, 0, 0))]})

    # ---------------- Gather: loopable two-handed wood chop / pick swing (contact frame 8)
    a.clip("Gather", 17, {
        "upper_arm.R": [(0, (-40, 8, -20)), (4, (-108, 4, -22)), (8, (-50, 8, -28)), (11, (-38, 8, -26)), (17, (-40, 8, -20))],
        "upper_arm.L": [(0, (-44, -6, 30)), (4, (-96, -6, 44)), (8, (-52, -6, 30)), (11, (-42, -6, 28)), (17, (-44, -6, 30))],
        "forearm.R": [(0, (-40, 0, 0)), (4, (-88, 0, 0)), (8, (-16, 0, 0)), (17, (-40, 0, 0))],
        "forearm.L": [(0, (-52, 0, 0)), (4, (-96, 0, 0)), (8, (-38, 0, 0)), (17, (-52, 0, 0))],
        "hand.R": [(0, (0, 0, 0)), (4, (22, 0, 0)), (8, (-24, 0, 0)), (17, (0, 0, 0))],
        "spine": [(0, (6, 0, -4)), (4, (-6, 0, 20)), (8, (16, 0, -20)), (17, (6, 0, -4))],
        "chest": [(0, (2, 0, -2)), (4, (-4, 0, 14)), (8, (9, 0, -14)), (17, (2, 0, -2))],
        "head": [(0, (-4, 0, 4)), (4, (4, 0, -18)), (8, (-10, 0, 16)), (17, (-4, 0, 4))],
        "thigh.R": [(0, (-12, 0, 0)), (8, (-20, 0, 0)), (17, (-12, 0, 0))],
        "thigh.L": [(0, (8, 0, 0)), (8, (12, 0, 0)), (17, (8, 0, 0))],
        "shin.R": [(0, (16, 0, 0)), (8, (26, 0, 0)), (17, (16, 0, 0))],
        "shin.L": [(0, (8, 0, 0)), (8, (10, 0, 0)), (17, (8, 0, 0))],
    }, moves={"root": [(0, (0, 0, -0.03)), (4, (0, 0.01, -0.01)), (8, (0, -0.03, -0.06)), (17, (0, 0, -0.03))]})

    # ---------------- Build: kneeling-forward hammer taps (two taps per loop)
    a.clip("Build", 16, {
        "upper_arm.R": [(0, (-58, 6, 0)), (3, (-104, 4, 0)), (6, (-50, 8, 0)), (11, (-100, 4, 0)), (14, (-50, 8, 0)), (16, (-58, 6, 0))],
        "forearm.R": [(0, (-50, 0, 0)), (3, (-96, 0, 0)), (6, (-34, 0, 0)), (11, (-92, 0, 0)), (14, (-34, 0, 0)), (16, (-50, 0, 0))],
        "hand.R": [(0, (0, 0, 0)), (3, (20, 0, 0)), (6, (-22, 0, 0)), (11, (20, 0, 0)), (14, (-22, 0, 0)), (16, (0, 0, 0))],
        "upper_arm.L": [(0, (-50, -10, 0)), (8, (-54, -12, 0)), (16, (-50, -10, 0))],
        "forearm.L": [(0, (-46, 0, 0)), (8, (-50, 0, 0)), (16, (-46, 0, 0))],
        "spine": [(0, (16, 0, -5)), (3, (11, 0, -2)), (6, (19, 0, -7)), (11, (12, 0, -2)), (14, (19, 0, -7)), (16, (16, 0, -5))],
        "chest": [(0, (8, 0, -3)), (6, (11, 0, -5)), (16, (8, 0, -3))],
        "head": [(0, (-8, 0, 4)), (6, (-3, 0, 6)), (14, (-3, 0, 6)), (16, (-8, 0, 4))],
        "thigh.R": [(0, (-26, 0, 0)), (16, (-26, 0, 0))],
        "thigh.L": [(0, (-26, 0, 0)), (16, (-26, 0, 0))],
        "shin.R": [(0, (44, 0, 0)), (16, (44, 0, 0))],
        "shin.L": [(0, (44, 0, 0)), (16, (44, 0, 0))],
        "foot.R": [(0, (-18, 0, 0)), (16, (-18, 0, 0))],
        "foot.L": [(0, (-18, 0, 0)), (16, (-18, 0, 0))],
    }, moves={"root": [(0, (0, 0, -0.085)), (6, (0, 0, -0.095)), (14, (0, 0, -0.095)), (16, (0, 0, -0.085))]})

    # ---------------- Cast: ability shout / ground slam (peak at frame 10)
    a.clip("Cast", 26, {
        "upper_arm.R": [(0, (0, 0, 0)), (6, (-112, 26, 0)), (10, (-36, 30, 0)), (16, (-20, 22, 0)), (26, (0, 0, 0))],
        "upper_arm.L": [(0, (0, 0, 0)), (6, (-112, -26, 0)), (10, (-36, -30, 0)), (16, (-20, -22, 0)), (26, (0, 0, 0))],
        "forearm.R": [(0, (-6, 0, 0)), (6, (-70, 0, 0)), (10, (-20, 0, 0)), (26, (-6, 0, 0))],
        "forearm.L": [(0, (-6, 0, 0)), (6, (-70, 0, 0)), (10, (-20, 0, 0)), (26, (-6, 0, 0))],
        "spine": [(0, (1.5, 0, 0)), (6, (-14, 0, 0)), (10, (22, 0, 0)), (16, (14, 0, 0)), (26, (1.5, 0, 0))],
        "chest": [(0, (0, 0, 0)), (6, (-10, 0, 0)), (10, (12, 0, 0)), (26, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (6, (-16, 0, 0)), (10, (8, 0, 0)), (26, (0, 0, 0))],
        "thigh.R": [(0, (0, 0, 0)), (6, (4, 0, 0)), (10, (-34, 0, 0)), (16, (-24, 0, 0)), (26, (0, 0, 0))],
        "thigh.L": [(0, (0, 0, 0)), (6, (4, 0, 0)), (10, (-34, 0, 0)), (16, (-24, 0, 0)), (26, (0, 0, 0))],
        "shin.R": [(0, (0, 0, 0)), (10, (56, 0, 0)), (16, (40, 0, 0)), (26, (0, 0, 0))],
        "shin.L": [(0, (0, 0, 0)), (10, (56, 0, 0)), (16, (40, 0, 0)), (26, (0, 0, 0))],
        "foot.R": [(0, (0, 0, 0)), (10, (-22, 0, 0)), (26, (0, 0, 0))],
        "foot.L": [(0, (0, 0, 0)), (10, (-22, 0, 0)), (26, (0, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (6, (0, 0, 0.05)), (10, (0, 0, -0.12)), (16, (0, 0, -0.08)), (26, (0, 0, 0))]})

    # ---------------- Ranged: Aim (hold), March (walk while aiming), Shoot (recoil + reload)
    aim_r = (-78, 0, -10)
    aim_l = (-60, 0, 40)
    fr, fl = (-10, 0, 0), (-46, 0, 0)
    a.clip("Aim", 40, {
        "upper_arm.R": [(0, aim_r), (20, (aim_r[0] - 1.5, aim_r[1], aim_r[2])), (40, aim_r)],
        "upper_arm.L": [(0, aim_l), (20, (aim_l[0] - 1.5, aim_l[1], aim_l[2])), (40, aim_l)],
        "forearm.R": [(0, fr), (40, fr)], "forearm.L": [(0, fl), (40, fl)],
        "spine": [(0, (3, 0, -10)), (20, (4, 0, -10)), (40, (3, 0, -10))],
        "chest": [(0, (0, 0, -8)), (40, (0, 0, -8))],
        "head": [(0, (0, 0, 16)), (40, (0, 0, 16))],
        "thigh.R": [(0, (-8, 0, 0)), (40, (-8, 0, 0))], "thigh.L": [(0, (8, 0, 0)), (40, (8, 0, 0))],
        "shin.R": [(0, (10, 0, 0)), (40, (10, 0, 0))], "shin.L": [(0, (6, 0, 0)), (40, (6, 0, 0))],
    })
    march_keys, march_moves = legs(16, 34, 24, 60, 0.022, 2.0, 5)
    march_keys.update({
        "upper_arm.R": [(0, aim_r), (8, (aim_r[0] + 3, aim_r[1], aim_r[2])), (16, aim_r)],
        "upper_arm.L": [(0, aim_l), (8, (aim_l[0] + 3, aim_l[1], aim_l[2])), (16, aim_l)],
        "forearm.R": [(0, fr), (16, fr)], "forearm.L": [(0, fl), (16, fl)],
        "spine": [(0, (6, 1.5, -12)), (8, (6, -1.5, -8)), (16, (6, 1.5, -12))],
        "chest": [(0, (0, 0, -8)), (16, (0, 0, -8))],
        "head": [(0, (-3, 0, 16)), (16, (-3, 0, 16))],
    })
    a.clip("March", 16, march_keys, moves=march_moves)
    a.clip("Shoot", 25, {
        "upper_arm.R": [(0, aim_r), (2, (aim_r[0] - 14, aim_r[1], aim_r[2])), (6, aim_r), (12, (aim_r[0] + 22, aim_r[1], aim_r[2])), (20, (aim_r[0] + 10, aim_r[1], aim_r[2])), (25, aim_r)],
        "upper_arm.L": [(0, aim_l), (2, (aim_l[0] - 10, aim_l[1], aim_l[2])), (6, aim_l), (12, (aim_l[0] + 30, aim_l[1] + 6, aim_l[2] + 20)), (18, (aim_l[0] + 6, aim_l[1], aim_l[2] + 6)), (25, aim_l)],
        "forearm.R": [(0, fr), (2, (-22, 0, 0)), (6, fr), (25, fr)],
        "forearm.L": [(0, fl), (12, (-88, 0, 0)), (17, (-60, 0, 0)), (25, fl)],
        "spine": [(0, (3, 0, -10)), (2, (-3, 0, -10)), (7, (4, 0, -10)), (13, (9, 0, -4)), (25, (3, 0, -10))],
        "chest": [(0, (0, 0, -8)), (2, (-4, 0, -8)), (8, (0, 0, -8)), (25, (0, 0, -8))],
        "head": [(0, (0, 0, 16)), (2, (-4, 0, 16)), (12, (10, 0, 8)), (25, (0, 0, 16))],
        "thigh.R": [(0, (-8, 0, 0)), (25, (-8, 0, 0))], "thigh.L": [(0, (8, 0, 0)), (25, (8, 0, 0))],
        "shin.R": [(0, (10, 0, 0)), (25, (10, 0, 0))], "shin.L": [(0, (6, 0, 0)), (25, (6, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (2, (0, 0.03, 0)), (8, (0, 0, 0)), (25, (0, 0, 0))]})

    # ---------------- Thrust: two-handed pike lunge, contact at frame 6
    a.clip("Thrust", 20, {
        "upper_arm.R": [(0, (-50, 4, -16)), (3, (-26, 8, -20)), (6, (-92, 0, -6)), (10, (-86, 0, -8)), (20, (-50, 4, -16))],
        "upper_arm.L": [(0, (-60, -4, 34)), (3, (-48, -4, 40)), (6, (-90, 0, 14)), (10, (-86, 0, 16)), (20, (-60, -4, 34))],
        "forearm.R": [(0, (-60, 0, 0)), (3, (-92, 0, 0)), (6, (-6, 0, 0)), (10, (-10, 0, 0)), (20, (-60, 0, 0))],
        "forearm.L": [(0, (-40, 0, 0)), (3, (-60, 0, 0)), (6, (-10, 0, 0)), (20, (-40, 0, 0))],
        "spine": [(0, (4, 0, -14)), (3, (-2, 0, -24)), (6, (18, 0, 6)), (10, (15, 0, 2)), (20, (4, 0, -14))],
        "chest": [(0, (0, 0, -10)), (3, (0, 0, -16)), (6, (8, 0, 4)), (20, (0, 0, -10))],
        "head": [(0, (0, 0, 20)), (6, (-14, 0, -6)), (20, (0, 0, 20))],
        "thigh.R": [(0, (-8, 0, 0)), (3, (0, 0, 0)), (6, (-40, 0, 0)), (10, (-34, 0, 0)), (20, (-8, 0, 0))],
        "shin.R": [(0, (10, 0, 0)), (6, (44, 0, 0)), (10, (38, 0, 0)), (20, (10, 0, 0))],
        "thigh.L": [(0, (8, 0, 0)), (6, (26, 0, 0)), (20, (8, 0, 0))],
        "shin.L": [(0, (6, 0, 0)), (6, (8, 0, 0)), (20, (6, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (3, (0, 0.04, 0)), (6, (0, -0.16, -0.06)), (10, (0, -0.13, -0.05)), (20, (0, 0, 0))]})

    # ---------------- Air: jump / fall pose with gentle flail
    a.clip("Air", 20, {
        "upper_arm.R": [(0, (-30, 46, 0)), (10, (-22, 54, 0)), (20, (-30, 46, 0))],
        "upper_arm.L": [(0, (-30, -46, 0)), (10, (-22, -54, 0)), (20, (-30, -46, 0))],
        "forearm.R": [(0, (-40, 0, 0)), (10, (-30, 0, 0)), (20, (-40, 0, 0))],
        "forearm.L": [(0, (-40, 0, 0)), (10, (-30, 0, 0)), (20, (-40, 0, 0))],
        "thigh.R": [(0, (-46, 0, 0)), (10, (-38, 0, 0)), (20, (-46, 0, 0))],
        "thigh.L": [(0, (-14, 0, 0)), (10, (-22, 0, 0)), (20, (-14, 0, 0))],
        "shin.R": [(0, (64, 0, 0)), (10, (56, 0, 0)), (20, (64, 0, 0))],
        "shin.L": [(0, (46, 0, 0)), (10, (52, 0, 0)), (20, (46, 0, 0))],
        "spine": [(0, (8, 0, 0)), (10, (5, 0, 0)), (20, (8, 0, 0))],
        "head": [(0, (-8, 0, 0)), (20, (-8, 0, 0))],
    })

    # ---------------- Ride: seated on the pony, reins in hand, light bounce
    a.clip("Ride", 16, {
        "thigh.R": [(0, (-72, 26, 0)), (8, (-70, 26, 0)), (16, (-72, 26, 0))],
        "thigh.L": [(0, (-72, -26, 0)), (8, (-70, -26, 0)), (16, (-72, -26, 0))],
        "shin.R": [(0, (78, 0, 0)), (16, (78, 0, 0))],
        "shin.L": [(0, (78, 0, 0)), (16, (78, 0, 0))],
        "upper_arm.R": [(0, (-16, 4, 0)), (8, (-12, 4, 0)), (16, (-16, 4, 0))],
        "upper_arm.L": [(0, (-16, -4, 0)), (8, (-12, -4, 0)), (16, (-16, -4, 0))],
        "forearm.R": [(0, (-46, 0, 0)), (8, (-40, 0, 0)), (16, (-46, 0, 0))],
        "forearm.L": [(0, (-46, 0, 0)), (8, (-40, 0, 0)), (16, (-46, 0, 0))],
        "spine": [(0, (8, 0, 0)), (8, (4, 0, 0)), (16, (8, 0, 0))],
        "head": [(0, (-6, 0, 0)), (8, (-2, 0, 0)), (16, (-6, 0, 0))],
    }, moves={"root": [(0, (0, 0, 0)), (8, (0, 0, 0.03)), (16, (0, 0, 0))]})

    # ---------------- Hit: quick flinch
    a.clip("Hit", 10, {
        "spine": [(0, (1.5, 0, 0)), (3, (-14, 0, 8)), (10, (1.5, 0, 0))],
        "chest": [(0, (0, 0, 0)), (3, (-8, 0, 6)), (10, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (3, (14, 0, -10)), (10, (0, 0, 0))],
        "upper_arm.R": [(0, (0, 0, 0)), (3, (-20, 26, 0)), (10, (0, 0, 0))],
        "upper_arm.L": [(0, (0, 0, 0)), (3, (-20, -26, 0)), (10, (0, 0, 0))],
    }, loop=False, moves={"root": [(0, (0, 0, 0)), (3, (0, 0.05, -0.02)), (10, (0, 0, 0))]})

    # ---------------- Downed: collapse to one knee, slumped, laboured breathing
    down = {
        "thigh.R": (-88, 6, 0), "shin.R": (104, 0, 0), "foot.R": (10, 0, 0),
        "thigh.L": (10, -6, 0), "shin.L": (92, 0, 0), "foot.L": (58, 0, 0),
        "spine": (34, 0, 6), "chest": (20, 0, 4), "head": (26, 0, -8),
        "upper_arm.R": (-34, 10, 0), "forearm.R": (-30, 0, 0),
        "upper_arm.L": (-10, -22, 0), "forearm.L": (-64, 0, 0),
    }
    drop = (0, 0.0, -kneel_drop)
    a.clip("Fall", 14, {k: [(0, (0, 0, 0) if not k.startswith("forearm") else (-6, 0, 0)), (14, v)] for k, v in down.items()},
           loop=False, moves={"root": [(0, (0, 0, 0)), (14, drop)]})
    breathe = {k: [(0, v), (20, (v[0] + (3 if k in ("spine", "chest") else 0), v[1], v[2])), (40, v)] for k, v in down.items()}
    a.clip("Downed", 40, breathe, moves={"root": [(0, drop), (20, (drop[0], drop[1], drop[2] - 0.012)), (40, drop)]})
