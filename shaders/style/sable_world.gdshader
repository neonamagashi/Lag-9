shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 ink : source_color = vec3(0.30, 0.20, 0.18);
uniform vec3 shadow_tint : source_color = vec3(0.60, 0.62, 0.82);
uniform float shadow_strength = 0.5;
uniform float band = 0.05;
uniform float detail_fade = 70.0;
uniform float ripple_density = 0.42;
uniform float strata_density = 1.25;
uniform float line_strength = 0.55;
uniform float sway = 0.0;

varying vec3 wpos;
varying vec3 wnrm;

float lines(float v, float width) {
	float f = abs(fract(v) - 0.5) * 2.0;
	float w = fwidth(v) * 1.5 + width;
	return smoothstep(1.0 - w * 2.0, 1.0 - w * 0.5, f);
}

void vertex() {
	if (sway > 0.0) {
		float k = clamp(VERTEX.x / 1.2, 0.0, 1.0);
		VERTEX.z += sin(TIME * 2.3 + VERTEX.y * 1.4 + VERTEX.x * 2.0) * sway * k;
		VERTEX.x += sin(TIME * 1.7 + VERTEX.y) * sway * 0.3 * k;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	float mat = COLOR.a;
	float dist = length(wpos - CAMERA_POSITION_WORLD);
	float fade = 1.0 - smoothstep(detail_fade * 0.5, detail_fade, dist);
	float n1 = texture(noise_tex, wpos.xz * 0.018).r;
	float n2 = texture(noise_tex, wpos.xz * 0.11 + vec2(0.37, 0.71)).r;
	float n3 = texture(noise_tex, vec2(wpos.x + wpos.z, wpos.y) * 0.09 + vec2(0.11, 0.53)).r;
	float ink_amt = 0.0;
	if (mat > 0.9) {
		float r = lines(wpos.z * ripple_density + wpos.x * 0.06 + n1 * 5.0, 0.03);
		r *= smoothstep(0.42, 0.55, n2);
		ink_amt = max(ink_amt, r * 0.6);
		vec2 cell = floor(wpos.xz * 1.6);
		float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		vec2 fp = fract(wpos.xz * 1.6) - 0.5;
		ink_amt = max(ink_amt, step(0.93, h) * (1.0 - smoothstep(0.05, 0.09, length(fp))) * 0.7);
	} else if (mat > 0.6) {
		vec2 cell = floor(wpos.xz * 2.2);
		float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		vec2 fp = fract(wpos.xz * 2.2) - 0.5;
		ink_amt = step(0.86, h) * (1.0 - smoothstep(0.06, 0.1, length(fp))) * 0.6;
		float crack = lines(wpos.x * 0.35 + wpos.z * 0.22 + n1 * 6.0, 0.02) * smoothstep(0.55, 0.62, n2);
		ink_amt = max(ink_amt, crack * 0.6);
	} else if (mat > 0.4) {
		float steep = 1.0 - smoothstep(0.55, 0.8, abs(wnrm.y));
		float s = lines(wpos.y * strata_density + n3 * 1.6 + n1 * 2.0, 0.025) * smoothstep(0.3, 0.45, n2);
		float crack = lines(wpos.x * 0.5 - wpos.z * 0.5 + n3 * 4.0, 0.015) * smoothstep(0.6, 0.66, n1) * smoothstep(0.3, 0.7, fract(wpos.y * 0.35 + n2));
		ink_amt = max(s, crack) * steep * 0.75;
	} else if (mat > 0.1) {
		float steep = 1.0 - smoothstep(0.55, 0.8, abs(wnrm.y));
		ink_amt = lines(wpos.y * 0.9 + n3 * 1.5, 0.02) * steep * 0.5;
	}
	ALBEDO = mix(c, c * ink * 1.4, ink_amt * line_strength * fade);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, band, ndl) * smoothstep(0.35, 0.55, ATTENUATION);
	vec3 shade = mix(shadow_tint, vec3(1.0), 1.0 - shadow_strength);
	float hatch = step(0.7, fract((FRAGCOORD.x + FRAGCOORD.y) / 5.0)) * (1.0 - lit);
	DIFFUSE_LIGHT += mix(shade * (1.0 - hatch * 0.12), vec3(1.0), lit) * LIGHT_COLOR / PI;
}
