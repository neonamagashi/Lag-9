class_name Fx
extends RefCounted

const TEAL := Color(0.46, 0.86, 0.82)
const LIGHT_TEX := preload("res://assets/env/light.png")

static var world: Node2D
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


static func ghost(actor: Actor) -> void:
	var g := Sprite2D.new()
	g.texture = actor.sprite.sprite_frames.get_frame_texture(actor.sprite.animation, actor.sprite.frame)
	g.centered = false
	g.flip_h = actor.sprite.flip_h
	g.offset = actor.sprite.offset
	g.position = actor.global_position + Vector2(0, -actor.z)
	g.modulate = Color(0.5, 1.0, 0.95, 0.55)
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
