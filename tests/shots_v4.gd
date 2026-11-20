extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	Game.level_choice = "limbo"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	await _frames(260)
	w.global_position = Vector2(-20, -470)
	w.reset_physics_interpolation()
	Input.action_press("move_up")
	await _frames(45)
	await _shot("01_float_up")
	Input.action_release("move_up")
	Input.action_press("move_right")
	await _frames(30)
	await _shot("02_float_side")
	Input.action_release("move_right")
	await _frames(30)
	w.global_position = Limbo.WARDEN_AT + Vector2(-30, 150)
	w.reset_physics_interpolation()
	await _frames(40)
	await _shot("03_warden_far")
	w.global_position = Limbo.WARDEN_AT + Vector2(10, 60)
	w.reset_physics_interpolation()
	await _frames(70)
	await _shot("04_warden_near")
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(330)
	w.aim_point = w.global_position + Vector2(120, -10)
	Input.action_press("pierce")
	await _frames(10)
	await _shot("05_hand_cast")
	Input.action_release("pierce")
	await _frames(20)
	var g := Enemy.new().setup("goblin")
	g._shot_cfg = {}
	g.position = w.global_position + Vector2(-90, 10)
	main.world.add_child(g)
	await _frames(3)
	w.aim_point = g.global_position
	Input.action_press("grab")
	await _frames(2)
	Input.action_release("grab")
	await _frames(40)
	await _shot("06_grab_squeeze")
	for i in 14:
		w.aim_point = w.global_position + Vector2(-90, 10).rotated(i * 0.12)
		await get_tree().physics_frame
	await _shot("07_grab_swing")
	Input.action_press("grab")
	await _frames(35)
	await _shot("08_throw_charge")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
