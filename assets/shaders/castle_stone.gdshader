shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
varying vec3 world_normal;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
	vec2 p=world_position.xz/1.65;
	p.x+=mod(floor(p.y),2.0)*0.5;
	vec2 cell=floor(p), local=fract(p);
	float edge=min(min(local.x,1.0-local.x),min(local.y,1.0-local.y));
	float variation=hash21(cell);
	vec3 stone=mix(vec3(.35,.39,.42),vec3(.49,.51,.49),variation);
	float flecks=hash21(floor(world_position.xz*48.0));
	stone*=.96+flecks*.08;
	float grout=smoothstep(.008,.025,edge);
	ALBEDO=abs(world_normal.y)>.5?mix(vec3(.23,.26,.28),stone,grout):vec3(.34,.38,.41);
	ROUGHNESS=.91;
}
