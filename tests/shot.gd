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
		w.rig.yaw = 0.5
	if frames == 140:
		_save("crush")
		w.field_mode = Witch.FieldMode.LIFT
		w._apply_field_look()
		main.spawn_wave()
	if frames == 330:
		_save("lift")
		get_tree().quit()


func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
