extends Node

var main: Node
var frames := 0


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _process(_delta: float) -> void:
	frames += 1
	var w: Witch = Game.witch
	var b := Game.balance
	if frames == 2:
		get_tree().call_group("enemies", "queue_free")
		main.debug.toggle()
		w.rig.arm.spring_length = 3.4
		w.rig.yaw = 0.5
		w.rig.pitch = -0.12
	if frames == 40:
		_save("staff_front")
		w.rig.yaw = PI - 0.4
	if frames == 70:
		_save("staff_back")
		b.pierce_rank = 3
		b.snap_rank = 2
		b.send_rank = 1
		b.draw_rank = 1
		b.rend_rank = 3
		b.singularity_rank = 2
		w.rig.arm.spring_length = 5.0
	if frames == 140:
		_save("staff_max")
		get_tree().quit()


func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
