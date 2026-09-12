"""Blender-built camp props; shares the art-pass palette and geometry helpers."""
from pathlib import Path
from math import pi, sin, cos, tau
import bpy

ROOT=Path(__file__).resolve().parents[1]
_helpers={'__name__':'fort_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),_helpers)
empty,box,taper,ellipsoid,ring,mesh=[_helpers[k] for k in ('empty','box','taper','ellipsoid','ring','mesh')]

def barrel(parent,pos=(0,0,0),scale=1):
    root=empty('CooperedBarrel',parent,pos)
    root.scale=(scale,scale,scale)
    for i in range(12):
        verts=[]
        for z,r in ((0.04,0.34),(0.20,0.40),(0.54,0.43),(0.87,0.40),(1.02,0.34)):
            for angle in ((i+0.04)*tau/12,(i+0.96)*tau/12):verts.append((sin(angle)*r,cos(angle)*r,z))
        faces=[(j*2+2,j*2+3,j*2+1,j*2) for j in range(4)]
        mesh('OakStave',root,verts,faces,'wood' if i%3 else 'leather_light')
    for z,r in ((0.18,0.403),(0.84,0.409)):
        ring('IronHoop',root,(0,0,z),r,0.033,'iron')
        for i in range(6):
            a=i*tau/6
            ellipsoid('HoopRivet',root,(sin(a)*(r+0.02),cos(a)*(r+0.02),z),(0.021,0.021,0.021),'edge',1)
    taper('BarrelLid',root,(0,0,0.98),(0,0,1.015),0.337,0.337,'wood',12)
    for y in (-0.14,0,0.14):box('LidSeam',root,(0,y,1.018),(0.58,0.012,0.012),'leather')
    taper('Bung',root,(0.14,0,1.015),(0.14,0,1.05),0.04,0.04,'leather_light')
    return root

def crate(parent,pos=(0,0,0),scale=1):
    root=empty('BracedCrate',parent,pos)
    root.scale=(scale,scale,scale)
    for i in range(4):
        for side in (-1,1):
            box('CrateFacePlank',root,((i-1.5)*0.205,side*0.42,0.42),(0.192,0.08,0.82),'wood' if i%2 else 'leather_light')
            box('CrateSidePlank',root,(side*0.42,(i-1.5)*0.205,0.42),(0.08,0.192,0.82),'wood')
        box('LidPlank',root,((i-1.5)*0.205,0,0.87),(0.192,0.86,0.07),'wood')
    for side in (-1,1):
        for z in (0.09,0.76):box('CrateBrace',root,(0,side*0.47,z),(0.95,0.075,0.12),'leather_light')
        box('DiagonalBrace',root,(0,side*0.51,0.43),(0.10,0.06,0.91),'leather_light',(0,0.79,0))
        for x in (-0.36,0.36):
            for z in (0.09,0.76):ellipsoid('CrateNail',root,(x,side*0.516,z),(0.025,0.012,0.025),'iron',1)
    return root

def workshop(parent):
    for x in (-1.25,1.25):
        for y in (-0.8,0.8):
            box('StonePostShoe',parent,(x,y,0.14),(0.35,0.35,0.28),'iron')
            box('OakPost',parent,(x,y,1.38),(0.19,0.19,2.43),'wood')
            taper('PostBrace',parent,(x,y,2.13),(x*0.60,y,2.53),0.065,0.065,'leather_light',4)
    for y in (-0.87,0.87):
        box('GableBeam',parent,(0,y,2.50),(2.8,0.17,0.18),'wood')
        for side in (-1,1):taper('GableRafter',parent,(0,y,3.15),(side*1.58,y,2.52),0.085,0.085,'leather_light',4)
    box('RidgeCap',parent,(0,0,3.19),(0.20,2.40,0.17),'gold')
    for side in (-1,1):
        for row in range(4):
            x=side*(0.19+row*0.37)
            for col in range(7):
                y=(col-3)*0.32+(0.055 if row%2 else 0)
                box('TealRoofShingle',parent,(x,y,3.13-abs(x)*0.40),(0.45,0.335,0.085),'teal' if (col+row)%4 else 'hood',(0,side*0.38,0))
    # Heavy plank workbench with vise, hanging tongs, ingots and a shaped anvil.
    for x in (-0.83,0.83):
        for y in (-0.40,0.40):box('BenchLeg',parent,(x,y,0.47),(0.16,0.16,0.91),'wood')
    for i in range(5):box('BenchPlank',parent,(0,(i-2)*0.22,0.95),(2.21,0.205,0.13),'leather_light')
    box('AnvilFoot',parent,(-0.18,0,1.09),(0.69,0.43,0.14),'iron')
    taper('AnvilWaist',parent,(-0.18,0,1.15),(-0.18,0,1.36),0.24,0.15,'iron',4)
    box('AnvilFace',parent,(-0.12,0,1.43),(0.77,0.38,0.15),'edge')
    taper('AnvilHorn',parent,(0.22,0,1.44),(0.73,0,1.43),0.16,0.016,'edge')
    box('ViseJaw',parent,(-0.91,-0.58,1.05),(0.30,0.20,0.17),'iron')
    taper('ViseScrew',parent,(-0.91,-0.56,0.84),(-0.91,-0.78,0.84),0.034,0.034,'edge')
    taper('ViseHandle',parent,(-0.91,-0.80,0.70),(-0.91,-0.80,0.98),0.022,0.022,'gold')
    for i in range(3):box('CopperIngot',parent,(0.65,(i-1)*0.15,1.08),(0.31,0.11,0.10),'copper')
    for x in (-0.35,0.0,0.35):
        taper('HangingTool',parent,(x,-0.61,0.81),(x,-0.61,0.43),0.022,0.022,'iron')
        ring('ToolLoop',parent,(x,-0.61,0.80),0.047,0.012,'iron',(pi/2,0,0))
    # Forge insignia under the gable, readable even from the default camera.
    box('ForgeSign',parent,(0,-0.97,2.16),(0.86,0.10,0.49),'hood')
    box('SignHammerHead',parent,(0,-1.04,2.25),(0.40,0.035,0.12),'gold')
    box('SignHammerHandle',parent,(0,-1.04,2.10),(0.085,0.035,0.28),'gold')

def stockpile(parent):
    crate(parent,(-0.65,0,0),0.85)
    crate(parent,(0.08,0.10,0),0.80)
    barrel(parent,(0.85,0,0),0.83)
    for i in range(4):
        x=-0.84+i*0.21
        taper('StoredLog',parent,(x,-0.32,0.85),(x,0.48,0.85),0.095,0.105,'wood',9)
        taper('LogCutEnd',parent,(x,-0.331,0.85),(x,-0.34,0.85),0.075,0.075,'leather_light',9)
    for i in range(3):
        box('StockIngot',parent,(0.01,(i-1)*0.18,0.87),(0.30,0.15,0.12),'edge')
    box('SharedInventoryPlate',parent,(-0.36,-0.50,0.40),(0.34,0.05,0.24),'hood')
    box('PlateRuneVertical',parent,(-0.36,-0.535,0.40),(0.045,0.02,0.16),'gold')
    box('PlateRuneHorizontal',parent,(-0.36,-0.535,0.40),(0.19,0.02,0.045),'gold')

def build():
    original=bpy.context.window.scene
    exporter={'__name__':'fort_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),exporter)
    results=[]
    try:
        for key,builder in (('barrel',barrel),('supply_crate',crate),('workshop',workshop),('stockpile',stockpile)):
            scene=bpy.data.scenes.new('Fort_Camp_'+key)
            bpy.context.window.scene=scene
            root=empty(key)
            builder(root)
            results.append(exporter['finish_asset'](key,scene))
    finally:
        bpy.context.window.scene=original
    return results

if __name__=='__main__':print(build())
