"""Fort 6 construction and quarry sculptures. New scenes only."""
from pathlib import Path
from math import pi
import bpy
ROOT=Path(__file__).resolve().parents[1]
def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort6_shapes','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'ruststone':'896c56','ochre':'b58a5d','rope':'c5ad83'})
    empty,box,taper,ring,ellipsoid=[ns[k] for k in ('empty','box','taper','ring','ellipsoid')]
    fin={'__name__':'fort6_export'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    result=[]
    try:
        for kind in ('construction_scaffold','quarry_crane','quarry_retaining','quarry_bridge','mine_portal'):
            scene=bpy.data.scenes.new('Fort6_'+kind);bpy.context.window.scene=scene;root=empty(kind)
            if kind=='construction_scaffold':
                for x in (-1.4,1.4):
                    for y in (-.9,.9):
                        box('Upright',root,(x,y,1.15),(.14,.14,2.3),'wood')
                        for z in (.4,1.5,2.1):ring('RopeLashing',root,(x,y,z),.10,.024,'rope')
                for y in (-.9,.9):
                    for z in (.45,1.6,2.15):box('Crossbar',root,(0,y,z),(3.1,.13,.13),'wood')
                    taper('DiagonalBrace',root,(-1.3,y,.4),(1.3,y,2.1),.07,.07,'leather_light',4)
                for i in range(5):box('WorkPlank',root,(0,-.7+i*.34,1.64),(3.0,.30,.08),'leather_light')
                for z in (.3,.7,1.1,1.5):box('LadderRung',root,(-1.48,0,z),(.09,.8,.08),'wood')
            elif kind=='quarry_crane':
                for x in (-1,1):box('StoneFoot',root,(x,0,.22),(.85,1.2,.44),'ruststone')
                box('Mast',root,(0,0,3.1),(.48,.5,6.2),'wood')
                for side in (-1,1):taper('MastBrace',root,(side*1.4,0,.3),(0,0,3.6),.15,.12,'wood',4)
                taper('Boom',root,(-1,0,5.5),(4.4,0,6.4),.25,.16,'wood',4)
                taper('Cable',root,(-1,0,5.7),(0,0,7.2),.025,.025,'rope',6)
                taper('Stay',root,(0,0,7.2),(4.4,0,6.4),.025,.025,'rope',6)
                taper('LiftRope',root,(4.2,0,6.3),(4.2,0,1.8),.04,.04,'rope',6)
                ring('Pulley',root,(4.2,0,6.25),.28,.07,'iron',(pi/2,0,0))
                ring('Winch',root,(0,0,1.5),.52,.12,'iron',(pi/2,0,0))
                for x in (3.6,4.8):taper('Sling',root,(4.2,0,1.8),(x,0,.75),.035,.035,'rope',6)
                box('SuspendedOre',root,(4.2,0,.75),(1.2,.85,.8),'ruststone')
                box('Counterweight',root,(-1.1,0,5.1),(.9,.9,.7),'iron')
            elif kind=='quarry_retaining':
                for z in (.3,.9,1.5):
                    for i in range(5):
                        x=-2.4+i*1.2+(.2 if z==.9 else 0)
                        box('CutBlock',root,(x,0,z),(1.1,.75,.56),'ruststone' if i%2 else 'ochre')
                for x in (-2.8,2.8):box('IronBrace',root,(x,-.45,.9),(.2,.15,1.9),'iron')
                for x in (-1.8,0,1.7):taper('OreSeam',root,(x,-.4,.2),(x+.4,-.42,1.6),.035,.02,'copper',4)
            elif kind=='quarry_bridge':
                for x in (-1.3,1.3):
                    box('Beam',root,(x,0,-.15),(.2,6,.3),'wood')
                    for y in (-2.8,0,2.8):box('RailPost',root,(x,y,.6),(.15,.15,1.2),'wood')
                    for z in (.45,1.0):taper('RopeRail',root,(x,-2.8,z),(x,2.8,z),.035,.035,'rope',6)
                for i in range(15):
                    if i!=9:box('DeckPlank',root,(0,-2.8+i*.4,0),(2.7,.35,.15),'leather_light' if i%3 else 'wood')
                box('RepairPlank',root,(.4,.8,.12),(.28,1.5,.10),'ochre',(0,0,.3))
            else:
                for x in (-2.2,2.2):
                    box('TimberPillar',root,(x,0,1.7),(.5,.7,3.4),'wood')
                    taper('Bracket',root,(x,0,2.3),(x*.65,0,3.2),.2,.2,'wood',4)
                box('Lintel',root,(0,0,3.5),(5.1,.8,.6),'wood')
                for i in range(7):box('SealedTimber',root,(-1.8+i*.6,.35,1.6),(.53,.25,3.0),'leather')
                box('WarningBoard',root,(0,-.48,2.4),(1.8,.12,.6),'ochre')
                for x in (-.55,.55):taper('CrossedTools',root,(x,-.56,2.2),(-x,-.56,2.6),.04,.04,'iron',4)
                for x in (-2.6,2.6):ellipsoid('RockFall',root,(x,.4,.5),(.8,.9,1.0),'ruststone',1)
            result.append(fin['finish_asset'](kind,scene))
    finally:bpy.context.window.scene=original
    return result
