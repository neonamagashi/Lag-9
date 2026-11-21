class_name Fx
extends RefCounted

const TEAL := Color(0.46, 0.86, 0.82)
const LIGHT_TEX := preload("res://assets/env/light.png")

const VFX := "res://assets/vfx/"
const ANIMS := {
	"cross": ["spell_pack3_a.png", 64, 2, 0, 18, 40.0],
	"summon": ["spell_pack3_a.png", 64, 0, 0, 17, 30.0],
	"vortex": ["spell_pack3_b.png", 64, 6, 0, 9, 12.0],
	"blades_in": ["spell_pack3_b.png", 64, 4, 0, 9, 22.0],
	"crush_ring": ["spell_pack3_b.png", 64, 5, 0, 9, 18.0],
	"lift_frame": ["spell_pack3_b.png", 64, 2, 0, 8, 18.0],
	"nova": ["holy/holy_nova.png", 64, 0, 0, 20, 34.0],
	"heal": ["holy/heal.png", 64, 0, 0, 12, 14.0],
	"comet": ["bullets/water.png", 16, 0, 24, 5, 14.0],
	"spark": ["bullets/water.png", 16, 5, 24, 5, 18.0],
	"slam_ring": ["bullets/purple.png", 16, 5, 14, 4, 14.0],
	"mana_orb": ["bullets/water.png", 16, 7, 14, 4, 6.0],
}

static var world: Node2D
static var _anim_frames := {}
static var _splats: Array[ImageTexture] = []
static var _beam: SpriteFrames
static var dark_world := false
static var _soft: Texture2D


static func soft() -> Texture2D:
	if not _soft:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 16
		t.height = 16
		_soft = t
	return _soft
static var camera: Camera2D
static var _shake := 0.0
static var _spikes: SpriteFrames


static func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


static func update(delta: float) -> void:
	if not camera:
		return
	_shake = maxf(0.0, _shake - delta * 30.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


static func burst(pos: Vector2, color: Color, n := 10, speed := 70.0, height := 8.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos + Vector2(0, -height)
	p.amount = n
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.45
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 160)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = color
	p.z_index = 5
	world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func number(pos: Vector2, value: float, color := Color(1, 0.95, 0.85)) -> void:
	var l := Label.new()
	l.text = str(int(round(value)))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
	l.add_theme_constant_override("outline_size", 3)
	l.position = pos + Vector2(-6 + randf_range(-4, 4), -34)
	l.z_index = 20
	world.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 14, 0.6).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	t.tween_callback(l.queue_free)


static func text(pos: Vector2, s: String, color: Color) -> void:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
	l.add_theme_constant_override("outline_size", 3)
	l.position = pos + Vector2(-14, -46)
	l.z_index = 20
	world.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 10, 0.8)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.tween_callback(l.queue_free)


static func light(parent: Node, color: Color, scale := 1.0, energy := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = LIGHT_TEX
	l.color = color
	l.texture_scale = scale
	l.energy = energy
	parent.add_child(l)
	return l


static func spikes(pos: Vector2) -> void:
	if not _spikes:
		_spikes = SpriteFrames.new()
		_spikes.remove_animation("default")
		Sheets.add(_spikes, "burst", "res://assets/witch/B_witch_attack.png", 104, 46, 4, 14.0, false, true, Rect2i(36, 0, 68, 46), 5)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _spikes
	s.centered = false
	s.offset = Vector2(-34, -44)
	s.position = pos
	world.add_child(s)
	s.play("burst")
	var l := light(s, TEAL, 0.9, 1.4)
	l.position = Vector2(0, -10)
	s.animation_finished.connect(func():
		var t := s.create_tween()
		t.tween_property(s, "modulate:a", 0.0, 0.25)
		t.tween_callback(s.queue_free))


static func frames(key: String) -> SpriteFrames:
	if _anim_frames.has(key):
		return _anim_frames[key]
	var d: Array = ANIMS[key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var size: int = d[1]
	Sheets.add(sf, "play", VFX + d[0], size, size, d[4], d[5], false, false, Rect2i(d[3] * size, d[2] * size, size, size))
	_anim_frames[key] = sf
	return sf


const VOID_ANIMS := ["cross", "spark", "lift_frame", "crush_ring", "slam_ring", "nova", "vortex", "blades_in", "summon", "comet"]
static var _void_mat: ShaderMaterial


static func _void() -> ShaderMaterial:
	if not _void_mat:
		_void_mat = ShaderMaterial.new()
		_void_mat.shader = load("res://scripts/void.gdshader")
	return _void_mat


static func anim(key: String, pos: Vector2, scale := 1.0, tint := Color.WHITE, height := 0.0, flatten := 1.0, z := 5) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames(key)
	s.position = pos + Vector2(0, -height)
	s.scale = Vector2(scale, scale * flatten)
	s.modulate = tint
	s.z_index = z
	if key in VOID_ANIMS:
		s.material = _void()
	world.add_child(s)
	s.play("play")
	s.animation_finished.connect(s.queue_free)
	return s


static var _rune_tex: Texture2D
const RUNE_COUNT := 19


## Tiny Futhark runes that spin, drift and fade: the visible grammar of her spells.
static func runes(pos: Vector2, n: int, spread: Vector2, rise := 10.0, life := 0.9, behind := false) -> void:
	if not _rune_tex:
		_rune_tex = load("res://assets/vfx/runes.png")
	var c := Color(0.24, 0.1, 0.45) if dark_world else Color(0.78, 0.64, 1.0)
	for i in n:
		var r := Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = _rune_tex
		at.region = Rect2((randi() % RUNE_COUNT) * 7, 0, 7, 9)
		r.texture = at
		var a := randf() * TAU
		r.position = pos + Vector2(cos(a) * spread.x, sin(a) * spread.y) * sqrt(randf())
		r.rotation = randf_range(-0.6, 0.6)
		r.modulate = Color(c, 0.0)
		r.z_index = 0 if behind else 9
		world.add_child(r)
		var spin := randf_range(1.2, 3.2) * (1.0 if randf() < 0.5 else -1.0)
		var t := r.create_tween().set_parallel()
		t.tween_property(r, "modulate:a", 0.95, life * 0.2)
		t.tween_property(r, "rotation", r.rotation + spin, life)
		t.tween_property(r, "position", r.position + Vector2(randf_range(-4, 4), -rise * randf_range(0.6, 1.2)), life).set_ease(Tween.EASE_OUT)
		t.tween_property(r, "scale", Vector2.ONE * 0.6, life).set_delay(life * 0.4)
		t.tween_property(r, "modulate:a", 0.0, life * 0.6).set_delay(life * 0.4)
		t.chain().tween_callback(r.queue_free)


## Runes strewn along a line (a beam, a throw).
static func runes_line(a: Vector2, b: Vector2, n: int, width: float, behind := false) -> void:
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	for i in n:
		runes(a.lerp(b, randf()) + side * randf_range(-width, width), 1, Vector2(2, 2), 8.0, randf_range(0.6, 1.0), behind)


static func ghost(actor: Actor) -> void:
	var g := Sprite2D.new()
	g.texture = actor.sprite.sprite_frames.get_frame_texture(actor.sprite.animation, actor.sprite.frame)
	g.centered = false
	g.flip_h = actor.sprite.flip_h
	g.offset = actor.sprite.offset
	g.position = actor.global_position + Vector2(0, -actor.z)
	g.modulate = Color(0.35, 0.2, 0.6, 0.55)
	g.z_index = -1
	world.add_child(g)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.25)
	t.tween_callback(g.queue_free)


static func ring(pos: Vector2, color: Color, radius: float, time := 0.35) -> void:
	var n := Node2D.new()
	n.position = pos
	n.z_index = -1
	var state := {"r": 4.0, "a": 1.0}
	n.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 33:
			var a := i / 32.0 * TAU
			pts.append(Vector2(cos(a), sin(a) * 0.6) * state.r)
		n.draw_polyline(pts, Color(color, state.a), 1.0))
	world.add_child(n)
	var t := n.create_tween()
	t.tween_method(func(v: float):
		state.r = lerpf(4.0, radius, v)
		state.a = 1.0 - v
		n.queue_redraw(), 0.0, 1.0, time)
	t.tween_callback(n.queue_free)


static func _particles(pos: Vector2, n: int, life: float, speed: Vector2, grav: Vector2, scale: Vector2, ramp: Gradient, z := 6) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = life
	p.spread = 180.0
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = grav
	p.scale_amount_min = scale.x
	p.scale_amount_max = scale.y
	p.color_ramp = ramp
	p.z_index = z
	world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func blood(pos: Vector2, height: float, amount := 1.0) -> void:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.85, 0.08, 0.1))
	ramp.set_color(1, Color(0.35, 0.02, 0.05, 0.0))
	var top := pos + Vector2(0, -height)
	_particles(top, int(46 * amount), 0.75, Vector2(40, 170) * amount, Vector2(0, 420), Vector2(1.0, 2.5), ramp)
	var chunks := Gradient.new()
	chunks.set_color(0, Color(0.55, 0.04, 0.08))
	chunks.set_color(1, Color(0.3, 0.02, 0.05, 0.0))
	_particles(top, int(12 * amount), 0.9, Vector2(60, 140) * amount, Vector2(0, 480), Vector2(2.5, 4.0), chunks)
	var mist := Gradient.new()
	mist.set_color(0, Color(0.7, 0.05, 0.08, 0.6))
	mist.set_color(1, Color(0.4, 0.0, 0.05, 0.0))
	_particles(top, 10, 0.6, Vector2(10, 40), Vector2(0, -10), Vector2(5.0, 8.0), mist)
	for i in int(3 * amount) + 1:
		splat(pos + Vector2(randf_range(-22, 22), randf_range(-10, 10)) * amount, randf_range(0.7, 1.3) * amount)


static func splat(pos: Vector2, scale := 1.0) -> void:
	if _splats.is_empty():
		for v in 4:
			var img := Image.create(24, 14, false, Image.FORMAT_RGBA8)
			for k in 7:
				var c := Vector2(randf_range(5, 19), randf_range(4, 10))
				var r := randf_range(1.5, 4.5)
				for y in 14:
					for x in 24:
						if Vector2(x, (y - c.y) * 1.6 + c.y).distance_to(c) < r:
							img.set_pixel(x, y, Color(0.42, 0.03, 0.06, 0.85) if randf() > 0.15 else Color(0.6, 0.06, 0.08, 0.9))
			_splats.append(ImageTexture.create_from_image(img))
	var s := Sprite2D.new()
	s.texture = _splats[randi() % _splats.size()]
	s.position = pos
	s.scale = Vector2.ONE * scale
	s.flip_h = randf() < 0.5
	s.z_index = -9
	world.add_child(s)
	var t := s.create_tween()
	t.tween_interval(7.0)
	t.tween_property(s, "modulate:a", 0.0, 2.0)
	t.tween_callback(s.queue_free)


static func smoke(pos: Vector2, n: int, size: float) -> void:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.04, 0.02, 0.06, 0.85))
	ramp.add_point(0.5, Color(0.12, 0.08, 0.16, 0.5))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.2, 0.15, 0.25, 0.0))
	var p := _particles(pos + Vector2(0, -12), n, 0.9, Vector2(8, 30) * size, Vector2(0, -26), Vector2(0.3, 0.6) * size, ramp, 6)
	p.texture = soft()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 6.0 * size
	var sparks := Gradient.new()
	sparks.set_color(0, Color(0.85, 0.8, 1.0, 0.9))
	sparks.set_color(1, Color(0.5, 0.4, 0.8, 0.0))
	_particles(pos + Vector2(0, -12), int(n * 0.4), 0.6, Vector2(20, 70) * size, Vector2(0, 0), Vector2(1.0, 1.0), sparks)


static func black_hole(pos: Vector2, size: float) -> void:
	anim("vortex", pos, size, Color(0.08, 0.04, 0.12, 0.95), 0.0, 0.6, -1)
	anim("vortex", pos, size * 0.6, Color(0.0, 0.0, 0.0, 0.9), 10.0, 0.8, 6)
	smoke(pos, int(10 + 18 * size), size)


static func beam(tip: Vector2, dir: Vector2, length: float, behind := false, band := 20.0) -> void:
	if not _beam:
		_beam = SpriteFrames.new()
		_beam.remove_animation("default")
		Sheets.add(_beam, "play", "res://assets/witch_white/beam.png", 88, 47, 6, 18.0, false, true)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _beam
	s.centered = false
	s.offset = Vector2(-3, -27.5)
	s.position = tip
	s.rotation = dir.angle()
	s.scale = Vector2(length / 88.0, 0.55)
	s.z_index = 0 if behind else 8
	world.add_child(s)
	s.play("play")
	s.animation_finished.connect(s.queue_free)
	var l := light(s, Color(0.55, 0.3, 1.0), 0.8, 0.8)
	l.position = Vector2(44, 0)
	anim("spark", tip, 0.8, Color.WHITE, 0.0)
	# twinkles mark the unseen band of gravity around the beam, wider than the beam itself
	var tw := CPUParticles2D.new()
	tw.amount = int(clampf(length / 5.0, 10.0, 48.0))
	tw.lifetime = 0.55
	tw.one_shot = true
	tw.explosiveness = 0.7
	tw.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	tw.emission_rect_extents = Vector2(length * 0.5, band)
	tw.position = tip + dir * length * 0.5
	tw.rotation = dir.angle()
	tw.direction = Vector2(0, 1)
	tw.spread = 180.0
	tw.initial_velocity_min = 2.0
	tw.initial_velocity_max = 10.0
	tw.gravity = Vector2.ZERO
	tw.texture = _twinkle()
	var g := Gradient.new()
	var c := Color(0.22, 0.1, 0.4) if dark_world else Color(0.8, 0.68, 1.0)
	g.set_color(0, Color(c, 0.0))
	g.add_point(0.25, Color(c, 1.0))
	g.set_color(g.get_point_count() - 1, Color(c, 0.0))
	tw.color_ramp = g
	tw.z_index = 0 if behind else 9
	world.add_child(tw)
	tw.emitting = true
	tw.get_tree().create_timer(1.0).timeout.connect(tw.queue_free)


static var _tw_tex: ImageTexture


static func _twinkle() -> Texture2D:
	if not _tw_tex:
		var im := Image.create(3, 3, false, Image.FORMAT_RGBA8)
		for k in 3:
			im.set_pixel(1, k, Color.WHITE)
			im.set_pixel(k, 1, Color.WHITE)
		_tw_tex = ImageTexture.create_from_image(im)
	return _tw_tex


static func _smoke_ramp(dark: Color, light_c: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(dark, 0.0))
	g.add_point(0.15, Color(dark, 0.85))
	g.add_point(0.6, Color(light_c, 0.45))
	g.set_color(g.get_point_count() - 1, Color(light_c, 0.0))
	return g


static func wave(pos: Vector2, r0: float, r1: float, time: float, inward: bool) -> void:
	var n := Node2D.new()
	n.position = pos
	n.z_index = 4
	world.add_child(n)
	var blobs := []
	for i in 56:
		blobs.append({"a": i / 56.0 * TAU + randf_range(-0.05, 0.05), "j": randf_range(-4, 4), "s": randf_range(1.5, 3.5), "rune": i % 7 == 0})
	var stars := []
	for i in 30:
		stars.append({"a": randf() * TAU, "j": randf_range(-8, 8), "p": randf() * TAU})
	var state := {"k": 0.0}
	n.draw.connect(func():
		var k: float = state.k
		var r := lerpf(r0, r1, ease(k, 0.6 if not inward else 1.8))
		var a := sin(k * PI) * 0.95
		for b in blobs:
			var rr: float = r + b.j * (0.4 + k)
			var p := Vector2(cos(b.a) * rr, sin(b.a) * rr * Witch.ELLIPSE)
			n.draw_circle(p, b.s * (1.0 + k * 0.6), Color(0.06, 0.04, 0.09, a * 0.55))
			if b.rune:
				var t := Vector2(-sin(b.a), cos(b.a) * Witch.ELLIPSE).normalized() * 3.0
				var o := Vector2(cos(b.a), sin(b.a) * Witch.ELLIPSE) * 3.0
				n.draw_line(p - o, p + o, Color(0.75, 0.68, 0.95, a), 1.0)
				n.draw_line(p, p + t + o * 0.5, Color(0.75, 0.68, 0.95, a), 1.0)
		for st in stars:
			var tw := pow(maxf(0.0, sin(st.p + k * 18.0)), 2.0)
			var rr: float = r + st.j
			var p := Vector2(cos(st.a) * rr, sin(st.a) * rr * Witch.ELLIPSE)
			var c := Color(0.15, 0.1, 0.25) if dark_world else Color(0.95, 0.92, 1.0)
			n.draw_rect(Rect2(p, Vector2(1, 1)), Color(c, a * tw)))
	var tw := n.create_tween()
	tw.tween_method(func(v: float):
		state.k = v
		n.queue_redraw(), 0.0, 1.0, time)
	tw.tween_callback(n.queue_free)


static func implode(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos + Vector2(0, -16)
	p.amount = 34
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 0.45
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	p.emission_sphere_radius = 22.0
	p.scale = Vector2(1.0, 0.8)
	p.radial_accel_min = -420.0
	p.radial_accel_max = -320.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 10.0
	p.gravity = Vector2.ZERO
	p.texture = soft()
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.7
	p.color_ramp = _smoke_ramp(Color(0.03, 0.02, 0.05), Color(0.2, 0.17, 0.25))
	p.z_index = 6
	world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func displace(pos: Vector2, follow: Node2D) -> void:
	var burst := CPUParticles2D.new()
	burst.position = pos + Vector2(0, -6)
	burst.amount = 40
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.lifetime = 0.8
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 5.0
	burst.direction = Vector2(0, -1)
	burst.spread = 75.0
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 110.0
	burst.damping_min = 120.0
	burst.damping_max = 180.0
	burst.gravity = Vector2(0, -50)
	burst.texture = soft()
	burst.scale_amount_min = 0.4
	burst.scale_amount_max = 0.9
	burst.color_ramp = _smoke_ramp(Color(0.02, 0.01, 0.04), Color(0.3, 0.27, 0.35))
	burst.z_index = 6
	world.add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
	var trail := CPUParticles2D.new()
	trail.local_coords = false
	trail.amount = 50
	trail.lifetime = 1.1
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 6.0
	trail.direction = Vector2(0, 1)
	trail.spread = 180.0
	trail.initial_velocity_min = 4.0
	trail.initial_velocity_max = 18.0
	trail.gravity = Vector2(0, 6)
	trail.texture = soft()
	trail.scale_amount_min = 0.35
	trail.scale_amount_max = 0.75
	trail.color_ramp = _smoke_ramp(Color(0.05, 0.04, 0.07), Color(0.4, 0.38, 0.45))
	trail.z_index = -1
	follow.add_child(trail)
	trail.position = Vector2(0, -2)
	trail.emitting = true
	var t := trail.create_tween()
	t.tween_interval(0.7)
	t.tween_callback(func(): trail.emitting = false)
	t.tween_interval(1.3)
	t.tween_callback(trail.queue_free)


static func ground_smoke(follow: Node2D, radius: float) -> CPUParticles2D:
	## Singularity: smoky flames billowing out from under her. Returns the flame emitter; the smoke is its child.
	var p := CPUParticles2D.new()
	p.amount = 160
	p.lifetime = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.scale = Vector2(1.0, Witch.ELLIPSE)
	p.direction = Vector2(0, -1)
	p.spread = 35.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, -60)
	p.damping_min = 10.0
	p.damping_max = 25.0
	p.texture = soft()
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1.0))
	sc.add_point(Vector2(0.5, 0.75))
	sc.add_point(Vector2(1, 0.15))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	# black flames with a faint red heart
	g.set_color(0, Color(0.35, 0.03, 0.04, 0.0))
	g.add_point(0.08, Color(0.3, 0.03, 0.04, 0.85))
	g.add_point(0.3, Color(0.09, 0.01, 0.02, 0.85))
	g.add_point(0.7, Color(0.03, 0.0, 0.01, 0.55))
	g.set_color(g.get_point_count() - 1, Color(0.02, 0.0, 0.0, 0.0))
	p.color_ramp = g
	p.z_index = -1
	follow.add_child(p)
	var smoke := CPUParticles2D.new()
	smoke.amount = 70
	smoke.lifetime = 1.8
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = radius * 1.1
	smoke.direction = Vector2(0, -1)
	smoke.spread = 45.0
	smoke.initial_velocity_min = 18.0
	smoke.initial_velocity_max = 40.0
	smoke.gravity = Vector2(0, -12)
	smoke.damping_min = 6.0
	smoke.damping_max = 12.0
	smoke.texture = soft()
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 1.8
	var c2 := Curve.new()
	c2.add_point(Vector2(0, 0.4))
	c2.add_point(Vector2(1, 1.4))
	smoke.scale_amount_curve = c2
	var g2 := Gradient.new()
	g2.set_color(0, Color(0.06, 0.0, 0.01, 0.0))
	g2.add_point(0.2, Color(0.07, 0.01, 0.02, 0.55))
	g2.add_point(0.6, Color(0.12, 0.06, 0.07, 0.3))
	g2.set_color(g2.get_point_count() - 1, Color(0.2, 0.15, 0.16, 0.0))
	smoke.color_ramp = g2
	smoke.z_index = -1
	smoke.show_behind_parent = true
	p.add_child(smoke)
	p.emitting = true
	smoke.emitting = true
	return p
