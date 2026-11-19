shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform sampler2D depth : hint_depth_texture, filter_nearest;
uniform bool edges = true;
uniform vec4 line_color : source_color = vec4(0.12, 0.09, 0.08, 1.0);
uniform float edge_threshold = 0.04;
uniform bool retro = false;
uniform vec2 retro_res = vec2(426.0, 240.0);
uniform float levels = 12.0;
uniform float dither = 1.0;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

float lin(vec2 uv, mat4 inv_proj) {
	float d = texture(depth, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
	if (OUTPUT_IS_SRGB) {
		ndc.z = d * 2.0 - 1.0;
	}
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return -v.z / v.w;
}

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / VIEWPORT_SIZE;
	if (retro) {
		uv = (floor(uv * retro_res) + 0.5) / retro_res;
		px = 1.0 / retro_res;
	}
	vec3 col = texture(screen, uv).rgb;
	if (edges) {
		float c = lin(uv, INV_PROJECTION_MATRIX);
		float m = 0.0;
		for (int i = 0; i < 4; i++) {
			vec2 o = vec2(i == 0 ? 1.0 : (i == 1 ? -1.0 : 0.0), i == 2 ? 1.0 : (i == 3 ? -1.0 : 0.0)) * px;
			float s = lin(uv + o, INV_PROJECTION_MATRIX);
			m = max(m, (s - c) / max(c, 0.001));
		}
		float e = smoothstep(edge_threshold, edge_threshold * 2.0, m);
		e *= 1.0 - smoothstep(25.0, 60.0, c);
		col = mix(col, line_color.rgb, e);
	}
	if (retro) {
		ivec2 p = ivec2(floor(SCREEN_UV * retro_res)) % 4;
		float b = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0 - 0.5;
		col = floor(col * levels + 0.5 + b * dither) / levels;
	}
	ALBEDO = col;
}
