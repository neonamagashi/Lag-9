extends Node

var main: Node
var w: Witch


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = Game.witch
	get_tree().call_group("enemies", "queue_free")
	await _frames(60)
	print("spawn: pos %s on_floor %s" % [_v(w.global_position), w.is_on_floor()])
	w.field_on = false

	_teleport(Vector3(14, 1.0, 2.0))
	await _frames(20)
	var best := 0.0
	for i in 12:
		await _climb_toward(Vector3(14, 0, -30))
		best = maxf(best, w.global_position.y)
	print("terraces: reached y %.1f (plateau is 14) at %s" % [best, _v(w.global_position)])

	_teleport(Vector3(-6, 1.0, -8))
	await _frames(20)
	var route := [Vector3(-6.8, 0, -15.5), Vector3(-8.8, 0, -20), Vector3(-11, 0, -22.5), Vector3(-13, 0, -24),
		Vector3(-15.5, 0, -22), Vector3(-19, 0, -18), Vector3(-20.5, 0, -13.5), Vector3(-21, 0, -8)]
	var ok := true
	for p in route:
		ok = await _walk_to(p) and ok
	print("cave walk-through: %s, exit at %s" % ["clear" if ok else "BLOCKED", _v(w.global_position)])

	var cols: Array = []
	for k in range(1, 7):
		var a := 3.07 + (k - 1) * 0.65
		cols.append(Vector3(-13 + cos(a) * 4.1, 2.2 * k, -24 + sin(a) * 4.1))
	_teleport(Vector3(-13, 0.6, -24))
	await _frames(20)
	var heights := []
	for c in cols:
		for attempt in 4:
			await _climb_toward(c)
			if w.global_position.y > c.y - 0.5:
				break
		heights.append(snappedf(w.global_position.y, 0.1))
	var last: Vector3 = cols[5]
	var out := Vector3(-13, 0, -24) + (Vector3(last.x + 13, 0, last.z + 24)).normalized() * 9.0
	for attempt in 4:
		await _climb_toward(out)
	heights.append(snappedf(w.global_position.y, 0.1))
	print("cave columns climb heights: %s (shaft exits at 14)" % [heights])

	_teleport(Vector3(-2.5, 1.0, 10.5))
	await _frames(20)
	var bh := []
	for i in 3:
		await _climb_toward(Vector3(-3.2, 0, 4.5))
		bh.append(snappedf(w.global_position.y, 0.1))
	print("boulder stack climb: %s (tops 1.7 then 3.7)" % [bh])
	get_tree().quit()


func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _teleport(p: Vector3) -> void:
	w.global_position = p
	w.velocity = Vector3.ZERO
	w.flying = false
	w.reset_physics_interpolation()


func _face(target: Vector3) -> void:
	var d := target - w.global_position
	w.rig.yaw = atan2(-d.x, -d.z)


func _climb_toward(target: Vector3) -> void:
	_face(target)
	Input.action_press("move_forward")
	for i in 8:
		_face(target)
		await get_tree().physics_frame
	Input.action_press("jump")
	for i in 4:
		_face(target)
		await get_tree().physics_frame
	Input.action_release("jump")
	for i in 30:
		_face(target)
		await get_tree().physics_frame
	Input.action_release("move_forward")
	await _frames(10)


func _walk_to(target: Vector3) -> bool:
	Input.action_press("move_forward")
	var t := 0
	while t < 240:
		_face(target)
		await get_tree().physics_frame
		t += 1
		var flat := Vector2(w.global_position.x - target.x, w.global_position.z - target.z)
		if flat.length() < 1.2:
			break
	Input.action_release("move_forward")
	return t < 240
