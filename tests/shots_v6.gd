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
	main.limbo.stage = Limbo.Stage.READY
	w.frozen = false
	w.abilities_enabled = true
	w.drunk = false
	w.global_position = Limbo.WARDEN_AT + Vector2(-150, 260)
	w.reset_physics_interpolation()
	await _frames(30)
	for i in 3:
		var r := Enemy.new().setup("rat")
		r.position = w.global_position + Vector2(-20 + i * 22, -110 + (i % 2) * 14)
		r._stun_t = 99.0
		main.world.add_child(r)
	await _frames(5)
	w.aim_point = w.global_position + Vector2(4, -200)
	Input.action_press("pierce")
	await _frames(8)
	await _shot("01_north_cast")
	Input.action_release("pierce")
	await _frames(20)
	w.aim_point = w.global_position + Vector2(200, -60)
	Input.action_press("pierce")
	await _frames(8)
	await _shot("02_side_band")
	Input.action_release("pierce")
	await _frames(30)
	Input.action_press("snap")
	await _frames(30)
	await _shot("03_snap_charge")
	Input.action_release("snap")
	await _frames(3)
	await _shot("04_snap_arrive")
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	w.global_position = Limbo.WARDEN_AT + Vector2(0, 150)
	w.reset_physics_interpolation()
	await _frames(40)
	for i in 3:
		w.aim_point = Limbo.WARDEN_AT + Vector2(0, -60)
		Input.action_press("pierce")
		await _frames(4)
		Input.action_release("pierce")
		await _frames(60)
	await _shot("05_warden_warns")
	await _frames(20)
	Input.action_press("pierce")
	await _frames(4)
	Input.action_release("pierce")
	await _frames(70)
	await _shot("06_doom")
	Input.action_press("move_down")
	await _frames(45)
	await _shot("07_doom_chase")
	while main.limbo._flash.color.a < 0.6:
		await get_tree().physics_frame
	await _shot("08_consumed")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
