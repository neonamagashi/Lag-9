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
		main.hud.visible = false
		w.rig.arm.spring_length = 2.6
		w.rig.yaw = PI * 0.5
		w.rig.pitch = -0.08
		w.rig.position.y += 0.0
		print("colliders: ", w._hair_sim.get_child_count())
	if frames == 70:
		_save("hair_crush")
		w.field_mode = Witch.FieldMode.LIFT
		w._apply_field_look()
	if frames == 130:
		_save("hair_lift")
		w.rig.yaw = PI
	if frames == 170:
		_save("hair_lift_back")
		get_tree().quit()


func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
