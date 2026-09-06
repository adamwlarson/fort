shader_type spatial;
render_mode cull_disabled;
void vertex(){
    float wind=sin(TIME*1.7+VERTEX.x*0.31+VERTEX.z*0.24);
    VERTEX.x+=wind*VERTEX.y*0.17;
    VERTEX.z+=cos(TIME*1.2+VERTEX.x*0.21)*VERTEX.y*0.08;
    NORMAL=vec3(0.0,1.0,0.0);
}
void fragment(){ALBEDO=COLOR.rgb;ROUGHNESS=1.0;}
