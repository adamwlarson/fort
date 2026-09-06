shader_type spatial;
render_mode cull_disabled;
uniform vec4 soil_color : source_color = vec4(.35,.42,.28,1.0);
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    vec2 p=world_pos.xz;
    float broad=noise(p*.055),detail=noise(p*.7),grain=hash(floor(p*9.0));
    float lane=1.0-smoothstep(1.0,3.2,min(abs(p.x),abs(p.y))+(detail-.5)*.6);
    vec3 soil=soil_color.rgb*(.65+broad*.45+detail*.12+grain*.06);
    ALBEDO=mix(soil,vec3(.31,.27,.20)*(1.0+detail*.15),lane);
    ROUGHNESS=1.0;
}
