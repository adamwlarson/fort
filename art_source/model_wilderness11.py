"""Fort 11 wilderness models; new scenes only, preserving the open tree scene."""
from pathlib import Path
from math import pi, sin, cos, tau
import bpy
ROOT=Path(__file__).resolve().parents[1]
CREATURES=['razorback','direwolf','stonebear','emberdrake','frostwyrm']
KEYS=CREATURES+['beast_den','dragon_nest','bandit_totem','forgotten_shrine','wrecked_caravan','ruined_observatory','trail_sign']

def animate(scene, root):
    movers=[root]+[o for o in scene.objects if o.type=='EMPTY' and o!=root]
    rests={o:(o.location.copy(),o.rotation_euler.copy(),o.scale.copy()) for o in movers}
    for clip in ['Idle','Walk','Attack','Hit','Death']:
        for obj in movers:
            loc,rot,scale=rests[obj];obj.rotation_mode='XYZ';obj.animation_data_create();obj.animation_data.action=None
            for index,frame in enumerate([1,7,13,19,25]):
                phase=(frame-1)/24;name=obj.name.split('.')[0]
                obj.location,obj.rotation_euler,obj.scale=loc,rot,scale
                if clip=='Walk':
                    if name.startswith('Leg'):obj.rotation_euler.x+=sin(phase*tau+(pi if name in ['LegFR','LegBL'] else 0))*.48
                    if name.startswith('Wing'):obj.rotation_euler.y+=sin(phase*tau)*.25*(1 if name=='WingL' else -1)
                    if obj==root:obj.location.z+=abs(sin(phase*tau))*.07
                elif clip=='Idle':
                    if obj==root:obj.scale.z*=1+sin(phase*tau)*.016
                    if name.startswith('Wing'):obj.rotation_euler.y+=sin(phase*tau)*.07
                elif clip=='Attack':
                    if name=='Head':obj.rotation_euler.x+=[0,-.3,.5,.1,0][index]
                    if name=='Jaw':obj.rotation_euler.x+=[0,.1,.55,.3,0][index]
                    if name.startswith('Wing'):obj.rotation_euler.y+=sin(phase*pi)*.5*(1 if name=='WingL' else -1)
                    if obj==root:obj.location.y-=sin(phase*pi)*.3
                elif clip=='Hit' and obj==root:obj.rotation_euler.x+=sin(phase*pi)*.14
                elif clip=='Death' and obj==root:obj.rotation_euler.y+=phase*1.5;obj.location.z-=phase*.3
                if name=='Tail' and clip in ['Idle','Walk']:obj.rotation_euler.z+=sin(phase*tau)*.12
                for path in ['location','rotation_euler','scale']:obj.keyframe_insert(data_path=path,frame=frame)
            action=obj.animation_data.action;action.name=root.name+'_'+clip+'_'+obj.name
            track=obj.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action)
            obj.animation_data.action=None;obj.location,obj.rotation_euler,obj.scale=loc,rot,scale

def build():
    original=bpy.context.window.scene
    ns={'__name__':'wild11_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'ember':'a54e35','membrane':'d48749','ice':'79aebd','icewing':'afcdd3','fur':'765a40','wolf':'738189','stone':'667474','leaf':'4b7355','rune':'94d4d5'})
    empty,box,taper,ring,ellipsoid,mesh=[ns[k] for k in ['empty','box','taper','ring','ellipsoid','mesh']]
    fin={'__name__':'wild11_finish'};exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    results=[]
    try:
        for key in KEYS:
            scene=bpy.data.scenes.new('Fort11_'+key);bpy.context.window.scene=scene;root=empty(key)
            if key in CREATURES:
                dragon=key in ['emberdrake','frostwyrm'];bear=key=='stonebear';boar=key=='razorback'
                skin='ember' if key=='emberdrake' else ('ice' if dragon else ('fur' if boar or bear else 'wolf'))
                height=1.7 if dragon else (1.0 if bear else .7)
                length=1.5 if dragon else (.85 if bear else .8)
                ellipsoid('MuscularBody',root,(0,.15,height),(.85 if dragon else .6,length,.72 if dragon or bear else .47),skin,2)
                ellipsoid('Shoulders',root,(0,-length*.6,height+.12),(.9 if dragon else .66,.6,.78 if bear else .56),skin,2)
                head=empty('Head',root,(0,-length*.8,height+.35))
                ellipsoid('Skull',head,(0,-.35,.06),(.56 if dragon else .4,.6 if dragon else .4,.42),skin,2)
                ellipsoid('LongMuzzle',head,(0,-.9 if dragon else -.65,-.1),(.34,.57 if dragon else .35,.23),'bone' if boar else skin,2)
                jaw=empty('Jaw',head,(0,-.25,-.28));ellipsoid('LowerJaw',jaw,(0,-.55,-.04),(.3,.65 if dragon else .37,.13),skin,1)
                for side in [-1,1]:
                    ellipsoid('BrightEye',head,(side*.36,-.59,.22),(.10,.075,.085),'eye' if not dragon else 'rune',2)
                    taper('Brow',head,(side*.27,-.69,.32),(side*.48,-.27,.31),.12,.07,skin)
                    taper('HornOrEar',head,(side*.37,-.1,.3),(side*.63,.28,.95 if dragon else .75),.18,0,'bone' if dragon else skin)
                    for y in [-.7,-.95]:taper('Fang',head,(side*.23,y,-.15),(side*.23,y,-.42),.055,0,'bone')
                    if boar:
                        taper('CurvedTuskBase',head,(side*.3,-.74,-.23),(side*.57,-.92,-.05),.12,.07,'bone')
                        taper('CurvedTuskTip',head,(side*.57,-.92,-.05),(side*.5,-1.0,.25),.07,0,'bone')
                for index,(x,y) in enumerate([(-.6,-.65),(.6,-.65),(-.55,.85),(.55,.85)]):
                    leg=empty(['LegFL','LegFR','LegBL','LegBR'][index],root,(x,y,height*.7))
                    taper('UpperLeg',leg,(0,0,0),(x*.12,.12,-height*.4),.24,.16,skin)
                    taper('Shin',leg,(x*.12,.12,-height*.4),(x*.18,-.09,-height*.7+.14),.16,.11,skin)
                    ellipsoid('Paw',leg,(x*.18,-.2,-height*.7+.14),(.22,.32,.14),'black',1)
                    for dx in [-.12,0,.12]:taper('Claw',leg,(x*.18+dx,-.37,-height*.7+.14),(x*.18+dx,-.58,-height*.7+.1),.045,0,'bone',5)
                tail=empty('Tail',root,(0,length,height))
                taper('TailBase',tail,(0,0,0),(.25,1.1,-.15),.3 if dragon else .19,.12,skin)
                taper('TailTip',tail,(.25,1.1,-.15),(.7,2.5 if dragon else 1.5,.2),.12,0,skin)
                for i in range(6 if dragon else 4):
                    y=-.7+i*.4;taper('DorsalSpine',root,(0,y,height+.5),(0,y+.2,height+.9),.16,0,'bone' if dragon or boar else 'stone')
                if bear:
                    for x in [-.52,0,.52]:ellipsoid('StoneArmor',root,(x,-.2,1.5),(.38,.6,.26),'stone',1)
                if dragon:
                    for side in [-1,1]:
                        wing=empty('WingL' if side<0 else 'WingR',root,(side*.65,-.05,2.05))
                        pts=[(0,0,0),(side*1.3,-.9,.85),(side*4.0,-.6,.5),(side*3.0,.65,-.1),(side*1.9,1.5,-.35),(0,.9,-.1)]
                        mesh('WingMembrane',wing,pts,[(0,1,2),(0,2,3),(0,3,4),(0,4,5)],'membrane' if key=='emberdrake' else 'icewing')
                        for a,b in [(0,1),(1,2),(1,3),(1,4),(0,5)]:taper('WingFinger',wing,pts[a],pts[b],.09,.04,skin,7)
                        taper('WingClaw',wing,pts[1],(side*1.55,-1.2,1.2),.10,0,'bone')
                    for y in [-.65,-.25,.15,.55]:ellipsoid('BellyPlate',root,(0,y,1.14),(.76,.2,.24),'gold' if key=='emberdrake' else 'bone',1)
                animate(scene,root)
            elif key=='beast_den':
                for i in range(7):
                    a=i*pi/6;ellipsoid('CaveStone',root,(cos(a)*3,1.8,sin(a)*3.3),(.95,1.5,1.0),'stone',1)
                ellipsoid('CaveShadow',root,(0,2.75,1.2),(2.6,.15,1.65),'black',1)
                for x in [-1.5,1.5]:taper('ScatteredBone',root,(x,-1,.12),(x+.8,-.5,.18),.09,.07,'bone')
                for x in [-2.4,2.4]:ellipsoid('Moss',root,(x,1,2),(.8,.8,.25),'leaf',1)
            elif key=='dragon_nest':
                for i in range(14):
                    a=i*tau/14;ellipsoid('RimStone',root,(sin(a)*5,cos(a)*5,.35),(.9,.8,.5),'stone',1)
                    if i%2==0:taper('Rib',root,(sin(a)*4,cos(a)*4,.3),(sin(a)*4.6,cos(a)*4.6,2.1),.18,.035,'bone')
                for x,y in [(-1,0),(1,.4),(.1,1.6)]:ellipsoid('DragonEgg',root,(x,y,.8),(.6,.55,.85),'ice',2)
                for i in range(22):
                    a=i*2.4;ellipsoid('HoardGold',root,(sin(a)*2.8,cos(a)*2.8,.16),(.38,.45,.13),'gold',1)
            elif key=='bandit_totem':
                taper('TotemPole',root,(0,0,0),(0,0,6),.3,.19,'wood')
                box('Crossbar',root,(0,0,4.5),(4,.25,.3),'wood')
                for side in [-1,1]:
                    box('HangingBanner',root,(side*1.25,-.04,3.4),(.9,.08,2),'cloth')
                    taper('BannerFang',root,(side*1.25,-.1,3.8),(side*1.25,-.1,2.9),.23,0,'bone',3)
                ellipsoid('Skull',root,(0,-.1,5.4),(.75,.55,.55),'bone',1)
                for side in [-1,1]:taper('SkullHorn',root,(side*.5,0,5.5),(side*1.1,0,6.3),.18,0,'bone')
            elif key=='forgotten_shrine':
                for z,r in [(.15,2.5),(.45,1.9),(.75,1.3)]:taper('AltarStep',root,(0,0,z-.15),(0,0,z+.15),r,r,'stone')
                taper('FloatingCrystal',root,(0,0,1.4),(0,0,4.4),.62,0,'rune',6)
                for x in [-2.8,2.8]:
                    taper('RunePillar',root,(x,0,0),(x,0,5),.45,.3,'stone')
                    for z in [1.2,2.2,3.2]:box('Glyph',root,(x,-.34,z),(.14,.04,.4),'rune',(0,.4,0))
                ring('SacredOrbit',root,(0,0,2.5),1.55,.10,'gold',(pi/2,0,0))
            elif key=='wrecked_caravan':
                box('WagonBed',root,(0,0,.8),(2.5,4,.22),'wood',(0,.12,.10))
                for x in [-1.2,1.2]:
                    for y in [-1.2,1.2]:
                        ring('BrokenWheel',root,(x,y,.6),.7,.12,'wood',(0,pi/2,0))
                        taper('Axle',root,(-1.4,y,.6),(1.4,y,.6),.10,.10,'iron')
                    for z in [1.05,1.4]:box('SideBoard',root,(x,0,z),(.14,3.8,.23),'wood')
                for x,y in [(-.5,-.6),(.4,.8)]:box('CargoCrate',root,(x,y,1.4),(.85,.85,.85),'leather_light')
                taper('SnappedShaft',root,(.7,-1.7,.8),(1,-4,.25),.1,.06,'wood')
            elif key=='ruined_observatory':
                for side in [-1,1]:
                    for depth in [-1,1]:
                        x=side*3;y=depth*3
                        taper('AncientColumn',root,(x,y,0),(x,y,7 if side<0 else 5),.55,.42,'stone')
                        box('Capital',root,(x,y,5),(1.3,1.3,.4),'stone')
                box('BrokenLintel',root,(-3,0,7),(1.3,7,.5),'stone')
                ring('StarDial',root,(0,0,1.3),2,.12,'gold',(pi/4,0,0))
                for i in range(8):
                    a=i*tau/8;taper('DialRay',root,(0,0,1.3),(sin(a)*2,cos(a)*1.4,1.3+cos(a)*1.4),.055,.035,'gold')
                for i in range(5):ellipsoid('FallenMasonry',root,(-3+i*1.3,4,.5),(.8,.6,.5),'stone',1)
            else:
                taper('Post',root,(0,0,0),(0,0,2.6),.1,.07,'wood')
                box('ArrowSign',root,(.35,0,2.1),(1.5,.14,.45),'wood')
                taper('ArrowPoint',root,(.9,0,2.1),(1.4,0,2.1),.35,0,'gold',3)
                ring('TrailRune',root,(.1,-.08,2.1),.15,.03,'rune',(pi/2,0,0))
            results.append(fin['finish_asset'](key,scene,['Idle','Walk','Attack','Hit','Death'] if key in CREATURES else None))
    finally:bpy.context.window.scene=original
    return results
