class_name Witch
extends CharacterBody3D

signal hp_changed(hp: float, max_hp: float)
signal toast(text: String)

enum FieldMode { CRUSH, LIFT }

const MODEL_PATH := "res://models/witch.glb"
const CRUSH_COLOR := Color(0.62, 0.42, 1.0)
const LIFT_COLOR := Color(0.36, 0.85, 1.0)
const GOLD := Color(1.0, 0.78, 0.25)

var rig: CameraRig
var field_on := true
var field_mode := FieldMode.CRUSH
var hp := 100.0
var whisky := 3
var spawn_point := Vector3.ZERO

var pierce_cd := 0.0
var snap_cd := 0.0

var _model: Node3D
var _staff: Node3D
var _staff_tip: Node3D
var _aura_mats: Array[StandardMaterial3D] = []
var _field_root: Node3D
var _field_spinner: Node3D
var _field_fill: StandardMaterial3D
var _field_edge: StandardMaterial3D
var _field_particles: GPUParticles3D
var _field_process: ParticleProcessMaterial
var _field_dot: StandardMaterial3D

var _coyote := 0.0
var _jump_buffer := 0.0
var _double_used := false
var _charging := 0.0
var _snap_time := 0.0
var _snap_vel := Vector3.ZERO
var _invuln := 0.0
var _face_cam := 0.0
var _hurt_flash := 0.0
var _contact_accum := 0.0
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
	reset_stats()


func reset_stats() -> void:
	hp = Game.witch_max_hp()
	whisky = Game.balance.whisky_count
	hp_changed.emit(hp, Game.witch_max_hp())


func is_invulnerable() -> bool:
	return _invuln > 0.0


func snap_rank() -> int:
	return clampi(Game.balance.snap_rank, 0, Game.balance.snap_distance.size() - 1)


func pierce_rank() -> int:
	return clampi(Game.balance.pierce_rank, 0, Game.balance.pierce_base_damage.size() - 1)


# ---------- damage ----------
func take_damage(amount: float, kind: String) -> void:
	if _invuln > 0.0:
		if kind != "contact":
			Art.popup(get_parent(), global_position + Vector3(0, 2.2, 0), "DODGED", GOLD, 48)
		return
	hp -= amount
	if kind == "contact":
		_contact_accum += amount
		if _contact_accum >= 1.0:
			Art.popup(get_parent(), global_position + Vector3(0, 2.0, 0), str(int(_contact_accum)), Color(1, 0.4, 0.35), 44)
			_contact_accum = 0.0
	else:
		_hurt_flash = 0.15
		Art.popup(get_parent(), global_position + Vector3(0, 2.0, 0), str(int(amount)), Color(1, 0.35, 0.3), 56)
	hp_changed.emit(hp, Game.witch_max_hp())
	if hp <= 0.0:
		toast.emit("She went down. Back to the start with a fresh bottle.")
		global_position = spawn_point
		velocity = Vector3.ZERO
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
	var heal := Game.witch_max_hp() * Game.balance.whisky_heal_pct
	hp = minf(Game.witch_max_hp(), hp + heal)
	Art.popup(get_parent(), global_position + Vector3(0, 2.2, 0), "+%d" % int(heal), Color(1, 0.75, 0.3), 56)
	hp_changed.emit(hp, Game.witch_max_hp())


# ---------- main loop ----------
func _physics_process(delta: float) -> void:
	var b := Game.balance
	_t += delta
	pierce_cd = maxf(0.0, pierce_cd - delta)
	snap_cd = maxf(0.0, snap_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_face_cam = maxf(0.0, _face_cam - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := rig.yaw if rig else 0.0
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw)

	_handle_abilities()

	if _snap_time > 0.0:
		_snap_time -= delta
		velocity = _snap_vel
		move_and_slide()
		if _snap_time <= 0.0:
			velocity = _snap_vel.normalized() * b.walk_speed
			velocity.y = 0.0
		_update_visuals(delta, dir)
		return

	if Input.is_action_just_pressed("snap") and snap_cd <= 0.0:
		_start_snap(dir)
		_update_visuals(delta, dir)
		return

	var on_floor := is_on_floor()
	if on_floor:
		_coyote = b.coyote_time
		_double_used = false
	else:
		_coyote -= delta
	_jump_buffer = b.jump_buffer if Input.is_action_just_pressed("jump") else _jump_buffer - delta

	if _charging > 0.0:
		_charging -= delta
		velocity = velocity.lerp(Vector3.ZERO, minf(1.0, delta * 20.0))
		if _charging <= 0.0:
			velocity.y = b.double_jump_velocity
			Art.burst(get_parent(), global_position + Vector3(0, 0.3, 0), CRUSH_COLOR if field_mode == FieldMode.CRUSH else LIFT_COLOR, 30)
		move_and_slide()
		_update_visuals(delta, dir)
		return

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = b.jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0
	elif _jump_buffer > 0.0 and not on_floor and not _double_used:
		_double_used = true
		_jump_buffer = 0.0
		_charging = b.double_jump_charge

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

	if global_position.y < -25.0:
		global_position = spawn_point
		velocity = Vector3.ZERO
		reset_physics_interpolation()

	_update_visuals(delta, dir)


func _handle_abilities() -> void:
	if Input.is_action_just_pressed("flip_gravity"):
		field_mode = FieldMode.LIFT if field_mode == FieldMode.CRUSH else FieldMode.CRUSH
		_apply_field_look()
	if Input.is_action_just_pressed("toggle_field"):
		field_on = not field_on
		_field_root.visible = field_on
		toast.emit("Gravity field %s" % ("on" if field_on else "off"))
	if Input.is_action_pressed("pierce") and pierce_cd <= 0.0:
		_pierce()
	if Input.is_action_just_pressed("drink_whisky"):
		drink()
	for a in ["send", "draw", "rend", "singularity"]:
		if Input.is_action_just_pressed(a):
			toast.emit("%s arrives in the next milestone" % a.capitalize())


# ---------- abilities ----------
func _start_snap(dir: Vector3) -> void:
	var b := Game.balance
	var r := snap_rank()
	var d := dir.normalized() if dir.length() > 0.1 else _model.global_basis.z.normalized()
	d.y = 0.0
	d = d.normalized()
	var dur: float = b.snap_duration[r]
	var dist: float = b.snap_distance[r]
	_snap_vel = d * (dist / dur)
	_snap_time = dur
	_invuln = dur + b.snap_iframe_padding
	snap_cd = b.snap_cooldown
	var from := global_position + Vector3(0, 1.0, 0)
	var width := 0.9 - r * 0.38
	Art.streak(get_parent(), from, from + d * dist, CRUSH_COLOR.lerp(GOLD, 0.35), width, 0.25 + r * 0.05)


func _pierce() -> void:
	var b := Game.balance
	var r := pierce_rank()
	pierce_cd = b.pierce_cooldown
	_face_cam = 0.6
	var cam := rig.camera
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := cam.project_ray_origin(center)
	var ray_dir := cam.project_ray_normal(center)
	var reach: float = b.pierce_range[r] + rig.arm.spring_length
	var q := PhysicsRayQueryParameters3D.create(origin, origin + ray_dir * reach, 1 | 4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end: Vector3 = hit.position if hit else origin + ray_dir * reach
	if hit and hit.collider is Enemy:
		var e: Enemy = hit.collider
		e.take_damage(Game.scaled_damage(b.pierce_base_damage[r], e.level), "pierce")
	Art.streak(get_parent(), _staff_tip.global_position, end, Color(0.85, 0.7, 1.0), 0.06, 0.12)


# ---------- visuals ----------
func _update_visuals(delta: float, dir: Vector3) -> void:
	var b := Game.balance
	var bob := sin(_t * 2.2) * 0.12
	_model.position.y = b.hover_height + bob
	var face := _model.rotation.y
	if _face_cam > 0.0:
		var f := rig.forward()
		face = atan2(f.x, f.z)
	elif dir.length() > 0.05:
		face = atan2(dir.x, dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, face, minf(1.0, delta * b.turn_speed))
	var lean := 0.12 if Vector3(velocity.x, 0, velocity.z).length() > 1.0 else 0.0
	_model.rotation.x = lerpf(_model.rotation.x, lean, minf(1.0, delta * 8.0))
	_staff.position.y = 1.35 + sin(_t * 1.6 + 1.0) * 0.1
	_staff.rotation.z = sin(_t * 1.1) * 0.06
	var flicker := 0.3 + (sin(_t * 9.0) * 0.5 + 0.5) * 0.25 * randf_range(0.8, 1.2)
	if _snap_time > 0.0:
		flicker = 0.9
	for m in _aura_mats:
		m.albedo_color = Color(1.0, 0.25, 0.2, 0.8) if _hurt_flash > 0.0 else Color(GOLD, flicker)
	_model.visible = not (_snap_time > 0.0 and snap_rank() == 2)
	_field_spinner.rotation.y += delta * (0.8 if field_mode == FieldMode.CRUSH else -0.8)
	var pulse := 1.0 + sin(_t * 3.0) * 0.02
	_field_spinner.scale = Vector3(pulse, 1, pulse)


func _apply_field_look() -> void:
	var c := CRUSH_COLOR if field_mode == FieldMode.CRUSH else LIFT_COLOR
	_field_fill.albedo_color = Color(c, 0.1)
	_field_edge.albedo_color = Color(c, 0.75)
	_field_dot.albedo_color = Color(c, 0.9)
	var r := Game.balance.field_radius
	if field_mode == FieldMode.CRUSH:
		_field_process.gravity = Vector3(0, -9, 0)
		_field_process.emission_shape_offset = Vector3(0, 3.5, 0)
	else:
		_field_process.gravity = Vector3(0, 5, 0)
		_field_process.emission_shape_offset = Vector3(0, 0.1, 0)
	_field_process.emission_ring_radius = r
	toast.emit("Gravity: %s" % ("Crush" if field_mode == FieldMode.CRUSH else "Lift"))


func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	if ResourceLoader.exists(MODEL_PATH):
		var scene: PackedScene = load(MODEL_PATH)
		_model.add_child(scene.instantiate())
	else:
		_build_placeholder()
	_staff = Node3D.new()
	_staff.position = Vector3(0.45, 1.35, -0.75)
	_model.add_child(_staff)
	var wood := Art.mat(Color(0.42, 0.27, 0.15))
	var gold := Art.mat(GOLD, Color(0.25, 0.15, 0.0))
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.05
	shaft.bottom_radius = 0.07
	shaft.height = 3.0
	shaft.radial_segments = 6
	Art.mesh(shaft, wood, Vector3.ZERO, _staff)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.14
	ring.outer_radius = 0.2
	ring.rings = 8
	ring.ring_segments = 4
	Art.mesh(ring, gold, Vector3(0, 1.55, 0), _staff).rotation.x = PI / 2
	var orb := SphereMesh.new()
	orb.radius = 0.16
	orb.height = 0.32
	orb.radial_segments = 6
	orb.rings = 3
	_staff_tip = Art.mesh(orb, Art.glow(Color(0.8, 0.6, 1.0), 1.0), Vector3(0, 1.55, 0), _staff)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.55, 1.0)
	light.light_energy = 1.4
	light.omni_range = 5.0
	light.position = Vector3(0, 1.55, 0)
	_staff.add_child(light)
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
	dot.size = Vector2(0.06, 0.06)
	gp.draw_pass_1 = dot
	gp.material_override = Art.glow(GOLD, 1.0, true)
	gp.amount = 60
	gp.lifetime = 1.8
	gp.position.y = 0.1
	_model.add_child(gp)


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
	_field_fill.no_depth_test = false
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
