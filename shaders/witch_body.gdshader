shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting, cull_back;

#include "res://shaders/witch_deform.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);

void vertex() {
	VERTEX = witch_deform(VERTEX, TIME);
}

void fragment() {
	ALBEDO = (texture(albedo_tex, UV) * tint).rgb;
	ROUGHNESS = 1.0;
}
