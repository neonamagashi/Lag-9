extends Node3D

const WAVE := [
	["gnawling", -3], ["gnawling", -2], ["gnawling", -1], ["gnawling", 0],
	["glutton", 3], ["glutton", 6],
	["acolyte", 0], ["acolyte", 2],
	["seer", 1], ["seer", 5],
	["archer", 0], ["archer", 4],
]

var witch: Witch
var rig: CameraRig
var hud: Hud
var debug: DebugOverlay
var menu: ControlsMenu
var _stone: ImageTexture
var _stone_light: ImageTexture


func _ready() -> void:
	_build_environment()
	_build_arena()
	witch = Witch.new()
	witch.position = Vector3(0, 0.2, 8)
	add_child(witch)
	rig = CameraRig.new()
	rig.target = witch
	add_child(rig)
	witch.rig = rig
	hud = Hud.new()
	add_child(hud)
	hud.connect_witch(witch)
	debug = DebugOverlay.new()
	add_child(debug)
	menu = ControlsMenu.new()
	add_child(menu)
	spawn_wave()
	for pos in [Vector3(-20, 2.6, -6), Vector3(18, 0, 18), Vector3(-18, 0, 20), Vector3(14, 2.7, -18.5)]:
		var bottle := Pickup.new().setup(Pickup.Kind.MANA_BOTTLE, Game.balance.mana_bottle_amount)
		bottle.position = pos
		add_child(bottle)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_toast("Find Whisky. Esc for controls, F1 for the debug overlay.")
	Sfx.play_ambient("limbo_loop", -12.0)


func spawn_wave() -> void:
	var lvl := Game.balance.witch_level
	for i in WAVE.size():
		var a := TAU * i / WAVE.size() + randf_range(-0.15, 0.15)
		var r := randf_range(15.0, 22.0)
		var e := Enemy.new().setup(lvl + int(WAVE[i][1]), str(WAVE[i][0]))
		var flat := Vector3(witch.global_position.x + cos(a) * r, 0, witch.global_position.z + sin(a) * r)
		e.position = flat.limit_length(34.0) + Vector3(0, 0.3, 0)
		add_child(e)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			menu.open()
		KEY_F1:
			debug.toggle()
		KEY_F2:
			spawn_wave()
			hud.show_toast("Spawned a wave: gnawlings, gluttons, acolytes, seers, archers")
		KEY_F3:
			hud.show_toast("3D render scale %d%%" % int(debug.cycle_scale() * 100))
		KEY_F4:
			get_tree().call_group("enemies", "queue_free")
			hud.show_toast("Cleared enemies")
		KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
			var step := 1 if event.physical_keycode == KEY_BRACKETRIGHT else -1
			Game.balance.witch_level = clampi(Game.balance.witch_level + step, 1, 99)
			witch.reset_stats()
			get_tree().call_group("enemies", "mark_dirty")
			hud.show_toast("Witch level %d" % Game.balance.witch_level)
		KEY_F6:
			witch.reset_stats()
			hud.show_toast("Healed and whisky refilled")
		KEY_F7:
			Game.balance.snap_rank = (Game.balance.snap_rank + 1) % Game.balance.snap_distance.size()
			hud.show_toast("Snap rank %d" % (Game.balance.snap_rank + 1))
		KEY_F8:
			Game.balance.pierce_rank = (Game.balance.pierce_rank + 1) % Game.balance.pierce_base_damage.size()
			hud.show_toast("Pierce rank %d" % (Game.balance.pierce_rank + 1))
		KEY_F9:
			witch.reset_cooldowns()
			hud.show_toast("Cooldowns reset, mana full")
		KEY_F10:
			Game.balance.send_rank = (Game.balance.send_rank + 1) % Game.balance.send_range.size()
			Game.balance.draw_rank = Game.balance.send_rank
			hud.show_toast("Send/Draw rank %d%s" % [Game.balance.send_rank + 1, " (all directions)" if Game.balance.send_rank >= 1 else ""])
		KEY_F12:
			Game.balance.singularity_rank = (Game.balance.singularity_rank + 1) % Game.balance.singularity_radius_mult.size()
			hud.show_toast("Singularity rank %d" % (Game.balance.singularity_rank + 1))
		KEY_F11:
			Game.balance.rend_rank = (Game.balance.rend_rank + 1) % Game.balance.rend_targets.size()
			hud.show_toast("Rend rank %d: %d targets%s" % [Game.balance.rend_rank + 1, Game.balance.rend_targets[Game.balance.rend_rank], ", shards" if Game.balance.rend_rank == Game.balance.rend_targets.size() - 1 else ""])


# ---------- world ----------
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.19, 0.2, 0.29)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.6, 0.78)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.21, 0.22, 0.32)
	env.fog_density = 0.03
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	Game.env = env
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color(1.0, 0.94, 0.85)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _build_arena() -> void:
	_stone = Art.stone_texture(32, 0.3, 7)
	_stone_light = Art.stone_texture(32, 0.5, 3)
	var floor_mat := Art.mat(Color.WHITE, Color.BLACK, _stone)
	floor_mat.uv1_scale = Vector3(40, 40, 1)
	_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80), floor_mat)
	var wall_mat := Art.mat(Color(0.75, 0.75, 0.85), Color.BLACK, _stone_light)
	wall_mat.uv1_triplanar = true
	wall_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	for s in [-1, 1]:
		_box(Vector3(40.5 * s, 3, 0), Vector3(1, 7, 82), wall_mat)
		_box(Vector3(0, 3, 40.5 * s), Vector3(82, 7, 1), wall_mat)
	var plat_mat := Art.mat(Color(0.8, 0.78, 0.9), Color.BLACK, _stone_light)
	plat_mat.uv1_triplanar = true
	plat_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	_box(Vector3(-14, 0.6, -6), Vector3(5, 1.2, 5), plat_mat)
	_box(Vector3(-20, 1.3, -6), Vector3(5, 2.6, 5), plat_mat)
	_box(Vector3(-26, 2.1, -6), Vector3(5, 4.2, 5), plat_mat)
	var ramp := _box(Vector3(14, 1.2, -10), Vector3(5, 0.6, 12), plat_mat)
	ramp.rotation.x = deg_to_rad(22)
	_box(Vector3(14, 2.4, -18.5), Vector3(5, 0.6, 6), plat_mat)
	var pillar_mat := Art.mat(Color(0.82, 0.82, 0.9), Color.BLACK, _stone_light)
	pillar_mat.uv1_triplanar = true
	pillar_mat.uv1_scale = Vector3(0.6, 0.6, 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 12:
		var a := TAU * i / 12.0 + 0.2
		var r := rng.randf_range(26.0, 32.0)
		_pillar(Vector3(cos(a) * r, 0, sin(a) * r), rng.randf_range(3.0, 7.5), pillar_mat)
	for p in [Vector3(7, 0, -6), Vector3(-6, 0, 12), Vector3(9, 0, 12)]:
		_pillar(p, 4.5, pillar_mat)
	_box(Vector3(26, 2.25, 26), Vector3(14, 4.5, 0.6), wall_mat)
	_box(Vector3(32.7, 2.25, 20), Vector3(0.6, 4.5, 12), wall_mat)
	_box(Vector3(26, 4.7, 20), Vector3(14, 0.4, 12.6), wall_mat)


func _box(pos: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var m := BoxMesh.new()
	m.size = size
	Art.mesh(m, material, Vector3.ZERO, body)
	add_child(body)
	return body


func _pillar(pos: Vector3, height: float, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)
	var shape := CylinderShape3D.new()
	shape.radius = 0.75
	shape.height = height
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var m := CylinderMesh.new()
	m.top_radius = 0.65
	m.bottom_radius = 0.75
	m.height = height
	m.radial_segments = 7
	Art.mesh(m, material, Vector3.ZERO, body)
	var cap := BoxMesh.new()
	cap.size = Vector3(1.9, 0.4, 1.9)
	Art.mesh(cap, material, Vector3(0, height * 0.5, 0), body)
	Art.mesh(cap, material, Vector3(0, -height * 0.5 + 0.2, 0), body)
	add_child(body)
