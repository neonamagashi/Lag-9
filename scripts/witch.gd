class_name Witch
extends Actor

enum Mode { CRUSH, LIFT }

const DIR := "res://assets/witch_white/%s.png"
const CRUSH_COLOR := Color(0.55, 0.42, 1.0)
const LIFT_COLOR := Color(1.0, 0.82, 0.4)
const ELLIPSE := 0.6
const HAND_TIP := Vector2(11, -18)

# ---------- tuning ----------
const SPEED := 118.0
const ACCEL := 1100.0
const BODY_H := 40.0
const R_INNER := BODY_H * 0.5
const R_MID := BODY_H * 1.5
const R_OUTER := BODY_H * 4.0
const HOVER := 3.0
const PIERCE_CD := 0.5
const PIERCE_DMG := 20.0
const PIERCE_RANGE := 210.0
const GRAB_RANGE := 220.0
const GRAB_CONE := 35.0
const HOLD_DIST := 46.0
const THROW_MAX_CHARGE := 0.8
const SEND_CD := 1.4
const SEND_MAX_CHARGE := 0.8
const SEND_RANGE := Vector2(90.0, 150.0)
const DRAW_CD := 1.4
const DRAW_MAX_CHARGE := 0.8
const DRAW_RANGE := Vector2(130.0, 210.0)
const REND_CD := 7.0
const REND_TARGETS := 3
const REND_RANGE := 190.0
const REND_DMG := 120.0
const REND_LIFT_TIME := 0.55
const SNAP_CD := 0.9
const SNAP_DIST := 96.0
const JUMP_MAX_CHARGE := 0.6
const JUMP_VZ := Vector2(170.0, 280.0)
const SING_CD := 25.0
const SING_COST := 60.0
const SING_TIME := 6.0
const SING_RADIUS := 2.4
const WHISKY_HEAL := 35.0

signal interact

var level := 10
var mode := Mode.CRUSH
var mana := 60.0
var whisky := 3
var cooldowns := {"pierce": 0.0, "grab": 0.0, "send": 0.0, "draw": 0.0, "rend": 0.0, "snap": 0.0, "jump": 0.0, "singularity": 0.0}
var send_charge := -1.0
var draw_charge := -1.0
var jump_charge := -1.0
var throw_charge := -1.0
var held: Enemy
var singularity_t := 0.0
var dead := false
var abilities_enabled := true
var field_active := true
var aim := Vector2.RIGHT
var aim_point: Variant = null
var hover := HOVER
var _cast_t := 0.0
var _hurt_t := 0.0
var _iframes := 0.0
var _field_k := 1.0
var _back := false
var _t := 0.0
var _sing_smoke: CPUParticles2D
var field: GravityField
var glow: PointLight2D
var eyes: AnimatedSprite2D


func _ready() -> void:
	add_to_group("witch")
	hp = 100.0
	max_hp = 100.0
	shadow_size = Vector2(9, 3)
	collision_layer = 0
	collision_mask = 1 | 8
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	col.shape = c
	add_child(col)
	var sf := SpriteFrames.new()
	var ef := SpriteFrames.new()
	sf.remove_animation("default")
	ef.remove_animation("default")
	var defs := [
		["idle", "idle", 64, 64, 6, 8.0, true, 0],
		["hurt", "hurt", 64, 64, 3, 12.0, false, 0], ["death", "death", 64, 64, 11, 10.0, false, 0],
		["cast", "cast", 44, 47, 2, 20.0, false, 0], ["cast_hold", "cast", 44, 47, 6, 14.0, true, 1],
		["jump", "jump", 54, 64, 8, 12.0, true, 0],
	]
	for d in defs:
		Sheets.add(sf, d[0], DIR % d[1], d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
		Sheets.add(ef, d[0], DIR % (d[1] + "_eyes"), d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
		if ResourceLoader.exists(DIR % (d[1] + "_back")):
			Sheets.add(sf, d[0] + "_back", DIR % (d[1] + "_back"), d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
			Sheets.add(ef, d[0] + "_back", DIR % (d[1] + "_eyes"), d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
	var base := {"idle": Vector3(23, 62, 64), "hurt": Vector3(23, 62, 64), "death": Vector3(23, 62, 64),
		"cast": Vector3(27, 45, 44), "cast_hold": Vector3(27, 45, 44), "jump": Vector3(35, 62, 54)}
	for k in base:
		anchors[k] = base[k]
		anchors[k + "_back"] = base[k]
	_build_visual(sf)
	eyes = AnimatedSprite2D.new()
	eyes.sprite_frames = ef
	eyes.centered = false
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	eyes.material = add
	visual.add_child(eyes)
	play("idle")
	field = GravityField.new()
	field.witch = self
	add_child(field)
	glow = Fx.light(self, Color(0.7, 0.55, 1.0), 1.6, 0.35)
	glow.position = Vector2(0, -26)


func _update_visual(delta: float) -> void:
	super(delta)
	visual.position.y -= hover
	# floating: lean into the drift instead of walking
	var lean := clampf(velocity.x / SPEED, -1.0, 1.0) * 0.09 * (1.0 if z <= 0.0 else 0.4)
	visual.skew = lerpf(visual.skew, -lean, 1.0 - exp(-delta * 8.0))
	eyes.animation = sprite.animation
	eyes.frame = sprite.frame
	eyes.flip_h = sprite.flip_h
	eyes.offset = sprite.offset
	eyes.visible = not _back
	eyes.modulate.a = 0.75 + 0.25 * sin(_t * 3.0)


# ---------- input & movement ----------
func _physics_process(delta: float) -> void:
	_t += delta
	for k in cooldowns:
		cooldowns[k] = maxf(0.0, cooldowns[k] - delta)
	_cast_t -= delta
	_hurt_t -= delta
	_iframes -= delta
	var drift := clampf(velocity.length() / SPEED, 0.0, 1.0)
	hover = HOVER + drift * 1.5 + sin(_t * (2.2 + drift * 1.4)) * (1.2 + drift * 0.6)
	if singularity_t > 0.0:
		singularity_t -= delta
		if singularity_t <= 0.0:
			Sfx.play("flip_crush", 0.0, -6.0)
			if _sing_smoke:
				_sing_smoke.emitting = false
				_sing_smoke = null
	_field_k = lerpf(_field_k, SING_RADIUS if singularity_t > 0.0 else 1.0, 1.0 - exp(-delta * 6.0))
	if _sing_smoke:
		_sing_smoke.emission_sphere_radius = r_inner()
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		move_and_slide()
		_update_visual(delta)
		return
	var target: Vector2 = aim_point if aim_point != null else get_global_mouse_position()
	aim = (target - global_position + Vector2(0, 20)).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT * facing
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var charging := send_charge >= 0.0 or draw_charge >= 0.0 or jump_charge >= 0.0
	var spd := SPEED * (0.45 if charging else 1.0)
	velocity = velocity.move_toward(dir * spd, ACCEL * delta * (0.35 if z > 0.0 else 1.0))
	collision_mask = 8 if z > 6.0 else 1 | 8
	move_and_slide()
	var impact := _update_z(delta)
	if impact > 0.0:
		_land()
	if Input.is_action_just_pressed("interact"):
		interact.emit()
	_abilities(delta, dir)
	_animate(dir)
	_update_visual(delta)


func _abilities(delta: float, dir: Vector2) -> void:
	if not abilities_enabled:
		return
	if Input.is_action_just_pressed("jump") and z <= 0.0 and cooldowns.jump <= 0.0:
		jump_charge = 0.0
	if jump_charge >= 0.0:
		jump_charge = minf(jump_charge + delta, JUMP_MAX_CHARGE)
		squash = 0.25 * jump_charge / JUMP_MAX_CHARGE
		if not Input.is_action_pressed("jump"):
			_jump(jump_charge / JUMP_MAX_CHARGE)
	if Input.is_action_just_pressed("flip"):
		mode = Mode.LIFT if mode == Mode.CRUSH else Mode.CRUSH
		Sfx.play("flip_lift" if mode == Mode.LIFT else "flip_crush", 0.03, -2.0)
		Fx.ring(global_position, _mode_color(), R_MID * _field_k, 0.3)
		if mode == Mode.CRUSH:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.lifted:
					e.slam()
	if Input.is_action_just_pressed("snap") and cooldowns.snap <= 0.0:
		_teleport(dir.normalized() if dir.length() > 0.1 else aim)
	if Input.is_action_pressed("pierce") and cooldowns.pierce <= 0.0:
		_pierce()
	_grab_input(delta)
	if Input.is_action_just_pressed("send") and cooldowns.send <= 0.0:
		send_charge = 0.0
	if send_charge >= 0.0:
		send_charge = minf(send_charge + delta, SEND_MAX_CHARGE)
		if not Input.is_action_pressed("send"):
			_push(send_charge / SEND_MAX_CHARGE)
			send_charge = -1.0
	if Input.is_action_just_pressed("draw") and cooldowns.draw <= 0.0:
		draw_charge = 0.0
	if draw_charge >= 0.0:
		draw_charge = minf(draw_charge + delta, DRAW_MAX_CHARGE)
		if not Input.is_action_pressed("draw"):
			_pull(draw_charge / DRAW_MAX_CHARGE)
			draw_charge = -1.0
	if Input.is_action_just_pressed("rend") and cooldowns.rend <= 0.0:
		_rend()
	if Input.is_action_just_pressed("singularity") and cooldowns.singularity <= 0.0 and mana >= SING_COST:
		_singularity()
	if Input.is_action_just_pressed("whisky") and whisky > 0 and hp < max_hp:
		whisky -= 1
		hp = minf(max_hp, hp + WHISKY_HEAL)
		Sfx.play("whisky", 0.0, -2.0)
		Fx.anim("heal", global_position, 1.0, Color.WHITE, 22.0)
		Fx.text(global_position, "+%d" % WHISKY_HEAL, Color(0.5, 0.9, 0.5))


func _animate(dir: Vector2) -> void:
	var casting := _cast_t > 0.0 or throw_charge >= 0.0 or held != null
	if casting:
		if absf(aim.x) > 0.15:
			facing = 1 if aim.x > 0 else -1
		_back = aim.y < -0.55
	else:
		if absf(dir.x) > 0.1:
			facing = 1 if dir.x > 0 else -1
		if dir.y < -0.35:
			_back = true
		elif dir.y > 0.35 or (absf(dir.x) > 0.5 and absf(dir.y) < 0.2):
			_back = false
	var anim := "idle"
	if _hurt_t > 0.0:
		anim = "hurt"
	elif z > 0.0 or jump_charge >= 0.0:
		anim = "jump"
	elif _cast_t > 0.0:
		anim = "cast" if sprite.animation.trim_suffix("_back") == "cast" and sprite.is_playing() else "cast_hold"
	elif held != null or send_charge >= 0.0 or draw_charge >= 0.0:
		anim = "cast_hold"
	var name := anim + "_back" if _back and sprite.sprite_frames.has_animation(anim + "_back") else anim
	if anim == "jump" and jump_charge >= 0.0:
		play(name)
		sprite.pause()
		sprite.frame = 0
	else:
		play(name)


# ---------- abilities ----------
func hand_tip() -> Vector2:
	return global_position + Vector2(HAND_TIP.x * facing, HAND_TIP.y - z - hover)


func _pierce() -> void:
	cooldowns.pierce = PIERCE_CD
	_cast_t = 0.42
	if aim.x != 0.0:
		facing = 1 if aim.x > 0 else -1
	play("cast_back" if _back else "cast", true)
	var tip := hand_tip()
	var target: Vector2 = aim_point if aim_point != null else get_global_mouse_position()
	var dir := (target - tip).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(facing, 0)
	var length := PIERCE_RANGE
	var ground := global_position
	var q := PhysicsRayQueryParameters2D.create(ground, ground + dir * PIERCE_RANGE, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		length = ground.distance_to(hit.position) + 6.0
	Fx.beam(tip, dir, length)
	Sfx.play("beam", 0.08, -8.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.dormant:
			continue
		var c: Vector2 = e.global_position - Vector2(0, e.z + e.body_height * 0.5)
		var t := clampf((c - tip).dot(dir), 0.0, length)
		if (tip + dir * t).distance_to(c) < e.hit_radius + 7.0:
			e.hit(PIERCE_DMG, dir * 50.0)
			Fx.anim("cross", c + Vector2(0, e.body_height * 0.5), 0.5, Color.WHITE, e.body_height * 0.5)


func _grab_input(delta: float) -> void:
	if held and (held.dead or not is_instance_valid(held)):
		held = null
		throw_charge = -1.0
	if Input.is_action_just_pressed("grab"):
		if held:
			throw_charge = 0.0
		elif cooldowns.grab <= 0.0:
			_grab()
	if throw_charge >= 0.0:
		throw_charge = minf(throw_charge + delta, THROW_MAX_CHARGE)
		if not Input.is_action_pressed("grab") and held:
			var k := throw_charge / THROW_MAX_CHARGE
			held.release(aim, lerpf(220.0, 560.0, k), lerpf(6.0, 18.0, k))
			Sfx.play("push_wave", 0.08, -6.0 + 4.0 * k)
			Fx.shake(1.5 + 2.0 * k)
			_cast_t = 0.3
			held = null
			throw_charge = -1.0
			cooldowns.grab = 0.4


func _grab() -> void:
	var best: Enemy = null
	var best_score := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.dormant or e.rending or not can_grab(e):
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() > GRAB_RANGE or to.length() < 4.0:
			continue
		var ang := rad_to_deg(absf(aim.angle_to(to)))
		if ang > GRAB_CONE:
			continue
		var score := ang * 2.0 + to.length() * 0.1
		if score < best_score:
			best_score = score
			best = e
	if not best:
		Fx.text(global_position, "nothing to grab", Color(0.6, 0.55, 0.7))
		cooldowns.grab = 0.3
		return
	held = best
	best.grab(self)
	_cast_t = 0.3
	Sfx.play("grab", 0.08, -4.0)


func can_grab(e: Enemy) -> bool:
	return not e.boss or level >= e.level


func hold_point() -> Vector2:
	return global_position + aim * HOLD_DIST


func _push(k: float) -> void:
	cooldowns.send = SEND_CD
	_cast_t = 0.3
	var rng := lerpf(SEND_RANGE.x, SEND_RANGE.y, k)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.dormant or e == held:
			continue
		var to: Vector2 = e.global_position - global_position
		if field_dist(e.global_position) < rng:
			var d := to.normalized() if to.length() > 1.0 else Vector2.RIGHT.rotated(randf() * TAU)
			e.knock(d, lerpf(180.0, 420.0, k), lerpf(5.0, 14.0, k))
	Fx.wave(global_position, r_inner(), rng, 0.35 + 0.1 * k, false)
	Sfx.play("push_wave", 0.05, -6.0 + 4.0 * k)
	Fx.shake(1.5 + 2.5 * k)


func _pull(k: float) -> void:
	cooldowns.draw = DRAW_CD
	_cast_t = 0.3
	var rng := lerpf(DRAW_RANGE.x, DRAW_RANGE.y, k)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.dormant or e == held:
			continue
		var to: Vector2 = global_position - e.global_position
		if field_dist(e.global_position) < rng and to.length() > 8.0:
			e.knock(to.normalized(), clampf(to.length() * 2.6, 140.0, 380.0) * lerpf(0.8, 1.2, k), lerpf(3.0, 8.0, k), true)
	Fx.wave(global_position, rng, r_inner(), 0.4 + 0.1 * k, true)
	Sfx.play("pull_wave", 0.05, -6.0 + 4.0 * k)


func _rend() -> void:
	var targets := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and not e.dormant and not e.rending and e != held and e.global_position.distance_to(global_position) < REND_RANGE:
			targets.append(e)
	if targets.is_empty():
		return
	targets.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	cooldowns.rend = REND_CD
	_cast_t = 0.5
	Sfx.play("rend", 0.05, -2.0)
	for i in mini(REND_TARGETS, targets.size()):
		targets[i].rend(REND_LIFT_TIME + 0.07 * i, REND_DMG)


func _singularity() -> void:
	mana -= SING_COST
	singularity_t = SING_TIME
	cooldowns.singularity = SING_CD
	_cast_t = 0.5
	Sfx.play("singularity", 0.0, 0.0)
	Fx.shake(4.0)
	_sing_smoke = Fx.ground_smoke(self, r_inner())


func _jump(k: float) -> void:
	jump_charge = -1.0
	squash = 0.0
	vz = lerpf(JUMP_VZ.x, JUMP_VZ.y, k)
	z = 0.5
	cooldowns.jump = 0.2
	velocity *= 1.15
	Sfx.play("jump", 0.08, -6.0)
	Fx.burst(global_position, Color(0.6, 0.58, 0.66), 6, 40.0, 1.0)


func _land() -> void:
	var main = Fx.world.get_meta("main")
	if main.level and not main.level.open_at(global_position):
		var spot: Vector2 = main.level.nearest_open(global_position)
		var t := create_tween()
		t.tween_property(self, "global_position", spot, 0.12)
	Sfx.play("land", 0.08, -8.0)
	Fx.burst(global_position, Color(0.6, 0.58, 0.66), 8, 45.0, 1.0)
	squash = 0.2


func _teleport(dir: Vector2) -> void:
	var from := global_position
	var to := from + dir * SNAP_DIST
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1 | 8
	var step := 0.0
	while step < SNAP_DIST:
		q.transform = Transform2D(0, from.lerp(to, 1.0 - step / SNAP_DIST))
		if space.intersect_shape(q, 1).is_empty():
			break
		step += 4.0
	if step >= SNAP_DIST:
		return
	to = from.lerp(to, 1.0 - step / SNAP_DIST)
	cooldowns.snap = SNAP_CD
	_iframes = 0.3
	send_charge = -1.0
	draw_charge = -1.0
	Fx.implode(from)
	global_position = to
	velocity = dir * SPEED * 0.5
	reset_physics_interpolation()
	Fx.displace(to, self)
	Sfx.play("snap_click", 0.05, -12.0)
	visual.scale = Vector2(0.5, 1.4)
	var t := create_tween()
	t.tween_property(visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------- field ----------
func field_scale() -> float:
	return _field_k


func r_inner() -> float:
	return R_INNER * _field_k


func r_mid() -> float:
	return R_MID * _field_k


func r_outer() -> float:
	return R_OUTER * _field_k


func field_dist(p: Vector2) -> float:
	var d := p - global_position
	return Vector2(d.x, d.y / ELLIPSE).length()


func field_depth(p: Vector2) -> float:
	return field_dist(p) / r_outer()


func _mode_color() -> Color:
	return LIFT_COLOR if mode == Mode.LIFT else CRUSH_COLOR


# ---------- damage ----------
func take_damage(amount: float, from: Vector2) -> void:
	if dead or _iframes > 0.0:
		return
	hp -= amount
	flash = 1.0
	_hurt_t = 0.25
	_iframes = 0.5
	velocity += (global_position - from).normalized() * 140.0
	Fx.number(global_position, amount, Color(1.0, 0.35, 0.35))
	Fx.shake(3.0)
	Sfx.play("witch_hurt", 0.1, -2.0)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		send_charge = -1.0
		draw_charge = -1.0
		if held:
			held.drop()
			held = null
		play("death", true)
		glow.energy = 0.1


func gain_mana(amount: float) -> void:
	mana = minf(100.0, mana + amount)
