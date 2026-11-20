extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	Game.level_choice = "ruins"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	main.cleared = true
	main.hud.help = false
	await _frames(5)
	await _clear()
	await _frames(40)
	await _shot("a_field")
	await _spawn("rat", Vector2(80, -10))
	await _spawn("slime", Vector2(-40, 8))
	await _spawn("goblin", Vector2(30, -30))
	await _spawn("skeleton", Vector2(-120, -40))
	await _frames(50)
	await _shot("b_pinned")
	await _clear()
	await _spawn("goblin", Vector2(90, -50))
	await _spawn("rat", Vector2(-95, 20))
	await _spawn("mushroom", Vector2(60, 70))
	w.aim_point = w.global_position + Vector2(100, 0)
	await _press("rend")
	await _frames(30)
	await _shot("c_rend_lift")
	await _frames(10)
	await _shot("d_rend_tear")
	await _frames(30)
	await _shot("e_rend_after")
	await _clear()
	await _spawn("goblin", Vector2(110, -10))
	w.aim_point = w.global_position + Vector2(110, -10)
	await _press("grab")
	w.aim_point = w.global_position + Vector2(-60, -60)
	await _frames(25)
	await _shot("f_grab_hold")
	Input.action_press("grab")
	await _frames(30)
	Input.action_release("grab")
	await _frames(6)
	await _shot("g_grab_throw")
	await _clear()
	for a in 6:
		await _spawn("rat", Vector2.RIGHT.rotated(a * TAU / 6) * Vector2(75, 45))
	Input.action_press("send")
	await _frames(30)
	Input.action_release("send")
	await _frames(8)
	await _shot("h_push_wave")
	await _clear()
	for a in 5:
		await _spawn("goblin", Vector2.RIGHT.rotated(a * TAU / 5 + 0.3) * Vector2(150, 90))
	Input.action_press("draw")
	await _frames(30)
	Input.action_release("draw")
	await _frames(10)
	await _shot("i_pull_wave")
	await _clear()
	w.aim_point = null
	Input.action_press("move_right")
	await _frames(3)
	await _press("snap")
	Input.action_release("move_right")
	await _frames(4)
	await _shot("j_teleport_arrive")
	await _frames(14)
	await _shot("k_teleport_trail")
	await _clear()
	Input.action_press("jump")
	await _frames(25)
	await _shot("l_jump_charge")
	Input.action_release("jump")
	await _frames(22)
	await _shot("m_jump_air")
	await _clear()
	await _spawn("goblin", Vector2(165, 20))
	await _spawn("skeleton", Vector2(-165, -20))
	await _spawn("flying_eye", Vector2(150, -60))
	for i in 140:
		await get_tree().physics_frame
		if i == 70 or i == 120:
			await _shot("g_projectiles_%d" % i)
	get_tree().quit()
	await _press("flip")
	await _spawn("rat", Vector2(40, 10))
	await _spawn("bat", Vector2(-40, -10))
	await _frames(40)
	await _shot("h_lift_field")
	await _press("flip")
	await _clear()
	w.mana = 100
	await _press("singularity")
	await _frames(40)
	await _shot("i_singularity")
	get_tree().quit()


func _spawn(k: String, off: Vector2) -> void:
	var e := Enemy.new().setup(k)
	e.position = w.global_position + off
	main.world.add_child(e)
	await _frames(1)


func _clear() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dormant:
			e.remove_from_group("enemies")
			e.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_shots"):
		s.queue_free()
	await _frames(2)
	w.global_position = main.START * main.level.tile
	w.hp = w.max_hp


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _press(a: String) -> void:
	Input.action_press(a)
	await _frames(2)
	Input.action_release(a)


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
