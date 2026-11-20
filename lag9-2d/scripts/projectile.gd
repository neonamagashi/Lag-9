class_name Projectile
extends Node2D

const SPEED := 270.0
const RANGE := 230.0
const HEIGHT := 16.0

var dir := Vector2.RIGHT
var damage := 10.0
var _travelled := 0.0
var _sprite: AnimatedSprite2D


func setup(pos: Vector2, d: Vector2, dmg: float) -> void:
	position = pos
	dir = d
	damage = dmg


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Fx.frames("comet")
	_sprite.position = Vector2(0, -HEIGHT)
	_sprite.rotation = Vector2(dir.x, dir.y * 0.8).angle()
	add_child(_sprite)
	_sprite.play("play")
	_sprite.animation_finished.connect(func(): _sprite.frame = 2; _sprite.play("play"))
	var l := Fx.light(self, Color(0.45, 0.95, 0.9), 0.5, 1.0)
	l.position = Vector2(0, -HEIGHT)


func _physics_process(delta: float) -> void:
	var step := dir * SPEED * delta
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		_pop(hit.position)
		return
	global_position += step
	_travelled += step.length()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.dormant:
			continue
		var d: Vector2 = e.global_position + Vector2(0, -e.z) - global_position
		if absf(d.x) < e.hit_radius + 3.0 and absf(d.y + e.body_height * 0.5 - HEIGHT * 0.5) < e.body_height * 0.6 + 4.0:
			e.hit(damage, dir * 60.0)
			Fx.anim("cross", global_position, 0.55, Color.WHITE, HEIGHT)
			queue_free()
			return
	if _travelled > RANGE:
		_pop(global_position)


func _pop(p: Vector2) -> void:
	Fx.anim("spark", p, 1.0, Color.WHITE, HEIGHT)
	queue_free()
