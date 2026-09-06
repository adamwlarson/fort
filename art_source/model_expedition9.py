"""Fort 9: authored silhouettes in independent scenes; preserve the open .blend."""
from pathlib import Path
from math import pi, sin, cos, tau
import bpy
ROOT=Path(__file__).resolve().parents[1]
KEYS=['weapon_cleaver','weapon_warpick','weapon_greatmaul','weapon_handcannon','weapon_longrifle','weapon_runestaff','weapon_runeblade','embercoil','gravitywell','sunlance','pet_badger','pet_mole','pet_sprite','shieldguard','prowler','hexer','colossus','biome_amberwood','biome_mycelium','biome_cinder','biome_glacier','biome_gardens']

def build():
    original=bpy.context.window.scene
    ns={'__name__':'fort9_geometry','__file__':str(ROOT/'art_source/model_raiders.py')}
    exec(compile((ROOT/'art_source/model_raiders.py').read_text(),'model_raiders.py','exec'),ns)
    ns['PALETTE'].update({'rune':'ad8de1','hot':'ef9b44','stone':'737b81','snow':'b6d5d6','amber':'c2a04d','leaf':'678363','mushroom':'936cad'})
    empty,box,taper,ring,ellipsoid=[ns[k] for k in ('empty','box','taper','ring','ellipsoid')]
    fin={'__name__':'fort9_finisher'}
    exec(compile((ROOT/'art_source/build_assets.py').read_text(),'build_assets.py','exec'),fin)
    results=[]
    try:
        for key in KEYS:
            if key in ('shieldguard','hexer','colossus'):
                scene=ns['enemy']('brute' if key=='colossus' else 'raider')
                root=next(o for o in scene.objects if o.parent is None);root.name=key
            else:
                scene=bpy.data.scenes.new('Fort9_'+key);bpy.context.window.scene=scene;root=empty(key)
            if key.startswith('weapon_'):
                kind=key.removeprefix('weapon_')
                if kind in ('handcannon','longrifle'):
                    length=1.25 if kind=='longrifle' else .65
                    box('CarvedStock',root,(0,.14,.10),(.20,.46,.19),'wood')
                    taper('Barrel',root,(0,0,.15),(0,-length,.15),.075 if kind=='longrifle' else .15,.09 if kind=='longrifle' else .24,'iron',12)
                    ring('FlaredMuzzle',root,(0,-length,.15),.09 if kind=='longrifle' else .24,.035,'gold',(pi/2,0,0))
                    for y in (-.18,-.40):ring('SteelBand',root,(0,y,.15),.10 if kind=='longrifle' else .18,.025,'gold',(pi/2,0,0))
                    box('Receiver',root,(0,-.05,.22),(.25,.24,.20),'iron')
                    taper('TriggerGuard',root,(.12,.08,.04),(.12,-.13,.04),.025,.025,'gold',8)
                    if kind=='longrifle':
                        taper('Scope',root,(0,-.10,.36),(0,-.58,.36),.055,.075,'gold',10)
                        ellipsoid('Lens',root,(0,-.59,.36),(.06,.025,.06),'glass')
                    else:
                        for x in (-.16,.16):ellipsoid('PowderChamber',root,(x,-.16,.22),(.08,.13,.09),'hot')
                else:
                    tall=1.35 if kind=='runestaff' else (.85 if kind=='greatmaul' else .65)
                    taper('WrappedHaft',root,(0,0,-.25),(0,0,tall),.045,.04,'wood',10)
                    for z in (-.1,.02,.14,.26):ring('GripBand',root,(0,0,z),.047,.015,'leather_light')
                    if kind=='greatmaul':
                        box('MassiveHammer',root,(0,0,.82),(1.15,.45,.48),'stone')
                        for side in (-1,1):
                            box('ForgedEndcap',root,(side*.5,0,.82),(.22,.51,.53),'iron')
                            box('GlowingRune',root,(side*.61,-.05,.82),(.025,.18,.28),'rune')
                        for x in (-.24,.24):box('GoldenStrap',root,(x,0,.82),(.075,.48,.51),'gold')
                    elif kind=='warpick':
                        taper('CurvedPick',root,(-.48,0,.72),(.35,0,.70),.015,.14,'edge',4)
                        taper('ArmorBeak',root,(-.48,0,.72),(-.62,0,.49),.07,0,'iron',4)
                        box('HammerPoll',root,(.34,0,.7),(.25,.22,.25),'iron')
                    elif kind=='cleaver':
                        box('WideCleaverBlade',root,(.22,0,.72),(.52,.065,.61),'edge',(0,-.18,0))
                        box('BlackSpine',root,(.0,0,.7),(.12,.10,.65),'iron')
                        taper('Point',root,(.25,0,.94),(.13,0,1.18),.14,0,'edge',4)
                    elif kind=='runeblade':
                        taper('RunicBlade',root,(0,0,.46),(0,0,1.55),.17,.012,'edge',4)
                        box('SweptGuard',root,(0,0,.43),(.63,.11,.10),'gold')
                        for z in (.65,.85,1.05):box('BladeRune',root,(0,-.085,z),(.065,.025,.1),'rune',(0,pi/4,0))
                        ellipsoid('PommelGem',root,(0,0,-.27),(.11,.09,.12),'rune')
                    else:
                        ring('RunicOrbit',root,(0,0,1.4),.32,.045,'gold',(pi/2,0,0))
                        taper('FloatingCrystal',root,(0,0,1.15),(0,0,1.92),.17,0,'rune',5)
                        for x in (-.29,.29):taper('CrownProng',root,(0,0,1.15),(x,0,1.75),.035,.015,'gold',8)
            elif key in ('embercoil','gravitywell','sunlance'):
                taper('StoneFoundation',root,(0,0,0),(0,0,.32),1.12,.98,'stone',8)
                for i in range(4):
                    a=i*pi/2;taper('Buttress',root,(sin(a)*.9,cos(a)*.9,.2),(sin(a)*.45,cos(a)*.45,1.5),.16,.1,'iron',6)
                if key=='embercoil':
                    taper('Furnace',root,(0,0,.3),(0,0,1.7),.52,.44,'iron',10)
                    for z in (.65,1.05,1.45):ring('CopperCoil',root,(0,0,z),.6,.08,'copper')
                    for i in range(6):
                        a=i*tau/6;taper('FlameVent',root,(sin(a)*.4,cos(a)*.4,1.5),(sin(a)*.78,cos(a)*.78,1.92),.11,.16,'gold',8)
                        ellipsoid('Ember',root,(sin(a)*.79,cos(a)*.79,1.96),(.10,.10,.19),'hot')
                    taper('Chimney',root,(0,0,1.6),(0,0,2.8),.23,.31,'iron',8)
                elif key=='gravitywell':
                    ellipsoid('SuspendedCore',root,(0,0,1.85),(.46,.46,.46),'rune',2)
                    for angle in (0,pi/3,2*pi/3):ring('Orbit',root,(0,0,1.85),.87,.065,'gold',(pi/2,angle,0))
                    for i in range(4):
                        a=i*pi/2;taper('CrystalAnchor',root,(sin(a)*.85,cos(a)*.85,.3),(sin(a)*.85,cos(a)*.85,1.35),.19,0,'rune',5)
                else:
                    taper('Column',root,(0,0,.3),(0,0,2.65),.38,.25,'iron',8)
                    for z in (.65,1.1,1.55,2.0):ring('InductionRing',root,(0,0,z),.46,.08,'gold')
                    turret=empty('Turret',root,(0,0,2.8))
                    taper('BeamEmitter',turret,(0,.4,0),(0,-1.3,0),.2,.32,'gold',12)
                    ellipsoid('FocusLens',turret,(0,-1.33,0),(.29,.07,.29),'hot',2)
                    for x in (-.48,.48):box('SolarPanel',turret,(x,.0,.10),(.38,1.3,.08),'teal',(0,x*.5,0))
            elif key in ('pet_badger','pet_mole','pet_sprite','prowler'):
                color='leather_light' if key=='pet_badger' else ('copper' if key=='pet_mole' else ('leaf' if key=='pet_sprite' else 'hood'))
                ellipsoid('RoundBody',root,(0,.06,.5),(.36,.52,.32),color,2)
                ellipsoid('Head',root,(0,-.46,.60),(.30,.29,.26),color,2)
                ellipsoid('Nose',root,(0,-.70,.54),(.13,.11,.09),'black',1)
                for side in (-1,1):
                    ellipsoid('BrightEye',root,(side*.16,-.68,.67),(.045,.027,.045),'eye' if key=='prowler' else 'black',2)
                    taper('Ear',root,(side*.23,-.4,.77),(side*.27,-.35,1.0),.10,0,'bone' if key=='pet_badger' else color,6)
                    box('SaddleBag',root,(side*.36,.13,.57),(.22,.36,.29),'leather')
                    box('BagClasp',root,(side*.48,.0,.58),(.045,.08,.1),'gold')
                    if key=='pet_badger':box('FaceStripe',root,(side*.12,-.63,.77),(.10,.13,.08),'bone',(0,side*.2,0))
                for idx,(x,y) in enumerate(((-.22,-.24),(.22,-.24),(-.22,.38),(.22,.38))):
                    leg=empty(['ArmL','ArmR','LegR','LegL'][idx],root,(x,y,.36))
                    taper('Paw',leg,(0,0,0),(0,-.02,-.27),.10,.075,color,7)
                    for dx in (-.04,.04):taper('Claw',leg,(dx,-.07,-.25),(dx,-.16,-.26),.02,0,'bone',5)
                if key=='pet_mole':
                    box('MinerHelmet',root,(0,-.44,.81),(.55,.40,.12),'iron')
                    ellipsoid('Headlamp',root,(0,-.66,.85),(.085,.04,.085),'hot')
                if key=='pet_sprite':
                    for side in (-1,1):ellipsoid('LeafWing',root,(side*.42,.15,.85),(.25,.08,.43),'leaf',1)
                    taper('Antenna',root,(0,-.43,.83),(0,-.3,1.2),.025,.01,'gold',6)
                    ellipsoid('GlowSeed',root,(0,-.30,1.2),(.09,.09,.11),'glass')
                if key=='prowler':
                    root.scale=(1.7,1.8,1.55)
                    for y in (-.1,.15,.4):taper('BackSpine',root,(0,y,.77),(0,y+.1,1.05),.11,0,'bone',5)
            elif key=='shieldguard':
                shield=empty('TowerShield',root,(-.52,-.36,.98))
                box('ShieldFace',shield,(0,0,0),(.72,.16,1.3),'iron')
                for x in (-.31,.31):box('GoldRail',shield,(x,-.1,0),(.06,.06,1.32),'gold')
                for z in (-.6,.6):box('Rim',shield,(0,-.1,z),(.69,.06,.08),'gold')
                taper('ShieldSpike',shield,(0,-.08,0),(0,-.38,0),.17,0,'edge',6)
                box('Crest',root,(0,0,1.85),(.12,.4,.32),'copper')
            elif key=='hexer':
                taper('TallHood',root,(0,0,1.5),(.05,.12,2.35),.39,0,'rune',7)
                for side in (-1,1):taper('ShoulderHorn',root,(side*.43,0,1.4),(side*.65,.05,1.95),.11,0,'bone',6)
                taper('RitualStaff',root,(.6,-.05,.25),(.6,-.05,2.2),.045,.04,'wood',8)
                ring('StaffCrown',root,(.6,-.05,2.15),.24,.04,'gold',(pi/2,0,0))
                ellipsoid('RitualGem',root,(.6,-.05,2.17),(.12,.1,.16),'rune')
            elif key=='colossus':
                root.scale=(2.7,2.7,2.7)
                for side in (-1,1):
                    box('MonolithShoulder',root,(side*.59,0,1.43),(.6,.62,.4),'stone')
                    for y in (-.16,.16):taper('CrownCrystal',root,(side*.58,y,1.6),(side*.64,y,2.05),.12,0,'rune',5)
                box('RuneChest',root,(0,-.36,1.04),(.57,.15,.48),'iron')
                for z in (.91,1.04,1.17):box('GlowingSigil',root,(0,-.45,z),(.27,.02,.05),'rune')
                ring('AncientCrown',root,(0,0,1.83),.42,.07,'gold')
            else:
                if key=='biome_amberwood':
                    for x,y,h in ((0,0,7),(-2,1,4),(2,1.5,5)):
                        taper('AncientTrunk',root,(x,y,0),(x+.3,y,h),.65,.25,'wood',8)
                        for i in range(4):
                            a=i*tau/4;taper('Bough',root,(x,y,h*.55),(x+sin(a)*2,y+cos(a)*2,h*.83),.19,.05,'wood',7)
                            ellipsoid('AmberCanopy',root,(x+sin(a)*1.9,y+cos(a)*1.9,h*.85),(1.8,1.5,1.1),'amber',1)
                elif key=='biome_mycelium':
                    for x,y,h in ((0,0,4),(-1.8,.4,2.7),(1.6,-.4,2)):
                        taper('MushroomStem',root,(x,y,0),(x+.2,y,h),.25,.36,'bone',9)
                        ellipsoid('MushroomCap',root,(x+.2,y,h),(h*.42,h*.42,.48),'mushroom',2)
                        ring('LuminousGills',root,(x+.2,y,h-.18),h*.33,.06,'glass')
                elif key=='biome_cinder':
                    for i in range(7):
                        a=i*2.4;h=2+i*.45;taper('BasaltColumn',root,(sin(a)*2,cos(a)*2,0),(sin(a)*2,cos(a)*2,h),.63,.51,'iron',6)
                        box('EmberCrack',root,(sin(a)*2-.1,cos(a)*2-.53,h*.5),(.055,.035,h*.7),'hot')
                elif key=='biome_glacier':
                    for i in range(7):
                        a=i*2.4;taper('IceShard',root,(sin(a)*2,cos(a)*2,0),(sin(a)*2.6,cos(a)*2.6,2+i*.6),.65,0,'snow' if i%2 else 'glass',5)
                else:
                    for x in (-2,2):
                        taper('RuinedPillar',root,(x,0,0),(x,0,4.2),.38,.34,'stone',8)
                        for z in (.3,3.8):box('Capital',root,(x,0,z),(1,1,.35),'stone')
                        for z in (1,2,3):ring('ClimbingVine',root,(x,0,z),.40,.09,'leaf')
                    box('AncientLintel',root,(0,0,4.1),(5,.9,.52),'stone')
                    ring('GardenSigil',root,(0,-.48,4.1),.27,.045,'gold',(pi/2,0,0))
                    for x in (-1.2,1.2):ellipsoid('Overgrowth',root,(x,.15,.35),(1,.7,.35),'leaf',1)
            results.append(fin['finish_asset'](key,scene))
    finally:
        bpy.context.window.scene=original
    return results
