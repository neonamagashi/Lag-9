extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
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
	Input.action_press("move_right")
	await _frames(3)
	await _press("snap")
	Input.action_release("move_right")
	await _frames(5)
	await _shot("f_teleport")
	await _clear()
	await _spawn("goblin", Vector2(165, 20))
	await _spawn("skeleton", Vector2(-165, -20))
	await _spawn("flying_eye", Vector2(150, -60))
	for i in 140:
		await get_tree().physics_frame
		if i == 70 or i == 120:
			await _shot("g_projectiles_%d" % i)
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
