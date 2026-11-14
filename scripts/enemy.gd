class_name Enemy
extends CharacterBody3D

static var _meshes := {}
static var _mats := {}

var level := 1
var kind := "imp"
var cfg: Dictionary = {}
var max_hp := 100.0
var hp := 100.0
var magical := false

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
var _knock_vel := Vector3.ZERO
var _knock_t := 0.0
var _stun_t := 0.0
var _rend_t := -1.0
var _rend_total := 1.0
var _rend_lift := false
var _rend_shards := false
var _strafe_sign := 1.0


func setup(lvl: int, enemy_kind := "imp") -> Enemy:
	level = maxi(1, lvl)
	kind = enemy_kind
	magical = randf() < Game.balance.mana_creature_chance
	return self


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	cfg = EnemyTypes.config(kind)
	max_hp = Game.hp_for_level(level) * float(cfg["hp_mult"])
	hp = max_hp
	_phase = randf() * TAU
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	_ground_y = global_position.y
	var h := float(cfg["height"])
	var r := float(cfg["radius"])
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = r
	cap.height = maxf(h * 0.95, r * 2.0 + 0.05)
	col.shape = cap
	col.position.y = cap.height * 0.5
	add_child(col)
	_model = Node3D.new()
	add_child(_model)
	var model_path: String = cfg["model"]
	if model_path != "" and ResourceLoader.exists(model_path):
		var body := _fit_model((load(model_path) as PackedScene).instantiate(), h)
		_model.add_child(body)
		var extra: String = cfg["extra"]
		if extra != "" and ResourceLoader.exists(extra):
			_attach_bow((load(extra) as PackedScene).instantiate(), body)
	else:
		_build_blob()
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.outline_size = 8
	_label.pixel_size = 0.007
	_label.position.y = h + float(cfg["hover"]) + 0.4
	add_child(_label)


func _build_blob() -> void:
	_ensure_shared()
	var eye_mat: Material = _mats.eye_magic if magical else _mats.eye
	Art.mesh(_meshes.body, _mats.body, Vector3(0, 0.5, 0), _model)
	Art.mesh(_meshes.horn, _mats.horn, Vector3(-0.2, 0.92, 0), _model).rotation.z = 0.45
	Art.mesh(_meshes.horn, _mats.horn, Vector3(0.2, 0.92, 0), _model).rotation.z = -0.45
	Art.mesh(_meshes.eye, eye_mat, Vector3(-0.15, 0.6, 0.4), _model)
	Art.mesh(_meshes.eye, eye_mat, Vector3(0.15, 0.6, 0.4), _model)


func _fit_model(inst: Node3D, height: float) -> Node3D:
	var holder := Node3D.new()
	holder.add_child(inst)
	inst.rotation.y = -PI / 2.0
	var box := _local_aabb(holder)
	if box.size.y > 0.0001:
		var k := height / box.size.y
		inst.scale = Vector3.ONE * k
		box = _local_aabb(holder)
		inst.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z)
	return holder


func _local_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != root and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b := xf * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _attach_bow(bow: Node3D, body: Node3D) -> void:
	var box := _local_aabb(body)
	var holder := Node3D.new()
	holder.add_child(bow)
	var bb := _local_aabb(holder)
	var k := float(cfg["height"]) * 0.7 / maxf(bb.size.y, 0.001)
	bow.scale = Vector3.ONE * k
	holder.position = Vector3(box.end.x - 0.06, float(cfg["height"]) * 0.5, 0.06)
	holder.rotation.y = PI / 2.0
	body.add_child(holder)


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
		"eye_magic": Art.glow(Color(0.35, 0.8, 1.0), 1.0),
	}


func mark_dirty() -> void:
	_label_dirty = true


func is_dead() -> bool:
	return _dead


func gap() -> int:
	return level - Game.balance.witch_level


func knock(v: Vector3, stun: float) -> void:
	if _dead:
		return
	var resist := 1.0 / ((1.0 + maxf(0.0, gap()) * Game.balance.knock_resist_per_gap) * float(cfg.get("mass", 1.0)))
	_knock_vel = Vector3(v.x, 0, v.z) * resist
	_knock_t = 0.7
	_stun_t = maxf(_stun_t, stun)
	velocity.y = maxf(velocity.y, 3.0 * resist)
	_airborne = true


func rend_start(hold: float, lift: bool, shards: bool) -> void:
	if _dead:
		return
	_rend_t = hold
	_rend_total = hold
	_rend_lift = lift
	_rend_shards = shards


func take_damage(amount: float, kind: String) -> void:
	if _dead:
		return
	hp -= amount
	_label_dirty = true
	if kind == "field":
		_field_accum += amount
	else:
		var c := Color(0.9, 0.75, 1.0)
		if kind in ["impact", "shard"]:
			c = Color(1.0, 0.85, 0.4)
		elif kind == "rend":
			c = Color(1.0, 0.45, 0.9)
		Art.popup(get_parent(), global_position + Vector3(0, 1.4, 0), str(int(amount)), c, 72 if kind == "rend" else 64)
		if kind == "impact":
			Sfx.play("impact", global_position, 0.12)
		elif kind != "rend":
			Sfx.play("enemy_hit", global_position, 0.12, -3.0)
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
	Sfx.play("crush_kill", global_position, 0.15)
	if magical:
		var orb := Pickup.new().setup(Pickup.Kind.MANA_ORB, Game.balance.mana_drop)
		get_parent().add_child(orb)
		orb.global_position = global_position + Vector3(0, 0.3, 0)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.9, 0.05, 1.9), 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _spawn_shards() -> void:
	for i in 5:
		var s := Shard.new()
		var a := TAU * i / 5.0 + randf() * 0.5
		s.velocity = Vector3(cos(a), 0.35, sin(a)) * 16.0
		s.damage_pct = Game.balance.rend_shard_damage_pct
		s.ignore = self
		get_parent().add_child(s)
		s.global_position = global_position + Vector3(0, 0.8, 0)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var b := Game.balance
	var w := Game.witch
	var ts := Game.enemy_time_scale
	var sdt := delta * ts
	_attack_cd = maxf(0.0, _attack_cd - sdt)
	_stun_t = maxf(0.0, _stun_t - sdt)
	_lunge = maxf(0.0, _lunge - sdt * 4.0)

	if _rend_t >= 0.0:
		_process_rend(delta)
		return

	var to_w := w.global_position - global_position
	to_w.y = 0.0
	var d := to_w.length()
	var d3 := w.field_center().distance_to(global_position + Vector3(0, 0.5, 0))
	var g := gap()
	var radius := w.field_radius()
	var speed_mult := 1.0
	var can_attack := _stun_t <= 0.0
	var target_squash := 1.0
	var lift_to := 0.0
	var shake := 0.0
	var in_field := w.field_on and d3 < radius

	if in_field:
		var surging := w.singularity_t > 0.0
		var prox := 1.0 - d3 / radius
		if surging:
			prox = maxf(prox, 0.75)
		take_damage(Game.field_dps(level, prox) * w.field_damage_mult() * delta, "field")
		if _dead:
			return
		if w.field_mode == Witch.FieldMode.CRUSH:
			can_attack = can_attack and g > b.kneel_gap_max
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
				if surging or d3 < radius * b.inner_crush_frac:
					target_squash = 0.35
					shake = 0.05
					_crush_t += delta
					if _crush_t >= b.inner_crush_time:
						die("crushed")
						return
			else:
				speed_mult = b.heavy_slow_mult
				target_squash = 0.8
				if d3 < radius * b.pin_frac:
					speed_mult = 0.0
					target_squash = 0.45
					shake = 0.03
					can_attack = false
					if d < 1.0:
						w.take_damage(b.pinned_contact_pct * Game.witch_max_hp() * delta, "contact")
		else:
			if g <= b.kneel_gap_max:
				lift_to = w.lift_height() + sin(Time.get_ticks_msec() * 0.002 + _phase) * 0.35
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
			velocity.y -= b.enemy_gravity * delta * maxf(ts, 0.35)
		_model.rotation.x = lerp_angle(_model.rotation.x, 0.0, minf(1.0, delta * 8.0))
		_model.rotation.z = lerp_angle(_model.rotation.z, 0.0, minf(1.0, delta * 8.0))

	var dir := to_w / d if d > 0.01 else Vector3.ZERO
	if _knock_t > 0.0:
		_knock_t -= delta
		velocity.x = _knock_vel.x
		velocity.z = _knock_vel.z
		_knock_vel *= exp(-2.5 * delta)
	else:
		var hv := Vector3.ZERO
		var spd := float(cfg["speed"])
		if lift_to <= 1.0 and _stun_t <= 0.0:
			if cfg["ranged"]:
				var keep := float(cfg["keep_range"])
				if d > keep + 2.0:
					hv = dir * spd
				elif d < keep - 3.0:
					hv = -dir * spd * 0.8
				else:
					hv = dir.cross(Vector3.UP) * spd * 0.45 * _strafe_sign
			elif d > float(cfg["attack_range"]) * 0.85:
				hv = dir * spd
			hv *= speed_mult * ts
		velocity.x = move_toward(velocity.x, hv.x, 30.0 * delta)
		velocity.z = move_toward(velocity.z, hv.z, 30.0 * delta)
		if d > 0.01 and lift_to <= 1.0:
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 8.0 * ts))

	var fall_speed := -velocity.y
	var knock_speed := _knock_vel.length() if _knock_t > 0.0 else 0.0
	move_and_slide()
	if knock_speed > b.enemy_collide_min_speed:
		_check_knock_collisions(knock_speed)
		if _dead:
			return
	if is_on_floor():
		if _airborne and lift_to <= 0.0 and fall_speed > b.impact_min_speed:
			take_damage(Game.impact_damage(level, fall_speed), "impact")
			_squash = 0.5
			if _dead:
				return
		if lift_to <= 0.0 and _knock_t <= 0.0:
			_airborne = false
		_ground_y = global_position.y

	var dmg := b.enemy_hit_pct * Game.witch_max_hp() * pow(b.level_growth, g) * float(cfg["dmg_mult"])
	if cfg["ranged"]:
		if can_attack and d < float(cfg["fire_range"]) and _attack_cd <= 0.0 and not _airborne:
			_attack_cd = float(cfg["cooldown"]) * randf_range(0.85, 1.15)
			_fire(w, dmg)
	elif can_attack and d < float(cfg["attack_range"]) and _attack_cd <= 0.0 and not _airborne:
		_attack_cd = float(cfg["cooldown"])
		_lunge = 1.0
		Sfx.play("enemy_attack", global_position, 0.15, -4.0 if kind != "glutton" else 2.0)
		w.take_damage(dmg, "melee")

	_squash = lerpf(_squash, target_squash, minf(1.0, delta * 10.0))
	_model.scale = Vector3(1.0 + (1.0 - _squash) * 0.5, _squash, 1.0 + (1.0 - _squash) * 0.5)
	var hover := float(cfg["hover"])
	if hover > 0.0:
		hover += sin(Time.get_ticks_msec() * 0.0025 + _phase) * 0.08
	_model.position = Vector3(randf_range(-shake, shake), hover, randf_range(-shake, shake)) + Vector3(0, 0, _lunge * 0.4).rotated(Vector3.UP, _model.rotation.y)
	_tick_labels(delta, g)


func _fire(w: Witch, dmg: float) -> void:
	var proj_kind: String = cfg["projectile"]
	var h := float(cfg["height"])
	var facing := Vector3(sin(_model.rotation.y), 0, cos(_model.rotation.y))
	var from := global_position + Vector3(0, h * 0.62 + float(cfg["hover"]), 0) + facing * 0.5
	var p := Projectile.new().launch(proj_kind, from, w.field_center(), dmg)
	get_parent().add_child(p)
	p.global_position = from
	_lunge = 0.6
	Sfx.play({"fireball": "fireball_cast", "void": "void_cast", "arrow": "arrow_shot"}.get(proj_kind, "whiff"), from, 0.1, -2.0)


func _check_knock_collisions(speed: float) -> void:
	var b := Game.balance
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var other := c.get_collider()
		if other is Enemy and other != self and not other.is_dead():
			take_damage(Game.impact_damage(level, speed), "impact")
			other.take_damage(Game.impact_damage(other.level, speed) * b.enemy_collide_share, "impact")
			other.knock(_knock_vel * 0.5, 0.3)
			_knock_vel *= 0.3
			return
		if not (other is Enemy) and absf(c.get_normal().y) < 0.5:
			take_damage(Game.impact_damage(level, speed), "impact")
			_knock_vel = Vector3.ZERO
			_knock_t = 0.0
			return


func _process_rend(delta: float) -> void:
	_rend_t -= delta
	var k := 1.0 - _rend_t / _rend_total
	var goal_y := _ground_y + (2.5 if _rend_lift else 0.0)
	velocity = Vector3(0, (goal_y - global_position.y) * 6.0, 0)
	move_and_slide()
	var j := 0.04 + k * 0.12
	var stretch := 1.0 + k * 0.6
	var squash := 0.45 if not _rend_lift else 1.0
	_model.scale = Vector3(stretch, squash * (1.0 + k * 0.4), stretch)
	_model.position = Vector3(randf_range(-j, j), randf_range(-j, j), randf_range(-j, j))
	if _rend_lift:
		_model.rotation.y += delta * 8.0 * k
	if _rend_t <= 0.0:
		_rend_t = -1.0
		_model.scale = Vector3.ONE
		_model.position = Vector3.ZERO
		Art.burst(get_parent(), global_position + Vector3(0, 0.6, 0), Color(0.9, 0.4, 1.0), 40)
		if _rend_shards:
			_spawn_shards()
		take_damage(Game.scaled_damage(Game.balance.rend_base_damage, level), "rend")
		if not _dead and _rend_lift:
			_airborne = true


func _tick_labels(delta: float, g: int) -> void:
	_field_popup_t -= delta
	if _field_accum >= 1.0 and _field_popup_t <= 0.0:
		Art.popup(get_parent(), global_position + Vector3(0, 1.2, 0), str(int(_field_accum)), Color(0.7, 0.55, 1.0), 44)
		_field_accum = 0.0
		_field_popup_t = 0.45
	if _label_dirty:
		_label_dirty = false
		var filled := clampi(ceili(hp / max_hp * 10.0), 0, 10)
		_label.text = "LV %d%s\n%s%s" % [level, " *" if magical else "", "=".repeat(filled), "·".repeat(10 - filled)]
		if g <= 0:
			_label.modulate = Color(0.55, 0.95, 0.5)
		elif g <= Game.balance.kneel_gap_max:
			_label.modulate = Color(1.0, 0.82, 0.35)
		else:
			_label.modulate = Color(1.0, 0.45, 0.4)
