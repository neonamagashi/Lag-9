shader_type canvas_item;

uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float squash_tint = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 rgb = mix(c.rgb, c.rgb * vec3(0.75, 0.7, 1.0), squash_tint);
	COLOR = vec4(mix(rgb, flash_color.rgb, flash), c.a);
}
