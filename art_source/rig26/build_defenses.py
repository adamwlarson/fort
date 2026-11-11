# blender -b -P build_defenses.py -- [kind ...] [--preview out_dir]
# Castle walls / window / gate / sentry cannon and the ten towers, each with upgrade stages.
# Stage 1 is the base model; groups named Up2* appear at level 3, Up3* at level 6.
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, rigkit
from props import Kit

STONE, STONE_D, STONE_L = "#8b919c", "#666c78", "#a7adb6"
WOOD, WOOD_D, WOOD_L = "#8c5f3c", "#5f3f29", "#b0835a"
IRON, IRON_L, IRON_D = "#4c5866", "#7a8894", "#343d48"
GOLD, BRASS, COPPER = "#d9aa4c", "#c49a45", "#c4783f"
TEAL, TEAL_D = "#2f8f8a", "#246d6a"
CYAN, ICE, PURPLE, PURPLE_D = "#74e4e8", "#c4ecf6", "#a87ce2", "#5d4590"
ORANGE, EMBER, ROPE, DARK = "#f08a3c", "#ffd36a", "#cdb98a", "#23272e"
H = 5.0  # castle storey height


def wall_shell(k, skip=None):
    k.box("Base", (4.0, 0.68, 0.42), (0, 0, 0.21), STONE_D, bevel=0.05)
    k.stones("Base", 4.0, 4.32, 0.5, (0, 0, 0.42), STONE, rows=8, skip=skip, backing=skip is None)
    if skip is not None:                       # mortar backing around the opening only
        k.box("Base", (3.98, 0.36, 0.84), (0, 0, 0.85), "#4a505a", bevel=0, jitter=0.02)
        k.box("Base", (3.98, 0.36, 1.6), (0, 0, 3.93), "#4a505a", bevel=0, jitter=0.02)
        for x in (-1.6, 1.6):
            k.box("Base", (0.78, 0.36, 1.86), (x, 0, 2.2), "#4a505a", bevel=0, jitter=0.02)
    k.box("Base", (4.0, 0.66, 0.2), (0, 0, 4.84), STONE_L, bevel=0.04)
    k.box("Base", (4.0, 0.7, 0.07), (0, 0, 4.965), GOLD, bevel=0.015)


def castlewall():
    k = Kit("def_castlewall", 11, H)
    wall_shell(k)
    # outer face (-Y): a buttress with an arrow slit and a small shield
    k.box("Base", (0.78, 0.26, 3.3), (0, -0.36, 1.85), STONE_D, bevel=0.05, taper=(0.72, 0.5))
    k.box("Base", (0.16, 0.06, 0.95), (0, -0.5, 2.4), DARK, bevel=0)
    k.prism("Base", [(-0.26, 0.3), (0.26, 0.3), (0.26, -0.05), (0, -0.34), (-0.26, -0.05)], 0.06, (0, -0.47, 3.75), TEAL, bevel=0.012)
    k.box("Base", (0.12, 0.03, 0.3), (0, -0.51, 3.78), GOLD, bevel=0.01)
    # inner face (+Y): a lantern bracket
    k.beam("Base", (1.2, 0.26, 3.1), (1.2, 0.56, 3.3), 0.06, IRON)
    k.box("Base", (0.2, 0.2, 0.28), (1.2, 0.6, 3.1), EMBER, bevel=0.04)
    k.box("Base", (0.26, 0.26, 0.06), (1.2, 0.6, 3.27), IRON_D, bevel=0.02)
    for z in (1.2, 3.4):
        k.box("Up2", (4.0, 0.58, 0.16), (0, 0, z), IRON, bevel=0.02)
        k.rivets("Up2", [(x, s * 0.3, z) for x in (-1.7, -0.85, 0.85, 1.7) for s in (-1, 1)], 0.045, IRON_L)
    for x in (-1.4, 1.4):
        k.prism("Up3", [(0, 0.3), (0.2, 0), (0, -0.3), (-0.2, 0)], 0.06, (x, -0.29, 2.3), CYAN)
        k.prism("Up3", [(0, 0.3), (0.2, 0), (0, -0.3), (-0.2, 0)], 0.06, (x, 0.29, 2.3), CYAN)
    k.box("Up3", (4.0, 0.74, 0.1), (0, 0, 4.7), GOLD, bevel=0.02)
    return k


def castlewindow():
    k = Kit("def_castlewindow", 12, H)
    wall_shell(k, skip=lambda x, z: abs(x) < 1.22 and 1.28 < z < 3.12)
    k.box("Base", (2.8, 0.74, 0.16), (0, 0, 1.25), STONE_L, bevel=0.03)            # sill
    k.box("Base", (2.9, 0.7, 0.26), (0, 0, 3.2), STONE_L, bevel=0.04)              # lintel
    k.prism("Base", [(-0.22, 0), (0.22, 0), (0.3, 0.32), (-0.3, 0.32)], 0.72, (0, 0, 3.2), STONE_D, bevel=0.02)
    for x in (-1.3, 1.3):
        k.box("Base", (0.2, 0.66, 1.8), (x, 0, 2.2), STONE_L, bevel=0.03)
    for x in (-1.72, 1.72):                                                        # shutters folded back outside
        k.planks("Base", 0.7, 1.7, 0.06, (x, -0.33, 1.38), WOOD, 3)
        k.box("Base", (0.72, 0.03, 0.08), (x, -0.37, 1.7), IRON, bevel=0.01)
        k.box("Base", (0.72, 0.03, 0.08), (x, -0.37, 2.75), IRON, bevel=0.01)
    k.box("Up2", (2.5, 0.08, 0.1), (0, -0.2, 1.42), IRON, bevel=0.02)
    for x in (-0.8, 0, 0.8):
        k.box("Up2", (0.08, 0.08, 0.5), (x, -0.2, 1.62), IRON, bevel=0.02)
    k.box("Up3", (3.0, 0.76, 0.08), (0, 0, 3.36), GOLD, bevel=0.02)
    k.prism("Up3", [(0, 0.24), (0.17, 0), (0, -0.24), (-0.17, 0)], 0.06, (0, -0.39, 3.9), CYAN)
    return k


def castlegate():
    k = Kit("def_castlegate", 13, H)
    for x in (-1.75, 1.75):
        k.box("Base", (0.56, 0.72, 0.42), (x, 0, 0.21), STONE_D, bevel=0.05)
        k.stones("Base", 0.5, 3.16, 0.62, (x, 0, 0.42), STONE, rows=6, per_row=1)
    k.stones("Base", 4.0, 1.26, 0.56, (0, 0, 3.58), STONE, rows=3)
    k.prism("Base", [(-1.5, 0), (-1.5, 0.2), (-0.9, 0.5), (0.9, 0.5), (1.5, 0.2), (1.5, 0), (1.05, 0), (0.7, 0.24), (-0.7, 0.24), (-1.05, 0)], 0.6, (0, 0, 3.34), STONE_L, bevel=0.02)
    k.prism("Base", [(-0.2, 0), (0.2, 0), (0.28, 0.5), (-0.28, 0.5)], 0.7, (0, 0, 3.52), STONE_D, bevel=0.02)
    k.box("Base", (4.0, 0.66, 0.2), (0, 0, 4.84), STONE_L, bevel=0.04)
    k.box("Base", (4.0, 0.7, 0.07), (0, 0, 4.965), GOLD, bevel=0.015)
    k.prism("Base", [(-0.3, 0.34), (0.3, 0.34), (0.3, -0.06), (0, -0.4), (-0.3, -0.06)], 0.06, (0, -0.31, 4.25), TEAL, bevel=0.012)
    k.box("Base", (0.13, 0.03, 0.34), (0, -0.35, 4.28), GOLD, bevel=0.01)
    for name, sx in (("DoorL", -1), ("DoorR", 1)):
        cx = sx * 0.75
        k.planks(name, 1.46, 3.36, 0.14, (cx, 0, 0.05), WOOD, 4)
        for z in (0.55, 1.75, 2.95):
            k.box(name, (1.46, 0.2, 0.14), (cx, 0, z), IRON, bevel=0.02)
            k.rivets(name, [(cx + dx, s * 0.105, z) for dx in (-0.5, 0, 0.5) for s in (-1, 1)], 0.04, IRON_L)
        k.ring(name, 0.11, 0.022, (sx * 0.2, -0.1, 1.75), BRASS, rot=(90, 0, 0), segs=10)
        k.pivot(name, name, (sx * 1.5, 0, 0))
    for x in (-1.75, 1.75):
        k.box("Up2", (0.62, 0.78, 0.14), (x, 0, 1.2), IRON, bevel=0.02)
        k.box("Up2", (0.62, 0.78, 0.14), (x, 0, 2.9), IRON, bevel=0.02)
        k.cyl("Up3", 0.09, 0.0, 0.34, (x, 0, 5.0), GOLD, segs=6)
        k.crystal("Up3", 0.1, 0.36, (x, -0.42, 2.0), CYAN)
    return k


def sentrycannon():
    k = Kit("def_sentrycannon", 14, 2.6)
    k.box("Base", (1.7, 1.7, 0.36), (0, 0, 0.18), STONE_D, bevel=0.06)
    k.box("Base", (1.3, 1.3, 0.3), (0, 0, 0.5), STONE, bevel=0.05)
    for x in (-0.46, 0.46):
        k.prism("Base", [(-0.5, 0), (0.5, 0), (0.3, 1.25), (-0.3, 1.25)], 0.16, (x, 0, 0.64), WOOD, rot=(0, 0, 90), bevel=0.02)
        k.box("Base", (0.2, 1.02, 0.08), (x, 0, 1.0), IRON, bevel=0.015)
    k.cyl("Base", 0.1, 0.1, 1.12, (-0.56, 0, 1.9), IRON_L, rot=(0, 90, 0), segs=8)
    for x, y in ((0.55, -0.45), (0.75, -0.3), (0.6, -0.15)):
        k.ball("Base", 0.16, (x, y, 0.8), IRON_D)
    k.cyl("Barrel", 0.27, 0.2, 2.3, (0, -0.75, 1.9), IRON, rot=(-90, 0, 0), segs=10)
    k.cyl("Barrel", 0.3, 0.3, 0.16, (0, -0.8, 1.9), IRON_D, rot=(-90, 0, 0), segs=10)
    k.cyl("Barrel", 0.25, 0.25, 0.12, (0, 0.2, 1.9), BRASS, rot=(-90, 0, 0), segs=10)
    k.cyl("Barrel", 0.24, 0.24, 0.16, (0, 1.42, 1.9), IRON_D, rot=(-90, 0, 0), segs=10)
    k.ball("Barrel", 0.2, (0, -0.86, 1.9), IRON_D)
    k.pivot("Barrel", "Turret", (0, 0, 1.9))
    k.cyl("Up2Barrel", 0.26, 0.26, 0.1, (0, 0.8, 1.9), BRASS, rot=(-90, 0, 0), segs=10)
    k.box("Up2Barrel", (0.5, 0.06, 0.7), (0, -0.2, 2.1), IRON_L, rot=(-12, 0, 0), bevel=0.02)
    k.pivot("Up2Barrel", "Turret", (0, 0, 1.9))
    k.ring("Up3Barrel", 0.3, 0.03, (0, 1.5, 1.9), GOLD, rot=(90, 0, 0), segs=12)
    k.crystal("Up3Barrel", 0.07, 0.26, (0, -0.2, 2.16), CYAN)
    k.pivot("Up3Barrel", "Turret", (0, 0, 1.9))
    return k


def crossbow(k, group, pivot, scale=1.0, color=WOOD):
    """Crossbow aiming +Y with its trunnion at pivot."""
    px, py, pz = pivot
    s = scale
    k.box(group, (0.2 * s, 1.9 * s, 0.2 * s), (px, py + 0.1 * s, pz), color, bevel=0.03)
    k.box(group, (0.07 * s, 1.5 * s, 0.05 * s), (px, py + 0.25 * s, pz + 0.12 * s), IRON_L, bevel=0.01)
    for sx in (-1, 1):
        k.beam(group, (px, py + 0.85 * s, pz), (px + sx * 0.62 * s, py + 0.7 * s, pz), 0.11 * s, WOOD_L)
        k.beam(group, (px + sx * 0.62 * s, py + 0.7 * s, pz), (px + sx * 0.98 * s, py + 0.38 * s, pz), 0.085 * s, WOOD_L)
        k.beam(group, (px + sx * 0.98 * s, py + 0.38 * s, pz), (px, py - 0.25 * s, pz + 0.03 * s), 0.022 * s, ROPE, bevel=0)
    k.box(group, (0.3 * s, 0.16 * s, 0.26 * s), (px, py + 0.84 * s, pz), IRON, bevel=0.02)
    k.cyl(group, 0.035 * s, 0.035 * s, 1.3 * s, (px, py - 0.2 * s, pz + 0.16 * s), WOOD_L, rot=(-90, 0, 0), segs=6)
    k.cyl(group, 0.07 * s, 0.0, 0.26 * s, (px, py + 1.1 * s, pz + 0.16 * s), IRON_L, rot=(-90, 0, 0), segs=6)
    k.box(group, (0.34 * s, 0.24 * s, 0.24 * s), (px, py - 0.72 * s, pz - 0.02 * s), WOOD_D, bevel=0.03)
    k.pivot(group, "Turret", pivot)


def watchtower():
    k = Kit("def_watchtower", 21, 4.2)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box("Base", (0.5, 0.5, 0.3), (sx * 0.86, sy * 0.86, 0.15), STONE_D, bevel=0.05)
            k.beam("Base", (sx * 0.86, sy * 0.86, 0.25), (sx * 0.72, sy * 0.72, 2.4), 0.2, WOOD)
    for a, b in (((-0.84, -0.84), (0.74, -0.74)), ((0.84, 0.84), (-0.74, 0.74)), ((-0.84, 0.84), (-0.74, -0.74)), ((0.84, -0.84), (0.74, 0.74))):
        k.beam("Base", (a[0], a[1], 0.4), (b[0], b[1], 2.2), 0.1, WOOD_D)
    k.planks("Base", 2.1, 2.1, 0.14, (0, -1.05, 2.42), WOOD_L, 7, rot=(-90, 0, 0))
    k.box("Base", (2.2, 2.2, 0.1), (0, 0, 2.32), WOOD_D, bevel=0.02)
    for sx in (-1, 1):
        k.box("Base", (0.1, 2.1, 0.42), (sx * 1.0, 0, 2.74), WOOD, bevel=0.02)
        k.box("Base", (0.14, 0.14, 0.62), (sx * 1.0, -1.0, 2.8), WOOD_D, bevel=0.02)
        k.box("Base", (0.14, 0.14, 0.62), (sx * 1.0, 1.0, 2.8), WOOD_D, bevel=0.02)
    k.box("Base", (2.1, 0.1, 0.42), (0, -1.0, 2.74), WOOD, bevel=0.02)
    for i in range(6):                                                              # ladder up the back
        k.box("Base", (0.46, 0.05, 0.05), (0, -1.12, 0.35 + i * 0.36), WOOD_L, bevel=0.01)
    for x in (-0.23, 0.23):
        k.beam("Base", (x, -1.2, 0.05), (x, -1.06, 2.4), 0.06, WOOD_D)
    k.banner("Base", 0.42, 0.7, (1.07, 0.5, 2.9), TEAL, rot=(0, 0, 90))
    crossbow(k, "Bow", (0, 0, 3.05), 0.92)
    k.box("Base", (0.3, 0.3, 0.5), (0, 0, 2.72), WOOD_D, bevel=0.04)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box("Up2", (0.3, 0.3, 0.16), (sx * 0.78, sy * 0.78, 1.3), IRON, bevel=0.02)
            k.box("Up2", (0.2, 0.2, 0.2), (sx * 1.0, sy * 1.0, 3.14), IRON, bevel=0.03)
    for x in (-0.6, 0.0, 0.6):
        k.prism("Up2", [(-0.2, 0.24), (0.2, 0.24), (0.2, -0.05), (0, -0.26), (-0.2, -0.05)], 0.05, (x, 1.06, 2.74), IRON_L, bevel=0.012)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.beam("Up3", (sx * 1.0, sy * 1.0, 3.1), (sx * 0.9, sy * 0.9, 4.0), 0.1, WOOD_D)
    k.roof("Up3", 2.0, 2.0, 0.75, (0, 0, 4.0), TEAL, overhang=0.2)
    k.cyl("Up3", 0.05, 0.0, 0.4, (0, 0, 4.72), GOLD, segs=6)
    k.crystal("Up3", 0.07, 0.24, (0, 1.12, 3.2), CYAN)
    return k


def barricade():
    k = Kit("def_barricade", 22, 1.8)
    k.box("Base", (3.5, 0.5, 0.14), (0, 0, 0.07), STONE_D, bevel=0.03)
    for i in range(8):
        x = -1.54 + i * 0.44; h = 1.05 + (i * 37 % 5) * 0.06
        k.cyl("Base", 0.2, 0.18, h, (x, 0, 0.08), WOOD if i % 2 else WOOD_D, segs=7)
        k.cyl("Base", 0.18, 0.0, 0.36, (x, 0, 0.08 + h), WOOD_L, segs=7)
    for z in (0.45, 0.95):
        k.box("Base", (3.52, 0.07, 0.1), (0, 0.2, z), ROPE, bevel=0.02)
        k.box("Base", (3.52, 0.07, 0.1), (0, -0.2, z), ROPE, bevel=0.02)
    for x in (-1.3, -0.45, 0.45, 1.3):                                              # outward stakes
        k.cyl("Base", 0.07, 0.0, 0.95, (x, 0.18, 0.5), WOOD_L, rot=(-62, 0, 0), segs=6)
    for x in (-1.75, 1.75):
        k.box("Base", (0.3, 0.46, 0.3), (x * 0.97, 0, 0.2), STONE, bevel=0.05)
    for i in range(8):
        x = -1.54 + i * 0.44; h = 1.05 + (i * 37 % 5) * 0.06
        k.cyl("Up2", 0.2, 0.02, 0.4, (x, 0, 0.07 + h), IRON, segs=7)
    k.box("Up2", (3.56, 0.52, 0.12), (0, 0, 0.7), IRON, bevel=0.02)
    k.rivets("Up2", [(-1.54 + i * 0.44, s * 0.27, 0.7) for i in range(8) for s in (-1, 1)], 0.04, IRON_L)
    for x in (-0.88, 0.88):
        k.prism("Up3", [(-0.32, 0.36), (0.32, 0.36), (0.32, -0.1), (0, -0.42), (-0.32, -0.1)], 0.07, (x, 0.3, 0.72), IRON_L, bevel=0.015)
        k.cyl("Up3", 0.07, 0.0, 0.3, (x, 0.34, 0.74), GOLD, rot=(-90, 0, 0), segs=6)
    for x in (-1.75, 0, 1.75):
        k.crystal("Up3", 0.08, 0.3, (x * 0.94, 0, 1.3), CYAN)
    return k


def ballista():
    k = Kit("def_ballista", 23, 2.2)
    k.cyl("Base", 0.78, 0.7, 0.16, (0, 0, 0.0), STONE_D, segs=10)
    for sx in (-1, 1):
        k.ring("Base", 0.36, 0.07, (sx * 0.62, -0.1, 0.42), WOOD_D, rot=(0, 90, 0), segs=12)
        k.cyl("Base", 0.09, 0.09, 0.12, (sx * 0.56, -0.1, 0.42), IRON, rot=(0, sx * 90, 0), segs=8)
        for a in range(4):
            ang = a * math.pi / 4
            k.beam("Base", (sx * 0.62, -0.1 - math.cos(ang) * 0.33, 0.42 - math.sin(ang) * 0.33), (sx * 0.62, -0.1 + math.cos(ang) * 0.33, 0.42 + math.sin(ang) * 0.33), 0.05, WOOD)
        k.beam("Base", (sx * 0.34, -0.5, 0.42), (sx * 0.2, 0.1, 1.0), 0.14, WOOD)
        k.beam("Base", (sx * 0.34, 0.5, 0.3), (sx * 0.2, 0.1, 1.0), 0.12, WOOD_D)
    k.box("Base", (1.3, 0.14, 0.14), (0, -0.1, 0.42), WOOD_D, bevel=0.02)
    k.beam("Base", (0, -0.3, 0.42), (0, -1.05, 0.1), 0.14, WOOD)
    k.cyl("Base", 0.2, 0.24, 0.2, (0, 0.1, 0.98), IRON, segs=10)
    crossbow(k, "Bow", (0, 0.1, 1.3), 1.25, WOOD_D)
    k.cyl("Bow", 0.11, 0.11, 0.5, (-0.25, -0.75, 1.3), IRON, rot=(0, 90, 0), segs=8)
    for sx in (-1, 1):
        k.box("Up2Bow", (0.5, 0.06, 0.62), (sx * 0.52, 0.72, 1.36), IRON_L, rot=(0, 0, -sx * 18), bevel=0.02)
        k.box("Up2Bow", (0.14, 0.2, 0.14), (sx * 1.18, 0.6, 1.3), IRON, bevel=0.02)
    k.pivot("Up2Bow", "Turret", (0, 0.1, 1.3))
    k.ring("Up3Bow", 0.16, 0.022, (0, 0.5, 1.62), GOLD, rot=(90, 0, 0), segs=10)
    k.box("Up3Bow", (0.03, 0.03, 0.2), (0, 0.5, 1.52), GOLD, bevel=0)
    k.cyl("Up3Bow", 0.035, 0.035, 1.5, (0.12, -0.3, 1.52), CYAN, rot=(-90, 0, 0), segs=6)
    k.cyl("Up3Bow", 0.035, 0.035, 1.5, (-0.12, -0.3, 1.52), CYAN, rot=(-90, 0, 0), segs=6)
    k.pivot("Up3Bow", "Turret", (0, 0.1, 1.3))
    return k


def mender():
    k = Kit("def_mender", 24, 2.4)
    k.cyl("Base", 0.85, 0.78, 0.2, (0, 0, 0), STONE_D, segs=8)
    k.cyl("Base", 0.66, 0.6, 0.26, (0, 0, 0.2), STONE, segs=8)
    k.cyl("Base", 0.5, 0.56, 0.16, (0, 0, 0.46), STONE_L, segs=8)
    k.cyl("Base", 0.44, 0.44, 0.05, (0, 0, 0.6), "#3fb6bf", segs=8)
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        x, y = math.cos(a), math.sin(a)
        k.beam("Base", (x * 0.56, y * 0.56, 0.5), (x * 0.66, y * 0.66, 1.25), 0.1, GOLD)
        k.beam("Base", (x * 0.66, y * 0.66, 1.25), (x * 0.36, y * 0.36, 1.72), 0.085, GOLD)
        k.ball("Base", 0.07, (x * 0.36, y * 0.36, 1.74), BRASS)
    k.crystal("Base", 0.2, 0.9, (0, 0, 1.0), CYAN)
    k.crystal("Base", 0.2, 0.34, (0, 0, 1.0), CYAN, rot=(180, 0, 0))
    for i in range(4):
        a = i * math.tau / 4
        k.prism("Base", [(0, 0.1), (0.07, 0), (0, -0.1), (-0.07, 0)], 0.04, (math.cos(a) * 0.67, math.sin(a) * 0.67, 0.34), CYAN, rot=(0, 0, math.degrees(a) + 90))
    for i in range(4):
        a = i * math.tau / 4
        k.crystal("Up2", 0.08, 0.36, (math.cos(a) * 0.72, math.sin(a) * 0.72, 0.2), "#9af0e0")
        k.cyl("Up2", 0.12, 0.16, 0.1, (math.cos(a) * 0.72, math.sin(a) * 0.72, 0.12), IRON, segs=6)
    k.ring("Up3", 0.6, 0.04, (0, 0, 1.45), GOLD, segs=16)
    k.ring("Up3", 0.46, 0.03, (0, 0, 1.45), GOLD, rot=(90, 0, 0), segs=16)
    for i in range(3):
        a = i * math.tau / 3
        k.ball("Up3", 0.08, (math.cos(a) * 0.6, math.sin(a) * 0.6, 1.45), PURPLE)
    return k


def metalwall():
    k = Kit("def_metalwall", 25, 2.4)
    k.box("Base", (2.8, 0.52, 0.22), (0, 0, 0.11), STONE_D, bevel=0.04)
    for x in (-1.26, 1.26):
        k.box("Base", (0.26, 0.42, 2.0), (x, 0, 1.2), IRON_D, bevel=0.03)
        k.cyl("Base", 0.16, 0.0, 0.24, (x, 0, 2.2), IRON_L, segs=4)
    for i in range(4):
        x = -0.87 + i * 0.58
        k.box("Base", (0.56, 0.2, 1.74), (x, 0, 1.1), IRON if i % 2 else "#566371", bevel=0.025)
        k.rivets("Base", [(x + dx, s * 0.11, z) for dx in (-0.2, 0.2) for z in (0.42, 1.78) for s in (-1, 1)], 0.035, IRON_L)
    for z in (0.62, 1.58):
        k.box("Base", (2.5, 0.26, 0.1), (0, 0, z), IRON_D, bevel=0.015)
    k.box("Base", (2.5, 0.22, 0.08), (0, 0, 1.1), TEAL, bevel=0.01)
    for i in range(7):
        k.cyl("Up2", 0.07, 0.0, 0.3, (-1.02 + i * 0.34, 0, 1.97), IRON_L, segs=5)
    for x in (-0.58, 0.58):
        k.box("Up2", (0.5, 0.3, 0.5), (x, 0, 1.1), IRON_L, bevel=0.04)
    for x in (-0.58, 0.58):
        k.prism("Up3", [(0, 0.17), (0.12, 0), (0, -0.17), (-0.12, 0)], 0.34, (x, 0, 1.1), CYAN)
    for x in (-1.26, 1.26):
        k.box("Up3", (0.32, 0.48, 0.1), (x, 0, 2.2), GOLD, bevel=0.02)
    return k


def stormspire():
    k = Kit("def_stormspire", 26, 3.4)
    k.cyl("Base", 0.84, 0.76, 0.22, (0, 0, 0), STONE_D, segs=8)
    k.cyl("Base", 0.6, 0.5, 0.3, (0, 0, 0.22), STONE, segs=8)
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        k.beam("Base", (math.cos(a) * 0.46, math.sin(a) * 0.46, 0.5), (math.cos(a) * 0.14, math.sin(a) * 0.14, 2.3), 0.09, IRON)
    k.cyl("Base", 0.1, 0.07, 2.0, (0, 0, 0.5), IRON_D, segs=6)
    for z, r in ((0.95, 0.36), (1.4, 0.3), (1.85, 0.24)):
        k.ring("Base", r, 0.045, (0, 0, z), COPPER, segs=12)
    k.cyl("Base", 0.2, 0.26, 0.14, (0, 0, 2.3), BRASS, segs=8)
    k.ball("Base", 0.26, (0, 0, 2.68), CYAN)
    for i in range(3):
        a = i * math.tau / 3
        k.beam("Base", (math.cos(a) * 0.2, math.sin(a) * 0.2, 2.42), (math.cos(a) * 0.36, math.sin(a) * 0.36, 2.86), 0.045, BRASS)
        k.cyl("Base", 0.035, 0.0, 0.2, (math.cos(a) * 0.36, math.sin(a) * 0.36, 2.86), BRASS, segs=5)
    for i in range(4):
        a = i * math.tau / 4
        k.cyl("Up2", 0.05, 0.03, 1.0, (math.cos(a) * 0.72, math.sin(a) * 0.72, 0.2), IRON_L, segs=6)
        k.ball("Up2", 0.07, (math.cos(a) * 0.72, math.sin(a) * 0.72, 1.24), CYAN)
    k.ring("Up2", 0.4, 0.035, (0, 0, 0.72), COPPER, segs=12)
    k.ring("Up3", 0.44, 0.03, (0, 0, 2.68), GOLD, rot=(64, 0, 0), segs=14)
    k.ring("Up3", 0.44, 0.03, (0, 0, 2.68), GOLD, rot=(64, 0, 90), segs=14)
    k.crystal("Up3", 0.08, 0.5, (0, 0, 2.92), "#e9fbff")
    return k


def frostmortar():
    k = Kit("def_frostmortar", 27, 2.2)
    k.cyl("Base", 0.86, 0.8, 0.2, (0, 0, 0), STONE_D, segs=8)
    for sx in (-1, 1):
        k.prism("Base", [(-0.62, 0), (0.62, 0), (0.42, 0.72), (-0.3, 0.72)], 0.18, (sx * 0.44, 0, 0.2), WOOD, rot=(0, 0, 90), bevel=0.02)
        k.box("Base", (0.22, 1.2, 0.08), (sx * 0.44, 0, 0.3), IRON, bevel=0.015)
    k.cyl("Base", 0.09, 0.09, 1.06, (-0.53, 0, 0.8), IRON_L, rot=(0, 90, 0), segs=8)
    for x, y in ((0.64, -0.36), (0.72, -0.08), (0.56, -0.2)):
        k.ball("Base", 0.14, (x, y, 0.33), ICE)
    tilt = -42
    k.cyl("Barrel", 0.36, 0.42, 0.95, (0, 0, 0.8), IRON, rot=(tilt, 0, 0), segs=10)
    k.cyl("Barrel", 0.45, 0.45, 0.12, (0, 0.56, 1.42), IRON_D, rot=(tilt, 0, 0), segs=10)
    k.cyl("Barrel", 0.39, 0.39, 0.1, (0, 0.2, 1.02), BRASS, rot=(tilt, 0, 0), segs=10)
    k.cyl("Barrel", 0.33, 0.33, 0.03, (0, 0.63, 1.5), "#9fdff0", rot=(tilt, 0, 0), segs=10)
    k.ball("Barrel", 0.3, (0, -0.08, 0.72), IRON_D)
    k.pivot("Barrel", "Turret", (0, 0, 0.8))
    for i in range(5):
        a = i * math.tau / 5 + 0.4
        k.crystal("Up2", 0.09, 0.42 + (i % 2) * 0.16, (math.cos(a) * 0.74, math.sin(a) * 0.74, 0.18), ICE, rot=(math.sin(a) * 16, -math.cos(a) * 16, 0))
    k.cyl("Up2Barrel", 0.41, 0.43, 0.1, (0, 0.38, 1.22), IRON_L, rot=(tilt, 0, 0), segs=10)
    k.pivot("Up2Barrel", "Turret", (0, 0, 0.8))
    k.ring("Up3Barrel", 0.47, 0.035, (0, 0.6, 1.47), GOLD, rot=(tilt, 0, 0), segs=14)
    for i in range(4):
        a = i * math.tau / 4
        k.crystal("Up3Barrel", 0.06, 0.34, (math.cos(a) * 0.46, 0.58 + math.sin(a) * 0.3, 1.45 + math.sin(a) * 0.34), "#e9fbff", rot=(tilt, 0, 0))
    k.pivot("Up3Barrel", "Turret", (0, 0, 0.8))
    return k


def embercoil():
    k = Kit("def_embercoil", 28, 2.6)
    k.cyl("Base", 0.86, 0.8, 0.22, (0, 0, 0), STONE_D, segs=8)
    for i in range(8):
        a = i * math.tau / 8
        k.box("Base", (0.4, 0.3, 0.34), (math.cos(a) * 0.62, math.sin(a) * 0.62, 0.38), STONE, rot=(0, 0, math.degrees(a) + 90), bevel=0.04)
    k.cyl("Base", 0.34, 0.5, 0.5, (0, 0, 0.5), IRON_D, segs=10)
    k.cyl("Base", 0.52, 0.52, 0.08, (0, 0, 0.98), IRON, segs=10)
    for x, y, r in ((0, 0, 0.2), (0.2, 0.12, 0.15), (-0.18, 0.14, 0.15), (0.05, -0.22, 0.15), (-0.2, -0.12, 0.13)):
        k.ball("Base", r, (x, y, 1.02), ORANGE if r < 0.18 else EMBER)
    for i, (z, r) in enumerate(((1.2, 0.36), (1.42, 0.31), (1.64, 0.26), (1.86, 0.21), (2.06, 0.16))):
        k.ring("Base", r, 0.04, (0, 0, z), COPPER, rot=(8 if i % 2 else -8, 0, 0), segs=12)
    for i in range(3):
        a = i * math.tau / 3
        k.beam("Base", (math.cos(a) * 0.46, math.sin(a) * 0.46, 1.0), (math.cos(a) * 0.14, math.sin(a) * 0.14, 2.2), 0.055, IRON)
    k.cyl("Base", 0.1, 0.0, 0.4, (0, 0, 2.18), EMBER, segs=6)
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        k.cyl("Up2", 0.12, 0.16, 0.26, (math.cos(a) * 0.76, math.sin(a) * 0.76, 0.2), IRON, segs=6)
        k.cyl("Up2", 0.09, 0.0, 0.36, (math.cos(a) * 0.76, math.sin(a) * 0.76, 0.46), ORANGE, segs=5)
    k.ring("Up2", 0.56, 0.04, (0, 0, 0.9), IRON_L, segs=12)
    k.ring("Up3", 0.42, 0.035, (0, 0, 2.26), GOLD, segs=12)
    for i in range(5):
        a = i * math.tau / 5
        k.cyl("Up3", 0.07, 0.0, 0.5, (math.cos(a) * 0.3, math.sin(a) * 0.3, 2.2), EMBER, rot=(-math.sin(a) * 18, math.cos(a) * 18, 0), segs=5)
    return k


def gravitywell():
    k = Kit("def_gravitywell", 29, 2.8)
    k.cyl("Base", 0.86, 0.8, 0.2, (0, 0, 0), STONE_D, segs=8)
    k.cyl("Base", 0.62, 0.56, 0.18, (0, 0, 0.2), "#4a4458", segs=8)
    k.cyl("Base", 0.42, 0.42, 0.04, (0, 0, 0.38), PURPLE, segs=8)
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        x, y = math.cos(a), math.sin(a)
        k.prism("Base", [(-0.13, 0), (0.13, 0), (0.07, 1.25), (-0.07, 1.25)], 0.2, (x * 0.68, y * 0.68, 0.2), "#3a3548", rot=(-y * 14, x * 14, math.degrees(a) + 90), bevel=0.02)
    k.ball("Base", 0.34, (0, 0, 1.5), "#3b2a63", subdiv=2)
    k.ball("Base", 0.2, (0, 0, 1.5), PURPLE)
    for rot in ((0, 0, 0), (70, 0, 0), (70, 0, 90)):
        k.ring("Base", 0.56, 0.035, (0, 0, 1.5), GOLD, rot=rot, segs=16)
    for i in range(5):
        a = i * math.tau / 5 + 0.3
        k.ball("Up2", 0.09 + (i % 2) * 0.04, (math.cos(a) * 0.86, math.sin(a) * 0.86, 0.9 + (i % 3) * 0.32), "#6a5a8c", scale=(1, 0.7, 1.2))
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        k.box("Up2", (0.3, 0.3, 0.12), (math.cos(a) * 0.68, math.sin(a) * 0.68, 0.7), IRON, rot=(0, 0, math.degrees(a)), bevel=0.02)
    k.ring("Up3", 0.76, 0.035, (0, 0, 1.5), "#e9d6ff", rot=(20, 20, 0), segs=18)
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        k.crystal("Up3", 0.08, 0.3, (math.cos(a) * 0.5, math.sin(a) * 0.5, 1.5), PURPLE)
    return k


def sunlance():
    k = Kit("def_sunlance", 30, 3.4)
    k.cyl("Base", 0.86, 0.8, 0.22, (0, 0, 0), STONE_D, segs=8)
    k.cyl("Base", 0.6, 0.52, 0.26, (0, 0, 0.22), STONE, segs=8)
    for i in range(3):
        a = i * math.tau / 3 + math.pi / 2
        k.beam("Base", (math.cos(a) * 0.5, math.sin(a) * 0.5, 0.46), (math.cos(a) * 0.12, math.sin(a) * 0.12, 2.0), 0.1, BRASS)
        k.prism("Base", [(0, 0.16), (0.11, 0), (0, -0.16), (-0.11, 0)], 0.05, (math.cos(a) * 0.62, math.sin(a) * 0.62, 0.35), GOLD, rot=(0, 0, math.degrees(a) + 90))
    k.cyl("Base", 0.09, 0.07, 1.7, (0, 0, 0.46), IRON_D, segs=6)
    k.cyl("Base", 0.22, 0.26, 0.16, (0, 0, 2.0), BRASS, segs=8)
    piv = (0, 0, 2.3)
    k.cyl("Lens", 0.2, 0.26, 1.3, (0, -0.45, 2.3), BRASS, rot=(-90, 0, 0), segs=10)
    k.cyl("Lens", 0.42, 0.42, 0.08, (0, 0.85, 2.3), GOLD, rot=(-90, 0, 0), segs=12)
    k.cyl("Lens", 0.36, 0.36, 0.05, (0, 0.9, 2.3), "#fff2b8", rot=(-90, 0, 0), segs=12)
    k.cyl("Lens", 0.28, 0.28, 0.06, (0, 0.2, 2.3), IRON, rot=(-90, 0, 0), segs=10)
    k.ball("Lens", 0.2, (0, -0.6, 2.3), IRON_D)
    for sx in (-1, 1):
        k.box("Lens", (0.08, 0.34, 0.34), (sx * 0.28, 0, 2.3), IRON, bevel=0.02)
    k.pivot("Lens", "Turret", piv)
    for i in range(6):
        a = i * math.tau / 6
        k.prism("Up2Lens", [(-0.12, 0), (0.12, 0), (0.07, 0.32), (-0.07, 0.32)], 0.03, (math.cos(a) * 0.44, 0.88, 2.3 + math.sin(a) * 0.44), GOLD, rot=(18, math.degrees(-a) + 90, 0))
    k.pivot("Up2Lens", "Turret", piv)
    k.ring("Up3Lens", 0.6, 0.03, (0, 0.5, 2.3), "#fff2b8", rot=(90, 0, 0), segs=18)
    k.cyl("Up3Lens", 0.3, 0.3, 0.04, (0, 0.52, 2.3), "#ffe08a", rot=(-90, 0, 0), segs=12)
    for sx in (-1, 1):
        k.crystal("Up3Lens", 0.06, 0.3, (sx * 0.3, -0.3, 2.5), EMBER)
    k.pivot("Up3Lens", "Turret", piv)
    return k


DESIGNS = {"castlewall": castlewall, "castlewindow": castlewindow, "castlegate": castlegate, "sentrycannon": sentrycannon,
           "watchtower": watchtower, "barricade": barricade, "ballista": ballista, "mender": mender, "metalwall": metalwall,
           "stormspire": stormspire, "frostmortar": frostmortar, "embercoil": embercoil, "gravitywell": gravitywell, "sunlance": sunlance}


def build(kind, out=None):
    rigkit.reset()
    kit = DESIGNS[kind]()
    objects = kit.build()
    if out:
        span = max(kit.height * 1.25, 4.6)
        for stage in (1, 2, 3):
            for o in objects:
                n = o.name
                o.hide_render = (n.startswith("Up2") and stage < 2) or (n.startswith("Up3") and stage < 3)
            rigkit.render_views(os.path.join(out, "%s_s%d" % (kind, stage)), views=("quarter",), target=(0, 0, kit.height * 0.48), distance=span, res=420, lift=3.0)
        for o in objects:
            o.hide_render = False
    path = rigkit.export(objects, "def_" + kind)
    rigkit.save_blend("def_" + kind)
    print("BUILT", kind, os.path.getsize(path), kit.triangles(), "tris", sorted(kit.groups))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = None
    if "--preview" in args:
        i = args.index("--preview"); out = args[i + 1]; args = args[:i] + args[i + 2:]
    for kind in (args or list(DESIGNS)):
        build(kind, out)
