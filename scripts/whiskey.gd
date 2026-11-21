class_name Whiskey
extends Node2D
## Whiskey: walks to a point, meowing, and slips away.

var path: Array = []
var speed := 70.0
var _sprite: AnimatedSprite2D
var _meow_t := 0.3
var _audio: AudioStreamPlayer2D
var _gone := false


func _ready() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for n in ["walk_up", "walk_down", "walk_left", "walk_right"]:
		Sheets.add(sf, n, "res://assets/cat/whiskey_%s_s.png" % n, 32, 32, 6, 9.0, true)
	Sheets.add(sf, "meow", "res://assets/cat/whiskey_meow_s.png", 32, 32, 3, 6.0, true)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.offset = Vector2(0, -10)
	add_child(_sprite)
	_sprite.play("walk_up")
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
	if path.is_empty():
		return
	var to: Vector2 = path[0] - position
	if to.length() < 3.0:
		path.pop_front()
		if path.is_empty() and not _gone:
			_gone = true
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.5)
			t.tween_callback(queue_free)
		return
	position += to.normalized() * speed * delta
	var d := to.normalized()
	var anim := ("walk_up" if d.y < 0.0 else "walk_down") if absf(d.y) > absf(d.x) * 0.8 else ("walk_right" if d.x > 0.0 else "walk_left")
	if _sprite.animation != anim:
		_sprite.play(anim)
	_meow_t -= delta
	if _meow_t <= 0.0:
		_meow_t = randf_range(1.4, 2.4)
		_audio.pitch_scale = randf_range(0.9, 1.15)
		_audio.play()
