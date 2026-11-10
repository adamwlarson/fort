shader_type sky;
// Fort 26 sky: painted gradient, drifting cloud banks, sun/moon discs and night stars.
uniform vec3 top_color : source_color = vec3(0.26, 0.47, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.78, 0.84, 0.86);
uniform vec3 ground_color : source_color = vec3(0.30, 0.38, 0.36);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.98, 0.94);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.68, 0.78);
uniform float night = 0.0;
uniform float cloud_cover = 0.5;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 4; i++) { v += noise(p) * a; p = p * 2.03 + vec2(17.0, 9.0); a *= 0.5; }
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(h, 0.42));
	if (d.y < 0.0) col = mix(horizon_color, ground_color, clamp(-d.y * 5.0, 0.0, 1.0));
	float sun_amount = max(dot(d, LIGHT0_DIRECTION), 0.0);
	// warm scatter around the sun by day, cool halo around the moon at night
	col += LIGHT0_COLOR * pow(sun_amount, 6.0) * mix(0.22, 0.10, night);
	if (d.y > 0.0) {
		// stars: stable cells, twinkle, hidden by day
		vec2 sp = d.xz / (d.y + 0.35) * 46.0;
		vec2 cell = floor(sp);
		float star = step(0.985, hash(cell)) * (1.0 - smoothstep(0.0, 0.34, length(fract(sp) - 0.5)));
		star *= 0.6 + 0.4 * sin(TIME * 2.0 + hash(cell) * 40.0);
		col += vec3(0.9, 0.95, 1.0) * star * night * smoothstep(0.02, 0.3, d.y);
		// two cloud decks projected on a dome
		vec2 uv = d.xz / (d.y + 0.22);
		float n = fbm(uv * 1.15 + vec2(TIME * 0.006, TIME * 0.002));
		float n2 = fbm(uv * 2.6 - vec2(TIME * 0.004, 0.0) + 31.0);
		float edge = 0.78 - cloud_cover * 0.42;
		float c = smoothstep(edge, edge + 0.2, n + n2 * 0.25);
		float lit = smoothstep(edge + 0.05, edge + 0.42, n + n2 * 0.3);
		vec3 cl = mix(cloud_shade, cloud_color, lit);
		cl = mix(cl, cl * vec3(0.28, 0.33, 0.46), night);
		cl += LIGHT0_COLOR * pow(sun_amount, 10.0) * 0.25 * (1.0 - night);
		col = mix(col, cl, c * smoothstep(0.015, 0.2, d.y) * 0.92);
	}
	// sun / moon disc
	float disc = smoothstep(0.9990, 0.9996, sun_amount);
	col += LIGHT0_COLOR * disc * mix(2.4, 1.3, night);
	COLOR = col;
}
