# blender -b -P build_pieces.py -- [name ...] [--preview out_dir]
# Fort 29 building pieces: foundations, floors, posts, stairs, timber and stone walls, roofs.
# Every piece fits the 4 m lattice and the 5 m storey used by scripts/fort_pieces.gd.
#   edge pieces  : run along X, origin at the bottom centre, outer face is -Y
#   deck pieces  : centred, top surface at z = 0
#   tile pieces  : centred on the tile, floor at z = 0; +Y is "forward" (stairs climb, slopes rise)
#   corner pieces: origin at the bottom
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, rigkit
from props import Kit

STONE, STONE_D, STONE_L = "#8b919c", "#666c78", "#a7adb6"
WOOD, WOOD_D, WOOD_L = "#8c5f3c", "#5f3f29", "#b0835a"
PLASTER, PLASTER_D = "#d9cba8", "#bfae88"
IRON, IRON_L, IRON_D = "#4c5866", "#7a8894", "#343d48"
GOLD, TEAL = "#d9aa4c", "#2f8f8a"
STRAW, STRAW_D, STRAW_L = "#b48d3c", "#8c6c30", "#c7a352"
SLATE, SLATE_D, SLATE_L = "#53677a", "#3f4f5f", "#6c8194"
ORANGE, EMBER, DARK, MORTAR = "#f08a3c", "#ffd36a", "#23272e", "#4a505a"
H = 5.0
PITCH = math.degrees(math.atan2(3.0, 4.0))


# ------------------------------------------------------------------ frame
def foundation():
    k = Kit("piece_foundation", 101, 1.2)
    k.box("Base", (5.44, 5.44, 0.62), (0, 0, -0.31), STONE_D, bevel=0.03, taper=(4.0 / 5.44, 4.0 / 5.44))
    k.box("Base", (5.44, 5.44, 1.0), (0, 0, -1.12), STONE_D, bevel=0)
    for i in range(4):
        for j in range(4):
            k.box("Base", (0.95, 0.95, 0.1), (-1.5 + i, -1.5 + j, -0.045), STONE_L if (i + j) % 3 == 0 else STONE, bevel=0.025, jitter=0.08)
    for x in (-1.5, -0.5, 0.5, 1.5):               # skirt blocks so the batter reads as masonry
        for sgn in (-1, 1):
            k.box("Base", (0.9, 0.2, 0.3), (x, sgn * 2.36, -0.36), STONE, bevel=0.03, jitter=0.1)
            k.box("Base", (0.2, 0.9, 0.3), (sgn * 2.36, x, -0.36), STONE, bevel=0.03, jitter=0.1)
    return k


def woodfloor():
    k = Kit("piece_woodfloor", 102, 1.0)
    for i in range(8):
        k.box("Base", (4.0, 0.485, 0.12), (0, -1.75 + i * 0.5, -0.06), WOOD_L if i % 3 == 1 else WOOD, bevel=0.015, jitter=0.1)
    for x in (-1.7, 0, 1.7):
        k.box("Base", (0.24, 4.0, 0.28), (x, 0, -0.26), WOOD_D, bevel=0.02)
    return k


def stonefloor():
    k = Kit("piece_stonefloor", 103, 1.0)
    k.box("Base", (4.0, 4.0, 0.22), (0, 0, -0.2), STONE_D, bevel=0)
    for i in range(3):
        for j in range(3):
            k.box("Base", (1.3, 1.3, 0.12), (-1.333 + i * 1.333, -1.333 + j * 1.333, -0.055), STONE_L if (i * 2 + j) % 4 == 0 else STONE, bevel=0.03, jitter=0.08)
    for x in (-1.6, 1.6):
        k.box("Base", (0.3, 4.0, 0.2), (x, 0, -0.32), WOOD_D, bevel=0.02)
    return k


def woodpost():
    k = Kit("piece_woodpost", 104, H)
    k.box("Base", (0.62, 0.62, 0.22), (0, 0, 0.11), WOOD_D, bevel=0.03)
    k.box("Base", (0.4, 0.4, 4.6), (0, 0, 2.5), WOOD, bevel=0.03)
    k.box("Base", (0.62, 0.62, 0.22), (0, 0, 4.89), WOOD_D, bevel=0.03)
    for s in (-1, 1):
        k.beam("Base", (s * 0.2, 0, 4.2), (s * 0.62, 0, 4.78), 0.14, WOOD_L)
        k.beam("Base", (0, s * 0.2, 4.2), (0, s * 0.62, 4.78), 0.14, WOOD_L)
    for z in (1.2, 3.4):
        k.box("Base", (0.46, 0.46, 0.09), (0, 0, z), IRON, bevel=0.015)
    return k


def stonecolumn():
    k = Kit("piece_stonecolumn", 105, H)
    k.box("Base", (0.84, 0.84, 0.3), (0, 0, 0.15), STONE_D, bevel=0.04)
    k.box("Base", (0.66, 0.66, 0.16), (0, 0, 0.38), STONE_L, bevel=0.03)
    for i in range(5):
        k.cyl("Base", 0.29, 0.285, 0.8, (0, 0, 0.46 + i * 0.8), STONE if i % 2 else STONE_L, segs=10, jitter=0.07)
    k.box("Base", (0.66, 0.66, 0.16), (0, 0, 4.54), STONE_L, bevel=0.03)
    k.box("Base", (0.84, 0.84, 0.3), (0, 0, 4.85), STONE_D, bevel=0.04)
    k.cyl("Base", 0.31, 0.31, 0.07, (0, 0, 4.36), GOLD, segs=10)
    return k


def woodstairs():
    k = Kit("piece_woodstairs", 106, H)
    n = 16
    for s in (-1, 1):
        k.beam("Base", (s * 1.72, -2.0, 0.0), (s * 1.72, 6.0, 5.0), 0.3, WOOD_D, width=0.14)
        k.beam("Base", (s * 1.72, -1.7, 1.25), (s * 1.72, 5.9, 6.0), 0.1, WOOD_L, width=0.1)      # handrail
        for y, z in ((-1.7, 0.2), (0.9, 1.8), (3.4, 3.4), (5.9, 4.95)):
            k.box("Base", (0.12, 0.12, 1.06), (s * 1.72, y, z + 0.53), WOOD, bevel=0.015)
        for y in (2.0, 5.6):
            h = 5.0 * (y + 2.0) / 8.0
            k.box("Base", (0.22, 0.22, h), (s * 1.5, y, h * 0.5 - 0.1), WOOD_D, bevel=0.02)
    for i in range(n):
        y = -2.0 + 8.0 * (i + 0.5) / n
        z = 5.0 * (i + 1) / n
        k.box("Base", (3.36, 0.54, 0.1), (0, y, z - 0.05), WOOD_L if i % 2 else WOOD, bevel=0.015, jitter=0.08)
    return k


def stone_stairs_clean():
    k = Kit("piece_stonestairs", 107, H)
    n = 16
    for i in range(n):
        y = -2.0 + 8.0 * (i + 0.5) / n
        h = 5.0 * (i + 1) / n
        k.box("Base", (3.3, 0.5, 0.26), (0, y, h - 0.13), STONE_L if i % 2 else STONE, bevel=0.03, jitter=0.07)
    for s in (-1, 1):
        for j in range(8):                               # side walls and the fill under the steps
            y = -1.5 + j
            h = 5.0 * (j + 1) / 8
            k.box("Base", (0.3, 0.98, h + 0.62), (s * 1.65, y, (h + 0.62) * 0.5), STONE if j % 2 else STONE_D, bevel=0.03, jitter=0.08)
            k.box("Base", (0.38, 1.0, 0.1), (s * 1.65, y, h + 0.66), STONE_L, bevel=0.02)
    for j in range(8):
        y = -1.5 + j
        h = 5.0 * (j + 1) / 8 - 0.5
        if h > 0.1:
            k.box("Base", (3.0, 0.98, h), (0, y, h * 0.5), MORTAR, bevel=0, jitter=0.03)
    return k


def brazier():
    k = Kit("piece_brazier", 108, 1.6)
    k.cyl("Base", 0.46, 0.4, 0.2, (0, 0, 0), STONE_D, segs=8)
    k.cyl("Base", 0.3, 0.26, 0.16, (0, 0, 0.2), STONE, segs=8)
    for i in range(3):
        a = i * math.tau / 3
        k.beam("Base", (math.cos(a) * 0.22, math.sin(a) * 0.22, 0.34), (math.cos(a) * 0.36, math.sin(a) * 0.36, 0.98), 0.06, IRON)
    k.cyl("Base", 0.26, 0.5, 0.3, (0, 0, 0.92), IRON_D, segs=10)
    k.ring("Base", 0.5, 0.04, (0, 0, 1.22), IRON_L, segs=12, tube=4)
    for i in range(7):
        a = i * 2.4
        k.ball("Base", 0.13, (math.cos(a) * 0.22, math.sin(a) * 0.22, 1.2), "#7a2f1c" if i % 2 else ORANGE, subdiv=1)
    for a, r, h in ((0.3, 0.12, 0.62), (2.2, 0.16, 0.5), (4.3, 0.14, 0.42), (0, 0.0, 0.74)):
        k.cyl("Base", 0.12, 0.0, h, (math.cos(a) * r, math.sin(a) * r, 1.22), EMBER if h > 0.6 else ORANGE, segs=5, jitter=0.02)
    return k


def bannerpole():
    k = Kit("piece_bannerpole", 109, H)
    k.box("Base", (0.36, 0.36, 0.2), (0, 0, 0.1), WOOD_D, bevel=0.03)
    k.cyl("Base", 0.075, 0.06, 5.0, (0, 0, 0.2), WOOD, segs=6)
    k.ball("Base", 0.13, (0, 0, 5.28), GOLD, subdiv=1)
    k.beam("Base", (0, 0, 4.7), (0, -1.15, 4.7), 0.07, WOOD_D)
    k.banner("Base", 0.9, 2.3, (0, -0.62, 4.62), TEAL, rot=(0, 0, 90))
    k.prism("Base", [(0, 0.26), (0.2, 0), (0, -0.26), (-0.2, 0)], 0.045, (0, -0.62, 3.75), GOLD, rot=(0, 0, 90))
    return k


# ------------------------------------------------------------------ timber walls
def timber(k, panels, beams):
    """Plaster panels (x0, x1, z0, z1) set back between dark beams (a, b, thickness)."""
    for x0, x1, z0, z1 in panels:
        k.box("Base", (x1 - x0, 0.2, z1 - z0), ((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5), PLASTER, bevel=0.012, jitter=0.04)
    for a, b, t in beams:
        k.beam("Base", (a[0], 0, a[1]), (b[0], 0, b[1]), 0.32, WOOD_D if t > 0.3 else WOOD, width=t)


def frame(k):
    timber(k, [], [((-2, 0.17), (2, 0.17), 0.34), ((-2, 4.84), (2, 4.84), 0.32), ((-1.84, 0.3), (-1.84, 4.7), 0.32), ((1.84, 0.3), (1.84, 4.7), 0.32)])


def woodwall():
    k = Kit("piece_woodwall", 110, H)
    frame(k)
    timber(k, [(-1.7, -0.13, 0.33, 2.38), (0.13, 1.7, 0.33, 2.38), (-1.7, -0.13, 2.62, 4.7), (0.13, 1.7, 2.62, 4.7)],
           [((0, 0.3), (0, 4.7), 0.26), ((-1.7, 2.5), (1.7, 2.5), 0.24), ((-1.66, 2.66), (-0.16, 4.64), 0.2), ((1.66, 2.66), (0.16, 4.64), 0.2)])
    return k


def woodwindow():
    k = Kit("piece_woodwindow", 111, H)
    frame(k)
    timber(k, [(-1.7, -0.84, 0.33, 4.7), (0.84, 1.7, 0.33, 4.7), (-0.84, 0.84, 0.33, 1.4), (-0.84, 0.84, 3.5, 4.7)],
           [((-0.96, 0.3), (-0.96, 4.7), 0.24), ((0.96, 0.3), (0.96, 4.7), 0.24), ((-0.9, 1.5), (0.9, 1.5), 0.22), ((-0.9, 3.4), (0.9, 3.4), 0.22)])
    k.box("Base", (0.06, 0.08, 1.7), (0, 0, 2.45), WOOD_D, bevel=0.01)
    k.box("Base", (1.7, 0.08, 0.06), (0, 0, 2.45), WOOD_D, bevel=0.01)
    k.box("Base", (1.96, 0.5, 0.1), (0, -0.06, 1.42), WOOD_L, bevel=0.02)            # sill
    for s in (-1, 1):                                                              # shutters, outside
        k.planks("Base", 0.78, 1.74, 0.07, (s * 1.3, -0.2, 1.58), WOOD_L, 3)
        for z in (1.95, 2.95):
            k.box("Base", (0.8, 0.05, 0.09), (s * 1.3, -0.25, z), IRON, bevel=0.012)
    return k


def wooddoorway():
    k = Kit("piece_wooddoorway", 112, H)
    timber(k, [], [((-2, 0.17), (-1.2, 0.17), 0.34), ((1.2, 0.17), (2, 0.17), 0.34), ((-2, 4.84), (2, 4.84), 0.32), ((-1.84, 0.3), (-1.84, 4.7), 0.32), ((1.84, 0.3), (1.84, 4.7), 0.32)])
    timber(k, [(-1.7, -1.5, 0.33, 4.7), (1.5, 1.7, 0.33, 4.7), (-1.2, 1.2, 3.95, 4.7)],
           [((-1.36, 0.0), (-1.36, 4.7), 0.3), ((1.36, 0.0), (1.36, 4.7), 0.3), ((-1.5, 3.78), (1.5, 3.78), 0.32)])
    k.prism("Base", [(-1.2, 3.62), (-0.86, 3.62), (-1.2, 3.2)], 0.24, (0, 0, 0), WOOD)
    k.prism("Base", [(1.2, 3.62), (1.2, 3.2), (0.86, 3.62)], 0.24, (0, 0, 0), WOOD)
    return k


def leaf(k, width, height, color, band):
    """Door leaf hinged on its left edge; group Leaf hangs under the Door pivot."""
    k.planks("Leaf", width, height, 0.12, (0, 0, 0.04), color, 5)
    k.box("Leaf", (width - 0.06, 0.05, height - 0.06), (0, 0, 0.04 + height * 0.5), WOOD_D, bevel=0)
    for z in (0.55, height * 0.5, height - 0.5):
        k.box("Leaf", (width, 0.16, 0.14), (0, 0, z), band, bevel=0.02)
        k.rivets("Leaf", [(x, s * 0.09, z) for x in (-width * 0.38, 0, width * 0.38) for s in (-1, 1)], 0.04, IRON_L)
    for s in (-1, 1):
        k.ring("Leaf", 0.13, 0.025, (width * 0.34, s * 0.1, height * 0.46), IRON_L, rot=(90, 0, 0), segs=10, tube=4)
    k.pivot("Leaf", "Door", (-width * 0.5, 0, 0))


def wooddoor():
    k = wooddoorway()
    k.key = "piece_wooddoor"
    leaf(k, 2.36, 3.56, WOOD_L, IRON)
    return k


def woodrailing():
    k = Kit("piece_woodrailing", 114, 1.4)
    for x in (-1.88, 0, 1.88):
        k.box("Base", (0.2, 0.2, 1.25), (x, 0, 0.625), WOOD_D, bevel=0.02)
    k.box("Base", (4.0, 0.26, 0.12), (0, 0, 1.28), WOOD_L, bevel=0.02)
    k.box("Base", (3.9, 0.12, 0.1), (0, 0, 0.3), WOOD, bevel=0.015)
    for x0, x1 in ((-1.8, -0.1), (0.1, 1.8)):
        k.beam("Base", (x0, 0, 0.36), (x1, 0, 1.2), 0.08, WOOD)
        k.beam("Base", (x0, 0, 1.2), (x1, 0, 0.36), 0.08, WOOD)
    return k


GABLES = {"tri": [(-2, 0), (2, 0), (0, 1.5)], "half": [(-2, 0), (2, 0), (2, 3.0)],
          "pent": [(-2, 0), (2, 0), (2, 3.0), (0, 4.5), (-2, 3.0)], "rect": [(-2, 0), (2, 0), (2, 3.0), (-2, 3.0)]}


def woodgable(variant):
    k = Kit("piece_woodgable_" + variant, 115, 4.5)
    pts = GABLES[variant]
    k.prism("Base", pts, 0.2, (0, 0, 0), PLASTER)
    for a, b in zip(pts, pts[1:] + pts[:1]):
        k.beam("Base", (a[0], 0, a[1]), (b[0], 0, b[1]), 0.3, WOOD_D, width=0.26)
    top = max(z for _, z in pts)
    if variant in ("tri", "pent"):
        k.beam("Base", (0, 0, 0.1), (0, 0, top - 0.1), 0.26, WOOD, width=0.22)
    if variant == "half":
        k.beam("Base", (0.4, 0, 0.1), (0.4, 0, 1.7), 0.26, WOOD, width=0.2)
        k.beam("Base", (-1.5, 0, 0.1), (1.9, 0, 1.4), 0.22, WOOD, width=0.18)
    if variant in ("pent", "rect"):
        k.beam("Base", (-1.9, 0, 1.5), (1.9, 0, 1.5), 0.31, WOOD, width=0.2)
        for s in (-1, 1):
            k.beam("Base", (s * 1.0, 0, 0.1), (s * 1.0, 0, 2.9), 0.26, WOOD, width=0.2)
    return k


# ------------------------------------------------------------------ stone walls
def shell(k, skip=None):
    k.box("Base", (4.0, 0.62, 0.4), (0, 0, 0.2), STONE_D, bevel=0.05)
    k.stones("Base", 4.0, 4.38, 0.5, (0, 0, 0.4), STONE, rows=8, skip=skip, backing=skip is None)
    k.box("Base", (4.0, 0.6, 0.22), (0, 0, 4.89), STONE_L, bevel=0.04)


def stonewall():
    k = Kit("piece_stonewall", 120, H)
    shell(k)
    return k


def stoneslit():
    k = Kit("piece_stoneslit", 121, H)
    shell(k, skip=lambda x, z: abs(x) < 0.3 and 1.7 < z < 3.7)
    for x in (-1.2, 1.2):
        k.box("Base", (1.6, 0.36, 4.3), (x, 0, 2.55), MORTAR, bevel=0, jitter=0.02)
    k.box("Base", (0.8, 0.36, 1.3), (0, 0, 1.05), MORTAR, bevel=0, jitter=0.02)
    k.box("Base", (0.8, 0.36, 1.0), (0, 0, 4.2), MORTAR, bevel=0, jitter=0.02)
    for x in (-0.34, 0.34):
        k.box("Base", (0.3, 0.56, 2.0), (x, 0, 2.7), STONE_L, bevel=0.03, taper=(1.0, 1.0))
    k.box("Base", (0.98, 0.58, 0.2), (0, 0, 1.62), STONE_L, bevel=0.03)
    k.box("Base", (0.98, 0.58, 0.2), (0, 0, 3.8), STONE_L, bevel=0.03)
    k.box("Base", (0.1, 0.2, 1.9), (0, 0, 2.7), DARK, bevel=0)
    return k


def stonearch():
    k = Kit("piece_stonearch", 122, H)
    inside = lambda x, z: abs(x) < 1.36 and (z < 2.5 or x * x + (z - 2.4) ** 2 < 1.36 ** 2)
    k.box("Base", (0.8, 0.62, 0.4), (-1.6, 0, 0.2), STONE_D, bevel=0.05)
    k.box("Base", (0.8, 0.62, 0.4), (1.6, 0, 0.2), STONE_D, bevel=0.05)
    k.stones("Base", 4.0, 4.38, 0.5, (0, 0, 0.4), STONE, rows=8, skip=inside, backing=False)
    k.box("Base", (4.0, 0.6, 0.22), (0, 0, 4.89), STONE_L, bevel=0.04)
    for x in (-1.68, 1.68):
        k.box("Base", (0.62, 0.36, 4.4), (x, 0, 2.6), MORTAR, bevel=0, jitter=0.02)
    k.box("Base", (2.8, 0.36, 0.9), (0, 0, 4.3), MORTAR, bevel=0, jitter=0.02)
    for x in (-1.36, 1.36):                               # jambs
        for i in range(4):
            k.box("Base", (0.34, 0.58, 0.58), (x, 0, 0.3 + i * 0.6), STONE_L if i % 2 else STONE, bevel=0.03, jitter=0.06)
    n = 9
    for i in range(n):                                    # voussoirs
        a = math.pi * (i + 0.5) / n
        k.box("Base", (0.36, 0.58, 0.5), (math.cos(a) * 1.4, 0, 2.4 + math.sin(a) * 1.4), STONE_L if i != n // 2 else "#b9bfc8",
              rot=(0, 90 - math.degrees(a), 0), bevel=0.03, jitter=0.05)
    k.prism("Base", [(-0.2, 0.0), (0.2, 0.0), (0.28, 0.5), (-0.28, 0.5)], 0.64, (0, 0, 3.6), STONE_L, bevel=0.02)
    return k


def stonegate():
    k = stonearch()
    k.key = "piece_stonegate"
    leaf(k, 2.4, 3.62, WOOD, IRON_D)
    for z in (1.0, 2.6):
        k.box("Leaf", (0.5, 0.2, 0.1), (-0.95, 0, z), IRON_L, bevel=0.015)
    return k


def battlement():
    k = Kit("piece_battlement", 124, 1.7)
    k.stones("Base", 4.0, 0.76, 0.44, (0, 0, 0), STONE, rows=2, per_row=5)
    k.box("Base", (4.0, 0.52, 0.1), (0, 0, 0.8), STONE_L, bevel=0.025)
    for x in (-1.5, 0, 1.5):
        k.stones("Base", 0.96, 0.7, 0.44, (x, 0, 0.84), STONE, rows=2, per_row=2)
        k.box("Base", (1.04, 0.52, 0.1), (x, 0, 1.58), STONE_L, bevel=0.025)
    return k


def stonegable(variant):
    k = Kit("piece_stonegable_" + variant, 125, 4.5)
    pts = GABLES[variant]
    top = max(z for _, z in pts)

    def outside(x, z):
        if variant == "tri":
            return z > 1.5 - abs(x) * 0.75 - 0.1
        if variant == "half":
            return z > (x + 2) * 0.75 - 0.1
        if variant == "pent":
            return z > 3.0 + 1.5 - abs(x) * 0.75 - 0.1
        return False
    k.stones("Base", 4.0, top, 0.42, (0, 0, 0), STONE, rows=max(3, round(top / 0.5)), skip=outside, backing=False)
    k.prism("Base", [(x * 0.97, z * 0.97) for x, z in pts], 0.3, (0, 0, 0.02), MORTAR)
    for a, b in zip(pts[1:], pts[2:] + pts[:1]):          # coping along every edge but the base
        if a[1] == 0 and b[1] == 0:
            continue
        k.beam("Base", (a[0], 0, a[1]), (b[0], 0, b[1]), 0.5, STONE_L, width=0.16)
    return k


# ------------------------------------------------------------------ roofs
def along(t, base=0.0, y0=-2.3, y1=2.0, rise=3.0):
    """Point on a slope surface: eave (t = 0) to top (t = 1)."""
    z0 = base - (-2.0 - y0) * 0.75
    return y0 + (y1 - y0) * t, z0 + (base + rise - z0) * t


def courses(k, y0, y1, base, rise, flip, straw):
    """One roof plane rising toward +Y (or -Y when flip), as overlapping courses."""
    length = math.hypot(y1 - y0, (y1 - y0) * 0.75)
    n = max(3, round(length / (0.62 if straw else 0.9)))
    sgn = -1 if flip else 1
    for i in range(n):
        t = (i + 0.5) / n
        y, z = along(t, base, y0, y1, rise)
        if straw:
            for c in range(4):                            # bundles: uneven lengths give a ragged thatch line
                drop = k.rng.uniform(0.0, 0.14)
                k.box("Base", (1.0, length / n + 0.2 + drop, 0.24), (-1.5 + c, sgn * (y - drop * 0.4), z + 0.05 + 0.035 * ((i + c) % 2) - drop * 0.3),
                      (STRAW, STRAW_L, STRAW, STRAW_D)[(i * 3 + c) % 4], rot=(sgn * PITCH, 0, 0), bevel=0.05, jitter=0.12)
        else:
            cols = 6
            for c in range(cols + (i % 2)):
                x = -2.0 + 4.0 * (c + (0.0 if i % 2 else 0.5)) / cols
                w = 4.0 / cols
                if x - w * 0.5 < -2.001:
                    x, w = -2.0 + w * 0.25, w * 0.5
                if x + w * 0.5 > 2.001:
                    x, w = 2.0 - w * 0.25, w * 0.5
                k.box("Base", (w - 0.03, length / n + 0.16, 0.09), (x, sgn * y, z + 0.06 + 0.035 * ((c + i) % 2)),
                      SLATE_L if (c * 7 + i * 3) % 5 == 0 else (SLATE if (c + i) % 2 else SLATE_D), rot=(sgn * PITCH, 0, 0), bevel=0.012, jitter=0.09)
    for x in (-1.7, 0, 1.7):                              # rafters underneath
        a = along(0.02, base, y0, y1, rise); b = along(0.99, base, y0, y1, rise)
        k.beam("Base", (x, sgn * a[0], a[1] - 0.16), (x, sgn * b[0], b[1] - 0.16), 0.16, WOOD_D, width=0.14)


def ridge_roll(k, z, straw):
    if straw:
        k.box("Base", (4.0, 0.5, 0.3), (0, 0, z + 0.06), STRAW_D, bevel=0.1, jitter=0.06)
        for x in (-1.3, 0, 1.3):
            k.box("Base", (0.1, 0.62, 0.36), (x, 0, z + 0.06), WOOD_D, bevel=0.03)
    else:
        k.box("Base", (4.0, 0.34, 0.2), (0, 0, z + 0.08), SLATE_D, bevel=0.06)
        k.box("Base", (4.0, 0.12, 0.08), (0, 0, z + 0.2), GOLD, bevel=0.02)


def slope(straw):
    k = Kit("piece_%sslope" % ("thatch" if straw else "slate"), 130 + straw, 3.4)
    courses(k, -2.3, 2.0, 0.0, 3.0, False, straw)
    k.box("Base", (4.0, 0.24, 0.24), (0, 1.94, 3.0), STRAW_D if straw else SLATE_D, bevel=0.05)
    k.box("Base", (4.0, 0.18, 0.2), (0, -2.26, -0.2), WOOD_D, bevel=0.03)                     # eave board
    return k


def ridge(straw):
    k = Kit("piece_%sridge" % ("thatch" if straw else "slate"), 132 + straw, 2.0)
    for flip in (False, True):
        courses(k, -2.3, 0.0, 0.0, 1.5, flip, straw)
        k.box("Base", (4.0, 0.18, 0.2), (0, 2.26 if flip else -2.26, -0.2), WOOD_D, bevel=0.03)
    ridge_roll(k, 1.5, straw)
    return k


def peak(straw):
    k = Kit("piece_%speak" % ("thatch" if straw else "slate"), 134 + straw, 5.0)
    for flip in (False, True):
        courses(k, -2.0, 0.0, 3.0, 1.5, flip, straw)
    ridge_roll(k, 4.5, straw)
    for x in (-1.7, 1.7):                                 # king posts and a tie beam inside
        k.box("Base", (0.16, 0.16, 1.4), (x, 0, 3.7), WOOD_D, bevel=0.02)
        k.box("Base", (0.16, 3.9, 0.18), (x, 0, 3.02), WOOD_D, bevel=0.02)
    return k


def thatchcap():
    k = Kit("piece_thatchcap", 136, 3.4)
    k.roof("Base", 4.0, 4.0, 3.0, (0, 0, -0.14), STRAW, overhang=0.3, tiles=8)
    k.cyl("Base", 0.2, 0.12, 0.4, (0, 0, 2.82), STRAW_D, segs=6)
    k.box("Base", (0.5, 0.1, 0.1), (0, 0, 3.0), WOOD_D, bevel=0.02)
    k.box("Base", (0.1, 0.5, 0.1), (0, 0, 3.0), WOOD_D, bevel=0.02)
    for s in (-1, 1):
        k.box("Base", (4.4, 0.14, 0.16), (0, s * 2.2, -0.16), WOOD_D, bevel=0.03)
        k.box("Base", (0.14, 4.4, 0.16), (s * 2.2, 0, -0.16), WOOD_D, bevel=0.03)
    return k


def slatespire():
    k = Kit("piece_slatespire", 137, 6.6)
    k.roof("Base", 4.0, 4.0, 6.0, (0, 0, -0.14), SLATE, overhang=0.3, tiles=10)
    k.cyl("Base", 0.1, 0.05, 0.7, (0, 0, 5.75), GOLD, segs=6)
    k.ball("Base", 0.17, (0, 0, 6.5), GOLD, subdiv=1)
    for s in (-1, 1):
        k.box("Base", (4.5, 0.16, 0.18), (0, s * 2.24, -0.16), STONE_L, bevel=0.03)
        k.box("Base", (0.16, 4.5, 0.18), (s * 2.24, 0, -0.16), STONE_L, bevel=0.03)
    return k


DESIGNS = {"foundation": foundation, "woodfloor": woodfloor, "stonefloor": stonefloor, "woodpost": woodpost, "stonecolumn": stonecolumn,
           "woodstairs": woodstairs, "stonestairs": stone_stairs_clean, "brazier": brazier, "bannerpole": bannerpole,
           "woodwall": woodwall, "woodwindow": woodwindow, "wooddoorway": wooddoorway, "wooddoor": wooddoor, "woodrailing": woodrailing,
           "stonewall": stonewall, "stoneslit": stoneslit, "stonearch": stonearch, "stonegate": stonegate, "battlement": battlement,
           "thatchslope": lambda: slope(True), "thatchridge": lambda: ridge(True), "thatchpeak": lambda: peak(True), "thatchcap": thatchcap,
           "slateslope": lambda: slope(False), "slateridge": lambda: ridge(False), "slatepeak": lambda: peak(False), "slatespire": slatespire}
for _v in GABLES:
    DESIGNS["woodgable_" + _v] = (lambda v=_v: woodgable(v))
    DESIGNS["stonegable_" + _v] = (lambda v=_v: stonegable(v))


def build(name, out=None):
    rigkit.reset()
    kit = DESIGNS[name]()
    objects = kit.build()
    if out:
        span = max(kit.height * 1.5, 6.5)
        rigkit.render_views(os.path.join(out, name), views=("quarter",), target=(0, 0, kit.height * 0.42), distance=span, res=420, lift=3.0)
    path = rigkit.export(objects, "piece_" + name)
    print("BUILT", name, os.path.getsize(path), kit.triangles(), "tris")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = None
    if "--preview" in args:
        i = args.index("--preview"); out = args[i + 1]; args = args[:i] + args[i + 2:]
    for name in (args or list(DESIGNS)):
        build(name, out)
