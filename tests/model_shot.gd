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
		w.rig.arm.spring_length = 3.2
		w.rig.yaw = 0.0
		w.rig.pitch = -0.12
	if frames == 40:
		_save("model_crush")
		w.field_mode = Witch.FieldMode.LIFT
		w._apply_field_look()
	if frames == 75:
		_save("model_lift")
		w.rig.yaw = 0.9
	if frames == 100:
		_save("model_lift_side")
		get_tree().quit()


func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
