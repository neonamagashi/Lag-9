class_name Enemy
extends Actor

const DIR := "res://assets/monsters/%s/%s.png"

const KINDS := {
	"rat": {
		"hp": 40.0, "speed": 78.0, "weight": 1, "dmg": 8.0, "range": 20.0, "cd": 0.9, "radius": 6.0, "height": 16.0,
		"fw": 70, "fh": 70, "anchor": Vector2(35, 45), "shadow": Vector2(11, 3), "hit_frame": 6,
		"anims": {"idle": ["idle", 10, 10.0, true], "move": ["run", 8, 14.0, true], "attack": ["attack", 12, 18.0, false], "hurt": ["hurt", 3, 12.0, false], "death": ["death", 6, 10.0, false]},
	},
	"slime": {
		"hp": 130.0, "speed": 34.0, "weight": 2, "dmg": 16.0, "range": 34.0, "cd": 2.0, "radius": 10.0, "height": 18.0,
		"fw": 156, "fh": 156, "anchor": Vector2(76, 87), "shadow": Vector2(15, 4), "hit_frame": 11,
		"anims": {"idle": ["idle", 14, 10.0, true], "move": ["walk", 6, 8.0, true], "attack": ["attack", 19, 16.0, false], "hurt": ["hurt", 3, 12.0, false], "death": ["death", 11, 12.0, false]},
	},
	"bat": {
		"hp": 45.0, "speed": 72.0, "weight": 1, "dmg": 10.0, "range": 22.0, "cd": 1.6, "radius": 6.0, "height": 22.0, "fly": 28.0,
		"fw": 87, "fh": 87, "anchor": Vector2(46, 62), "shadow": Vector2(10, 3), "hit_frame": 6,
		"anims": {"idle": ["fly", 11, 14.0, true], "move": ["fly", 11, 14.0, true], "attack": ["attack", 11, 16.0, false], "hurt": ["hurt", 3, 12.0, false], "death": ["death", 4, 8.0, false], "fall": ["fall", 5, 10.0, true]},
	},
	"mimic": {
		"hp": 240.0, "speed": 46.0, "weight": 3, "dmg": 22.0, "range": 32.0, "cd": 1.9, "radius": 11.0, "height": 22.0, "dormant": true,
		"fw": 146, "fh": 146, "anchor": Vector2(73, 83), "shadow": Vector2(16, 4), "hit_frame": 8,
		"anims": {"closed": ["idle_closed", 1, 1.0, true], "wake": ["opening", 6, 12.0, false], "transform": ["transform", 7, 12.0, false], "idle": ["idle_transformed", 9, 10.0, true], "move": ["walk", 6, 9.0, true], "attack": ["attack_1", 14, 16.0, false], "hurt": ["hurt", 3, 12.0, false], "death": ["death", 6, 10.0, false]},
	},
	"goblin": {
		"hp": 60.0, "speed": 72.0, "weight": 1, "dmg": 12.0, "range": 24.0, "cd": 1.2, "radius": 7.0, "height": 30.0,
		"fw": 150, "fh": 150, "anchor": Vector2(75, 101), "shadow": Vector2(10, 3), "hit_frame": 6,
		"anims": {"idle": ["idle", 4, 8.0, true], "move": ["run", 8, 12.0, true], "attack": ["attack", 8, 14.0, false], "hurt": ["take_hit", 4, 14.0, false], "death": ["death", 4, 8.0, false]},
	},
	"skeleton": {
		"hp": 110.0, "speed": 40.0, "weight": 2, "dmg": 18.0, "range": 30.0, "cd": 1.8, "radius": 9.0, "height": 36.0,
		"fw": 150, "fh": 150, "anchor": Vector2(80, 101), "shadow": Vector2(12, 3), "hit_frame": 6,
		"anims": {"idle": ["idle", 4, 8.0, true], "move": ["walk", 4, 8.0, true], "attack": ["attack", 8, 12.0, false], "hurt": ["take_hit", 4, 14.0, false], "death": ["death", 4, 8.0, false]},
	},
	"mushroom": {
		"hp": 80.0, "speed": 46.0, "weight": 2, "dmg": 14.0, "range": 24.0, "cd": 1.5, "radius": 8.0, "height": 28.0,
		"fw": 150, "fh": 150, "anchor": Vector2(75, 101), "shadow": Vector2(10, 3), "hit_frame": 6,
		"anims": {"idle": ["idle", 4, 8.0, true], "move": ["run", 8, 12.0, true], "attack": ["attack", 8, 14.0, false], "hurt": ["take_hit", 4, 14.0, false], "death": ["death", 4, 8.0, false]},
	},
	"flying_eye": {
		"hp": 40.0, "speed": 82.0, "weight": 1, "dmg": 9.0, "range": 22.0, "cd": 1.4, "radius": 6.0, "height": 20.0, "fly": 26.0,
		"fw": 150, "fh": 150, "anchor": Vector2(77, 92), "shadow": Vector2(9, 3), "hit_frame": 6,
		"anims": {"idle": ["flight", 8, 14.0, true], "move": ["flight", 8, 14.0, true], "attack": ["attack", 8, 16.0, false], "hurt": ["take_hit", 4, 14.0, false], "death": ["death", 4, 8.0, false]},
	},
}

# ---------- field tuning by weight ----------
const CRUSH_DPS := {1: 0.5, 2: 0.15, 3: 0.05}
const INNER_MULT := 1.8
const SLOW := {1: 0.2, 2: 0.45, 3: 0.65}
const LIFT_Z := {1: 34.0, 2: 22.0, 3: 6.0}

static var _frames := {}

var kind := "rat"
var cfg: Dictionary
var weight := 1
var dead := false
var dormant := false
var lifted := false
var hit_radius := 6.0
var body_height := 16.0
var _cd := 0.5
var _attack_t := -1.0
var _struck := false
var _hurt_t := 0.0
var _knock_t := 0.0
var _stun_t := 0.0
var _waking := false
var _slam := false
var _fly_z := 0.0


func setup(k: String) -> Enemy:
	kind = k
	cfg = KINDS[k]
	return self


func _ready() -> void:
	add_to_group("enemies")
	max_hp = cfg.hp
	hp = max_hp
	weight = cfg.weight
	hit_radius = cfg.radius
	body_height = cfg.height
	shadow_size = cfg.shadow
	dormant = cfg.get("dormant", false)
	_fly_z = cfg.get("fly", 0.0)
	z = _fly_z
	collision_layer = 2
	collision_mask = 1 | 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = cfg.radius
	col.shape = c
	add_child(col)
	_build_visual(_sprite_frames())
	for a in cfg.anims:
		anchors[a] = Vector3(cfg.anchor.x, cfg.anchor.y, cfg.fw)
	play("closed" if dormant else "idle")
	_cd = randf_range(0.3, 1.0)


func _sprite_frames() -> SpriteFrames:
	if _frames.has(kind):
		return _frames[kind]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a in cfg.anims:
		var d: Array = cfg.anims[a]
		Sheets.add(sf, a, DIR % [kind, d[0]], cfg.fw, cfg.fh, d[1], d[2], d[3])
	_frames[kind] = sf
	return sf


# ---------- update ----------
func _physics_process(delta: float) -> void:
	var w: Witch = Fx.world.get_meta("witch")
	var dt := delta * (0.35 if w and w.singularity_t > 0.0 and w.field_depth(global_position) < 1.0 else 1.0)
	_update_visual(delta)
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		move_and_slide()
		var impact := _update_z(delta)
		if impact > 0.0:
			Fx.burst(global_position, Color(0.4, 0.35, 0.5), 6, 40.0, 2.0)
		return
	if dormant:
		if w and not w.dead and w.global_position.distance_to(global_position) < 52.0:
			_wake()
		return
	_cd -= dt
	_hurt_t -= dt
	_knock_t -= dt
	_stun_t -= dt
	var speed_mult := 1.0
	var in_field := w != null and not w.dead and w.field_depth(global_position) < 1.0
	var depth := w.field_depth(global_position) if in_field else 1.0
	var target_z := 0.0
	squash = move_toward(squash, 0.0, delta * 3.0)
	if in_field and w.mode == Witch.Mode.CRUSH:
		speed_mult = SLOW[weight]
		var dps: float = max_hp * CRUSH_DPS[weight] * (INNER_MULT if depth < 0.45 else 1.0) * (2.0 if w.singularity_t > 0.0 else 1.0)
		_field_damage(dps * dt)
		squash = move_toward(squash, 0.5 if depth < 0.45 else 0.3, delta * 4.0)
		if _fly_z > 0.0 and z > 2.0 and _stun_t <= 0.0:
			_stun_t = 1.8
			vz = -260.0
			_slam = true
			play("fall", true)
	elif in_field and w.mode == Witch.Mode.LIFT:
		speed_mult = 0.15 if weight < 3 else SLOW[3]
		target_z = LIFT_Z[weight] * (1.6 if w.singularity_t > 0.0 else 1.0) + sin(Time.get_ticks_msec() / 300.0 + get_instance_id()) * 2.0
	var was_lifted := lifted
	lifted = in_field and w.mode == Witch.Mode.LIFT and weight < 3
	if was_lifted and not lifted and z > 4.0:
		_slam = true
	if lifted:
		z = move_toward(z, target_z, 60.0 * dt)
		vz = 0.0
	elif _fly_z > 0.0 and _stun_t <= 0.0 and not _slam:
		z = move_toward(z, _fly_z, 40.0 * dt)
		vz = 0.0
	else:
		var impact := _update_z(dt)
		if impact > 0.0:
			_land(impact)
	_ai(w, dt, speed_mult)
	move_and_slide()
	_collisions()


func _ai(w: Witch, dt: float, speed_mult: float) -> void:
	if _knock_t > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * dt)
		return
	if _stun_t > 0.0 or lifted or _hurt_t > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * dt)
		if _stun_t > 0.0 and z <= 0.0 and _fly_z > 0.0:
			play("fall")
		elif lifted:
			play("hurt" if _hurt_t > 0.0 else "idle")
		return
	if _waking:
		velocity = Vector2.ZERO
		return
	if not w or w.dead:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * dt)
		play("idle")
		return
	var to := w.global_position - global_position
	if absf(to.x) > 2.0:
		facing = 1 if to.x > 0 else -1
	if _attack_t >= 0.0:
		_attack_t += dt
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * dt)
		if not _struck and sprite.animation == "attack" and sprite.frame >= cfg.hit_frame:
			_struck = true
			var reach: float = cfg.range + 8.0
			if to.length() < reach and w.z < 20.0:
				w.take_damage(cfg.dmg, global_position)
		if sprite.animation != "attack" or not sprite.is_playing():
			_attack_t = -1.0
			_cd = cfg.cd
		return
	var stand_off: float = cfg.range * 0.8
	if to.length() < cfg.range and _cd <= 0.0 and z < 40.0:
		_attack_t = 0.0
		_struck = false
		play("attack", true)
		Sfx.play("enemy_attack", 0.15, -10.0)
		return
	var want: Vector2 = to.normalized() * cfg.speed * speed_mult if to.length() > stand_off else Vector2.ZERO
	var sep := Vector2.ZERO
	for o in get_tree().get_nodes_in_group("enemies"):
		if o != self and not o.dead:
			var d: Vector2 = global_position - o.global_position
			if d.length() < 18.0 and d.length() > 0.01:
				sep += d.normalized() * (18.0 - d.length()) * 3.0
	velocity = velocity.move_toward(want + sep, 500.0 * dt)
	play("move" if velocity.length() > 6.0 else "idle")


func _collisions() -> void:
	if _knock_t <= 0.0:
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var speed := velocity.length()
		if speed < 90.0 and _knock_t < 0.3:
			continue
		var other := c.get_collider()
		var force := maxf(speed, 160.0)
		var dmg := max_hp * 0.22 * clampf(force / 300.0, 0.4, 1.4)
		if other is Enemy and not other.dead:
			other.hit(dmg * 0.6, velocity * 0.5)
			other.knock(velocity.normalized(), force * 0.5, 0.0)
		Fx.burst(c.get_position(), Color(0.8, 0.75, 0.9), 8, 60.0, 6.0)
		Sfx.play("impact", 0.1, -4.0)
		Fx.shake(2.5)
		hit(dmg, -velocity * 0.2)
		_knock_t = 0.0
		velocity = c.get_normal() * 30.0
		break


func _land(impact: float) -> void:
	if impact < 120.0 and not _slam:
		return
	var dmg := max_hp * clampf(impact / 1000.0, 0.08, 0.3) * (1.5 if _slam else 1.0)
	_slam = false
	Fx.burst(global_position, Color(0.75, 0.7, 0.85), 10, 70.0, 2.0)
	Fx.ring(global_position, Witch.CRUSH_COLOR, 22.0, 0.25)
	Sfx.play("impact", 0.1, -2.0)
	Fx.shake(2.0)
	hit(dmg, Vector2.ZERO)


func _field_damage(amount: float) -> void:
	hp -= amount
	if not has_meta("tick"):
		set_meta("tick", 0.0)
	var acc: float = get_meta("tick") + amount
	if acc >= 12.0:
		Fx.number(global_position + Vector2(0, -z), acc, Color(0.8, 0.7, 1.0))
		acc = 0.0
	set_meta("tick", acc)
	if hp <= 0.0:
		_die(true)


# ---------- interactions ----------
func hit(amount: float, push: Vector2) -> void:
	if dead:
		return
	if dormant:
		_wake()
	hp -= amount
	flash = 1.0
	Fx.number(global_position + Vector2(0, -z), amount)
	Sfx.play("enemy_hit", 0.12, -6.0)
	if _attack_t < 0.0 and weight < 3:
		_hurt_t = 0.18
		play("hurt", true)
	velocity += push
	if hp <= 0.0:
		_die(false)


func knock(dir: Vector2, force: float, dmg: float, pull := false) -> void:
	if dead or dormant:
		return
	var resist: float = {1: 1.0, 2: 0.7, 3: 0.35}[weight]
	velocity = dir * force * resist
	_knock_t = 0.35 if not pull else 0.25
	_attack_t = -1.0
	if not pull:
		vz = force * 0.3 * resist
		z = maxf(z, 0.5)
	if dmg > 0.0:
		hit(dmg, Vector2.ZERO)
	play("hurt", true)


func slam() -> void:
	_slam = true
	vz = -380.0
	lifted = false
	_stun_t = 0.6


func _wake() -> void:
	if not dormant:
		return
	dormant = false
	_waking = true
	Sfx.play("flip_crush", 0.0, -2.0)
	Fx.text(global_position, "!", Color(1.0, 0.5, 0.4))
	play("wake", true)
	await sprite.animation_finished
	play("transform", true)
	await sprite.animation_finished
	_waking = false
	play("idle")


func _die(crushed: bool) -> void:
	dead = true
	hp = 0.0
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 1
	_fly_z = 0.0
	if z > 0.0 and vz >= 0.0:
		vz = 0.0
	play("death", true)
	Sfx.play("crush_kill" if crushed else "enemy_hit", 0.1, -4.0)
	Fx.burst(global_position + Vector2(0, -z), Color(0.85, 0.8, 0.95), 12, 70.0, body_height * 0.5)
	var w: Witch = Fx.world.get_meta("witch")
	if w:
		w.gain_mana(4.0)
	if randf() < (0.35 if weight == 1 else 0.8):
		var p := Pickup.new()
		p.kind = "mana"
		p.amount = 10.0 + 8.0 * weight
		p.position = global_position + Vector2(randf_range(-6, 6), randf_range(-3, 3))
		Fx.world.call_deferred("add_child", p)
	Fx.world.get_meta("main").on_enemy_died(self)
	await get_tree().create_timer(1.6).timeout
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)
