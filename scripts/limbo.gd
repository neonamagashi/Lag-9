class_name Limbo
extends Node2D

const WARDEN_AT := Vector2(0, -1500)
const BOUNDS := Rect2(-460, -1760, 920, 1960)
const LINES_PATH := "res://assets/dialogue/limbo.json"
const VAGRANTS := [
	Vector2(-120, -560), Vector2(90, -640), Vector2(-40, -760), Vector2(170, -820), Vector2(-200, -900),
	Vector2(40, -980), Vector2(-110, -1080), Vector2(150, -1150), Vector2(-60, -1230), Vector2(210, -1300),
	Vector2(-230, -1180), Vector2(100, -1390),
]

var main: Node
var witch: Witch
var warden: Node2D
var started := false
var _lines := {}
var _said := {}
var _prompt: Label
var _flash: ColorRect
var _vagrants: Array[Vagrant] = []


func setup(m: Node, w: Witch) -> void:
	main = m
	witch = w
	w.abilities_enabled = false
	w.field_active = false
	w.visible = false
	w.set_physics_process(false)


func _ready() -> void:
	if ResourceLoader.exists(LINES_PATH) or FileAccess.file_exists(LINES_PATH):
		_lines = JSON.parse_string(FileAccess.get_file_as_string(LINES_PATH))
	_floor()
	_bounds()
	for i in VAGRANTS.size():
		var v := Vagrant.new()
		v.variant = i % 6
		v.position = VAGRANTS[i]
		main.world.add_child(v)
		_vagrants.append(v)
	_build_warden()
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_flash = ColorRect.new()
	_flash.color = Color.BLACK
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash)
	_prompt = Label.new()
	_prompt.text = "[E]  Begin"
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Color(0.15, 0.12, 0.2))
	_prompt.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.position = WARDEN_AT + Vector2(-22, 14)
	_prompt.visible = false
	_prompt.z_index = 40
	main.world.add_child(_prompt)
	witch.interact.connect(_on_interact)
	_arrive()


func _line(key: String) -> String:
	return str(_lines.get(key, ""))


# ---------- arrival ----------
func _arrive() -> void:
	await get_tree().create_timer(0.8).timeout
	_flash.color = Color.WHITE
	Sfx.play("arrive_flash", 0.0, -2.0)
	witch.visible = true
	witch.set_physics_process(true)
	witch.visual.scale = Vector2(0.2, 2.2)
	var t := witch.create_tween()
	t.tween_property(witch.visual, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.shake(3.0)
	var burst := Fx.light(main.world, Color(1, 1, 1), 6.0, 2.0)
	burst.global_position = witch.global_position + Vector2(0, -20)
	var bt := burst.create_tween()
	bt.tween_property(burst, "energy", 0.0, 1.6)
	bt.tween_callback(burst.queue_free)
	var ft := _flash.create_tween()
	ft.tween_interval(0.25)
	ft.tween_property(_flash, "color:a", 0.0, 2.2).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(2.8).timeout
	_say("arrive")
	await get_tree().create_timer(4.0).timeout
	_say("wander")


func _say(key: String) -> void:
	if _said.has(key) or _line(key) == "":
		return
	_said[key] = true
	Dialogue.say(witch, _line(key), "babble", 1.25, Color(0.2, 0.12, 0.35), 52.0)


# ---------- update ----------
func _process(delta: float) -> void:
	if not is_instance_valid(witch):
		return
	var p := witch.global_position
	var look := clampf(1.0 - (p.distance_to(WARDEN_AT) - 120.0) / 220.0, 0.0, 1.0) if not started else 0.0
	main.camera.position.y = lerpf(main.camera.position.y, -16.0 - 95.0 * look, 1.0 - exp(-delta * 3.0))
	if not started:
		for v in _vagrants:
			if is_instance_valid(v) and v.global_position.distance_to(p) < 150.0:
				_say("see_souls")
				break
		var near := p.distance_to(WARDEN_AT) < 110.0
		if p.distance_to(WARDEN_AT) < 300.0:
			_say("see_warden")
		_prompt.visible = near
	else:
		_prompt.visible = false


func _on_interact() -> void:
	if started or witch.global_position.distance_to(WARDEN_AT) > 110.0:
		return
	started = true
	_prompt.visible = false
	Sfx.play("singularity", 0.0, -4.0, 0.7)
	Fx.shake(4.0)
	for v in _vagrants:
		if is_instance_valid(v):
			v.leave(WARDEN_AT)
	main.hud.banner("The Trial", "")
	await get_tree().create_timer(1.2).timeout
	witch.field_active = true
	witch.abilities_enabled = true
	main.hud.show_abilities = true
	Fx.ring(witch.global_position, Witch.CRUSH_COLOR, Witch.R_OUTER, 0.8)
	Sfx.play("flip_crush", 0.0, -2.0)
	await get_tree().create_timer(1.2).timeout
	main.start_battle()


# ---------- scenery ----------
func _floor() -> void:
	RenderingServer.set_default_clear_color(Color(1, 1, 1))
	var n := Node2D.new()
	n.z_index = -30
	var specks := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 900:
		specks.append([Vector2(rng.randf_range(BOUNDS.position.x - 300, BOUNDS.end.x + 300), rng.randf_range(BOUNDS.position.y - 300, BOUNDS.end.y + 300)), rng.randf_range(0.04, 0.12), rng.randi_range(1, 3)])
	n.draw.connect(func():
		for s in specks:
			n.draw_rect(Rect2(s[0], Vector2(s[2], 1)), Color(0.55, 0.53, 0.6, s[1])))
	add_child(n)
	var motes := CPUParticles2D.new()
	motes.amount = 40
	motes.lifetime = 6.0
	motes.preprocess = 6.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(300, 200)
	motes.direction = Vector2(0, -1)
	motes.spread = 40.0
	motes.initial_velocity_min = 3.0
	motes.initial_velocity_max = 9.0
	motes.gravity = Vector2.ZERO
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(0.6, 0.58, 0.68, 0.0))
	g.add_point(0.5, Color(0.6, 0.58, 0.68, 0.35))
	g.set_color(g.get_point_count() - 1, Color(0.6, 0.58, 0.68, 0.0))
	motes.color_ramp = g
	motes.local_coords = false
	motes.z_index = 20
	witch.add_child(motes)


func _bounds() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8
	add_child(body)
	var b := BOUNDS
	for r in [Rect2(b.position.x - 40, b.position.y - 40, b.size.x + 80, 40), Rect2(b.position.x - 40, b.end.y, b.size.x + 80, 40),
			Rect2(b.position.x - 40, b.position.y, 40, b.size.y), Rect2(b.end.x, b.position.y, 40, b.size.y)]:
		var col := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = r.size
		col.shape = s
		col.position = r.get_center()
		body.add_child(col)


func _build_warden() -> void:
	warden = Node2D.new()
	warden.position = WARDEN_AT
	main.world.add_child(warden)
	# the cloak's train lies on the floor, under everything that walks over it
	var train_sf := SpriteFrames.new()
	train_sf.remove_animation("default")
	Sheets.add(train_sf, "flow", "res://assets/limbo/warden_train.png", 280, 200, 8, 6.0, true)
	var train := AnimatedSprite2D.new()
	train.sprite_frames = train_sf
	train.centered = false
	train.offset = Vector2(-140, -176)
	train.position = WARDEN_AT
	train.z_index = -5
	main.world.add_child(train)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	Sheets.add(sf, "flow", "res://assets/limbo/warden.png", 280, 200, 8, 6.0, true)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.centered = false
	s.offset = Vector2(-140, -176)
	warden.add_child(s)
	s.play("flow")
	train.play("flow")
	var smoke := CPUParticles2D.new()
	smoke.amount = 70
	smoke.lifetime = 2.6
	smoke.preprocess = 2.0
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(100, 10)
	smoke.position = Vector2(8, -14)
	smoke.direction = Vector2(0.5, -1)
	smoke.spread = 30.0
	smoke.initial_velocity_min = 5.0
	smoke.initial_velocity_max = 14.0
	smoke.gravity = Vector2(6, -3)
	smoke.texture = Fx.soft()
	smoke.scale_amount_min = 0.35
	smoke.scale_amount_max = 0.8
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.01, 0.04, 0.0))
	g.add_point(0.25, Color(0.05, 0.04, 0.08, 0.45))
	g.set_color(g.get_point_count() - 1, Color(0.3, 0.28, 0.35, 0.0))
	smoke.color_ramp = g
	smoke.z_index = 2
	train.add_child(smoke)
	smoke.position = Vector2(8, -14)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 24.0
	col.shape = c
	body.add_child(col)
	warden.add_child(body)
