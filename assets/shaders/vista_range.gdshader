shader_type spatial;
render_mode cull_disabled, shadows_disabled, fog_disabled;
// Distant mountain ranges: vertex-painted strata, snow caps and aerial haze. Tinted by day/night.
uniform vec3 haze : source_color = vec3(0.62, 0.72, 0.8);
uniform float haze_amount = 0.45;
uniform float dim = 1.0;
varying float height;
void vertex() { height = VERTEX.y; }
void fragment() {
	vec3 base = COLOR.rgb;
	float band = sin(height * 0.21 + UV.x * 40.0) * 0.5 + 0.5;
	base *= 0.9 + band * 0.14;
	ALBEDO = mix(base, haze, haze_amount) * dim;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
