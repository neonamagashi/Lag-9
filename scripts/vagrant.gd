class_name Vagrant
extends Node2D

const VARIANTS := 14
const SOLO := ["...", "mm... mmh...", "so close...", "was it enough...", "...why...", "hm... hm...", "almost...", "they never came...",
	"the forms... I filed the forms...", "left the kettle on...", "was it a tuesday...", "seven... no, eight...", "I had a hat once..."]
const ROWS := {"down": 0, "down_side": 1, "side": 2, "up_side": 3, "up": 4}

enum Mode { WANDER, STAND, SIT }

var variant := 0
var mode := Mode.WANDER
var face := Vector2.DOWN
var solo := true
## Height of whatever she's sitting on (a slab, a fallen drum).
var seat := 0.0
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
	_mumble_t = randf_range(2.0, 9.0)
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
	var sit_tex: Texture2D = load("res://assets/limbo/vagrant_%d_sit.png" % variant)
	sf.add_animation("sit")
	sf.set_animation_speed("sit", 3.0)
	for i in 4:
		var at := AtlasTexture.new()
		at.atlas = sit_tex
		at.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame("sit", at)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.offset = Vector2(0, -16)
	_sprite.position = Vector2(0, 1 - seat)
	add_child(_sprite)
	_sprite.play("sit" if mode == Mode.SIT else "idle_down")
	_sprite.frame = randi() % 4
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
	_audio.max_distance = 220.0
	_audio.volume_db = -12.0
	add_child(_audio)


func _process(delta: float) -> void:
	var speed := 30.0 if leaving else 13.0
	if leaving:
		modulate.a -= delta * 0.25
		if modulate.a <= 0.0:
			queue_free()
			return
	if mode == Mode.WANDER or leaving:
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
	if solo and not leaving:
		_mumble_t -= delta
		var w := get_tree().get_first_node_in_group("witch") as Node2D
		if _mumble_t <= 0.0 and w and w.global_position.distance_to(global_position) < 230.0:
			_mumble_t = randf_range(6.0, 13.0)
			speak(SOLO[randi() % SOLO.size()])


func speak(line: String, to_her := false) -> void:
	var c := Color(0.25, 0.22, 0.32) if to_her else Color(0.45, 0.43, 0.5)
	Dialogue.say(self, line, "", 1.0, c, 32.0 if mode != Mode.SIT else 28.0, 7 if to_her else 6)
	_audio.pitch_scale = randf_range(0.85, 1.15)
	_audio.play()


func _animate() -> void:
	if mode == Mode.SIT and not leaving:
		if _sprite.animation != "sit":
			_sprite.play("sit")
		return
	var moving := _vel.length() > 1.0
	var kind := "walk" if moving else "idle"
	var v := _vel if moving else face
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
	_wait = randf_range(0.0, 0.8) + (0.6 if mode == Mode.SIT else 0.0)
	if seat > 0.0:
		var t := create_tween()
		t.tween_property(_sprite, "position:y", 1.0, 0.3)
