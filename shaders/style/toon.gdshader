shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_tex = false;
uniform vec3 shadow_tint : source_color = vec3(0.55, 0.58, 0.78);
uniform float shadow_strength = 0.55;
uniform float band = 0.04;
uniform float hatch = 0.35;
uniform float hatch_spacing = 5.0;
uniform float pastel = 0.25;
uniform vec3 pastel_color : source_color = vec3(0.98, 0.92, 0.82);
uniform float snap = 0.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (snap > 0.0) {
		clip.xy = round(clip.xy / clip.w * snap) / snap * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	vec4 c = albedo;
	if (use_tex) {
		c *= texture(albedo_tex, UV);
	}
	ALBEDO = mix(c.rgb, pastel_color, pastel);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, band, ndl) * smoothstep(0.35, 0.55, ATTENUATION);
	vec3 shade = mix(shadow_tint, vec3(1.0), 1.0 - shadow_strength);
	float h = 1.0;
	if (hatch > 0.0) {
		float line = step(0.72, fract((FRAGCOORD.x + FRAGCOORD.y) / hatch_spacing));
		h = 1.0 - hatch * line * (1.0 - lit) * 0.5;
	}
	DIFFUSE_LIGHT += mix(shade * h, vec3(1.0), lit) * LIGHT_COLOR / PI;
}
