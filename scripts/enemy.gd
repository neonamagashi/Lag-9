class_name Enemy
extends CharacterBody3D

static var _meshes := {}
static var _mats := {}

var level := 1
var max_hp := 100.0
var hp := 100.0

var _model: Node3D
var _label: Label3D
var _crush_t := 0.0
var _attack_cd := 0.0
var _squash := 1.0
var _lunge := 0.0
var _dead := false
var _airborne := false
var _ground_y := 0.0
var _phase := 0.0
var _field_accum := 0.0
var _field_popup_t := 0.0
var _label_dirty := true


func setup(lvl: int) -> Enemy:
	level = maxi(1, lvl)
	return self


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	max_hp = Game.hp_for_level(level)
	hp = max_hp
	_phase = randf() * TAU
	_ground_y = global_position.y
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.3
	col.shape = cap
	col.position.y = 0.65
	add_child(col)
	_ensure_shared()
	_model = Node3D.new()
	add_child(_model)
	Art.mesh(_meshes.body, _mats.body, Vector3(0, 0.5, 0), _model)
	Art.mesh(_meshes.horn, _mats.horn, Vector3(-0.2, 0.92, 0), _model).rotation.z = 0.45
	Art.mesh(_meshes.horn, _mats.horn, Vector3(0.2, 0.92, 0), _model).rotation.z = -0.45
	Art.mesh(_meshes.eye, _mats.eye, Vector3(-0.15, 0.6, 0.4), _model)
	Art.mesh(_meshes.eye, _mats.eye, Vector3(0.15, 0.6, 0.4), _model)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.outline_size = 8
	_label.pixel_size = 0.007
	_label.position.y = 1.75
	add_child(_label)


static func _ensure_shared() -> void:
	if not _meshes.is_empty():
		return
	var body := SphereMesh.new()
	body.radius = 0.5
	body.height = 1.0
	body.radial_segments = 7
	body.rings = 4
	var horn := CylinderMesh.new()
	horn.top_radius = 0.0
	horn.bottom_radius = 0.1
	horn.height = 0.38
	horn.radial_segments = 4
	var eye := BoxMesh.new()
	eye.size = Vector3(0.11, 0.08, 0.05)
	_meshes = {"body": body, "horn": horn, "eye": eye}
	_mats = {
		"body": Art.mat(Color(0.17, 0.11, 0.24)),
		"horn": Art.mat(Color(0.08, 0.06, 0.11)),
		"eye": Art.glow(Color(1.0, 0.3, 0.22), 1.0),
	}


func mark_dirty() -> void:
	_label_dirty = true


func gap() -> int:
	return level - Game.balance.witch_level


func take_damage(amount: float, kind: String) -> void:
	if _dead:
		return
	hp -= amount
	_label_dirty = true
	if kind == "field":
		_field_accum += amount
	else:
		var c := Color(0.9, 0.75, 1.0) if kind == "pierce" else Color(1.0, 0.85, 0.4)
		Art.popup(get_parent(), global_position + Vector3(0, 1.4, 0), str(int(amount)), c)
	if hp <= 0.0:
		die(kind)


func die(_cause: String) -> void:
	if _dead:
		return
	_dead = true
	Game.kills += 1
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_label.visible = false
	Art.burst(get_parent(), global_position + Vector3(0, 0.5, 0), Color(0.75, 0.5, 1.0))
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.9, 0.05, 1.9), 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var b := Game.balance
	var w := Game.witch
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_lunge = maxf(0.0, _lunge - delta * 4.0)
	var to_w := w.global_position - global_position
	to_w.y = 0.0
	var d := to_w.length()
	var g := gap()
	var speed_mult := 1.0
	var can_attack := true
	var target_squash := 1.0
	var lift_to := 0.0
	var shake := 0.0
	var in_field := w.field_on and d < b.field_radius

	if in_field:
		var prox := 1.0 - d / b.field_radius
		take_damage(Game.field_dps(level, prox) * delta, "field")
		if _dead:
			return
		if w.field_mode == Witch.FieldMode.CRUSH:
			can_attack = g > b.kneel_gap_max
			if g <= 0:
				speed_mult = 0.0
				target_squash = 0.3
				shake = 0.05
				_crush_t += delta
				if _crush_t >= b.instant_crush_time:
					die("crushed")
					return
			elif g <= b.kneel_gap_max:
				speed_mult = b.kneel_speed_mult
				target_squash = 0.6
				shake = 0.02
				if d < b.field_radius * b.inner_crush_frac:
					target_squash = 0.35
					shake = 0.05
					_crush_t += delta
					if _crush_t >= b.inner_crush_time:
						die("crushed")
						return
			else:
				speed_mult = b.heavy_slow_mult
				target_squash = 0.8
				if d < b.field_radius * b.pin_frac:
					speed_mult = 0.0
					target_squash = 0.45
					shake = 0.03
					can_attack = false
					if d < 1.0:
						w.take_damage(b.pinned_contact_pct * Game.witch_max_hp() * delta, "contact")
		else:
			if g <= b.kneel_gap_max:
				lift_to = b.lift_height + sin(Time.get_ticks_msec() * 0.002 + _phase) * 0.35
				speed_mult = 0.0
				can_attack = false
			else:
				lift_to = b.heavy_lift_height
				speed_mult = b.heavy_slow_mult
	else:
		_crush_t = maxf(0.0, _crush_t - delta)

	if lift_to > 0.0:
		_airborne = true
		velocity.y = (_ground_y + lift_to - global_position.y) * 5.0
		if lift_to > 1.0:
			_model.rotation.x += delta * 1.4
			_model.rotation.z += delta * 0.9
	else:
		if not is_on_floor():
			velocity.y -= b.enemy_gravity * delta
		_model.rotation.x = lerp_angle(_model.rotation.x, 0.0, minf(1.0, delta * 8.0))
		_model.rotation.z = lerp_angle(_model.rotation.z, 0.0, minf(1.0, delta * 8.0))

	var dir := to_w / d if d > 0.01 else Vector3.ZERO
	var hv := Vector3.ZERO
	if d > b.enemy_attack_range * 0.85 and lift_to <= 1.0:
		hv = dir * b.enemy_speed * speed_mult
	velocity.x = move_toward(velocity.x, hv.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, hv.z, 30.0 * delta)
	if d > 0.01 and lift_to <= 1.0:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 8.0))

	var fall_speed := -velocity.y
	move_and_slide()
	if is_on_floor():
		if _airborne and lift_to <= 0.0 and fall_speed > b.impact_min_speed:
			take_damage(Game.impact_damage(level, fall_speed), "impact")
			_squash = 0.5
			if _dead:
				return
		if lift_to <= 0.0:
			_airborne = false
		_ground_y = global_position.y

	if can_attack and d < b.enemy_attack_range and _attack_cd <= 0.0 and not _airborne:
		_attack_cd = b.enemy_attack_cooldown
		_lunge = 1.0
		var dmg := b.enemy_hit_pct * Game.witch_max_hp() * pow(b.level_growth, g)
		w.take_damage(dmg, "melee")

	_squash = lerpf(_squash, target_squash, minf(1.0, delta * 10.0))
	_model.scale = Vector3(1.0 + (1.0 - _squash) * 0.5, _squash, 1.0 + (1.0 - _squash) * 0.5)
	_model.position = Vector3(randf_range(-shake, shake), 0, randf_range(-shake, shake)) + Vector3(0, 0, _lunge * 0.4).rotated(Vector3.UP, _model.rotation.y)

	_field_popup_t -= delta
	if _field_accum >= 1.0 and _field_popup_t <= 0.0:
		Art.popup(get_parent(), global_position + Vector3(0, 1.2, 0), str(int(_field_accum)), Color(0.7, 0.55, 1.0), 44)
		_field_accum = 0.0
		_field_popup_t = 0.45
	if _label_dirty:
		_refresh_label(g)


func _refresh_label(g: int) -> void:
	_label_dirty = false
	var filled := clampi(ceili(hp / max_hp * 10.0), 0, 10)
	_label.text = "LV %d\n%s%s" % [level, "=".repeat(filled), "·".repeat(10 - filled)]
	if g <= 0:
		_label.modulate = Color(0.55, 0.95, 0.5)
	elif g <= Game.balance.kneel_gap_max:
		_label.modulate = Color(1.0, 0.82, 0.35)
	else:
		_label.modulate = Color(1.0, 0.45, 0.4)
