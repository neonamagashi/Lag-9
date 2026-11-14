extends Node3D

const POSES := [
	["Push", 0.15], ["Push", 0.40], ["Push", 0.70], ["OverhandThrow", 0.15], ["OverhandThrow", 0.40], ["OverhandThrow", 0.70], ["Shield_OneShot", 0.15], ["Shield_OneShot", 0.40], ["Shield_OneShot", 0.70], ["Chest_Open", 0.15], ["Chest_Open", 0.40], ["Chest_Open", 0.70], ["Spell_Simple_Enter", 0.15], ["Spell_Simple_Enter", 0.40], ["Spell_Simple_Enter", 0.70], ["Consume", 0.15], ["Consume", 0.40], ["Consume", 0.70],
]

var witch: Node3D
var ap: AnimationPlayer
var cam: Camera3D
var i := 0
var f := 0


func _ready() -> void:
	witch = (load("res://models/witch/witch_rigged.fbx") as PackedScene).instantiate()
	add_child(witch)
	ap = AnimationPlayer.new()
	witch.add_child(ap)
	ap.root_node = ap.get_path_to(witch)
	for pack in ["res://animations/Universal Animation Library/Unreal-Godot/UAL1_Standard.glb", "res://animations/Universal Animation Library 2/Unreal-Godot/UAL2_Standard.glb"]:
		var src := (load(pack) as PackedScene).instantiate()
		var sap: AnimationPlayer = src.find_children("*", "AnimationPlayer", true, false)[0]
		var lib: AnimationLibrary = sap.get_animation_library("")
		var mine: AnimationLibrary = ap.get_animation_library("") if ap.has_animation_library("") else AnimationLibrary.new()
		for n in lib.get_animation_list():
			if not mine.has_animation(n):
				mine.add_animation(n, lib.get_animation(n))
		if not ap.has_animation_library(""):
			ap.add_animation_library("", mine)
		src.free()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.22, 0.22, 0.28)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.position = Vector3(2.4, 1.1, 2.6)
	cam.look_at(Vector3(0, 0.8, 0))


func _process(_d: float) -> void:
	f += 1
	if i >= POSES.size():
		get_tree().quit()
		return
	var p: Array = POSES[i]
	if f % 6 == 1:
		ap.play(p[0])
		ap.seek(ap.current_animation_length * float(p[1]), true)
		ap.pause()
	if f % 6 == 5:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/pose_%02d_%s.png" % [i, p[0]])
		i += 1
