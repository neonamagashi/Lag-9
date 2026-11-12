extends Node

var main: Node
var w: Witch
var step := 0
var wait := 0
var peak := 0.0
var log_lines: PackedStringArray = []


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = Game.witch
	print("pierce hits to kill by gap [0,1,2,3,4,5,8]: ", [0, 1, 2, 3, 4, 5, 8].map(func(g): return Game.pierce_hits_to_kill(g)))


func _enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(func(e): return not e.is_dead())


func _clear() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()


func _place(gap: int, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(Game.balance.witch_level + gap)
	e.magical = false
	e.position = pos
	main.add_child(e)
	return e


func _teleport(pos: Vector3) -> void:
	w.global_position = pos
	w.velocity = Vector3.ZERO
	w.flying = false
	w.reset_physics_interpolation()


func _physics_process(_delta: float) -> void:
	if wait > 0:
		wait -= 1
		peak = maxf(peak, w.global_position.y)
		return
	step += 1
	match step:
		1:
			_clear()
			w.field_on = false
			_teleport(Vector3(0, 0.1, 8))
			wait = 30
		2:
			Input.action_press("jump")
			wait = 2
		3:
			Input.action_release("jump")
			wait = 20
		4:
			peak = 0.0
			Input.action_press("jump")
			wait = 2
		5:
			Input.action_release("jump")
			wait = 70
		6:
			print("tap air jump peak height: %.2f m" % peak)
			_teleport(Vector3(0, 0.1, 8))
			wait = 30
		7:
			Input.action_press("jump")
			wait = 2
		8:
			Input.action_release("jump")
			wait = 20
		9:
			peak = 0.0
			Input.action_press("jump")
			wait = 50
		10:
			Input.action_release("jump")
			wait = 90
		11:
			print("held air jump peak height: %.2f m" % peak)
			_teleport(Vector3(0, 0.1, 8))
			wait = 30
		12:
			Input.action_press("jump")
			wait = 2
		13:
			Input.action_release("jump")
			wait = 6
		14:
			Input.action_press("jump")
			wait = 2
		15:
			Input.action_release("jump")
			wait = 10
		16:
			print("double-tap -> flying: ", w.flying, ", field radius in flight: %.2f" % w.field_radius())
			w.flying = false
			_teleport(Vector3(-14, 0.1, -2.9))
			w.rig.yaw = 0.0
			Input.action_press("move_forward")
			wait = 20
		17:
			Input.action_press("jump")
			wait = 3
		18:
			Input.action_release("jump")
			wait = 25
		19:
			Input.action_release("move_forward")
			print("clamber onto 1.2m platform, witch y: %.2f (expect ~1.2)" % w.global_position.y)
			_teleport(Vector3(0, 0.1, 0))
			w.field_on = false
			w.rig.yaw = 0.0
			_place(0, Vector3(0, 0.3, -4))
			_place(0, Vector3(0, 0.3, -7))
			_place(3, Vector3(1.5, 0.3, -4.5))
			wait = 10
		20:
			var hp_before := _enemies().map(func(e): return int(e.hp))
			Input.action_press("send")
			wait = 60
			log_lines.append("send hp before " + str(hp_before))
		21:
			for e in _enemies():
				var to: Vector3 = e.global_position - w.global_position
				print("  send target gap %+d at %s angle %.0f deg" % [e.gap(), str(to.snapped(Vector3.ONE * 0.1)), rad_to_deg(Vector3(to.x, 0, to.z).normalized().angle_to(w._aim_flat()))])
			Input.action_release("send")
			wait = 50
		22:
			print(log_lines[0], " after ", _enemies().map(func(e): return int(e.hp)), " kills ", Game.kills)
			print("send cooldown after cast: %.1f" % w.send_cd)
			_clear()
			wait = 5
		23:
			_teleport(Vector3(0, 0.1, 0))
			w.field_on = true
			w.field_mode = Witch.FieldMode.CRUSH
			_place(0, Vector3(0, 0.3, -11))
			_place(0, Vector3(0.6, 0.3, -12))
			Game.kills = 0
			w.draw_cd = 0.0
			wait = 10
		24:
			Input.action_press("draw")
			wait = 40
		25:
			Input.action_release("draw")
			wait = 60
		26:
			print("draw pulled same-level foes into crush, kills: ", Game.kills)
			_clear()
			w.field_on = false
			Game.kills = 0
			for i in 5:
				_place(i - 1, Vector3(-4 + i * 2, 0.3, -9))
			Game.balance.rend_rank = 3
			wait = 10
		27:
			Input.action_press("rend")
			wait = 2
		28:
			Input.action_release("rend")
			wait = 100
		29:
			print("rend rank 4 (10 targets + shards) on gaps -1..+3, kills: ", Game.kills, ", survivors hp%: ", _enemies().map(func(e): return int(e.hp / e.max_hp * 100)))
			_clear()
			Game.balance.rend_rank = 0
			w.field_on = true
			w.field_mode = Witch.FieldMode.CRUSH
			w.mana = 100.0
			_place(2, Vector3(0, 0.3, -18))
			_place(6, Vector3(3, 0.3, -18))
			wait = 10
		30:
			Input.action_press("singularity")
			wait = 2
		31:
			Input.action_release("singularity")
			wait = 30
		32:
			print("singularity: radius %.1f, enemy time scale %.2f, mana left %d, field on %s" % [w.field_radius(), Game.enemy_time_scale, int(w.mana), w.field_on])
			wait = 330
		33:
			print("after singularity: time scale %.2f, kills %d, survivors %s" % [Game.enemy_time_scale, Game.kills, str(_enemies().map(func(e): return e.level - Game.balance.witch_level))])
			_clear()
			wait = 30
		34:
			print("orphan nodes: ", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			print("TEST DONE")
			get_tree().quit()
