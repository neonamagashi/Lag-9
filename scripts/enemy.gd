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

const SHOTS := {
	"goblin": {"shot": "bomb", "anim": ["attack3", 12, 14.0], "fire_frame": 8, "range": 230.0, "keep": 165.0, "cd": 3.0},
	"skeleton": {"shot": "sword", "anim": ["attack3", 6, 10.0], "fire_frame": 4, "range": 220.0, "keep": 160.0, "cd": 2.8},
	"mushroom": {"shot": "spore", "anim": ["attack3", 11, 14.0], "fire_frame": 7, "range": 200.0, "keep": 165.0, "cd": 3.4},
	"flying_eye": {"shot": "bolt", "anim": ["attack3", 6, 12.0], "fire_frame": 4, "range": 220.0, "keep": 170.0, "cd": 3.2},
}
const SCALE := {"rat": 0.62, "slime": 0.8, "bat": 0.8, "mimic": 0.85, "goblin": 0.82, "skeleton": 0.82, "mushroom": 0.82, "flying_eye": 0.82}
const STRUGGLE := {"rat": 2, "slime": 4, "bat": 1, "mimic": 2, "goblin": 1, "skeleton": 1, "mushroom": 1, "flying_eye": 1}

# ---------- field tuning by weight ----------
const DPS_OUTER := {1: 0.1, 2: 0.06, 3: 0.03}
const DPS_MID := {1: 0.55, 2: 0.3, 3: 0.12}
const SLOW_OUTER := {1: 0.35, 2: 0.5, 3: 0.7}
const LIFT_Z := {1: 34.0, 2: 22.0, 3: 6.0}
const TICK := 0.5
const KNOCK_FRICTION := 400.0
const LIFT_REACH := 0.3
const BOSS_FIELD_MULT := 0.3

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
var boss := false
var level := 10
var grabbed := false
var _holder: Witch
var pinned := false
var rending := false
var vis_scale := 1.0
var _stretch := 0.0
var _tick_t := 0.0
var _tick_acc := 0.0
var _struggle_t := 0.0
var _shot_cfg: Dictionary = {}
var _shooting := false
var _path := PackedVector2Array()
var _path_t := 0.0
var _hold_vel := Vector2.ZERO
var _squeeze := 0.0
var _spasm := 0.0
var _grip: Node2D
var _bump_from: Node
var _bump_t := 0.0
var _strafe_t := 0.0
var _strafe_dir := 1.0


func setup(k: String) -> Enemy:
	kind = k
	cfg = KINDS[k]
	return self


func _ready() -> void:
	add_to_group("enemies")
	max_hp = cfg.hp
	hp = max_hp
	weight = cfg.weight
	boss = cfg.get("boss", false)
	level = cfg.get("level", 10)
	vis_scale = SCALE.get(kind, 1.0)
	hit_radius = cfg.radius * vis_scale
	body_height = cfg.height * vis_scale
	shadow_size = cfg.shadow * vis_scale
	_shot_cfg = SHOTS.get(kind, {})
	dormant = cfg.get("dormant", false)
	_fly_z = cfg.get("fly", 0.0)
	z = _fly_z
	collision_layer = 2
	collision_mask = 1 | 2 | 8
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = cfg.radius * vis_scale
	col.shape = c
	add_child(col)
	_build_visual(_sprite_frames())
	for a in cfg.anims.keys() + ["shoot"]:
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
	if SHOTS.has(kind):
		var sa: Array = SHOTS[kind].anim
		Sheets.add(sf, "shoot", DIR % [kind, sa[0]], cfg.fw, cfg.fh, sa[1], sa[2], false)
	_frames[kind] = sf
	return sf


# ---------- update ----------
func _update_visual(delta: float) -> void:
	super(delta)
	visual.scale *= vis_scale * Vector2(1.0 + 0.4 * _stretch, 1.0 - 0.18 * _stretch)
	if rending:
		visual.position.x += randf_range(-1.5, 1.5)
	elif grabbed:
		# squeezed in an invisible fist: crushed inward, shuddering, struggling
		var sq := _squeeze
		visual.scale *= Vector2(1.0 - 0.3 * sq, 1.0 - 0.14 * sq + 0.06 * sin(_spasm * 3.0))
		visual.position += Vector2(randf_range(-1.0, 1.0), randf_range(-0.6, 0.6)) * (0.4 + sq)
		# legs (or wings) thrash in the air, faster as the grip tightens, with the odd jolt of pain
		_struggle_t -= delta
		if _struggle_t <= 0.0:
			_struggle_t = randf_range(0.5, 1.1)
			sprite.speed_scale = randf_range(1.8, 2.6) + sq
			if randf() < 0.35:
				play("hurt", true)
				sprite.speed_scale = 1.0
				_struggle_t = 0.2
			else:
				play("move")
		if _grip:
			_grip.position = Vector2(0, -z - body_height * 0.5)
			_grip.queue_redraw()
	elif pinned and not boss:
		_struggle_t -= delta
		if _struggle_t <= 0.0:
			_struggle_t = randf_range(0.12, 0.22)
			var f: int = STRUGGLE.get(kind, 1)
			sprite.frame = f if sprite.frame != f else maxi(0, f - 1)
		visual.position.x += randf_range(-0.8, 0.8)


func _physics_process(delta: float) -> void:
	var w: Witch = Fx.world.get_meta("witch")
	var alive_w := w != null and not w.dead
	var sing := alive_w and w.singularity_t > 0.0
	var dist := w.field_dist(global_position) if alive_w else INF
	var dt := delta * (0.35 if sing and dist < w.r_outer() else 1.0)
	_update_visual(delta)
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		move_and_slide()
		var impact := _update_z(delta)
		if impact > 0.0:
			Fx.burst(global_position, Color(0.4, 0.35, 0.5), 6, 40.0, 2.0)
		return
	if dormant:
		if alive_w and w.global_position.distance_to(global_position) < 52.0:
			_wake()
		return
	if rending:
		velocity = Vector2.ZERO
		return
	if grabbed:
		_held_update(delta)
		return
	_cd -= dt
	_bump_t -= dt
	_strafe_t -= dt
	_hurt_t -= dt
	_knock_t -= dt
	_stun_t -= dt
	var resists := boss and not sing
	var zone := 3
	if alive_w and w.field_active:
		zone = 0 if dist < w.r_inner() else (1 if dist < w.r_mid() else (2 if dist < w.r_outer() else 3))
	var speed_mult := 1.0
	var target_z := 0.0
	var was_pinned := pinned
	pinned = false
	squash = move_toward(squash, 0.0, delta * 3.0)
	if zone < 3 and w.mode == Witch.Mode.CRUSH:
		var k := clampf((w.r_outer() - dist) / (w.r_outer() - w.r_mid()), 0.0, 1.0)
		var dps: float
		if zone == 2:
			speed_mult = lerpf(1.0, SLOW_OUTER[weight], k)
			dps = max_hp * DPS_OUTER[weight] * k
			squash = move_toward(squash, 0.12 * k, delta * 3.0)
		else:
			speed_mult = 0.15 if weight >= 3 else 0.0
			dps = max_hp * DPS_MID[weight]
			pinned = weight < 3 or sing
			squash = move_toward(squash, 0.22, delta * 4.0)
		if resists:
			speed_mult = maxf(speed_mult, 0.6)
			dps *= BOSS_FIELD_MULT
			pinned = false
		if sing:
			dps *= 2.0
		_field_damage(dps * dt)
		if zone == 0 and not resists:
			_die(true)
			return
		if _fly_z > 0.0:
			if zone <= 1 and not resists:
				if z > 2.0 and _stun_t <= 0.0:
					vz = -260.0
					_slam = true
				_stun_t = maxf(_stun_t, 0.4)
			else:
				target_z = _fly_z * (1.0 - 0.6 * k)
	elif zone < 3 and w.mode == Witch.Mode.LIFT:
		var k := clampf((w.r_outer() - dist) / (w.r_outer() - w.r_mid()), 0.0, 1.0)
		speed_mult = lerpf(1.0, 0.4, k) if zone == 2 else (0.15 if weight < 3 else SLOW_OUTER[3])
		if resists:
			speed_mult = maxf(speed_mult, 0.6)
		var depth := 1.0 if zone <= 1 else lerpf(0.5, 1.0, k)
		target_z = LIFT_Z[weight] * depth * (1.6 if sing else 1.0) + sin(Time.get_ticks_msec() / 300.0 + get_instance_id()) * 2.0
	if pinned and not was_pinned:
		play("death", true)
		sprite.pause()
	elif was_pinned and not pinned:
		play("idle", true)
	var was_lifted := lifted
	var lift_k := clampf((w.r_outer() - dist) / (w.r_outer() - w.r_mid()), 0.0, 1.0) if alive_w else 0.0
	# the barrier keeps enemies out of the middle ring, so Lift also takes the inner part of the outer band
	lifted = alive_w and w.field_active and w.mode == Witch.Mode.LIFT and (zone <= 1 or (zone == 2 and lift_k > LIFT_REACH)) and (weight < 3 or sing) and not resists
	if lifted and not was_lifted:
		Fx.anim("lift_frame", global_position, 0.55, Color.WHITE, body_height * 0.5)
	if was_lifted and not lifted and z > 4.0:
		_slam = true
	if lifted:
		z = move_toward(z, target_z, 60.0 * dt)
		vz = 0.0
	elif _fly_z > 0.0 and _stun_t <= 0.0 and not _slam:
		z = move_toward(z, target_z if zone < 3 and target_z > 0.0 else _fly_z, 40.0 * dt)
		vz = 0.0
	else:
		var impact := _update_z(dt)
		if impact > 0.0:
			_land(impact)
	if pinned:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * dt)
		_attack_t = -1.0
		_shooting = false
	else:
		_ai(w, dt, speed_mult, resists)
	var pre := velocity
	move_and_slide()
	_collisions(pre)


func _steer(goal: Vector2, dt: float) -> Vector2:
	var level: TiledLevel = Fx.world.get_meta("main").level
	var direct := (goal - global_position).normalized()
	if not level:
		return direct
	var q := PhysicsRayQueryParameters2D.create(global_position, goal, 1)
	if not get_world_2d().direct_space_state.intersect_ray(q):
		_path = PackedVector2Array()
		return direct
	_path_t -= dt
	if _path_t <= 0.0 or _path.is_empty():
		_path_t = 0.5
		_path = level.path(global_position, goal)
		if _path.size() > 1:
			_path.remove_at(0)
	while _path.size() > 1 and global_position.distance_to(_path[0]) < 10.0:
		_path.remove_at(0)
	if _path.is_empty():
		return direct
	return (_path[0] - global_position).normalized()


func _barrier(w: Witch, v: Vector2) -> Vector2:
	var dist := w.field_dist(global_position)
	if dist > w.r_mid() + 3.0:
		return v
	var out := (global_position - w.global_position).normalized()
	var inward := v.dot(-out)
	return v + out * inward if inward > 0.0 else v


func _ai(w: Witch, dt: float, speed_mult: float, resists: bool) -> void:
	if _knock_t > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, KNOCK_FRICTION * dt)
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
	if _shooting:
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * dt)
		if not _struck and sprite.frame >= _shot_cfg.fire_frame:
			_struck = true
			var shot := EnemyShot.new()
			shot.setup(_shot_cfg.shot, global_position + Vector2(facing * 8.0, 0), w.global_position, z + body_height * 0.55)
			shot.shooter = self
			Fx.world.add_child(shot)
		if sprite.animation != "shoot" or not sprite.is_playing():
			_shooting = false
			_cd = _shot_cfg.cd
		return
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
	if not _shot_cfg.is_empty():
		stand_off = _shot_cfg.keep
		if to.length() < _shot_cfg.range and _cd <= 0.0 and _strafe_t <= 0.0:
			if _shot_cfg.shot != "bomb" and _ally_in_line(w.global_position):
				# an ally is in the way: sidestep for a clear shot instead of firing
				_strafe_t = randf_range(0.4, 0.8)
				_strafe_dir = -1.0 if randf() < 0.5 else 1.0
				return
			_shooting = true
			_struck = false
			play("shoot", true)
			return
	var want: Vector2 = Vector2.ZERO
	if to.length() > stand_off:
		want = _steer(w.global_position, dt) * cfg.speed * speed_mult
	elif not _shot_cfg.is_empty() and to.length() < stand_off - 20.0:
		want = -to.normalized() * cfg.speed * 0.6 * speed_mult
	if _strafe_t > 0.0:
		want = to.normalized().orthogonal() * _strafe_dir * cfg.speed * 0.8 * speed_mult
	var sep := Vector2.ZERO
	for o in get_tree().get_nodes_in_group("enemies"):
		if o != self and not o.dead:
			var d: Vector2 = global_position - o.global_position
			var room: float = hit_radius + o.hit_radius + 10.0
			if d.length() < room and d.length() > 0.01:
				sep += d.normalized() * (room - d.length()) * 3.5
			# keep clear of anything thrown or knocked flying
			if (o._knock_t > 0.0 or o.grabbed) and d.length() < 60.0 and o.velocity.length() > 80.0:
				var lane: Vector2 = o.velocity.normalized()
				var off := d - lane * d.dot(lane)
				if d.dot(lane) > 0.0 and off.length() < 26.0:
					sep += (off.normalized() if off.length() > 0.5 else lane.orthogonal()) * cfg.speed * 1.2
	# get out from under falling bombs
	for b in get_tree().get_nodes_in_group("enemy_shots"):
		if b.kind == "bomb" and not b.done:
			var d: Vector2 = global_position - b.landing
			var r: float = b.cfg.splash + 14.0
			if d.length() < r:
				sep += (d.normalized() if d.length() > 0.5 else Vector2.RIGHT) * cfg.speed * 1.3
	var v := want + sep
	if not resists:
		v = _barrier(w, v)
	velocity = velocity.move_toward(v, 500.0 * dt)
	play("move" if velocity.length() > 6.0 else "idle")


func _collisions(pre: Vector2) -> void:
	if _knock_t <= 0.0:
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var speed := pre.length()
		if speed < 80.0:
			continue
		var other := c.get_collider()
		if other is Enemy:
			if other.dead or (other == _bump_from and _bump_t > 0.0):
				continue
			_body_hit(other, pre, c.get_normal(), c.get_position())
			break
		if speed < 90.0 and _knock_t < 0.3:
			continue
		var force := maxf(speed, 160.0)
		var dmg := max_hp * 0.22 * clampf(force / 300.0, 0.4, 1.4)
		Fx.burst(c.get_position(), Color(0.8, 0.75, 0.9), 8, 60.0, 6.0)
		Sfx.play("impact", 0.1, -4.0)
		Fx.shake(2.5)
		hit(dmg, -velocity * 0.2)
		_knock_t = 0.0
		velocity = c.get_normal() * 30.0
		break


## Two bodies collide: momentum passes on by weight, both get hurt, and the struck one can go on to hit others.
func _body_hit(other: Enemy, v: Vector2, normal: Vector2, at: Vector2) -> void:
	var speed := v.length()
	_bump_from = other
	_bump_t = 0.35
	other._bump_from = self
	other._bump_t = 0.35
	var ratio := clampf(float(weight) / float(other.weight), 0.4, 1.8)
	var dmg := (5.0 + speed * 0.035) * (0.7 + 0.3 * weight)
	var dir := v.normalized().lerp(-normal, 0.5).normalized()
	if other.grabbed:
		other.hit(dmg, Vector2.ZERO)
	else:
		other.knock(dir, speed * 0.95 * sqrt(ratio), dmg)
	hit(dmg * 0.6 / ratio, Vector2.ZERO)
	velocity = v.bounce(normal) * 0.3 / ratio
	_knock_t = minf(_knock_t, 0.15)
	Fx.burst(at + Vector2(0, -z - body_height * 0.4), Color(0.85, 0.8, 0.95), 10, 70.0, 0.0)
	Fx.anim("slam_ring", at, 1.2, Color.WHITE, 0.0, 0.5, -1)
	Sfx.play("impact", 0.1, -3.0)
	Fx.shake(2.0 + minf(speed / 200.0, 2.0))


func _ally_in_line(goal: Vector2) -> bool:
	var seg := goal - global_position
	var n := seg.length()
	if n < 1.0:
		return false
	var dir := seg / n
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self or o.dead or o.dormant:
			continue
		var d: Vector2 = o.global_position - global_position
		var t := d.dot(dir)
		if t > 4.0 and t < n - 12.0 and (d - dir * t).length() < o.hit_radius + 5.0:
			return true
	return false


func _land(impact: float) -> void:
	if impact < 120.0 and not _slam:
		return
	var dmg := max_hp * clampf(impact / 1000.0, 0.08, 0.3) * (1.5 if _slam else 1.0)
	_slam = false
	Fx.burst(global_position, Color(0.75, 0.7, 0.85), 10, 70.0, 2.0)
	Fx.anim("slam_ring", global_position, 2.4, Color.WHITE, 0.0, 0.6, -1)
	Sfx.play("impact", 0.1, -2.0)
	Fx.shake(2.0)
	hit(dmg, Vector2.ZERO)


func _field_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	hp -= amount
	_tick_acc += amount
	_tick_t -= get_physics_process_delta_time()
	if _tick_t <= 0.0:
		_tick_t = TICK
		if _tick_acc >= 1.0:
			Fx.number(global_position + Vector2(0, -z), _tick_acc, Color(0.78, 0.68, 1.0))
		_tick_acc = 0.0
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
	if _attack_t < 0.0 and weight < 3 and not pinned and not rending:
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
	# airborne/sliding until friction has bled the speed off
	_knock_t = maxf(0.25, force * resist / KNOCK_FRICTION) if not pull else 0.25
	_attack_t = -1.0
	if not pull:
		vz = force * 0.3 * resist
		z = maxf(z, 0.5)
	if dmg > 0.0:
		hit(dmg, Vector2.ZERO)
	play("hurt", true)


func rend(lift_time: float, dmg: float) -> void:
	if dead or rending:
		return
	rending = true
	_attack_t = -1.0
	_shooting = false
	pinned = false
	play("hurt", true)
	sprite.pause()
	Fx.anim("lift_frame", global_position, 0.6, Color(1.0, 0.4, 0.4), body_height * 0.5)
	var start_z := z
	var t := create_tween()
	t.tween_method(func(v: float):
		z = lerpf(start_z, start_z + 30.0, v)
		_stretch = v * v, 0.0, 1.0, lift_time).set_ease(Tween.EASE_OUT)
	await t.finished
	rending = false
	_stretch = 0.0
	if dead:
		return
	var tear := not boss and (weight <= 2 or hp <= dmg)
	Fx.blood(global_position, z + body_height * 0.5, 1.0 if tear else 0.5)
	Fx.anim("crush_ring", global_position, 0.9, Color(1.0, 0.35, 0.35), z + body_height * 0.5)
	Fx.shake(3.5 if tear else 2.0)
	Sfx.play("crush_kill", 0.1, 0.0)
	if tear:
		hp = 0.0
		visual.visible = false
		(get_meta("shadow") as Node2D).visible = false
		_die(false, true)
	else:
		vz = -200.0
		hit(dmg, Vector2.ZERO)


func grab(w: Witch) -> void:
	grabbed = true
	_holder = w
	pinned = false
	_attack_t = -1.0
	_shooting = false
	_knock_t = 0.0
	_hold_vel = velocity * 0.5
	_squeeze = 0.0
	_struggle_t = 0.0
	play("hurt", true)
	Fx.anim("lift_frame", global_position, 0.55, Color(0.8, 0.7, 1.0), body_height * 0.5)
	_grip = Node2D.new()
	_grip.z_index = 1
	_grip.draw.connect(_draw_grip)
	add_child(_grip)


## Four dark "fingers" closing around the body, tightening with the squeeze.
func _draw_grip() -> void:
	var r := (hit_radius + 7.0) * (1.0 - 0.25 * _squeeze)
	var c := Color(0.2, 0.1, 0.35, 0.55 + 0.35 * _squeeze) if Fx.dark_world else Color(0.75, 0.6, 1.0, 0.45 + 0.4 * _squeeze)
	for i in 4:
		var a0 := i * TAU / 4.0 + 0.35 + sin(_spasm + i) * 0.05
		_grip.draw_arc(Vector2.ZERO, r, a0, a0 + 0.9, 8, c, 1.0)
		var tip := Vector2(cos(a0 + 0.9), sin(a0 + 0.9)) * (r - 3.0 - 2.0 * _squeeze)
		_grip.draw_line(Vector2(cos(a0 + 0.9), sin(a0 + 0.9)) * r, tip, c, 1.0)


func _held_update(delta: float) -> void:
	if not is_instance_valid(_holder) or _holder.dead:
		drop()
		return
	_update_visual_hold(delta)
	var target := _holder.hold_point()
	# held on a spring: lags behind the hand and swings when she moves her aim
	var stiff := 70.0 / (0.6 + 0.4 * weight)
	_hold_vel += ((target - global_position) * stiff - _hold_vel * 7.0) * delta
	velocity = _hold_vel
	var pre := velocity
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var other := c.get_collider()
		if other is Enemy and not other.dead and pre.length() > 120.0 and not (other == _bump_from and _bump_t > 0.0):
			_body_hit(other, pre, c.get_normal(), c.get_position())
			_hold_vel = velocity
			break
	_bump_t -= delta
	var dangle := 16.0 + sin(Time.get_ticks_msec() / 160.0) * 1.5
	vz += ((dangle - z) * 60.0 - vz * 8.0) * delta
	z += vz * delta
	var swing := clampf(-_hold_vel.x * 0.0035, -0.55, 0.55)
	visual.rotation = lerpf(visual.rotation, swing, 1.0 - exp(-delta * 10.0))


func _update_visual_hold(delta: float) -> void:
	var charge := 0.0
	if _holder.throw_charge >= 0.0:
		charge = _holder.throw_charge / Witch.THROW_MAX_CHARGE
	_spasm += delta * (6.0 + 8.0 * charge)
	var beat := pow(maxf(0.0, sin(_spasm)), 3.0)
	_squeeze = clampf(0.35 + 0.35 * beat + 0.4 * charge, 0.0, 1.0)
	if beat > 0.95 and randf() < 0.3:
		Sfx.play("enemy_hit", 0.25, -16.0, 0.6)
	_field_damage(max_hp * (0.04 + 0.06 * charge) * delta)


func release(dir: Vector2, force: float, dmg: float) -> void:
	_let_go()
	velocity = dir * force + _hold_vel * 0.3
	_knock_t = maxf(0.4, velocity.length() / KNOCK_FRICTION)
	vz = 60.0
	if dmg > 0.0:
		hit(dmg, Vector2.ZERO)


func drop() -> void:
	_let_go()
	vz = -40.0


func _let_go() -> void:
	grabbed = false
	_holder = null
	visual.rotation = 0.0
	_squeeze = 0.0
	sprite.speed_scale = 1.0
	if _grip:
		_grip.queue_free()
		_grip = null


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


func _die(crushed: bool, torn := false) -> void:
	if dead:
		return
	dead = true
	pinned = false
	hp = 0.0
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 1
	_fly_z = 0.0
	if z > 0.0 and vz >= 0.0:
		vz = 0.0
	play("death", true)
	if not torn:
		Sfx.play("crush_kill" if crushed else "enemy_hit", 0.1, -4.0)
	if torn:
		pass
	elif crushed:
		Fx.anim("crush_ring", global_position, 0.8, Color.WHITE, z + body_height * 0.5)
	else:
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
