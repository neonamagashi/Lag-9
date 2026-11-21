class_name Whiskey
extends Node2D
## Placeholder cat: walks to a point, meowing, and slips away.

var target := Vector2.ZERO
var speed := 70.0
var _sprite: AnimatedSprite2D
var _meow_t := 0.3
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	Sheets.add(sf, "walk", "res://assets/limbo/whiskey_walk.png", 16, 16, 4, 8.0, true)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	_sprite.play("walk")
	var sh := Node2D.new()
	sh.z_index = -1
	sh.draw.connect(func(): sh.draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.18)))
	sh.scale = Vector2(1, 0.4)
	add_child(sh)
	_audio = AudioStreamPlayer2D.new()
	_audio.bus = "World"
	_audio.stream = Sfx.stream("meow")
	_audio.max_distance = 400.0
	_audio.volume_db = -6.0
	add_child(_audio)


func _process(delta: float) -> void:
	var to := target - position
	if to.length() < 3.0:
		modulate.a -= delta * 2.0
		if modulate.a <= 0.0:
			queue_free()
		return
	position += to.normalized() * speed * delta
	_sprite.flip_h = to.x < 0.0
	_meow_t -= delta
	if _meow_t <= 0.0:
		_meow_t = randf_range(1.4, 2.4)
		_audio.pitch_scale = randf_range(0.9, 1.15)
		_audio.play()
