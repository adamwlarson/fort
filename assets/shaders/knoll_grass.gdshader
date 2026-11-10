shader_type spatial;
render_mode cull_disabled;
// Grass on knolls: tips are lighter (painted in COLOR) and sway; bases stay planted.
void vertex() {
	float tip = step(0.5, fract(float(VERTEX_ID) / 3.0) * 3.0) * step(fract(float(VERTEX_ID) / 3.0) * 3.0, 1.5);
	float wind = sin(TIME * 1.7 + VERTEX.x * 0.31 + VERTEX.z * 0.24);
	VERTEX.x += wind * tip * 0.07;
	VERTEX.z += cos(TIME * 1.2 + VERTEX.x * 0.21) * tip * 0.04;
	NORMAL = vec3(0.0, 1.0, 0.0);
}
void fragment() { ALBEDO = COLOR.rgb; ROUGHNESS = 1.0; }
