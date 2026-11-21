class_name GravityField
extends Node2D

const SIGIL_OUTER := preload("res://assets/vfx/sigil_outer.png")
const SIGIL_MID := preload("res://assets/vfx/sigil_mid.png")
const ZONE_COUNTS := [60, 90, 64]
const STAR_COLORS := [Color(0.96, 0.94, 1.0), Color(0.78, 0.7, 1.0), Color(0.6, 0.95, 0.92)]
const STAR_COLORS_DARK := [Color(0.2, 0.17, 0.28), Color(0.4, 0.3, 0.6), Color(0.3, 0.45, 0.5)]

var witch: Witch
var _stars := []
var _t := 0.0
var _pulse := 0.0
var _reveal := 1.0


func _ready() -> void:
	z_index = -2
	for zone in 3:
		for i in ZONE_COUNTS[zone]:
			var s := {"zone": 2 - zone}
			_respawn(s, true)
			_stars.append(s)


func _bounds(zone: int) -> Vector2:
	var k := witch.field_scale()
	match zone:
		0:
			return Vector2(Witch.R_INNER * 0.25, Witch.R_INNER) * k
		1:
			return Vector2(Witch.R_INNER, Witch.R_MID) * k
	return Vector2(Witch.R_MID, Witch.R_OUTER) * k


func _respawn(s: Dictionary, anywhere := false) -> void:
	var b := _bounds(s.zone)
	var lift := witch.mode == Witch.Mode.LIFT
	s.r = randf_range(b.x, b.y) if anywhere else (b.x if lift else b.y) * randf_range(0.97, 1.0)
	s.a = randf() * TAU
	s.phase = randf() * TAU
	s.rate = randf_range(2.5, 6.0)
	s.rise = 0.0
	s.big = randf() < (0.08 if s.zone == 2 else 0.16)
	var roll := randf()
	var pal: Array = STAR_COLORS_DARK if Fx.dark_world else STAR_COLORS
	s.color = pal[0] if roll < 0.7 else (pal[1] if roll < 0.92 else pal[2])


func _process(delta: float) -> void:
	if witch.dead:
		visible = false
		return
	_t += delta
	_reveal = move_toward(_reveal, 1.0 if witch.field_active else 0.0, delta * 0.8)
	_pulse = fmod(_pulse + delta / 1.8, 1.0)
	var lift := witch.mode == Witch.Mode.LIFT
	var sing := witch.singularity_t > 0.0
	var k := witch.field_scale()
	for s in _stars:
		var b := _bounds(s.zone)
		var speed: float = (8.0 + 900.0 / (s.r / k + 12.0)) * k * (1.8 if sing else 1.0)
		var swirl: float = (0.25 + 9.0 / (s.r / k + 8.0)) * (1.6 if sing else 1.0)
		if lift:
			s.r += speed * 0.55 * delta
			s.a -= swirl * 0.5 * delta
			s.rise += (10.0 + 30.0 / (s.zone + 1)) * delta
			if s.r > b.y or s.rise > 26.0:
				_respawn(s)
		else:
			s.r -= speed * delta
			s.a += swirl * delta
			if s.r < b.x:
				_respawn(s)
	queue_redraw()


func _ellipse(r: float, n := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := i / float(n) * TAU
		pts.append(Vector2(cos(a) * r, sin(a) * r * Witch.ELLIPSE))
	return pts


func _draw() -> void:
	var k := witch.field_scale()
	var sing := witch.singularity_t > 0.0
	var lift := witch.mode == Witch.Mode.LIFT
	var r_out := Witch.R_OUTER * k
	var r_mid := Witch.R_MID * k
	var r_in := Witch.R_INNER * k
	var shade := Color(0.03, 0.02, 0.05)
	var rv := _reveal
	if rv > 0.01:
		_draw_zones(k, sing, lift, r_out, r_mid, r_in, shade, rv)
	_draw_stars(lift, rv)


func _draw_zones(k: float, sing: bool, lift: bool, r_out: float, r_mid: float, r_in: float, shade: Color, rv: float) -> void:
	for i in 4:
		draw_colored_polygon(_ellipse(r_out * (1.0 - i * 0.025)), Color(shade, (0.045 + (0.03 if sing else 0.0)) * rv))
	for i in 3:
		draw_colored_polygon(_ellipse(r_mid * (1.0 - i * 0.04)), Color(shade, (0.09 + (0.04 if sing else 0.0)) * rv))
	for i in 3:
		draw_colored_polygon(_ellipse(r_in * (1.0 - i * 0.12)), Color(0.0, 0.0, 0.0, 0.4 * rv))
	var line := Color(0.62, 0.56, 0.8, 0.32 * rv) if not lift else Color(0.9, 0.78, 0.5, 0.32 * rv)
	if Fx.dark_world:
		line = Color(0.3, 0.25, 0.42, 0.45 * rv) if not lift else Color(0.55, 0.42, 0.15, 0.45 * rv)
	var spin := _t * (0.12 if not lift else -0.12) * (2.0 if sing else 1.0)
	_sigil(SIGIL_OUTER, r_out, spin, line)
	_sigil(SIGIL_MID, r_mid, -spin * 1.7, Color(line, line.a * 1.15))
	var p := _pulse if lift else 1.0 - _pulse
	var pr := lerpf(r_in, r_out, p)
	draw_polyline(_ellipse(pr, 64) + PackedVector2Array([_ellipse(pr, 64)[0]]), Color(line, 0.35 * sin(p * PI) * rv), 1.0)


func _draw_stars(lift: bool, rv: float) -> void:
	for s in _stars:
		if rv < 0.5 and s.zone == 2:
			continue
		var b := _bounds(s.zone)
		var edge := clampf((b.y - s.r) / (b.y * 0.12), 0.0, 1.0) if not lift else clampf(1.0 - s.rise / 26.0, 0.0, 1.0)
		var tw := pow(maxf(0.0, sin(s.phase + _t * s.rate)), 2.0)
		var base: float = [0.95, 0.75, 0.55][s.zone]
		var a: float = base * tw * edge
		if a < 0.04:
			continue
		var pos := Vector2(cos(s.a) * s.r, sin(s.a) * s.r * Witch.ELLIPSE - s.rise)
		var c: Color = s.color
		c.a = a
		if s.big and tw > 0.6:
			draw_rect(Rect2(pos + Vector2(-1, 0), Vector2(3, 1)), c)
			draw_rect(Rect2(pos + Vector2(0, -1), Vector2(1, 3)), c)
		else:
			draw_rect(Rect2(pos, Vector2(1, 1)), c)


func _draw_aim(r_in: float) -> void:
	var d := witch.aim
	var t := r_in / Vector2(d.x, d.y / Witch.ELLIPSE).length() + 7.0
	var p := d * t
	var out := d
	var side := Vector2(-d.y, d.x)
	var c := Color(0.82, 0.72, 1.0, 0.9) if not Fx.dark_world else Color(0.35, 0.22, 0.6, 0.95)
	var pulse := 0.7 + 0.3 * sin(_t * 6.0)
	draw_line(p - out * 4.0, p + out * 4.0, Color(c, c.a * pulse), 1.0)
	draw_line(p + out * 4.0, p + out * 1.0 + side * 3.0, Color(c, c.a * pulse), 1.0)
	draw_line(p + out * 4.0, p + out * 1.0 - side * 3.0, Color(c, c.a * pulse), 1.0)
	draw_line(p - out * 1.0 + side * 2.0, p - out * 3.0 + side * 4.0, Color(c, c.a * 0.6 * pulse), 1.0)
	draw_line(p - out * 1.0 - side * 2.0, p - out * 3.0 - side * 4.0, Color(c, c.a * 0.6 * pulse), 1.0)


func _sigil(tex: Texture2D, r: float, rot: float, color: Color) -> void:
	var sq := Transform2D(Vector2(1, 0), Vector2(0, Witch.ELLIPSE), Vector2.ZERO)
	draw_set_transform_matrix(sq * Transform2D(rot, Vector2.ZERO))
	draw_texture_rect(tex, Rect2(-r, -r, r * 2.0, r * 2.0), false, color)
	draw_set_transform_matrix(Transform2D.IDENTITY)
