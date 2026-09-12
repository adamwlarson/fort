shader_type spatial;
render_mode cull_disabled;
uniform vec3 dwarf_position=vec3(10000.0);
varying float blade_height;
void vertex(){
    vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    blade_height=UV.y;
    float distance_to_camera=distance(world,CAMERA_POSITION_WORLD);
    float fade=1.0-smoothstep(58.0,82.0,distance_to_camera);
    VERTEX.y*=fade;
    float gust=sin(TIME*1.5+world.x*.18+world.z*.24)*.7+sin(TIME*2.9+world.x*.63)*.3;
    VERTEX.x+=gust*UV.y*UV.y*.17*fade;
    VERTEX.z+=sin(TIME*1.1+world.z*.3)*UV.y*UV.y*.09*fade;
    vec2 away=world.xz-dwarf_position.xz;
    float bend=(1.0-smoothstep(.2,1.4,length(away)))*UV.y*UV.y;
    vec3 local_away=transpose(mat3(MODEL_MATRIX))*vec3(away.x+.001,0.0,away.y+.001);
    VERTEX.xz+=normalize(local_away.xz)*bend*.45;
    VERTEX.y*=1.0-bend*.6;
    NORMAL=vec3(0.0,1.0,0.0);
}
void fragment(){
    ALBEDO=COLOR.rgb*mix(.60,1.12,clamp(blade_height,0.0,1.0));
    ROUGHNESS=1.0;
    BACKLIGHT=COLOR.rgb*.16;
}
