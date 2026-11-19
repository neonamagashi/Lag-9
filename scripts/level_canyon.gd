class_name LevelCanyon
extends Node3D

const DIR := "res://models/levels/canyon/"
const SOLID := ["terrain", "boulders", "props"]
const DECOR := ["decor", "far"]

var player_start := Vector3(0, 1.8, 22)
var spawn_points: Array[Vector3] = [
	Vector3(-8, 1.2, -4), Vector3(-4, 1.2, -8), Vector3(4, 1.2, -2), Vector3(9, 1.2, 4),
	Vector3(-10, 1.2, 2), Vector3(-6, 1.2, 12), Vector3(6, 1.2, 9), Vector3(14, 1.2, 12),
	Vector3(-16, 1.4, 14), Vector3(0, 1.2, 12), Vector3(-20, 1.6, 4), Vector3(18, 1.6, 2),
]
var bottle_points: Array[Vector3] = [
	Vector3(12.4, 13.6, -15.5), Vector3(-13.0, 0.4, -24.0), Vector3(-3.2, 4.1, 4.5),
	Vector3(2.5, 14.4, -31.0), Vector3(19.0, 1.0, 10.0),
]


func _ready() -> void:
	for n in SOLID + DECOR + ["banners"]:
		var path: String = DIR + n + ".glb"
		if not ResourceLoader.exists(path):
			continue
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		add_child(inst)
		var mat := Style.world(0.12 if n == "banners" else 0.0)
		for node in inst.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = node
			mi.material_override = mat
			if n == "banners":
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	_bounds()


func _bounds() -> void:
	for b in [[Vector3(0, 20, 31.5), Vector3(70, 50, 1)], [Vector3(0, 20, -39.5), Vector3(70, 50, 1)],
			[Vector3(30.5, 20, 0), Vector3(1, 50, 80)], [Vector3(-30.5, 20, 0), Vector3(1, 50, 80)],
			[Vector3(0, 30, 0), Vector3(70, 1, 80)]]:
		var body := StaticBody3D.new()
		body.position = b[0]
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = b[1]
		col.shape = shape
		body.add_child(col)
		add_child(body)
