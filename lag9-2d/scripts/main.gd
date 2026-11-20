extends Node2D

const T := 16
const W := 30
const H := 21
const WALL_H := 40
const ENV := "res://assets/env/%s.png"
const WAVES := [
	["rat", "rat", "rat", "goblin"],
	["rat", "rat", "goblin", "slime", "bat", "flying_eye"],
	["mushroom", "mushroom", "skeleton", "goblin", "goblin", "bat", "flying_eye"],
	["skeleton", "skeleton", "slime", "slime", "flying_eye", "flying_eye", "goblin", "rat", "rat", "rat"],
]

var world: Node2D
var witch: Witch
var camera: Camera2D
var hud: Hud
var wave := -1
var wave_alive := 0
var cleared := false
var _next_wave_t := 1.2
var _braziers: Array[PointLight2D] = []
var _reticle: Node2D


func _ready() -> void:
	randomize()
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	Fx.world = world
	world.set_meta("main", self)
	var cm := CanvasModulate.new()
	cm.color = Color(0.6, 0.55, 0.72)
	add_child(cm)
	_build_room()
	witch = Witch.new()
	witch.position = Vector2(W * T / 2.0, H * T - 60)
	world.add_child(witch)
	world.set_meta("witch", witch)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = -8
	camera.limit_right = W * T
	camera.limit_bottom = H * T
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	witch.add_child(camera)
	camera.position = Vector2(0, -16)
	Fx.camera = camera
	var mimic := Enemy.new().setup("mimic")
	mimic.position = Vector2(W * T - 70, 74)
	mimic.facing = -1
	world.add_child(mimic)
	_spawn_pickup("whisky", Vector2(52, H * T - 52))
	_reticle = Node2D.new()
	_reticle.z_index = 40
	_reticle.draw.connect(func():
		_reticle.draw_arc(Vector2.ZERO, 4.0, 0, TAU, 12, Color(0.6, 1.0, 0.95, 0.9), 1.0)
		_reticle.draw_rect(Rect2(-0.5, -0.5, 1, 1), Color(0.6, 1.0, 0.95)))
	add_child(_reticle)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	hud = Hud.new()
	hud.witch = witch
	hud.main = self
	add_child(hud)


func _process(delta: float) -> void:
	Fx.update(delta)
	_reticle.position = get_global_mouse_position()
	var t := Time.get_ticks_msec() / 1000.0
	for i in _braziers.size():
		_braziers[i].energy = 1.05 + sin(t * 9.0 + i * 1.7) * 0.08 + sin(t * 23.0 + i) * 0.05
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if cleared or witch.dead:
		return
	if wave_alive <= 0:
		_next_wave_t -= delta
		if _next_wave_t <= 0.0:
			if wave + 1 >= WAVES.size():
				cleared = true
				hud.banner("Room cleared", "F5 to play again")
				Sfx.play("singularity", 0.0, -8.0)
			else:
				_start_wave(wave + 1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F1:
		hud.help = not hud.help


# ---------- waves ----------
func _start_wave(i: int) -> void:
	wave = i
	hud.banner("Wave %d" % (i + 1), "")
	var kinds: Array = WAVES[i]
	wave_alive = kinds.size()
	var center := Vector2(W * T / 2.0, H * T / 2.0 - 10)
	for k in kinds.size():
		var a := k / float(kinds.size()) * TAU + randf_range(-0.2, 0.2)
		var p := center + Vector2(cos(a) * 70.0, sin(a) * 42.0)
		var timer := get_tree().create_timer(0.15 * k + 0.3)
		timer.timeout.connect(_spawn.bind(kinds[k], p))


func _spawn(kind: String, p: Vector2) -> void:
	Fx.anim("summon", p, 0.8, Color.WHITE, 12.0)
	Sfx.play("ui_click", 0.1, -8.0)
	var e := Enemy.new().setup(kind)
	e.position = p
	e.set_meta("wave", true)
	world.add_child(e)


func on_enemy_died(e: Enemy) -> void:
	if e.has_meta("wave"):
		wave_alive -= 1
		if wave_alive <= 0:
			_next_wave_t = 2.0


func _spawn_pickup(kind: String, p: Vector2) -> void:
	var pk := Pickup.new()
	pk.kind = kind
	pk.position = p
	world.add_child(pk)


# ---------- room ----------
func _build_room() -> void:
	var floor_layer := TileMapLayer.new()
	floor_layer.z_index = -10
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = load(ENV % "floor")
	src.texture_region_size = Vector2i(T, T)
	for y in 4:
		for x in 4:
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, 0)
	floor_layer.tile_set = ts
	add_child(floor_layer)
	for y in range(2, H - 1):
		for x in range(1, W - 1):
			var v := Vector2i(randi() % 4, randi() % 3)
			if randf() < 0.04:
				v = Vector2i(3, 3)
			floor_layer.set_cell(Vector2i(x, y), 0, v)
	var wall := Sprite2D.new()
	wall.texture = load(ENV % "wall")
	wall.centered = false
	wall.region_enabled = true
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.region_rect = Rect2(0, 0, (W - 2) * T, WALL_H)
	wall.position = Vector2(T, 0)
	wall.z_index = -9
	add_child(wall)
	var top: Texture2D = load(ENV % "wall_top")
	for side in [0, W - 1]:
		var s := Sprite2D.new()
		s.texture = top
		s.centered = false
		s.region_enabled = true
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.region_rect = Rect2(0, 0, T, H * T)
		s.position = Vector2(side * T, 0)
		s.z_index = 4
		add_child(s)
	var south := Sprite2D.new()
	south.texture = top
	south.centered = false
	south.region_enabled = true
	south.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	south.region_rect = Rect2(0, 0, W * T, T)
	south.position = Vector2(0, (H - 1) * T)
	south.z_index = 4
	add_child(south)
	_box(Rect2(0, -40, W * T, WALL_H + 46))
	_box(Rect2(0, (H - 1) * T - 4, W * T, 60))
	_box(Rect2(-40, 0, T + 40, H * T))
	_box(Rect2((W - 1) * T, 0, T + 40, H * T))
	var rune := Sprite2D.new()
	rune.texture = load(ENV % "rune_circle")
	rune.position = Vector2(W * T / 2.0, H * T / 2.0 - 10)
	rune.z_index = -8
	add_child(rune)
	var rl := Fx.light(rune, Color(0.4, 0.85, 0.8), 1.6, 0.35)
	for x in [80, 200, 266, 386]:
		var b := Sprite2D.new()
		b.texture = load(ENV % "banner")
		b.centered = false
		b.position = Vector2(x, 8)
		b.z_index = -8
		add_child(b)
	for x in [140, 330]:
		var c := Sprite2D.new()
		c.texture = load(ENV % "chains")
		c.centered = false
		c.position = Vector2(x, 6)
		c.z_index = -8
		add_child(c)
	for p in [Vector2(120, 124), Vector2(W * T - 120, 124), Vector2(120, H * T - 92), Vector2(W * T - 120, H * T - 92)]:
		_pillar(p)
	for p in [Vector2(40, 58), Vector2(W * T - 40, 58), Vector2(W * T / 2.0 - 70, 54), Vector2(W * T / 2.0 + 70, 54)]:
		_brazier(p)
	var decor := [["bones", Vector2(70, 200)], ["rubble", Vector2(400, 290)], ["bones", Vector2(360, 110)], ["rubble", Vector2(96, 290)], ["rubble", Vector2(240, 64)]]
	for d in decor:
		var s := Sprite2D.new()
		s.texture = load(ENV % d[0])
		s.position = d[1]
		s.z_index = -7
		add_child(s)


func _box(r: Rect2) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	c.shape = s
	c.position = r.get_center()
	b.add_child(c)
	add_child(b)


func _pillar(p: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = p
	b.collision_layer = 1
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 10.0
	c.shape = s
	b.add_child(c)
	var spr := Sprite2D.new()
	spr.texture = load(ENV % "pillar")
	spr.centered = false
	spr.offset = Vector2(-12, -57)
	b.add_child(spr)
	var occ := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-8, -2), Vector2(8, -2), Vector2(8, 3), Vector2(-8, 3)])
	occ.occluder = poly
	b.add_child(occ)
	world.add_child(b)


func _brazier(p: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = p
	b.collision_layer = 1
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 5.0
	c.shape = s
	b.add_child(c)
	var spr := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	Sheets.add(sf, "burn", ENV % "brazier", 16, 30, 6, 10.0, true)
	spr.sprite_frames = sf
	spr.centered = false
	spr.offset = Vector2(-8, -30)
	spr.play("burn")
	spr.frame = randi() % 6
	b.add_child(spr)
	var l := Fx.light(b, Color(1.0, 0.62, 0.32), 2.6, 1.1)
	l.position = Vector2(0, -18)
	l.shadow_enabled = true
	_braziers.append(l)
	world.add_child(b)
