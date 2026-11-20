extends Node

var main: Node
var w: Witch


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	main.cleared = true
	main.hud.help = false
	await _frames(5)
	w.global_position = Vector2(240, 230)
	var kinds := ["goblin", "skeleton", "mushroom", "flying_eye"]
	for i in kinds.size():
		var e := Enemy.new().setup(kinds[i])
		e.position = Vector2(150 + i * 60, 140 + (i % 2) * 14)
		main.world.add_child(e)
	Input.action_press("move_up")
	await _frames(40)
	Input.action_release("move_up")
	await _frames(4)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/back_view.png")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
