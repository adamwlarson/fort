"""Fort's woodland/ruins pass, modeled directly in Blender. Z up, -Y forward."""
from pathlib import Path
from math import pi, sin, cos, tau
import random
import bpy

ROOT=Path(__file__).resolve().parents[1]
_g={'__name__':'fort_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),_g)
_g['PALETTE'].update({'pine':'385e49','pine_light':'537859','leaf':'78944e','leaf_light':'a1ad60',
    'bark':'aeb5a6','bark_dark':'46534b','stone':'667780','stone_light':'889696',
    'moss':'687d4a','petal':'cda985','flower':'b7bed2','canvas':'bca578','ruin':'516970'})
empty,box,taper,ellipsoid,ring,mesh=[_g[k] for k in ('empty','box','taper','ellipsoid','ring','mesh')]

def pine(parent):
    taper('PineTrunk',parent,(0,0,0),(0.08,0,4.5),0.23,0.025,'wood',9)
    for side in (-1,1):
        taper('RootFlare',parent,(side*0.52,0.13,0.03),(0,0,0.6),0.12,0.16,'wood',6)
    for tier in range(5):
        z=1.25+tier*0.69
        radius=1.30-tier*0.21
        verts=[]
        for i in range(12):
            a=i*tau/12+tier*0.37
            r=radius*(1 if i%2==0 else 0.78)
            verts.append((sin(a)*r,cos(a)*r,z+(0 if i%2==0 else 0.16)))
        verts.append((0.04,0,z+1.3))
        faces=[(i,(i+1)%12,12) for i in range(12)]
        faces.append(tuple(reversed(range(12))))
        # Reverse the clockwise fan so the foliage has outward normals.
        faces=[tuple(reversed(f)) for f in faces]
        mesh('NeedleBough',parent,verts,faces,'pine' if tier%2==0 else 'pine_light')
        for i in range(3):
            a=i*tau/3+tier
            taper('BareTwig',parent,(0,0,z+0.20),(sin(a)*radius*0.82,cos(a)*radius*0.82,z+0.02),0.055,0.015,'wood',5)

def birch(parent):
    taper('BirchTrunk',parent,(0,0,0),(0.12,0,3.4),0.19,0.065,'bark',9)
    for i in range(10):
        z=0.24+i*0.26
        box('BarkMark',parent,((-1 if i%2 else 1)*0.065,-0.15+z*0.026,z),(0.17 if i%3 else 0.26,0.018,0.038),'bark_dark',(0,0.12,0))
    for i in range(6):
        a=i*2.4
        pos=(sin(a)*0.63,cos(a)*0.51,2.4+(i%3)*0.48)
        taper('BirchBranch',parent,(0.05,0,1.6+i*0.16),pos,0.075,0.025,'bark',7)
        ellipsoid('AutumnCrown',parent,pos,(0.75,0.63,0.79),'leaf' if i%2 else 'leaf_light',1)
    ellipsoid('TopCrown',parent,(0.1,0,3.7),(0.63,0.56,0.8),'leaf_light',1)

def fern(parent):
    for frond in range(7):
        a=frond*tau/7
        tip=(sin(a)*0.66,cos(a)*0.66,0.18)
        taper('FrondStem',parent,(0,0,0.06),tip,0.012,0.004,'pine_light',4)
        for i in range(1,6):
            t=i/6
            x,y=sin(a)*t*0.64,cos(a)*t*0.64
            z=sin(t*pi)*0.26+0.10
            for side in (-1,1):
                w=0.15*(1-t*0.65)
                verts=[(x,y,z),(x+cos(a)*side*w-sin(a)*0.08,y-sin(a)*side*w-cos(a)*0.08,z-0.025),
                       (x+sin(a)*0.14,y+cos(a)*0.14,z+0.03)]
                mesh('FernLeaf',parent,verts,[(0,1,2)],'pine_light' if i%2 else 'moss')

def flowers(parent):
    for i in range(5):
        a=i*2.4
        x,y=sin(a)*0.23,cos(a)*0.23
        h=0.23+(i%3)*0.09
        taper('FlowerStem',parent,(x,y,0),(x+0.04,y,h),0.011,0.007,'pine_light',5)
        for petal in range(5):
            p=petal*tau/5
            ellipsoid('Petal',parent,(x+0.04+sin(p)*0.065,y+cos(p)*0.065,h),(0.065,0.042,0.027),'flower' if i%2 else 'petal',1)
        ellipsoid('Pollen',parent,(x+0.04,y,h+0.024),(0.027,0.027,0.02),'gold',1)

def moss_rock(parent):
    ellipsoid('GraniteMass',parent,(0,0,0.45),(1.05,0.78,0.68),'stone',1)
    ellipsoid('SplitBoulder',parent,(0.60,0.13,0.21),(0.49,0.47,0.40),'stone_light',1)
    ellipsoid('MossCap',parent,(-0.16,0.02,0.92),(0.65,0.48,0.12),'moss',1)
    for i in range(3):
        x=-0.42+i*0.28
        taper('RockVein',parent,(x,-0.61,0.33),(x+0.20,-0.47,0.82),0.024,0.018,'stone_light',4)

def ruin_arch(parent):
    for side in (-1,1):
        box('PillarFoot',parent,(side*1.42,0,0.18),(1.01,1.00,0.36),'ruin')
        for i in range(5):
            box('AncientBlock',parent,(side*1.42,(i%2)*0.035,0.6+i*0.48),(0.74,0.78,0.43),'stone' if i%2 else 'ruin',(0,0,(i%3-1)*0.025))
        box('CarvedCap',parent,(side*1.42,0,2.85),(1.00,0.95,0.20),'stone_light')
        for z in (1.25,1.7):
            box('RuneStem',parent,(side*1.42,-0.41,z),(0.07,0.026,0.27),'teal')
            box('RuneArm',parent,(side*1.37,-0.41,z+0.06),(0.17,0.026,0.05),'teal',(0,0.6,0))
    for i in range(7):
        x=(i-3)*0.40
        box('ArchStone',parent,(x,0,3.15+0.23*(1-abs(x)/1.3)),(0.38,0.82,0.58),'stone_light' if i==3 else 'stone',(0,x*0.12,0))
    for side in (-1,1):
        ellipsoid('FootMoss',parent,(side*1.7,-0.30,0.35),(0.50,0.31,0.10),'moss',1)

def waystone(parent):
    taper('StandingStone',parent,(0,0,0),(0.06,0,1.95),0.50,0.26,'ruin',5)
    for i in range(3):
        box('InlaidRune',parent,(0,-0.33+i*0.02,0.7+i*0.33),(0.055,0.04,0.24),'glass')
        box('RuneBranch',parent,(0.05,-0.33+i*0.02,0.77+i*0.33),(0.16,0.04,0.05),'glass',(0,0.6,0))
    ring('StoneCollar',parent,(0,0,0.23),0.48,0.065,'stone')

def cart(parent):
    for i in range(5):box('BedPlank',parent,((i-2)*0.20,0,0.61),(0.18,1.50,0.10),'wood')
    taper('Axle',parent,(-0.85,0,0.44),(0.85,0,0.44),0.075,0.075,'iron')
    for side in (-1,1):
        wheel=empty('WagonWheel',parent,(side*0.73,0,0.45))
        ring('WheelRim',wheel,(0,0,0),0.43,0.055,'wood',(0,pi/2,0))
        ring('IronTyre',wheel,(0,0,0),0.47,0.024,'iron',(0,pi/2,0))
        for i in range(6):
            a=i*tau/6
            taper('WheelSpoke',wheel,(0,0,0),(0,sin(a)*0.42,cos(a)*0.42),0.028,0.022,'leather_light',4)
        taper('Hub',wheel,(-0.08,0,0),(0.08,0,0),0.09,0.09,'iron')
        for i in range(3):box('WagonRail',parent,(side*0.55,0,0.84+i*0.22),(0.08,1.57,0.15),'wood')
        taper('Drawbar',parent,(side*0.4,-0.64,0.56),(side*0.4,-2.1,0.40),0.047,0.037,'wood',4)
    for i in range(4):ellipsoid('QuarriedStone',parent,((i%2-0.5)*0.50,(i//2-0.5)*0.55,0.86),(0.35,0.36,0.30),'stone',1)

def tent(parent):
    for y in (-0.95,0.95):taper('TentPole',parent,(0,y,0),(0,y,1.83),0.052,0.038,'wood')
    taper('RidgePole',parent,(0,-1.12,1.85),(0,1.12,1.85),0.046,0.046,'wood')
    for side in (-1,1):
        mesh('CanvasSheet',parent,[(0,-1,1.80),(0,1,1.80),(side*1.17,1,0.12),(side*1.17,-1,0.12)],[(0,1,2,3)],'canvas')
        for y in (-1,1):
            taper('GuyRope',parent,(side*1.06,y,0.3),(side*1.5,y*1.1,0.05),0.013,0.013,'leather_light',4)
            taper('TentPeg',parent,(side*1.5,y*1.1,0),(side*1.48,y*1.1,0.17),0.025,0.022,'wood')
        mesh('OpenFlap',parent,[(0,-1.02,1.78),(side*0.99,-1.05,0.2),(side*0.52,-0.84,0.26)],[(0,1,2)],'teal')
    box('Bedroll',parent,(0,0.25,0.09),(0.56,1.30,0.12),'hood')

def cliff(parent):
    xs=(-3.8,-2.5,-1.35,0,1.3,2.5,3.8)
    heights=(0.45,2.8,4.15,5.3,4.0,2.6,0.50)
    verts=[]
    for row in range(4):
        for i,x in enumerate(xs):
            if row==0:verts.append((x,-1.3,-0.15))
            elif row==1:verts.append((x*0.92,-0.70,heights[i]*0.64))
            elif row==2:verts.append((x*0.78,0.12+(i%2)*0.3,heights[i]))
            else:verts.append((x,1.4,-0.15))
    faces=[]
    for row in range(3):
        for i in range(6):
            a=row*7+i;b=a+1;c=a+8;d=a+7
            faces.extend([(a,b,c),(a,c,d)])
    faces.extend([(0,7,14,21),(6,27,20,13),(0,21,27,6)])
    rock=mesh('BrokenRidgeline',parent,verts,faces,'stone')
    rock.data.materials.append(_g['material']('ruin'))
    rock.data.materials.append(_g['material']('stone_light'))
    for i,polygon in enumerate(rock.data.polygons):polygon.material_index=1 if i%5==0 else (2 if i%7==0 else 0)
    for i in range(5):
        ellipsoid('TalusStone',parent,((i-2)*1.2,-0.9,0.14),(0.95,0.62,0.7),'stone' if i%2 else 'stone_light',1)

def tree_clips(root):
    root.rotation_mode='XYZ'
    for clip in ('Idle','Hit','Destruction'):
        root.animation_data_create()
        root.animation_data.action=None
        for frame in (1,7,13,19,25):
            t=(frame-1)/24
            root.rotation_euler=(0,0,0)
            if clip=='Idle':root.rotation_euler.x=sin(t*tau)*0.018
            elif clip=='Hit':root.rotation_euler.x=sin(t*pi)*0.12
            else:root.rotation_euler.y=t*t*1.45
            root.keyframe_insert(data_path='rotation_euler',frame=frame)
        action=root.animation_data.action
        action.name=root.name+'_'+clip
        track=root.animation_data.nla_tracks.new()
        track.name=clip
        track.strips.new(clip,1,action)
        root.animation_data.action=None
        root.rotation_euler=(0,0,0)

def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),ns)
    results=[]
    try:
        for key,builder in [('pine_tree',pine),('birch_tree',birch),('fern',fern),('wildflowers',flowers),('moss_rock',moss_rock),('ruin_arch',ruin_arch),('waystone',waystone),('quarry_cart',cart),('camp_tent',tent),('cliff_chunk',cliff)]:
            scene=bpy.data.scenes.new('Fort_World_'+key)
            bpy.context.window.scene=scene
            root=empty(key)
            builder(root)
            clips=[]
            if key.endswith('_tree'):
                tree_clips(root)
                clips=['Idle','Hit','Destruction']
            results.append(ns['finish_asset'](key,scene,clips))
    finally:
        bpy.context.window.scene=original
    return results

if __name__=='__main__':print(build())
