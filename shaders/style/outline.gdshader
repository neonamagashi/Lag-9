shader_type spatial;
render_mode unshaded, cull_front, specular_disabled, shadows_disabled;

uniform vec4 line_color : source_color = vec4(0.12, 0.09, 0.08, 1.0);
uniform float width = 1.6;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 off = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	if (length(off) > 0.0001) {
		clip.xy += normalize(off) / VIEWPORT_SIZE * width * 2.0 * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = line_color.rgb;
}
