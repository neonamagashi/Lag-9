class_name Witch
extends CharacterBody3D

signal hp_changed(hp: float, max_hp: float)
signal toast(text: String)

enum FieldMode { CRUSH, LIFT }

const MODEL_PATH := "res://models/witch.glb"
const RIGGED_PATH := "res://models/witch_rigged.glb"
const HAIR_CHAINS := [
	["Hair_Back_1", "Hair_Back_4"],
	["Hair_BackL_1", "Hair_BackL_4"],
	["Hair_BackR_1", "Hair_BackR_4"],
	["Hair_FrontL_1", "Hair_FrontL_3"],
	["Hair_FrontR_1", "Hair_FrontR_3"],
]
const BODY_SHADER := preload("res://shaders/witch_body.gdshader")
const AURA_SHADER := preload("res://shaders/witch_aura.gdshader")
const STAFF_SHADER := preload("res://shaders/staff.gdshader")
const STAFF_PATH := "res://models/staff.glb"
const STONE_LOCAL := Vector3(0, 0.354, 0)
const CRUSH_COLOR := Color(0.62, 0.42, 1.0)
const LIFT_COLOR := Color(0.36, 0.85, 1.0)
const GOLD := Color(1.0, 0.78, 0.25)
const MANA_COLOR := Color(0.35, 0.75, 1.0)

var rig: CameraRig
var field_on := true
var field_mode := FieldMode.CRUSH
var hp := 100.0
var mana := 0.0
var whisky := 3
var flying := false
var spawn_point := Vector3.ZERO

var pierce_cd := 0.0
var snap_cd := 0.0
var send_cd := 0.0
var draw_cd := 0.0
var rend_cd := 0.0
var singularity_cd := 0.0
var singularity_t := 0.0
var send_charge := -1.0
var draw_charge := -1.0

var _model: Node3D
var _staff: Node3D
var _staff_tip: Node3D
var _staff_body: Node3D
var _staff_light: OmniLight3D
var _staff_glow: Sprite3D
var _staff_mats: Array[ShaderMaterial] = []
var _staff_len := 1.0
var _aura_mats: Array[StandardMaterial3D] = []
var _body_mats: Array[ShaderMaterial] = []
var _aura_shader_mats: Array[ShaderMaterial] = []
var _sway := Vector3.ZERO
var _rigged := false
var _skeleton: Skeleton3D
var _hair_sim: SpringBoneSimulator3D
var _skel_unit := 1.0
var _hair_state := []
var _sway_vel := Vector3.ZERO
var _prev_vel := Vector3.ZERO
var _field_root: Node3D
var _field_spinner: Node3D
var _field_fill: StandardMaterial3D
var _field_edge: StandardMaterial3D
var _field_particles: GPUParticles3D
var _field_process: ParticleProcessMaterial
var _field_dot: StandardMaterial3D
var _field_scale := 1.0

var _coyote := 0.0
var _jump_buffer := 0.0
var _air_jump_used := false
var _charging := false
var _charge_t := 0.0
var _charge_released := false
var _last_jump_press := -10.0
var _snap_time := 0.0
var _snap_vel := Vector3.ZERO
var _clamber_t := -1.0
var _clamber_from := Vector3.ZERO
var _clamber_to := Vector3.ZERO
var _invuln := 0.0
var _face_cam := 0.0
var _hurt_flash := 0.0
var _contact_accum := 0.0
var _ghost_t := 0.0
var _charge_sound: AudioStreamPlayer
var _t := 0.0


func _ready() -> void:
	Game.witch = self
	add_to_group("witch")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.3
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	_build_model()
	_build_field()
	spawn_point = global_position
	mana = Game.balance.start_mana
	reset_stats()


func reset_stats() -> void:
	hp = Game.witch_max_hp()
	whisky = Game.balance.whisky_count
	hp_changed.emit(hp, Game.witch_max_hp())


func reset_cooldowns() -> void:
	pierce_cd = 0.0
	snap_cd = 0.0
	send_cd = 0.0
	draw_cd = 0.0
	rend_cd = 0.0
	singularity_cd = 0.0
	mana = Game.balance.max_mana


func is_invulnerable() -> bool:
	return _invuln > 0.0


func field_radius() -> float:
	var b := Game.balance
	if singularity_t > 0.0:
		return b.field_radius * Game.rank_value(b.singularity_radius_mult, b.singularity_rank)
	if flying:
		return b.field_radius * b.flight_field_mult
	return b.field_radius


func field_damage_mult() -> float:
	return Game.rank_value(Game.balance.singularity_damage_mult, Game.balance.singularity_rank) if singularity_t > 0.0 else 1.0


func lift_height() -> float:
	return Game.balance.singularity_lift_height if singularity_t > 0.0 else Game.balance.lift_height


func field_center() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)


func add_mana(amount: float) -> void:
	mana = minf(Game.balance.max_mana, mana + amount)


# ---------- damage ----------
func take_damage(amount: float, kind: String) -> void:
	if _invuln > 0.0:
		if kind != "contact":
			Art.popup(get_parent(), global_position + Vector3(0, 2.2, 0), "DODGED", GOLD, 48)
			Sfx.play("dodge", global_position)
		return
	hp -= amount
	if kind == "contact":
		_contact_accum += amount
		if _contact_accum >= 1.0:
			Art.popup(get_parent(), global_position + Vector3(0, 2.0, 0), str(int(_contact_accum)), Color(1, 0.4, 0.35), 44)
			_contact_accum = 0.0
	else:
		_hurt_flash = 0.15
		Sfx.play("witch_hurt", global_position, 0.1)
		Art.popup(get_parent(), global_position + Vector3(0, 2.0, 0), str(int(amount)), Color(1, 0.35, 0.3), 56)
	hp_changed.emit(hp, Game.witch_max_hp())
	if hp <= 0.0:
		toast.emit("She went down. Back to the start with a fresh bottle.")
		global_position = spawn_point
		velocity = Vector3.ZERO
		flying = false
		reset_physics_interpolation()
		reset_stats()


func drink() -> void:
	if whisky <= 0:
		toast.emit("Out of whisky")
		return
	if hp >= Game.witch_max_hp():
		toast.emit("Already at full health")
		return
	whisky -= 1
	Sfx.play("whisky", global_position)
	var heal := Game.witch_max_hp() * Game.balance.whisky_heal_pct
	hp = minf(Game.witch_max_hp(), hp + heal)
	Art.popup(get_parent(), global_position + Vector3(0, 2.2, 0), "+%d" % int(heal), GOLD, 56)
	hp_changed.emit(hp, Game.witch_max_hp())


# ---------- main loop ----------
func _physics_process(delta: float) -> void:
	var b := Game.balance
	_t += delta
	for cd in ["pierce_cd", "snap_cd", "send_cd", "draw_cd", "rend_cd", "singularity_cd"]:
		set(cd, maxf(0.0, get(cd) - delta))
	_invuln = maxf(0.0, _invuln - delta)
	_face_cam = maxf(0.0, _face_cam - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if singularity_t > 0.0:
		singularity_t -= delta
		if singularity_t <= 0.0:
			_end_singularity()

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := rig.yaw if rig else 0.0
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw)

	_handle_abilities(delta)

	if _clamber_t >= 0.0:
		_process_clamber(delta)
	elif _snap_time > 0.0:
		_process_snap(delta)
	elif Input.is_action_just_pressed("snap") and snap_cd <= 0.0:
		_start_snap(dir)
	elif flying:
		_process_flight(delta, dir)
	else:
		_process_ground(delta, dir)

	if global_position.y < -25.0:
		global_position = spawn_point
		velocity = Vector3.ZERO
		flying = false
		reset_physics_interpolation()

	_update_visuals(delta, dir)


func _process_ground(delta: float, dir: Vector3) -> void:
	var b := Game.balance
	var on_floor := is_on_floor()
	if on_floor:
		_coyote = b.coyote_time
		_air_jump_used = false
	else:
		_coyote -= delta

	var pressed := Input.is_action_just_pressed("jump")
	if pressed:
		if not on_floor and _t - _last_jump_press < b.double_tap_window:
			_last_jump_press = -10.0
			_charging = false
			_stop_charge_sound()
			_start_flight()
			return
		_last_jump_press = _t
		_jump_buffer = b.jump_buffer
	else:
		_jump_buffer -= delta

	if dir.length() > 0.3 and (pressed or (not on_floor and velocity.y < 3.0)):
		if _try_clamber(dir):
			_jump_buffer = 0.0
			return

	if _charging:
		_charge_t += delta
		if Input.is_action_just_released("jump"):
			_charge_released = true
		velocity = velocity.lerp(Vector3.ZERO, minf(1.0, delta * 18.0))
		var full := _charge_t >= b.air_jump_max_charge
		if full or (_charge_released and _charge_t >= b.air_jump_min_charge):
			var k := clampf((_charge_t - b.air_jump_min_charge) / (b.air_jump_max_charge - b.air_jump_min_charge), 0.0, 1.0)
			velocity.y = lerpf(b.air_jump_min_velocity, b.air_jump_max_velocity, k)
			velocity += dir * b.walk_speed * 0.6
			_charging = false
			_stop_charge_sound()
			Sfx.play("jump_release", global_position, 0.05, -2.0 + 4.0 * k)
			var c := CRUSH_COLOR if field_mode == FieldMode.CRUSH else LIFT_COLOR
			Art.burst(get_parent(), global_position + Vector3(0, 0.3, 0), c, int(20 + 30 * k))
			Art.ring_pulse(get_parent(), global_position + Vector3(0, 0.2, 0), c.lerp(GOLD, k), 1.5 + 2.5 * k, 0.35)
		move_and_slide()
		return

	if _jump_buffer > 0.0 and _coyote > 0.0:
		Sfx.play("whiff", global_position, 0.1, -8.0)
		velocity.y = b.jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0
	elif _jump_buffer > 0.0 and not on_floor and not _air_jump_used:
		_air_jump_used = true
		_jump_buffer = 0.0
		_charging = true
		_charge_t = 0.0
		_charge_sound = Sfx.play_held("jump_charge", -6.0)
		_charge_released = not Input.is_action_pressed("jump")

	if not on_floor:
		velocity.y -= b.gravity * delta
		if Input.is_action_just_released("jump") and velocity.y > 0.0:
			velocity.y *= b.jump_cut

	var speed := b.sprint_speed if Input.is_action_pressed("sprint") else b.walk_speed
	var target := dir * speed
	var accel := b.air_accel
	if on_floor:
		accel = b.ground_accel if dir.length() > 0.05 else b.ground_decel
	var hv := Vector3(velocity.x, 0, velocity.z).move_toward(target, accel * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	move_and_slide()


func _stop_charge_sound() -> void:
	if _charge_sound and _charge_sound.stream and _charge_sound.stream.resource_path.ends_with("jump_charge.wav"):
		_charge_sound.stop()
	_charge_sound = null


func _start_flight() -> void:
	Sfx.play("flight_on", global_position)
	flying = true
	velocity.y = maxf(velocity.y, 3.0)
	Art.ring_pulse(get_parent(), global_position + Vector3(0, 0.5, 0), GOLD, 3.0, 0.4)
	toast.emit("Flying  (double-tap jump to drop)")


func _process_flight(delta: float, dir: Vector3) -> void:
	var b := Game.balance
	if Input.is_action_just_pressed("jump"):
		if _t - _last_jump_press < b.double_tap_window:
			flying = false
			_last_jump_press = -10.0
			Sfx.play("whiff", global_position)
			return
		_last_jump_press = _t
	if b.flight_mana_per_sec > 0.0:
		mana -= b.flight_mana_per_sec * delta
		if mana <= 0.0:
			mana = 0.0
			flying = false
			toast.emit("Out of mana")
			return
	var vert := 0.0
	if Input.is_action_pressed("jump"):
		vert += 1.0
	if Input.is_action_pressed("descend"):
		vert -= 1.0
	var speed := b.flight_sprint_speed if Input.is_action_pressed("sprint") else b.flight_speed
	var target := dir * speed + Vector3.UP * vert * b.flight_vertical_speed
	target.y += sin(_t * 2.0) * 0.3
	velocity = velocity.move_toward(target, b.flight_accel * delta)
	move_and_slide()
	if is_on_floor() and vert < 0.0:
		flying = false


func _try_clamber(dir: Vector3) -> bool:
	var b := Game.balance
	var space := get_world_3d().direct_space_state
	var fwd := Vector3(dir.x, 0, dir.z).normalized()
	var chest := global_position + Vector3(0, 0.9, 0)
	var q := PhysicsRayQueryParameters3D.create(chest, chest + fwd * b.clamber_reach, 1)
	q.exclude = [get_rid()]
	var wall := space.intersect_ray(q)
	if wall.is_empty():
		var shin := global_position + Vector3(0, 0.3, 0)
		q = PhysicsRayQueryParameters3D.create(shin, shin + fwd * b.clamber_reach, 1)
		q.exclude = [get_rid()]
		wall = space.intersect_ray(q)
		if wall.is_empty():
			return false
	if absf(wall.normal.y) > 0.5:
		return false
	var probe_xz: Vector3 = wall.position + fwd * 0.45
	var top := Vector3(probe_xz.x, global_position.y + b.clamber_max_height + 0.1, probe_xz.z)
	var bottom := Vector3(probe_xz.x, global_position.y + 0.45, probe_xz.z)
	q = PhysicsRayQueryParameters3D.create(top, bottom, 1)
	q.exclude = [get_rid()]
	var ledge := space.intersect_ray(q)
	if ledge.is_empty() or ledge.normal.y < 0.7:
		return false
	var land: Vector3 = ledge.position + Vector3(0, 0.05, 0)
	q = PhysicsRayQueryParameters3D.create(land + Vector3(0, 0.1, 0), land + Vector3(0, 1.9, 0), 1)
	q.exclude = [get_rid()]
	if not space.intersect_ray(q).is_empty():
		return false
	_clamber_from = global_position
	_clamber_to = land
	_clamber_t = 0.0
	_charging = false
	_stop_charge_sound()
	Sfx.play("whiff", global_position, 0.1, -4.0)
	velocity = Vector3.ZERO
	return true


func _process_clamber(delta: float) -> void:
	var b := Game.balance
	_clamber_t += delta / b.clamber_time
	var k := clampf(_clamber_t, 0.0, 1.0)
	var rise := clampf(k / 0.6, 0.0, 1.0)
	var push := clampf((k - 0.45) / 0.55, 0.0, 1.0)
	var y := lerpf(_clamber_from.y, _clamber_to.y, ease(rise, 0.5))
	var xz := Vector2(_clamber_from.x, _clamber_from.z).lerp(Vector2(_clamber_to.x, _clamber_to.z), ease(push, 0.6))
	global_position = Vector3(xz.x, y, xz.y)
	if _clamber_t >= 1.0:
		_clamber_t = -1.0
		var fwd := (_clamber_to - _clamber_from) * Vector3(1, 0, 1)
		velocity = fwd.normalized() * Game.balance.walk_speed * 0.5 if fwd.length() > 0.01 else Vector3.ZERO


func _start_snap(dir: Vector3) -> void:
	var b := Game.balance
	var r := b.snap_rank
	var d := dir if dir.length() > 0.1 else _model.global_basis.z
	d.y = 0.0
	d = d.normalized()
	var dur: float = Game.rank_value(b.snap_duration, r)
	var dist: float = Game.rank_value(b.snap_distance, r)
	_snap_vel = d * (dist / dur)
	_snap_time = dur
	_invuln = dur + b.snap_iframe_padding
	snap_cd = b.snap_cooldown
	_charging = false
	_stop_charge_sound()
	Sfx.play("snap", global_position, 0.06)
	var from := global_position + Vector3(0, 1.0, 0)
	var width := 0.9 - clampi(r, 0, 2) * 0.38
	Art.streak(get_parent(), from, from + d * dist, CRUSH_COLOR.lerp(GOLD, 0.35), width, 0.25 + r * 0.05)
	Art.ghost(_model, get_parent(), GOLD, 0.5, 0.3)


func _process_snap(delta: float) -> void:
	_snap_time -= delta
	velocity = _snap_vel
	move_and_slide()
	if _snap_time <= 0.0:
		velocity = _snap_vel.normalized() * Game.balance.sprint_speed
		velocity.y = 0.0
		Art.ghost(_model, get_parent(), GOLD, 0.35, 0.25)


# ---------- abilities ----------
func _handle_abilities(delta: float) -> void:
	var b := Game.balance
	if Input.is_action_just_pressed("flip_gravity"):
		field_mode = FieldMode.LIFT if field_mode == FieldMode.CRUSH else FieldMode.CRUSH
		Sfx.play("flip_crush" if field_mode == FieldMode.CRUSH else "flip_lift", global_position, 0.03)
		_apply_field_look()
	if Input.is_action_just_pressed("toggle_field"):
		if singularity_t > 0.0:
			toast.emit("Can't drop the field during Singularity")
		else:
			field_on = not field_on
			Sfx.play("flip_crush" if field_on else "whiff", global_position, 0.03, -3.0)
			toast.emit("Gravity field %s" % ("on" if field_on else "off"))
	if Input.is_action_pressed("pierce") and pierce_cd <= 0.0:
		_pierce()
	if Input.is_action_just_pressed("drink_whisky"):
		drink()

	if Input.is_action_just_pressed("send") and send_cd <= 0.0:
		send_charge = 0.0
	if send_charge >= 0.0:
		send_charge = minf(b.send_max_charge, send_charge + delta)
		if Input.is_action_just_released("send") or not Input.is_action_pressed("send"):
			_fire_push(true, send_charge / b.send_max_charge)
			send_charge = -1.0

	if Input.is_action_just_pressed("draw") and draw_cd <= 0.0:
		draw_charge = 0.0
	if draw_charge >= 0.0:
		draw_charge = minf(b.draw_max_charge, draw_charge + delta)
		if Input.is_action_just_released("draw") or not Input.is_action_pressed("draw"):
			_fire_push(false, draw_charge / b.draw_max_charge)
			draw_charge = -1.0

	if Input.is_action_just_pressed("rend"):
		if rend_cd > 0.0:
			toast.emit("Rend ready in %ds" % ceili(rend_cd))
		else:
			_rend()

	if Input.is_action_just_pressed("singularity"):
		if singularity_t > 0.0:
			pass
		elif singularity_cd > 0.0:
			toast.emit("Singularity ready in %ds" % ceili(singularity_cd))
		elif mana < b.singularity_mana_cost:
			toast.emit("Singularity needs %d mana" % int(b.singularity_mana_cost))
		else:
			_start_singularity()


func _aim_flat() -> Vector3:
	var f := rig.forward() if rig else -global_basis.z
	f.y = 0.0
	return f.normalized()


func _fire_push(outward: bool, charge: float) -> void:
	var b := Game.balance
	var rank: int = b.send_rank if outward else b.draw_rank
	var reach: float = Game.rank_value(b.send_range if outward else b.draw_range, rank)
	var fmax: float = Game.rank_value(b.send_force_max if outward else b.draw_force_max, rank)
	var fmin: float = b.send_force_min if outward else b.draw_force_min
	var half := deg_to_rad((b.send_cone_deg if outward else b.draw_cone_deg) * 0.5)
	var all_dirs := rank >= 1
	var force := lerpf(fmin, fmax, charge)
	var stagger := charge < 0.15
	var aim := _aim_flat()
	_face_cam = 0.5
	if outward:
		send_cd = b.send_cooldown
	else:
		draw_cd = b.draw_cooldown
	var color := Color(1.0, 0.65, 0.35) if outward else Color(0.5, 0.85, 1.0)
	Sfx.play("send" if outward else "draw", global_position, 0.05, -4.0 + 4.0 * charge)
	var origin := global_position + Vector3(0, 1.0, 0)
	if all_dirs:
		Art.ring_pulse(get_parent(), global_position + Vector3(0, 0.6, 0), color, reach if outward else reach * 0.6, 0.35)
	else:
		Art.cone_flash(get_parent(), origin, aim, reach, half, color, not outward)
	var hit := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Enemy) or e.is_dead():
			continue
		var to: Vector3 = e.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d > reach or d < 0.01:
			continue
		if not all_dirs and to.normalized().angle_to(aim) > half:
			continue
		var falloff := 1.0 - (d / reach) * 0.4
		var push_dir := to.normalized() if outward else -to.normalized()
		var f := force * falloff
		if not outward:
			f = minf(f, d * 3.2 + 4.0)
		e.knock(push_dir * f, b.stagger_time if stagger else 0.25)
		if outward:
			e.take_damage(Game.scaled_damage(b.send_base_damage, e.level) * (0.5 + 0.5 * charge), "send")
		hit += 1
	if stagger and hit > 0:
		toast.emit("Stagger")


func _rend() -> void:
	var b := Game.balance
	var count: int = Game.rank_value(b.rend_targets, b.rend_rank)
	var shards := b.rend_rank >= b.rend_targets.size() - 1
	var targets: Array[Enemy] = []
	var aimed := _aimed_enemy(b.rend_range)
	if aimed:
		targets.append(aimed)
	var aim_point := aimed.global_position if aimed else global_position + _aim_flat() * 8.0
	var pool: Array = get_tree().get_nodes_in_group("enemies").filter(func(e): return e is Enemy and not e.is_dead() and not targets.has(e) and e.global_position.distance_to(global_position) <= b.rend_range)
	pool.sort_custom(func(a, c): return a.global_position.distance_to(aim_point) < c.global_position.distance_to(aim_point))
	for e in pool:
		if targets.size() >= count:
			break
		targets.append(e)
	if targets.is_empty():
		toast.emit("No target in range")
		return
	rend_cd = b.rend_cooldown
	_face_cam = 0.6
	Sfx.play("rend", global_position, 0.05)
	for e in targets:
		e.rend_start(b.rend_hold_time, field_mode == FieldMode.LIFT, shards)
		Art.streak(get_parent(), _staff_tip.global_position, e.global_position + Vector3(0, 0.6, 0), Color(0.75, 0.4, 1.0), 0.08, b.rend_hold_time)


func _start_singularity() -> void:
	var b := Game.balance
	mana -= b.singularity_mana_cost
	singularity_t = b.singularity_duration
	singularity_cd = b.singularity_cooldown
	field_on = true
	Sfx.play("singularity", global_position, 0.0, 2.0)
	Game.enemy_time_scale = b.singularity_time_scale
	if Game.env:
		Game.env.adjustment_enabled = true
		Game.env.adjustment_saturation = 0.35
		Game.env.adjustment_contrast = 1.15
	Art.ring_pulse(get_parent(), global_position + Vector3(0, 0.8, 0), Color(0.1, 0.0, 0.2), field_radius(), 0.6)
	Art.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(0.8, 0.6, 1.0), 60)
	toast.emit("SINGULARITY")


func _end_singularity() -> void:
	singularity_t = 0.0
	Game.enemy_time_scale = 1.0
	if Game.env:
		Game.env.adjustment_enabled = false


func _aimed_enemy(reach: float) -> Enemy:
	var cam := rig.camera
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := cam.project_ray_origin(center)
	var ray_dir := cam.project_ray_normal(center)
	var q := PhysicsRayQueryParameters3D.create(origin, origin + ray_dir * (reach + rig.arm.spring_length), 1 | 4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit and hit.collider is Enemy:
		return hit.collider
	return null


func _pierce() -> void:
	var b := Game.balance
	pierce_cd = b.pierce_cooldown
	_face_cam = 0.6
	var cam := rig.camera
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := cam.project_ray_origin(center)
	var ray_dir := cam.project_ray_normal(center)
	var reach: float = Game.rank_value(b.pierce_range, b.pierce_rank) + rig.arm.spring_length
	var q := PhysicsRayQueryParameters3D.create(origin, origin + ray_dir * reach, 1 | 4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end: Vector3 = hit.position if hit else origin + ray_dir * reach
	if hit and hit.collider is Enemy:
		var e: Enemy = hit.collider
		e.take_damage(Game.scaled_damage(Game.rank_value(b.pierce_base_damage, b.pierce_rank), e.level), "pierce")
	Art.streak(get_parent(), _staff_tip.global_position, end, Color(0.85, 0.7, 1.0), 0.06, 0.12)
	Sfx.play("pierce", _staff_tip.global_position, 0.1, -5.0)


# ---------- visuals ----------
func _update_visuals(delta: float, dir: Vector3) -> void:
	var b := Game.balance
	var bob := sin(_t * 2.2) * 0.12
	_model.position.y = b.hover_height + bob
	var face := _model.rotation.y
	if _face_cam > 0.0 or send_charge >= 0.0 or draw_charge >= 0.0:
		var f := rig.forward()
		face = atan2(f.x, f.z)
	elif _clamber_t >= 0.0:
		var c := _clamber_to - _clamber_from
		face = atan2(c.x, c.z)
	elif dir.length() > 0.05:
		face = atan2(dir.x, dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, face, minf(1.0, delta * b.turn_speed))
	var hspeed := Vector3(velocity.x, 0, velocity.z).length()
	var lean := clampf(hspeed / b.sprint_speed, 0.0, 1.0) * (0.3 if flying else 0.18)
	_model.rotation.x = lerpf(_model.rotation.x, lean, minf(1.0, delta * 8.0))
	_update_staff(delta)
	var flicker := 0.3 + (sin(_t * 9.0) * 0.5 + 0.5) * 0.25 * randf_range(0.8, 1.2)
	if _snap_time > 0.0 or singularity_t > 0.0:
		flicker = 0.9
	elif _charging:
		flicker = 0.4 + 0.5 * clampf(_charge_t / b.air_jump_max_charge, 0.0, 1.0)
	var aura_c := Color(1.0, 0.25, 0.2, 0.8) if _hurt_flash > 0.0 else Color(GOLD, flicker)
	for m in _aura_mats:
		m.albedo_color = aura_c
	for m in _aura_shader_mats:
		m.set_shader_parameter("aura_color", Color(aura_c, aura_c.a * 0.8))
	_update_sway(delta)
	_model.visible = not (_snap_time > 0.0 and b.snap_rank >= 2)

	var sprinting := Input.is_action_pressed("sprint") and hspeed > b.walk_speed * 1.05
	_ghost_t -= delta
	if (sprinting or (flying and hspeed > b.flight_speed * 0.9)) and _ghost_t <= 0.0:
		_ghost_t = 0.08
		Art.ghost(_model, get_parent(), GOLD, 0.16, 0.22)
	if rig:
		var fov_goal := b.sprint_fov if (sprinting or _snap_time > 0.0 or (flying and hspeed > b.flight_speed)) else b.base_fov
		rig.camera.fov = lerpf(rig.camera.fov, fov_goal, minf(1.0, delta * 6.0))

	_field_root.visible = field_on
	var goal := field_radius() / b.field_radius
	_field_scale = lerpf(_field_scale, goal, minf(1.0, delta * 10.0))
	_field_root.scale = Vector3(_field_scale, 1.0, _field_scale)
	_field_root.position.y = 0.04 if not flying else 0.3
	_field_spinner.rotation.y += delta * (0.8 if field_mode == FieldMode.CRUSH else -0.8) * (3.0 if singularity_t > 0.0 else 1.0)
	var pulse := 1.0 + sin(_t * 3.0) * 0.02
	_field_spinner.scale = Vector3(pulse, 1, pulse)
	_field_fill.albedo_color.a = 0.13 if singularity_t > 0.0 else 0.1


func _apply_field_look() -> void:
	var c := CRUSH_COLOR if field_mode == FieldMode.CRUSH else LIFT_COLOR
	_field_fill.albedo_color = Color(c, 0.1)
	_field_edge.albedo_color = Color(c, 0.75)
	_field_dot.albedo_color = Color(c, 0.9)
	if field_mode == FieldMode.CRUSH:
		_field_process.gravity = Vector3(0, -9, 0)
		_field_process.emission_shape_offset = Vector3(0, 3.5, 0)
	else:
		_field_process.gravity = Vector3(0, 5, 0)
		_field_process.emission_shape_offset = Vector3(0, 0.1, 0)
	toast.emit("Gravity: %s" % ("Crush" if field_mode == FieldMode.CRUSH else "Lift"))


func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	if ResourceLoader.exists(RIGGED_PATH):
		var rigged: PackedScene = load(RIGGED_PATH)
		var inst := rigged.instantiate()
		_model.add_child(inst)
		for stray in inst.find_children("Cube*", "MeshInstance3D", true, false):
			stray.queue_free()
		_apply_model_shaders(inst)
		for node in inst.find_children("*", "MeshInstance3D", true, false):
			if node.skin:
				node.custom_aabb = AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3, 3.5, 3))
		_setup_hair_physics(inst)
	elif ResourceLoader.exists(MODEL_PATH):
		var scene: PackedScene = load(MODEL_PATH)
		var inst := scene.instantiate()
		_model.add_child(inst)
		_apply_model_shaders(inst)
	else:
		_build_placeholder()
	_build_staff()
	var gp := GPUParticles3D.new()
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	proc.emission_ring_axis = Vector3.UP
	proc.emission_ring_radius = 0.55
	proc.emission_ring_inner_radius = 0.3
	proc.emission_ring_height = 0.2
	proc.direction = Vector3.UP
	proc.spread = 10.0
	proc.initial_velocity_min = 0.6
	proc.initial_velocity_max = 1.4
	proc.gravity = Vector3.ZERO
	gp.process_material = proc
	var dot := QuadMesh.new()
	dot.size = Vector2(0.035, 0.035)
	gp.draw_pass_1 = dot
	gp.material_override = Art.glow(GOLD, 1.0, true)
	gp.amount = 60
	gp.lifetime = 1.8
	gp.position.y = 0.1
	_model.add_child(gp)


func _build_staff() -> void:
	_staff = Node3D.new()
	_model.add_child(_staff)
	_staff_body = Node3D.new()
	_staff.add_child(_staff_body)
	if ResourceLoader.exists(STAFF_PATH):
		var scene: PackedScene = load(STAFF_PATH)
		var inst: Node3D = scene.instantiate()
		inst.rotation.y = PI / 2
		_staff_body.add_child(inst)
		for node in inst.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = node
			for i in mi.mesh.get_surface_count():
				var src := mi.get_active_material(i) as BaseMaterial3D
				var sm := ShaderMaterial.new()
				sm.shader = STAFF_SHADER
				if src and src.albedo_texture:
					sm.set_shader_parameter("albedo_tex", src.albedo_texture)
				mi.set_surface_override_material(i, sm)
				_staff_mats.append(sm)
	else:
		var shaft := CylinderMesh.new()
		shaft.top_radius = 0.02
		shaft.bottom_radius = 0.025
		shaft.height = 1.0
		shaft.radial_segments = 6
		Art.mesh(shaft, Art.mat(Color(0.75, 0.7, 0.6)), Vector3.ZERO, _staff_body)
	_staff_tip = Node3D.new()
	_staff_tip.position = STONE_LOCAL
	_staff_body.add_child(_staff_tip)
	_staff_glow = Sprite3D.new()
	_staff_glow.texture = _glow_texture()
	_staff_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_staff_glow.modulate = Color(0.75, 0.5, 1.0, 0.8)
	_staff_glow.pixel_size = 0.004
	_staff_glow.shaded = false
	_staff_glow.no_depth_test = false
	_staff_glow.render_priority = 1
	_staff_tip.add_child(_staff_glow)
	_staff_light = OmniLight3D.new()
	_staff_light.light_color = Color(0.7, 0.5, 1.0)
	_staff_light.omni_range = 4.0
	_staff_tip.add_child(_staff_light)
	_staff_len = Game.staff_length()


func _glow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _update_staff(delta: float) -> void:
	var b := Game.balance
	var maxed := Game.maxed_abilities()
	_staff_len = lerpf(_staff_len, Game.staff_length(), minf(1.0, delta * 3.0))
	var grow := _staff_len - b.staff_base_length
	_staff_body.scale = Vector3.ONE * _staff_len
	var local_sway := _model.global_basis.orthonormalized().inverse() * _sway
	_staff.position = Vector3(0.0, 1.0 + grow * 0.2, -0.3 - grow * 0.05) + Vector3(0, sin(_t * 1.6 + 1.0) * 0.04, 0) - local_sway * 0.06
	_staff.rotation = Vector3(0.0, 0.0, -deg_to_rad(b.staff_tilt_deg) + sin(_t * 1.1) * 0.04)
	var pulse := 1.0 + sin(_t * 2.4) * 0.25
	var glow := b.staff_glow_base + b.staff_glow_per_max * maxed
	if singularity_t > 0.0 or rend_cd > b.rend_cooldown - 1.0:
		glow *= 2.0
	for m in _staff_mats:
		m.set_shader_parameter("glow", glow)
		m.set_shader_parameter("pulse", pulse)
	_staff_light.light_energy = (0.6 + 0.25 * maxed) * pulse
	_staff_glow.modulate.a = clampf(0.35 + 0.08 * maxed, 0.0, 0.9) * pulse


func _apply_model_shaders(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i) as BaseMaterial3D
			var body := ShaderMaterial.new()
			body.shader = BODY_SHADER
			if src and src.albedo_texture:
				body.set_shader_parameter("albedo_tex", src.albedo_texture)
			var aura := ShaderMaterial.new()
			aura.shader = AURA_SHADER
			body.next_pass = aura
			mi.set_surface_override_material(i, body)
			_body_mats.append(body)
			_aura_shader_mats.append(aura)


func _setup_hair_physics(root: Node) -> void:
	var skels := root.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return
	_skeleton = skels[0]
	_rigged = true
	_skel_unit = 1.0 / maxf(_skeleton.global_basis.get_scale().x, 0.0001)
	var b := Game.balance
	_hair_sim = SpringBoneSimulator3D.new()
	_skeleton.add_child(_hair_sim)
	var chains := HAIR_CHAINS.filter(func(c): return _skeleton.find_bone(c[0]) >= 0 and _skeleton.find_bone(c[1]) >= 0)
	_hair_sim.setting_count = chains.size()
	for i in chains.size():
		_hair_sim.set_root_bone_name(i, chains[i][0])
		_hair_sim.set_end_bone_name(i, chains[i][1])
		_hair_sim.set_extend_end_bone(i, true)
		_hair_sim.set_end_bone_direction(i, SpringBoneSimulator3D.BONE_DIRECTION_FROM_PARENT)
		_hair_sim.set_end_bone_length(i, 0.06 * _skel_unit)
		_hair_sim.set_radius(i, b.hair_joint_radius * _skel_unit)
		_hair_sim.set_stiffness(i, b.hair_stiffness)
		_hair_sim.set_drag(i, b.hair_drag)
		_hair_sim.set_gravity(i, b.hair_gravity_idle)
		_hair_sim.set_gravity_direction(i, Vector3.DOWN)
		_hair_sim.set_enable_all_child_collisions(i, true)
		_hair_sim.set_stiffness_damping_curve(i, _curve(1.0, 0.35))
		_hair_sim.set_gravity_damping_curve(i, _curve(0.15, 1.0))
	_add_hair_collider("SpringBoneCollisionSphere3D", "mixamorig:Head", 0.105, 0.0, Vector3(0, 0.07, 0.0))
	_add_hair_collider("SpringBoneCollisionCapsule3D", "mixamorig:Neck", 0.055, 0.14, Vector3(0, 0.03, 0))
	_add_hair_collider("SpringBoneCollisionCapsule3D", "mixamorig:Spine2", 0.12, 0.38, Vector3(0, 0.02, -0.01))
	_add_hair_collider("SpringBoneCollisionSphere3D", "mixamorig:LeftShoulder", 0.06, 0.0, Vector3.ZERO)
	_add_hair_collider("SpringBoneCollisionSphere3D", "mixamorig:RightShoulder", 0.06, 0.0, Vector3.ZERO)


func _curve(root_value: float, tip_value: float) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, root_value))
	c.add_point(Vector2(1.0, tip_value))
	return c


func _find_bone(bone: String) -> String:
	for candidate in [bone, bone.replace(":", "_"), bone.get_slice(":", 1)]:
		if candidate != "" and _skeleton.find_bone(candidate) >= 0:
			return candidate
	return ""


func _add_hair_collider(kind: String, bone: String, radius: float, height: float, offset: Vector3) -> void:
	var resolved := _find_bone(bone)
	if resolved == "":
		return
	var c: SpringBoneCollision3D = ClassDB.instantiate(kind)
	c.bone_name = resolved
	c.position_offset = offset * _skel_unit
	c.set("radius", radius * _skel_unit)
	if height > 0.0:
		c.set("height", height * _skel_unit)
	_hair_sim.add_child(c)


func _update_hair(delta: float) -> void:
	var b := Game.balance
	var dir := Vector3.DOWN
	var g := b.hair_gravity_idle
	if field_on:
		if field_mode == FieldMode.LIFT:
			dir = Vector3.UP
			g = b.hair_gravity_lift
		else:
			g = b.hair_gravity_crush
	if singularity_t > 0.0:
		g *= 1.5
	var state := [g, dir, b.hair_stiffness, b.hair_drag]
	if state != _hair_state:
		_hair_state = state
		for i in _hair_sim.setting_count:
			_hair_sim.set_gravity(i, g)
			_hair_sim.set_gravity_direction(i, dir)
			_hair_sim.set_stiffness(i, b.hair_stiffness)
			_hair_sim.set_drag(i, b.hair_drag)
	var flutter := Vector3(sin(_t * 3.1), sin(_t * 2.3) * 0.5, cos(_t * 2.7)) * b.hair_flutter
	_hair_sim.external_force = flutter


func _update_sway(delta: float) -> void:
	if _rigged:
		_update_hair(delta)
	var b := Game.balance
	var accel := (velocity - _prev_vel) / maxf(delta, 0.0001)
	_prev_vel = velocity
	var bias := Vector3.DOWN * b.sway_idle_bias
	if field_on:
		bias = Vector3.UP * b.sway_lift_bias if field_mode == FieldMode.LIFT else Vector3.DOWN * b.sway_crush_bias
	var target := bias - (accel * b.sway_inertia).limit_length(1.5)
	_sway_vel += (target - _sway) * b.sway_stiffness * delta
	_sway_vel *= exp(-b.sway_damping * delta)
	_sway += _sway_vel * delta
	var local := _model.global_basis.orthonormalized().inverse() * _sway
	var hat_amt := 0.0 if _rigged else b.hat_sway_amount
	var hair_amt := 0.0 if _rigged else b.hair_sway_amount
	for m in _body_mats:
		m.set_shader_parameter("sway", local)
		m.set_shader_parameter("hat_amount", hat_amt)
		m.set_shader_parameter("hair_amount", hair_amt)
	for m in _aura_shader_mats:
		m.set_shader_parameter("sway", local)
		m.set_shader_parameter("hat_amount", hat_amt)
		m.set_shader_parameter("hair_amount", hair_amt)


func _add_aura(material: StandardMaterial3D) -> StandardMaterial3D:
	var a := Art.aura_pass(GOLD)
	material.next_pass = a
	_aura_mats.append(a)
	return material


func _build_placeholder() -> void:
	var robe_c := Color(0.29, 0.17, 0.44)
	var robe := CylinderMesh.new()
	robe.top_radius = 0.2
	robe.bottom_radius = 0.62
	robe.height = 1.35
	robe.radial_segments = 7
	Art.mesh(robe, _add_aura(Art.mat(robe_c)), Vector3(0, 0.68, 0), _model)
	var hem := CylinderMesh.new()
	hem.top_radius = 0.63
	hem.bottom_radius = 0.66
	hem.height = 0.08
	hem.radial_segments = 7
	var gold := Art.mat(GOLD, Color(0.25, 0.15, 0.0))
	Art.mesh(hem, gold, Vector3(0, 0.04, 0), _model)
	var head := SphereMesh.new()
	head.radius = 0.24
	head.height = 0.48
	head.radial_segments = 7
	head.rings = 4
	Art.mesh(head, _add_aura(Art.mat(Color(0.94, 0.78, 0.66))), Vector3(0, 1.55, 0.02), _model)
	var hair := BoxMesh.new()
	hair.size = Vector3(0.36, 0.5, 0.14)
	var dark := Art.mat(Color(0.11, 0.08, 0.16))
	Art.mesh(hair, dark, Vector3(0, 1.38, -0.18), _model)
	var eye := BoxMesh.new()
	eye.size = Vector3(0.05, 0.07, 0.04)
	var eye_m := Art.mat(Color(0.25, 0.12, 0.45), Color(0.3, 0.15, 0.6))
	Art.mesh(eye, eye_m, Vector3(-0.09, 1.56, 0.23), _model)
	Art.mesh(eye, eye_m, Vector3(0.09, 1.56, 0.23), _model)
	var brim := CylinderMesh.new()
	brim.top_radius = 0.62
	brim.bottom_radius = 0.62
	brim.height = 0.05
	brim.radial_segments = 9
	Art.mesh(brim, _add_aura(Art.mat(robe_c.darkened(0.3))), Vector3(0, 1.76, 0), _model)
	var hat := CylinderMesh.new()
	hat.top_radius = 0.0
	hat.bottom_radius = 0.3
	hat.height = 0.75
	hat.radial_segments = 8
	var hat_mi := Art.mesh(hat, _add_aura(Art.mat(robe_c)), Vector3(0, 2.12, -0.05), _model)
	hat_mi.rotation = Vector3(-0.3, 0, -0.25)
	var band := CylinderMesh.new()
	band.top_radius = 0.29
	band.bottom_radius = 0.31
	band.height = 0.1
	band.radial_segments = 8
	Art.mesh(band, gold, Vector3(0, 1.83, 0), _model)
	var sleeve := CylinderMesh.new()
	sleeve.top_radius = 0.07
	sleeve.bottom_radius = 0.13
	sleeve.height = 0.55
	sleeve.radial_segments = 6
	var robe_m := Art.mat(robe_c)
	Art.mesh(sleeve, robe_m, Vector3(-0.32, 1.0, 0.08), _model).rotation.z = 0.5
	Art.mesh(sleeve, robe_m, Vector3(0.32, 1.0, 0.08), _model).rotation.z = -0.5


func _build_field() -> void:
	var r := Game.balance.field_radius
	_field_root = Node3D.new()
	_field_root.position.y = 0.04
	add_child(_field_root)
	_field_fill = Art.glow(CRUSH_COLOR, 0.1)
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.02
	disc.radial_segments = 40
	disc.rings = 1
	Art.mesh(disc, _field_fill, Vector3.ZERO, _field_root)
	_field_spinner = Node3D.new()
	_field_root.add_child(_field_spinner)
	_field_edge = Art.glow(CRUSH_COLOR, 0.75)
	var edge := TorusMesh.new()
	edge.inner_radius = r - 0.12
	edge.outer_radius = r
	edge.rings = 48
	edge.ring_segments = 3
	Art.mesh(edge, _field_edge, Vector3.ZERO, _field_spinner)
	var inner := TorusMesh.new()
	inner.inner_radius = r * Game.balance.inner_crush_frac - 0.05
	inner.outer_radius = r * Game.balance.inner_crush_frac
	inner.rings = 32
	inner.ring_segments = 3
	Art.mesh(inner, _field_edge, Vector3.ZERO, _field_spinner)
	var rune := BoxMesh.new()
	rune.size = Vector3(0.18, 0.05, 0.45)
	for i in 12:
		var a := TAU * i / 12.0
		var m := Art.mesh(rune, _field_edge, Vector3(cos(a) * (r - 0.4), 0.02, sin(a) * (r - 0.4)), _field_spinner)
		m.rotation.y = -a
	_field_particles = GPUParticles3D.new()
	_field_process = ParticleProcessMaterial.new()
	_field_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	_field_process.emission_ring_axis = Vector3.UP
	_field_process.emission_ring_radius = r
	_field_process.emission_ring_inner_radius = 0.0
	_field_process.emission_ring_height = 0.1
	_field_process.spread = 0.0
	_field_process.initial_velocity_min = 0.0
	_field_process.initial_velocity_max = 0.0
	_field_particles.process_material = _field_process
	var q := QuadMesh.new()
	q.size = Vector2(0.055, 0.055)
	_field_particles.draw_pass_1 = q
	_field_dot = Art.glow(CRUSH_COLOR, 0.9, true)
	_field_particles.material_override = _field_dot
	_field_particles.amount = 90
	_field_particles.lifetime = 0.9
	_field_particles.visibility_aabb = AABB(Vector3(-r, -1, -r), Vector3(r * 2, 6, r * 2))
	_field_root.add_child(_field_particles)
	field_mode = FieldMode.CRUSH
	_apply_field_look()
