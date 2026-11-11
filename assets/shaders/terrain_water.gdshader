shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;
// Fort 30 lakes and ponds. COLOR.r carries the depth of the bed under each vertex
// (0.2 at the waterline, 1.0 at wading depth), so shallows, deep water and the foam line
// are drawn without reading the depth buffer.
uniform vec3 shallow_color : source_color = vec3(0.30, 0.62, 0.60);
uniform vec3 deep_color : source_color = vec3(0.07, 0.25, 0.36);
varying vec3 world_pos;
varying float bed;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float swell(vec2 p){return noise(p*.55+vec2(TIME*.21,TIME*.13))*.6+noise(p*1.7-vec2(TIME*.17,TIME*.26))*.4;}
void vertex(){
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    bed=COLOR.r;
}
void fragment(){
    vec2 p=world_pos.xz;
    float near=1.0-smoothstep(60.0,260.0,length(VERTEX));
    float depth=clamp((bed-.2)/.8,0.0,1.0);
    // Small wind ripples; they flatten out with distance so far lakes stay calm and bright.
    float e=.3;
    vec3 n=normalize(vec3((swell(p-vec2(e,0.0))-swell(p+vec2(e,0.0)))*.55*near,1.0,(swell(p-vec2(0.0,e))-swell(p+vec2(0.0,e)))*.55*near));
    NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
    vec3 water=mix(shallow_color,deep_color,smoothstep(0.0,.85,depth));
    // The surface picks up more sky at grazing angles.
    float graze=pow(1.0-clamp(dot(normalize(VIEW),NORMAL),0.0,1.0),3.0);
    water=mix(water,vec3(.62,.76,.86),graze*.55);
    // A moving line of foam where the water meets the shore.
    float lap=sin(TIME*1.3+noise(p*.6)*6.283)*.5+.5;
    float foam=(1.0-smoothstep(.0,.07+lap*.05,abs(bed-.235-lap*.02)))*near*(.55+.45*noise(p*5.0+TIME*.3));
    ALBEDO=mix(water,vec3(.92,.96,.97),foam*.8);
    ALPHA=smoothstep(.175,.24,bed)*mix(.5,.9,smoothstep(0.0,.7,depth)+graze*.3);
    ROUGHNESS=mix(.07,.3,foam);
    SPECULAR=.7;
    METALLIC=0.0;
}
