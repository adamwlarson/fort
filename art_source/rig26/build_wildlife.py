# blender -b -P build_wildlife.py -- [key ...] [--preview out_dir]
# Fort 33 wildlife, sculpted locally with the same tools as the pets (see sculpt.py):
# rabbit, frost hare, deer, stag, amber stag, boar, fox, ram, sunhorn, sporeback tortoise,
# cinder salamander and yak. Every animal faces -Y, stands on z = 0 and gets the quadruped
# skeleton and clips (Idle, Walk, Attack, Hit, Death) from creatures.py.
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, rigkit, creatures, sculpt
from rigkit import Animator
from sculpt import P, limb, hard

EYE, GLINT, HOOF, BONE = "#0d0d10", "#ffffff", "#2b2320", "#efe6d2"


def eyes(body, x, y, z, r):
    hard(body, "sphere", (x, y, z), (r, r, r), EYE, mirror=True)
    hard(body, "sphere", (x + r * 0.35, y - r * 0.6, z + r * 0.4), (r * 0.32, r * 0.32, r * 0.32), GLINT, mirror=True)


def rabbit(coat="#9a7a58", belly_c="#e6d9c2", ear_in="#d9a39a", scale=1.35, name="rabbit"):
    dark = "#6f573f" if coat == "#9a7a58" else "#c9d6e2"
    parts = [
        P((0, 0.04, 0.17), (0.105, 0.16, 0.115), coat), P((0, 0.16, 0.185), (0.115, 0.115, 0.125), coat),
        P((0, -0.10, 0.17), (0.09, 0.10, 0.10), coat), P((0, -0.23, 0.265), (0.075, 0.088, 0.075), coat),
        P((0, -0.31, 0.245), (0.046, 0.05, 0.04), belly_c), P((0, 0.29, 0.205), (0.052, 0.05, 0.052), "#f4efe6"),
        P((0.085, 0.05, 0.022), (0.034, 0.085, 0.022), dark),
    ]
    parts += limb((0.036, -0.20, 0.31), (0.05, -0.15, 0.50), 0.03, 0.022, coat)
    parts += limb((0.058, -0.12, 0.12), (0.058, -0.14, 0.025), 0.032, 0.026, dark)
    parts += limb((0.088, 0.14, 0.13), (0.088, 0.09, 0.04), 0.052, 0.036, coat)
    body, full = sculpt.skin(name, parts, voxel=0.011, target_faces=6000)
    belly = lambda co: ((co[:, 2] < 0.12) & (abs(co[:, 0]) < 0.07) & (co[:, 1] > -0.2)).astype(float) * 0.85
    inner = lambda co: ((co[:, 2] > 0.34) & (co[:, 1] < -0.165) & (abs(co[:, 0]) > 0.025)).astype(float) * 0.7
    sculpt.paint(body, full, markings=[(belly, belly_c), (inner, ear_in)], variation=0.04)
    hard(body, "sphere", (0, -0.352, 0.25), (0.014, 0.012, 0.011), "#c9837a")
    eyes(body, 0.055, -0.255, 0.285, 0.015)
    spec = dict(hips=(0.18, 0.19), chest=(-0.10, 0.18), neck=(-0.17, 0.22), head=(-0.19, 0.25), nose=(-0.35, 0.245),
                front=((-0.12, 0.12), (-0.13, 0.07), (-0.14, 0.01)), fx=0.058, hind=((0.14, 0.13), (0.11, 0.08), (0.07, 0.01)), hx=0.088,
                tail=[(0.33, 0.21)], r=0.11, leg_r=0.042, head_r=0.085, neck_r=0.085, tail_r=0.05)
    return body, spec, dict(attack="bite", stride=1.5, scale=scale)


def deer(antlers=False, coat="#a8713f", belly_c="#ead9bd", dark="#5d3d27", antler_c=BONE, name="deer", scale=1.0):
    parts = [
        P((0, 0.05, 0.95), (0.195, 0.42, 0.215), coat), P((0, -0.34, 0.975), (0.19, 0.22, 0.225), coat), P((0, 0.42, 0.985), (0.2, 0.22, 0.22), coat),
        P((0, -0.77, 1.50), (0.085, 0.135, 0.09), coat, rot=(22, 0, 0)), P((0, -0.92, 1.44), (0.052, 0.085, 0.052), dark, rot=(22, 0, 0)),
        P((0.105, -0.68, 1.60), (0.032, 0.022, 0.075), coat, rot=(0, 28, 0)), P((0, 0.63, 1.0), (0.05, 0.065, 0.085), "#f6f1e6"),
    ]
    parts += limb((0, -0.44, 1.04), (0, -0.70, 1.44), 0.135, 0.085, coat)
    parts += limb((0.11, -0.36, 0.82), (0.11, -0.38, 0.43), 0.072, 0.045, coat) + limb((0.11, -0.38, 0.43), (0.11, -0.39, 0.08), 0.04, 0.034, dark)
    parts += limb((0.12, 0.42, 0.84), (0.12, 0.50, 0.46), 0.095, 0.05, coat) + limb((0.12, 0.50, 0.46), (0.12, 0.44, 0.08), 0.042, 0.034, dark)
    body, full = sculpt.skin(name, parts, voxel=0.022, target_faces=8000)
    belly = lambda co: ((co[:, 2] < 0.82) & (co[:, 2] > 0.7) & (abs(co[:, 1]) < 0.55)).astype(float) * 0.75
    throat = lambda co: ((co[:, 1] < -0.5) & (co[:, 1] > -0.7) & (co[:, 2] < 1.28) & (co[:, 2] > 1.0) & (abs(co[:, 0]) < 0.07)).astype(float) * 0.7
    rump = lambda co: ((co[:, 1] > 0.55) & (co[:, 2] > 0.8) & (abs(co[:, 0]) < 0.12)).astype(float) * 0.8
    spots = lambda co: (((co[:, 1] * 11).round() + (co[:, 2] * 13).round() + (abs(co[:, 0]) * 9).round()) % 3 == 0) * (co[:, 2] > 0.98) * (abs(co[:, 1]) < 0.55) * (0.0 if antlers else 0.3)
    sculpt.paint(body, full, markings=[(belly, belly_c), (throat, belly_c), (rump, "#f6f1e6"), (spots, belly_c)])
    for y, z in ((-0.39, 0.035), (0.44, 0.035)):
        hard(body, "cylinder", (0.11 if y < 0 else 0.12, y, z), (0.04, 0.046, 0.035), HOOF, mirror=True, segments=10)
    hard(body, "sphere", (0, -1.0, 1.42), (0.026, 0.022, 0.02), "#1b1412")
    eyes(body, 0.078, -0.80, 1.525, 0.02)
    if antlers:
        # A main beam sweeping back and out, with three tines on each side.
        hard(body, "cylinder", (0.10, -0.70, 1.72), (0.02, 0.02, 0.13), antler_c, rot=(-18, 26, 0), mirror=True, segments=8)
        hard(body, "cylinder", (0.20, -0.63, 1.93), (0.017, 0.017, 0.13), antler_c, rot=(-30, 34, 0), mirror=True, segments=8)
        hard(body, "cone", (0.13, -0.80, 1.78), (0.015, 0.015, 0.085), antler_c, rot=(48, 16, 0), mirror=True, segments=8)
        hard(body, "cone", (0.24, -0.72, 1.94), (0.014, 0.014, 0.09), antler_c, rot=(38, 40, 0), mirror=True, segments=8)
        hard(body, "cone", (0.29, -0.56, 2.08), (0.014, 0.014, 0.09), antler_c, rot=(-20, 30, 0), mirror=True, segments=8)
    spec = dict(hips=(0.50, 1.0), chest=(-0.38, 1.0), neck=(-0.68, 1.42), head=(-0.70, 1.47), nose=(-1.0, 1.42),
                front=((-0.36, 0.82), (-0.38, 0.43), (-0.39, 0.04)), fx=0.11, hind=((0.42, 0.84), (0.50, 0.46), (0.44, 0.04)), hx=0.12,
                tail=[(0.70, 0.95)], r=0.23, leg_r=0.07, head_r=0.11, neck_r=0.15, tail_r=0.06)
    return body, spec, dict(attack="bite", stride=1.25, scale=scale)


def boar():
    coat, dark, snout_c = "#4b3a31", "#2c2320", "#b98877"
    parts = [
        P((0, 0.05, 0.50), (0.25, 0.42, 0.265), coat), P((0, -0.26, 0.575), (0.245, 0.25, 0.285), coat), P((0, 0.38, 0.48), (0.225, 0.2, 0.24), coat),
        P((0, -0.55, 0.47), (0.17, 0.2, 0.175), coat), P((0, -0.76, 0.40), (0.088, 0.13, 0.085), dark),
        P((0.13, -0.49, 0.665), (0.05, 0.03, 0.07), dark, rot=(0, 25, 0)), P((0, -0.10, 0.80), (0.05, 0.30, 0.055), dark),
    ]
    parts += limb((0.15, -0.28, 0.36), (0.15, -0.30, 0.06), 0.078, 0.05, dark)
    parts += limb((0.15, 0.36, 0.37), (0.15, 0.40, 0.06), 0.088, 0.05, dark)
    parts += limb((0, 0.56, 0.52), (0, 0.66, 0.44), 0.03, 0.018, dark)
    body, full = sculpt.skin("boar", parts, voxel=0.022, target_faces=8000)
    belly = lambda co: ((co[:, 2] < 0.3) & (abs(co[:, 1]) < 0.4)).astype(float) * 0.5
    grizzle = lambda co: (abs(co[:, 0]) < 0.1) * (co[:, 2] > 0.74) * (co[:, 1] < 0.3) * 0.5
    sculpt.paint(body, full, markings=[(belly, "#6b5648"), (grizzle, "#77665a")], variation=0.07)
    hard(body, "cylinder", (0, -0.895, 0.395), (0.062, 0.058, 0.012), snout_c, rot=(90, 0, 0), segments=12)
    hard(body, "sphere", (0.024, -0.908, 0.40), (0.012, 0.006, 0.016), "#4a2f2a", mirror=True)
    hard(body, "cone", (0.075, -0.80, 0.415), (0.022, 0.022, 0.075), BONE, rot=(-22, 28, 0), mirror=True, segments=8)
    eyes(body, 0.115, -0.63, 0.545, 0.017)
    for y in (-0.30, 0.40):
        hard(body, "cylinder", (0.15, y, 0.03), (0.05, 0.055, 0.03), HOOF, mirror=True, segments=10)
    spec = dict(hips=(0.40, 0.50), chest=(-0.28, 0.53), neck=(-0.44, 0.50), head=(-0.48, 0.48), nose=(-0.90, 0.40),
                front=((-0.28, 0.36), (-0.29, 0.20), (-0.30, 0.03)), fx=0.15, hind=((0.36, 0.37), (0.38, 0.20), (0.40, 0.03)), hx=0.15,
                tail=[(0.66, 0.44)], r=0.27, leg_r=0.085, head_r=0.18, neck_r=0.23, tail_r=0.035)
    return body, spec, dict(attack="bite", stride=1.0, heavy=True)


def fox():
    coat, dark, white = "#c8642a", "#2e211c", "#f3ece0"
    parts = [
        P((0, 0.03, 0.36), (0.118, 0.27, 0.12), coat), P((0, -0.20, 0.37), (0.115, 0.13, 0.125), coat), P((0, 0.26, 0.36), (0.115, 0.13, 0.12), coat),
        P((0, -0.44, 0.52), (0.085, 0.10, 0.08), coat), P((0, -0.565, 0.49), (0.04, 0.085, 0.036), white),
        P((0.058, -0.40, 0.625), (0.034, 0.022, 0.066), dark, rot=(0, 14, 0)), P((0, 0.84, 0.31), (0.066, 0.085, 0.066), white),
    ]
    parts += limb((0, -0.27, 0.40), (0, -0.38, 0.50), 0.088, 0.072, coat)
    parts += limb((0.075, -0.20, 0.29), (0.075, -0.22, 0.03), 0.042, 0.03, dark)
    parts += limb((0.085, 0.25, 0.29), (0.085, 0.30, 0.03), 0.052, 0.03, dark)
    parts += limb((0, 0.36, 0.36), (0, 0.74, 0.31), 0.065, 0.095, coat)
    body, full = sculpt.skin("fox", parts, voxel=0.013, target_faces=7000)
    bib = lambda co: ((co[:, 2] < 0.36) & (co[:, 1] < -0.12) & (co[:, 1] > -0.46) & (abs(co[:, 0]) < 0.07)).astype(float) * 0.9
    belly = lambda co: ((co[:, 2] < 0.28) & (abs(co[:, 1]) < 0.3) & (abs(co[:, 0]) < 0.07)).astype(float) * 0.7
    sculpt.paint(body, full, markings=[(bib, white), (belly, white)], variation=0.04)
    hard(body, "sphere", (0, -0.648, 0.492), (0.016, 0.014, 0.013), "#17120f")
    eyes(body, 0.052, -0.495, 0.545, 0.014)
    spec = dict(hips=(0.30, 0.37), chest=(-0.20, 0.38), neck=(-0.36, 0.48), head=(-0.38, 0.50), nose=(-0.65, 0.49),
                front=((-0.20, 0.29), (-0.21, 0.16), (-0.22, 0.02)), fx=0.075, hind=((0.25, 0.29), (0.28, 0.16), (0.30, 0.02)), hx=0.085,
                tail=[(0.56, 0.33), (0.90, 0.31)], r=0.13, leg_r=0.048, head_r=0.09, neck_r=0.095, tail_r=0.095)
    return body, spec, dict(attack="bite", stride=1.3, scale=1.2)


def ram(wool="#e3dccb", face="#4a3b33", horn="#c9b48a", name="ram"):
    parts = [
        P((0, 0.03, 0.68), (0.24, 0.36, 0.25), wool), P((0, -0.28, 0.70), (0.22, 0.2, 0.24), wool), P((0, 0.33, 0.68), (0.22, 0.2, 0.23), wool),
        P((0, -0.58, 1.0), (0.095, 0.14, 0.10), face, rot=(25, 0, 0)), P((0, -0.72, 0.93), (0.06, 0.085, 0.06), face, rot=(25, 0, 0)),
        P((0.125, -0.50, 1.0), (0.045, 0.025, 0.03), face), P((0, 0.56, 0.66), (0.05, 0.05, 0.07), wool),
    ]
    parts += limb((0, -0.38, 0.78), (0, -0.50, 0.98), 0.15, 0.115, wool)
    parts += limb((0.12, -0.28, 0.50), (0.12, -0.29, 0.06), 0.055, 0.04, face)
    parts += limb((0.13, 0.32, 0.50), (0.13, 0.36, 0.06), 0.065, 0.04, face)
    body, full = sculpt.skin(name, parts, voxel=0.02, target_faces=8000)
    tufts = lambda co: (((co[:, 1] * 14).round() + (co[:, 2] * 12).round() + (abs(co[:, 0]) * 10).round()) % 2 == 0) * (co[:, 2] > 0.5) * (co[:, 1] > -0.5) * 0.14
    sculpt.paint(body, full, markings=[(tufts, "#cfc6b0" if wool == "#e3dccb" else "#b9a25a")], variation=0.06)
    # Curled horns: a spiral of shrinking beads sweeping back, down and forward again.
    for i in range(9):
        a = math.radians(-60 + i * 34)
        r = 0.135 - i * 0.004
        hard(body, "sphere", (0.10 + i * 0.012, -0.50 + math.sin(a) * r * 0.9, 1.02 + math.cos(a) * r - 0.07), (0.05 - i * 0.004,) * 3, horn, mirror=True)
    for y in (-0.29, 0.36):
        hard(body, "cylinder", (0.12 if y < 0 else 0.13, y, 0.03), (0.042, 0.048, 0.03), HOOF, mirror=True, segments=10)
    hard(body, "sphere", (0, -0.80, 0.905), (0.022, 0.018, 0.016), "#1b1412")
    eyes(body, 0.082, -0.63, 1.03, 0.018)
    spec = dict(hips=(0.36, 0.70), chest=(-0.30, 0.72), neck=(-0.50, 0.96), head=(-0.52, 1.0), nose=(-0.82, 0.91),
                front=((-0.28, 0.50), (-0.29, 0.28), (-0.29, 0.03)), fx=0.12, hind=((0.32, 0.50), (0.35, 0.28), (0.36, 0.03)), hx=0.13,
                tail=[(0.60, 0.62)], r=0.25, leg_r=0.065, head_r=0.12, neck_r=0.16, tail_r=0.05)
    return body, spec, dict(attack="bite", stride=1.0, heavy=True)


def tortoise():
    shell, plate, skin_c, cap, stem = "#55664f", "#a59572", "#6d7f5a", "#63e0c2", "#e9e2c6"
    parts = [
        P((0, 0.05, 0.52), (0.50, 0.62, 0.36), shell), P((0, 0.05, 0.30), (0.43, 0.56, 0.17), plate),
        P((0, -0.95, 0.52), (0.13, 0.16, 0.12), skin_c), P((0, -1.08, 0.49), (0.09, 0.09, 0.08), skin_c),
    ]
    parts += limb((0, -0.55, 0.38), (0, -0.86, 0.50), 0.135, 0.11, skin_c)
    parts += limb((0.36, -0.38, 0.30), (0.42, -0.42, 0.07), 0.13, 0.11, skin_c)
    parts += limb((0.36, 0.45, 0.30), (0.42, 0.50, 0.07), 0.13, 0.11, skin_c)
    parts += limb((0, 0.64, 0.34), (0, 0.84, 0.26), 0.07, 0.035, skin_c)
    body, full = sculpt.skin("tortoise", parts, voxel=0.028, target_faces=8000)
    scutes = lambda co: ((((co[:, 1] * 4.2).round() + (abs(co[:, 0]) * 4.2).round()) % 2 == 0) & (co[:, 2] > 0.5)).astype(float) * 0.22
    rim = lambda co: ((co[:, 2] > 0.36) & (co[:, 2] < 0.44) & (abs(co[:, 1] - 0.05) < 0.62)).astype(float) * 0.5
    moss = lambda co: (co[:, 2] > 0.78) * 0.4
    sculpt.paint(body, full, markings=[(scutes, "#3f4d3c"), (rim, "#3a4636"), (moss, "#6f8f58")], variation=0.07)
    # Glowing mushrooms growing on the shell.
    for x, y, z, s in ((0.0, -0.05, 0.86, 1.3), (0.2, 0.2, 0.80, 0.9), (-0.22, -0.25, 0.78, 0.8), (0.12, -0.36, 0.76, 0.7), (-0.14, 0.34, 0.77, 1.0), (0.3, -0.1, 0.72, 0.6)):
        hard(body, "cylinder", (x, y, z + 0.06 * s), (0.022 * s, 0.022 * s, 0.07 * s), stem, segments=8)
        hard(body, "sphere", (x, y, z + 0.14 * s), (0.085 * s, 0.085 * s, 0.045 * s), cap)
        hard(body, "sphere", (x + 0.03 * s, y - 0.02 * s, z + 0.168 * s), (0.016 * s, 0.016 * s, 0.01 * s), "#e8fff7")
    for x, y in ((0.42, -0.42), (0.42, 0.50)):
        for k in (-1, 0, 1):
            hard(body, "cone", (x + k * 0.05, y - 0.09, 0.035), (0.02, 0.02, 0.045), BONE, rot=(90, 0, 0), mirror=True, segments=8)
    eyes(body, 0.095, -1.03, 0.565, 0.02)
    spec = dict(hips=(0.50, 0.42), chest=(-0.40, 0.42), neck=(-0.82, 0.49), head=(-0.86, 0.50), nose=(-1.16, 0.49),
                front=((-0.38, 0.30), (-0.40, 0.18), (-0.42, 0.03)), fx=0.39, hind=((0.45, 0.30), (0.48, 0.18), (0.50, 0.03)), hx=0.39,
                tail=[(0.86, 0.26)], r=0.45, leg_r=0.15, head_r=0.15, neck_r=0.15, tail_r=0.06)
    return body, spec, dict(attack="bite", stride=0.7, heavy=True)


def salamander():
    hide, ember, pale = "#2b2422", "#ff7a2a", "#ffd27a"
    parts = [
        P((0, 0.0, 0.22), (0.17, 0.42, 0.13), hide), P((0, -0.30, 0.225), (0.165, 0.2, 0.125), hide), P((0, 0.32, 0.215), (0.155, 0.2, 0.12), hide),
        P((0, -0.62, 0.24), (0.16, 0.2, 0.10), hide), P((0, -0.83, 0.22), (0.115, 0.125, 0.072), hide),
        P((0.32, -0.40, 0.03), (0.07, 0.09, 0.028), hide), P((0.32, 0.40, 0.03), (0.07, 0.09, 0.028), hide),
    ]
    parts += limb((0.16, -0.30, 0.20), (0.32, -0.36, 0.05), 0.062, 0.05, hide)
    parts += limb((0.16, 0.30, 0.20), (0.32, 0.36, 0.05), 0.066, 0.05, hide)
    parts += limb((0, 0.44, 0.215), (0, 1.14, 0.11), 0.12, 0.035, hide)
    body, full = sculpt.skin("salamander", parts, voxel=0.016, target_faces=8000)
    cracks = lambda co: ((abs(((co[:, 1] * 6.0 + abs(co[:, 0]) * 4.0) % 1.0) - 0.5) < 0.07) & (co[:, 2] > 0.12)).astype(float) * 0.95
    belly = lambda co: ((co[:, 2] < 0.13) & (abs(co[:, 0]) < 0.13)).astype(float) * 0.8
    sculpt.paint(body, full, markings=[(belly, "#c2491e"), (cracks, ember)], variation=0.05, underside=0.05)
    for i in range(9):
        y = -0.5 + i * 0.16
        hard(body, "cone", (0, y, 0.36 - abs(y) * 0.03), (0.026, 0.035, 0.06 - i * 0.003), pale if i % 2 else ember, rot=(-14, 0, 0), segments=8)
    hard(body, "sphere", (0.10, -0.74, 0.305), (0.028, 0.028, 0.026), pale, mirror=True)
    hard(body, "sphere", (0.108, -0.762, 0.31), (0.009, 0.014, 0.02), EYE, mirror=True)
    spec = dict(hips=(0.34, 0.22), chest=(-0.30, 0.225), neck=(-0.50, 0.23), head=(-0.54, 0.24), nose=(-0.95, 0.22),
                front=((-0.30, 0.20), (-0.33, 0.12), (-0.36, 0.02)), fx=0.25, hind=((0.30, 0.20), (0.33, 0.12), (0.36, 0.02)), hx=0.25,
                tail=[(0.78, 0.17), (1.14, 0.11)], r=0.18, leg_r=0.075, head_r=0.16, neck_r=0.17, tail_r=0.10)
    return body, spec, dict(attack="bite", stride=0.9)


def yak():
    coat, shag, muzzle, horn = "#4a362a", "#3a2a21", "#b9a48a", "#ddd0b4"
    parts = [
        P((0, 0.05, 0.95), (0.36, 0.60, 0.38), coat), P((0, -0.36, 1.15), (0.32, 0.30, 0.33), coat), P((0, 0.50, 0.92), (0.33, 0.28, 0.35), coat),
        P((0, -0.85, 0.95), (0.20, 0.22, 0.20), coat), P((0, -1.05, 0.82), (0.12, 0.13, 0.10), muzzle),
        P((0, 0.05, 0.58), (0.34, 0.56, 0.20), shag), P((0, -0.80, 1.14), (0.16, 0.14, 0.10), shag),
    ]
    parts += limb((0.20, -0.38, 0.62), (0.20, -0.40, 0.09), 0.115, 0.085, shag)
    parts += limb((0.20, 0.45, 0.62), (0.20, 0.46, 0.09), 0.115, 0.085, shag)
    parts += limb((0, 0.72, 0.98), (0, 0.80, 0.42), 0.06, 0.10, shag)
    body, full = sculpt.skin("yak", parts, voxel=0.03, target_faces=9000)
    fringe = lambda co: (((co[:, 1] * 16).round() % 2 == 0) & (co[:, 2] < 0.6) & (co[:, 2] > 0.4)).astype(float) * 0.25
    saddle = lambda co: (abs(co[:, 0]) < 0.14) * (co[:, 2] > 1.2) * 0.3
    sculpt.paint(body, full, markings=[(fringe, "#2a1e18"), (saddle, "#6b5444")], variation=0.08)
    hard(body, "cylinder", (0.25, -0.86, 1.14), (0.045, 0.045, 0.11), horn, rot=(0, 74, 0), mirror=True, segments=10)
    hard(body, "cone", (0.39, -0.88, 1.24), (0.04, 0.04, 0.12), horn, rot=(-8, 22, 0), mirror=True, segments=10)
    for y in (-0.40, 0.46):
        hard(body, "cylinder", (0.20, y, 0.04), (0.09, 0.095, 0.04), HOOF, mirror=True, segments=12)
    hard(body, "sphere", (0.05, -1.165, 0.82), (0.02, 0.014, 0.016), "#1b1412", mirror=True)
    eyes(body, 0.165, -0.95, 1.02, 0.024)
    spec = dict(hips=(0.52, 1.0), chest=(-0.40, 1.02), neck=(-0.66, 1.0), head=(-0.70, 0.98), nose=(-1.17, 0.84),
                front=((-0.38, 0.62), (-0.39, 0.35), (-0.40, 0.04)), fx=0.20, hind=((0.45, 0.62), (0.46, 0.35), (0.46, 0.04)), hx=0.20,
                tail=[(0.78, 0.72), (0.80, 0.42)], r=0.40, leg_r=0.125, head_r=0.21, neck_r=0.27, tail_r=0.09)
    return body, spec, dict(attack="bite", stride=0.9, heavy=True)


BUILDERS = {
    "rabbit": rabbit,
    "frosthare": lambda: rabbit(coat="#e9eef2", belly_c="#ffffff", ear_in="#bcd3e6", scale=1.9, name="frosthare"),
    "deer": deer,
    "stag": lambda: deer(antlers=True, coat="#8a5a35", name="stag", scale=1.12),
    "amberstag": lambda: deer(antlers=True, coat="#d9912e", belly_c="#f6e2b0", dark="#7a4a1c", antler_c="#ffd768", name="amberstag", scale=1.18),
    "boar": boar,
    "fox": fox,
    "ram": ram,
    "sunhorn": lambda: ram(wool="#e8cf74", face="#5a4a2a", horn="#f6f0d0", name="sunhorn"),
    "tortoise": tortoise,
    "salamander": salamander,
    "yak": yak,
}


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


def build(key, out=None):
    rigkit.reset()
    body, spec, opts = BUILDERS[key]()
    sculpt.material(body)
    k = opts.get("scale", 1.0)
    if k != 1.0:
        from mathutils import Matrix
        body.data.transform(Matrix.Scale(k, 4))
    lo, hi = rigkit.bounds(body)
    spec = scale_spec(spec, k)
    bones = creatures.quad_bones(spec)
    arm = rigkit.build_armature(key, bones)
    rigkit.skin(body, arm, bones)
    anim = Animator(arm)
    creatures.quad_clips(anim, attack=opts["attack"], heavy=opts.get("heavy", False), tails=len(spec.get("tail", [])), stride=opts.get("stride", 1.0))
    if out:
        span = max(hi[2], hi[1] - lo[1]) * 1.5
        for clip, frame in (("Idle", 1), ("Walk", 6)):
            rigkit.render_views(os.path.join(out, "%s_%s%d" % (key, clip, frame)), views=("quarter", "side"), target=(0, (lo[1] + hi[1]) * 0.5, hi[2] * 0.5),
                                distance=span, res=420, frame=frame, track=clip, arm=arm, lift=1.2)
        for t in arm.animation_data.nla_tracks:
            t.mute = False
    path = rigkit.export([arm, body], key)
    print("BUILT", key, os.path.getsize(path), len(body.data.vertices), "verts", [round(v, 2) for v in lo], [round(v, 2) for v in hi])


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = None
    if "--preview" in args:
        i = args.index("--preview"); out = args[i + 1]; args = args[:i] + args[i + 2:]
    for key in (args or list(BUILDERS)):
        build(key, out)
