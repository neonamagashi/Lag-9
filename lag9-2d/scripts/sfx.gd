extends Node

const DIR := "res://assets/sfx/"

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


func play(sound: String, pitch_var := 0.08, vol_db := 0.0) -> void:
	if not _streams.has(sound):
		var path := DIR + sound + ".wav"
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	var s: AudioStream = _streams[sound]
	if not s:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = vol_db
	p.play()
