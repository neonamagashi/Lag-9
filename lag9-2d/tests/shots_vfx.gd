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
	w.global_position = Vector2(240, 250)
	w.aim_point = Vector2(240, 150)
	await _spawn("slime", Vector2(240, 180))
	Input.action_press("pierce")
	await _frames(9)
	Input.action_release("pierce")
	await _shot("a_pierce")
	await _frames(20)
	await _clear()
	await _spawn("rat", Vector2(270, 230))
	await _spawn("goblin", Vector2(210, 225))
	w.aim_point = Vector2(240, 120)
	Input.action_press("send")
	await _frames(40)
	Input.action_release("send")
	await _frames(6)
	await _shot("b_send")
	await _frames(40)
	await _clear()
	await _spawn("skeleton", Vector2(240, 160))
	await _spawn("mushroom", Vector2(300, 190))
	await _press("draw")
	await _frames(5)
	await _shot("c_draw")
	await _frames(40)
	await _clear()
	await _spawn("rat", Vector2(265, 245))
	await _spawn("slime", Vector2(215, 255))
	await _press("flip")
	await _frames(5)
	await _shot("d_lift")
	await _frames(45)
	await _press("flip")
	await _frames(9)
	await _shot("e_slam")
	await _frames(50)
	await _clear()
	w.mana = 100
	for i in 4:
		await _spawn(["rat", "goblin", "flying_eye", "rat"][i], Vector2(170 + i * 45, 200 + (i % 2) * 40))
	await _press("singularity")
	await _frames(14)
	await _shot("f_singularity")
	await _frames(70)
	await _shot("g_crush_kills")
	await _clear()
	w.hp = 50
	await _press("whisky")
	await _frames(6)
	await _shot("h_whisky")
	get_tree().quit()


func _spawn(k: String, p: Vector2) -> void:
	var e := Enemy.new().setup(k)
	e.position = p
	main.world.add_child(e)
	await _frames(1)


func _clear() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dormant:
			e.remove_from_group("enemies")
			e.queue_free()
	await _frames(2)


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
