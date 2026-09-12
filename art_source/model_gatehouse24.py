"""Fort24: concept-guided ashlar gatehouse, authored in an isolated Blender process.
Z up / -Y exterior. Named moving pivots exported separately; no artist scene touched.
Run: blender --background --factory-startup --python art_source/model_gatehouse24.py
"""
from pathlib import Path
from math import sin, cos, pi, tau
import math, random, json
import bpy
import numpy as np
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/fort'
SRC=ROOT/'art_source/blender'
REVIEW=ROOT/'build'
TEX=ROOT/'assets/textures/gatehouse24'
for folder in (OUT,SRC,REVIEW,TEX):folder.mkdir(parents=True,exist_ok=True)
random.seed(24011)
scene=bpy.data.scenes.new('Fort24_Gatehouse');bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'
materials={}

def texture(name,color,wood=False):
    """Bake a deterministic painterly material surface, not generated concept pixels."""
    n=512;yy,xx=np.mgrid[0:n,0:n].astype(np.float32)/n
    rng=np.random.default_rng(240 if wood else 241)
    noise=np.zeros((n,n),dtype=np.float32)
    for i in range(1,12):
        a,b=rng.uniform(1,28,2);phase=rng.uniform(0,tau)
        noise+=np.sin((xx*a+yy*b)*tau+phase)/(i+3)
    if wood:
        grain=np.sin((xx*46+np.sin(yy*5)*.5+np.sin(yy*11+xx*5)*.4)*tau)
        height=.5+.07*noise+.09*grain
        flecks=.96+.09*noise-.13*np.maximum(grain,0)**10
    else:
        height=.5+.045*noise
        flecks=.96+.035*noise+rng.uniform(-.025,.025,(n,n))
    rgba=np.ones((n,n,4),dtype=np.float32)
    rgb=np.array(color[:3],dtype=np.float32)
    rgba[:,:,:3]=np.clip(flecks[:,:,None]*rgb,0,1)
    image=bpy.data.images.new('Gate24_'+name,width=n,height=n)
    image.pixels.foreach_set(rgba.ravel());image.filepath_raw=str(TEX/(name+'.png'));image.file_format='PNG';image.save();image.pack()
    dy,dx=np.gradient(height)
    normal=np.stack((-dx*8,-dy*8,np.ones_like(dx)),axis=-1)
    normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
    rgba[:,:,:3]=normal*.5+.5
    bump=bpy.data.images.new('Gate24_'+name+'_normal',width=n,height=n)
    bump.colorspace_settings.name='Non-Color';bump.pixels.foreach_set(rgba.ravel());bump.filepath_raw=str(TEX/(name+'_normal.png'));bump.file_format='PNG';bump.save();bump.pack()
    return image,bump

def mat(name,hexcolor,metal=0,rough=.8,tex=False,wood=False,emission=0):
    srgb=tuple(int(hexcolor[i:i+2],16)/255 for i in (0,2,4))
    color=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in srgb)+(1,)
    m=bpy.data.materials.new('Gate24_'+name);m.diffuse_color=color;m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=color
    shader.inputs['Metallic'].default_value=metal;shader.inputs['Roughness'].default_value=rough
    if tex:
        image,bump=texture(name,color,wood)
        image_node=m.node_tree.nodes.new('ShaderNodeTexImage');image_node.image=image
        m.node_tree.links.new(image_node.outputs['Color'],shader.inputs['Base Color'])
        normal_node=m.node_tree.nodes.new('ShaderNodeTexImage');normal_node.image=bump
        normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.38
        m.node_tree.links.new(normal_node.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],shader.inputs['Normal'])
    if emission:
        shader.inputs['Emission Color'].default_value=color;shader.inputs['Emission Strength'].default_value=emission
    materials[name]=m;return m

mat('Ashlar','65747d',tex=True);mat('Limestone','94a09e',tex=True)
mat('Oak','66452c',tex=True,wood=True);mat('Bronze','ac8049',.65,.4)
mat('Edge','cfaa68',.55,.38);mat('Iron','283a43',.7,.48)
mat('Teal','24656c',.05,.86);mat('Shadow','243338')
mat('Amber','ffc878',.1,.35,emission=2);mat('Rune','76cec4',.15,.4,emission=.35)

def empty(name,parent=None,loc=(0,0,0)):
    o=bpy.data.objects.new(name,None);scene.collection.objects.link(o);o.parent=parent;o.location=loc;return o
root=empty('Gatehouse24')
frame=empty('Masonry',root);mechanics=empty('Mechanism',root)
leaf=empty('Portcullis',root);winch=empty('Winch',root,(0,0,5.72))
weights=[empty('WeightL' if x<0 else 'WeightR',root,(x,.92,3.4)) for x in (-2.34,2.34)]
upgrades=[empty('Upgrade_%02d'%i,root) for i in range(2,9)]

def uv_project(o):
    uv=o.data.uv_layers.new(name='UVMap')
    for f in o.data.polygons:
        normal=f.normal;axis=max(range(3),key=lambda i:abs(normal[i]))
        axes=[i for i in range(3) if i!=axis]
        for idx in f.loop_indices:
            v=o.data.vertices[o.data.loops[idx].vertex_index].co
            uv.data[idx].uv=(v[axes[0]]*.65+.5,v[axes[1]]*.65+.5)

def mesh(name,parent,verts,faces,material,bevel=.025):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);o.parent=parent
    data.materials.append(materials[material]);uv_project(o)
    if bevel:
        mod=o.modifiers.new('Worn dressed edges','BEVEL');mod.width=bevel;mod.segments=2
        mod=o.modifiers.new('Face-weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;mod.weight=40
    return o

def box(name,parent,loc,size,material,bevel=.025,rot=(0,0,0)):
    x,y,z=[s/2 for s in size]
    v=[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]
    o=mesh(name,parent,v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],material,bevel);o.location=loc;o.rotation_euler=rot;return o

def beam(name,parent,a,b,radius,material,vertices=8):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=(b-a).length,location=(a+b)*.5)
    o=bpy.context.object;o.name=name;o.parent=parent;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(materials[material])
    mod=o.modifiers.new('Forged edge','BEVEL');mod.width=min(.015,radius*.2);mod.segments=2
    return o

def ring(name,parent,loc,major,minor,material,rot=(pi/2,0,0),scale=(1,1,1)):
    bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=4,location=loc,rotation=rot,major_radius=major,minor_radius=minor)
    o=bpy.context.object;o.name=name;o.parent=parent;o.scale=scale;o.data.materials.append(materials[material]);return o

def relief(parent,x,y,z,scale=1):
    # Angular twin peaks above a forged anvil; genuine raised geometry on both faces.
    for a,b in [((-.28,0),(-.04,.39)),((-.04,.39),(.23,0)),((.02,.11),(.22,.34)),((.22,.34),(.43,0))]:
        beam('Mountain crest',parent,(x+a[0]*scale,y,z+a[1]*scale),(x+b[0]*scale,y,z+b[1]*scale),.033*scale,'Edge',6)
    pts=[(-.31,-.07),(.3,-.07),(.38,-.14),(.12,-.22),(.08,-.36),(.22,-.43),(-.21,-.43),(-.06,-.34),(-.1,-.2),(-.29,-.17)]
    v=[(x+a*scale,y+depth,z+b*scale) for depth in [-.024,.024] for a,b in pts];n=len(pts)
    mesh('Anvil crest',parent,v,[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'Bronze',.008)

# Fitted, staggered courses give mass without a pile-of-boxes silhouette.
for side in (-1,1):
    x=side*2.34
    box('Splayed footing',frame,(x,0,.14),(.92,2.68,.28),'Limestone',.065)
    for row in range(12):
        h=.41;z=.3+row*.43+h/2
        breaks=[-1.2,-.6,0,.6,1.2] if row%2==0 else [-1.2,-.85,-.25,.35,.95,1.2]
        for j in range(len(breaks)-1):
            width=breaks[j+1]-breaks[j]
            box('Ashlar course %02d'%row,frame,(x,(breaks[j]+breaks[j+1])/2,z),(.87,width-.018,h),'Limestone' if (row+j)%7==0 else 'Ashlar',.028)
    for z in (.36,3.52,5.43):box('Continuous bronze band',frame,(x,0,z),(.95,2.48,.075),'Bronze',.012)
    box('Coping cap',frame,(x,0,5.55),(1.02,2.65,.21),'Limestone',.04)
    for y in (-1.0,0,1.0):
        box('Pier merlon',frame,(x,y,5.93),(.84,.6,.58),'Ashlar',.045)
        box('Merlon bronze lip',frame,(x,y,6.2),(.91,.67,.065),'Bronze',.012)
    # Slim guide rails, visible chains and a recessed lantern niche.
    for y in (-.2,.2):box('Portcullis guide',mechanics,(side*1.93,y,2.25),(.105,.10,4.5),'Bronze',.01)
    for y in (-1.28,1.28):
        box('Lantern niche backing',frame,(x,y,1.6),(.55,.06,1.38),'Shadow',.035)
        for sx in (-.34,.34):box('Niche jamb',frame,(x+sx,y,1.57),(.09,.2,1.52),'Limestone',.012)
        box('Niche pediment',frame,(x,y,2.4),(.77,.23,.19),'Limestone',.025)
        for z in (1.02,1.93):box('Lantern cage cap',frame,(x,y*1.09,z),(.32,.31,.10),'Bronze',.025)
        box('Lantern glass',frame,(x,y*1.09,1.47),(.18,.17,.77),'Amber',.018)
        for dx in (-.13,.13):
            for dy in (-.12,.12):beam('Lantern cage',frame,(x+dx,y*1.09+dy,1.07),(x+dx,y*1.09+dy,1.89),.022,'Iron')
        ring('Lantern suspension',frame,(x,y*1.09,2.12),.085,.016,'Bronze')
    # Cloth is shaped, not a flat rectangular sticker.
    for y in (-1.28,1.28):
        vertices=[]
        for row in range(8):
            for col in range(5):
                u=col/4;v=row/7
                z=5.21-v*1.7-(.20*(1-abs(u*2-1)) if row==7 else 0)
                vertices.append((x+(u-.5)*.64,y+(1 if y>0 else -1)*(.04+sin(u*pi*3+v)*.055),z))
        faces=[(r*5+c,r*5+c+1,(r+1)*5+c+1,(r+1)*5+c) for r in range(7) for c in range(4)]
        cloth=mesh('Folded teal pennant',frame,vertices,faces,'Teal',0)
        solid=cloth.modifiers.new('Woven cloth thickness','SOLIDIFY');solid.thickness=.014
        beam('Banner rod',frame,(x-.43,y,5.26),(x+.43,y,5.26),.048,'Bronze')
        relief(frame,x,y+(1 if y>0 else -1)*.12,4.43,.66)

# Real segmental arch voussoirs, with dark joints and keystone relief.
for i in range(13):
    a=i*pi/13+.007;b=(i+1)*pi/13-.007
    cross=[(cos(a)*1.91,2.85+sin(a)*.85),(cos(b)*1.91,2.85+sin(b)*.85),(cos(b)*2.20,2.85+sin(b)*1.17),(cos(a)*2.20,2.85+sin(a)*1.17)]
    v=[(x,y,z) for y in (-1.18,1.18) for x,z in cross]
    mesh('Arch voussoir %02d'%i,frame,v,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'Limestone' if i%3==0 else 'Ashlar',.022)
for y in (-1.22,1.22):
    box('Keystone escutcheon',frame,(0,y,3.86),(.79,.23,.85),'Limestone',.05)
    relief(frame,0,y+(-.15 if y<0 else .15),3.92,.83)
    box('Crown lintel',frame,(0,y,4.19),(4.58,.30,.25),'Limestone',.04)
    box('Lintel bronze reveal',frame,(0,y,4.32),(4.7,.34,.065),'Bronze',.01)
    box('Battlement wall',frame,(0,y,4.67),(3.9,.26,.57),'Ashlar',.03)
    for x in (-1.45,-.48,.48,1.45):
        box('Crown merlon',frame,(x,y,5.16),(.54,.36,.45),'Ashlar',.03)
        box('Crown merlon cap',frame,(x,y,5.4),(.62,.43,.10),'Limestone',.02)
for y in (-.67,.67):box('Upper platform',frame,(0,y,4.35),(3.92,.94,.22),'Ashlar',.035)

# Portcullis, bound in iron with individually forged rivets and chamfered teeth.
for i in range(9):
    x=-1.68+i*.42
    box('Oak gate stave',leaf,(x,0,1.75),(.31,.20,2.67),'Oak',.025)
    box('Iron vertical facing',leaf,(x,-.14,1.72),(.095,.10,2.8),'Iron',.012)
    mesh('Gate tooth',leaf,[(x-.085,-.19,.37),(x+.085,-.19,.37),(x,-.19,.06),(x-.085,.02,.37),(x+.085,.02,.37),(x,.02,.06)],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)],'Iron',.008)
for z in (.52,1.56,2.74):
    for y in (-.2,.18):
        box('Gate binding',leaf,(0,y,z),(3.79,.11,.14),'Iron',.02)
        for i in range(9):beam('Bronze rivet',leaf,(-1.68+i*.42,y-.09,z),(-1.68+i*.42,y+.09,z),.036,'Bronze',8)
box('Portcullis head',leaf,(0,0,3.05),(3.83,.42,.15),'Bronze',.025)

# Counterweight and winch assembly, retained as named animation pivots.
beam('Winch axle',winch,(-2.08,0,0),(2.08,0,0),.085,'Iron',12)
beam('Oak drum',winch,(-1.4,0,0),(1.4,0,0),.27,'Oak',16)
for x in (-1.5,-1.24,1.24,1.5):
    ring('Bronze winch wheel',winch,(x,0,0),.36,.048,'Bronze',(0,pi/2,0))
    for angle in range(6):beam('Wheel spoke',winch,(x,0,0),(x,cos(angle*tau/6)*.35,sin(angle*tau/6)*.35),.035,'Bronze')
for side in (-1,1):
    box('Winch bearing block',mechanics,(side*1.78,0,5.53),(.26,.67,.85),'Oak',.025)
    box('Winch bearing strap',mechanics,(side*1.78,-.36,5.57),(.30,.05,.84),'Iron',.015)
    for i in range(15):ring('Hanging chain',mechanics,(side*1.78,.17,3.2+i*.16),.082,.016,'Iron',(pi/2,0,(i%2)*pi/2),(.65,1,1.2))
for weight in weights:
    box('Counterweight oak case',weight,(0,0,0),(.54,.45,.72),'Oak',.03)
    for x in (-.22,.22):box('Weight iron binding',weight,(x,-.26,0),(.065,.055,.78),'Bronze',.012)
    for z in (-.31,.31):box('Weight end plate',weight,(0,0,z),(.60,.50,.10),'Iron',.015)

# Reachable interior controls, with a protected lever and engraved bronze backplate.
for side in (-1,1):
    box('Control backplate',mechanics,(side*2.34,1.31,2.76),(.48,.09,.50),'Bronze',.035)
    beam('Control lever',mechanics,(side*2.34,1.37,2.65),(side*2.34,1.65,2.94),.048,'Iron')
    beam('Lever grip',mechanics,(side*2.34-.13,1.65,2.94),(side*2.34+.13,1.65,2.94),.06,'Oak')

# Reinforcement tiers: visible geometric additions, not just a label or a tint.
for level,parent in enumerate(upgrades,2):
    for side in (-1,1):
        z=.7+(level-2)*.59
        box('Reinforcement collar',parent,(side*2.34,-1.26,z),(.88,.12,.12),'Bronze',.018)
        diamond=[(side*2.34-.10,-1.36,z),(side*2.34,-1.36,z+.13),(side*2.34+.10,-1.36,z),(side*2.34,-1.36,z-.13)]
        mesh('Inset rank stone',parent,diamond,[(0,1,2,3)],'Rune' if level>=3 else 'Edge',0)
    if level==2:
        for x in (-1.1,1.1):box('Iron buttress cheek',parent,(x,-1.3,4.57),(.32,.17,.62),'Iron',.03)
    if level==3:
        for y in (-1.4,1.4):relief(parent,0,y,4.8,.68)

# Export an editable source before batching. Runtime owns the mechanical timeline.
for o in scene.objects:
    if o.type=='MESH':
        o.data.update()
        for poly in o.data.polygons:poly.use_smooth=False
bpy.context.view_layer.update()
bpy.data.libraries.write(str(SRC/'gatehouse24_sculpt.blend'),{scene},fake_user=True,compress=True)
helpers={'__name__':'gate_finish'}
exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),helpers)
helpers['merge_static_batches'](scene)
bpy.ops.object.select_all(action='DESELECT')
for o in scene.objects:o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.export_scene.gltf(filepath=str(OUT/'gatehouse.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_cameras=False,export_lights=False,export_yup=True,export_animations=False,export_apply=True)

# Three separately authored worksite stages. The passage stays open throughout.
finished=list(scene.objects)
for stage in range(3):
    site=empty('Gatehouse_work_%d'%stage)
    for side in (-1,1):
        x=side*2.34
        box('Dressed foundation',site,(x,0,.14),(.92,2.68,.28),'Limestone',.05)
        for row in range(2+stage*4):
            for j in range(4):
                box('Laid course',site,(x,-.9+j*.6,.51+row*.43),(.87,.58,.41),'Ashlar',.025)
        for y in (-1.4,1.4):
            beam('Scaffold upright',site,(x,y,.2),(x,y,1.7+stage*1.6),.065,'Oak')
            beam('Tied brace',site,(x-.34,y,.4),(x+.34,y,1.6+stage*1.3),.04,'Oak')
            for z in (.7,1.4+stage*1.4):
                ring('Rope lashing',site,(x,y,z),.085,.016,'Oak')
        if stage>0:
            for j in range(4):box('Work platform plank',site,(x,-.96+j*.64,1.5+stage),(.98,.6,.10),'Oak',.018)
        for j in range(3):box('Stacked cut stone',site,(x,1.6,.2+j*.18),(.6,.34,.16),'Limestone',.022)
    if stage==2:
        for y in (-.7,.7):
            beam('Arch centering timber',site,(-2,y,3.3),(2,y,3.3),.10,'Oak')
            for side in (-1,1):beam('Centering diagonal',site,(side*1.9,y,1.8),(side*.5,y,3.3),.07,'Oak')
    # A pitched carpenter's drawing board makes the worksite recognizable.
    box('Plan board',site,(-2.34,-1.56,1.08),(.68,.055,.52),'Oak',.02,rot=(.22,0,0))
    relief(site,-2.34,-1.64,1.13,.45)
    helpers['merge_static_batches'](scene)
    bpy.ops.object.select_all(action='DESELECT')
    site.select_set(True)
    for o in site.children_recursive:o.select_set(True)
    bpy.context.view_layer.objects.active=site
    bpy.ops.export_scene.gltf(filepath=str(OUT/('gatehouse_work_%d.glb'%stage)),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_animations=False,export_apply=True)
    for o in [site]+list(site.children_recursive):o.hide_render=True

# Asset review is a real render of the exported geometry's source, not the concept.
for parent in upgrades:
    for o in parent.children_recursive:o.hide_render=True
scene.render.engine='CYCLES';scene.cycles.samples=48
scene.render.resolution_x=1280;scene.render.resolution_y=1280;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Gate24 studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.085,.105,.12,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
floor=box('Review floor',None,(0,0,-.18),(200,200,.2),'Shadow',0)
for loc,energy,size in [((3,-6,10),1600,7),((-5,-2,5),1000,5),((0,5,8),1800,5)]:
    data=bpy.data.lights.new('Studio softbox','AREA');data.energy=energy;data.shape='DISK';data.size=size
    o=bpy.data.objects.new('Studio softbox',data);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,3))-o.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Review camera');camera=bpy.data.objects.new('Review camera',data);scene.collection.objects.link(camera);scene.camera=camera
camera.location=(9,-12,8);camera.rotation_euler=(Vector((0,0,3))-camera.location).to_track_quat('-Z','Y').to_euler();data.type='ORTHO';data.ortho_scale=9.4
for opened in (False,True):
    leaf.location.z=3.15 if opened else 0;winch.rotation_euler.x=2.8 if opened else 0
    for weight in weights:weight.location.z=1.6 if opened else 3.4
    scene.render.filepath=str(REVIEW/('gate24_open.png' if opened else 'gate24_closed.png'));bpy.ops.render.render(write_still=True)
triangles=sum(len(o.data.polygons) for o in scene.objects if o.type=='MESH')
print('GATE24_ASSET_READY',json.dumps({'file':str(OUT/'gatehouse.glb'),'bytes':(OUT/'gatehouse.glb').stat().st_size,'mesh_nodes':len([o for o in scene.objects if o.type=='MESH']),'polygons':triangles}))
