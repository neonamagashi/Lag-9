extends Node

var main: Node
var frames := 0
var by_kind := {}


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _reset_stats() -> void:
	for k in Projectile.stats:
		Projectile.stats[k] = 0


func _place(kind: String, gap: int, pos: Vector3) -> Enemy:
	var e := Enemy.new().setup(Game.balance.witch_level + gap, kind)
	e.position = pos
	main.add_child(e)
	return e


func _physics_process(_delta: float) -> void:
	frames += 1
	var w: Witch = Game.witch
	match frames:
		3:
			get_tree().call_group("enemies", "queue_free")
			w.global_position = Vector3(0, 0.2, 0)
			w.reset_physics_interpolation()
		5:
			for k in ["gnawling", "glutton", "acolyte", "seer", "archer"]:
				var e := _place(k, 6 if k == "glutton" else 5, Vector3(randf_range(-3, 3), 0.3, -18 - randf_range(0, 4)))
				var box: AABB = e._local_aabb(e._model)
				by_kind[k] = e
				print("%-9s fitted height %.2f m  width %.2f  hp %d  collider r %.2f" % [k, box.size.y, maxf(box.size.x, box.size.z), int(e.max_hp), float(e.cfg["radius"])])
			_reset_stats()
			w.reset_stats()
			w.field_on = true
		600:
			print("FIELD ON 10s: projectiles fired %d, crushed by field %d, hit witch %d; witch hp %d/%d" % [Projectile.stats["fired"], Projectile.stats["crushed"], Projectile.stats["hit"], int(w.hp), int(Game.witch_max_hp())])
			for k in by_kind:
				var e: Enemy = by_kind[k]
				if is_instance_valid(e) and not e.is_dead():
					print("   %-9s distance to witch %.1f m" % [k, Vector2(e.global_position.x, e.global_position.z).distance_to(Vector2(w.global_position.x, w.global_position.z))])
			_reset_stats()
			w.reset_stats()
			w.field_on = false
		1200:
			print("FIELD OFF 10s: projectiles fired %d, crushed %d, hit witch %d; witch hp %d/%d" % [Projectile.stats["fired"], Projectile.stats["crushed"], Projectile.stats["hit"], int(w.hp), int(Game.witch_max_hp())])
			get_tree().call_group("enemies", "queue_free")
			get_tree().call_group("projectiles", "queue_free")
		1240:
			print("orphans: ", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			get_tree().quit()
