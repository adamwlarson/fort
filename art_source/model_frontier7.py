"""Fort 7 silhouettes and expedition architecture. Preserves the open user scene."""
from pathlib import Path
from math import pi, sin, cos, tau
import bpy
ROOT=Path(__file__).resolve().parents[1]

def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort7_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'plaster':'cec0a0','slate':'496674','red':'bd5434','hot':'ffb54e','aether':'bd98ea','stone':'7e817b'})
    empty,box,taper,ring,ellipsoid,mesh=[ns[k] for k in ('empty','box','taper','ring','ellipsoid','mesh')]
    fin={'__name__':'fort7_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    weapons={'__name__':'fort7_weapons','__file__':str(ROOT/'art_source/model_weapons.py')}
    exec(compile((ROOT/'art_source/model_weapons.py').read_text(),'model_weapons.py','exec'),weapons)
    results=[]
    try:
        for kind in ('watchtower7','upgrade_iron','upgrade_aether','weapon_pike','weapon_repeater','sapper7','cinderlobber','bombwing','village_house','village_well'):
            clips=None
            if kind in ('sapper7','cinderlobber'):
                scene=ns['enemy']('sapper');root=next(o for o in scene.objects if o.parent is None);root.name=kind
            elif kind=='bombwing':
                # Append an independent authored scene, preserving all wing animation tracks.
                with bpy.data.libraries.load(str(ROOT/'art_source/blender/ashwing_sculpt.blend'),link=False) as (src,dst):dst.scenes=[src.scenes[0]]
                scene=dst.scenes[0];bpy.context.window.scene=scene
                root=next(o for o in scene.objects if o.parent is None);root.name=kind
                # The source has animation already; don't apply a second edge finish.
                for obj in scene.objects:
                    for modifier in list(obj.modifiers):obj.modifiers.remove(modifier)
                clips=['Idle','Walk','Attack','Hit','Death']
            else:
                scene=bpy.data.scenes.new('Fort7_'+kind);bpy.context.window.scene=scene;root=empty(kind)
            if kind=='watchtower7':
                taper('OctagonalPlinth',root,(0,0,0),(0,0,.3),1.18,1.12,'stone',8)
                for x in (-.75,.75):
                    for y in (-.75,.75):
                        box('TimberPier',root,(x,y,1.4),(.27,.27,2.5),'wood')
                        box('IronFoot',root,(x,y,.52),(.34,.34,.4),'iron')
                        box('RivetedCapital',root,(x,y,2.35),(.36,.36,.25),'gold')
                for side in (-1,1):
                    taper('DiagonalTimber',root,(-.75,side*.76,.55),(.75,side*.76,2.25),.085,.085,'wood',4)
                    taper('SideBrace',root,(side*.76,-.75,.55),(side*.76,.75,2.25),.085,.085,'wood',4)
                for i in range(7):box('DeckPlank',root,(-.9+i*.3,0,2.47),(.28,2.1,.15),'wood')
                for side in (-1,1):
                    box('SteelParapet',root,(side*1.0,0,2.67),(.1,2.15,.32),'iron')
                    for y in (-.8,0,.8):box('ParapetRivet',root,(side*1.06,y,2.7),(.04,.08,.08),'gold')
                box('HangingStandard',root,(0,.83,1.75),(.72,.05,.8),'teal')
                box('StandardSigil',root,(0,.866,1.84),(.14,.04,.45),'gold')
                taper('Bearing',root,(0,0,2.52),(0,0,2.88),.28,.22,'iron',12)
                turret=empty('Turret',root,(0,0,2.9));weapons['crossbow'](turret);turret.scale=(1.8,1.8,1.8)
            elif kind=='upgrade_iron':
                for x in (-.88,.88):
                    for y in (-.78,.78):
                        box('ArmoredButtress',root,(x,y,.85),(.27,.25,1.7),'iron')
                        box('BrassEdging',root,(x,y,1.54),(.31,.29,.12),'gold')
                        for z in (.35,.75,1.2):ellipsoid('Stud',root,(x,y-.15,z),(.055,.035,.055),'gold',1)
                for side in (-1,1):box('ReinforcedBelt',root,(0,side*.8,.48),(2.0,.12,.22),'iron')
                box('TierTwoShield',root,(0,.9,1.2),(.65,.1,.64),'teal')
                for x in (-.12,.12):box('RankII',root,(x,.97,1.22),(.075,.035,.4),'gold')
            elif kind=='upgrade_aether':
                for x in (-.9,.9):
                    taper('CrystalSocket',root,(x,.78,1.4),(x,.78,1.65),.19,.19,'gold',8)
                    taper('AetherFinial',root,(x,.78,1.6),(x,.78,2.35),.18,0,'aether',5)
                    ring('OrbitBrace',root,(x,.78,1.87),.28,.035,'gold',(0,.25*x,0))
                box('LongPennant',root,(.9,.79,1.08),(.44,.07,.8),'aether')
                for x in (.78,.9,1.02):box('RankIII',root,(x,.84,1.1),(.05,.03,.35),'bone')
            elif kind=='weapon_pike':
                taper('IronwoodShaft',root,(0,0,-.4),(0,0,1.3),.037,.032,'wood',10)
                for z in (-.12,0,.12):ring('Grip',root,(0,0,z),.04,.012,'leather')
                taper('Spearhead',root,(0,0,1.2),(0,0,1.85),.13,0,'edge',4)
                box('Crossguard',root,(0,0,1.15),(.42,.055,.075),'iron')
                for side in (-1,1):taper('Hook',root,(side*.18,0,1.15),(side*.23,0,1.4),.04,0,'gold',4)
                ring('Ferrule',root,(0,0,1.2),.065,.022,'gold')
            elif kind=='weapon_repeater':
                weapons['crossbow'](root)
                box('Magazine',root,(0,-.15,.3),(.24,.32,.24),'iron')
                for x in (-.075,0,.075):taper('SpareBolt',root,(x,-.02,.44),(x,-.48,.44),.017,.017,'gold',6)
                for side in (-1,1):
                    ellipsoid('AetherCell',root,(side*.17,-.2,.18),(.07,.18,.075),'aether')
                    ring('WindingGear',root,(side*.15,.06,.17),.12,.026,'gold',(0,pi/2,0))
                taper('ForwardRail',root,(0,-.48,.12),(0,-.86,.12),.04,.035,'iron',8)
            elif kind in ('sapper7','cinderlobber'):
                if kind=='sapper7':
                    ellipsoid('HugePowderCharge',root,(0,.52,1.45),(.53,.46,.62),'red')
                    for z in (1.08,1.7):ring('ChargeBand',root,(0,.52,z),.43,.055,'iron')
                    taper('TallFuse',root,(0,.52,1.96),(.15,.52,2.42),.045,.025,'bone',6)
                    ellipsoid('HotFuseTip',root,(.15,.52,2.42),(.095,.08,.13),'hot',1)
                    for side in (-1,1):box('WarningStripe',root,(side*.3,-.30,1.08),(.13,.08,.55),'red',(0,side*.2,0))
                    box('HazardBadge',root,(0,-.36,1.02),(.33,.08,.33),'hot',(0,pi/4,0))
                else:
                    taper('MortarTube',root,(0,.48,1.0),(0,.82,2.55),.29,.36,'iron',12)
                    ring('MortarMuzzle',root,(0,.82,2.55),.35,.055,'copper')
                    for side in (-1,1):
                        box('OrangeShoulder',root,(side*.49,0,1.43),(.42,.42,.18),'red')
                        ellipsoid('AmmoSack',root,(side*.39,.3,.83),(.24,.24,.33),'leather_light')
                    box('MortarSight',root,(.3,.7,2.28),(.06,.1,.65),'gold')
            elif kind=='bombwing':
                box('BombSaddle',root,(0,.04,.65),(.62,.42,.20),'leather')
                for side in (-1,1):
                    ellipsoid('HangingPowderBomb',root,(side*.44,.07,.34),(.28,.3,.38),'red')
                    ring('BombBand',root,(side*.44,.07,.32),.29,.038,'gold')
                    taper('Sling',root,(side*.14,0,.95),(side*.44,0,.58),.045,.045,'gold',4)
                    taper('SignalHorn',root,(side*.22,0,1.4),(side*.38,.1,1.96),.1,0,'hot',6)
            elif kind=='village_house':
                box('StoneFoundation',root,(0,0,.18),(4.2,3.6,.36),'stone')
                # Three walls and front side panels leave a real, enterable doorway.
                for x in (-1.9,1.9):box('GableWall',root,(x,0,1.55),(.22,3.25,2.8),'plaster')
                box('BackWall',root,(0,1.55,1.55),(3.9,.2,2.8),'plaster')
                for x in (-1.32,1.32):box('FrontWall',root,(x,-1.55,1.55),(1.25,.2,2.8),'plaster')
                for x in (-1.95,1.95,-.65,.65):box('TimberPost',root,(x,-1.69,1.6),(.17,.18,2.9),'wood')
                for z in (.48,2.85):box('CrossTimber',root,(0,-1.7,z),(4.15,.17,.15),'wood')
                for side in (-1,1):
                    box('RoofSlope',root,(side*1.1,0,3.35),(2.65,4.1,.2),'slate',(0,side*.5,0))
                    for row in range(5):box('TileCourse',root,(side*(.2+row*.44),0,3.86-row*.24),(.12,4.12,.10),'teal')
                    box('Window',root,(side*1.34,-1.67,1.85),(.62,.08,.75),'black')
                    for xoff in (-.23,0,.23):box('WindowMullion',root,(side*1.34+xoff,-1.74,1.85),(.05,.06,.72),'gold')
                box('Chimney',root,(1.25,.75,3.75),(.6,.65,1.25),'stone')
                for z in (3.6,3.95,4.3):box('ChimneyCourse',root,(1.25,.75,z),(.66,.71,.07),'plaster')
                box('DoorLintel',root,(0,-1.72,2.66),(1.5,.26,.25),'wood')
            else:
                for i in range(12):
                    angle=i*tau/12
                    box('WellStone',root,(sin(angle)*.85,cos(angle)*.85,.46),(.47,.4,.84),'stone',(0,0,-angle))
                taper('DarkWater',root,(0,0,.14),(0,0,.18),.65,.65,'teal',16)
                for x in (-1.12,1.12):box('WellPost',root,(x,0,1.55),(.22,.24,3.1),'wood')
                box('WellBeam',root,(0,0,2.85),(2.65,.28,.3),'wood')
                taper('Rope',root,(0,0,.6),(0,0,2.8),.025,.025,'bone',6)
                ring('WindingWheel',root,(1.27,0,1.8),.38,.065,'iron',(0,pi/2,0))
                taper('Bucket',root,(0,0,.5),(0,0,.9),.18,.23,'wood',8)
            results.append(fin['finish_asset'](kind,scene,clips))
    finally:bpy.context.window.scene=original
    return results
