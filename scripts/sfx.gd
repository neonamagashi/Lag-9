extends Node

const SFX_DIR := "res://audio/sfx/"
const AMBIENT_DIR := "res://audio/ambient/"
const POOL_3D := 24
const POOL_2D := 8

var _streams := {}
var _pool3d: Array[AudioStreamPlayer3D] = []
var _pool2d: Array[AudioStreamPlayer] = []
var _i3 := 0
var _i2 := 0
var _ambient: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_3D:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 8.0
		p.max_distance = 70.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_pool3d.append(p)
	for i in POOL_2D:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool2d.append(p)
	_ambient = AudioStreamPlayer.new()
	add_child(_ambient)


func _stream(sound: String) -> AudioStream:
	if not _streams.has(sound):
		var path := SFX_DIR + sound + ".wav"
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sound]


func play(sound: String, pos: Variant = null, pitch_var := 0.08, vol_db := 0.0) -> void:
	var s := _stream(sound)
	if s == null:
		return
	if pos is Vector3:
		var p := _pool3d[_i3]
		_i3 = (_i3 + 1) % POOL_3D
		p.stream = s
		p.global_position = pos
		p.volume_db = vol_db
		p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
		p.play()
	else:
		play_held(sound, vol_db, pitch_var)


func play_held(sound: String, vol_db := 0.0, pitch_var := 0.0) -> AudioStreamPlayer:
	var s := _stream(sound)
	if s == null:
		return null
	var p := _pool2d[_i2]
	_i2 = (_i2 + 1) % POOL_2D
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()
	return p


func play_ambient(track: String, vol_db := -10.0) -> void:
	var path := AMBIENT_DIR + track + ".wav"
	if not ResourceLoader.exists(path):
		return
	var s: AudioStreamWAV = (load(path) as AudioStreamWAV).duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	_ambient.stream = s
	_ambient.volume_db = vol_db
	_ambient.play()
