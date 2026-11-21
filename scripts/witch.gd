class_name Witch
extends Actor

enum Mode { CRUSH, LIFT }

const DIR := "res://assets/witch_white/%s.png"
const CRUSH_COLOR := Color(0.55, 0.42, 1.0)
const LIFT_COLOR := Color(1.0, 0.82, 0.4)
const ELLIPSE := 0.6
const PALM_PX := Vector2(39.0, 28.0)
const SING_EYES := Color(1.0, 0.1, 0.08)

# ---------- tuning ----------
const SPEED := 118.0
const SPRINT := 1.6
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
const SNAP_MAX_DIST := 192.0
const SNAP_MAX_CHARGE := 0.7
const PIERCE_BAND := 20.0
const NORTH_COS := 0.924
const HUNCH_MOUTH := [Vector2(8.2, -19.9), Vector2(9.3, -18.5), Vector2(9.8, -17.6)]
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
var snap_charge := -1.0
var held: Enemy
var singularity_t := 0.0
var dead := false
var abilities_enabled := true
var sprint_enabled := true
## Scene control: frozen stops her moving, move_mult slows her, drunk sways her, pose holds a frame (e.g. "hunch").
var frozen := false
var move_mult := 1.0
var drunk := false
var pose := ""
var pose_frame := 0
var _lean := 0.0
var _north := false
var _dip := 0.0
var _snap_fx: CPUParticles2D
var _rune_t := 0.0
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
var charge_hand: AnimatedSprite2D
var charge_dust: AnimatedSprite2D
var _tint: ColorRect
var _sing_k := 0.0


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
		["hunch", "hunch", 64, 64, 3, 6.0, false, 0], ["cast_n", "cast_n", 64, 64, 6, 10.0, true, 0],
	]
	for d in defs:
		Sheets.add(sf, d[0], DIR % d[1], d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
		Sheets.add(ef, d[0], DIR % (d[1] + "_eyes"), d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
		if ResourceLoader.exists(DIR % (d[1] + "_back")):
			Sheets.add(sf, d[0] + "_back", DIR % (d[1] + "_back"), d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
			Sheets.add(ef, d[0] + "_back", DIR % (d[1] + "_eyes"), d[2], d[3], d[4], d[5], d[6], true, Rect2i(), d[7])
	var base := {"idle": Vector3(23, 62, 64), "hurt": Vector3(23, 62, 64), "death": Vector3(23, 62, 64),
		"cast": Vector3(27, 45, 44), "cast_hold": Vector3(27, 45, 44), "hunch": Vector3(23, 62, 64), "cast_n": Vector3(23, 62, 64), "jump": Vector3(35, 62, 54)}
	for k in base:
		anchors[k] = base[k]
		anchors[k + "_back"] = base[k]
	_build_visual(sf)
	eyes = AnimatedSprite2D.new()
	eyes.sprite_frames = ef
	eyes.centered = false
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	eyes.material = unshaded
	visual.add_child(eyes)
	var cf := SpriteFrames.new()
	cf.remove_animation("default")
	Sheets.add(cf, "hand", DIR % "charge_hand", 40, 32, 10, 1.0, false, true)
	Sheets.add(cf, "dust", DIR % "charge_dust", 90, 28, 10, 1.0, false, true)
	charge_hand = AnimatedSprite2D.new()
	charge_hand.sprite_frames = cf
	charge_hand.animation = "hand"
	charge_hand.centered = false
	charge_hand.z_index = 2
	charge_hand.visible = false
	add_child(charge_hand)
	charge_dust = AnimatedSprite2D.new()
	charge_dust.sprite_frames = cf
	charge_dust.animation = "dust"
	charge_dust.centered = false
	charge_dust.z_index = -1
	charge_dust.visible = false
	add_child(charge_dust)
	# Snap prep: black smoke curling in around her feet
	_snap_fx = CPUParticles2D.new()
	_snap_fx.amount = 30
	_snap_fx.lifetime = 0.45
	_snap_fx.emitting = false
	_snap_fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	_snap_fx.emission_sphere_radius = 16.0
	_snap_fx.scale = Vector2(1.0, ELLIPSE)
	_snap_fx.gravity = Vector2.ZERO
	_snap_fx.radial_accel_min = -90.0
	_snap_fx.radial_accel_max = -60.0
	_snap_fx.tangential_accel_min = 40.0
	_snap_fx.tangential_accel_max = 70.0
	_snap_fx.texture = Fx.soft()
	_snap_fx.scale_amount_min = 0.3
	_snap_fx.scale_amount_max = 0.6
	var sg := Gradient.new()
	sg.set_color(0, Color(0.02, 0.0, 0.04, 0.0))
	sg.add_point(0.3, Color(0.04, 0.01, 0.07, 0.8))
	sg.add_point(0.8, Color(0.3, 0.16, 0.55, 0.5))
	sg.set_color(sg.get_point_count() - 1, Color(0.4, 0.25, 0.7, 0.0))
	_snap_fx.color_ramp = sg
	_snap_fx.z_index = -1
	add_child(_snap_fx)
	var tl := CanvasLayer.new()
	tl.layer = 4
	add_child(tl)
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0.3, 0.0, 0.02, 0.0)
	tl.add_child(_tint)
	play("idle")
	field = GravityField.new()
	field.witch = self
	add_child(field)
	glow = Fx.light(self, Color(0.7, 0.55, 1.0), 1.6, 0.35)
	glow.position = Vector2(0, -26)


func _update_visual(delta: float) -> void:
	super(delta)
	visual.position.y -= hover
	# floating: head leans into the drift (shear pivots at her feet)
	var lean := clampf(velocity.x / SPEED, -1.0, 1.0) * 0.12 * (1.0 if z <= 0.0 else 0.4)
	if snap_charge >= 0.0 and velocity.length() > 10.0:
		# bracing to snap while moving: thrown forward into it, like a sprinter off the line
		lean = signf(velocity.x) * (0.22 + 0.14 * snap_charge / SNAP_MAX_CHARGE) if absf(velocity.x) > 5.0 else 0.0
	_lean = lerpf(_lean, lean, 1.0 - exp(-delta * 8.0))
	visual.skew = _lean
	if drunk:
		visual.skew += sin(_t * 1.3) * 0.06 + sin(_t * 2.9) * 0.02
		visual.position.x += sin(_t * 0.8) * 1.2
	_dip = move_toward(_dip, 0.0, delta * 3.0)
	if _dip > 0.0:
		visual.position.y += 2.5 * _dip
		visual.scale.y *= 1.0 - 0.1 * _dip
	eyes.animation = sprite.animation
	eyes.frame = sprite.frame
	eyes.flip_h = sprite.flip_h
	eyes.offset = sprite.offset
	# eyes are purple pixels in the sprite; this mask paints them red in Singularity
	_sing_k = move_toward(_sing_k, 1.0 if singularity_t > 0.0 else 0.0, delta * 2.5)
	eyes.visible = not _back and _sing_k > 0.01
	eyes.modulate = Color(SING_EYES, _sing_k * (0.85 + 0.15 * sin(_t * 9.0)))
	glow.color = Color(0.7, 0.55, 1.0).lerp(Color(1.0, 0.1, 0.05), _sing_k)
	glow.energy = 0.35 + 0.6 * _sing_k * (0.8 + 0.2 * sin(_t * 9.0)) if not dead else 0.1
	_tint.color.a = 0.2 * _sing_k
	_update_charge_fx()


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
	_rune_t -= delta
	if _rune_t <= 0.0:
		if singularity_t > 0.0:
			# a churning swarm of runes around her while the Singularity holds
			_rune_t = 0.04
			var a := randf() * TAU
			var rr := r_inner() * randf_range(0.6, 2.2)
			Fx.runes(global_position + Vector2(cos(a) * rr, sin(a) * rr * ELLIPSE), 2, Vector2(3, 2), 18.0, 1.1)
		elif send_charge >= 0.0 or draw_charge >= 0.0 or throw_charge >= 0.0 or snap_charge >= 0.0:
			_rune_t = 0.14
			Fx.runes(hand_tip() if snap_charge < 0.0 else global_position, 1, Vector2(9, 6), 8.0, 0.7)
	if singularity_t > 0.0:
		singularity_t -= delta
		if singularity_t <= 0.0:
			Sfx.play("flip_crush", 0.0, -6.0)
			if _sing_smoke:
				var old := _sing_smoke
				old.emitting = false
				for c in old.get_children():
					c.emitting = false
				get_tree().create_timer(2.0).timeout.connect(old.queue_free)
				_sing_smoke = null
	_field_k = lerpf(_field_k, SING_RADIUS if singularity_t > 0.0 else 1.0, 1.0 - exp(-delta * 6.0))
	if _sing_smoke:
		_sing_smoke.emission_sphere_radius = R_INNER * 0.7
	if dead:
		_snap_fx.emitting = false
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		move_and_slide()
		_update_visual(delta)
		return
	var target: Vector2 = aim_point if aim_point != null else get_global_mouse_position()
	aim = (target - global_position + Vector2(0, 20)).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT * facing
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down") if not frozen else Vector2.ZERO
	var charging := send_charge >= 0.0 or draw_charge >= 0.0 or jump_charge >= 0.0
	var sprinting := sprint_enabled and not charging and not frozen and Input.is_action_pressed("sprint")
	var spd := SPEED * (0.45 if charging else (SPRINT if sprinting else 1.0)) * move_mult
	velocity = velocity.move_toward(dir * spd, ACCEL * delta * (0.35 if z > 0.0 else 1.0))
	collision_mask = 8 if z > 6.0 else 1 | 8
	move_and_slide()
	var impact := _update_z(delta)
	if impact > 0.0:
		_land()
	if Input.is_action_just_pressed("interact") and not frozen:
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
		snap_charge = 0.0
		_snap_fx.emitting = true
		Sfx.play("pull_wave", 0.1, -16.0, 1.6)
	if snap_charge >= 0.0:
		snap_charge = minf(snap_charge + delta, SNAP_MAX_CHARGE)
		squash = 0.08 + 0.12 * snap_charge / SNAP_MAX_CHARGE
		_snap_fx.emission_sphere_radius = lerpf(16.0, 9.0, snap_charge / SNAP_MAX_CHARGE)
		if not Input.is_action_pressed("snap"):
			var k := snap_charge / SNAP_MAX_CHARGE
			snap_charge = -1.0
			squash = 0.0
			_snap_fx.emitting = false
			_teleport(dir.normalized() if dir.length() > 0.1 else aim, lerpf(SNAP_DIST, SNAP_MAX_DIST, k))
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
	if pose != "":
		_back = false
		play(pose)
		sprite.pause()
		sprite.frame = pose_frame
		return
	if _cast_t <= 0.0:
		_north = false
	if _north:
		play("cast_n")
		_back = true
		return
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
## Where her palm is in the casting pose, through the sprite's real transform (hover, lean, squash).
func hand_tip() -> Vector2:
	return global_position + visual.transform * _palm_local()


func _palm_local() -> Vector2:
	var a: Vector3 = anchors["cast"]
	var off := Vector2(-(a.z - a.x) if facing < 0 else -a.x, -a.y)
	var px := Vector2(a.z - PALM_PX.x if facing < 0 else PALM_PX.x, PALM_PX.y)
	return off + px


## The red witch's charge, in violet: a rune circle gathering into a spark at her palm, dust at her feet.
func _update_charge_fx() -> void:
	var k := -1.0
	for c in [send_charge / SEND_MAX_CHARGE if send_charge >= 0.0 else -1.0,
			draw_charge / DRAW_MAX_CHARGE if draw_charge >= 0.0 else -1.0,
			throw_charge / THROW_MAX_CHARGE if throw_charge >= 0.0 else -1.0]:
		k = maxf(k, c)
	var jumping := jump_charge >= 0.0
	charge_hand.visible = k >= 0.0 and not dead
	charge_dust.visible = (k >= 0.0 or jumping) and not dead
	if jumping and k < 0.0:
		k = jump_charge / JUMP_MAX_CHARGE
	if k < 0.0:
		return
	var f := 2 + int(k * 7.0) if k < 1.0 else 6 + int(_t * 10.0) % 4
	charge_hand.frame = mini(f, 9)
	charge_dust.frame = mini(f, 9)
	charge_hand.flip_h = facing < 0
	charge_hand.offset = Vector2(-32 if facing < 0 else -8, -16)
	charge_hand.position = visual.transform * _palm_local()
	charge_dust.flip_h = facing < 0
	charge_dust.offset = Vector2(-46 if facing < 0 else -44, -18)


func _pierce() -> void:
	cooldowns.pierce = PIERCE_CD
	_cast_t = 0.42
	_dip = 1.0
	_north = aim.y < -NORTH_COS
	var tip: Vector2
	if _north:
		# facing away: no hands, the beam leaves from in front of her
		play("cast_n", true)
		tip = global_position + Vector2(0, -24.0 - z - hover)
	else:
		if aim.x != 0.0:
			facing = 1 if aim.x > 0 else -1
		play("cast_back" if _back else "cast", true)
		tip = hand_tip()
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
	Fx.beam(tip, dir, length, _north, PIERCE_BAND)
	Fx.runes_line(tip, tip + dir * length, int(clampf(length / 22.0, 3.0, 10.0)), PIERCE_BAND, _north)
	Sfx.play("beam", 0.08, -8.0)
	# the beam is a thin core inside a wider, unseen band of gravity: the band hurts too and shoves aside
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.dormant:
			continue
		var c: Vector2 = e.global_position - Vector2(0, e.z + e.body_height * 0.5)
		var t := clampf((c - tip).dot(dir), 0.0, length)
		var on := tip + dir * t
		var d := on.distance_to(c)
		if d < e.hit_radius + 4.0:
			e.hit(PIERCE_DMG, dir * 50.0)
			Fx.anim("cross", c + Vector2(0, e.body_height * 0.5), 0.5, Color.WHITE, e.body_height * 0.5)
		elif d < e.hit_radius + PIERCE_BAND:
			var away := (c - on).normalized() if d > 0.5 else dir.orthogonal()
			e.hit(PIERCE_DMG * 0.6, away * 140.0)
	for n in get_tree().get_nodes_in_group("immune"):
		var c2: Vector2 = n.global_position
		var t2 := clampf((c2 - ground).dot(dir), 0.0, length + 10.0)
		if (ground + dir * t2).distance_to(c2) < n.get_meta("radius", 20.0) + PIERCE_BAND:
			n.get_meta("on_hit").call()


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
			Fx.runes_line(held.global_position, held.global_position + aim * 70.0, 4 + int(4 * k), 8.0)
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
	Fx.runes(best.global_position + Vector2(0, -best.body_height * 0.5), 5, Vector2(12, 8), 10.0, 0.9)
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
	for n in get_tree().get_nodes_in_group("immune"):
		if field_dist(n.global_position) < rng + n.get_meta("radius", 20.0):
			n.get_meta("on_hit").call()
	Fx.wave(global_position, r_inner(), rng, 0.35 + 0.1 * k, false)
	_rune_ring(rng * 0.75, 10)
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
	_rune_ring(rng * 0.6, 10)
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
		Fx.runes(targets[i].global_position + Vector2(0, -targets[i].body_height * 0.5), 6, Vector2(10, 8), 14.0, 1.0)


func _singularity() -> void:
	mana -= SING_COST
	singularity_t = SING_TIME
	cooldowns.singularity = SING_CD
	_cast_t = 0.5
	Sfx.play("singularity", 0.0, 0.0)
	Fx.shake(4.0)
	_sing_smoke = Fx.ground_smoke(self, R_INNER * 0.7)
	_rune_ring(r_inner() * 1.6, 24)


func _jump(k: float) -> void:
	jump_charge = -1.0
	squash = 0.0
	vz = lerpf(JUMP_VZ.x, JUMP_VZ.y, k)
	z = 0.5
	cooldowns.jump = 0.2
	velocity *= 1.15
	Sfx.play("jump", 0.08, -6.0)
	Fx.runes(global_position, 3, Vector2(10, 4), 6.0, 0.7, true)
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


func _rune_ring(radius: float, n: int) -> void:
	for i in n:
		var a := i * TAU / n + randf_range(-0.2, 0.2)
		Fx.runes(global_position + Vector2(cos(a) * radius, sin(a) * radius * ELLIPSE), 1, Vector2(3, 2), 10.0, randf_range(0.7, 1.1))


func _teleport(dir: Vector2, dist := SNAP_DIST) -> void:
	var from := global_position
	var to := from + dir * dist
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1 | 8
	var step := 0.0
	while step < dist:
		q.transform = Transform2D(0, from.lerp(to, 1.0 - step / dist))
		if space.intersect_shape(q, 1).is_empty():
			break
		step += 4.0
	if step >= dist:
		return
	to = from.lerp(to, 1.0 - step / dist)
	cooldowns.snap = SNAP_CD
	_iframes = 0.3
	send_charge = -1.0
	draw_charge = -1.0
	Fx.implode(from)
	Fx.runes(from, 4, Vector2(8, 5), 10.0, 0.8)
	var lunging := velocity.length() > 20.0
	# afterimages strung along the path, so the jump reads as a burst of speed
	for i in 4:
		var g := Sprite2D.new()
		g.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		g.centered = false
		g.flip_h = sprite.flip_h
		g.offset = sprite.offset
		g.skew = visual.skew
		g.position = from.lerp(to, (i + 1) / 5.0) + Vector2(0, -z - hover)
		g.modulate = Color(0.25, 0.12, 0.45, 0.5 - i * 0.08) if lunging else Color(0.25, 0.12, 0.45, 0.0)
		g.z_index = -1
		Fx.world.add_child(g)
		var gt := g.create_tween()
		gt.tween_property(g, "modulate:a", 0.0, 0.25 + i * 0.05)
		gt.tween_callback(g.queue_free)
	global_position = to
	velocity = dir * SPEED * 0.5
	reset_physics_interpolation()
	Fx.displace(to, self)
	Fx.runes(to, 5, Vector2(10, 6), 14.0, 0.9)
	Sfx.play("snap_click", 0.05, -6.0)
	visual.scale = Vector2(1.5, 0.75) if lunging and absf(dir.x) > 0.4 else Vector2(0.5, 1.4)
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


func gain_mana(amount: float) -> void:
	mana = minf(100.0, mana + amount)
