"""Fort asset finishing pipeline. Run through Blender MCP or blender --background --python.
Builds new asset scenes without changing or deleting the user's open scene.
Input blockouts come from export_prototypes.gd; outputs are editable .blend libraries
and glTF models. Named pivots are preserved for game animation and aiming.
"""
import bpy
import bmesh
import math
from pathlib import Path

ROOT = Path(r"C:\Users\maddo\Documents\Code\fort")
STAGE = ROOT / ".tools" / "asset_stage"
OUTPUT = ROOT / "assets" / "models" / "fort"
SOURCES = ROOT / "art_source" / "blender"
OUTPUT.mkdir(parents=True, exist_ok=True)
SOURCES.mkdir(parents=True, exist_ok=True)

def merge_static_batches(scene):
    """Merge only fresh, unanimated leaf meshes sharing a pivot and material.

    Keeps named moving pivots intact, reducing draw submissions without changing
    silhouettes. The unmerged artist source is saved separately before this step.
    """
    groups = {}
    for obj in list(scene.objects):
        if obj.type != 'MESH' or obj.animation_data or obj.children:
            continue
        key = (obj.parent, tuple(obj.data.materials))
        groups.setdefault(key, []).append(obj)
    for objects in groups.values():
        if len(objects) < 2:
            continue
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        # Apply each new mesh's edge finish before joining; join retains only the
        # active object's modifier stack otherwise.
        for obj in objects:
            bpy.context.view_layer.objects.active = obj
            for modifier in list(obj.modifiers):
                bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()

def bake_enemy_palette(scene):
    """Keep sculpt colors but merge material submissions per animation pivot."""
    material=bpy.data.materials.new('Fort_Swarm_VertexPalette')
    material.use_nodes=True
    shader=material.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value=.86
    shader.inputs['Metallic'].default_value=.08
    attribute=material.node_tree.nodes.new('ShaderNodeVertexColor')
    attribute.layer_name='SwarmPalette'
    material.node_tree.links.new(attribute.outputs['Color'],shader.inputs['Base Color'])
    for obj in scene.objects:
        if obj.type!='MESH':continue
        colors=[]
        for old in obj.data.materials:
            node=old.node_tree.nodes.get('Principled BSDF') if old and old.use_nodes else None
            colors.append(tuple(node.inputs['Base Color'].default_value) if node else (.5,.5,.5,1))
        attr=obj.data.color_attributes.new(name='SwarmPalette',type='FLOAT_COLOR',domain='CORNER')
        obj.data.color_attributes.active_color=attr
        for polygon in obj.data.polygons:
            color=colors[polygon.material_index] if colors else (.5,.5,.5,1)
            for index in polygon.loop_indices:attr.data[index].color=color
            polygon.material_index=0
        obj.data.materials.clear();obj.data.materials.append(material)

def finish_asset(key, source_scene=None, authored_clips=None):
    old_scene = bpy.context.window.scene
    scene = source_scene or bpy.data.scenes.new("Fort_" + key)
    bpy.context.window.scene = scene
    scene.render.fps = 30
    scene.frame_start, scene.frame_end = 1, 25
    if source_scene is None:
        bpy.ops.import_scene.gltf(filepath=str(STAGE / (key + ".glb")))
    objects = list(scene.objects)
    roots = [o for o in objects if o.parent is None]
    asset_root = roots[0]
    asset_root["fort_asset"] = key
    # Remove split seams on fresh imports before beveling so box faces meet.
    for obj in objects:
        if obj.type != 'MESH':
            continue
        obj.data = obj.data.copy()
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        bmesh.ops.remove_doubles(mesh, verts=list(mesh.verts), dist=0.00001)
        mesh.to_mesh(obj.data)
        mesh.free()
        bevel = obj.modifiers.new("Hand softened edges", 'BEVEL')
        bevel.width = float(obj.get("fort_bevel", 0.025 if key not in ("bolt", "jetpack") else 0.01))
        bevel.segments = 2
        bevel.limit_method = 'ANGLE'
        bevel.angle_limit = math.radians(35)
        for polygon in obj.data.polygons:
            polygon.use_smooth = bool(obj.get("fort_smooth", False))
        for mat in obj.data.materials:
            if mat and mat.use_nodes:
                node = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
                if node:
                    node.inputs["Roughness"].default_value = 0.86
                    node.inputs["Metallic"].default_value = 0.08
                    if node.inputs["Emission Strength"].default_value > 0 and max(node.inputs["Emission Color"].default_value[:3]) > 0:
                        node.inputs["Emission Color"].default_value = node.inputs["Base Color"].default_value
                        node.inputs["Emission Strength"].default_value = 0.3
    clips = authored_clips or []
    if key in ("raider", "brute", "sapper", "emberrunner", "chieftain", "sapper7", "cinderlobber", "shieldguard", "hexer", "colossus", "prowler", "pet_badger", "pet_mole", "pet_sprite"):
        clips = ["Idle", "Walk", "Attack", "Hit", "Death"]
        movers = [o for o in objects if o.name.split(".")[0] in ("ArmL","ArmR","LegL","LegR")] + [asset_root]
        for obj in movers:
            obj.rotation_mode = 'XYZ'
        rests = {o: (o.location.copy(), o.rotation_euler.copy(), o.scale.copy()) for o in movers}
        for clip in clips:
            for obj in movers:
                loc, rot, scale = rests[obj]
                obj.animation_data_create()
                obj.animation_data.action = None
                for frame in [1,7,13,19,25]:
                    phase = (frame - 1) / 24
                    obj.location, obj.rotation_euler, obj.scale = loc, rot, scale
                    name = obj.name.split(".")[0]
                    if clip == "Walk":
                        swing = math.sin(phase * math.tau) * 0.62
                        if name in ("LegL","ArmR"): obj.rotation_euler.x += swing
                        if name in ("LegR","ArmL"): obj.rotation_euler.x -= swing
                        if obj == asset_root: obj.location.z += abs(math.sin(phase * math.tau)) * 0.045
                    elif clip == "Idle":
                        if name.startswith("Arm"): obj.rotation_euler.x += math.sin(phase * math.tau) * 0.06
                        if obj == asset_root: obj.scale.z *= 1 + math.sin(phase * math.tau) * 0.025
                    elif clip == "Attack":
                        if name == "ArmR": obj.rotation_euler.x += [-0.4,-2.3,0.5,0.1,-0.4][[1,7,13,19,25].index(frame)]
                        if obj == asset_root: obj.rotation_euler.z += math.sin(phase * math.pi) * 0.14
                    elif clip == "Hit":
                        if obj == asset_root: obj.rotation_euler.x += math.sin(phase * math.pi) * 0.22
                    elif clip == "Death":
                        if obj == asset_root:
                            obj.rotation_euler.y += phase * 1.45
                            obj.location.z -= phase * 0.25
                    obj.keyframe_insert(data_path="location",frame=frame)
                    obj.keyframe_insert(data_path="rotation_euler",frame=frame)
                    obj.keyframe_insert(data_path="scale",frame=frame)
                action = obj.animation_data.action
                action.name = key + "_" + clip + "_" + name
                track = obj.animation_data.nla_tracks.new()
                track.name = clip
                strip = track.strips.new(clip,1,action)
                strip.action_frame_start = 1
                strip.action_frame_end = 25
                obj.animation_data.action = None
                obj.location, obj.rotation_euler, obj.scale = loc, rot, scale
    elif key == "horse":
        clips = ["Gallop"]
        for obj in objects:
            if not obj.name.startswith("Leg_"): continue
            obj.rotation_mode = 'XYZ'
            rest = obj.rotation_euler.copy()
            offset = (1 if obj.location.x > 0 else 0) + (1 if obj.location.y > 0 else 0)
            for frame in [1,7,13,19,25]:
                obj.rotation_euler = rest
                obj.rotation_euler.x += math.sin((frame-1)/24*math.tau + offset*math.pi) * 0.6
                obj.keyframe_insert(data_path="rotation_euler",frame=frame)
            action = obj.animation_data.action
            action.name = "horse_Gallop_" + obj.name
            track = obj.animation_data.nla_tracks.new()
            track.name = "Gallop"
            track.strips.new("Gallop",1,action)
            obj.animation_data.action = None
            obj.rotation_euler = rest
    scene.frame_set(1)
    bpy.context.view_layer.update()
    if source_scene is not None:
        bpy.data.libraries.write(str(SOURCES / (key + "_sculpt.blend")), {scene}, fake_user=True, compress=True)
        if key in ('raider','brute','sapper','ashwing','emberrunner','chieftain','sapper7','cinderlobber','bombwing','shieldguard','hexer','colossus','prowler','razorback','direwolf','stonebear','emberdrake','frostwyrm'):
            bake_enemy_palette(scene)
        merge_static_batches(scene)
        for obj in scene.objects:
            if obj.type == 'MESH': obj.data.validate(clean_customdata=False)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT / (key + ".glb")), export_format='GLB',
        use_active_scene=True, export_apply=True, export_animations=bool(clips),
        export_animation_mode='NLA_TRACKS', export_merge_animation='NLA_TRACK',
        export_optimize_animation_size=False, export_lights=False,
        export_cameras=False, export_extras=True
    )
    bpy.data.libraries.write(str(SOURCES / (key + ".blend")), {scene}, fake_user=True, compress=True)
    result = {"asset":key, "objects":len(scene.objects), "clips":clips, "file":str(OUTPUT / (key+".glb"))}
    bpy.context.window.scene = old_scene
    return result

def build(keys=None):
    keys = keys or ["hearthhold","stockpile","workshop","watchtower","barricade","ballista","mender",
                    "raider","brute","sapper","horse","jetpack","stone_deposit","crystal_deposit","lantern","bolt"]
    original_scene = bpy.context.window.scene
    try:
        return [finish_asset(key) for key in keys]
    finally:
        bpy.context.window.scene = original_scene

if __name__ == "__main__":
    print(build())
