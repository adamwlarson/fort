shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    float broad=noise(world_pos*.7),detail=noise(world_pos*4.0);
    float strata=smoothstep(.06,.15,abs(sin(world_pos.y*3.1+noise(world_pos*.25)*1.8)));
    vec3 stone=mix(vec3(.20,.23,.24),vec3(.37,.36,.31),broad);
    stone*=.76+.19*strata+.12*detail;
    float damp=(1.0-smoothstep(.1,1.9,world_pos.y))*noise(world_pos*1.2);
    ALBEDO=mix(stone,vec3(.12,.19,.15),damp*.5);ROUGHNESS=.94;
}
