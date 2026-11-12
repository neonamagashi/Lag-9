class_name Pickup
extends Node3D

enum Kind { MANA_ORB, MANA_BOTTLE, WHISKY }

const COLORS := {
	Kind.MANA_ORB: Color(0.35, 0.75, 1.0),
	Kind.MANA_BOTTLE: Color(0.35, 0.75, 1.0),
	Kind.WHISKY: Color(1.0, 0.7, 0.25),
}

var kind := Kind.MANA_ORB
var amount := 20.0
var _respawn := 0.0
var _body: Node3D
var _t := 0.0


func setup(k: Kind, amt: float) -> Pickup:
	kind = k
	amount = amt
	return self


func _ready() -> void:
	_t = randf() * TAU
	_body = Node3D.new()
	add_child(_body)
	var c: Color = COLORS[kind]
	if kind == Kind.MANA_ORB:
		var s := SphereMesh.new()
		s.radius = 0.18
		s.height = 0.36
		s.radial_segments = 6
		s.rings = 3
		Art.mesh(s, Art.glow(c, 1.0), Vector3.ZERO, _body)
	else:
		var bottle := CylinderMesh.new()
		bottle.top_radius = 0.16
		bottle.bottom_radius = 0.2
		bottle.height = 0.5
		bottle.radial_segments = 6
		Art.mesh(bottle, Art.mat(c.darkened(0.3), c * 0.6), Vector3(0, 0.25, 0), _body)
		var neck := CylinderMesh.new()
		neck.top_radius = 0.06
		neck.bottom_radius = 0.08
		neck.height = 0.2
		neck.radial_segments = 5
		Art.mesh(neck, Art.mat(c.darkened(0.5)), Vector3(0, 0.6, 0), _body)
	var light := OmniLight3D.new()
	light.light_color = c
	light.light_energy = 0.8
	light.omni_range = 2.5
	light.position.y = 0.4
	_body.add_child(light)


func _physics_process(delta: float) -> void:
	_t += delta
	if _respawn > 0.0:
		_respawn -= delta
		if _respawn <= 0.0:
			_body.visible = true
		return
	_body.position.y = 0.5 + sin(_t * 2.5) * 0.15
	_body.rotation.y += delta * 1.5
	var w := Game.witch
	if not w:
		return
	var target := w.global_position + Vector3(0, 1.0, 0)
	var d := global_position.distance_to(target)
	if kind == Kind.MANA_ORB and d < 7.0:
		global_position = global_position.move_toward(target, (14.0 - d) * delta)
	if d < 1.3:
		_collect(w)


func _collect(w: Witch) -> void:
	if kind == Kind.WHISKY:
		w.whisky += 1
		Art.popup(get_parent(), global_position + Vector3(0, 1, 0), "+1 Whisky", COLORS[kind], 44)
	else:
		if w.mana >= Game.balance.max_mana and kind == Kind.MANA_BOTTLE:
			return
		w.add_mana(amount)
		Art.popup(get_parent(), global_position + Vector3(0, 1, 0), "+%d mana" % int(amount), COLORS[kind], 44)
	if kind == Kind.MANA_BOTTLE:
		_body.visible = false
		_respawn = Game.balance.mana_bottle_respawn
	else:
		queue_free()
