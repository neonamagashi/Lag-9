extends Node

var main: Node
var frames := 0


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _process(_delta: float) -> void:
	frames += 1
	var w: Witch = Game.witch
	if frames == 2:
		get_tree().call_group("enemies", "queue_free")
		main.debug.toggle()
		w.field_on = false
		w.global_position = Vector3(0, 0.2, 6)
		w.reset_physics_interpolation()
		var kinds := ["gnawling", "glutton", "acolyte", "seer", "archer"]
		for i in kinds.size():
			var e := Enemy.new().setup(Game.balance.witch_level, kinds[i])
			e.position = Vector3(-6 + i * 3.0, 0.3, 0)
			main.add_child(e)
		Game.enemy_time_scale = 0.0
		w.rig.yaw = 0.0
		w.rig.pitch = -0.18
		w.rig.arm.spring_length = 7.0
	if frames == 40:
		for e in get_tree().get_nodes_in_group("enemies"):
			e._model.rotation.y = 0.0
	if frames == 60:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/enemies_lineup.png")
		print("saved")
		get_tree().quit()
