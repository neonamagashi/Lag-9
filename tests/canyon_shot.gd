extends Node

const VIEWS := [
	["01_spawn", Vector3(1.5, 3.2, 27.5), Vector3(-1, 3.5, 0), Vector3(0, 0.7, 22.0), 0.2],
	["02_boulders", Vector3(4.5, 2.4, 12.0), Vector3(-6, 1.5, 4), Vector3(-1.5, 0.9, 9.5), 2.4],
	["03_cave_mouth", Vector3(-3.5, 2.2, -3.0), Vector3(-7, 2.0, -14), Vector3(-5.6, 0.5, -7.5), 2.8],
	["04_chamber", Vector3(-10.5, 1.6, -21.5), Vector3(-15, 9.0, -27), Vector3(-12.0, 0.4, -23.0), 2.6],
	["05_terraces", Vector3(4.0, 3.0, 6.0), Vector3(14, 6, -10), Vector3(13.0, 4.8, -4.0), -2.6],
	["06_plateau", Vector3(-4.0, 17.5, -19.0), Vector3(2, 1, 14), Vector3(-2.0, 14.3, -17.5), 0.3],
	["08_tunnel", Vector3(-6.4, 2.1, -13.0), Vector3(-10, 1.6, -22.0), Vector3(-7.4, 0.4, -17.0), 2.6],
	["07_arch_ring", Vector3(4.0, 2.6, 22.0), Vector3(15, 2.5, 9), Vector3(6.5, 1.0, 18.0), 2.2],
]

var main: Node
var cam: Camera3D
var i := 0
var f := 0


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	cam = Camera3D.new()
	cam.fov = 68
	cam.far = 300
	add_child(cam)
	Style.attach_post(cam)
	cam.make_current()
	for c in main.get_children():
		if c is CanvasLayer:
			c.visible = false
	get_tree().call_group("enemies", "queue_free")


func _process(_d: float) -> void:
	f += 1
	if f < 30:
		return
	if i >= VIEWS.size():
		get_tree().quit()
		return
	var v: Array = VIEWS[i]
	if (f - 30) % 20 == 0:
		cam.position = v[1]
		cam.look_at(v[2])
		var w: Witch = Game.witch
		w.global_position = v[3]
		w.velocity = Vector3.ZERO
		w.reset_physics_interpolation()
		w._model.rotation.y = v[4]
		if i == 1:
			for k in 3:
				var e := Enemy.new().setup(10, ["gnawling", "acolyte", "seer"][k])
				e.position = [Vector3(-7, 1.0, 2), Vector3(-9.5, 1.0, -1), Vector3(-4.5, 1.2, -3)][k]
				main.add_child(e)
	if (f - 30) % 20 == 19:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + v[0] + ".png")
		i += 1
