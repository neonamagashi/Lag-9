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
	await _shot("01_back")
	Input.action_release("move_up")
	Input.action_press("move_right")
	await _frames(30)
	await _shot("02_lean")
	Input.action_release("move_right")
	w.global_position = Limbo.WARDEN_AT + Vector2(10, 60)
	w.reset_physics_interpolation()
	await _frames(70)
	await _shot("03_warden")
	main.limbo.stage = Limbo.Stage.READY
	w.frozen = false
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(330)
	for e in get_tree().get_nodes_in_group("enemies"):
		e._stun_t = 3.0
	w.aim_point = w.global_position + Vector2(120, -30)
	Input.action_press("pierce")
	await _frames(9)
	await _shot("04_cast")
	Input.action_release("pierce")
	await _frames(30)
	Input.action_press("send")
	await _frames(40)
	await _shot("05_charge")
	Input.action_release("send")
	await _frames(20)
	var g := Enemy.new().setup("goblin")
	g._shot_cfg = {}
	g.position = w.global_position + Vector2(-80, 30)
	main.world.add_child(g)
	await _frames(3)
	w.aim_point = g.global_position
	Input.action_press("grab")
	await _frames(2)
	Input.action_release("grab")
	await _frames(25)
	await _shot("06_squirm_a")
	await _frames(5)
	await _shot("07_squirm_b")
	Input.action_press("grab")
	await _frames(30)
	Input.action_release("grab")
	await _frames(30)
	w.mode = Witch.Mode.LIFT
	await _frames(60)
	await _shot("08_lift")
	w.mode = Witch.Mode.CRUSH
	w.mana = 100
	Input.action_press("singularity")
	await _frames(2)
	Input.action_release("singularity")
	await _frames(60)
	await _shot("09_singularity")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
	var c := get_viewport().get_canvas_transform() * w.global_position
	var s := get_viewport().get_texture().get_image()
	var k := s.get_width() / get_viewport().get_visible_rect().size.x
	var r := Rect2i(int(c.x * k) - 150, int(c.y * k) - 200, 300, 260)
	s.get_region(r).save_png(dir + "/z_" + n + ".png")
