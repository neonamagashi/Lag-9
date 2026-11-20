extends Node

var main: Node
var w: Witch


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	await _frames(10)
	await _mechanics()
	await _autoplay()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _press(a: String, frames := 3) -> void:
	Input.action_press(a)
	await _frames(frames)
	Input.action_release(a)


func _enemy(kind: String, p: Vector2) -> Enemy:
	var e := Enemy.new().setup(kind)
	e.position = p
	main.world.add_child(e)
	await _frames(2)
	return e


func _clear() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dormant:
			e.remove_from_group("enemies")
			e.queue_free()
	await _frames(2)


func _mechanics() -> void:
	main.cleared = true
	w.global_position = Vector2(272, 250)
	var rat := await _enemy("rat", w.global_position + Vector2(20, 0))
	await _frames(120)
	print("crush: rat inside field dead after 2s = %s" % rat.dead)
	await _clear()

	var slime := await _enemy("slime", w.global_position + Vector2(25, 0))
	await _press("flip")
	await _frames(60)
	print("lift: slime z after 1s = %.1f (lifted %s)" % [slime.z, slime.lifted])
	var hp0 := slime.hp
	await _press("flip")
	await _frames(40)
	print("slam: slime hp %.0f -> %.0f" % [hp0, slime.hp])
	await _clear()

	w.global_position = Vector2(80, 200)
	var rat2 := await _enemy("rat", Vector2(110, 200))
	rat2.cfg = rat2.cfg.duplicate()
	w.mode = Witch.Mode.LIFT
	w.aim_point = Vector2(560, 200)
	var hp1 := rat2.hp
	rat2.global_position = Vector2(400, 200)
	w.global_position = Vector2(350, 200)
	w._field_r = 1.0
	await _frames(1)
	Input.action_press("send")
	await _frames(50)
	Input.action_release("send")
	await _frames(70)
	print("send: rat hp %.0f -> %.0f, x %.0f (east wall ~464)" % [hp1, rat2.hp, rat2.global_position.x])
	await _clear()

	w.mode = Witch.Mode.CRUSH
	w.global_position = Vector2(272, 250)
	var bat := await _enemy("bat", w.global_position + Vector2(90, 0))
	await _frames(30)
	var bz := bat.z
	bat.global_position = w.global_position + Vector2(25, 0)
	await _frames(40)
	print("bat: flying z %.0f -> in crush field z %.0f, stunned %s" % [bz, bat.z, bat._stun_t > 0.0])
	await _clear()

	var mimic: Enemy = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "mimic":
			mimic = e
	var was := mimic.dormant
	w.global_position = mimic.global_position + Vector2(-40, 10)
	await _frames(150)
	var whp := w.hp
	await _frames(180)
	print("mimic: dormant %s -> %s, anim %s; witch hp next to it %.0f -> %.0f" % [was, mimic.dormant, mimic.sprite.animation, whp, w.hp])
	mimic.remove_from_group("enemies")
	mimic.queue_free()

	var targets := []
	for i in 5:
		targets.append(await _enemy("slime", Vector2(140 + i * 50, 120)))
	w.global_position = Vector2(272, 260)
	await _press("rend")
	await _frames(40)
	print("rend: slime hp %s" % [targets.map(func(e): return int(e.hp))])
	await _clear()
	w.hp = w.max_hp
	w.mode = Witch.Mode.CRUSH
	w._field_r = Witch.FIELD_RADIUS


func _autoplay() -> void:
	main.cleared = false
	main.wave = -1
	main.wave_alive = 0
	main._next_wave_t = 0.5
	w.global_position = Vector2(272, 290)
	var t := 0
	var min_hp := w.hp
	while t < 60 * 90 and not main.cleared and not w.dead:
		t += 1
		var near: Enemy = null
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or e.dormant:
				continue
			if not near or e.global_position.distance_to(w.global_position) < near.global_position.distance_to(w.global_position):
				near = e
		if near:
			w.aim_point = near.global_position + Vector2(0, -near.z - 8)
			var d := near.global_position.distance_to(w.global_position)
			if t % 20 < 12:
				Input.action_press("pierce")
			else:
				Input.action_release("pierce")
			if w.cooldowns.rend <= 0.0 and t % 30 == 0:
				Input.action_press("rend")
			else:
				Input.action_release("rend")
			if d < 40.0 and w.cooldowns.send <= 0.0 and t % 40 == 0:
				Input.action_press("send")
			elif t % 40 == 8:
				Input.action_release("send")
			if w.hp < 50 and w.whisky > 0 and t % 30 == 0:
				Input.action_press("whisky")
			else:
				Input.action_release("whisky")
			if w.mana >= Witch.SING_COST and get_tree().get_nodes_in_group("enemies").size() >= 5 and t % 60 == 0:
				Input.action_press("singularity")
			else:
				Input.action_release("singularity")
			Input.action_release("move_left")
			Input.action_release("move_right")
			if d < 30.0:
				Input.action_press("move_left" if near.global_position.x > w.global_position.x else "move_right")
		min_hp = minf(min_hp, w.hp)
		await get_tree().physics_frame
	for a in ["pierce", "rend", "send", "whisky", "singularity", "move_left", "move_right"]:
		Input.action_release(a)
	print("autoplay: cleared %s after %.1fs, wave %d, witch hp %.0f (low %.0f), whisky left %d, dead %s" % [main.cleared, t / 60.0, main.wave + 1, w.hp, min_hp, w.whisky, w.dead])
