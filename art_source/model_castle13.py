"""Concept-guided modular ashlar / brass castle kit. Blender Z up, -Y forward.
Creates independent scenes and preserves the artist's current scene.
"""
from pathlib import Path
from math import sin, cos, pi, tau
import bpy
ROOT=Path(__file__).resolve().parents[1]
KEYS=['castle_wall','castle_pier','castle_sign','castle_merchant','castle_lodge','castle_research']
def build():
    original=bpy.context.window.scene
    ns={'__name__':'castle_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'ashlar':'65717d','stone_light':'87939a','roof':'336c72','rune':'82d3c4'})
    empty,box,taper,ellipsoid,ring,mesh=[ns[k] for k in ['empty','box','taper','ellipsoid','ring','mesh']]
    fin={'__name__':'castle_finish'};exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    results=[]
    try:
        for key in KEYS:
            scene=bpy.data.scenes.new('Fort13_'+key);bpy.context.window.scene=scene;root=empty(key)
            if key=='castle_wall':
                box('BatteredFooting',root,(0,0,.14),(2.8,.65,.28),'stone_light')
                for row in range(4):
                    for col in range(4):
                        x=-1.05+col*.7
                        box('DressedAshlar',root,(x,0,.48+row*.39),(.68,.48,.37),'ashlar' if (col+row)%3 else 'stone_light')
                box('Cornice',root,(0,0,1.92),(2.8,.67,.2),'stone_light')
                for x in [-1.0,0,1.0]:box('Merlon',root,(x,0,2.23),(.6,.57,.45),'ashlar')
                for x in [-1.22,1.22]:
                    box('Buttress',root,(x,0,1.03),(.24,.7,1.8),'ashlar')
                    box('BrassBand',root,(x,0,1.48),(.27,.73,.12),'gold')
                box('Banner',root,(0,-.29,1.16),(.55,.06,.9),'roof')
                mesh('BannerPoint',root,[(-.275,-.29,.71),(.275,-.29,.71),(0,-.29,.46)],[(0,1,2)],'roof')
                for s in [-1,1]:box('Rune',root,(s*.085,-.33,1.2),(.065,.045,.34),'gold',(0,s*.42,0))
            elif key=='castle_pier':
                box('Plinth',root,(0,0,.12),(1.05,1.05,.24),'stone_light')
                for i in range(4):box('CornerStone',root,(0,0,.4+i*.3),(.76,.76,.28),'ashlar' if i%2 else 'stone_light')
                box('Band',root,(0,0,1.15),(.8,.8,.11),'gold');box('Capital',root,(0,0,1.62),(1,1,.25),'stone_light')
            elif key=='castle_sign':
                for x in [-.55,.55]:
                    box('Peg',root,(x,0,.7),(.12,.14,1.4),'wood')
                    ellipsoid('Rivet',root,(x,-.14,1.1),(.045,.045,.045),'gold',1)
                for i in range(3):box('CarvedBoard',root,(0,0,.8+i*.22),(1.45,.18,.2),'wood' if i%2 else 'leather_light')
                for x,h in [(-.32,.3),(0,.44),(.32,.3)]:box('CastleCrest',root,(x,-.115,1),( .18,.07,h),'gold')
                box('MaterialTray',root,(0,.35,.23),(1.4,.75,.15),'wood')
                for x in [-.4,0,.4]:ellipsoid('SupplyStone',root,(x,.3,.4),(.2,.2,.17),'ashlar',1)
            else:
                # Open-faced service pavilions: compact enough for clear room circulation.
                for x in [-2.6,2.6]:
                    for y in [-1.7,1.7]:
                        box('StonePedestal',root,(x,y,.3),(.7,.7,.6),'ashlar')
                        taper('CarvedPost',root,(x,y,.6),(x,y,3.15),.19,.14,'wood',8)
                        for z in [.65,2.65]:box('PostBand',root,(x,y,z),(.35,.35,.1),'gold')
                for s in [-1,1]:
                    box('RoofPlane',root,(s*1.4,0,3.45),(3,4.25,.17),'roof',(0,s*.32,0))
                    for i in range(7):box('RaisedRoofSeam',root,(s*1.4,-1.95+i*.65,3.56),(3,.04,.045),'gold',(0,s*.32,0))
                taper('RidgeCap',root,(0,-2.2,3.95),(0,2.2,3.95),.12,.12,'gold')
                if key=='castle_merchant':
                    box('Counter',root,(0,-1.1,.9),(4.6,.8,.18),'wood')
                    for x in [-1.8,1.8]:box('CounterLeg',root,(x,-1.1,.45),(.16,.5,.9),'wood')
                    for i in range(7):
                        taper('PotionBottle',root,(-1.8+i*.58,-1.1,1),(-1.8+i*.58,-1.1,1.3+i%2*.15),.12,.065,'glass' if i%2 else 'copper')
                        ellipsoid('BottleStopper',root,(-1.8+i*.58,-1.1,1.36+i%2*.15),(.07,.07,.06),'wood',1)
                    for x in [-1.7,0,1.7]:box('TradeChest',root,(x,.7,.5),(1.25,.9,1),'leather_light')
                elif key=='castle_lodge':
                    for i in range(5):
                        taper('StoredTimber',root,(-1.8,0,.3+i*.22),(1.5,0,.3+i*.22),.18,.18,'wood')
                    for x in [-1.8,1.8]:
                        ellipsoid('GrainSack',root,(x,-.9,.55),(.45,.38,.55),'leather_light')
                        ring('SackTie',root,(x,-.9,1),.15,.035,'gold')
                    box('ExpeditionDesk',root,(0,1,1.2),(3.5,1,.16),'wood')
                    box('Map',root,(0,1,1.3),(1.8,.75,.02),'bone')
                else:
                    taper('AstrolabeBase',root,(0,0,0),(0,0,1.2),.8,.36,'ashlar')
                    for angle in [0,pi/3,-pi/3]:ring('ArmillaryRing',root,(0,0,2.05),.88,.07,'gold',(pi/2,angle,0))
                    ellipsoid('RuneCore',root,(0,0,2.05),(.38,.38,.5),'rune',2)
                    for x in [-1.8,1.8]:
                        box('BookPlinth',root,(x,0,.7),(.8,.8,1.4),'ashlar')
                        for i in range(3):box('BoundTome',root,(x,0,1.46+i*.12),(.65,.48,.1),'hood' if i%2 else 'copper')
            for obj in scene.objects:
                if obj.type=='MESH':obj['fort_bevel']=.025
            results.append(fin['finish_asset'](key,scene,[]))
    finally:bpy.context.window.scene=original
    return results
