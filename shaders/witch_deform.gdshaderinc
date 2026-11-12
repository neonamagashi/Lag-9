uniform vec3 sway = vec3(0.0);
uniform float hat_base_y = 1.33;
uniform float head_radius = 0.17;
uniform float brim_radius = 0.41;
uniform float tip_start_y = 1.62;
uniform float top_y = 1.83;
uniform float hat_amount = 0.14;
uniform float hair_top_y = 1.3;
uniform float hair_end_y = 0.9;
uniform float hair_back_z = -0.12;
uniform float hair_amount = 0.07;

vec3 witch_deform(vec3 v, float t) {
	float above = smoothstep(hat_base_y - 0.02, hat_base_y + 0.04, v.y);
	float brim = smoothstep(head_radius, brim_radius, length(v.xz));
	float tip = smoothstep(tip_start_y, top_y, v.y);
	float hat_w = above * max(brim * brim, tip);
	float hair_len = clamp((hair_top_y - v.y) / (hair_top_y - hair_end_y), 0.0, 1.0);
	float hair_mask = smoothstep(hair_back_z, hair_back_z - 0.05, v.z) * step(hair_end_y - 0.05, v.y) * (1.0 - above);
	float hair_w = hair_len * hair_mask;
	float energy = 0.3 + length(sway);
	vec3 flutter = vec3(sin(t * 5.0 + v.x * 9.0), sin(t * 6.3 + v.z * 7.0), cos(t * 4.1 + v.x * 6.0)) * 0.1 * energy;
	return v + (sway + flutter) * hat_w * hat_amount + (sway + flutter * 0.5) * hair_w * hair_amount;
}
