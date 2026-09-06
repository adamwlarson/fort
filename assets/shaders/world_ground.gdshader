shader_type spatial;
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float segment(vec2 p,vec2 a,vec2 b){vec2 d=b-a;return length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.0,1.0));}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    vec2 p=world_pos.xz;
    float broad=noise(p*0.075),detail=noise(p*0.65),grain=hash(floor(p*8.0));
    vec3 meadow=mix(vec3(0.18,0.28,0.17),vec3(0.32,0.38,0.22),broad);
    float grove=1.0-smoothstep(10.0,24.0,length(p-vec2(-31,28)));
    float quarry=1.0-smoothstep(8.0,19.0,length(p-vec2(36,-28)));
    float ruins=1.0-smoothstep(8.0,20.0,length(p-vec2(-37,-34)));
    meadow=mix(meadow,vec3(0.16,0.24,0.18),grove*0.75);
    meadow=mix(meadow,vec3(0.37,0.39,0.36),quarry*0.85);
    meadow=mix(meadow,vec3(0.20,0.29,0.28),ruins*0.7);
    float frontier=smoothstep(72.0,88.0,length(p)+(broad-0.5)*14.0);
    float east=smoothstep(-8.0,8.0,p.x+(broad-0.5)*18.0);
    vec3 elder=mix(vec3(0.13,0.23,0.17),vec3(0.25,0.31,0.18),broad);
    vec3 rust=mix(vec3(0.29,0.20,0.15),vec3(0.43,0.33,0.22),broad);
    meadow=mix(meadow,mix(elder,rust,east),frontier);
    float outer=smoothstep(152.0,175.0,length(p)+(broad-0.5)*18.0);
    vec3 storm=mix(vec3(0.19,0.20,0.31),vec3(0.29,0.29,0.39),broad);
    vec3 frost=mix(vec3(0.30,0.36,0.39),vec3(0.47,0.52,0.52),broad);
    meadow=mix(meadow,mix(storm,frost,smoothstep(-12.0,12.0,p.y)),outer);
    float d=min(segment(p,vec2(0),vec2(0,12)),segment(p,vec2(0,12),vec2(-31,28)));
    d=min(d,min(segment(p,vec2(0),vec2(12,0)),segment(p,vec2(12,0),vec2(36,-28))));
    d=min(d,min(segment(p,vec2(0),vec2(-12,0)),segment(p,vec2(-12,0),vec2(-37,-34))));
    // The fourth gate also has a short clear approach for enemies and players.
    d=min(d,segment(p,vec2(0),vec2(0,-14)));
    // Narrow weathered expedition tracks connect the expanded regions.
    d=min(d,min(segment(p,vec2(12,0),vec2(225,0)),segment(p,vec2(-12,0),vec2(-225,0))));
    d=min(d,min(segment(p,vec2(0,14),vec2(0,225)),segment(p,vec2(0,-14),vec2(0,-225))));
    float path=1.0-smoothstep(1.0,2.7,d+(detail-0.5)*0.8);
    path=max(path,1.0-smoothstep(8.5,10.8,length(p)));
    vec3 soil=mix(vec3(0.34,0.28,0.21),vec3(0.47,0.39,0.27),detail);
    ALBEDO=mix(meadow,soil,path)*(0.9+detail*0.14+grain*0.07);
    ROUGHNESS=1.0;
}
