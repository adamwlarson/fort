"""Fort 4 enemies. New scenes only; preserve the user's active scene."""
from pathlib import Path
import bpy
from math import sin, cos, pi, tau
ROOT = Path(__file__).resolve().parents[1]

def build():
    original = bpy.context.window.scene
    ns = {'__name__':'fort_geometry', '__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(), 'model_raiders.py','exec'), ns)
    ns['PALETTE'].update({'wing':'784751','vein':'b37968','ash':'485866','ember':'e99547'})
    empty, ellipsoid, taper, mesh, box, ring = [ns[k] for k in ('empty','ellipsoid','taper','mesh','box','ring')]
    finish = {'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),finish)
    results=[]
    try:
        for kind in ('ashwing','emberrunner'):
            if kind == 'emberrunner':
                scene=ns['enemy']('raider')
                scene.name='Fort4_EmberRunner'
                root=next(o for o in scene.objects if o.parent is None)
                root.name=kind
                # Distinct ember crest, armored face and three glowing furnace vents.
                head=next(o for o in scene.objects if o.name.split('.')[0]=='Head')
                box('RunnerFaceplate',head,(0,-.39,.16),(.43,.10,.26),'iron')
                for s in (-1,1):
                    box('HotEyeSlit',head,(s*.13,-.448,.20),(.12,.024,.045),'ember')
                    taper('SweptCrest',head,(s*.27,.08,.43),(s*.36,.47,.66),.10,.01,'ember')
                box('FurnacePack',root,(0,.38,1.02),(.68,.34,.68),'iron')
                for x in (-.22,0,.22):
                    box('EmberVent',root,(x,.565,1.03),(.11,.025,.45),'ember')
                    taper('Exhaust',root,(x,.41,1.30),(x,.48,1.56),.065,.085,'copper')
                ring('FurnaceBand',root,(0,.38,1.0),.37,.035,'gold')
                root.scale=(.9,.9,1.03)
                # Reuse the authored biped exporter while keeping the new identity.
                results.append(finish['finish_asset'](kind,scene))
                continue
            scene=bpy.data.scenes.new('Fort4_Ashwing');bpy.context.window.scene=scene
            root=empty(kind)
            ellipsoid('FlightTorso',root,(0,0,.64),(.30,.31,.45),'ash')
            ellipsoid('BreastPlating',root,(0,-.25,.70),(.23,.10,.29),'iron',1)
            ellipsoid('BatHead',root,(0,-.08,1.16),(.30,.25,.27),'ash')
            ellipsoid('Muzzle',root,(0,-.29,1.07),(.20,.12,.12),'skin_dark',1)
            for side in (-1,1):
                taper('TallBatEar',root,(side*.21,-.03,1.31),(side*.36,.04,1.76),.13,.005,'ash')
                taper('EarLining',root,(side*.22,-.10,1.36),(side*.34,-.025,1.67),.07,.003,'wing')
                ellipsoid('MoltenEye',root,(side*.13,-.291,1.23),(.075,.035,.052),'ember')
                taper('Fang',root,(side*.13,-.36,1.08),(side*.12,-.36,.94),.035,0,'bone')
                wing=empty('WingL' if side<0 else 'WingR',root,(side*.22,.02,.91))
                verts=[(0,0,0),(side*.60,-.10,.34),(side*1.38,-.01,.54),(side*1.92,.22,.29),(side*1.25,.38,-.05),(side*1.02,.57,-.38),(side*.59,.48,-.15),(side*.28,.54,-.54),(0,.20,-.33)]
                # Solid double-sided scalloped sail with visible finger spars.
                vertices=verts+[(x,y+.035,z) for x,y,z in verts]
                faces=[(0,i,i+1) for i in range(1,8)]+[(9,9+i+1,9+i) for i in range(1,8)]
                faces += [(i,(i+1)%9,(i+1)%9+9,i+9) for i in range(9)]
                mesh('ScallopedMembrane',wing,vertices,faces,'wing')
                for a,b in [(0,1),(1,2),(2,3),(1,4),(1,5),(0,6),(0,7)]:
                    taper('WingFinger',wing,verts[a],verts[b],.052,.016,'vein')
                taper('WingThumb',wing,verts[1],(side*.68,-.22,.54),.04,0,'bone')
                taper('HindLeg',root,(side*.16,.09,.38),(side*.21,.12,.08),.085,.055,'ash')
                for toe in (-1,1):taper('HookedTalon',root,(side*.21,.12,.09),(side*.21+toe*.065,-.12,-.01),.036,0,'bone')
            taper('Tail',root,(0,.26,.53),(0,.80,.23),.08,.02,'ash')
            movers=[root]+[o for o in scene.objects if o.name.startswith('WingL') or o.name.startswith('WingR')]
            clips=['Idle','Walk','Attack','Hit','Death']
            rests={o:(o.location.copy(),o.rotation_euler.copy(),o.scale.copy()) for o in movers}
            for clip in clips:
                for o in movers:
                    loc,rot,scale=rests[o];o.animation_data_create();o.animation_data.action=None
                    for frame in (1,7,13,19,25):
                        t=(frame-1)/24;o.location=loc;o.rotation_euler=rot;o.scale=scale
                        if o!=root:
                            side=-1 if o.name.startswith('WingL') else 1
                            o.rotation_euler.y=side*(sin(t*tau)*.65 if clip!='Death' else t*1.35)
                        elif clip in ('Idle','Walk'):o.location.z+=sin(t*tau)*.07
                        elif clip=='Attack':o.rotation_euler.x+=sin(t*pi)*.6
                        elif clip=='Hit':o.rotation_euler.y+=sin(t*pi)*.3
                        else:o.rotation_euler.x=t*1.5;o.location.z-=t*.4
                        for channel in ('location','rotation_euler','scale'):o.keyframe_insert(data_path=channel,frame=frame)
                    action=o.animation_data.action;action.name=kind+'_'+clip+'_'+o.name
                    track=o.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action)
                    o.animation_data.action=None;o.location=loc;o.rotation_euler=rot;o.scale=scale
            results.append(finish['finish_asset'](kind,scene,clips))
    finally:bpy.context.window.scene=original
    return results
