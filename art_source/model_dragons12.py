"""Concept-guided Fort dragons. Continuous lofts, articulated wings, layered armor.
Reference: art_source/concepts/dragons12-reference.png. Preserves existing clip names.
"""
from pathlib import Path
from math import sin, cos, pi, tau
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]

def build():
    original=bpy.context.window.scene
    ns={'__name__':'dragon_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'ember12':'943f2f','emberlight12':'b65a3b','char12':'463c3e','bronze12':'b36a3e','belly12':'bba17a','horn12':'d8c6a0','ice12':'536d84','icelight12':'7d9bab','icearmor12':'bacdd1','iceweb12':'839aaf','eye12':'f4a737','pupil12':'211d25','mouth12':'3f232a'})
    empty,ellipsoid,mesh=[ns[k] for k in ['empty','ellipsoid','mesh']]
    fin={'__name__':'dragon_finish'};exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    anim={'__name__':'dragon_clips','__file__':str(ROOT/'art_source/model_wilderness11.py')};exec(compile((ROOT/'art_source/model_wilderness11.py').read_text(),'model_wilderness11.py','exec'),anim)
    def loft(name,parent,points,radii,color,sides=12,steps=4):
        pts=[Vector(p) for p in points];centers=[];sizes=[]
        for i in range(len(pts)-1):
            a,b,c,d=pts[max(0,i-1)],pts[i],pts[i+1],pts[min(len(pts)-1,i+2)]
            for j in range(steps):
                t=j/steps
                centers.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
                sizes.append((radii[i][0]*(1-t)+radii[i+1][0]*t,radii[i][1]*(1-t)+radii[i+1][1]*t))
        centers.append(pts[-1]);sizes.append(radii[-1]);v=[];f=[]
        for i,p in enumerate(centers):
            tangent=(centers[min(i+1,len(centers)-1)]-centers[max(0,i-1)]).normalized()
            side=tangent.cross(Vector((0,0,1)))
            if side.length<.01:side=tangent.cross(Vector((0,1,0)))
            side.normalize();up=side.cross(tangent).normalized()
            for j in range(sides):
                a=j*tau/sides;v.append(tuple(p+side*cos(a)*sizes[i][0]+up*sin(a)*sizes[i][1]))
        for i in range(len(centers)-1):
            for j in range(sides):
                a=i*sides+j;b=i*sides+(j+1)%sides;c=b+sides;d=a+sides
                f.extend([(a,b,c),(a,c,d)])
        f.append(tuple(reversed(range(sides))));f.append(tuple((len(centers)-1)*sides+j for j in range(sides)))
        obj=mesh(name,parent,v,f,color);obj['fort_smooth']=True;obj['fort_bevel']=.002
        # Correct winding on generated lofts before export.
        import bmesh
        bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
        return obj
    def plate(name,parent,pos,width,length,color,rotation=(0,0,0)):
        w=width;l=length
        obj=mesh(name,parent,[(-w,0,0),(-w*.7,-l*.55,.08),(0,-l,.02),(w*.7,-l*.55,.08),(w,0,0),(0,l*.18,.09),(0,-l*.3,.18)],[(0,1,6),(1,2,6),(2,3,6),(3,4,6),(4,5,6),(5,0,6),(5,4,3,2,1,0)],color)
        obj.location=pos;obj.rotation_euler=rotation;obj['fort_bevel']=.006
        return obj
    results=[]
    try:
        for key in ['emberdrake','frostwyrm']:
            scene=bpy.data.scenes.new('Fort12_'+key);bpy.context.window.scene=scene;root=empty(key)
            ice=key=='frostwyrm';skin='ice12' if ice else 'ember12';light='icelight12' if ice else 'emberlight12';armor='icearmor12' if ice else 'char12';web='iceweb12' if ice else 'bronze12';horn='icearmor12' if ice else 'horn12'
            loft('ContinuousTorso',root,[(0,1.9,1.1),(0,1.3,1.35),(0,.4,1.5),(0,-.5,1.7),(0,-.85,1.85)],[(.18,.22),(.62,.55),(.78,.70),(.70,.75),(.40,.48)],skin,16,5)
            loft('SculptedNeck',root,[(0,-.45,1.6),(0,-1.03,1.95),(0,-1.15,2.6),(0,-1.55,3.08),(0,-1.96,3.12)],[(.58,.60),(.48,.53),(.34,.42),(.31,.35),(.24,.27)],skin,14,6)
            # Broad overlapping throat shields follow the lifted neck.
            for i in range(7):
                t=i/6;plate('ThroatShield',root,(0,-1.10-.80*t,1.65+1.30*t),.39-.17*t,.30,'icearmor12' if ice else 'belly12',(pi/2-.35,0,0))
            for i in range(9):
                y=1.45-i*.32;plate('DorsalArmor',root,(0,y,1.92+max(0,-y)*.65),.27,.43,armor)
                loft('BackSpine',root,[(0,y,2.0+max(0,-y)*.65),(0,y+.12,2.33+max(0,-y)*.65),(0,y+.30,2.48+max(0,-y)*.65)],[(.12,.14),(.065,.065),(.004,.004)],armor,7,3)
            # Raised overlapping shoulder plates give the flanks a designed rhythm.
            for side in [-1,1]:
                for row in range(3):
                    for i in range(5):
                        plate('FlankScale',root,(side*(.48+row*.10),-.45+i*.37,1.85-row*.22),.19,.32,light if row==2 else armor,(0,side*(.45+row*.4),.12*side))
            head=empty('Head',root,(0,-1.85,3.12))
            loft('WedgeSkull',head,[(0,.19,0),(0,-.12,.07),(0,-.5,0),(0,-.91,-.11),(0,-1.07,-.17)],[(.25,.23),(.43,.31),(.36,.20),(.23,.13),(.10,.09)],skin,12,4)
            jaw=empty('Jaw',head,(0,-.12,-.19))
            loft('LowerJaw',jaw,[(0,.12,0),(0,-.3,-.10),(0,-.70,-.08),(0,-.94,-.01)],[(.26,.09),(.27,.10),(.19,.055),(.055,.025)],light,10,4)
            for side in [-1,1]:
                ellipsoid('RecessedEyeSocket',head,(side*.355,-.32,.15),(.115,.15,.095),armor,2)
                ellipsoid('AmberEye',head,(side*.40,-.38,.16),(.035,.080,.055),'icearmor12' if ice else 'eye12',2)
                ellipsoid('VerticalPupil',head,(side*.427,-.393,.16),(.011,.020,.045),'pupil12',1)
                loft('AngryBrow',head,[(side*.19,-.58,.22),(side*.39,-.35,.28),(side*.45,-.08,.23)],[(.07,.07),(.095,.07),(.03,.035)],armor,7,3)
                loft('CheekRidge',head,[(side*.22,-.72,-.05),(side*.41,-.22,-.04),(side*.49,.24,.12)],[(.06,.065),(.12,.10),(.012,.015)],light,8,3)
                ellipsoid('Nostril',head,(side*.17,-.84,-.02),(.032,.065,.025),'pupil12',1)
                loft('SweptCrownHorn',head,[(side*.30,.04,.25),(side*.43,.25,.49),(side*.58,.64,.63),(side*.54,.92,.81)],[(.14,.14),(.105,.105),(.065,.055),(.002,.002)],horn,10,5)
                loft('JawHorn',head,[(side*.36,.02,-.08),(side*.59,.34,-.04),(side*.68,.53,.04)],[(.10,.10),(.055,.055),(.002,.002)],armor,8,4)
                for i in range(5):
                    y=-.30-i*.115;loft('IvoryTooth',head,[(side*(.27-i*.022),y,-.16),(side*(.27-i*.022),y-.025,-.25)],[(.025,.024),(.001,.001)],horn,6,2)
                for i in range(3):plate('TempleScale',head,(side*.24,-.02+i*.17,.24),.16,.29,armor,(0,side*.3,side*.2))
            for i in range(3):plate('SnoutArmor',head,(0,-.35-i*.20,.23-i*.06),.22-i*.025,.26,light)
            for side in [-1,1]:
                for front in [True,False]:
                    leg=empty('Leg'+('F' if front else 'B')+('L' if side<0 else 'R'),root,(side*.55,-.52 if front else 1.18,1.48 if front else 1.3))
                    loft('ArticulatedLimb',leg,[(0,0,0),(side*.22,.18,-.35),(side*.32,.35,-.76),(side*.28,.02,-1.10),(side*.36,-.25,-1.22)],[(.28,.32),(.25,.29),(.16,.18),(.10,.12),(.13,.08)],skin,12,5)
                    plate('KneeGuard',leg,(side*.20,.05,-.38),.23,.39,armor,(.5,side*.4,0))
                    for toe in range(3):
                        x=side*.36+(toe-1)*.13
                        loft('SplayedToe',leg,[(x,-.12,-1.22),(x+(toe-1)*.04,-.37,-1.29),(x+(toe-1)*.06,-.55,-1.29)],[(.075,.075),(.06,.05),(.04,.035)],light,8,3)
                        loft('CurvedClaw',leg,[(x+(toe-1)*.06,-.48,-1.27),(x+(toe-1)*.07,-.67,-1.30),(x+(toe-1)*.07,-.70,-1.37)],[(.058,.045),(.03,.03),(.001,.001)],horn,8,3)
            tail=empty('Tail',root,(0,1.6,1.15))
            tailpath=[(0,0,0),(.12,.75,-.26),(.45,1.55,-.55),(.95,2.5,-.65),(1.5,3.25,-.35),(1.75,3.9,.18),(1.60,4.35,.35)]
            loft('FlowingTail',tail,tailpath,[(.40,.38),(.29,.27),(.20,.19),(.15,.14),(.10,.10),(.045,.05),(.004,.004)],skin,12,6)
            for i in range(1,6):
                x,y,z=tailpath[i];plate('TailPlate',tail,(x,y,z+.13),.20-i*.025,.34,armor,(0,0,pi))
                loft('TailSpine',tail,[(x,y,z+.12),(x,y+.15,z+.43),(x,y+.28,z+.50)],[(.095,.10),(.045,.04),(.002,.002)],armor,7,3)
            for side in [-1,1]:
                wing=empty('WingL' if side<0 else 'WingR',root,(side*.62,-.38,1.95))
                wrist=Vector((side*1.94,-.18,1.33))
                loft('MuscularWingArm',wing,[(0,0,0),(side*.82,.12,.43),(side*1.33,-.14,.98),tuple(wrist)],[(.18,.18),(.15,.15),(.10,.10),(.09,.09)],skin,10,5)
                ends=[Vector((side*3.75,.05,.65)),Vector((side*3.20,1.48,.08)),Vector((side*2.35,2.48,-.52)),Vector((side*.75,2.55,-.65))]
                for i,end in enumerate(ends):
                    mid=wrist.lerp(end,.53)+Vector((0,-.08,.12))
                    loft('WingFinger',wing,[tuple(wrist),tuple(mid),tuple(end)],[(.075,.07),(.045,.04),(.013,.013)],armor,8,5)
                    loft('WingTipClaw',wing,[tuple(end),tuple(end+Vector((side*.04,.12,-.12)))],[(.035,.03),(.001,.001)],horn,6,3)
                for panel in range(3):
                    verts=[];faces=[];segments=10;radial=6
                    for depth in [-.012,.012]:
                        for r in range(radial+1):
                            u=.025+.975*r/radial
                            for j in range(segments+1):
                                t=j/segments;end=ends[panel].lerp(ends[panel+1],t)
                                scallop=1-.20*sin(t*pi)*u*u
                                point=wrist+(end-wrist)*u*scallop
                                point.z+=sin(t*pi)*sin(u*pi)*.12+depth
                                verts.append(tuple(point))
                    layer=(segments+1)*(radial+1)
                    for r in range(radial):
                        for j in range(segments):
                            a=r*(segments+1)+j;b=a+1;c=b+segments+1;d=c-1
                            faces.extend([(a,b,c),(a,c,d),(a+layer,c+layer,b+layer),(a+layer,d+layer,c+layer)])
                    membrane=mesh('ScallopedMembrane',wing,verts,faces,web);membrane['fort_smooth']=True;membrane['fort_bevel']=.001
                loft('WingThumb',wing,[tuple(wrist),tuple(wrist+Vector((side*.10,-.23,.19))),tuple(wrist+Vector((side*.11,-.35,.11)))],[(.08,.08),(.04,.04),(.001,.001)],horn,8,4)
            anim['animate'](scene,root)
            results.append(fin['finish_asset'](key,scene,['Idle','Walk','Attack','Hit','Death']))
    finally:bpy.context.window.scene=original
    return results
