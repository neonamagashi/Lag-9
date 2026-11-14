class_name Projectile
extends Node3D

const SPEEDS := {"fireball": 11.0, "void": 7.0, "arrow": 26.0}
const COLORS := {"fireball": Color(1.0, 0.5, 0.15), "void": Color(0.45, 0.95, 0.9), "arrow": Color(1.0, 0.25, 0.2)}

static var _meshes := {}
static var stats := {"fired": 0, "crushed": 0, "hit": 0}

var kind := "fireball"
var velocity := Vector3.ZERO
var damage := 10.0
var physical := true
var _life := 5.0
var _t := 0.0
var _body: Node3D


func launch(k: String, from: Vector3, target: Vector3, dmg: float) -> Projectile:
	kind = k
	damage = dmg
	physical = kind != "void"
	velocity = (target - from).normalized() * SPEEDS.get(kind, 10.0)
	return self


func _ready() -> void:
	add_to_group("projectiles")
	stats["fired"] += 1
	_build()
	if kind == "arrow" and velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP if absf(velocity.normalized().y) < 0.95 else Vector3.RIGHT)


func _build() -> void:
	if _meshes.is_empty():
		var orb := SphereMesh.new()
		orb.radius = 0.18
		orb.height = 0.36
		orb.radial_segments = 8
		orb.rings = 4
		var shaft := BoxMesh.new()
		shaft.size = Vector3(0.04, 0.04, 0.75)
		var tip := BoxMesh.new()
		tip.size = Vector3(0.08, 0.08, 0.12)
		_meshes = {"orb": orb, "shaft": shaft, "tip": tip}
	_body = Node3D.new()
	add_child(_body)
	var c: Color = COLORS.get(kind, Color.WHITE)
	match kind:
		"arrow":
			Art.mesh(_meshes.shaft, Art.mat(Color(0.86, 0.82, 0.72)), Vector3.ZERO, _body)
			Art.mesh(_meshes.tip, Art.glow(c, 1.0), Vector3(0, 0, -0.42), _body)
		"void":
			Art.mesh(_meshes.orb, Art.glow(Color(0.3, 0.1, 0.5), 1.0), Vector3.ZERO, _body)
			var halo := Art.mesh(_meshes.orb, Art.glow(c, 0.6), Vector3.ZERO, _body)
			halo.scale = Vector3.ONE * 1.6
		_:
			Art.mesh(_meshes.orb, Art.glow(c, 1.0), Vector3.ZERO, _body)
			var core := Art.mesh(_meshes.orb, Art.glow(Color(1.0, 0.9, 0.5), 1.0), Vector3.ZERO, _body)
			core.scale = Vector3.ONE * 0.55


func _physics_process(delta: float) -> void:
	var w := Game.witch
	var dt := delta * Game.enemy_time_scale
	_life -= dt
	_t += dt
	if _life <= 0.0 or not w:
		queue_free()
		return
	if kind == "void":
		var want := (w.field_center() - global_position).normalized() * float(SPEEDS["void"])
		velocity = velocity.slerp(want, minf(1.0, 0.9 * dt))
		_body.scale = Vector3.ONE * (1.0 + sin(_t * 12.0) * 0.15)
	elif kind == "fireball":
		_body.rotation += Vector3(4, 6, 0) * dt
	var next := global_position + velocity * dt
	var q := PhysicsRayQueryParameters3D.create(global_position, next, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		_pop(hit.position, "projectile_crushed", -6.0)
		return
	global_position = next
	if kind == "arrow" and velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP if absf(velocity.normalized().y) < 0.95 else Vector3.RIGHT)
	var dist := global_position.distance_to(w.field_center())
	if physical and w.field_on and dist < w.field_radius():
		_crushed(w)
		return
	if dist < 0.75:
		stats["hit"] += 1
		w.take_damage(damage, "projectile")
		_pop(global_position, "impact", -4.0)


func _crushed(w: Witch) -> void:
	var c: Color = COLORS.get(kind, Color.WHITE)
	if w.field_mode == Witch.FieldMode.LIFT:
		Art.ring_pulse(get_parent(), global_position, Witch.LIFT_COLOR, 0.8, 0.25)
	else:
		Art.ring_pulse(get_parent(), global_position, Witch.CRUSH_COLOR, 0.8, 0.25)
	Art.burst(get_parent(), global_position, c, 16)
	Sfx.play("projectile_crushed", global_position, 0.1, -3.0)
	stats["crushed"] += 1
	queue_free()


func _pop(pos: Vector3, sound: String, vol: float) -> void:
	Art.burst(get_parent(), pos, COLORS.get(kind, Color.WHITE), 12)
	Sfx.play(sound, pos, 0.1, vol)
	queue_free()
