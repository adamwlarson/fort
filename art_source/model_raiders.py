"""Direct Blender modeling for Fort's second art pass.

Run build() via the Blender MCP. Creates new scenes only, then uses the shared
finishing/animation exporter. Blender coordinates: Z up, -Y forward, meters.
All meshes and materials belong to this pass; the open user scene is preserved.
"""
from pathlib import Path
from math import pi, sin, cos, tau
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
PALETTE = {
    'skin': '658064', 'skin_light': '8ea078', 'skin_dark': '415449',
    'brute': '8a6f63', 'brute_light': 'b29a80', 'sapper': '899078',
    'leather': '503c31', 'leather_light': '896044', 'cloth': '674640',
    'hood': '384c58', 'iron': '394952', 'edge': '84989c',
    'gold': 'c29b58', 'bone': 'ead9ad', 'eye': 'e5b855', 'black': '19282a',
    'copper': 'ae6941', 'teal': '367f80', 'glass': '79cab4', 'wood': '805b3b',
}
MATS = {}

def material(key):
    if key not in MATS:
        color = PALETTE[key]
        # Palette values are sRGB; Blender material inputs are linear.
        channels = [int(color[i:i+2],16)/255 for i in (0,2,4)]
        channels = [v/12.92 if v<=0.04045 else ((v+0.055)/1.055)**2.4 for v in channels]
        m = bpy.data.materials.new('FortArt2_'+key)
        m.diffuse_color = (*channels,1)
        m.use_nodes = True
        n = m.node_tree.nodes.get('Principled BSDF')
        n.inputs['Base Color'].default_value = (*channels,1)
        n.inputs['Roughness'].default_value = 0.83
        MATS[key] = m
    return MATS[key]

def empty(name, parent=None, pos=(0,0,0)):
    obj = bpy.data.objects.new(name,None)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.location = pos
    return obj

def finish(obj,name,parent,pos,scale,key):
    obj.name = name
    obj.parent = parent
    obj.location = pos
    obj.scale = scale
    obj.data.materials.append(material(key))
    # Bake only this newly created object's scale so edge widths stay consistent.
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return obj

def ellipsoid(name,parent,pos,scale,key,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1)
    return finish(bpy.context.object,name,parent,pos,scale,key)

def box(name,parent,pos,size,key,rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj=finish(bpy.context.object,name,parent,pos,size,key)
    obj.rotation_euler=rotation
    return obj

def taper(name,parent,a,b,r1,r2,key,vertices=8):
    direction=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=direction.length)
    obj=finish(bpy.context.object,name,parent,(Vector(a)+Vector(b))/2,(1,1,1),key)
    obj.rotation_euler=direction.to_track_quat('Z','Y').to_euler()
    return obj

def mesh(name,parent,vertices,faces,key):
    data=bpy.data.meshes.new(name)
    data.from_pydata(vertices,[],faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent=parent
    obj.data.materials.append(material(key))
    return obj

def ring(name,parent,pos,radius,thickness,key,rotation=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=4,major_radius=radius,minor_radius=thickness)
    obj=finish(bpy.context.object,name,parent,pos,(1,1,1),key)
    obj.rotation_euler=rotation
    return obj

def torso(parent,key,width=1):
    vertices=[]
    rings=[(0.66,0.29,0.21),(0.88,0.36,0.29),(1.15,0.41,0.25),(1.33,0.31,0.18)]
    for z,rx,ry in rings:
        for i in range(10):
            angle=i*tau/10
            vertices.append((cos(angle)*rx*width,sin(angle)*ry,z))
    faces=[tuple(reversed(range(10)))]
    for j in range(3):
        for i in range(10):
            n=(i+1)%10
            faces.append((j*10+i,j*10+n,(j+1)*10+n,(j+1)*10+i))
    faces.append(tuple(range(30,40)))
    return mesh('TailoredTorso',parent,vertices,faces,key)

def face(parent,kind):
    skin='skin' if kind=='raider' else ('brute' if kind=='brute' else 'sapper')
    light='brute_light' if kind=='brute' else 'skin_light'
    head=empty('Head',parent,(0,0,1.54))
    if kind=='sapper':
        ellipsoid('WaxedHood',head,(0,0.08,0.09),(0.47,0.36,0.49),'hood')
        taper('HoodTail',head,(0,0.13,0.4),(0,0.40,0.50),0.22,0.03,'hood')
    ellipsoid('Cranium',head,(0,0,0.13),(0.39,0.30,0.36),skin)
    ellipsoid('AngularJaw',head,(0,-0.12,-0.12),(0.29,0.26,0.20),skin)
    ellipsoid('UpperMuzzle',head,(0,-0.295,-0.055),(0.25,0.11,0.10),light)
    box('MouthCrease',head,(0,-0.362,-0.13),(0.35,0.028,0.048),'black')
    ellipsoid('LowerLip',head,(0,-0.325,-0.17),(0.22,0.07,0.045),skin)
    for side in (-1,1):
        # Solid, tapered ear with a contrasting inset, not a cone stuck to a ball.
        verts=[(side*0.26,0,0.15),(side*0.78,0.035,0.37),(side*0.39,-0.025,-0.015),(side*0.42,0.13,0.16)]
        mesh('PointedEar',head,verts,[(0,1,2),(0,3,1),(1,3,2),(2,3,0)],skin)
        mesh('EarInset',head,[(side*0.36,-0.035,0.14),(side*0.65,0.003,0.29),(side*0.41,-0.045,0.045)],[(0,1,2)],'leather_light')
        ellipsoid('CheekPlane',head,(side*0.27,-0.21,-0.015),(0.16,0.11,0.12),light,1)
        ellipsoid('EyeSocket',head,(side*0.16,-0.257,0.18),(0.151,0.076,0.105),'skin_dark')
        ellipsoid('AmberEye',head,(side*0.16,-0.309,0.18),(0.107,0.045,0.065),'eye')
        ellipsoid('SlitPupil',head,(side*0.15,-0.349,0.18),(0.019,0.012,0.047),'black')
        box('ScowlingBrow',head,(side*0.16,-0.31,0.27),(0.26,0.065,0.072),skin,(0,side*-0.23,0))
        taper('LowerTusk',head,(side*0.17,-0.36,-0.19),(side*0.20,-0.42,-0.005 if kind=='brute' else -0.065),0.045,0.008,'bone')
        ellipsoid('Nostril',head,(side*0.07,-0.479,0.029),(0.033,0.016,0.019),'skin_dark')
    ellipsoid('LongNoseBridge',head,(0,-0.325,0.16),(0.10,0.16,0.18),light)
    ellipsoid('NoseTip',head,(0,-0.432,0.065),(0.127,0.09,0.09),light,1)
    if kind=='raider':
        for i in range(5):
            x=(i-2)*0.085
            taper('CrestHair',head,(x,0,0.39),(x,0.06,0.60-abs(i-2)*0.035),0.07,0.008,'black')
        ring('StolenEarring',head,(0.54,-0.01,0.075),0.07,0.018,'gold',(pi/2,0,0))
    elif kind=='brute':
        ellipsoid('IronSkullcap',head,(0,0.045,0.40),(0.40,0.28,0.15),'iron')
        box('HelmetBrowPlate',head,(0,-0.29,0.37),(0.65,0.09,0.15),'iron')
        box('HelmetNoseGuard',head,(0,-0.36,0.29),(0.10,0.05,0.29),'edge')
        for side in (-1,1):
            taper('HelmetHorn',head,(side*0.29,0.04,0.44),(side*0.48,0.06,0.71),0.10,0.035,'bone')
            taper('HornTip',head,(side*0.48,0.06,0.71),(side*0.44,0.06,0.82),0.035,0.0,'bone')
    else:
        for side in (-1,1):
            ring('BrassGoggle',head,(side*0.17,-0.34,0.20),0.115,0.029,'gold',(pi/2,0,0))
            ellipsoid('GoggleLens',head,(side*0.17,-0.36,0.20),(0.087,0.015,0.074),'glass')
        box('GoggleBridge',head,(0,-0.36,0.21),(0.08,0.04,0.033),'gold')
    return head

def enemy(kind):
    scene=bpy.data.scenes.new('Fort_Sculpt_'+kind)
    bpy.context.window.scene=scene
    root=empty(kind)
    skin='skin' if kind=='raider' else ('brute' if kind=='brute' else 'sapper')
    width=1.24 if kind=='brute' else 1
    torso(root,'leather' if kind=='raider' else ('iron' if kind=='brute' else 'hood'),width)
    face(root,kind)
    # Layered belt, buckle and cloth skirt give a readable waist and outfit.
    for i in range(8):
        angle=i*tau/8
        plate=box('BeltSegment',root,(sin(angle)*0.33*width,cos(angle)*0.25,0.77),(0.28,0.07,0.13),'leather_light',(0,0,-angle))
    box('BeltBuckle',root,(0,-0.293,0.77),(0.15,0.045,0.13),'gold')
    for side in (-1,1):
        arm=empty('ArmL' if side<0 else 'ArmR',root,(side*0.45*width,0,1.26))
        ellipsoid('Deltoid',arm,(0,0,-0.10),(0.17,0.18,0.23),skin)
        taper('Forearm',arm,(0,0,-0.19),(side*0.025,-0.02,-0.48),0.13,0.10,skin)
        ellipsoid('ClenchedHand',arm,(side*0.025,-0.035,-0.50),(0.13,0.15,0.14),skin,1)
        taper('LeatherBracer',arm,(0,0,-0.29),(0,0,-0.40),0.147,0.135,'iron' if kind=='brute' else 'leather')
        leg=empty('LegL' if side<0 else 'LegR',root,(side*0.22,0,0.66))
        taper('TrouserLeg',leg,(0,0,-0.01),(0,0,-0.37),0.16,0.105,'cloth' if kind=='raider' else 'leather')
        ellipsoid('Kneecap',leg,(0,-0.075,-0.26),(0.13,0.09,0.13),'iron' if kind=='brute' else skin,1)
        ellipsoid('WornBoot',leg,(0,-0.08,-0.53),(0.15,0.25,0.115),'leather')
        box('BootSole',leg,(0,-0.08,-0.60),(0.29,0.42,0.065),'black')
        if kind=='brute':
            ellipsoid('ForgedPauldron',arm,(side*0.07,0,0.035),(0.26,0.27,0.18),'iron',1)
            for spike in range(3):
                taper('ShoulderSpike',arm,(side*0.1,(spike-1)*0.13,0.12),(side*0.18,(spike-1)*0.15,0.36),0.07,0,'bone')
        elif kind=='raider' and side<0:
            ellipsoid('ScavengedPauldron',arm,(0,0,0.02),(0.22,0.23,0.11),'edge',1)
        if side>0:
            hand=empty('WeaponGrip',arm,(0,-0.065,-0.50))
            if kind=='sapper':
                ellipsoid('HeldBomb',hand,(0,-0.10,0.10),(0.18,0.18,0.20),'iron')
                taper('BombFuse',hand,(0,-0.1,0.26),(0.05,-0.1,0.40),0.023,0.015,'bone')
                ellipsoid('FuseEmber',hand,(0.05,-0.1,0.40),(0.028,0.028,0.03),'copper',1)
            else:
                taper('WeaponHandle',hand,(0,0,-0.18),(0,0,0.60),0.047,0.047,'wood')
                for z in (0,0.07,0.14):ring('GripWrap',hand,(0,0,z),0.047,0.011,'leather')
                if kind=='brute':
                    box('Warhammer',hand,(0,0,0.56),(0.65,0.29,0.29),'iron')
                    for x in (-0.30,0.30):box('HammerFace',hand,(x,0,0.56),(0.07,0.33,0.33),'edge')
                else:
                    mesh('Cleaver',hand,[(0,-0.045,0.27),(0.38,-0.045,0.31),(0.42,-0.045,0.65),(0.07,-0.045,0.72),(0,0.045,0.27),(0.38,0.045,0.31),(0.42,0.045,0.65),(0.07,0.045,0.72)],[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'edge')
    if kind=='raider':
        taper('Bandolier',root,(-0.31,-0.23,1.30),(0.24,-0.31,0.84),0.055,0.055,'leather_light',4)
        for i in range(3):box('StolenPouch',root,((i-1)*0.22,-0.30,0.65),(0.17,0.13,0.20),'leather_light')
        ellipsoid('Bedroll',root,(0,0.29,1.12),(0.36,0.17,0.17),'cloth')
    elif kind=='brute':
        for z in (0.98,1.16):box('ChestArmor',root,(0,-0.27,z),(0.70,0.10,0.14),'iron')
        for x in (-0.27,0.27):
            for z in (0.98,1.16):ellipsoid('ArmorRivet',root,(x,-0.334,z),(0.028,0.02,0.028),'gold',1)
        root.scale=(1.28,1.28,1.28)
    else:
        box('BombHarness',root,(0,0.27,1.03),(0.62,0.16,0.59),'leather')
        for side in (-1,1):
            taper('CopperCanister',root,(side*0.18,0.39,0.77),(side*0.18,0.39,1.40),0.14,0.14,'copper',10)
            for z in (0.85,1.28):ring('TankBand',root,(side*0.18,0.39,z),0.143,0.023,'iron')
            taper('TankValve',root,(side*0.18,0.39,1.41),(side*0.18,0.39,1.50),0.05,0.05,'gold')
            ellipsoid('BeltBomb',root,(side*0.27,-0.22,0.70),(0.13,0.13,0.15),'iron')
        taper('ChestStrap',root,(-0.27,-0.22,1.29),(0.22,-0.29,0.82),0.042,0.042,'gold',4)
    return scene

def build():
    original=bpy.context.window.scene
    namespace={'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),namespace)
    results=[]
    try:
        for kind in ('raider','brute','sapper'):
            results.append(namespace['finish_asset'](kind,enemy(kind)))
    finally:
        bpy.context.window.scene=original
    return results

if __name__=='__main__':
    print(build())
