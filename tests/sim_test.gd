extends Node

var main: Node
var frames := 0


func _ready() -> void:
	Engine.time_scale = 4.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	print("pierce hits to kill by gap [0,1,2,3,4,5,8]: ", [0, 1, 2, 3, 4, 5, 8].map(func(g): return Game.pierce_hits_to_kill(g)))


func _gaps(list: Array) -> Array:
	return list.map(func(e): return e.level - Game.balance.witch_level)


func _physics_process(_delta: float) -> void:
	frames += 1
	var w: Witch = Game.witch
	match frames:
		300:
			print("CRUSH ~20s game: survivors by gap ", _gaps(get_tree().get_nodes_in_group("enemies")), " kills ", Game.kills, " witch hp ", int(w.hp))
			get_tree().call_group("enemies", "queue_free")
		310:
			w.field_mode = Witch.FieldMode.LIFT
			main.spawn_wave()
		500:
			var rows := []
			for e in get_tree().get_nodes_in_group("enemies"):
				var d := Vector2(e.global_position.x - w.global_position.x, e.global_position.z - w.global_position.z).length()
				if d < Game.balance.field_radius:
					rows.append("%+d@%.1fm" % [e.level - Game.balance.witch_level, e.global_position.y])
			print("LIFT, in-field enemies gap@height: ", rows)
			w.field_on = false
		560:
			print("FIELD OFF: kills from fall impacts so far ", Game.kills, ", witch hp ", int(w.hp), "/", int(Game.witch_max_hp()))
			w.reset_stats()
			var before := w.hp
			w._start_snap(Vector3.FORWARD)
			w.take_damage(50.0, "melee")
			print("SNAP i-frames: hp before ", int(before), " after hit during snap ", int(w.hp))
		600:
			get_tree().call_group("enemies", "queue_free")
		640:
			print("orphan nodes after clearing: ", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			print("TEST DONE")
			get_tree().quit()
