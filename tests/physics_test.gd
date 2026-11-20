extends Node
## Grab squeeze/dangle, enemy-vs-enemy collisions, friendly fire and avoidance (Limbo's open void).

var main: Node
var w: Witch


func _ready() -> void:
	Game.level_choice = "limbo"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	await _frames(300)
	main.cleared = true
	w.abilities_enabled = true
	w.field_active = false
	w.global_position = Vector2(0, -300)
	await _frames(5)
	await _grab()
	await _throw()
	await _chain()
	await _friendly_fire()
	await _bombs()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _enemy(kind: String, off: Vector2, still := false) -> Enemy:
	var e := Enemy.new().setup(kind)
	e.position = w.global_position + off
	main.world.add_child(e)
	if still:
		e.set_meta("still", true)
	await _frames(2)
	return e


func _clear() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.remove_from_group("enemies")
		e.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_shots"):
		s.queue_free()
	w.aim_point = null
	await _frames(3)
	w.hp = w.max_hp
	w.global_position = Vector2(0, -300)


func _grab() -> void:
	var g := await _enemy("goblin", Vector2(90, 0))
	g._shot_cfg = {}
	w.aim_point = g.global_position
	Input.action_press("grab")
	await _frames(2)
	Input.action_release("grab")
	await _frames(30)
	var hp0 := g.hp
	var max_rot := 0.0
	var min_sx := 9.0
	var max_lag := 0.0
	for i in 60:
		var a := PI * i / 60.0
		w.aim_point = w.global_position + Vector2(cos(a), sin(a) * 0.6) * 100.0
		await get_tree().physics_frame
		max_rot = maxf(max_rot, absf(g.visual.rotation))
		min_sx = minf(min_sx, g.visual.scale.x / g.vis_scale)
		max_lag = maxf(max_lag, g.global_position.distance_to(w.hold_point()))
	print("grab: held %s, squeeze scale.x min %.2f, swing rotation max %.2f rad, lags hand by up to %.0f px, squeeze dmg %.0f in 1s, dangling z %.0f" % [w.held == g, min_sx, max_rot, max_lag, hp0 - g.hp, g.z])
	await _clear()


func _throw() -> void:
	var g := await _enemy("goblin", Vector2(60, 0))
	g._shot_cfg = {}
	var r := await _enemy("skeleton", Vector2(220, 0))
	r._shot_cfg = {}
	r._stun_t = 99.0
	w.aim_point = g.global_position
	Input.action_press("grab")
	await _frames(2)
	Input.action_release("grab")
	await _frames(20)
	w.aim_point = r.global_position - Vector2(0, 20)
	await _frames(20)
	var rp := r.global_position
	var rhp := r.hp
	Input.action_press("grab")
	await _frames(40)
	Input.action_release("grab")
	await _frames(50)
	print("throw goblin into skeleton: skeleton hp %.0f -> %.0f, knocked %.0f px; goblin hp %.0f, bounced %s" % [rhp, r.hp, r.global_position.distance_to(rp), g.hp, g.velocity.length() < 200.0])
	await _clear()


func _chain() -> void:
	var a := await _enemy("rat", Vector2(70, 0))
	var b := await _enemy("rat", Vector2(185, 0))
	var c := await _enemy("rat", Vector2(260, 0))
	for e in [a, b, c]:
		e._stun_t = 99.0
	var bp := b.global_position
	var cp := c.global_position
	Input.action_press("send")
	await _frames(40)
	Input.action_release("send")
	await _frames(60)
	print("chain push: rat A hp %.0f, rat B (out of range) hp %.0f moved %.0f px, rat C hp %.0f moved %.0f px" % [a.hp, b.hp, b.global_position.distance_to(bp), c.hp, c.global_position.distance_to(cp)])
	await _clear()


func _friendly_fire() -> void:
	var eye := await _enemy("flying_eye", Vector2(200, 0))
	var rat := await _enemy("rat", Vector2(100, 0))
	rat._stun_t = 99.0
	rat.z = 0.0
	eye._cd = 0.0
	var ep := eye.global_position
	var shots := 0
	for i in 40:
		await get_tree().physics_frame
		shots = maxi(shots, get_tree().get_nodes_in_group("enemy_shots").size())
	print("line of fire: ally between eye and witch -> eye fired %d shots, strafed %.0f px sideways" % [shots, absf(eye.global_position.y - ep.y)])
	eye.queue_free()
	await _frames(2)
	rat.global_position = w.global_position + Vector2(100, 0)
	var hp0 := rat.hp
	var whp := w.hp
	var s := EnemyShot.new()
	s.setup("sword", w.global_position + Vector2(200, 0), w.global_position, rat.body_height * 0.5)
	main.world.add_child(s)
	await _frames(90)
	print("friendly fire: thrown sword hit the rat in the way: rat hp %.0f -> %.0f, witch hp %.0f -> %.0f" % [hp0, rat.hp, whp, w.hp])
	await _clear()


func _bombs() -> void:
	var stuck := await _enemy("rat", Vector2(120, 40))
	stuck._stun_t = 99.0
	var free := await _enemy("skeleton", Vector2(-120, 40))
	free._shot_cfg = {}
	var hp_s := stuck.hp
	var hp_f := free.hp
	var fp := free.global_position
	for target in [stuck.global_position, free.global_position]:
		var b := EnemyShot.new()
		b.setup("bomb", target + Vector2(0, -160), target, 20.0)
		main.world.add_child(b)
	await _frames(120)
	print("bomb splash: stunned rat hp %.0f -> %.0f; free skeleton dodged %.0f px, hp %.0f -> %.0f" % [hp_s, stuck.hp, free.global_position.distance_to(fp), hp_f, free.hp])
