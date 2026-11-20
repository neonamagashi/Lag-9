class_name Witch
extends Actor

enum Mode { CRUSH, LIFT }

const SHEET := "res://assets/witch/B_witch_%s.png"
const CRUSH_COLOR := Color(0.55, 0.42, 1.0)
const LIFT_COLOR := Color(1.0, 0.82, 0.4)
const ELLIPSE := 0.6

# ---------- tuning ----------
const SPEED := 118.0
const ACCEL := 1100.0
const BODY_H := 37.0
const R_INNER := BODY_H * 0.5
const R_MID := BODY_H * 1.5
const R_OUTER := BODY_H * 4.0
const PIERCE_CD := 0.3
const PIERCE_DMG := 14.0
const SEND_CD := 1.4
const SEND_MAX_CHARGE := 0.8
const SEND_RANGE := 95.0
const SEND_CONE := 80.0
const DRAW_CD := 1.4
const DRAW_RANGE := 150.0
const DRAW_CONE := 100.0
const REND_CD := 7.0
const REND_TARGETS := 3
const REND_RANGE := 190.0
const REND_DMG := 120.0
const REND_LIFT_TIME := 0.55
const SNAP_CD := 0.9
const SNAP_DIST := 96.0
const SING_CD := 25.0
const SING_COST := 60.0
const SING_TIME := 6.0
const SING_RADIUS := 2.4
const WHISKY_HEAL := 35.0

var mode := Mode.CRUSH
var mana := 60.0
var whisky := 3
var cooldowns := {"pierce": 0.0, "send": 0.0, "draw": 0.0, "rend": 0.0, "snap": 0.0, "singularity": 0.0}
var send_charge := -1.0
var singularity_t := 0.0
var dead := false
var aim := Vector2.RIGHT
var aim_point: Variant = null
var _cast_t := 0.0
var _hurt_t := 0.0
var _iframes := 0.0
var _field_k := 1.0
var _back := false
var field: Node2D
var glow: PointLight2D


func _ready() -> void:
	hp = 100.0
	max_hp = 100.0
	draw_shadow = false
	collision_layer = 0
	collision_mask = 1
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	col.shape = c
	add_child(col)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	Sheets.add(sf, "idle", SHEET % "idle", 32, 48, 6, 8.0, true, true)
	Sheets.add(sf, "run", SHEET % "run", 32, 48, 8, 12.0, true, true)
	Sheets.add(sf, "cast", SHEET % "cast", 60, 46, 5, 20.0, false, true)
	Sheets.add(sf, "charge", SHEET % "charge", 48, 48, 5, 10.0, true, true)
	Sheets.add(sf, "hurt", SHEET % "take_damage", 32, 48, 3, 12.0, false, true)
	Sheets.add(sf, "death", SHEET % "death", 32, 48, 10, 10.0, false, true)
	Sheets.add(sf, "idle_back", SHEET % "idle_back", 32, 48, 6, 8.0, true, true)
	Sheets.add(sf, "run_back", SHEET % "run_back", 32, 48, 8, 12.0, true, true)
	Sheets.add(sf, "charge_back", SHEET % "charge_back", 48, 48, 5, 10.0, true, true)
	Sheets.add(sf, "hurt_back", SHEET % "take_damage_back", 32, 48, 3, 12.0, false, true)
	anchors = {
		"idle_back": Vector3(15, 42, 32), "run_back": Vector3(15, 42, 32), "charge_back": Vector3(23, 44, 48), "hurt_back": Vector3(15, 42, 32),
		"idle": Vector3(15, 42, 32), "run": Vector3(15, 42, 32), "cast": Vector3(18.5, 43, 60),
		"charge": Vector3(23, 44, 48), "hurt": Vector3(15, 42, 32), "death": Vector3(15, 42, 32),
	}
	_build_visual(sf)
	play("idle")
	var gf := GravityField.new()
	gf.witch = self
	field = gf
	add_child(field)
	glow = Fx.light(self, Color(0.55, 0.85, 0.9), 1.8, 0.45)
	glow.position = Vector2(0, -20)


# ---------- input & movement ----------
func _physics_process(delta: float) -> void:
	for k in cooldowns:
		cooldowns[k] = maxf(0.0, cooldowns[k] - delta)
	_cast_t -= delta
	_hurt_t -= delta
	_iframes -= delta
	if singularity_t > 0.0:
		var before := singularity_t
		singularity_t -= delta
		if fmod(before, 1.5) < fmod(singularity_t, 1.5) and singularity_t > 0.5:
			Fx.anim("vortex", global_position, 2.2, Color(0.85, 0.8, 1.0, 0.3), 0.0, 0.6, -1)
		if singularity_t <= 0.0:
			Sfx.play("flip_crush", 0.0, -6.0)
	_field_k = lerpf(_field_k, SING_RADIUS if singularity_t > 0.0 else 1.0, 1.0 - exp(-delta * 6.0))
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		move_and_slide()
		_update_visual(delta)
		return
	var target: Vector2 = aim_point if aim_point != null else get_global_mouse_position()
	aim = (target - global_position + Vector2(0, 16)).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT * facing
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var spd := SPEED * (0.45 if send_charge >= 0.0 else 1.0)
	velocity = velocity.move_toward(dir * spd, ACCEL * delta)
	move_and_slide()
	_abilities(delta, dir)
	_animate(dir)
	_update_visual(delta)


func _abilities(delta: float, dir: Vector2) -> void:
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
	if Input.is_action_pressed("pierce") and cooldowns.pierce <= 0.0 and send_charge < 0.0:
		_pierce()
	if Input.is_action_just_pressed("send") and cooldowns.send <= 0.0:
		send_charge = 0.0
	if send_charge >= 0.0:
		send_charge = minf(send_charge + delta, SEND_MAX_CHARGE)
		if not Input.is_action_pressed("send"):
			_send(send_charge / SEND_MAX_CHARGE)
			send_charge = -1.0
	if Input.is_action_just_pressed("draw") and cooldowns.draw <= 0.0:
		_draw_in()
	if Input.is_action_just_pressed("rend") and cooldowns.rend <= 0.0:
		_rend()
	if Input.is_action_just_pressed("singularity") and cooldowns.singularity <= 0.0 and mana >= SING_COST:
		mana -= SING_COST
		singularity_t = SING_TIME
		cooldowns.singularity = SING_CD
		_cast_t = 0.5
		Sfx.play("singularity", 0.0, 0.0)
		Fx.shake(4.0)
		Fx.anim("vortex", global_position, 3.2, Color(0.85, 0.8, 1.0, 0.45), 0.0, 0.6, -1)
	if Input.is_action_just_pressed("whisky") and whisky > 0 and hp < max_hp:
		whisky -= 1
		hp = minf(max_hp, hp + WHISKY_HEAL)
		Sfx.play("whisky", 0.0, -2.0)
		Fx.anim("heal", global_position, 1.0, Color.WHITE, 18.0)
		Fx.text(global_position, "+%d" % WHISKY_HEAL, Color(0.6, 1.0, 0.6))


func _animate(dir: Vector2) -> void:
	var casting := _cast_t > 0.0 or send_charge >= 0.0 or Input.is_action_pressed("pierce")
	if casting:
		if absf(aim.x) > 0.2:
			facing = 1 if aim.x > 0 else -1
		_back = aim.y < -0.5
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
	elif send_charge >= 0.0 or (singularity_t > SING_TIME - 0.6):
		anim = "charge"
	elif _cast_t > 0.0:
		anim = "idle" if _back else "cast"
	elif velocity.length() > 12.0:
		anim = "run"
	play(anim + "_back" if _back and sprite.sprite_frames.has_animation(anim + "_back") else anim)


# ---------- abilities ----------
func _pierce() -> void:
	cooldowns.pierce = PIERCE_CD
	_cast_t = 0.22
	play("cast", true)
	var p := Projectile.new()
	p.setup(global_position + aim * 12.0, aim, PIERCE_DMG)
	get_parent().add_child(p)
	Fx.anim("spark", global_position + aim * 12.0, 0.8, Color.WHITE, 16.0)
	Sfx.play("pierce", 0.1, -8.0)


func _cone_targets(rng: float, cone: float) -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() < rng and (to.length() < 14.0 or rad_to_deg(absf(aim.angle_to(to))) < cone * 0.5):
			out.append(e)
	return out


func _send(k: float) -> void:
	cooldowns.send = SEND_CD
	_cast_t = 0.25
	play("cast", true)
	var rng := SEND_RANGE * (0.8 + 0.4 * k)
	for e in _cone_targets(rng, SEND_CONE):
		var to: Vector2 = e.global_position - global_position
		e.knock(to.normalized() if to.length() > 1.0 else aim, lerpf(170.0, 400.0, k), lerpf(6.0, 20.0, k))
	_cone_fx(rng, SEND_CONE, Color(0.7, 0.6, 1.0))
	Fx.anim("nova", global_position + aim * 18.0, 1.3 + 0.8 * k, Color(0.8, 0.72, 1.0), 0.0, 0.8, -1)
	Sfx.play("send", 0.05, -4.0 + 4.0 * k)
	Fx.shake(1.5 + 2.5 * k)


func _draw_in() -> void:
	cooldowns.draw = DRAW_CD
	_cast_t = 0.25
	play("cast", true)
	for e in _cone_targets(DRAW_RANGE, DRAW_CONE):
		var to: Vector2 = global_position - e.global_position
		var pull := clampf(to.length() * 2.6, 120.0, 360.0)
		e.knock(to.normalized(), pull, 3.0, true)
	_cone_fx(DRAW_RANGE, DRAW_CONE, Color(0.5, 0.95, 0.9))
	Fx.anim("blades_in", global_position, 1.6, Color(0.75, 1.0, 1.0), 14.0)
	Sfx.play("draw", 0.05, -4.0)


func _rend() -> void:
	var targets := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and not e.dormant and not e.rending and e.global_position.distance_to(global_position) < REND_RANGE:
			targets.append(e)
	if targets.is_empty():
		return
	targets.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	cooldowns.rend = REND_CD
	_cast_t = 0.45
	play("charge", true)
	Sfx.play("rend", 0.05, -2.0)
	for i in mini(REND_TARGETS, targets.size()):
		targets[i].rend(REND_LIFT_TIME + 0.07 * i, REND_DMG)


func _teleport(dir: Vector2) -> void:
	var from := global_position
	var to := from + dir * SNAP_DIST
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1
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
	Fx.black_hole(from, 0.55)
	global_position = to
	velocity = dir * SPEED * 0.5
	reset_physics_interpolation()
	Fx.black_hole(to, 1.4)
	Fx.shake(1.5)
	Sfx.play("snap", 0.06, -3.0)
	visual.scale = Vector2(0.4, 1.6)
	var t := create_tween()
	t.tween_property(visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _cone_fx(rng: float, cone: float, color: Color) -> void:
	var n := Node2D.new()
	n.position = global_position
	n.z_index = -1
	var state := {"a": 0.9}
	var base := aim.angle()
	n.draw.connect(func():
		var pts := PackedVector2Array([Vector2.ZERO])
		for i in 13:
			var a := base + deg_to_rad(-cone * 0.5 + cone * i / 12.0)
			pts.append(Vector2(cos(a), sin(a) * ELLIPSE) * rng)
		n.draw_colored_polygon(pts, Color(color, 0.18 * state.a))
		n.draw_polyline(pts.slice(1), Color(color, 0.8 * state.a), 1.0))
	get_parent().add_child(n)
	var tw := n.create_tween()
	tw.tween_method(func(v: float):
		state.a = 1.0 - v
		n.queue_redraw(), 0.0, 1.0, 0.25)
	tw.tween_callback(n.queue_free)


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
	if dead:
		return
	if _iframes > 0.0:
		return
	hp -= amount
	flash = 1.0
	_hurt_t = 0.25
	_iframes = 0.5
	velocity += (global_position - from).normalized() * 140.0
	Fx.number(global_position, amount, Color(1.0, 0.45, 0.45))
	Fx.shake(3.0)
	Sfx.play("witch_hurt", 0.1, -2.0)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		send_charge = -1.0
		play("death", true)
		glow.energy = 0.3


func gain_mana(amount: float) -> void:
	mana = minf(100.0, mana + amount)
