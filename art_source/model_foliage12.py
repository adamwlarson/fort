"""Fort 12 woodland kit. Separate Blender scenes; original open scene is preserved."""
from pathlib import Path
from math import sin, cos, pi, tau
import random
import bpy
ROOT=Path(__file__).resolve().parents[1]
KEYS=['elder_oak','amber_tree','spore_tree','woodland_brush','bluebell_patch','forest_floor','dry_sedge','frost_shrub']

def build():
    original=bpy.context.window.scene
    ns={'__name__':'foliage_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'bark12':'594638','barklight12':'8b7050','leaf12':'426747','sunleaf12':'769650','amber12':'ba7735','goldleaf12':'d1a749','moss12':'657c43','violet12':'7272b3','pale12':'b1c5cb','spore12':'a78eae','gill12':'d9bda2','sedge12':'a3905d'})
    empty,taper,ellipsoid,mesh=[ns[k] for k in ['empty','taper','ellipsoid','mesh']]
    fin={'__name__':'foliage_finish'};exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    motion={'__name__':'foliage_motion','__file__':str(ROOT/'art_source/model_world.py')}
    exec(compile((ROOT/'art_source/model_world.py').read_text(),'model_world.py','exec'),motion)
    results=[]
    try:
        for key in KEYS:
            scene=bpy.data.scenes.new('Fort12_'+key);bpy.context.window.scene=scene;root=empty(key);rng=random.Random(1212)
            def leaf(name,pos,length,width,angle,color):
                x,y,z=pos;dx,dy=sin(angle),cos(angle);sx,sy=cos(angle),-sin(angle)
                v=[(x,y,z),(x+dx*length*.48+sx*width,y+dy*length*.48+sy*width,z+.07),(x+dx*length,y+dy*length,z+.10),(x+dx*length*.48-sx*width,y+dy*length*.48-sy*width,z+.07),(x+dx*length*.48,y+dy*length*.48,z+.15)]
                v.append((x+dx*length*.48,y+dy*length*.48,z+.035))
                mesh(name,root,v,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(5,1,0),(5,2,1),(5,3,2),(5,0,3)],color)
            if key in ['elder_oak','amber_tree']:
                amber=key=='amber_tree';taper('RidgedTrunk',root,(0,0,0),(.18,.05,4.1),.40,.13,'bark12',10)
                for i in range(7):
                    a=i*tau/7;taper('ButtressRoot',root,(sin(a)*.85,cos(a)*.85,.05),(0,0,.85),.13,.24,'bark12',6)
                    taper('BarkRidge',root,(sin(a)*.34,cos(a)*.34,.45),(.16+sin(a)*.15,cos(a)*.15,3.65),.045,.025,'barklight12',5)
                for i in range(9):
                    a=i*2.399;z=2.6+(i%3)*.65;r=1.1 if i<6 else .6
                    tip=(sin(a)*r,cos(a)*r,z+.5)
                    taper('Branch',root,(.1,0,1.6+i*.18),tip,.15,.035,'bark12',7)
                    for j in range(3):
                        p=(tip[0]+sin(a+j*2)*.4,tip[1]+cos(a+j*2)*.4,tip[2]+j*.16)
                        ellipsoid('LeafMass',root,p,(.7,.66,.42),'amber12' if amber and j%2 else ('goldleaf12' if amber else ('leaf12' if j%2 else 'sunleaf12')),1)
                        for k in range(4):leaf('CrownSpray',(p[0]+sin(k*1.7)*.58,p[1]+cos(k*1.7)*.58,p[2]+.15),.4,.13,k*1.7,'goldleaf12' if amber else 'sunleaf12')
                for i in range(4):ellipsoid('TrunkMoss',root,(sin(i)*.3,cos(i)*.3,.20+i*.12),(.28,.24,.08),'moss12',1)
            elif key=='spore_tree':
                taper('TwistingStem',root,(0,0,0),(.2,0,3.7),.35,.23,'gill12',10)
                for z,r in [(3.7,1.65),(2.0,.75)]:
                    center=(.2 if z>3 else -.4,0,z)
                    ellipsoid('VelvetCap',root,center,(r,r,.55),'spore12',2)
                    for i in range(16):
                        a=i*tau/16;taper('RadialGill',root,(center[0],0,z-.35),(center[0]+sin(a)*r*.87,cos(a)*r*.87,z-.16),.032,.02,'gill12',4)
                    for i in range(13):
                        a=i*2.4;rr=r*rng.uniform(.2,.83)
                        ellipsoid('CapFreckle',root,(center[0]+sin(a)*rr,cos(a)*rr,z+.48*(1-rr/r*.55)),(.10,.12,.035),'pale12',1)
                for i in range(5):
                    a=i*2.4;taper('MyceliumRoot',root,(0,0,.18),(sin(a)*.9,cos(a)*.9,.03),.08,.02,'gill12',5)
            elif key in ['woodland_brush','frost_shrub']:
                frost=key=='frost_shrub'
                for i in range(9):
                    a=i*2.4;h=rng.uniform(.35,.9);tip=(sin(a)*.55,cos(a)*.55,h)
                    taper('WoodyStem',root,(0,0,.03),tip,.024,.009,'barklight12',5)
                    for j in range(3):
                        t=.35+j*.22;p=(tip[0]*t,tip[1]*t,tip[2]*t)
                        for side in [-1,1]:leaf('PointedLeaf',p,.29,.085,a+side*1.05,'pale12' if frost else ('leaf12' if j%2 else 'sunleaf12'))
                    if i%2==0:
                        for j in range(3):ellipsoid('Berry',root,(tip[0]+j*.04,tip[1],tip[2]),(.045,.045,.045),'violet12' if frost else 'amber12',1)
            elif key=='bluebell_patch':
                for i in range(9):
                    a=i*2.4;x,y=sin(a)*.48,cos(a)*.48;h=rng.uniform(.3,.6)
                    taper('Stem',root,(x,y,0),(x+.07,y,h),.009,.005,'leaf12',4)
                    leaf('BasalLeaf',(x,y,.04),.32,.045,a,'sunleaf12')
                    for j in range(3):
                        z=h-j*.08;taper('HangingBell',root,(x+.08,y,z+.02),(x+.15,y,z-.075),.022,.058,'violet12',6)
                        ellipsoid('BellLip',root,(x+.15,y,z-.08),(.06,.06,.015),'pale12',1)
            elif key=='forest_floor':
                for i in range(20):
                    a=i*2.4;r=rng.uniform(.1,.9);leaf('FallenLeaf',(sin(a)*r,cos(a)*r,.015),rng.uniform(.12,.25),.065,a,'sedge12' if i%3 else 'amber12')
                taper('FallenBranch',root,(-.65,.1,.06),(.7,-.15,.07),.065,.022,'bark12',7)
                taper('BrokenTwig',root,(0,0,.06),(.24,.38,.08),.025,.005,'bark12',5)
                for x,y,h in [(-.3,.15,.18),(-.15,.26,.25),(.0,.21,.12)]:
                    taper('MushroomStem',root,(x,y,0),(x,y,h),.025,.021,'gill12',5)
                    ellipsoid('MushroomCap',root,(x,y,h),(.12,.12,.055),'amber12',1)
            else:
                for i in range(20):
                    a=i*2.4;h=rng.uniform(.3,.7);x,y=sin(a)*.35,cos(a)*.35
                    leaf('SedgeBlade',(0,0,.02),.48,.025,a,'sedge12')
                    taper('SeedStem',root,(x*.4,y*.4,0),(x,y,h),.009,.004,'sedge12',4)
                    ellipsoid('SeedHead',root,(x,y,h),(.035,.035,.12),'goldleaf12',1)
            for obj in scene.objects:
                if obj.type=='MESH':obj['fort_bevel']=.003
            clips=[]
            if key in ['elder_oak','amber_tree','spore_tree']:
                motion['tree_clips'](root);clips=['Idle','Hit','Destruction']
            results.append(fin['finish_asset'](key,scene,clips))
    finally:bpy.context.window.scene=original
    return results
