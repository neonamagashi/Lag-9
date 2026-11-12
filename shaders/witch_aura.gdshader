shader_type spatial;
render_mode unshaded, cull_front, blend_add, depth_draw_never;

#include "res://shaders/witch_deform.gdshaderinc"

uniform vec4 aura_color : source_color = vec4(1.0, 0.78, 0.25, 0.45);
uniform float grow = 0.018;

void vertex() {
	VERTEX = witch_deform(VERTEX, TIME) + NORMAL * grow;
}

void fragment() {
	ALBEDO = aura_color.rgb;
	ALPHA = aura_color.a;
}
