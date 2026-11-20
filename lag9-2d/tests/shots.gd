extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	main.cleared = true
	await _frames(30)
	await _shot("1_start")
	main.hud.help = false
	for k in ["rat", "rat", "slime", "bat", "rat"]:
		var e := Enemy.new().setup(k)
		e.position = w.global_position + Vector2(randf_range(-110, 110), randf_range(-90, -40))
		e.set_meta("wave", true)
		main.world.add_child(e)
	w.aim_point = w.global_position + Vector2(80, -60)
	main.wave = 1
	await _frames(70)
	Input.action_press("pierce")
	await _frames(10)
	await _shot("2_fight")
	Input.action_release("pierce")
	await _press("flip")
	await _frames(35)
	await _shot("3_lift")
	await _press("flip")
	await _frames(25)
	await _press("rend")
	await _frames(14)
	await _shot("4_rend")
	await _frames(40)
	w.mana = 100
	await _press("singularity")
	await _frames(30)
	await _shot("5_singularity")
	get_tree().quit()


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
