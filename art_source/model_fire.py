"""Fort hearth logs, modeled in a new Blender scene; preserves the open scene."""
from pathlib import Path
from math import sin, cos, tau
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]

def build():
    original = bpy.context.window.scene
    helpers = {'__name__': 'fort_geometry', '__file__': str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(), 'model_raiders.py', 'exec'), helpers)
    helpers['PALETTE'].update({'charcoal':'302c2b', 'bark':'594134', 'cut':'bd9060', 'heartwood':'8c603d', 'coal':'b84624', 'ash':'83786a'})
    empty, taper, ellipsoid = [helpers[k] for k in ['empty','taper','ellipsoid']]
    finisher = {'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(), 'build_assets.py', 'exec'), finisher)
    try:
        scene = bpy.data.scenes.new('Fort_Campfire_Logs')
        bpy.context.window.scene = scene
        root = empty('campfire_logs')
        for i in range(18):
            angle = i*2.399
            radius = .18 + (i%5)*.16
            ellipsoid('Coal_%02d'%i,root,(cos(angle)*radius,sin(angle)*radius,.51),(.17,.13,.075),'coal' if i%3 else 'charcoal',1)
        for i in range(5):
            angle = i*tau/5
            axis = Vector((cos(angle),sin(angle),.10 if i%2 else -.08))
            center = Vector((cos(angle+1)*.22,sin(angle+1)*.22,.64+(i%2)*.16))
            a,b = center-axis*.85, center+axis*.85
            taper('Split_Log_%d'%i,root,a,b,.19,.16,'bark',9)
            for end, direction, radius in [(a,-axis,.18),(b,axis,.15)]:
                taper('Cut_End',root,end,end+direction*.014,radius,radius,'cut',9)
                taper('Heart_Ring',root,end+direction*.016,end+direction*.019,radius*.68,radius*.68,'heartwood',9)
                taper('Growth_Ring',root,end+direction*.020,end+direction*.022,radius*.40,radius*.40,'cut',9)
            for j in range(5):
                phi = j*tau/5
                side = Vector((-sin(angle)*cos(phi),cos(angle)*cos(phi),sin(phi)))*.17
                taper('Charred_Bark',root,a+axis*.18+side,b-axis*.18+side,.028,.018,'charcoal',5)
            taper('Glowing_Seam',root,center-axis*.48+Vector((0,0,.17)),center+axis*.37+Vector((0,0,.17)),.017,.009,'coal',5)
        return finisher['finish_asset']('campfire_logs',source_scene=scene)
    finally:
        bpy.context.window.scene = original

if __name__ == '__main__':
    print(build())
