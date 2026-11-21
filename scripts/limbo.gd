class_name Limbo
extends Node2D

const WARDEN_AT := Vector2(0, -2200)
const BOUNDS := Rect2(-560, -2470, 1120, 2670)
const LINES_PATH := "res://assets/dialogue/limbo.json"
const SLOW := 0.55
const MEET_DIST := 150.0
const GROUP_SIZES := [2, 3, 2, 4, 3, 2, 3, 2, 3, 2]
const SITTERS := 9
const STANDERS := 9
const WANDERERS := 12
const GROUP_LINES := ["did you see the price of turnips?", "...and then he said 'twelve'.", "no, no. the blue one.",
	"my neighbour's fence was a foot too tall.", "I was going to repaint the shed.", "have you tried the soup?",
	"it rained on a thursday once.", "I never returned that ladle.", "mm. yes. the ladle.", "they moved the bus stop.",
	"spoons go on the left.", "it's all in the paperwork.", "was it the second drawer?", "I always said that.",
	"...exactly.", "hm. quite.", "my cousin had a goat.", "four across was 'umbrella'.", "the good scissors, though."]

enum Stage { INTRO, PEOPLE, BUSY, WALK, READY, TRIAL }

var main: Node
var witch: Witch
var warden: Node2D
var started := false
var stage := Stage.INTRO
var _lines := {}
var _prompt: Label
var _flash: ColorRect
var _vagrants: Array[Vagrant] = []
var _groups := []


func setup(m: Node, w: Witch) -> void:
	main = m
	witch = w
	w.abilities_enabled = false
	w.field_active = false
	w.visible = false
	w.set_physics_process(false)


func _ready() -> void:
	if FileAccess.file_exists(LINES_PATH):
		_lines = JSON.parse_string(FileAccess.get_file_as_string(LINES_PATH))
	_floor()
	_bounds()
	_populate()
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


# ---------- the souls ----------
func _populate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var taken: Array[Vector2] = []
	var spot := func(spread: float) -> Vector2:
		for i in 60:
			# denser the further north she gets
			var p := Vector2(rng.randf_range(-380, 380), -240.0 - 1740.0 * sqrt(rng.randf()))
			if taken.all(func(q): return q.distance_to(p) > spread):
				return p
		return Vector2(rng.randf_range(-380, 380), rng.randf_range(-1900, -300))
	for gi in GROUP_SIZES.size():
		var size: int = GROUP_SIZES[gi]
		# the first group stands just ahead of where she arrives, so she notices them
		var c: Vector2 = Vector2(64, -330) if gi == 0 else spot.call(70.0)
		taken.append(c)
		var sitting := gi > 0 and rng.randf() < 0.3
		var members := []
		for k in size:
			var a: float = k * TAU / size + rng.randf_range(-0.3, 0.3)
			var p: Vector2 = c + Vector2(cos(a), sin(a) * 0.6) * (13.0 + size * 2.0)
			var v := _soul(p, rng, Vagrant.Mode.SIT if sitting else Vagrant.Mode.STAND)
			v.face = (c - p).normalized()
			v.solo = false
			members.append(v)
		_groups.append({"c": c, "members": members, "t": rng.randf_range(0.5, 3.0), "turn": rng.randi() % size})
	for k in SITTERS + STANDERS + WANDERERS:
		var p: Vector2 = spot.call(34.0)
		taken.append(p)
		var mode := Vagrant.Mode.SIT if k < SITTERS else (Vagrant.Mode.STAND if k < SITTERS + STANDERS else Vagrant.Mode.WANDER)
		var v := _soul(p, rng, mode)
		v.face = Vector2.from_angle(rng.randf() * TAU)


func _soul(p: Vector2, rng: RandomNumberGenerator, mode: Vagrant.Mode) -> Vagrant:
	var v := Vagrant.new()
	v.variant = rng.randi() % Vagrant.VARIANTS
	v.mode = mode
	v.position = p
	main.world.add_child(v)
	_vagrants.append(v)
	return v


func _chatter(delta: float) -> void:
	var p := witch.global_position
	for g in _groups:
		g.t -= delta
		if g.t > 0.0 or g.c.distance_to(p) > 260.0:
			continue
		var alive: Array = g.members.filter(func(v): return is_instance_valid(v) and not v.leaving)
		if alive.is_empty():
			continue
		var v: Vagrant = alive[g.turn % alive.size()]
		g.turn += 1
		v.speak(GROUP_LINES[randi() % GROUP_LINES.size()])
		g.t = randf_range(1.8, 3.2)


# ---------- lines ----------
func _text(key: String) -> String:
	return str(_lines.get(key, ""))


func _line(key: String, who := "witch") -> void:
	var text := _text(key)
	if text == "":
		return
	var d: Dialogue
	if who == "warden":
		d = Dialogue.say(warden, text, "warden", 1.0, Color(0.32, 0.04, 0.08), 196.0, 9)
		d.cps = 16.0
	else:
		d = Dialogue.say(witch, text, "babble", 1.25, Color(0.2, 0.12, 0.35), 56.0)
		d.cue.connect(_on_cue)
	while is_instance_valid(d) and not d.read():
		await get_tree().process_frame


func _on_cue(action: String) -> void:
	if action.begins_with("bu"):
		Sfx.play("burp", 0.05, -2.0)
		witch.squash = 0.25
		var t := witch.create_tween()
		t.tween_property(witch, "squash", 0.0, 0.4)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


# ---------- the scene ----------
func _arrive() -> void:
	await _wait(0.8)
	_flash.color = Color.WHITE
	Sfx.play("arrive_flash", 0.0, -2.0)
	witch.visible = true
	witch.set_physics_process(true)
	witch.drunk = true
	witch.move_mult = SLOW
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
	await _wait(1.6)
	_cat(witch.global_position + Vector2(18, -60), witch.global_position + Vector2(40, -460), 62.0)
	await _wait(1.0)
	await _line("cat_seen")
	await _wait(2.2)
	await _line("cat_gone")
	stage = Stage.PEOPLE


func _people() -> void:
	stage = Stage.BUSY
	await _line("people_1")
	await _line("people_2")
	await _line("people_3")
	await _vomit()
	await _line("hangover")
	stage = Stage.WALK


func _meet() -> void:
	stage = Stage.BUSY
	witch.frozen = true
	_cat(WARDEN_AT + Vector2(-90, 70), WARDEN_AT + Vector2(-40, -300), 58.0)
	await _wait(0.8)
	await _line("cat_again")
	await _wait(0.9)
	Sfx.play("groan", 0.0, -4.0, 1.1)
	await _wait(0.5)
	await _line("warden_1", "warden")
	await _think()
	await _line("warden_2", "warden")
	await _line("witch_cat")
	await _line("warden_3", "warden")
	await _line("witch_shock")
	Sfx.play("groan", 0.0, -2.0)
	await _wait(1.0)
	await _line("warden_4", "warden")
	Sfx.play("laugh", 0.05, -4.0)
	await _line("witch_laugh")
	await _vomit()
	witch.frozen = false
	stage = Stage.READY


func on_trial_complete() -> void:
	await _wait(1.8)
	Sfx.play("groan", 0.0, -3.0, 0.9)
	await _wait(0.8)
	await _line("warden_pass", "warden")
	await _line("warden_sins", "warden")


## She keels over and throws up: three heaves, the last one productive.
func _vomit() -> void:
	witch.frozen = true
	var t := witch.create_tween()
	t.tween_property(witch, "keel", 0.7, 0.45).set_ease(Tween.EASE_OUT)
	await t.finished
	Sfx.play("retch", 0.03, -4.0)
	for i in 3:
		var h := witch.create_tween()
		h.tween_property(witch, "keel", 1.0, 0.12)
		h.tween_property(witch, "keel", 0.75, 0.38)
		if i == 2:
			_spew()
		await h.finished
	await _wait(0.7)
	var back := witch.create_tween()
	back.tween_property(witch, "keel", 0.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	await back.finished
	witch.frozen = false


const RAINBOW := [Color(1.0, 0.25, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.92, 0.3), Color(0.35, 0.9, 0.4), Color(0.3, 0.6, 1.0), Color(0.62, 0.38, 1.0)]


## Rainbow, Nyan-style: six stacked bands arcing down, with sparkles, into a rainbow puddle.
func _spew() -> void:
	var f := float(witch.facing)
	var mouth := witch.global_position + Vector2(f * 14.0, -24.0 - witch.hover)
	var dir := Vector2(f * 0.55, 1.0).normalized()
	var side := Vector2(-dir.y, dir.x)
	for i in RAINBOW.size():
		var p := CPUParticles2D.new()
		p.amount = 36
		p.lifetime = 0.5
		p.one_shot = true
		p.explosiveness = 0.0
		p.direction = dir
		p.spread = 2.0
		p.initial_velocity_min = 70.0
		p.initial_velocity_max = 74.0
		p.gravity = Vector2(0, 200)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 2.0
		p.color = RAINBOW[i]
		p.global_position = mouth + side * (i - 2.5) * 1.6
		p.z_index = 5
		main.world.add_child(p)
		p.emitting = true
		get_tree().create_timer(1.5).timeout.connect(p.queue_free)
	var sp := CPUParticles2D.new()
	sp.amount = 26
	sp.lifetime = 0.9
	sp.one_shot = true
	sp.direction = dir
	sp.spread = 40.0
	sp.initial_velocity_min = 30.0
	sp.initial_velocity_max = 90.0
	sp.gravity = Vector2(0, 60)
	sp.texture = _sparkle_tex()
	sp.color = Color(1, 1, 1)
	sp.hue_variation_min = -1.0
	sp.hue_variation_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.5, Color(1, 0.95, 0.7, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	sp.color_ramp = g
	sp.global_position = mouth
	sp.z_index = 6
	main.world.add_child(sp)
	sp.emitting = true
	get_tree().create_timer(2.0).timeout.connect(sp.queue_free)
	Sfx.play("pop", 0.3, -10.0, 1.6)
	await _wait(0.3)
	var puddle := Node2D.new()
	puddle.global_position = witch.global_position + Vector2(f * 22.0, 3.0)
	puddle.z_index = -5
	puddle.draw.connect(func():
		for i in RAINBOW.size():
			var pts := PackedVector2Array()
			var r := 10.0 - i * 1.5
			for k in 16:
				var a := k / 16.0 * TAU
				pts.append(Vector2(cos(a) * r, sin(a) * r * 0.32))
			puddle.draw_colored_polygon(pts, Color(RAINBOW[i], 0.9)))
	puddle.scale = Vector2(0.2, 0.2)
	main.world.add_child(puddle)
	var glint := CPUParticles2D.new()
	glint.amount = 5
	glint.lifetime = 1.2
	glint.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	glint.emission_rect_extents = Vector2(9, 2)
	glint.direction = Vector2(0, -1)
	glint.initial_velocity_min = 2.0
	glint.initial_velocity_max = 6.0
	glint.gravity = Vector2.ZERO
	glint.texture = _sparkle_tex()
	glint.color_ramp = g
	glint.z_index = 7
	puddle.add_child(glint)
	var pt := puddle.create_tween()
	pt.tween_property(puddle, "scale", Vector2.ONE, 0.5)
	pt.tween_interval(25.0)
	pt.tween_property(puddle, "modulate:a", 0.0, 3.0)
	pt.tween_callback(puddle.queue_free)


static var _sparkle: ImageTexture


static func _sparkle_tex() -> Texture2D:
	if not _sparkle:
		var im := Image.create(5, 5, false, Image.FORMAT_RGBA8)
		for k in 5:
			im.set_pixel(2, k, Color(1, 1, 1, 1.0 if k == 2 else 0.8))
			im.set_pixel(k, 2, Color(1, 1, 1, 1.0 if k == 2 else 0.8))
		_sparkle = ImageTexture.create_from_image(im)
	return _sparkle


## "?" then a plate of pancakes: she isn't listening.
func _think() -> void:
	var q := _bubble("q", Vector2(12, -64))
	await _wait(1.1)
	var pc := _bubble("pancakes", Vector2(30, -88))
	await _wait(1.8)
	for b: Sprite2D in [q, pc]:
		var t := b.create_tween()
		t.tween_property(b, "modulate:a", 0.0, 0.4)
		t.tween_callback(b.queue_free)
	await _wait(0.3)


func _bubble(kind: String, at: Vector2) -> Sprite2D:
	var b := Sprite2D.new()
	b.texture = load("res://assets/limbo/think_%s.png" % kind)
	b.position = at
	b.z_index = 30
	b.z_as_relative = false
	b.scale = Vector2.ZERO
	witch.add_child(b)
	Sfx.play("pop", 0.1, -8.0)
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return b


func _cat(from: Vector2, to: Vector2, speed: float) -> void:
	var c := Whiskey.new()
	c.position = from
	c.target = to
	c.speed = speed
	main.world.add_child(c)


# ---------- update ----------
func _process(delta: float) -> void:
	if not is_instance_valid(witch):
		return
	var p := witch.global_position
	var look := clampf(1.0 - (p.distance_to(WARDEN_AT) - 120.0) / 220.0, 0.0, 1.0) if not started else 0.0
	main.camera.position.y = lerpf(main.camera.position.y, -16.0 - 95.0 * look, 1.0 - exp(-delta * 3.0))
	_chatter(delta)
	match stage:
		Stage.PEOPLE:
			if p.y < -450.0 or _vagrants.any(func(v): return v.global_position.distance_to(p) < 130.0):
				_people()
		Stage.WALK:
			if p.distance_to(WARDEN_AT) < MEET_DIST:
				_meet()
	_prompt.visible = stage == Stage.READY and p.distance_to(WARDEN_AT) < MEET_DIST + 30.0


func _on_interact() -> void:
	if stage != Stage.READY or witch.global_position.distance_to(WARDEN_AT) > MEET_DIST + 30.0:
		return
	stage = Stage.TRIAL
	started = true
	_prompt.visible = false
	witch.drunk = false
	witch.move_mult = 1.0
	Sfx.play("singularity", 0.0, -4.0, 0.7)
	Fx.shake(4.0)
	for v in _vagrants:
		if is_instance_valid(v):
			v.leave(WARDEN_AT)
	main.hud.banner("The Trial", "")
	await _wait(1.2)
	witch.field_active = true
	witch.abilities_enabled = true
	main.hud.show_abilities = true
	Fx.ring(witch.global_position, Witch.CRUSH_COLOR, Witch.R_OUTER, 0.8)
	Sfx.play("flip_crush", 0.0, -2.0)
	await _wait(1.2)
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
