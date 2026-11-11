class_name FortGround
extends RefCounted

# Fort 30: one height field for the whole world.
#
# height(x,z) is rebuilt from the expedition seed on every machine, so hosts, guests and
# saves agree without sending any terrain. Hearthhold stays level at y=0. Every authored
# site (camps, villages, landmarks, wilderness encounters, the quarry and the ridge) sits on
# a level shelf cut into the hills at its own height, and castle rooms and foundations level
# the ground beneath them. Everything else is placed "as if the ground were y=0" and then
# registered here, which lifts it onto the surface and keeps it there when the land changes.

const CHUNK:=96.0
const GRID:=20
const HALF:=960.0
const FINE:=2.0
const COARSE:=12.0
const FN:=48
const CN:=8
const HOME:=38.0
## Automated fixtures place walls and raiders at fixed meadow coordinates; keep that ring level for them.
const TEST_HOME:=76.0
const FINE_VIEW:=430.0
const PEAKS_START:=655.0
## Hollows below this height hold water. Lake beds are never deeper than WADE, so every
## lake and pond can be waded: nothing in the game has to swim.
const WATER:=-4.0
const WADE:=1.15

static var built_world:=0
static var seed_value:=-1
static var revision:=0
static var root:Node3D
static var material:ShaderMaterial
static var water_material:ShaderMaterial
static var home:=HOME
## Tests set this to exercise the real slopes close to the hearth.
static var home_override:=-1.0
static var headless:=false
static var large:FastNoiseLite
static var hills:FastNoiseLite
static var detail:FastNoiseLite
static var peaks:FastNoiseLite
static var pads:Array=[]
static var levelled:Array=[]
static var levelled_key:=""
static var chunk_pads:Array=[]
static var fine:Array=[]
static var nodes:Array=[]
static var fine_radius:=0.0
static var grounded:Array=[]
static var resource_count:=-1
static var weight:=0.0
static var ward:=73.0
static var index_cache:Dictionary={}
static var walkers:Array=[]

# ---------------------------------------------------------------- queries
static func flat(a:Vector3,b:Vector3)->float:
	return Vector2(a.x-b.x,a.z-b.z).length()

static func on(pos:Vector3,offset:=0.0)->Vector3:
	return Vector3(pos.x,height(pos.x,pos.z)+offset,pos.z)

## The shape of the land before any site or building has levelled it.
static func natural(x:float,z:float)->float:
	var r:=sqrt(x*x+z*z)
	if r<=home or large==null:return 0.0
	var t:=minf((r-home)/52.0,1.0)
	var env:=t*t*(3.0-2.0*t)
	var far:=1.0
	if r>200.0:
		var f:=minf((r-200.0)/360.0,1.0);far+=f*f*(3.0-2.0*f)*.9
	var h:=large.get_noise_2d(x,z)*32.0*far+hills.get_noise_2d(x,z)*9.5+detail.get_noise_2d(x,z)*.9
	# Hollows are shallower than the hills are tall.
	# (Far out the hills grow taller but the hollows do not grow deeper, or the outer rings would flood.)
	var hollow:=(1.0-.45/far)*.5
	h=(1.0-hollow)*h+hollow*(sqrt(h*h+1.0)-1.0)
	# The four expedition roads follow gentler ground.
	# Their verges widen further out, where the hills beside them are taller.
	var lane:=minf(absf(x),absf(z));var verge:=31.0+r*.14
	if lane<3.0+verge:
		var l:=maxf((lane-3.0)/verge,0.0);h*=.3+.7*l*l*(3.0-2.0*l)
	h*=env
	if r<PEAKS_START:
		# The roads cross wet ground on a low causeway.
		if lane<12.0 and h<WATER+.45:
			var c:=1.0-clampf((lane-5.0)/7.0,0.0,1.0);h+=(WATER+.45-h)*c*c*(3.0-2.0*c)
		if h<WATER:h=WATER-WADE*(1.0-exp((h-WATER)/WADE))
	if r>PEAKS_START:
		# Beyond the last ring the land climbs into a wall of real mountains.
		var m:=minf((r-PEAKS_START)/290.0,1.0);m=m*m*(3.0-2.0*m)
		var ridge:=peaks.get_noise_2d(x,z)*.5+.5
		h+=m*(34.0+ridge*ridge*250.0*(.62+.38*large.get_noise_2d(z*1.7,x*1.7)))
	return h

## Inside a shelf the ground is exactly its height. Around it the land eases back to its
## natural shape, and where two shelves meet their slopes share the ground between them.
static func _blend(x:float,z:float,h:float,list:Array)->float:
	weight=0.0
	var total:=0.0;var sum:=0.0
	for pad:PackedFloat32Array in list:
		var d:float
		if pad[0]<.5:
			d=sqrt((x-pad[1])*(x-pad[1])+(z-pad[2])*(z-pad[2]))-pad[3]
		else:
			var dx:=maxf(absf(x-pad[1])-pad[3],0.0);var dz:=maxf(absf(z-pad[2])-pad[4],0.0);d=sqrt(dx*dx+dz*dz)
		if d>=pad[5]:continue
		if d<=0.0:
			weight=1.0;return pad[6]
		var t:=1.0-d/pad[5];var w:=t*t*(3.0-2.0*t)
		var pull:=w/(1.0001-w)
		total+=pull;sum+=pull*pad[6]
		if w>weight:weight=w
	return h if total<=0.0 else h+(sum/total-h)*weight

static func _computed(x:float,z:float)->float:
	var h:=natural(x,z)
	var gx:=int(floorf((x+HALF)/CHUNK));var gz:=int(floorf((z+HALF)/CHUNK))
	if gx<0 or gz<0 or gx>=GRID or gz>=GRID or chunk_pads.is_empty():return h
	var list:=_pads_for(gx+gz*GRID)
	return h if list.is_empty() else _blend(x,z,h,list)

## Ground height. Inside the playable land this reads the same triangles that are drawn and collided with.
static func height(x:float,z:float)->float:
	var fx:=(x+HALF)/CHUNK;var fz:=(z+HALF)/CHUNK
	if fx>=0.0 and fz>=0.0 and fx<GRID and fz<GRID and not fine.is_empty():
		var cx:=int(fx);var cz:=int(fz)
		var data:PackedFloat32Array=fine[cx+cz*GRID]
		if not data.is_empty():
			var u:=(fx-cx)*FN;var v:=(fz-cz)*FN
			var i:=mini(int(u),FN-1);var j:=mini(int(v),FN-1)
			u-=i;v-=j
			var at:=i+j*(FN+1)
			# Same two triangles per cell as the mesh and the heightfield collider.
			var h10:=data[at+1];var h01:=data[at+FN+1]
			if u+v<=1.0:
				var h00:=data[at]
				return h00+u*(h10-h00)+v*(h01-h00)
			var h11:=data[at+FN+2]
			return h11+(1.0-u)*(h01-h11)+(1.0-v)*(h10-h11)
	return _computed(x,z)

static func wet(x:float,z:float)->bool:
	return height(x,z)<WATER-.05

## Nearest dry spot to a map position. Uses the exact field, so every machine agrees.
static func dry(pos:Vector3)->Vector3:
	if _computed(pos.x,pos.z)>WATER+.2:return pos
	# Far enough to reach the shore of the broadest lake a seed can make.
	for ring in range(1,70):
		for step in 12:
			var a:=step*TAU/12.0+ring*.4
			var at:=pos+Vector3(sin(a),0,cos(a))*ring*3.0
			if _computed(at.x,at.z)>WATER+.2:return at
	return pos

static func slope(x:float,z:float)->float:
	return Vector2(height(x+1.0,z)-height(x-1.0,z),height(x,z+1.0)-height(x,z-1.0)).length()*.5

static func normal(x:float,z:float)->Vector3:
	return Vector3(height(x-1.0,z)-height(x+1.0,z),2.0,height(x,z-1.0)-height(x,z+1.0)).normalized()

# ---------------------------------------------------------------- pads
static func _circle(x:float,z:float,radius:float)->PackedFloat32Array:
	var h:=(natural(x,z)*2.0+natural(x+radius*.6,z)+natural(x-radius*.6,z)+natural(x,z+radius*.6)+natural(x,z-radius*.6))/6.0
	return PackedFloat32Array([0.0,x,z,radius,0.0,10.0,h])

## Open ground between two shelves. Close neighbours at very different heights would
## leave a cliff between them, so they are joined onto one level instead.
static func _gap(a:PackedFloat32Array,b:PackedFloat32Array)->float:
	if a[0]>.5 and b[0]<.5:return _gap(b,a)
	if b[0]<.5:return Vector2(a[1]-b[1],a[2]-b[2]).length()-a[3]-b[3]
	return Vector2(maxf(absf(a[1]-b[1])-b[3],0.0),maxf(absf(a[2]-b[2])-b[4],0.0)).length()-a[3]

static func _collect(world:FortWorld)->void:
	pads.clear()
	var owners:Array=[]
	# Hearthhold itself is the first shelf, fixed at y=0. Sites that crowd it share its level.
	pads.append(PackedFloat32Array([0.0,0.0,0.0,home,0.0,6.0,0.0]));owners.append(null)
	for landmark in FortLandscape.LANDMARKS:
		pads.append(_circle(landmark.pos.x,landmark.pos.z,11.0));owners.append(landmark)
	for site in FortProgression.SITES:
		pads.append(_circle(site.pos.x,site.pos.z,17.0 if site.get("village",false) else 12.0));owners.append(site)
	for spec in FortEncounters.layout(seed_value):
		pads.append(_circle(spec.pos.x,spec.pos.z,float(spec.radius)+1.5));owners.append(spec)
	# Rustscar Quarry: authored terraces, ramps and rails need one level shelf.
	var quarry:=_circle(120.0,7.0,30.0)
	pads.append(PackedFloat32Array([1.0,120.0,7.0,30.0,39.0,18.0,quarry[6]]));owners.append(null)
	# Hollowback Ridge keeps its own authored hill and cavern on a level base.
	var ridge:=FortTerrain.origin(seed_value)
	pads.append(_circle(ridge.x,ridge.z,33.0));owners.append(null)
	# Shelves that touch share one height, so neither is cut by the other.
	var group:PackedInt32Array=[]
	for i in pads.size():group.append(i)
	for attempt in 4:
		var joined:=false
		for i in pads.size():
			for j in range(i+1,pads.size()):
				if group[i]!=group[j] and _gap(pads[i],pads[j])<6.0+absf(pads[i][6]-pads[j][6])*4.5:
					var from:=group[j];var to:=group[i];joined=true
					for k in pads.size():
						if group[k]==from:group[k]=to
		var level:PackedFloat32Array=[]
		for i in pads.size():
			var sum:=0.0;var count:=0
			for j in pads.size():
				if group[j]==group[i]:sum+=pads[j][6];count+=1
			# No camp is founded in a lake.
			level.append(0.0 if group[i]==group[0] else maxf(sum/count,WATER+.7))
		for i in pads.size():
			var shared:PackedFloat32Array=pads[i];shared[6]=level[i];pads[i]=shared
		if not joined:break
	for i in range(1,pads.size()):
		var pad:PackedFloat32Array=pads[i]
		# Shelves cut deeper into the hills ease out over a wider apron.
		var reach:=pad[3] if pad[0]<.5 else maxf(pad[3],pad[4])
		var worst:=0.0
		for step in 24:
			var a:=step*TAU/8.0;var out:=reach+(step/8)*9.0
			worst=maxf(worst,absf(natural(pad[1]+sin(a)*out,pad[2]+cos(a)*out)-pad[6]))
		pad[5]=clampf(6.0+worst*3.6,6.0 if pad[0]<.5 else 18.0,72.0)
		pads[i]=pad
		if owners[i]!=null:owners[i].pos=Vector3(owners[i].pos.x,pad[6],owners[i].pos.z)

static func _pads_for(ci:int)->Array:
	var cached=chunk_pads[ci]
	if cached!=null:return cached
	var x0:=(ci%GRID)*CHUNK-HALF-COARSE;var z0:=(ci/GRID)*CHUNK-HALF-COARSE
	var x1:=x0+CHUNK+COARSE*2.0;var z1:=z0+CHUNK+COARSE*2.0
	var list:Array=[]
	# Buildings come first: where a room meets a camp shelf the room stays level.
	for source in [levelled,pads]:
		for pad:PackedFloat32Array in source:
			var ex:=pad[3]+pad[5];var ez:=(pad[3] if pad[0]<.5 else pad[4])+pad[5]
			if pad[1]+ex<x0 or pad[1]-ex>x1 or pad[2]+ez<z0 or pad[2]-ez>z1:continue
			list.append(pad)
	chunk_pads[ci]=list
	return list

## Castle rooms and foundations cut level ground for themselves.
static func _levelled(world:FortWorld)->Array:
	var list:Array=[]
	if world.castle:
		for room in world.castle.rooms.values():
			if int(room.floor)!=0 or str(room.kind)=="Keep":continue
			list.append(PackedFloat32Array([1.0,float(room.x)*FortCastle.CELL,float(room.z)*FortCastle.CELL,12.5,12.5,7.0,0.0]))
	if world.castle:
		# Farm plots just inside the outer wall stand on level beds too.
		for i in FortFarms.plots(world.castle).size():
			var plot:=FortFarms.position(world.castle,i)
			list.append(PackedFloat32Array([1.0,plot.x,plot.z,6.5,6.5,5.0,0.0]))
	if world.pieces:
		for at in world.pieces.ground_cells():
			list.append(PackedFloat32Array([1.0,at.x,at.y,2.5,2.5,2.6,0.0]))
	return list

static func _signature(list:Array)->String:
	var parts:PackedStringArray=[]
	for pad:PackedFloat32Array in list:parts.append("%d,%d,%d"%[roundi(pad[1]*2),roundi(pad[2]*2),roundi(pad[3]*2)])
	parts.sort()
	return ",".join(parts)

static func _sync_levelled(world:FortWorld)->void:
	var stamp:="%d/%d/%s"%[world.castle.revision if world.castle else -1,world.pieces.ground_revision if world.pieces else -1,str(world.castle.perimeter.get("bounds")) if world.castle else ""]
	if stamp==str(root.get_meta("stamp","")):return
	root.set_meta("stamp",stamp)
	var next:=_levelled(world);var key:=_signature(next)
	if key==levelled_key:return
	# Only the land around rooms that appeared or disappeared is rebuilt.
	var before:Dictionary={};var after:Dictionary={}
	for pad:PackedFloat32Array in levelled:before["%d,%d,%d"%[roundi(pad[1]*2),roundi(pad[2]*2),roundi(pad[3]*2)]]=pad
	for pad:PackedFloat32Array in next:after["%d,%d,%d"%[roundi(pad[1]*2),roundi(pad[2]*2),roundi(pad[3]*2)]]=pad
	var changed:Array=[]
	for k in before:
		if not after.has(k):changed.append(before[k])
	for k in after:
		if not before.has(k):changed.append(after[k])
	levelled=next;levelled_key=key
	if changed.is_empty():return
	var area:=Rect2(changed[0][1],changed[0][2],0,0)
	for pad:PackedFloat32Array in changed:
		var reach:=pad[3]+pad[5]+FINE
		area=area.merge(Rect2(pad[1]-reach,pad[2]-reach,reach*2,reach*2))
	for ci in GRID*GRID:
		var rect:=Rect2((ci%GRID)*CHUNK-HALF-COARSE,(ci/GRID)*CHUNK-HALF-COARSE,CHUNK+COARSE*2,CHUNK+COARSE*2)
		if not rect.intersects(area):continue
		chunk_pads[ci]=null
		if not fine[ci].is_empty():_make_fine(ci)
		elif not headless:_make_coarse(ci)
	revision+=1
	resettle(area)
	# Nobody is left underground when a hollow is filled in.
	for group in [world.players.values(),world.pets.pets.values() if world.pets else [],world.enemies.values()]:
		for item in group:
			var body:Node3D=item if item is Node3D else item.node
			if not area.has_point(Vector2(body.position.x,body.position.z)):continue
			var h:=height(body.position.x,body.position.z)
			if body.position.y<h-.02:
				body.position.y=h+.05
				if body is FortPlayer:body.target_position=body.position
	world.navigation_revision+=1

# ---------------------------------------------------------------- building
static func ensure(world:FortWorld)->void:
	if not world.expedition:return
	if built_world!=world.get_instance_id() or seed_value!=world.expedition.seed_value or not is_instance_valid(root):build(world)
	if _wanted(world)>fine_radius:_grow(world)
	_sync_levelled(world)
	if world.resource_nodes.size()!=resource_count:
		resource_count=world.resource_nodes.size()
		for resource in world.resource_nodes.values():
			var node:Node3D=resource.node
			if is_instance_valid(node) and not node.has_meta("grounded"):
				# Trees and ore that would stand in a lake grow on its shore instead.
				var authored:=node.position
				node.set_meta("ground_origin",authored)
				var shore:=dry(authored);node.position.x=shore.x;node.position.z=shore.z
				ground(node,authored.y,.3)

static func _wanted(world:FortWorld)->float:
	var want:=world.frontier_radius()+34.0
	return want if headless else maxf(want,180.0)

static func build(world:FortWorld)->void:
	if is_instance_valid(root):
		root.get_parent().remove_child(root);root.queue_free()
	built_world=world.get_instance_id();seed_value=world.expedition.seed_value
	headless=DisplayServer.get_name()=="headless"
	home=home_override if home_override>=0.0 else (TEST_HOME if "--fort-test" in OS.get_cmdline_user_args() else HOME)
	large=_noise(seed_value+11,1.0/520.0,3,false);hills=_noise(seed_value+23,1.0/130.0,3,false)
	detail=_noise(seed_value+37,1.0/26.0,2,false);peaks=_noise(seed_value+41,1.0/420.0,3,true)
	root=Node3D.new();root.name="MarchTerrain";world.add_child(root);world.move_child(root,0)
	if not material:
		material=ShaderMaterial.new();material.shader=load("res://assets/shaders/terrain_ground.gdshader")
	material.set_shader_parameter("ward_radius",ward)
	material.set_shader_parameter("water_level",WATER)
	if not water_material:
		water_material=ShaderMaterial.new();water_material.shader=load("res://assets/shaders/terrain_water.gdshader")
	var tints:PackedColorArray=[]
	for level in range(4,9):tints.append(world.expedition.biome(level).color)
	material.set_shader_parameter("ring_color",tints)
	fine.clear();nodes.clear();chunk_pads.clear()
	for i in GRID*GRID:fine.append(PackedFloat32Array());nodes.append({});chunk_pads.append(null)
	_collect(world)
	levelled=_levelled(world);levelled_key=_signature(levelled);root.set_meta("stamp","")
	fine_radius=0.0
	if not headless:
		for ci in GRID*GRID:_make_coarse(ci)
	_grow(world)
	revision+=1
	for resource in world.resource_nodes.values():
		var node:Node3D=resource.node
		if is_instance_valid(node) and node.has_meta("ground_origin"):
			var shore:=dry(node.get_meta("ground_origin"));node.position.x=shore.x;node.position.z=shore.z
	resettle()

static func _noise(noise_seed:int,frequency:float,octaves:int,ridged:bool)->FastNoiseLite:
	var noise:=FastNoiseLite.new()
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH;noise.seed=noise_seed;noise.frequency=frequency
	noise.fractal_type=FastNoiseLite.FRACTAL_RIDGED if ridged else FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves=octaves;noise.fractal_gain=.48;noise.fractal_lacunarity=2.1
	return noise

static func _grow(world:FortWorld)->void:
	fine_radius=_wanted(world)
	for ci in GRID*GRID:
		if not fine[ci].is_empty():continue
		var cx:=((ci%GRID)+.5)*CHUNK-HALF;var cz:=((ci/GRID)+.5)*CHUNK-HALF
		if Vector2(maxf(absf(cx)-CHUNK*.5,0.0),maxf(absf(cz)-CHUNK*.5,0.0)).length()<fine_radius:_make_fine(ci)
	revision+=1

## Heights on an (n+3)² lattice: the chunk plus one cell all round, so normals match across seams.
static func _sample(ci:int,cell:float,n:int)->Array:
	var side:=n+3
	var heights:=PackedFloat32Array();heights.resize(side*side)
	var weights:=PackedFloat32Array();weights.resize(side*side)
	var x0:=(ci%GRID)*CHUNK-HALF-cell;var z0:=(ci/GRID)*CHUNK-HALF-cell
	var list:=_pads_for(ci);var padded:=not list.is_empty()
	var at:=0
	for j in side:
		var z:=z0+j*cell
		for i in side:
			var x:=x0+i*cell
			var h:=natural(x,z)
			if padded:
				h=_blend(x,z,h,list);weights[at]=weight
			heights[at]=h;at+=1
	return [heights,weights]

static func _mesh(heights:PackedFloat32Array,weights:PackedFloat32Array,cell:float,n:int,skirt:float)->ArrayMesh:
	var side:=n+3;var row:=n+1
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
	vertices.resize(row*row);normals.resize(row*row);colors.resize(row*row)
	var half:=CHUNK*.5
	for j in row:
		for i in row:
			var s:=(i+1)+(j+1)*side
			var v:=i+j*row
			vertices[v]=Vector3(i*cell-half,heights[s],j*cell-half)
			normals[v]=Vector3(heights[s-1]-heights[s+1],2.0*cell,heights[s-side]-heights[s+side]).normalized()
			colors[v]=Color(weights[s],0,0)
	# A short curtain under every edge hides the seams between detail levels.
	for edge in 4:
		for i in row:
			var v:int=i if edge==0 else (i+n*row if edge==1 else (i*row if edge==2 else i*row+n))
			vertices.append(vertices[v]-Vector3(0,skirt,0));normals.append(normals[v]);colors.append(colors[v])
	if not index_cache.has(n):
		indices.resize(n*n*6)
		var k:=0
		for j in n:
			for i in n:
				var a:=i+j*row
				indices[k]=a;indices[k+1]=a+1;indices[k+2]=a+row
				indices[k+3]=a+1;indices[k+4]=a+row+1;indices[k+5]=a+row
				k+=6
		for edge in 4:
			var first:=row*row+edge*row
			for i in n:
				var a:int=i if edge==0 else (i+n*row if edge==1 else (i*row if edge==2 else i*row+n))
				var b:int=a+(1 if edge<2 else row)
				var c:=first+i;var d:=first+i+1
				indices.append_array(PackedInt32Array([a,b,d,a,d,c,a,d,b,a,c,d]))
		index_cache[n]=indices
	indices=index_cache[n]
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

## The water surface over one chunk: only the cells that touch a lake, each vertex carrying
## how deep the bed is there so the shader can draw shallows, depth and a shoreline.
static func _water(heights:PackedFloat32Array,cell:float,n:int)->ArrayMesh:
	var side:=n+3;var half:=CHUNK*.5
	var vertices:=PackedVector3Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
	for j in n:
		for i in n:
			var s:=(i+1)+(j+1)*side
			var h00:=heights[s];var h10:=heights[s+1];var h01:=heights[s+side];var h11:=heights[s+side+1]
			if minf(minf(h00,h10),minf(h01,h11))>WATER+.25:continue
			var first:=vertices.size();var x:=i*cell-half;var z:=j*cell-half
			vertices.append(Vector3(x,WATER,z));vertices.append(Vector3(x+cell,WATER,z));vertices.append(Vector3(x,WATER,z+cell));vertices.append(Vector3(x+cell,WATER,z+cell))
			for h in [h00,h10,h01,h11]:colors.append(Color(clampf((WATER-h)/WADE*.8+.2,0.0,1.0),0,0))
			indices.append_array(PackedInt32Array([first,first+1,first+2,first+1,first+3,first+2]))
	if vertices.is_empty():return null
	var normals:=PackedVector3Array();normals.resize(vertices.size());normals.fill(Vector3.UP)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

static func _lake(ci:int,key:String,mesh:ArrayMesh)->MeshInstance3D:
	var record:Dictionary=nodes[ci]
	var old:MeshInstance3D=record.get(key)
	if mesh==null:
		if is_instance_valid(old):old.queue_free()
		record.erase(key);return null
	var node:=_instance(ci,key,mesh,false)
	node.material_override=water_material
	return node

static func _instance(ci:int,key:String,mesh:ArrayMesh,shadows:bool)->MeshInstance3D:
	var record:Dictionary=nodes[ci]
	var node:MeshInstance3D=record.get(key)
	if not is_instance_valid(node):
		node=MeshInstance3D.new();node.name="%s%d"%[key.capitalize(),ci]
		node.position=Vector3(((ci%GRID)+.5)*CHUNK-HALF,0,((ci/GRID)+.5)*CHUNK-HALF)
		node.material_override=material
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node);record[key]=node
	node.mesh=mesh
	return node

static func _make_coarse(ci:int)->void:
	var sampled:=_sample(ci,COARSE,CN)
	_instance(ci,"far",_mesh(sampled[0],sampled[1],COARSE,CN,16.0),false)
	var lake:=_lake(ci,"lake_far",_water(sampled[0],COARSE,CN))
	if lake and not fine[ci].is_empty():lake.visibility_range_begin=FINE_VIEW

static func _make_fine(ci:int)->void:
	var sampled:=_sample(ci,FINE,FN)
	var heights:PackedFloat32Array=sampled[0]
	var side:=FN+3;var row:=FN+1
	var core:=PackedFloat32Array();core.resize(row*row)
	for j in row:
		for i in row:core[i+j*row]=heights[(i+1)+(j+1)*side]
	fine[ci]=core
	# A heightfield is far cheaper for a hundred raiders to walk on than a triangle soup,
	# and takes the height lattice as it is.
	var record:Dictionary=nodes[ci]
	var body:StaticBody3D=record.get("body")
	if not is_instance_valid(body):
		body=StaticBody3D.new();body.name="Ground%d"%ci;body.collision_layer=1;body.collision_mask=0;body.set_meta("terrain",true)
		body.position=Vector3(((ci%GRID)+.5)*CHUNK-HALF,0,((ci/GRID)+.5)*CHUNK-HALF)
		var holder:=CollisionShape3D.new();holder.scale=Vector3(FINE,1,FINE)
		var field:=HeightMapShape3D.new();field.map_width=row;field.map_depth=row;holder.shape=field;body.add_child(holder)
		root.add_child(body);record["body"]=body
		for walker in walkers:
			if is_instance_valid(walker):walker.add_collision_exception_with(body)
	((body.get_child(0) as CollisionShape3D).shape as HeightMapShape3D).map_data=core
	if headless:return
	var near:=_instance(ci,"near",_mesh(heights,sampled[1],FINE,FN,2.5),true)
	near.visibility_range_end=FINE_VIEW
	var far:MeshInstance3D=record.get("far")
	if is_instance_valid(far):far.visibility_range_begin=FINE_VIEW
	var lake:=_lake(ci,"lake_near",_water(heights,FINE,FN))
	if lake:lake.visibility_range_end=FINE_VIEW
	var far_lake:MeshInstance3D=record.get("lake_far")
	if is_instance_valid(far_lake):far_lake.visibility_range_begin=FINE_VIEW

## Raiders and beasts follow the height field directly instead of colliding with it:
## sweeping a hundred capsules over terrain every frame costs ten times what a lookup does.
## They still collide with walls, props, castle floors and each other's obstacles as before.
static func exempt(body:CharacterBody3D)->void:
	walkers=walkers.filter(func(w):return is_instance_valid(w))
	walkers.append(body)
	for record in nodes:
		var ground_body:StaticBody3D=record.get("body")
		if is_instance_valid(ground_body):body.add_collision_exception_with(ground_body)

## move_and_slide for a body registered with exempt(): then stand it on the land.
static func walk(body:CharacterBody3D)->void:
	body.move_and_slide()
	var grounded_now:=false
	if not body.is_on_floor():
		var floor_y:=height(body.position.x,body.position.z)
		# Snap down gentle descents; a real drop (a wall top, a ledge) is fallen, not teleported.
		if body.position.y<=floor_y+(.4 if body.velocity.y<=0.0 else 0.0):
			body.position.y=floor_y;grounded_now=true
			if body.velocity.y<0.0:body.velocity.y=0.0
	body.set_meta("on_ground",grounded_now)

static func standing(body:CharacterBody3D)->bool:
	return body.is_on_floor() or body.get_meta("on_ground",false)

## First thing a ray meets that is not walkable ground: walls, props and cliffs block a
## route, rolling hills between two points do not.
static func sight(space:PhysicsDirectSpaceState3D,from:Vector3,to:Vector3,mask:=1)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(from,to,mask)
	var skipped:Array[RID]=[]
	for attempt in 6:
		var hit:=space.intersect_ray(query)
		if hit.is_empty() or hit.normal.y<.7 or not (hit.collider as Node).has_meta("terrain"):return hit
		skipped.append(hit.rid);query.exclude=skipped
	return {}

static func set_ward(radius:float)->void:
	ward=radius
	if material:material.set_shader_parameter("ward_radius",radius)

static func release(world:FortWorld)->void:
	if built_world!=world.get_instance_id():return
	built_world=0;seed_value=-1;root=null;grounded.clear();walkers.clear();fine.clear();nodes.clear();chunk_pads.clear();pads.clear();levelled.clear()
	levelled_key="";resource_count=-1;fine_radius=0.0

# ---------------------------------------------------------------- keeping things on the ground
static func _chain(node:Node)->Transform3D:
	var pose:=Transform3D.IDENTITY
	while node is Node3D:
		pose=(node as Node3D).transform*pose;node=node.get_parent()
	return pose

## Stand a node on the ground, `offset` above it, and keep it there when the land changes.
## `sink` lets wide props settle into slopes instead of floating on the downhill side.
## `anchor` names the map position to measure at when the node's own origin is elsewhere.
static func ground(node:Node3D,offset:=0.0,sink:=0.0,anchor:=Vector2.INF)->void:
	node.set_meta("grounded",true)
	var entry:=[node,0,offset,sink,anchor]
	grounded.append(entry);_settle(entry)

## The same for a batch of instanced scenery. Pass `seated` (the height every instance was
## authored above the ground) when the caller has already stood them on the terrain.
static func ground_batch(batch:MultiMeshInstance3D,reach:=INF,seated:=NAN)->void:
	if not is_nan(seated):
		grounded.append([batch,1,seated,reach]);return
	var base:=PackedFloat32Array();var count:=batch.multimesh.instance_count;base.resize(count)
	for i in count:base[i]=batch.multimesh.get_instance_transform(i).origin.y
	var entry:=[batch,1,base,reach]
	grounded.append(entry);_settle(entry)

## A batch whose instances already stand on the terrain: only remember how far above it.
static func ground_seated(batch:MultiMeshInstance3D,reach:=INF)->void:
	var pose:=_chain(batch)
	var base:=PackedFloat32Array();var count:=batch.multimesh.instance_count;base.resize(count)
	for i in count:
		var at:Vector3=pose*batch.multimesh.get_instance_transform(i).origin
		base[i]=at.y-height(at.x,at.z)
	grounded.append([batch,1,base,reach])

## And for a mesh of loose grass blades: `group` vertices per blade, authored on flat ground.
static func ground_blades(node:MeshInstance3D,vertices:PackedVector3Array,colors:PackedColorArray,group:=3)->void:
	var entry:=[node,2,vertices,colors,group]
	grounded.append(entry);_settle(entry)

static func _settle(entry:Array,area:=Rect2())->void:
	var node:Node3D=entry[0]
	var base:=_chain(node.get_parent())
	var filtered:=area.has_area()
	match int(entry[1]):
		0:
			var at:Vector3=base*node.position
			var anchor:Vector2=entry[4]
			if anchor.is_finite():at=Vector3(anchor.x,0,anchor.y)
			if filtered and not area.has_point(Vector2(at.x,at.z)):return
			var lift:=height(at.x,at.z)+float(entry[2])
			if float(entry[3])>0.0:lift-=minf(.45,slope(at.x,at.z)*float(entry[3]))
			node.position.y=(lift-base.origin.y)/maxf(.01,base.basis.y.y)
		1:
			var batch:MultiMeshInstance3D=node;base=base*batch.transform
			if filtered and is_finite(float(entry[3])) and not area.grow(float(entry[3])).has_point(Vector2(base.origin.x,base.origin.z)):return
			var multi:=batch.multimesh
			var uniform:bool=entry[2] is float
			var heights:PackedFloat32Array=PackedFloat32Array() if uniform else entry[2]
			for i in (multi.instance_count if uniform else mini(heights.size(),multi.instance_count)):
				var pose:=multi.get_instance_transform(i)
				var at:Vector3=base*pose.origin
				var land:=height(at.x,at.z)
				# Ferns and flowers do not grow on a lake bed.
				pose.origin.y=(float(entry[2]) if uniform else heights[i])+land-base.origin.y-(6.0 if land<WATER else 0.0)
				multi.set_instance_transform(i,pose)
		2:
			var holder:MeshInstance3D=node;base=base*holder.transform
			var vertices:PackedVector3Array=(entry[2] as PackedVector3Array).duplicate();var group:int=entry[4]
			if vertices.is_empty():return
			if filtered:
				# Blade meshes cover whole rings; skip them unless the change is inside the ring.
				var near:=INF;var far:=0.0
				for i in range(0,vertices.size(),maxi(group,vertices.size()/64)):
					var d:=Vector2(vertices[i].x,vertices[i].z).length();near=minf(near,d);far=maxf(far,d)
				var centre:=area.get_center().length();var reach:=area.size.length()*.5
				if centre+reach<near-2.0 or centre-reach>far+2.0:return
			for i in range(0,vertices.size(),group):
				var at:Vector3=base*vertices[i]
				var land:=height(at.x,at.z)
				var lift:=land-base.origin.y-(6.0 if land<WATER+.05 else 0.0)
				for j in group:vertices[i+j].y+=lift
			var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=entry[3]
			var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);holder.mesh=mesh

## Re-seat everything registered, or only what stands inside `area`.
static func resettle(area:=Rect2())->void:
	var live:Array=[]
	for entry in grounded:
		if not is_instance_valid(entry[0]):continue
		live.append(entry);_settle(entry,area)
	grounded=live
