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
	w.global_position = Limbo.TALKERS[0] + Vector2(30, 40)
	w.reset_physics_interpolation()
	Input.action_press("move_up")
	await _frames(40)
	Input.action_release("move_up")
	await _zoom("01_back_hair", 1.0)
	w.global_position = Limbo.TALKERS[0] + Vector2(22, 6)
	w.reset_physics_interpolation()
	await _frames(10)
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(40)
	await _zoom("02_talker", 1.0)
	# abilities
	main.limbo.stage = Limbo.Stage.READY
	w.drunk = false
	w.abilities_enabled = true
	w.field_active = true
	w.global_position = Vector2(-200, -1400)
	w.reset_physics_interpolation()
	await _frames(20)
	w.aim_point = w.global_position + Vector2(180, -40)
	Input.action_press("pierce")
	await _frames(14)
	await _shot("03_pierce_runes")
	Input.action_release("pierce")
	await _frames(30)
	w.mana = 100
	Input.action_press("singularity")
	await _frames(2)
	Input.action_release("singularity")
	await _frames(70)
	await _shot("04_singularity_runes")
	await _frames(330)
	Input.action_press("move_right")
	await _frames(20)
	Input.action_press("snap")
	await _frames(24)
	await _zoom("05_snap_lunge", 1.0)
	Input.action_release("snap")
	await _frames(2)
	await _shot("06_snap_trail")
	Input.action_release("move_right")
	# the meeting: cat goes round behind him
	main.limbo.stage = Limbo.Stage.WALK
	w.field_active = false
	w.global_position = Limbo.WARDEN_AT + Vector2(0, 250)
	w.reset_physics_interpolation()
	await _frames(300)
	await _shot("07_cat_behind")
	await _frames(140)
	await _shot("08_cat_at_door")
	main.menu.toggle()
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("09_menu")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")


func _zoom(n: String, _k: float) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var c := get_viewport().get_canvas_transform() * w.global_position
	var k := img.get_width() / get_viewport().get_visible_rect().size.x
	img.get_region(Rect2i(int(c.x * k) - 240, int(c.y * k) - 260, 480, 330)).save_png(dir + "/" + n + ".png")
