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
const FIELD_RADIUS := 56.0
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
const REND_TARGETS := 5
const REND_RANGE := 170.0
const REND_DMG := 70.0
const SNAP_CD := 0.8
const SNAP_DIST := 84.0
const SNAP_TIME := 0.12
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
var _snap_t := 0.0
var _snap_dir := Vector2.ZERO
var _field_r := FIELD_RADIUS
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
	Sheets.add(sf, "cast", SHEET % "attack", 104, 46, 5, 20.0, false, true, Rect2i(0, 0, 40, 46))
	Sheets.add(sf, "charge", SHEET % "charge", 48, 48, 5, 10.0, true, true)
	Sheets.add(sf, "hurt", SHEET % "take_damage", 32, 48, 3, 12.0, false, true)
	Sheets.add(sf, "death", SHEET % "death", 32, 48, 10, 10.0, false, true)
	Sheets.add(sf, "idle_back", SHEET % "idle_back", 32, 48, 6, 8.0, true, true)
	Sheets.add(sf, "run_back", SHEET % "run_back", 32, 48, 8, 12.0, true, true)
	Sheets.add(sf, "charge_back", SHEET % "charge_back", 48, 48, 5, 10.0, true, true)
	Sheets.add(sf, "hurt_back", SHEET % "take_damage_back", 32, 48, 3, 12.0, false, true)
	anchors = {
		"idle_back": Vector3(15, 42, 32), "run_back": Vector3(15, 42, 32), "charge_back": Vector3(23, 44, 48), "hurt_back": Vector3(15, 42, 32),
		"idle": Vector3(15, 42, 32), "run": Vector3(15, 42, 32), "cast": Vector3(18.5, 43, 40),
		"charge": Vector3(23, 44, 48), "hurt": Vector3(15, 42, 32), "death": Vector3(15, 42, 32),
	}
	_build_visual(sf)
	play("idle")
	field = Node2D.new()
	field.z_index = -2
	field.draw.connect(_draw_field)
	add_child(field)
	glow = Fx.light(self, Color(0.5, 0.92, 0.88), 2.2, 1.0)
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
	var target_r := FIELD_RADIUS * (SING_RADIUS if singularity_t > 0.0 else 1.0)
	_field_r = lerpf(_field_r, target_r, 1.0 - exp(-delta * 6.0))
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		move_and_slide()
		_update_visual(delta)
		field.queue_redraw()
		return
	var target: Vector2 = aim_point if aim_point != null else get_global_mouse_position()
	aim = (target - global_position + Vector2(0, 16)).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT * facing
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _snap_t > 0.0:
		_snap_t -= delta
		velocity = _snap_dir * SNAP_DIST / SNAP_TIME
		if Engine.get_physics_frames() % 2 == 0:
			Fx.ghost(self)
	else:
		var spd := SPEED * (0.45 if send_charge >= 0.0 else 1.0)
		velocity = velocity.move_toward(dir * spd, ACCEL * delta)
	move_and_slide()
	_abilities(delta, dir)
	_animate(dir)
	_update_visual(delta)
	field.queue_redraw()


func _abilities(delta: float, dir: Vector2) -> void:
	if Input.is_action_just_pressed("flip"):
		mode = Mode.LIFT if mode == Mode.CRUSH else Mode.CRUSH
		Sfx.play("flip_lift" if mode == Mode.LIFT else "flip_crush", 0.03, -2.0)
		Fx.ring(global_position, _mode_color(), _field_r * 1.1, 0.3)
		if mode == Mode.CRUSH:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.lifted and _in_field(e.global_position):
					e.slam()
	if Input.is_action_just_pressed("snap") and cooldowns.snap <= 0.0:
		_snap_dir = dir.normalized() if dir.length() > 0.1 else aim
		_snap_t = SNAP_TIME
		_iframes = SNAP_TIME + 0.12
		cooldowns.snap = SNAP_CD
		send_charge = -1.0
		Sfx.play("snap", 0.06, -3.0)
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
	p.setup(global_position + aim * 10.0, aim, PIERCE_DMG)
	get_parent().add_child(p)
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
		if not e.dead and e.global_position.distance_to(global_position) < REND_RANGE:
			targets.append(e)
	if targets.is_empty():
		return
	targets.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	cooldowns.rend = REND_CD
	_cast_t = 0.35
	play("cast", true)
	Sfx.play("rend", 0.05, -2.0)
	for i in mini(REND_TARGETS, targets.size()):
		var e: Enemy = targets[i]
		var t := get_tree().create_timer(0.08 * i + 0.1)
		t.timeout.connect(func():
			if is_instance_valid(e) and not e.dead:
				Fx.spikes(e.global_position)
				e.vz = 160.0
				e.hit(REND_DMG, (e.global_position - global_position).normalized() * 40.0)
				Fx.shake(2.0))


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
func field_radius() -> float:
	return _field_r


func field_depth(p: Vector2) -> float:
	var d := p - global_position
	return Vector2(d.x, d.y / ELLIPSE).length() / _field_r


func _in_field(p: Vector2) -> bool:
	return field_depth(p) < 1.0


func _mode_color() -> Color:
	return LIFT_COLOR if mode == Mode.LIFT else CRUSH_COLOR


func _draw_field() -> void:
	if dead:
		return
	var c := _mode_color()
	var r := _field_r
	var t := Time.get_ticks_msec() / 1000.0
	var fill := PackedVector2Array()
	for i in 48:
		var a := i / 48.0 * TAU
		fill.append(Vector2(cos(a) * r, sin(a) * r * ELLIPSE))
	field.draw_colored_polygon(fill, Color(c, 0.07 if singularity_t <= 0.0 else 0.13))
	var segs := 24
	for i in segs:
		if i % 2 == 1:
			continue
		var a0 := i / float(segs) * TAU + t * (0.6 if mode == Mode.CRUSH else -0.6)
		var a1 := a0 + TAU / segs
		var pts := PackedVector2Array()
		for k in 5:
			var a := lerpf(a0, a1, k / 4.0)
			pts.append(Vector2(cos(a) * r, sin(a) * r * ELLIPSE))
		field.draw_polyline(pts, Color(c, 0.75), 1.0)
	var inner := r * 0.45
	var pts2 := PackedVector2Array()
	for i in 33:
		var a := i / 32.0 * TAU
		pts2.append(Vector2(cos(a) * inner, sin(a) * inner * ELLIPSE))
	field.draw_polyline(pts2, Color(c, 0.25), 1.0)


# ---------- damage ----------
func take_damage(amount: float, from: Vector2) -> void:
	if dead:
		return
	if _iframes > 0.0:
		if _snap_t > 0.0:
			Fx.text(global_position, "dodge", Color(0.6, 1.0, 0.95))
			Sfx.play("dodge", 0.05, -6.0)
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
