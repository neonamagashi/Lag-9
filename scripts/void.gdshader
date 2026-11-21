shader_type canvas_item;
// Her magic: bright cores become black, softer parts glow in the Crush purple.
uniform vec4 glow : source_color = vec4(0.55, 0.42, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(glow.rgb * 0.85, vec3(0.03, 0.0, 0.05), smoothstep(0.35, 0.95, l));
	COLOR = vec4(col, c.a * COLOR.a);
}
