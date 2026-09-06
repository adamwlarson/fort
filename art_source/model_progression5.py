"""New Fort 5 assets; no changes to the user's active Blender scene."""
from pathlib import Path
from math import pi, sin, cos, tau
import bpy
ROOT=Path(__file__).resolve().parents[1]

def build():
    previous=bpy.context.window.scene
    ns={'__name__':'fort5_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'ore':'9b6749','silver':'94b1bb','aether':'b480e5','frost':'8cd7e1','pack':'607b67','red':'983f40'})
    empty,box,taper,ellipsoid,ring,mesh=[ns[k] for k in ('empty','box','taper','ellipsoid','ring','mesh')]
    fin={'__name__':'fort5_finish'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    results=[]
    try:
        for kind in ('iron_ore','aether_geode','metalwall','stormspire','frostmortar','backpack_trail','backpack_frame','armor_ironheart','treasure_chest','chieftain'):
            if kind=='chieftain':
                scene=ns['enemy']('brute');scene.name='Fort5_Chieftain'
                root=next(o for o in scene.objects if o.parent is None);root.name=kind;root.scale=(1.6,1.6,1.6)
                for x in (-.35,0,.35):taper('CrownProng',root,(x,-.02,2.0),(x,0,2.38-abs(x)*.4),.10,0,'gold')
                box('WarchiefBanner',root,(0,.45,1.0),(.80,.07,.80),'red')
                box('BannerRune',root,(0,.496,1.0),(.12,.02,.48),'gold')
            else:
                scene=bpy.data.scenes.new('Fort5_'+kind);bpy.context.window.scene=scene;root=empty(kind)
                if kind in ('iron_ore','aether_geode'):
                    ellipsoid('RockBed',root,(0,0,.16),(1.15,.85,.24),'skin_dark',1)
                    for i in range(6):
                        chunk=empty('HarvestChunk_'+str(i),root)
                        a=i*tau/6;x=cos(a)*.53;y=sin(a)*.43
                        ellipsoid('FracturedOre',chunk,(x,y,.40),(.46,.36,.50),'iron' if kind=='iron_ore' else 'hood',1)
                        if kind=='iron_ore':
                            for j in range(3):box('IronVein',chunk,(x+(j-1)*.11,y-.18,.56),(.055,.43,.32),'ore',(0,.25,a))
                            ellipsoid('ExposedMetal',chunk,(x,y,.82),(.25,.18,.08),'silver',1)
                        else:
                            taper('AetherPrism',chunk,(x,y,.28),(x*.9,y*.9,1.20+i%2*.25),.22,0,'aether',6)
                elif kind=='metalwall':
                    for x in (-1.35,1.35):
                        box('StoneFoot',root,(x,0,.18),(.55,.72,.36),'skin_dark')
                        box('IronPost',root,(x,0,1.05),(.24,.32,2.10),'iron')
                        taper('PostCap',root,(x,0,2.05),(x,0,2.35),.20,0,'silver')
                    for i in range(5):
                        x=(i-2)*.5;box('ForgedPlate',root,(x,0,1.0),(.47,.20,1.85),'iron')
                        box('RaisedPlateEdge',root,(x-.18,-.12,1.0),(.05,.05,1.7),'silver')
                        for z in (.3,1.6):ellipsoid('Rivet',root,(x,-.14,z),(.065,.03,.065),'gold',1)
                    box('CrossBrace',root,(0,.15,.85),(2.6,.10,.15),'copper')
                elif kind in ('stormspire','frostmortar'):
                    taper('OctagonalPlinth',root,(0,0,.0),(0,0,.3),1.1,.9,'iron',8)
                    for i in range(4):
                        a=i*pi/2;taper('Buttress',root,(cos(a)*.85,sin(a)*.85,.18),(cos(a)*.42,sin(a)*.42,1.35),.15,.10,'silver')
                    taper('TowerColumn',root,(0,0,.3),(0,0,1.6),.40,.32,'iron',8)
                    gun=empty('Turret',root,(0,0,1.6))
                    if kind=='stormspire':
                        for z in (.0,.22,.44):ring('CopperCoil',gun,(0,0,z),.52-z*.4,.065,'copper')
                        ellipsoid('AetherHeart',gun,(0,0,.82),(.33,.33,.45),'aether')
                        for i in range(3):
                            a=i*tau/3
                            taper('Conductor',gun,(cos(a)*.45,sin(a)*.45,.22),(cos(a)*.65,sin(a)*.65,1.13),.09,.05,'silver')
                            ellipsoid('ArcTerminal',gun,(cos(a)*.65,sin(a)*.65,1.13),(.12,.12,.12),'gold')
                    else:
                        for s in (-1,1):box('Trunnion',gun,(s*.45,0,.1),(.16,.55,.50),'copper')
                        taper('MortarBarrel',gun,(0,.32,0),(0,-.55,.7),.32,.40,'silver',12)
                        taper('DarkBore',gun,(0,-.55,.7),(0,-.57,.72),.30,.30,'black',12)
                        for x in (-.6,.6):ellipsoid('FrostReservoir',gun,(x,.3,-.05),(.2,.2,.34),'frost')
                        ring('AetherBelt',root,(0,0,1.15),.42,.07,'aether')
                elif kind.startswith('backpack'):
                    # Godot +Z is forward, Blender -Y is forward; bag sits behind dwarf.
                    frame=kind=='backpack_frame'
                    box('CanvasPack',root,(0,.34,1.02),(.70,.37,.66 if frame else .52),'pack')
                    box('LeatherFlap',root,(0,.55,1.18),(.72,.09,.28),'leather')
                    for x in (-.24,.24):
                        box('PackStrap',root,(x,.59,1.02),(.065,.045,.56),'gold')
                        ring('Buckle',root,(x,.62,.95),.06,.016,'silver',(pi/2,0,0))
                    if frame:
                        for x in (-.40,.40):box('IronFrame',root,(x,.41,1.06),(.06,.12,.92),'silver')
                        ellipsoid('Bedroll',root,(0,.4,1.49),(.46,.18,.17),'leather_light')
                elif kind=='armor_ironheart':
                    box('Breastplate',root,(0,-.33,1.0),(.62,.12,.44),'silver',(0,0,0))
                    for x in (-.23,.23):box('RaisedRib',root,(x,-.40,1.0),(.065,.04,.39),'gold')
                    ellipsoid('IronheartGem',root,(0,-.43,1.06),(.10,.035,.12),'aether',1)
                elif kind=='treasure_chest':
                    box('ChestBody',root,(0,0,.40),(1.28,.80,.62),'wood')
                    lid=empty('Lid',root,(0,.39,.70))
                    box('DomedLid',lid,(0,-.39,.10),(1.30,.82,.23),'leather_light')
                    for x in (-.49,.49):
                        box('LidBand',lid,(x,-.39,.23),(.08,.84,.07),'gold')
                        box('ChestBand',root,(x,-.415,.4),(.08,.05,.60),'gold')
                    box('LockPlate',root,(0,-.45,.56),(.22,.06,.23),'gold')
                    box('Keyhole',root,(0,-.49,.55),(.04,.015,.10),'black')
                    for x in (-.62,.62):ring('CarryHandle',root,(x,0,.48),.13,.026,'iron',(0,pi/2,0))
            results.append(fin['finish_asset'](kind,scene))
    finally:bpy.context.window.scene=previous
    return results
