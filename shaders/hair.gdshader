shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting, cull_disabled;

#include "res://shaders/hair_deform.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;

void vertex() {
	VERTEX = hair_deform(VERTEX, TIME);
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = 1.0;
}
