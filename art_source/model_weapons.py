"""Fort 3 hand weapons. Grip at origin; Blender Z up and -Y forward."""
from pathlib import Path
from math import pi
import bpy
ROOT=Path(__file__).resolve().parents[1]
g={'__name__':'fort_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),g)
empty,box,taper,ring,mesh=[g[k] for k in ['empty','box','taper','ring','mesh']]

def hammer(root):
    taper('AshHandle',root,(0,0,-.15),(0,0,.46),.032,.045,'wood',10)
    for z in [-.11,-.05,.01,.07]:ring('LeatherGrip',root,(0,0,z),.033,.009,'leather')
    box('ForgedHead',root,(0,0,.43),(.54,.24,.23),'iron')
    for x in [-.27,.27]:
        box('StrikingFace',root,(x,0,.43),(.07,.28,.28),'edge')
        box('FaceInset',root,(x*1.15,0,.43),(.012,.17,.17),'iron')
    box('GoldCollar',root,(0,0,.43),(.075,.255,.26),'gold')
    for y in [-.132,.132]:
        box('TealRune',root,(.13,y,.43),(.035,.015,.12),'teal')
        box('RuneBranch',root,(.16,y,.46),(.07,.015,.025),'teal',(0,.4,0))
    taper('Pommel',root,(0,0,-.18),(0,0,-.12),.053,.04,'gold',8)

def crossbow(root):
    box('WalnutStock',root,(0,-.13,.05),(.13,.72,.12),'wood')
    box('ShoulderButt',root,(0,.22,.02),(.18,.18,.17),'leather')
    box('Grip',root,(0,0,-.07),(.10,.13,.20),'leather',(0.2,0,0))
    box('Rail',root,(0,-.17,.12),(.055,.64,.045),'edge')
    for side in [-1,1]:
        taper('SteelBowInner',root,(0,-.36,.07),(side*.28,-.42,.07),.038,.03,'iron',6)
        taper('SteelBowTip',root,(side*.28,-.42,.07),(side*.43,-.26,.07),.03,.018,'edge',6)
        taper('BowString',root,(side*.43,-.26,.07),(0,-.04,.07),.006,.006,'bone',4)
        box('LimbBinding',root,(side*.19,-.40,.07),(.06,.09,.09),'gold')
    ammo=empty('LoadedAmmo',root)
    taper('LoadedBolt',ammo,(0,.05,.16),(0,-.57,.16),.014,.014,'wood',6)
    taper('BoltHead',ammo,(0,-.57,.16),(0,-.66,.16),.035,0,'edge',4)
    for side in [-1,1]:box('Fletching',ammo,(side*.023,.02,.16),(.04,.10,.014),'teal')
    box('Sight',root,(0,-.3,.21),(.018,.03,.12),'gold')
    ring('TriggerGuard',root,(0,.025,-.045),.065,.009,'gold',(0,pi/2,0))

def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),ns)
    results=[]
    try:
        for key,builder in [('weapon_hammer',hammer),('weapon_crossbow',crossbow)]:
            scene=bpy.data.scenes.new('Fort_Weapon_'+key)
            bpy.context.window.scene=scene
            root=empty(key);builder(root)
            results.append(ns['finish_asset'](key,source_scene=scene))
        return results
    finally:bpy.context.window.scene=original

if __name__=='__main__':print(build())
