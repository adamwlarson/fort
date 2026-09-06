"""Crew relic variants, preserving normal weapon grips and the active Blender scene."""
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[1]

def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort_relic_geometry','__file__':str(ROOT/'art_source/model_weapons.py')}
    exec(compile((ROOT/'art_source/model_weapons.py').read_text(),'model_weapons.py','exec'),ns)
    ns['g']['PALETTE'].update({'ember':'f7a452','aether':'ba83ec'})
    box,taper,ring,empty=[ns[k] for k in ('box','taper','ring','empty')]
    fin={'__name__':'fort_relic_finish'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    results=[]
    try:
        for kind in ('embermaul','stormstring'):
            scene=bpy.data.scenes.new('Fort5_'+kind);bpy.context.window.scene=scene
            root=empty(kind)
            if kind=='embermaul':
                ns['hammer'](root)
                for x in (-.23,0,.23):
                    taper('FlameCrown',root,(x,0,.55),(x*1.2,0,.80-abs(x)*.4),.09,.008,'gold',5)
                for y in (-.15,.15):
                    box('EmberCore',root,(0,y,.43),(.16,.03,.15),'ember',(0,.5,0))
                    for x in (-.18,.18):box('HeatVent',root,(x,y,.43),(.025,.025,.17),'ember')
            else:
                ns['crossbow'](root)
                for side in (-1,1):
                    taper('AetherPrism',root,(side*.28,-.4,.09),(side*.28,-.4,.33),.07,0,'aether',5)
                    taper('GildedLimb',root,(side*.20,-.4,.07),(side*.5,-.32,.07),.045,.012,'gold',5)
                    box('Coil',root,(side*.08,-.14,.08),(.03,.22,.12),'aether')
            results.append(fin['finish_asset'](kind,scene))
    finally:bpy.context.window.scene=original
    return results
