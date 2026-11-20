extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	Game.level_choice = "limbo"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	await _frames(20)
	await _shot("00_dark")
	await _frames(40)
	await _shot("01_flash")
	await _frames(130)
	await _shot("02_arrive")
	w.global_position = Vector2(-20, -520)
	w.reset_physics_interpolation()
	await _frames(70)
	await _shot("03_souls")
	w.global_position = Limbo.WARDEN_AT + Vector2(20, 95)
	w.reset_physics_interpolation()
	await _frames(70)
	await _shot("04_warden")
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(180)
	await _shot("05_trial_begins")
	await _frames(160)
	w.aim_point = w.global_position + Vector2(120, -40)
	Input.action_press("pierce")
	await _frames(14)
	await _shot("06_battle_beam")
	Input.action_release("pierce")
	await _frames(40)
	w.mana = 100
	Input.action_press("singularity")
	await _frames(2)
	Input.action_release("singularity")
	await _frames(70)
	await _shot("07_singularity")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
