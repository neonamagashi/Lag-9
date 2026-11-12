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
		w.field_on = false
	if frames == 70:
		Input.action_press("send")
	if frames == 100:
		Input.action_release("send")
	if frames == 104:
		_save("send")
	if frames == 140:
		w.field_on = true
		w.field_mode = Witch.FieldMode.LIFT
		w._apply_field_look()
		main.spawn_wave()
		w.mana = 100
		Input.action_press("singularity")
	if frames == 143:
		Input.action_release("singularity")
	if frames == 152:
		_save("singularity")
		get_tree().quit()


func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
