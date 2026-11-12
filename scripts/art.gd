class_name Art
extends RefCounted

static var _burst_process: ParticleProcessMaterial
static var _burst_mesh: Mesh


static func mat(color: Color, emission := Color.BLACK, tex: Texture2D = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.roughness = 1.0
	if tex:
		m.albedo_texture = tex
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
	return m


static func glow(color: Color, alpha := 1.0, billboard := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(color, alpha)
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	return m


static func aura_pass(color: Color) -> StandardMaterial3D:
	var m := glow(color, 0.45)
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = 0.045
	return m


static func mesh(m: Mesh, material: Material, pos := Vector3.ZERO, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	if parent:
		parent.add_child(mi)
	return mi


static func stone_texture(size: int, base: float, seed_value: int) -> ImageTexture:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in size:
		for x in size:
			var v := base + rng.randf_range(-0.05, 0.05)
			var off := 4 if (y / 8) % 2 == 1 else 0
			if y % 8 == 7 or (x + off) % 8 == 7:
				v *= 0.6
			elif y % 8 == 0:
				v *= 1.12
			img.set_pixel(x, y, Color(v, v * 1.01, v * 1.1))
	return ImageTexture.create_from_image(img)


static func popup(parent: Node, pos: Vector3, text: String, color: Color, size := 64) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.outline_size = 10
	l.pixel_size = 0.006
	l.modulate = color
	l.no_depth_test = true
	parent.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	var tw := l.create_tween()
	tw.set_parallel()
	tw.tween_property(l, "global_position:y", pos.y + 1.2, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)


static func burst(parent: Node, pos: Vector3, color: Color, amount := 24) -> void:
	if _burst_process == null:
		_burst_process = ParticleProcessMaterial.new()
		_burst_process.direction = Vector3.UP
		_burst_process.spread = 75.0
		_burst_process.initial_velocity_min = 3.0
		_burst_process.initial_velocity_max = 7.0
		_burst_process.gravity = Vector3(0, -12, 0)
		_burst_process.scale_min = 0.6
		_burst_process.scale_max = 1.3
		var q := BoxMesh.new()
		q.size = Vector3(0.12, 0.12, 0.12)
		_burst_mesh = q
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 0.8
	p.process_material = _burst_process
	p.draw_pass_1 = _burst_mesh
	p.material_override = glow(color, 1.0)
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func streak(parent: Node, from: Vector3, to: Vector3, color: Color, width: float, life: float) -> void:
	var length := from.distance_to(to)
	if length < 0.05:
		return
	var box := BoxMesh.new()
	box.size = Vector3(width, width, length)
	var mi := mesh(box, glow(color, 0.9), Vector3.ZERO, parent)
	mi.global_position = (from + to) * 0.5
	var dir := (to - from).normalized()
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	mi.look_at(to, up)
	var m: StandardMaterial3D = mi.material_override
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, life)
	tw.tween_callback(mi.queue_free)
