extends Node

var main: Node
var w: Witch


func _ready() -> void:
	Game.level_choice = "limbo"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	w = main.witch
	await _frames(240)
	print("arrival: visible %s, abilities %s, field %s, flash alpha %.2f" % [w.visible, w.abilities_enabled, w.field_active, main.limbo._flash.color.a])
	Input.action_press("move_up")
	var t := 0
	while w.global_position.distance_to(Limbo.WARDEN_AT) > 100.0 and t < 60 * 30:
		t += 1
		await get_tree().physics_frame
	Input.action_release("move_up")
	print("walked north %.1fs to the warden, prompt visible %s, souls said %s" % [t / 60.0, main.limbo._prompt.visible, main.limbo._said.keys()])
	Input.action_press("interact")
	await _frames(3)
	Input.action_release("interact")
	await _frames(200)
	var leaving := 0
	for v in main.limbo._vagrants:
		if is_instance_valid(v) and v.leaving:
			leaving += 1
	print("trial: started %s, souls leaving %d, abilities %s, field %s, wave %d" % [main.limbo.started, leaving, w.abilities_enabled, w.field_active, main.wave + 1])
	var t2 := 0
	var min_hp := w.hp
	while t2 < 60 * 120 and not main.cleared and not w.dead:
		t2 += 1
		var near: Enemy = null
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.dead and (not near or e.global_position.distance_to(w.global_position) < near.global_position.distance_to(w.global_position)):
				near = e
		if near:
			w.aim_point = near.global_position + Vector2(0, -near.z - 10)
			Input.action_press("pierce") if t2 % 20 < 12 else Input.action_release("pierce")
			Input.action_press("rend") if t2 % 40 == 0 else Input.action_release("rend")
			Input.action_press("draw") if t2 % 90 == 0 else Input.action_release("draw")
		min_hp = minf(min_hp, w.hp)
		await get_tree().physics_frame
	for a in ["pierce", "rend", "draw"]:
		Input.action_release(a)
	print("battle: cleared %s after %.1fs, waves %d, witch hp %.0f (low %.0f)" % [main.cleared, t2 / 60.0, main.wave + 1, w.hp, min_hp])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
