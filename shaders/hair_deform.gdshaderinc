uniform vec3 sway = vec3(0.0);
uniform float lift = 0.0;
uniform float root_y = 1.42;
uniform float tip_y = 0.31;
uniform float amount = 0.3;
uniform float spread = 0.18;

vec3 hair_deform(vec3 v, float t) {
	float w = clamp((root_y - v.y) / (root_y - tip_y), 0.0, 1.0);
	w = w * w;
	float energy = 0.3 + length(sway) + lift;
	vec3 flutter = vec3(sin(t * 2.7 + v.y * 6.0 + v.x * 4.0), sin(t * 1.9 + v.z * 5.0) * 0.4, cos(t * 2.1 + v.y * 5.0)) * 0.07 * energy;
	vec2 radial = v.xz - vec2(0.0, -0.02);
	vec2 out_dir = length(radial) > 0.001 ? normalize(radial) : vec2(0.0, -1.0);
	vec3 float_up = (vec3(out_dir.x, 0.0, out_dir.y) * spread + vec3(0.0, 1.0, 0.0) * spread * 0.9 + vec3(0.0, 0.0, -0.6) * spread) * lift;
	return v + (sway + flutter) * w * amount + float_up * w;
}
