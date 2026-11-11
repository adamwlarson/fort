shader_type sky;
// Fort 32 sky. A painted atmosphere that follows the sun: deep zenith, hazy horizon, a
// warm glow and a pink counter-glow at dusk and dawn; two lit cloud decks and high cirrus;
// a sun with a soft corona; at night a cratered moon with a phase, a small second moon,
// coloured twinkling stars, the Milky Way, shooting stars and an aurora in the north.
uniform vec3 top_color : source_color = vec3(0.18, 0.43, 0.77);
uniform vec3 horizon_color : source_color = vec3(0.71, 0.83, 0.92);
uniform vec3 ground_color : source_color = vec3(0.30, 0.38, 0.36);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.98, 0.94);
uniform vec3 cloud_shade : source_color = vec3(0.56, 0.63, 0.76);
uniform float night = 0.0;
uniform float dusk = 0.0;
uniform float cloud_cover = 0.5;
uniform float aurora_strength = 1.0;
uniform vec3 second_moon = vec3(-0.52, 0.46, -0.72);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 5; i++) { v += noise(p) * a; p = p * 2.03 + vec2(17.0, 9.0); a *= 0.5; }
	return v;
}
float fbm3(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 3; i++) { v += noise(p) * a; p = p * 2.1 + vec2(5.0, 13.0); a *= 0.5; }
	return v;
}

// One layer of stars on the whole sphere: stable cells, varied size, colour and twinkle.
vec3 star_layer(vec3 d, float scale, float density, float time) {
	vec3 p = d * scale;
	vec3 cell = floor(p);
	float seed = hash3(cell);
	if (seed < density) return vec3(0.0);
	vec3 offset = vec3(hash3(cell + 1.7), hash3(cell + 5.3), hash3(cell + 9.1)) - 0.5;
	float spread = length(fract(p) - 0.5 - offset * 0.6);
	float size = mix(0.10, 0.30, pow(hash3(cell + 3.1), 2.0));
	float glow = 1.0 - smoothstep(0.0, size, spread);
	float twinkle = 0.7 + 0.3 * sin(time * (1.5 + seed * 4.0) + seed * 60.0);
	float warmth = hash3(cell + 7.7);
	vec3 tint = mix(vec3(0.72, 0.82, 1.0), vec3(1.0, 0.84, 0.66), smoothstep(0.55, 1.0, warmth));
	return tint * glow * glow * twinkle * mix(0.5, 1.6, hash3(cell + 2.2));
}

// A disc on the sky with a shaded sphere inside it: xy across the disc, z towards the eye.
vec3 disc_normal(vec3 d, vec3 centre, float radius, out float inside) {
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), centre) + vec3(0.0001, 0.0, 0.0));
	vec3 up = cross(centre, right);
	vec2 uv = vec2(dot(d, right), dot(d, up)) / radius;
	float r2 = dot(uv, uv);
	inside = (dot(d, centre) > 0.0 && r2 < 1.0) ? 1.0 : 0.0;
	return vec3(uv, sqrt(max(1.0 - r2, 0.0)));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 sun = normalize(LIGHT0_DIRECTION);
	float up = clamp(d.y, 0.0, 1.0);
	float sun_amount = max(dot(d, sun), 0.0);
	float day = 1.0 - night;

	// --- atmosphere
	vec3 col = mix(horizon_color, top_color, pow(up, 0.45));
	// Deeper overhead, and a bright milky band low down where the air is thick.
	col *= mix(1.0, 0.78, smoothstep(0.35, 1.0, up) * day);
	col = mix(col, horizon_color * 1.06, exp(-up * 9.0) * 0.55);
	// Dusk and dawn: fire around the sun, a rose belt opposite it, violet above.
	vec2 flat_view = normalize(d.xz + vec2(0.0001));
	vec2 flat_sun = normalize(sun.xz + vec2(0.0001));
	float toward = dot(flat_view, flat_sun) * 0.5 + 0.5;
	float low = exp(-up * 4.5);
	col = mix(col, vec3(1.0, 0.50, 0.16), pow(toward, 3.0) * low * dusk * 0.85);
	col = mix(col, vec3(0.96, 0.56, 0.60), pow(1.0 - toward, 2.0) * exp(-abs(up - 0.13) * 9.0) * dusk * 0.5);
	col = mix(col, vec3(0.34, 0.27, 0.56), smoothstep(0.25, 0.9, up) * dusk * 0.35);
	// Night: nearly black overhead with a faint blue rim of light on the horizon.
	col += vec3(0.02, 0.05, 0.10) * exp(-up * 5.0) * night;
	if (d.y < 0.0) col = mix(col, ground_color, clamp(-d.y * 6.0, 0.0, 1.0));

	// --- the heavens, hidden by day and skipped when the sky is baked for reflections
	if (!AT_CUBEMAP_PASS && night > 0.01 && d.y > -0.05) {
		// The whole star field turns slowly about a tilted pole.
		float turn = TIME * 0.0035;
		vec3 axis = normalize(vec3(0.25, 0.9, -0.36));
		vec3 r = d * cos(turn) + cross(axis, d) * sin(turn) + axis * dot(axis, d) * (1.0 - cos(turn));
		float clear = smoothstep(0.0, 0.22, d.y) * night;
		// The Milky Way: a soft band of dust and a thicker scatter of faint stars.
		vec3 pole = normalize(vec3(0.55, 0.35, 0.76));
		float band = exp(-pow(dot(r, pole) * 3.6, 2.0));
		vec2 along = vec2(atan(r.z, r.x) * 3.0, dot(r, pole) * 9.0);
		float dust = fbm3(along * 1.6 + 4.0) * fbm3(along * 4.1 - 2.0);
		col += mix(vec3(0.10, 0.12, 0.22), vec3(0.26, 0.20, 0.30), dust) * band * (0.35 + dust * 2.4) * clear;
		vec3 stars = star_layer(r, 34.0, 0.93, TIME) * 1.3 + star_layer(r, 70.0, 0.93 - band * 0.06, TIME) * 0.8 + star_layer(r, 140.0, 0.94 - band * 0.2, TIME) * 0.5;
		col += stars * clear;

		// A shooting star every few seconds, somewhere overhead.
		float slot = floor(TIME / 7.0);
		float t = fract(TIME / 7.0) / 0.09;
		if (t < 1.0) {
			vec3 from = normalize(vec3(hash(vec2(slot, 1.0)) - 0.5, 0.55 + hash(vec2(slot, 2.0)) * 0.4, hash(vec2(slot, 3.0)) - 0.5));
			vec3 travel = normalize(vec3(hash(vec2(slot, 4.0)) - 0.5, -0.25, hash(vec2(slot, 5.0)) - 0.5)) * 0.42;
			vec3 head = normalize(from + travel * t);
			vec3 tail = normalize(from + travel * max(t - 0.28, 0.0));
			vec3 line = head - tail;
			float s = clamp(dot(d - tail, line) / max(dot(line, line), 0.00001), 0.0, 1.0);
			float streak = 1.0 - smoothstep(0.0, 0.0035, length(d - tail - line * s));
			col += vec3(0.9, 0.96, 1.0) * streak * s * sin(t * 3.1416) * 1.8 * night;
		}

		// Aurora: tall curtains in the northern sky that ripple and breathe.
		float north = smoothstep(-0.15, 0.7, -d.z) * smoothstep(0.04, 0.2, d.y) * (1.0 - smoothstep(0.55, 0.95, d.y));
		if (north > 0.001 && aurora_strength > 0.0) {
			vec2 q = d.xz / (d.y + 0.3);
			float sway = fbm3(vec2(q.x * 0.9 + TIME * 0.015, q.y * 0.35 - TIME * 0.008));
			float curtain = pow(0.5 + 0.5 * sin(q.x * 2.6 + sway * 7.0 + TIME * 0.06), 3.0);
			curtain += 0.6 * pow(0.5 + 0.5 * sin(q.x * 5.3 - sway * 5.0 - TIME * 0.045 + 1.7), 4.0);
			float rays = 0.55 + 0.45 * noise(vec2(q.x * 22.0 + sway * 6.0, TIME * 0.12));
			float breath = 0.65 + 0.35 * sin(TIME * 0.21 + sway * 4.0);
			vec3 hue = mix(vec3(0.16, 0.95, 0.52), vec3(0.20, 0.62, 0.95), smoothstep(0.1, 0.42, d.y));
			hue = mix(hue, vec3(0.62, 0.30, 0.86), smoothstep(0.38, 0.72, d.y));
			col += hue * curtain * rays * breath * north * 0.55 * aurora_strength * night;
		}

		// The small second moon: teal, always in the same quarter of the sky.
		vec3 m2 = normalize(second_moon);
		float in2;
		vec3 n2 = disc_normal(d, m2, 0.022, in2);
		float lit2 = clamp(dot(n2, normalize(vec3(-0.6, 0.35, 0.72))), 0.0, 1.0);
		col = mix(col, vec3(0.50, 0.86, 0.82) * (0.10 + lit2 * 1.25), in2 * night);
		col += vec3(0.30, 0.62, 0.60) * pow(max(dot(d, m2), 0.0), 900.0) * 0.5 * night;
	}

	// --- sun by day, moon by night, both where the light comes from
	float corona = pow(sun_amount, 7.0) * 0.26 + pow(sun_amount, 60.0) * 0.5 + pow(sun_amount, 900.0) * 1.2;
	vec3 sun_tint = mix(LIGHT0_COLOR, vec3(1.0, 0.62, 0.30), dusk * 0.6);
	col += sun_tint * corona * day;
	col += LIGHT0_COLOR * smoothstep(0.99955, 0.99975, sun_amount) * 3.0 * day;
	float in_moon;
	vec3 mn = disc_normal(d, sun, 0.048, in_moon);
	if (in_moon > 0.5 && night > 0.01) {
		// Lit from one side for a gibbous phase; maria and craters from layered noise.
		float lit = smoothstep(-0.12, 0.35, dot(mn, normalize(vec3(0.55, 0.28, 0.78))));
		float seas = smoothstep(0.42, 0.62, fbm3(mn.xy * 2.3 + 8.0));
		float craters = noise(mn.xy * 9.0) * noise(mn.xy * 21.0 + 3.0);
		vec3 face = mix(vec3(0.95, 0.94, 0.86), vec3(0.62, 0.66, 0.72), seas * 0.75);
		face *= 0.86 + craters * 0.5;
		face *= mix(0.06, 1.0, lit) * (0.72 + 0.28 * mn.z);
		col = mix(col, face * 0.82, night);
	}
	col += vec3(0.50, 0.60, 0.86) * (pow(sun_amount, 30.0) * 0.14 + pow(sun_amount, 400.0) * 0.22) * (1.0 - in_moon) * night;

	// --- clouds: two decks on a dome, lit from the sun's side, with cirrus above
	if (d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.22);
		vec2 drift = vec2(TIME * 0.006, TIME * 0.002);
		vec2 warp = vec2(fbm3(uv * 0.7 + drift), fbm3(uv * 0.7 - drift + 9.0)) - 0.5;
		float body = fbm(uv * 1.1 + warp * 0.9 + drift) + fbm3(uv * 3.1 - drift * 0.7 + 31.0) * 0.22;
		float edge = 0.78 - cloud_cover * 0.42;
		float c = smoothstep(edge, edge + 0.22, body);
		if (c > 0.001) {
			// Thinner toward the sun means brighter: a cheap silver lining.
			float toward_sun = fbm(uv * 1.1 + warp * 0.9 + drift + flat_sun * 0.18);
			float lit = clamp(0.55 + (body - toward_sun) * 3.2 + (body - edge) * 0.4, 0.0, 1.0);
			vec3 cl = mix(cloud_color, cloud_shade, lit);
			cl += LIGHT0_COLOR * pow(sun_amount, 6.0) * 0.5 * (1.0 - lit) * day;
			// Sunset paints the sunward clouds gold and the far ones rose and violet.
			vec3 ember = mix(vec3(0.72, 0.42, 0.56), vec3(1.0, 0.60, 0.26), toward);
			cl = mix(cl, ember * mix(1.15, 0.55, lit), dusk * 0.75);
			cl = mix(cl, cl * vec3(0.16, 0.20, 0.32) + vec3(0.03, 0.04, 0.07) * (1.0 - lit), night);
			cl += vec3(0.38, 0.46, 0.66) * pow(sun_amount, 10.0) * 0.5 * (1.0 - lit) * night;
			col = mix(col, cl, c * smoothstep(0.02, 0.2, d.y) * 0.94);
		}
		// Cirrus: long thin streaks far overhead that catch the last light.
		vec2 high = d.xz / (d.y + 0.6);
		float wisps = fbm3(vec2(high.x * 1.4 + TIME * 0.003, high.y * 6.0 + fbm3(high * 2.0) * 1.5));
		float cirrus = smoothstep(0.56, 0.8, wisps) * smoothstep(0.1, 0.4, d.y) * 0.34;
		vec3 thin = mix(vec3(1.0), vec3(1.0, 0.70, 0.52), dusk);
		col = mix(col, thin * mix(1.0, 0.16, night), cirrus * (1.0 - c));
	}
	COLOR = col;
}
