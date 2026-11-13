shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting, cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float glow = 1.5;
uniform float pulse = 1.0;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	float purple = smoothstep(0.06, 0.2, min(c.b - c.g, c.r - c.g * 0.9));
	ALBEDO = c;
	EMISSION = c * purple * glow * pulse;
	ROUGHNESS = 1.0;
}
