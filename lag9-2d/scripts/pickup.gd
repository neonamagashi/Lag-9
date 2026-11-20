class_name Pickup
extends Node2D

static var _frames: Array[Texture2D] = []

var kind := "mana"
var amount := 15.0
var _t := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	if _frames.is_empty():
		_frames = Sheets.strip("res://assets/env/pickups.png", 8, 12)
	_sprite = Sprite2D.new()
	_sprite.texture = _frames[4] if kind == "whisky" else Fx.frames("mana_orb").get_frame_texture("play", 2)
	if kind == "mana":
		_sprite.scale = Vector2.ONE * 0.75
	add_child(_sprite)
	Fx.light(self, Color(0.45, 0.95, 0.9) if kind == "mana" else Color(1.0, 0.7, 0.4), 0.35, 0.8)


func _physics_process(delta: float) -> void:
	_t += delta
	_sprite.position.y = -6.0 + sin(_t * 4.0) * 1.5
	if kind == "mana":
		_sprite.rotation = sin(_t * 3.0) * 0.2
	var w: Witch = Fx.world.get_meta("witch")
	if not w or w.dead:
		return
	var d := w.global_position - global_position
	if d.length() < 40.0:
		global_position += d.normalized() * minf(d.length(), 160.0 * delta)
	if d.length() < 8.0:
		if kind == "mana":
			w.gain_mana(amount)
			Fx.anim("spark", w.global_position, 1.0, Color.WHITE, 14.0)
			Sfx.play("mana_pickup", 0.1, -8.0)
		else:
			w.whisky += 1
			Sfx.play("whisky", 0.0, -4.0)
			Fx.text(global_position, "whisky", Color(1.0, 0.8, 0.5))
		queue_free()
