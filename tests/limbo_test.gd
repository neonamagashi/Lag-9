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
	print("souls: %d (groups %d), sitting %d" % [main.limbo._vagrants.size(), main.limbo._groups.size(), main.limbo._vagrants.filter(func(v): return v.mode == Vagrant.Mode.SIT).size()])
	Input.action_press("move_up")
	var t := 0
	var marks := {}
	var max_keel := 0.0
	var slow_speed := 0.0
	while main.limbo.stage != Limbo.Stage.READY and t < 60 * 120:
		t += 1
		var st: String = Limbo.Stage.keys()[main.limbo.stage]
		if not marks.has(st):
			marks[st] = snappedf(t / 60.0, 0.1)
		max_keel = maxf(max_keel, 1.0 if w.pose == "hunch" else 0.0)
		if main.limbo.stage == Limbo.Stage.WALK:
			slow_speed = maxf(slow_speed, w.velocity.length())
		await get_tree().physics_frame
	Input.action_release("move_up")
	await _frames(10)
	print("scene: stages reached at %s s, ready after %.1fs; walking speed %.0f (normal %d); she bent over to vomit %s; cats seen %s; prompt visible %s, %.0f px from the warden" % [marks, t / 60.0, slow_speed, Witch.SPEED, max_keel > 0.0, get_tree().root.find_children("*", "Whiskey", true, false).size(), main.limbo._prompt.visible, w.global_position.distance_to(Limbo.WARDEN_AT)])
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
	main.limbo._warden_hit()
	var hits_during: int = main.limbo._hits
	var anchored := false
	var t3 := 0
	while main.limbo.stage != Limbo.Stage.PASSED and t3 < 60 * 40:
		t3 += 1
		if main.limbo.warden.get_children().any(func(c): return c is Dialogue):
			anchored = anchored or (w.frozen and w.global_position.distance_to(Limbo.WARDEN_AT + Limbo.ANCHOR) < 4.0 and main.camera.zoom.x < 0.8)
		await get_tree().physics_frame
	print("after the trial: warden hit during trial counted %d; anchored and zoomed out for his words %s; passed %s after %.1fs; portal open %s, sprint %s" % [hits_during, anchored, main.limbo.stage == Limbo.Stage.PASSED, t3 / 60.0, not is_instance_valid(main.limbo._portal_block), w.sprint_enabled])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
