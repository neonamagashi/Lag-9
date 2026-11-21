extends Node

var main: Node
var w: Witch
var dir := OS.get_environment("SHOT_DIR")
var _taken := {}


func _ready() -> void:
	Game.level_choice = "limbo"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	await _frames(150)
	await _shot("01_cat")
	Input.action_press("move_up")
	var t := 0
	var spew_t := -1
	while main.limbo.stage != Limbo.Stage.READY and t < 60 * 120:
		t += 1
		await get_tree().physics_frame
		var line := _witch_line()
		if line.begins_with("It's disturbingly") and not _taken.has("02"):
			await _shot("02_people")
		if w.pose == "hunch" and w.pose_frame == 2 and spew_t < 0:
			spew_t = t
		if spew_t > 0 and t == spew_t + 14 and not _taken.has("03"):
			await _shot("03_rainbow")
		if main.limbo.stage == Limbo.Stage.WALK and w.global_position.y < -1500 and not _taken.has("04"):
			await _shot("04_crowd")
		if w.get_children().any(func(c): return c is Sprite2D and c.texture and c.texture.resource_path.ends_with("pancakes.png") and c.scale.x > 0.9) and not _taken.has("05"):
			await _shot("05_pancakes")
		if line.contains("buuurp") and not _taken.has("06"):
			await _frames(70)
			await _shot("06_burp")
		var wl := _warden_line()
		if wl.begins_with("If you seek") and not _taken.has("07"):
			await _frames(80)
			await _shot("07_warden")
	Input.action_release("move_up")
	await _frames(20)
	await _shot("08_begin")
	get_tree().quit()


func _witch_line() -> String:
	for c in w.get_children():
		if c is Dialogue:
			return c.text
	return ""


func _warden_line() -> String:
	for c in main.limbo.warden.get_children():
		if c is Dialogue:
			return c.text
	return ""


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	_taken[n.substr(0, 2)] = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
