class_name Style
extends RefCounted

const TOON := preload("res://shaders/style/toon.gdshader")
const OUTLINE := preload("res://shaders/style/outline.gdshader")
const WORLD := preload("res://shaders/style/sable_world.gdshader")
const POST := preload("res://shaders/style/post.gdshader")
const INK := Color(0.16, 0.11, 0.10)
const SKY_TOP := Color(0.62, 0.78, 0.80)
const SKY_HORIZON := Color(0.98, 0.90, 0.78)
const HAZE := Color(0.97, 0.89, 0.78)

static var enabled := true
static var retro := false
static var _noise: NoiseTexture2D
static var _post: ShaderMaterial


static func toon(tex: Texture2D, color := Color.WHITE, outline_width := 1.5) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("use_tex", tex != null)
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("pastel", 0.08)
	m.set_shader_parameter("posterize", 7.0)
	m.set_shader_parameter("saturation", 1.1)
	m.set_shader_parameter("hatch", 0.25)
	if outline_width > 0.0:
		m.next_pass = outline(outline_width)
	return m


static func outline(width := 1.5) -> ShaderMaterial:
	var o := ShaderMaterial.new()
	o.shader = OUTLINE
	o.set_shader_parameter("line_color", INK)
	o.set_shader_parameter("width", width)
	return o


static func toonify(root: Node, outline_width := 1.5) -> void:
	if not enabled:
		return
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node
		if not mi.mesh:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i) as BaseMaterial3D
			if src and (src.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or src.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
				continue
			var tex: Texture2D = src.albedo_texture if src else null
			var col: Color = src.albedo_color if src else Color.WHITE
			mi.set_surface_override_material(i, toon(tex, col, outline_width))


static func noise() -> NoiseTexture2D:
	if not _noise:
		var fn := FastNoiseLite.new()
		fn.frequency = 0.02
		fn.fractal_octaves = 3
		_noise = NoiseTexture2D.new()
		_noise.width = 256
		_noise.height = 256
		_noise.seamless = true
		_noise.noise = fn
		_noise.generate_mipmaps = true
	return _noise


static func world(sway := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WORLD
	m.set_shader_parameter("noise_tex", noise())
	m.set_shader_parameter("sway", sway)
	return m


static func environment() -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = SKY_TOP
	sm.sky_horizon_color = SKY_HORIZON
	sm.ground_horizon_color = SKY_HORIZON
	sm.ground_bottom_color = Color(0.9, 0.78, 0.64)
	sm.sun_angle_max = 6.0
	sm.sun_curve = 0.05
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.95)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = HAZE
	env.fog_density = 0.011
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 1.2
	return env


static func sun() -> DirectionalLight3D:
	var s := DirectionalLight3D.new()
	s.rotation_degrees = Vector3(-38, 35, 0)
	s.light_color = Color(1.0, 0.97, 0.9)
	s.light_energy = 0.9
	s.shadow_enabled = true
	s.directional_shadow_max_distance = 90.0
	return s


static func attach_post(cam: Camera3D) -> void:
	if not enabled:
		return
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	q.mesh = qm
	q.extra_cull_margin = 16384.0
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_post = ShaderMaterial.new()
	_post.shader = POST
	_post.set_shader_parameter("line_color", INK)
	_post.set_shader_parameter("retro", retro)
	q.material_override = _post
	cam.add_child(q)
	q.position.z = -1.0


static func set_retro(on: bool) -> void:
	retro = on
	if _post:
		_post.set_shader_parameter("retro", on)
