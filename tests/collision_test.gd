extends Node

var main: Node
var frame := 0
var wall_hit: Enemy
var mover: Enemy
var heavy: Enemy


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		for e in get_tree().get_nodes_in_group("enemies"):
			e.queue_free()
		var w := Game.witch
		w.field_on = false
		w.global_position = Vector3(0, 0.1, -30)
		w.reset_physics_interpolation()
		wall_hit = _place(0, Vector3(0, 0.3, -36))
		mover = _place(0, Vector3(6, 0.3, -31))
		heavy = _place(6, Vector3(6, 0.3, -35))
	if frame == 8:
		wall_hit.knock(Vector3(0, 0, -24), 0.3)
		mover.knock(Vector3(0, 0, -24), 0.3)
	if frame == 60:
		print("knocked into wall: hp %d/%d" % [int(wall_hit.hp), int(wall_hit.max_hp)] if is_instance_valid(wall_hit) and not wall_hit.is_dead() else "knocked into wall: died")
		print("knocked into heavy: hp %d/%d" % [int(mover.hp), int(mover.max_hp)] if is_instance_valid(mover) and not mover.is_dead() else "knocked into heavy: died")
		print("heavy that was hit: hp %d/%d" % [int(heavy.hp), int(heavy.max_hp)])
		get_tree().quit()


func _place(gap: int, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(Game.balance.witch_level + gap)
	e.magical = false
	e.position = pos
	main.add_child(e)
	return e
