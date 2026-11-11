shader_type spatial;
// Fort 30 terrain: meadow, biome rings and trails painted by position, then rock on
// steep faces, scree below it, snow on the high peaks, worn earth on levelled ground
// and the glowing ward line that marks the frontier.
uniform float ward_radius = 73.0;
uniform float water_level = -4.0;
uniform vec3 ring_color[5] : source_color;
varying vec3 world_pos;
varying vec3 world_normal;
varying float cleared;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.55+noise(p*2.13+7.1)*.3+noise(p*4.7-3.3)*.15;}
float segment(vec2 p,vec2 a,vec2 b){vec2 d=b-a;return length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.0,1.0));}
void vertex(){
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
    cleared=COLOR.r;
}
void fragment(){
    vec2 p=world_pos.xz;
    float r=length(p);
    float broad=noise(p*0.075),detail=noise(p*0.65),grain=hash(floor(p*8.0));
    vec3 n=normalize(world_normal);
    // Fine grain fades with distance so far hillsides stay clean instead of shimmering.
    float near=1.0-smoothstep(90.0,340.0,length(VERTEX));
    float steep=1.0-n.y;
    vec3 meadow=mix(vec3(0.18,0.28,0.17),vec3(0.32,0.38,0.22),broad);
    float grove=1.0-smoothstep(10.0,24.0,length(p-vec2(-31,28)));
    float quarry=1.0-smoothstep(8.0,19.0,length(p-vec2(36,-28)));
    float ruins=1.0-smoothstep(8.0,20.0,length(p-vec2(-37,-34)));
    meadow=mix(meadow,vec3(0.16,0.24,0.18),grove*0.75);
    meadow=mix(meadow,vec3(0.37,0.39,0.36),quarry*0.85);
    meadow=mix(meadow,vec3(0.20,0.29,0.28),ruins*0.7);
    float frontier=smoothstep(72.0,88.0,r+(broad-0.5)*14.0);
    float east=smoothstep(-8.0,8.0,p.x+(broad-0.5)*18.0);
    vec3 elder=mix(vec3(0.13,0.23,0.17),vec3(0.25,0.31,0.18),broad);
    vec3 rust=mix(vec3(0.29,0.20,0.15),vec3(0.43,0.33,0.22),broad);
    meadow=mix(meadow,mix(elder,rust,east),frontier);
    float outer=smoothstep(152.0,175.0,r+(broad-0.5)*18.0);
    vec3 storm=mix(vec3(0.19,0.20,0.31),vec3(0.29,0.29,0.39),broad);
    vec3 frost=mix(vec3(0.30,0.36,0.39),vec3(0.47,0.52,0.52),broad);
    meadow=mix(meadow,mix(storm,frost,smoothstep(-12.0,12.0,p.y)),outer);
    // Expedition biomes beyond the third ring take their colour from this run's order.
    float band=(r+(broad-0.5)*22.0-243.0)/80.0;
    if(band>-0.2){
        int index=clamp(int(floor(band)),0,4);
        vec3 here=ring_color[index]*(0.62+broad*0.45);
        vec3 next=ring_color[min(index+1,4)]*(0.62+broad*0.45);
        vec3 biome=mix(here,next,smoothstep(0.86,1.0,fract(max(band,0.0)))*step(band,4.0));
        meadow=mix(meadow,biome,smoothstep(-0.2,0.08,band)*(1.0-smoothstep(650.0,720.0,r)));
    }
    float d=min(segment(p,vec2(0),vec2(0,12)),segment(p,vec2(0,12),vec2(-31,28)));
    d=min(d,min(segment(p,vec2(0),vec2(12,0)),segment(p,vec2(12,0),vec2(36,-28))));
    d=min(d,min(segment(p,vec2(0),vec2(-12,0)),segment(p,vec2(-12,0),vec2(-37,-34))));
    d=min(d,segment(p,vec2(0),vec2(0,-14)));
    // Weathered expedition tracks run out along the four gentle roads.
    float road=min(abs(p.x),abs(p.y));
    d=min(d,max(road,12.0-r)+step(640.0,r)*40.0);
    float path=1.0-smoothstep(1.0,2.7,d+(detail-0.5)*0.8);
    path=max(path,1.0-smoothstep(8.5,10.8,r));
    vec3 soil=mix(vec3(0.34,0.28,0.21),vec3(0.47,0.39,0.27),detail);
    float moss=noise(p*2.8)*noise(p*.29);
    meadow=mix(meadow,meadow*vec3(1.10,1.19,.85),smoothstep(.36,.63,moss)*.38);
    vec2 pebble_cell=floor(p*4.5), pebble_uv=fract(p*4.5)-.5;
    float pebble=(1.0-smoothstep(.10,.19,length(pebble_uv)))*step(.84,hash(pebble_cell));
    soil=mix(soil,vec3(.44,.43,.36),pebble*.5);
    float lush=smoothstep(.42,.7,noise(p*.021+7.3));
    meadow=mix(meadow,meadow*vec3(.82,1.12,.78)+vec3(.0,.03,.0),lush*.55);
    float dry=smoothstep(.55,.8,noise(p*.033-11.0));
    meadow=mix(meadow,meadow*vec3(1.25,1.12,.8),dry*.4);
    vec2 fc=floor(p*3.1), fu=fract(p*3.1)-.5;
    float bloom=(1.0-smoothstep(.05,.16,length(fu+vec2(hash(fc)-.5,hash(fc+3.1)-.5)*.5)))*step(.78,hash(fc+9.7))*smoothstep(.5,.75,noise(p*.09+2.0))*(1.0-path)*(1.0-smoothstep(66.0,74.0,r));
    vec3 petal=mix(vec3(.93,.86,.45),vec3(.78,.62,.9),step(.5,hash(fc+1.3)));
    meadow=mix(meadow,petal,bloom*.8);
    // Relief: hollows stay damp and green, crests dry out, slopes read darker.
    float height=world_pos.y;
    meadow=mix(meadow,meadow*vec3(.78,.96,.8),smoothstep(-.3,-2.6,height)*.7);
    meadow=mix(meadow,meadow*vec3(1.16,1.08,.84),smoothstep(3.0,14.0,height)*.45*(1.0-outer*.5));
    meadow*=mix(1.0,.84,smoothstep(.015,.11,steep));
    // Levelled ground under camps and buildings is trodden earth.
    float worn=smoothstep(.55,1.0,cleared+(detail-.5)*.25)*.5;
    vec3 ground=mix(mix(meadow,soil,path),soil*vec3(.98,.95,.9),worn*(1.0-path));
    // Shores: pale sand above the waterline, dark silt and pebbles on the lake beds.
    float beach=(1.0-smoothstep(water_level+.1,water_level+.85,height+(detail-.5)*.35))*(1.0-smoothstep(640.0,660.0,r));
    vec3 sand=mix(vec3(.50,.45,.33),vec3(.62,.56,.41),noise(p*.8));
    ground=mix(ground,sand,beach*.85);
    float bed=(1.0-smoothstep(water_level-.5,water_level+.02,height))*(1.0-smoothstep(640.0,660.0,r));
    ground=mix(ground,mix(vec3(.19,.24,.20),vec3(.30,.31,.25),pebble+detail*.5),bed);
    // Rock breaks through steep faces in tilted strata, with scree just below.
    float strata=noise(vec2(height*mix(.3,1.7,near)+broad*3.0,dot(p,vec2(.06,.04))))*.6+noise(p*mix(.12,.9,near))*.4;
    vec3 rock=mix(vec3(.30,.29,.28),vec3(.52,.49,.44),strata);
    rock=mix(rock,rock*vec3(1.12,.93,.8),east*frontier*(1.0-outer)*.7);
    rock*=mix(1.0,.86+.28*noise(p*3.3+height),near);
    float rocky=smoothstep(.15,.3,steep+(fbm(p*.35)-.5)*.11);
    float scree=smoothstep(.08,.17,steep+(detail-.5)*.06)*(1.0-rocky);
    ground=mix(ground,mix(ground,rock*vec3(.9,.92,.86),.55),scree);
    ground=mix(ground,rock,rocky);
    // High peaks: bare stone, then snow that clings to the gentler faces.
    // The mountain wall: dark forest on the foothills, bare stone above, snow on the heights.
    float wall=smoothstep(650.0,700.0,r);
    vec3 crag=mix(vec3(.21,.21,.24),vec3(.37,.35,.34),strata);
    ground=mix(ground,mix(ground,crag,rocky),wall);
    float wooded=smoothstep(20.0,46.0,height+(broad-.5)*18.0)*wall;
    vec3 forest=mix(vec3(.08,.16,.11),vec3(.15,.24,.14),noise(p*.045));
    ground=mix(ground,forest,wooded*(1.0-rocky*.55)*.94);
    float bare=smoothstep(105.0,155.0,height+(broad-.5)*40.0)*wall;
    ground=mix(ground,crag,bare);
    float snow=smoothstep(170.0,220.0,height+(fbm(p*.012)-.5)*90.0)*smoothstep(.75,.32,steep)*wall;
    ground=mix(ground,vec3(.90,.93,.97),snow);
    float cloud=noise(p*.011+vec2(TIME*.012,TIME*.004))*.65+noise(p*.03-vec2(TIME*.01,0.0))*.35;
    float shade=mix(1.0,.74,smoothstep(.48,.66,cloud));
    ALBEDO=ground*(0.9+mix(.09,detail*0.14+grain*0.045,near))*shade;
    // Fine relief from the same noise, so flat meadow still catches the light.
    float e=.35;
    float bump=mix(.5,1.6,rocky)*(1.0-snow*.7)*near;
    vec3 fine_normal=normalize(n+vec3(fbm(p*1.3-vec2(e,0.0))-fbm(p*1.3+vec2(e,0.0)),0.0,fbm(p*1.3-vec2(0.0,e))-fbm(p*1.3+vec2(0.0,e)))*bump);
    NORMAL=normalize((VIEW_MATRIX*vec4(fine_normal,0.0)).xyz);
    ROUGHNESS=mix(1.0,.72,snow);
    // The ward: a thin line of light where the frontier ends.
    float line=1.0-smoothstep(.10,.34,abs(r-ward_radius));
    ALBEDO=mix(ALBEDO,vec3(.45,.71,.65),line*.85);
    EMISSION=vec3(.45,.71,.65)*line*.55;
}
