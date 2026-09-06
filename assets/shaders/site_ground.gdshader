shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 soil_color : source_color = vec4(.4,.35,.25,1.0);
uniform float radius = 12.0;
varying vec2 ground_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){ground_pos=VERTEX.xz;}
void fragment(){
    float grain=noise(ground_pos*1.2);
    ALBEDO=soil_color.rgb*(.85+grain*.25);
    ALPHA=(1.0-smoothstep(radius*.40,radius,length(ground_pos)+(grain-.5)*2.0))*.32;
}
