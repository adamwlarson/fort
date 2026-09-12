"""Fort 13 concept-guided cast refinements. New scenes, unchanged source rig / clips.
Hero clothing is weighted onto the original bones, not attached as static scenery.
"""
from pathlib import Path
from math import sin, cos, pi, tau
import bpy
ROOT=Path(__file__).resolve().parents[1]
HEROES=['dwarf_vanguard','dwarf_warden','dwarf_engineer','dwarf_ranger']
ENEMIES=['raider','brute','sapper','ashwing','emberrunner','chieftain','sapper7','cinderlobber','bombwing','shieldguard','hexer','colossus','prowler','razorback','direwolf','stonebear','emberdrake','frostwyrm']
def build(heroes=True,enemies=True):
    original=bpy.context.window.scene
    ns={'__name__':'cast_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'red13':'934d43','teal13':'3f8580','ochre13':'b38a42','green13':'526c48','beard13':'a56b42','white13':'dbd5b8','brown13':'5b4134','hair13':'574c36','rune13':'91ded2','scar13':'b78072'})
    empty,box,taper,ellipsoid,ring,mesh=[ns[k] for k in ['empty','box','taper','ellipsoid','ring','mesh']]
    results=[]
    try:
        if heroes:
            for role,key in enumerate(HEROES):
                with bpy.data.libraries.load(str(ROOT/'art_source/blender/dwarf.blend'),link=False) as (src,dst):
                    dst.scenes=src.scenes[:1];dst.actions=[a for a in src.actions if a in ['Idle','Walk','Axe_Swing']]
                scene=dst.scenes[0];scene.name='Fort13_'+key;bpy.context.window.scene=scene
                rig=next(o for o in scene.objects if o.type=='ARMATURE');body=next(o for o in scene.objects if o.type=='MESH' and 'Dwarf' in o.name)
                rig.animation_data.action=None
                for action in dst.actions:
                    name=action.name.split('.')[0];track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action)
                scene.frame_set(1)
                # Model against the bind pose. Joining keeps source material names and skin weights.
                rig.data.pose_position='REST'
                before=set(scene.objects);root=empty('Costume13')
                cloth=['red13','teal13','ochre13','green13'][role];hair=['beard13','white13','brown13','hair13'][role]
                # Solid chamfered shoulder layers, braided beards and class-specific headwear.
                for side in [-1,1]:
                    for i in range(3 if role==0 else 2):
                        ellipsoid('ShoulderLamella',root,(side*(.34+i*.03),0,1.03-i*.06),(.20,.23,.085),'iron' if role==0 else cloth,2)
                    ring('BrassClasp',root,(side*.23,-.23,.98),.047,.013,'gold',(pi/2,0,0))
                    for j in range(7):
                        x=side*(.11+.025*sin(j*pi));z=1.18-j*.055
                        ellipsoid('BeardBraid',root,(x,-.28-.018*sin(j),z),(.067,.065,.062),hair,2)
                    ring('BeardCuff',root,(side*.11,-.28,.84),.060,.018,'gold')
                    box('BeltPouch',root,(side*.26,-.19,.62),(.15,.12,.16),'leather_light')
                    box('PouchBuckle',root,(side*.26,-.258,.65),(.055,.025,.055),'gold')
                if role==0:
                    ellipsoid('ForgedHelmet',root,(0,.01,1.43),(.32,.29,.18),'iron',2)
                    box('BrowBand',root,(0,-.27,1.41),(.53,.045,.065),'gold')
                    for i in range(5):taper('IronCrest',root,(0,-.16+i*.08,1.55),(0,-.16+i*.08,1.74),.045,.02,cloth)
                    for side in [-1,1]:box('CheekGuard',root,(side*.255,-.12,1.3),(.075,.22,.22),'iron',(0,side*.18,0))
                elif role==1:
                    for i in range(9):
                        a=i*tau/9;ellipsoid('RuneCollar',root,(sin(a)*.30,cos(a)*.24,1.02),(.075,.07,.12),'gold' if i%2 else cloth,1)
                    for side in [-1,1]:taper('RunePendant',root,(side*.20,-.28,.96),(side*.16,-.29,.8),.06,.025,'rune13',4)
                    ellipsoid('WardenCap',root,(0,.035,1.43),(.29,.25,.12),cloth,2)
                elif role==2:
                    for side in [-1,1]:
                        ring('EngineerGoggle',root,(side*.135,-.235,1.43),.087,.024,'gold',(pi/2,0,0))
                        ellipsoid('GoggleLens',root,(side*.135,-.25,1.43),(.066,.017,.055),'glass',2)
                    box('GoggleBridge',root,(0,-.26,1.43),(.13,.04,.04),'gold')
                    for i in range(3):taper('BeltTools',root,(-.1+i*.1,-.29,.62),(-.1+i*.1,-.29,.8),.025,.025,'edge',6)
                    box('WorkApron',root,(0,-.22,.78),(.37,.055,.32),cloth)
                else:
                    # Hood keeps the face opening visible; back panels follow the chest.
                    for side in [-1,1]:ellipsoid('HoodSide',root,(side*.255,.025,1.33),(.12,.28,.29),cloth,2)
                    ellipsoid('HoodCrown',root,(0,.07,1.54),(.30,.25,.13),cloth,2)
                    mesh('PointedCape',root,[(-.32,.20,1.03),(.32,.20,1.03),(.36,.3,.69),(0,.34,.48),(-.36,.3,.69)],[(0,1,2,3,4)],cloth)
                    for i in range(4):taper('QuiverArrow',root,(.22+i*.055,.22,.76),(.22+i*.055,.22,1.21),.013,.013,'wood',5)
                added=[o for o in scene.objects if o not in before and o.type=='MESH']
                for obj in added:
                    # Shoulder geometry follows arms, headwear and beard follow head.
                    bone='head' if any(t in obj.name for t in ['Beard','Helmet','Crest','Brow','Cheek','Goggle','Hood','Cap']) else 'chest'
                    if 'Shoulder' in obj.name:bone='upper_arm.L' if obj.location.x<0 else 'upper_arm.R'
                    group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
                    mod=obj.modifiers.new('Soft crafted edges','BEVEL');mod.width=.007;mod.segments=2
                    bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
                    # Parent removal preserves the model-space vertex positions for joining.
                    obj.parent=None
                bpy.ops.object.select_all(action='DESELECT');body.select_set(True)
                for obj in added:obj.select_set(True)
                bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
                rig.data.pose_position='POSE';scene.frame_set(1)
                bpy.data.libraries.write(str(ROOT/'art_source/blender'/(key+'_sculpt.blend')),{scene},fake_user=True,compress=True)
                bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);body.select_set(True);bpy.context.view_layer.objects.active=rig
                bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/fort'/(key+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
                results.append({'hero':key,'vertices':len(body.data.vertices),'clips':[t.name for t in rig.animation_data.nla_tracks]})
        if enemies:
            fin={'__name__':'cast_finish'};exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
            for key in ENEMIES:
                with bpy.data.libraries.load(str(ROOT/'art_source/blender'/(key+'_sculpt.blend')),link=False) as (src,dst):dst.scenes=src.scenes[:1]
                scene=dst.scenes[0];scene.name='Fort13_'+key;bpy.context.window.scene=scene
                # Rerunnable refinement: remove only this pass's details from the copied scene.
                for obj in list(scene.objects):
                    if obj.type=='MESH' and obj.name.split('.')[0].endswith('13'):
                        bpy.data.objects.remove(obj,do_unlink=True);continue
                    bevels=[m for m in obj.modifiers if m.type=='BEVEL']
                    for modifier in bevels[1:]:obj.modifiers.remove(modifier)
                root=next(o for o in scene.objects if o.parent is None)
                head=next((o for o in scene.objects if o.name.split('.')[0]=='Head'),root)
                # Refinements are local to authored pivots, so attack and locomotion remain intact.
                if key in ['raider','brute','chieftain','shieldguard','hexer','colossus','prowler','emberrunner','sapper','sapper7','cinderlobber']:
                    for side in [-1,1]:
                        for i in range(3):
                            box('FaceScar13',head,(side*(.23+i*.035),-.285,.07+i*.045),(.014,.02,.10),'scar13',(0,side*.4,0))
                        ring('TrophyRing13',head,(side*.43,-.04,.08),.075,.022,'gold',(pi/2,0,0))
                    for arm in [o for o in scene.objects if o.name.split('.')[0] in ['ArmL','ArmR']]:
                        side=-1 if 'ArmL' in arm.name else 1
                        for i in range(3):
                            ellipsoid('LayeredShoulder13',arm,(side*.05,0,.03-i*.065),(.24-i*.015,.26,.07),'iron' if key not in ['hexer','prowler'] else 'hood',2)
                        for j in [-1,0,1]:ellipsoid('ArmorRivet13',arm,(side*.18,j*.12,.035),(.025,.025,.025),'gold',1)
                    if key in ['sapper','sapper7','emberrunner']:
                        for side in [-1,1]:
                            box('WarningHarness13',root,(side*.29,-.26,1.06),(.12,.065,.55),'copper',(0,side*.22,0))
                        taper('TallFuse13',root,(0,.25,1.75),(.12,.25,2.15),.035,.023,'bone')
                        ellipsoid('BurningFuse13',root,(.12,.25,2.17),(.09,.07,.14),'copper',2)
                    elif key in ['hexer','colossus']:
                        for i in range(5):taper('RuneCrown13',head,((i-2)*.12,.03,.4),((i-2)*.15,.03,.69-abs(i-2)*.055),.07,.005,'rune13',5)
                elif key in ['ashwing','bombwing']:
                    for side in [-1,1]:
                        taper('SweptEar13',root,(side*.18,0,1.32),(side*.35,.12,1.78),.11,.015,'leather')
                        for i in range(3):box('FlightHarness13',root,(side*.25,-.16,.55+i*.16),(.12,.09,.13),'gold')
                    if key=='bombwing':
                        for side in [-1,1]:
                            ellipsoid('PayloadBomb13',root,(side*.35,0,.35),(.22,.22,.26),'iron',2)
                            taper('BombFuse13',root,(side*.35,0,.58),(side*.4,0,.77),.025,.014,'copper')
                elif key in ['razorback','direwolf','stonebear']:
                    for i in range(9):
                        y=-.5+i*.16
                        for side in [-1,1]:taper('SculptedMane13',root,(side*.25,y,1.15),(side*.43,y+.1,1.36),.13,.005,'leather_light' if key=='razorback' else 'hood',6)
                    for side in [-1,1]:
                        for i in range(3):taper('WhiskerTuft13',head,(side*.3,-.2,-.03),(side*(.48+i*.05),-.28,.05-i*.06),.045,.003,'bone',5)
                else:
                    # Dragons retain the recent anatomy / wing rebuild; add jaw plates and gem sockets.
                    for side in [-1,1]:
                        for i in range(3):ellipsoid('JawScute13',head,(side*(.24+i*.06),-.2+i*.15,-.16),(.09,.13,.07),'copper' if key=='emberdrake' else 'edge',1)
                results.append(fin['finish_asset'](key,scene,['Idle','Walk','Attack','Hit','Death'],preserve_animation=True))
    finally:bpy.context.window.scene=original
    return results
