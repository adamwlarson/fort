shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform bool flame = false;

void vertex() {
	// Face the camera, preserving per-particle size. No external textures needed.
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	billboard[0].xyz *= length(MODEL_MATRIX[0].xyz);
	billboard[1].xyz *= length(MODEL_MATRIX[1].xyz);
	billboard[2].xyz *= length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float mask;
	if (flame) {
		float height = 1.0 - UV.y;
		float sway = sin(TIME * 5.0 + height * 5.0 + MODEL_MATRIX[3].x * 4.0) * 0.16 * height;
		float width = mix(0.78, 0.04, height);
		mask = (1.0 - smoothstep(width * 0.6, width, abs(p.x - sway))) * smoothstep(0.0, 0.18, UV.y) * smoothstep(0.0, 0.16, height);
	} else {
		mask = pow(max(0.0, 1.0 - dot(p,p)), 2.0);
	}
	ALBEDO = COLOR.rgb;
	ALPHA = mask * COLOR.a;
}
