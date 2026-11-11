class_name FortRaze
extends RefCounted

# Castle wings may be built over an enemy base once the crew has cleared it.
# Razed bases are removed for good: no guards, no chest, no respawn.

## Describes the base that owns a protected keep-out, or {} for landmarks and terrain.
static func find(world:FortWorld,obstacle:Dictionary)->Dictionary:
	if obstacle.get("terrain",false) or obstacle.get("clearable",false) or obstacle.has("node"):return {}
	if obstacle.get("wilderness",false):
		for id in world.encounters.sites:
			var site:Dictionary=world.encounters.sites[id]
			if FortGround.flat(site.spec.pos,obstacle.pos)<.1:
				return {"key":"wild:%d"%int(id),"name":site.spec.name,"cleared":site.phase in ["cleared","claimed"],"village":false}
		return {}
	for i in FortProgression.SITES.size():
		if FortGround.flat(FortProgression.SITES[i].pos,obstacle.pos)<.1:
			var spec:Dictionary=FortProgression.SITES[i]
			var cleared:bool=world.progression.sites.has(i) and (world.progression.sites[i].opened or not spec.guards)
			return {"key":"camp:%d"%i,"name":spec.name,"cleared":cleared,"village":spec.get("village",false)}
	return {}

## "" when the wing may cover this keep-out, otherwise a clear reason.
static func reason(world:FortWorld,obstacle:Dictionary)->String:
	var base:=find(world,obstacle)
	if base.is_empty():
		return "A hill or landmark is in the way. Build this room in another direction." if obstacle.get("terrain",false) else "A protected landmark is in the way. Build this room in another direction."
	if base.village:return "%s is a village, not an enemy base. Build this room in another direction."%base.name
	if not base.cleared:return "Enemy base in the way: %s. Defeat its guards and open its chest, then build over it."%base.name
	return ""

static func raze_under(c:FortCastle,target:Dictionary)->void:
	var names:PackedStringArray=[]
	for obstacle in c.world.scenery_keepouts:
		if obstacle.get("clearable",false) or not FortCastleClearance.scenery_overlap(target,obstacle):continue
		var base:=find(c.world,obstacle)
		if base.is_empty() or not base.cleared or base.village:continue
		c.razed[base.key]=true;names.append(base.name)
	if names.is_empty():return
	apply(c)
	c.world.broadcast("recv_notice",["BASE RAZED / %s cleared away for the castle. It will not return."%", ".join(names)])

static func apply(c:FortCastle)->void:
	for key in c.razed:
		var parts:=str(key).split(":");var id:=int(parts[1])
		var site:Dictionary={};var pos:=Vector3.INF
		if parts[0]=="wild" and c.world.encounters.sites.has(id):
			site=c.world.encounters.sites[id];pos=site.spec.pos
		elif parts[0]=="camp" and c.world.progression.sites.has(id):
			site=c.world.progression.sites[id];pos=FortProgression.SITES[id].pos
		if site.is_empty() or site.get("razed",false):continue
		site.razed=true
		var node:Node=site.get("node")
		if is_instance_valid(node):
			# Stay in the tree (still owned and freed with the world) but vanish and stop colliding.
			node.visible=false;node.process_mode=Node.PROCESS_MODE_DISABLED
			for body in node.find_children("*","CollisionObject3D",true,false):body.collision_layer=0;body.collision_mask=0
		for i in range(c.world.scenery_keepouts.size()-1,-1,-1):
			var obstacle:Dictionary=c.world.scenery_keepouts[i]
			if not obstacle.get("clearable",false) and not obstacle.get("terrain",false) and obstacle.pos.distance_to(pos)<.1:c.world.scenery_keepouts.remove_at(i)
