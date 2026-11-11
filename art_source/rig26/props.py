"""Hard-surface prop kit for Fort defenses: chamfered, vertex-painted pieces built locally.

A Kit collects primitives into named groups. Each group becomes one mesh object; groups
can hang under pivot empties ("Turret", door hinges). Names beginning Up2 / Up3 are the
upgrade stages the game reveals as a defense levels up.
Blender axes: Z up, +Y is the aim / front direction (Godot -Z).
"""
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler

LIGHT = Vector((0.35, -0.45, 0.82)).normalized()


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def lin(c):
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c)


class Kit:
    def __init__(self, key, seed=1, height=3.0):
        self.key = key
        self.groups = {}      # name -> {"v": [], "f": [], "c": []}
        self.pivots = {}      # group -> (pivot name, origin)
        self.rng = random.Random(seed)
        self.height = height

    # ------------------------------------------------------------ plumbing
    def _emit(self, group, bm, color, matrix, jitter=0.05):
        g = self.groups.setdefault(group, {"v": [], "f": [], "c": []})
        bm.verts.ensure_lookup_table()
        base = len(g["v"])
        for v in bm.verts:
            g["v"].append(tuple(matrix @ v.co))
        c = rgb(color) if isinstance(color, str) else color
        k = 1.0 + self.rng.uniform(-jitter, jitter)
        warm = self.rng.uniform(-jitter, jitter) * 0.5
        c = (min(1, c[0] * (k + warm)), min(1, c[1] * k), min(1, c[2] * (k - warm)))
        for f in bm.faces:
            g["f"].append(tuple(base + v.index for v in f.verts))
            g["c"].append(c)
        bm.free()

    @staticmethod
    def _m(pos, rot=(0, 0, 0), scale=(1, 1, 1)):
        return Matrix.Translation(Vector(pos)) @ Euler([math.radians(a) for a in rot], 'XYZ').to_matrix().to_4x4() @ Matrix.Diagonal((*scale, 1.0))

    def pivot(self, group, name, origin):
        """Hang a group under an empty placed at origin (turret or hinge)."""
        self.pivots[group] = (name, Vector(origin))

    # ------------------------------------------------------------ primitives
    def box(self, group, size, pos, color, rot=(0, 0, 0), bevel=0.02, taper=(1.0, 1.0), jitter=0.05):
        """Chamfered box centred at pos. taper scales the top face in X and Y."""
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for v in bm.verts:
            v.co.x *= size[0]; v.co.y *= size[1]; v.co.z *= size[2]
            if v.co.z > 0:
                v.co.x *= taper[0]; v.co.y *= taper[1]
        if bevel > 0:
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=min(bevel, min(size) * 0.3), segments=1, affect='EDGES')
        self._emit(group, bm, color, self._m(pos, rot), jitter)

    def cyl(self, group, r0, r1, h, pos, color, rot=(0, 0, 0), segs=8, jitter=0.05):
        """Tapered cylinder standing on pos (base centre) along local Z."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r0, radius2=max(r1, 0.0005), depth=h)
        for v in bm.verts:
            v.co.z += h * 0.5
        self._emit(group, bm, color, self._m(pos, rot), jitter)

    def ball(self, group, r, pos, color, scale=(1, 1, 1), subdiv=1, rot=(0, 0, 0), jitter=0.03):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
        self._emit(group, bm, color, self._m(pos, rot, scale), jitter)

    def crystal(self, group, r, h, pos, color, rot=(0, 0, 0), sides=6):
        """Pointed gem standing on pos: a short shaft with a long tip."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r * 0.7, radius2=r, depth=h * 0.45)
        for v in bm.verts:
            v.co.z += h * 0.225
        top = bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r, radius2=0.0005, depth=h * 0.55)
        for v in top["verts"]:
            v.co.z += h * 0.45 + h * 0.275
        self._emit(group, bm, color, self._m(pos, rot), 0.06)

    def ring(self, group, radius, thickness, pos, color, rot=(0, 0, 0), segs=14, tube=5):
        bm = bmesh.new()
        ring_verts = []
        for i in range(segs):
            a = i * math.tau / segs
            row = []
            for j in range(tube):
                b = j * math.tau / tube
                rr = radius + math.cos(b) * thickness
                row.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, math.sin(b) * thickness)))
            ring_verts.append(row)
        for i in range(segs):
            for j in range(tube):
                a0, a1 = ring_verts[i], ring_verts[(i + 1) % segs]
                bm.faces.new((a0[j], a1[j], a1[(j + 1) % tube], a0[(j + 1) % tube]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        self._emit(group, bm, color, self._m(pos, rot))

    def beam(self, group, a, b, thickness, color, bevel=0.015, width=None):
        a, b = Vector(a), Vector(b)
        d = b - a
        quat = d.to_track_quat('Z', 'Y')
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for v in bm.verts:
            v.co.x *= width or thickness; v.co.y *= thickness; v.co.z *= d.length
        if bevel > 0:
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=1, affect='EDGES')
        self._emit(group, bm, color, Matrix.Translation((a + b) * 0.5) @ quat.to_matrix().to_4x4())

    def prism(self, group, points, depth, pos, color, rot=(0, 0, 0), bevel=0.0):
        """Extrude a 2D outline (x, z) by depth along Y, centred on pos."""
        bm = bmesh.new()
        front = [bm.verts.new((x, -depth * 0.5, z)) for x, z in points]
        back = [bm.verts.new((x, depth * 0.5, z)) for x, z in points]
        n = len(points)
        bm.faces.new(front); bm.faces.new(back[::-1])
        for i in range(n):
            bm.faces.new((front[i], back[i], back[(i + 1) % n], front[(i + 1) % n]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        if bevel > 0:
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=1, affect='EDGES')
        self._emit(group, bm, color, self._m(pos, rot))

    # ------------------------------------------------------------ assemblies
    def stones(self, group, width, height, depth, pos, color, rows, per_row=None, dark="#4a505a", skip=None, backing=True):
        """Coursed masonry filling a slab whose bottom centre is pos. skip(x, z) -> True leaves a gap."""
        course = height / rows
        per_row = per_row or max(2, round(width / (course * 1.9)))
        if backing:
            self.box(group, (width - 0.02, depth * 0.72, height - 0.02), (pos[0], pos[1], pos[2] + height * 0.5), dark, bevel=0, jitter=0.02)
        for r in range(rows):
            n = per_row + (r % 2)
            edges = [-width * 0.5]
            for i in range(1, n):
                base = -width * 0.5 + width * (i - (0.5 if r % 2 else 0.0)) / (n - (1 if r % 2 else 0))
                edges.append(min(width * 0.5 - 0.08, max(-width * 0.5 + 0.08, base + self.rng.uniform(-0.04, 0.04))))
            edges.append(width * 0.5)
            edges = sorted(set(round(e, 4) for e in edges))
            for x0, x1 in zip(edges, edges[1:]):
                if x1 - x0 < 0.06:
                    continue
                cx = (x0 + x1) * 0.5; cz = pos[2] + course * (r + 0.5)
                if skip and skip(pos[0] + cx, cz):
                    continue
                out = self.rng.uniform(-0.012, 0.02)
                self.box(group, (x1 - x0 - 0.035, depth + out * 2, course - 0.035), (pos[0] + cx, pos[1], cz), color, bevel=0.022, jitter=0.085)

    def planks(self, group, width, height, depth, pos, color, count, rot=(0, 0, 0)):
        """Vertical boards side by side, bottom centre at pos (before rot about pos)."""
        w = width / count
        base = self._m(pos, rot)
        for i in range(count):
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0)
            h = height + self.rng.uniform(-0.02, 0.02)
            for v in bm.verts:
                v.co.x *= w - 0.025; v.co.y *= depth; v.co.z *= h
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=0.012, segments=1, affect='EDGES')
            self._emit(group, bm, color, base @ Matrix.Translation((-width * 0.5 + w * (i + 0.5), 0, h * 0.5)), 0.09)

    def rivets(self, group, points, r, color):
        for p in points:
            self.ball(group, r, p, color, subdiv=1, jitter=0.02)

    def roof(self, group, width, depth, height, pos, color, overhang=0.15, tiles=4):
        """Hipped roof made of stepped tile courses; pos is the centre of its base."""
        for i in range(tiles):
            t0 = i / tiles; t1 = (i + 1) / tiles
            w0 = (width + overhang * 2) * (1 - t0 * 0.92); d0 = (depth + overhang * 2) * (1 - t0 * 0.92)
            self.box(group, (w0, d0, height / tiles + 0.02), (pos[0], pos[1], pos[2] + height * (t0 + t1) * 0.5), color,
                     bevel=0.03, taper=((1 - t1 * 0.92) / (1 - t0 * 0.92), (1 - t1 * 0.92) / (1 - t0 * 0.92)), jitter=0.07)

    def banner(self, group, width, height, pos, color, rot=(0, 0, 0), trim="#d9aa4c"):
        """Hanging pennant with a pointed foot; pos is the top centre."""
        w = width * 0.5
        self.prism(group, [(-w, 0), (w, 0), (w, -height * 0.78), (0, -height), (-w, -height * 0.78)], 0.03, pos, color, rot)
        self.box(group, (width + 0.08, 0.05, 0.05), pos, trim, rot=rot, bevel=0.01)

    # ------------------------------------------------------------ output
    def build(self):
        """Create objects: root empty named key, one mesh per group, pivot empties as declared."""
        root = bpy.data.objects.new(self.key, None)
        bpy.context.scene.collection.objects.link(root)
        mat = bpy.data.materials.get("DefensePaint")
        if not mat:
            mat = bpy.data.materials.new("DefensePaint"); mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            attr = mat.node_tree.nodes.new("ShaderNodeVertexColor"); attr.layer_name = "Col"
            mat.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
            bsdf.inputs["Roughness"].default_value = 0.85; bsdf.inputs["Metallic"].default_value = 0.0
        empties = {}
        objects = [root]
        for name, g in self.groups.items():
            origin = Vector((0, 0, 0)); parent = root
            if name in self.pivots:
                pivot_name, origin = self.pivots[name]
                if pivot_name not in empties:
                    e = bpy.data.objects.new(pivot_name, None); e.location = origin; e.parent = root
                    bpy.context.scene.collection.objects.link(e); empties[pivot_name] = e; objects.append(e)
                parent = empties[pivot_name]
            mesh = bpy.data.meshes.new(name + "Mesh")
            mesh.from_pydata([tuple(Vector(v) - origin) for v in g["v"]], [], g["f"])
            mesh.update()
            attr = mesh.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
            colors = []
            for poly in mesh.polygons:
                c = g["c"][poly.index]
                shade = 0.84 + 0.2 * max(poly.normal.dot(LIGHT), 0.0)
                for li in poly.loop_indices:
                    z = (mesh.vertices[mesh.loops[li].vertex_index].co.z + origin.z) / self.height
                    k = 0.84 * shade * (0.86 + 0.14 * min(1.0, max(0.0, z * 2.2)))   # 0.84: the game lights these brightly
                    colors.extend((*lin((min(1, c[0] * k), min(1, c[1] * k), min(1, c[2] * k))), 1.0))
            attr.data.foreach_set("color", colors)
            mesh.materials.append(mat)
            obj = bpy.data.objects.new(name, mesh); obj.parent = parent
            bpy.context.scene.collection.objects.link(obj); objects.append(obj)
        self.objects = objects
        return objects

    def triangles(self):
        return sum(sum(len(f) - 2 for f in g["f"]) for g in self.groups.values())
