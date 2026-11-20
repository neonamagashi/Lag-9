class_name Vagrant
extends Node2D

const MUMBLES := ["...", "mm... mmh...", "so close...", "was it enough...", "...why...", "hm... hm...", "almost...", "they never came..."]
const ROWS := {"down": 0, "down_side": 1, "side": 2, "up_side": 3, "up": 4}

var variant := 0
var home := Vector2.ZERO
var leaving := false
var _sprite: AnimatedSprite2D
var _target := Vector2.ZERO
var _wait := 0.0
var _mumble_t := 0.0
var _vel := Vector2.ZERO
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	home = position
	_target = home
	_wait = randf_range(0.5, 3.0)
	_mumble_t = randf_range(2.0, 8.0)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for kind in ["idle", "walk"]:
		var tex: Texture2D = load("res://assets/limbo/vagrant_%d_%s.png" % [variant, kind])
		for dir in ROWS:
			var a: String = kind + "_" + dir
			sf.add_animation(a)
			sf.set_animation_speed(a, 5.0 if kind == "idle" else 6.0)
			for i in 4:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * 32, ROWS[dir] * 32, 32, 32)
				sf.add_frame(a, at)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.offset = Vector2(0, -16)
	_sprite.scale = Vector2.ONE * 1.5
	_sprite.position = Vector2(0, 1)
	_sprite.play("idle_down")
	_sprite.frame = randi() % 4
	add_child(_sprite)
	var sh := Node2D.new()
	sh.z_index = -1
	sh.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 12:
			var a := i / 12.0 * TAU
			pts.append(Vector2(cos(a) * 7.0, sin(a) * 2.2))
		sh.draw_colored_polygon(pts, Color(0, 0, 0, 0.18)))
	add_child(sh)
	_audio = AudioStreamPlayer2D.new()
	_audio.bus = "World"
	_audio.stream = Sfx.stream("mumble")
	_audio.max_distance = 260.0
	_audio.volume_db = -10.0
	add_child(_audio)


func _process(delta: float) -> void:
	var speed := 30.0 if leaving else 13.0
	if leaving:
		modulate.a -= delta * 0.25
		if modulate.a <= 0.0:
			queue_free()
			return
	if position.distance_to(_target) > 2.0 and _wait <= 0.0:
		_vel = (_target - position).normalized() * speed
	else:
		_vel = Vector2.ZERO
		_wait -= delta
		if _wait <= 0.0 and not leaving:
			_target = home + Vector2(randf_range(-70, 70), randf_range(-45, 45))
			_wait = randf_range(1.5, 4.5)
	position += _vel * delta
	_animate()
	_mumble_t -= delta
	var w := get_tree().get_first_node_in_group("witch") as Node2D
	if _mumble_t <= 0.0 and not leaving and w and w.global_position.distance_to(global_position) < 240.0:
		_mumble_t = randf_range(5.0, 11.0)
		Dialogue.say(self, MUMBLES[randi() % MUMBLES.size()], "", 1.0, Color(0.45, 0.43, 0.5), 30.0, 6)
		_audio.pitch_scale = randf_range(0.85, 1.15)
		_audio.play()


func _animate() -> void:
	var kind := "walk" if _vel.length() > 1.0 else "idle"
	var v := _vel if _vel.length() > 1.0 else Vector2(0, 1)
	var dir := "down"
	var ang := rad_to_deg(atan2(v.y, absf(v.x)))
	if ang > 67.5:
		dir = "down"
	elif ang > 22.5:
		dir = "down_side"
	elif ang > -22.5:
		dir = "side"
	elif ang > -67.5:
		dir = "up_side"
	else:
		dir = "up"
	_sprite.flip_h = v.x < -0.1
	var a := kind + "_" + dir
	if _sprite.animation != a:
		_sprite.play(a)


func leave(from: Vector2) -> void:
	leaving = true
	var away := (global_position - from).normalized()
	if away == Vector2.ZERO:
		away = Vector2.DOWN
	_target = global_position + away.rotated(randf_range(-0.5, 0.5)) * 400.0
	_wait = randf_range(0.0, 0.8)
