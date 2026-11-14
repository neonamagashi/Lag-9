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
		w.rig.arm.spring_length = 2.4
		for c in main.get_children():
			if c is CanvasLayer: c.visible = false
		w.rig.yaw = 0.6
		w.rig.pitch = -0.1
	if frames == 50:
		_save("a_idle")
		w._play_shot("pierce", 1.6)
	if frames == 58:
		_save("b_pierce")
		w.send_charge = 0.0
	if frames == 85:
		_save("c_send_hold")
		w.send_charge = -1.0
		w._play_shot("draw", 2.0)
	if frames == 100:
		_save("d_draw")
		w._play_shot("drink", 1.6)
	if frames == 125:
		_save("e_drink")
		w.flying = true
		w.velocity = Vector3(0, 0, 0)
	if frames == 180:
		_save("f_fly_idle")
		w.flying = false
	if frames == 240:
		w._idle_t = 8.5
	if frames == 330:
		_save("g_lounge")
		w.rig.yaw = PI + 0.5
	if frames == 360:
		_save("h_lounge_back")
		get_tree().quit()


func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
