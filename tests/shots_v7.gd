extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")


func _ready() -> void:
	Game.level_choice = "limbo"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	while main.limbo.stage != Limbo.Stage.PEOPLE:
		await get_tree().physics_frame
	main.limbo.stage = Limbo.Stage.WALK
	w.global_position = Limbo.WARDEN_AT + Vector2(-60, 420)
	w.reset_physics_interpolation()
	Input.action_press("move_up")
	await _frames(70)
	await _shot("01_back_hair")
	while main.limbo.stage == Limbo.Stage.WALK:
		await get_tree().physics_frame
	Input.action_release("move_up")
	await _frames(200)
	await _shot("02_cat_to_portal")
	await _frames(110)
	await _shot("03_cat_in_portal")
	while not (w.pose == "hunch" and w.pose_frame == 2):
		await get_tree().physics_frame
	await _frames(20)
	await _shot("04_rainbow_puddle")
	while main.limbo.stage != Limbo.Stage.READY:
		await get_tree().physics_frame
	await _frames(20)
	main.limbo.stage = Limbo.Stage.TRIAL
	w.global_position = Limbo.WARDEN_AT + Vector2(140, 260)
	w.reset_physics_interpolation()
	main.limbo.on_trial_complete()
	while not main.limbo.warden.get_children().any(func(c): return c is Dialogue):
		await get_tree().physics_frame
	await _frames(40)
	await _shot("05_after_trial")
	while main.limbo.stage != Limbo.Stage.PASSED:
		await get_tree().physics_frame
	await _frames(10)
	w.global_position = Limbo.PORTAL_AT + Vector2(-50, 60)
	w.reset_physics_interpolation()
	await _frames(20)
	await _shot("06_portal")
	w.aim_point = Limbo.WARDEN_AT
	Input.action_press("pierce")
	await _frames(4)
	Input.action_release("pierce")
	await _frames(50)
	await _shot("07_after_trial_hit")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
