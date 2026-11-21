extends Node

var main: Node
var w: Witch


func _ready() -> void:
	Game.level_choice = "ruins"
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


func _enemy(kind: String, off: Vector2, boss := false) -> Enemy:
	var e := Enemy.new().setup(kind)
	if boss:
		e.cfg = e.cfg.duplicate()
		e.cfg["boss"] = true
	e.position = w.global_position + off
	main.world.add_child(e)
	await _frames(2)
	return e


func _clear() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dormant:
			e.remove_from_group("enemies")
			e.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_shots"):
		s.queue_free()
	await _frames(2)
	w.hp = w.max_hp
	w.mode = Witch.Mode.CRUSH
	w.global_position = main.START * main.level.tile


func _mechanics() -> void:
	main.cleared = true
	await _clear()
	print("zones (px): inner %.1f  mid %.1f  outer %.1f" % [w.r_inner(), w.r_mid(), w.r_outer()])

	var goblin := await _enemy("goblin", Vector2(110, 0))
	goblin._shot_cfg = {}
	var closest := 999.0
	for i in 240:
		await get_tree().physics_frame
		closest = minf(closest, w.field_dist(goblin.global_position))
	print("barrier: goblin chasing for 4s got as close as %.0f (mid ring %.0f), witch hp %.0f, goblin hp %.0f/%.0f" % [closest, w.r_mid(), w.hp, goblin.hp, goblin.max_hp])
	await _clear()

	var rat := await _enemy("rat", Vector2(8, 0))
	await _frames(3)
	print("inner ring: rat placed under her dead = %s" % rat.dead)
	await _clear()

	var slime := await _enemy("slime", Vector2(36, 0))
	await _frames(20)
	var p := slime.pinned
	await _frames(100)
	print("mid ring: slime pinned %s, anim %s frame %d, hp %.0f/%.0f after ~2s, witch hp %.0f" % [p, slime.sprite.animation, slime.sprite.frame, slime.hp, slime.max_hp, w.hp])
	await _clear()

	var g2 := await _enemy("goblin", Vector2(170, 0))
	await _frames(300)
	var crushed_hp := w.hp
	print("physical shots (goblin bombs): witch hp after 5s %.0f" % crushed_hp)
	await _clear()

	var eye := await _enemy("flying_eye", Vector2(150, 60))
	await _frames(300)
	print("magic shots (flying eye bolts): witch hp after 5s %.0f" % w.hp)
	await _clear()

	var targets := []
	for off in [Vector2(90, -20), Vector2(-90, 10), Vector2(100, 40), Vector2(-100, -40)]:
		targets.append(await _enemy("rat", off))
	targets[3].global_position = w.global_position + Vector2(170, 0)
	var mimic := await _enemy("mimic", Vector2(0, -60))
	mimic.dormant = false
	await _press("rend")
	await _frames(70)
	print("rend: 3 nearest of [rat, rat, rat, far rat, mimic]: dead %s" % [targets.map(func(e): return e.dead) + [mimic.dead]])
	await _clear()

	var start := w.global_position
	await _frames(2)
	Input.action_press("move_right")
	await _frames(2)
	await _press("snap", 2)
	await _frames(2)
	Input.action_release("move_right")
	print("teleport: moved %.0f px (max %d)" % [w.global_position.distance_to(start), Witch.SNAP_DIST])
	await _frames(60)
	w.global_position = Vector2(8.5, 10.5) * 32
	await _frames(2)
	var s2 := w.global_position
	Input.action_press("move_left")
	await _frames(2)
	await _press("snap", 2)
	await _frames(2)
	Input.action_release("move_left")
	print("teleport toward water/wall: moved %.0f px, now on open tile %s" % [w.global_position.distance_to(s2), main.level.open_at(w.global_position)])
	await _clear()

	var gob := await _enemy("goblin", Vector2(100, 0))
	gob._shot_cfg = {}
	w.aim_point = gob.global_position
	await _press("grab")
	await _frames(20)
	var held_ok := w.held == gob and gob.grabbed
	var hold_d := gob.global_position.distance_to(w.hold_point())
	w.aim_point = w.global_position + Vector2(-200, 0)
	await _frames(20)
	var followed := gob.global_position.x < w.global_position.x
	Input.action_press("grab")
	await _frames(40)
	Input.action_release("grab")
	await _frames(3)
	var vel := gob.velocity.length()
	await _frames(40)
	print("grab: held %s (%.0f px from hold point), follows aim %s, release speed %.0f, label now %s, goblin hp %.0f/%.0f" % [held_ok, hold_d, followed, vel, "Release" if w.held else "Grab", gob.hp, gob.max_hp])
	w.aim_point = null
	await _clear()

	var ring := []
	for a in 6:
		ring.append(await _enemy("rat", Vector2.RIGHT.rotated(a * TAU / 6) * Vector2(70, 40)))
	var d0: Array = ring.map(func(e): return w.field_dist(e.global_position))
	Input.action_press("send")
	await _frames(30)
	Input.action_release("send")
	await _frames(20)
	var d1: Array = ring.map(func(e): return int(w.field_dist(e.global_position)) if is_instance_valid(e) else -1)
	print("push (F, radial): distances %s -> %s" % [d0.map(func(x): return int(x)), d1])
	await _clear()
	var far := []
	for a in 4:
		far.append(await _enemy("goblin", Vector2.RIGHT.rotated(a * TAU / 4 + 0.4) * Vector2(150, 90)))
	for e in far:
		e._shot_cfg = {}
	var f0: Array = far.map(func(e): return int(w.field_dist(e.global_position)))
	Input.action_press("draw")
	await _frames(30)
	Input.action_release("draw")
	await _frames(25)
	var f1: Array = far.map(func(e): return int(w.field_dist(e.global_position)) if is_instance_valid(e) and not e.dead else -1)
	print("pull (T, radial): distances %s -> %s (-1 = crushed)" % [f0, f1])
	await _clear()

	w.global_position = Vector2(13.5, 11.5) * 32
	await _frames(5)
	var y0 := w.global_position.y
	Input.action_press("move_down")
	Input.action_press("jump")
	await _frames(30)
	Input.action_release("jump")
	var peak := 0.0
	for i in 90:
		await get_tree().physics_frame
		peak = maxf(peak, w.z)
	Input.action_release("move_down")
	print("jump down off the ledge: peak %.0f px, moved %.0f px south, landed on open tile %s" % [peak, w.global_position.y - y0, main.level.open_at(w.global_position)])
	await _clear()

	var bossy := await _enemy("skeleton", Vector2(120, 0), true)
	bossy._shot_cfg = {}
	var bc := 999.0
	for i in 200:
		await get_tree().physics_frame
		bc = minf(bc, w.field_dist(bossy.global_position))
	print("boss (no singularity): closest %.0f, pinned %s, witch hp %.0f" % [bc, bossy.pinned, w.hp])
	w.mana = 100
	await _press("singularity")
	await _frames(30)
	print("boss under singularity: sing %.1f, dist %.0f (mid %.0f), dead %s, pinned %s" % [w.singularity_t, w.field_dist(bossy.global_position), w.r_mid(), bossy.dead, bossy.pinned])
	await _clear()
	w.singularity_t = 0.0
	w.cooldowns.singularity = 0.0


func _autoplay() -> void:
	main.cleared = false
	main.wave = -1
	main.wave_alive = 0
	main._next_wave_t = 0.5
	var t := 0
	var min_hp := w.hp
	while t < 60 * 120 and not main.cleared and not w.dead:
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
			Input.action_press("pierce") if t % 20 < 12 else Input.action_release("pierce")
			Input.action_press("rend") if w.cooldowns.rend <= 0.0 and t % 30 == 0 else Input.action_release("rend")
			Input.action_press("draw") if d > 90.0 and w.cooldowns.draw <= 0.0 and t % 45 == 0 else Input.action_release("draw")
			Input.action_press("whisky") if w.hp < 50 and w.whisky > 0 and t % 30 == 0 else Input.action_release("whisky")
			Input.action_press("singularity") if w.mana >= Witch.SING_COST and get_tree().get_nodes_in_group("enemies").size() >= 5 and t % 60 == 0 else Input.action_release("singularity")
		min_hp = minf(min_hp, w.hp)
		await get_tree().physics_frame
	for a in ["pierce", "rend", "draw", "whisky", "singularity"]:
		Input.action_release(a)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and not e.dormant:
			var q := PhysicsRayQueryParameters2D.create(w.global_position, e.global_position, 1)
			print("  left: %s at %s dist %.0f hp %.0f los %s anim %s shooting %s" % [e.kind, e.global_position, e.global_position.distance_to(w.global_position), e.hp, not w.get_world_2d().direct_space_state.intersect_ray(q), e.sprite.animation, e._shooting])
	print("autoplay: cleared %s after %.1fs, wave %d, witch hp %.0f (low %.0f), dead %s" % [main.cleared, t / 60.0, main.wave + 1, w.hp, min_hp, w.dead])
