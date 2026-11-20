class_name EnemyShot
extends Node2D

const DIR := "res://assets/monsters/%s"
const KINDS := {
	"bomb": {"sheet": "goblin/bomb.png", "fw": 100, "fh": 100, "fly": [0, 9], "burst": [9, 10], "magic": false, "arc": 34.0, "speed": 120.0, "dmg": 14.0, "splash": 22.0},
	"sword": {"sheet": "skeleton/sword.png", "fw": 92, "fh": 102, "fly": [0, 3], "burst": [3, 5], "magic": false, "arc": 0.0, "speed": 175.0, "dmg": 12.0, "splash": 0.0},
	"spore": {"sheet": "mushroom/spore.png", "fw": 50, "fh": 50, "fly": [0, 4], "burst": [4, 4], "magic": true, "arc": 0.0, "speed": 80.0, "dmg": 10.0, "splash": 0.0, "home": 0.8},
	"bolt": {"sheet": "flying_eye/bolt.png", "fw": 48, "fh": 48, "fly": [0, 3], "burst": [3, 5], "magic": true, "arc": 0.0, "speed": 145.0, "dmg": 9.0, "splash": 0.0, "home": 0.6},
}

static var _frames := {}

var kind := "bolt"
var cfg: Dictionary
var height := 14.0
var _from := Vector2.ZERO
var _target := Vector2.ZERO
var _vel := Vector2.ZERO
var _t := 0.0
var _flight := 1.0
var _done := false
var _sprite: AnimatedSprite2D
var _shadow: Node2D


func setup(k: String, from: Vector2, target: Vector2, h: float) -> void:
	kind = k
	cfg = KINDS[k]
	position = from
	_from = from
	_target = target
	height = h
	_vel = (target - from).normalized() * cfg.speed
	_flight = maxf(from.distance_to(target) / cfg.speed, 0.25)


func _ready() -> void:
	add_to_group("enemy_shots")
	if not _frames.has(kind):
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		Sheets.add(sf, "fly", DIR % cfg.sheet, cfg.fw, cfg.fh, cfg.fly[1], 14.0, true, false, Rect2i(), cfg.fly[0])
		Sheets.add(sf, "burst", DIR % cfg.sheet, cfg.fw, cfg.fh, cfg.burst[1], 18.0, false, false, Rect2i(), cfg.burst[0])
		_frames[kind] = sf
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _frames[kind]
	_sprite.scale = Vector2.ONE * 0.8
	add_child(_sprite)
	_sprite.play("fly")
	if kind == "sword" or kind == "bolt":
		_sprite.flip_h = _vel.x < 0.0
	_shadow = Node2D.new()
	_shadow.z_index = -1
	_shadow.draw.connect(func(): _shadow.draw_circle(Vector2.ZERO, 3.0, Color(0, 0, 0, 0.3)))
	add_child(_shadow)
	if cfg.magic:
		Fx.light(_sprite, Color(1.0, 0.45, 0.5) if kind == "spore" else Color(1.0, 0.7, 0.4), 0.4, 0.8)


func _physics_process(delta: float) -> void:
	if _done:
		return
	var w: Witch = Fx.world.get_meta("witch")
	var dt := delta * (0.35 if w and w.singularity_t > 0.0 and w.field_dist(global_position) < w.r_outer() else 1.0)
	_t += dt
	if cfg.has("home") and w and not w.dead:
		var want: Vector2 = (w.global_position - global_position).normalized() * cfg.speed
		_vel = _vel.lerp(want, minf(1.0, cfg.home * dt))
	var z := height
	if cfg.arc > 0.0:
		var k := _t / _flight
		z = lerpf(height, 0.0, k) + sin(minf(k, 1.0) * PI) * cfg.arc
		_sprite.rotation += 8.0 * dt
	elif kind == "sword":
		_sprite.rotation += 14.0 * dt
	var next := global_position + _vel * dt
	var q := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if get_world_2d().direct_space_state.intersect_ray(q):
		_burst(false)
		return
	global_position = next
	_sprite.position = Vector2(0, -z)
	if not w or w.dead:
		if _t > 4.0:
			queue_free()
		return
	var dist := w.field_dist(global_position)
	if not cfg.magic and dist < w.r_inner():
		_crushed()
		return
	if cfg.arc > 0.0 and _t >= _flight:
		_burst(true)
		return
	if cfg.arc <= 0.0 and global_position.distance_to(w.global_position) < 9.0:
		w.take_damage(cfg.dmg, global_position)
		_burst(false)
		return
	if _t > 4.0:
		_burst(false)


func _crushed() -> void:
	_done = true
	Fx.anim("crush_ring", global_position, 0.45, Color(0.85, 0.75, 1.0), 6.0)
	Fx.burst(global_position, Color(0.75, 0.7, 0.85), 8, 50.0, 6.0)
	Sfx.play("projectile_crushed", 0.1, -6.0)
	queue_free()


func _burst(splash: bool) -> void:
	_done = true
	if splash and cfg.splash > 0.0:
		var w: Witch = Fx.world.get_meta("witch")
		if w and not w.dead and global_position.distance_to(w.global_position) < cfg.splash:
			w.take_damage(cfg.dmg, global_position)
		Fx.shake(1.5)
		Sfx.play("impact", 0.1, -6.0)
	_shadow.visible = false
	_sprite.rotation = 0.0
	_sprite.play("burst")
	await _sprite.animation_finished
	queue_free()
