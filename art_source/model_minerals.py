"""Fractured mineral outcrops with six removable harvest chunks. New scenes only."""
from pathlib import Path
from math import sin, cos, tau
import random
import bpy

ROOT=Path(__file__).resolve().parents[1]
g={'__name__':'fort_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),g)
g['PALETTE'].update({'slate':'657779','face':'87958f','strata':'b7b4a0','darkrock':'35494e','moss':'637e4e','gem':'65cbb8','gemlight':'b7ecce'})
empty,mesh,ellipsoid,taper=[g[k] for k in ('empty','mesh','ellipsoid','taper')]

def rock(parent,rng,pos,radius,height,key='slate'):
    n=7
    points=[(cos(i*tau/n)*radius*rng.uniform(.82,1.12),sin(i*tau/n)*radius*rng.uniform(.82,1.12)) for i in range(n)]
    verts=[(x+pos[0],y+pos[1],pos[2]) for x,y in points]
    verts += [(x*rng.uniform(.45,.8)+pos[0]+.10,y*rng.uniform(.5,.85)+pos[1],pos[2]+height+rng.uniform(-.15,.08)) for x,y in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    obj=mesh('FracturedMass',parent,verts,faces,key)
    obj.data.materials.append(g['material']('face' if key=='slate' else 'slate'))
    obj.data.polygons[1].material_index=1
    return obj

def deposit(root,variant,crystal=False):
    rng=random.Random(120+variant)
    # Low embedded bed and small detached rubble remain until fully exhausted.
    rock(root,rng,(0,0,-.13),1.05,.30,'darkrock' if crystal else 'slate')
    for i in range(9):
        a=i*2.399
        rock(root,rng,(cos(a)*1.08,sin(a)*.80,-.05),rng.uniform(.10,.22),rng.uniform(.14,.28),'darkrock' if crystal else 'slate')
    for i in range(6):
        chunk=empty('HarvestChunk_%d_Piece'%i,root)
        a=i*2.399+variant*.6
        r=.12 if i==0 else .52+(i%2)*.20
        x,y=cos(a)*r,sin(a)*r
        h=(.90 if i==0 else .34+(i%3)*.18)*(1+variant*.06)
        rock(chunk,rng,(x,y,.08),.61 if i==0 else .43,h,'darkrock' if crystal else 'slate')
        if crystal:
            shaft=empty('CrystalGrowth',chunk,(x,y,h*.5))
            shaft.rotation_euler=(rng.uniform(-.3,.3),rng.uniform(-.3,.3),a)
            taper('PrismaticShaft',shaft,(0,0,0),(0,0,.55+h*.35),.13,.13,'gem',6)
            taper('CrystalTip',shaft,(0,0,.55+h*.35),(0,0,.88+h*.35),.13,0,'gemlight',6)
            taper('BrightFacet',shaft,(.10,-.055,.12),(.10,-.055,.51+h*.35),.017,.012,'gemlight',4)
        else:
            if i%3==0:
                ellipsoid('MossShelf',chunk,(x-.03,y+.05,h+.07),(.23,.16,.035),'moss',1)
            # Light mineral seams exposed on the front broken face.
            taper('SedimentSeam',chunk,(x-.23,y-.25,h*.48),(x+.22,y-.26,h*.57),.018,.013,'strata',4)

def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),ns)
    result=[]
    try:
        for i,key in enumerate(['stone_outcrop_a','stone_outcrop_b','stone_outcrop_c','crystal_vein']):
            scene=bpy.data.scenes.new('Fort_Mineral_'+key)
            bpy.context.window.scene=scene
            root=empty(key)
            deposit(root,i,i==3)
            result.append(ns['finish_asset'](key,source_scene=scene))
        return result
    finally:
        bpy.context.window.scene=original

if __name__=='__main__': print(build())
