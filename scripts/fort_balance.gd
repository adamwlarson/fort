class_name FortBalance
extends RefCounted

# Threat points, not hit points: specialists consume a larger part of each assault.
const COST := {"Raider":10,"EmberRunner":13,"Brute":30,"Ashwing":18,"Sapper":25,"Cinderlobber":30,"Bombwing":35,"Shieldguard":24,"Prowler":16,"Hexer":32}
const CREW := [1.0,1.75,2.6,3.5,4.45,5.45,6.5,7.6]
const FRONT_NAMES := ["SOUTH","EAST","NORTH","WEST"]

static func budget(night:int,hearth:int,crew:int)->int:
	var n:=mini(29,maxi(0,night-1))
	return roundi((70+18*n+4*n*n+maxi(0,night-30)*80)*10*CREW[clampi(crew,1,GameData.MAX_PLAYERS)-1]*(1+.1*(clampi(hearth,1,GameData.MAX_HEARTH)-1)))

static func active_cap(night:int,crew:int)->int:
	crew=clampi(crew,1,GameData.MAX_PLAYERS)
	return mini(100,roundi(22+(crew-1)*12+maxi(0,night-1)*(3+crew*.5)))

static func fronts(night:int,crew:int)->int:
	return mini(4,clampi(crew,1,4)+(1 if crew==1 and night>=6 else 0))

static func category(kind:String)->String:
	return "bombard" if kind in ["Cinderlobber","Bombwing"] else kind

static func special_cap(kind:String,night:int,crew:int)->int:
	match category(kind):
		"Hexer":return crew
		"Shieldguard":return crew+2
		"Sapper":return crew
		"bombard":return (1 if night<7 else 2) if crew==1 else crew+1
		"Brute":return crew+1+int(night/4)
		"Ashwing":return crew+1+int(night/3)
	return 100

static func pool(night:int)->Array[String]:
	var result:Array[String]=["Raider","Raider","Raider","Raider","Raider","Raider","Raider","Raider","EmberRunner","EmberRunner"]
	if night>=2:result.append_array(["Brute","Brute","Ashwing","Ashwing"])
	if night>=3:result.append_array(["Sapper","Cinderlobber"])
	if night>=4:result.append("Bombwing")
	if night>=6:result.append("Prowler")
	if night>=8:result.append("Shieldguard")
	if night>=12:result.append("Hexer")
	return result

static func camp(tier:int,crew:int)->Dictionary:
	crew=clampi(crew,1,GameData.MAX_PLAYERS)
	return {"crew":crew,"escorts":crew,"boss_hp":(650.0+tier*100)*(.65+.35*(crew-1)),"guard_hp":(100.0+tier*20)*(1+.08*(crew-1))}

static func wilderness_multiplier(crew:int)->float:return [1.0,1.3,1.65,2.0,2.35,2.7,3.05,3.4][clampi(crew,1,GameData.MAX_PLAYERS)-1]
static func colossus_multiplier(crew:int)->float:return [.8,1.25,1.7,2.2,2.7,3.2,3.7,4.2][clampi(crew,1,GameData.MAX_PLAYERS)-1]

static func work_multiplier(crew:int)->float:return 1.25 if crew==1 else 1.0
