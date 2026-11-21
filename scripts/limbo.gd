class_name Limbo
extends Node2D

const WARDEN_AT := Vector2(0, -2200)
const BOUNDS := Rect2(-560, -2470, 1120, 2670)
## His cloak's train on the floor: nobody walks through it.
const CLOAK_C := Vector2(6, -14)
const CLOAK_R := Vector2(112, 23)
const NAUSEA_Y := -1150.0
const TALKERS := [Vector2(-70, -640), Vector2(95, -1050), Vector2(-100, -1450), Vector2(80, -1800)]
const LINES_PATH := "res://assets/dialogue/limbo.json"
const SLOW := 0.55
const MEET_DIST := 150.0
const GROUP_SIZES := [2, 3, 2, 4, 3, 2, 3, 2, 3, 2]
const SITTERS := 5
const STANDERS := 6
## piece, seat height (0 = can't sit), collision (radius, or size for blocks)
const RUINS := {"column_tall": [0.0, 9.0], "column_mid": [0.0, 9.0], "column_short": [0.0, 9.0],
	"drum": [11.0, Vector2(28, 8)], "capital": [9.0, Vector2(28, 8)], "slab": [11.0, Vector2(38, 8)], "slab_small": [9.0, Vector2(24, 6)]}
const RUIN_LAYOUT := ["column_tall", "slab", "column_short", "drum", "column_mid", "slab_small", "capital", "column_tall",
	"slab", "column_short", "drum", "column_mid", "slab_small", "column_tall", "capital", "slab"]
const WANDERERS := 12
const GROUP_LINES := ["did you see the price of turnips?", "...and then he said 'twelve'.", "no, no. the blue one.",
	"my neighbour's fence was a foot too tall.", "I was going to repaint the shed.", "have you tried the soup?",
	"it rained on a thursday once.", "I never returned that ladle.", "mm. yes. the ladle.", "they moved the bus stop.",
	"spoons go on the left.", "it's all in the paperwork.", "was it the second drawer?", "I always said that.",
	"...exactly.", "hm. quite.", "my cousin had a goat.", "four across was 'umbrella'.", "the good scissors, though."]

enum Stage { INTRO, PEOPLE, BUSY, NAUSEA, WALK, READY, TRIAL, PASSED, DOOM }

const ANCHOR := Vector2(0, 112)
const CUT_ZOOM := 0.7
const CUT_CAM := Vector2(0, -160)
const DOOM_SPEED := Vector2(150.0, 72.0)
const PORTAL_AT := Vector2(120, -2335)

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
var _cutscene := false
var _hits := 0
var _hit_cd := 0.0
var _peek_t := 0.0
var _doom_r := 0.0
var _doom_t := 0.0
var _doom: Node2D
var _doom_smoke: CPUParticles2D
var _portal: Node2D
var _portal_block: StaticBody2D
var _portal_t := 0.0
var _funnel: StaticBody2D
var _talkers: Array[Vagrant] = []
var _talk_prompt: Label


func setup(m: Node, w: Witch) -> void:
	main = m
	witch = w
	w.abilities_enabled = false
	w.sprint_enabled = false
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
	_build_portal()
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
	_talk_prompt = Label.new()
	_talk_prompt.text = "[E] Talk"
	_talk_prompt.add_theme_font_size_override("font_size", 7)
	_talk_prompt.add_theme_color_override("font_color", Color(0.15, 0.12, 0.2))
	_talk_prompt.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	_talk_prompt.add_theme_constant_override("outline_size", 3)
	_talk_prompt.visible = false
	_talk_prompt.z_index = 40
	main.world.add_child(_talk_prompt)
	_build_funnel()
	witch.interact.connect(_on_interact)
	_arrive()


# ---------- the souls ----------
func _populate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var taken: Array[Vector2] = []
	var spot := func(spread: float) -> Vector2:
		var span := -WARDEN_AT.y - 170.0 - 240.0
		for i in 60:
			# denser the further north she gets; near him they line the flanks of the way in
			var f := sqrt(rng.randf())
			var y := -240.0 - span * f
			var x := rng.randf_range(-380, 380)
			if f > 0.55:
				var lane := _lane(y)
				x = (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(lane * 0.7, lane + 230.0)
			var p := Vector2(x, y)
			if taken.all(func(q): return q.distance_to(p) > spread):
				return p
		return Vector2(rng.randf_range(-380, 380), rng.randf_range(WARDEN_AT.y + 200.0, -300.0))
	# broken marble scattered through the crowd: souls sit on the slabs and loiter by the columns
	for i in RUIN_LAYOUT.size():
		var kind: String = RUIN_LAYOUT[i]
		var p: Vector2 = spot.call(60.0)
		if absf(p.x) < 70.0:
			p.x = signf(p.x + 0.1) * rng.randf_range(80.0, 160.0)
		taken.append(p)
		_ruin(kind, p)
		var seat: float = RUINS[kind][0]
		if seat > 0.0 and rng.randf() < 0.75:
			var v := _soul(p + Vector2(rng.randf_range(-6, 6), 1), rng, Vagrant.Mode.SIT)
			v.seat = seat
		elif seat == 0.0 and rng.randf() < 0.6:
			var v := _soul(p + Vector2(rng.randf_range(14, 20) * (1 if rng.randf() < 0.5 else -1), 6), rng, Vagrant.Mode.STAND)
			v.face = Vector2.from_angle(rng.randf() * TAU)
	# a few souls who can actually see her
	for t in TALKERS:
		taken.append(t)
		var v := _soul(t, rng, Vagrant.Mode.STAND)
		v.face = Vector2(-signf(t.x), 0.4).normalized()
		_talkers.append(v)
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


func _ruin(kind: String, p: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/limbo/ruin_%s.png" % kind)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height() + 2)
	s.position = p
	main.world.add_child(s)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var shape_def = RUINS[kind][1]
	if shape_def is Vector2:
		var r := RectangleShape2D.new()
		r.size = shape_def
		col.shape = r
		col.position = Vector2(0, -2)
	else:
		var c := CircleShape2D.new()
		c.radius = shape_def
		col.shape = c
	body.add_child(col)
	s.add_child(body)


## Half-width of the way in at height y: wide at the start, narrowing toward him.
func _lane(y: float) -> float:
	var f := clampf((y + 350.0) / (WARDEN_AT.y + 190.0 + 350.0), 0.0, 1.0)
	return lerpf(470.0, 170.0, f)


static func in_cloak(p: Vector2, margin := 0.0) -> bool:
	var d := p - (WARDEN_AT + CLOAK_C)
	return pow(d.x / (CLOAK_R.x + margin), 2.0) + pow(d.y / (CLOAK_R.y + margin * 0.4), 2.0) < 1.0


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
	var big := _cutscene
	if who == "warden":
		d = Dialogue.say(warden, text, "warden", 1.0, Color(0.32, 0.04, 0.08), 210.0 if big else 196.0, 13 if big else 9, 300.0 if big else 200.0)
		d.cps = 16.0
	else:
		d = Dialogue.say(witch, text, "babble", 1.25, Color(0.2, 0.12, 0.35), 62.0 if big else 56.0, 12 if big else 8, 240.0 if big else 160.0)
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
	_cat(witch.global_position + Vector2(18, -60), [witch.global_position + Vector2(40, -460)], 62.0)
	await _wait(1.0)
	await _line("cat_seen")
	await _wait(3.2)
	await _line("cat_gone")
	stage = Stage.PEOPLE


## Unhurried: pauses between lines so there's time to read and look around; the nausea hits further in.
func _people() -> void:
	stage = Stage.BUSY
	await _line("people_1")
	await _wait(2.0)
	await _line("people_2")
	await _wait(2.4)
	await _line("people_3")
	stage = Stage.NAUSEA


func _nausea() -> void:
	stage = Stage.BUSY
	await _vomit()
	await _wait(0.6)
	await _line("hangover")
	stage = Stage.WALK


func _meet() -> void:
	stage = Stage.BUSY
	_cat(WARDEN_AT + Vector2(-110, 90), [WARDEN_AT + Vector2(-150, 12), WARDEN_AT + Vector2(-95, -52), WARDEN_AT + Vector2(40, -70), PORTAL_AT], 58.0)
	await _cut_in()
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
	witch.drunk = false
	if is_instance_valid(_funnel):
		_funnel.queue_free()
	await _cut_out()
	witch.abilities_enabled = true
	main.hud.show_abilities = true
	stage = Stage.READY


## Drawn in and anchored in front of him while the camera pulls back to show the scale of him.
func _cut_in() -> void:
	witch.frozen = true
	witch.velocity = Vector2.ZERO
	_cutscene = true
	var pull := witch.create_tween()
	pull.tween_property(witch, "global_position", WARDEN_AT + ANCHOR, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	Sfx.play("pull_wave", 0.0, -10.0, 0.7)
	var cam: Tween = main.camera.create_tween().set_parallel()
	cam.tween_property(main.camera, "zoom", Vector2.ONE * CUT_ZOOM, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cam.tween_property(main.camera, "position", CUT_CAM, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await pull.finished
	witch.facing = 1
	await cam.finished


func _cut_out() -> void:
	var back: Tween = main.camera.create_tween().set_parallel()
	back.tween_property(main.camera, "zoom", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(main.camera, "position", Vector2(0, -111), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished
	_cutscene = false
	witch.frozen = false


func on_trial_complete() -> void:
	await _wait(1.8)
	await _cut_in()
	Sfx.play("groan", 0.0, -3.0, 0.9)
	await _wait(0.8)
	await _line("warden_pass", "warden")
	await _line("warden_sins", "warden")
	await _cut_out()
	stage = Stage.PASSED
	_open_portal()


## She bends over, hands on knees, and heaves three times; the last one comes up as a rainbow.
func _vomit() -> void:
	var was_frozen := witch.frozen
	witch.frozen = true
	witch.pose = "hunch"
	witch.pose_frame = 0
	await _wait(0.35)
	Sfx.play("retch", 0.03, -4.0)
	for i in 3:
		witch.pose_frame = 1
		witch.squash = 0.12
		await _wait(0.14)
		witch.pose_frame = 2 if i == 2 else 0
		witch.squash = 0.0
		if i == 2:
			_spew()
			await _wait(0.9)
		else:
			await _wait(0.36)
	witch.pose_frame = 0
	await _wait(0.5)
	witch.pose = ""
	witch.frozen = was_frozen


const RAINBOW := [Color(1.0, 0.25, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.92, 0.3), Color(0.35, 0.9, 0.4), Color(0.3, 0.6, 1.0), Color(0.62, 0.38, 1.0)]


## Rainbow, Nyan-style: six stacked bands arcing down, with sparkles, into a rainbow puddle.
func _spew() -> void:
	var f := float(witch.facing)
	var m: Vector2 = Witch.HUNCH_MOUTH[2]
	var mouth := witch.global_position + Vector2(f * m.x, m.y - witch.hover)
	var dir := Vector2(f * 0.35, 1.0).normalized()
	var side := Vector2(-dir.y, dir.x)
	# each drop lives exactly as long as it takes to reach the floor, so the stream ends in the puddle
	var drop := -m.y + witch.hover + 3.0
	var vy := 72.0 * dir.y
	var fall := (-vy + sqrt(vy * vy + 400.0 * drop)) / 200.0
	for i in RAINBOW.size():
		var p := CPUParticles2D.new()
		p.amount = 30
		p.lifetime = fall
		p.direction = dir
		p.spread = 2.0
		p.initial_velocity_min = 72.0
		p.initial_velocity_max = 72.0
		p.gravity = Vector2(0, 200)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 2.0
		p.color = RAINBOW[i]
		p.global_position = mouth + side * (i - 2.5) * 1.6
		p.z_index = 5
		main.world.add_child(p)
		p.emitting = true
		get_tree().create_timer(0.6).timeout.connect(func(): p.emitting = false)
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
	puddle.global_position = witch.global_position + Vector2(f * (m.x + 72.0 * dir.x * fall), 3.0)
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


func _cat(from: Vector2, path: Array, speed: float) -> void:
	var c := Whiskey.new()
	c.position = from
	c.path = path
	c.speed = speed
	main.world.add_child(c)


# ---------- update ----------
func _process(delta: float) -> void:
	if not is_instance_valid(witch):
		return
	var p := witch.global_position
	var look := clampf(1.0 - (p.distance_to(WARDEN_AT) - 120.0) / 220.0, 0.0, 1.0) if not started else 0.0
	if not _cutscene:
		main.camera.position.y = lerpf(main.camera.position.y, -16.0 - 95.0 * look, 1.0 - exp(-delta * 3.0))
	_hit_cd -= delta
	_chatter(delta)
	if stage == Stage.DOOM:
		_spread_doom(delta)
		return
	if _portal:
		_portal_t += delta
		_portal.queue_redraw()
		if stage == Stage.PASSED and p.distance_to(PORTAL_AT) < 16.0 and not witch.frozen:
			_enter_portal()
	match stage:
		Stage.PEOPLE:
			if p.y < -300.0:
				_people()
		Stage.NAUSEA:
			if p.y < NAUSEA_Y:
				_nausea()
		Stage.WALK:
			if p.distance_to(WARDEN_AT) < MEET_DIST + 110.0:
				_meet()
	_prompt.visible = stage == Stage.READY and p.distance_to(WARDEN_AT) < MEET_DIST + 40.0
	var near := _near_talker()
	_talk_prompt.visible = near != null and not witch.frozen
	if near:
		_talk_prompt.position = near.global_position + Vector2(-16, -46)


func _near_talker() -> Vagrant:
	if stage in [Stage.TRIAL, Stage.DOOM]:
		return null
	for v in _talkers:
		if is_instance_valid(v) and not v.leaving and v.global_position.distance_to(witch.global_position) < 34.0:
			return v
	return null


func _on_interact() -> void:
	var talker := _near_talker()
	if talker:
		talker.speak(_text("talker") if _text("talker") != "" else "Not now...", true)
		return
	if stage != Stage.READY or witch.global_position.distance_to(WARDEN_AT) > MEET_DIST + 40.0:
		return
	stage = Stage.TRIAL
	started = true
	_prompt.visible = false
	witch.drunk = false
	witch.move_mult = 1.0
	witch.sprint_enabled = true
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


# ---------- striking the Warden ----------
func _warden_hit() -> void:
	# he can only be struck before the trial or after it; during it, he is out of reach
	if _hit_cd > 0.0 or not stage in [Stage.READY, Stage.PASSED] or witch.frozen:
		return
	_hit_cd = 0.8
	_hits += 1
	Sfx.play("impact", 0.1, -10.0, 0.5)
	var flick := warden.create_tween()
	flick.tween_property(warden, "modulate", Color(0.6, 0.5, 0.8), 0.06)
	flick.tween_property(warden, "modulate", Color.WHITE, 0.2)
	if _hits <= 3:
		Sfx.play("groan", 0.0, -6.0, 1.0 + _hits * 0.08)
		_peek()
		_line("warden_hit_%d" % _hits, "warden")
	else:
		_engulf()


## Pull the camera back to frame him while he speaks; each new warning keeps it there a little longer.
func _peek() -> void:
	_peek_t = 2.8
	if _cutscene:
		return
	_cutscene = true
	var to_center := (WARDEN_AT.y - 30.0) - witch.global_position.y
	var cam: Tween = main.camera.create_tween().set_parallel()
	cam.tween_property(main.camera, "zoom", Vector2.ONE * CUT_ZOOM, 0.6).set_trans(Tween.TRANS_SINE)
	cam.tween_property(main.camera, "position", Vector2(0, clampf(to_center, -900.0, -16.0)), 0.6).set_trans(Tween.TRANS_SINE)
	while _peek_t > 0.0:
		await get_tree().process_frame
		_peek_t -= get_process_delta_time()
	if stage == Stage.DOOM:
		return
	var back: Tween = main.camera.create_tween().set_parallel()
	back.tween_property(main.camera, "zoom", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	back.tween_property(main.camera, "position", Vector2(0, -16), 0.6).set_trans(Tween.TRANS_SINE)
	await back.finished
	_cutscene = false


## Black, viscous smoke pours out of him and spreads faster than she can drift away.
func _engulf() -> void:
	stage = Stage.DOOM
	_line("warden_doom", "warden")
	Sfx.play("groan", 0.0, 0.0, 0.7)
	Sfx.play("singularity", 0.0, -2.0, 0.5)
	Fx.shake(6.0)
	witch.move_mult = SLOW
	# pull back so she can see it coming while she runs
	_cutscene = true
	var cam: Tween = main.camera.create_tween().set_parallel()
	cam.tween_property(main.camera, "zoom", Vector2.ONE * CUT_ZOOM, 0.8).set_trans(Tween.TRANS_SINE)
	cam.tween_property(main.camera, "position", Vector2(0, -16), 0.8).set_trans(Tween.TRANS_SINE)
	_doom_r = 20.0
	_doom = Node2D.new()
	_doom.position = WARDEN_AT + Vector2(0, -40)
	_doom.z_index = 60
	_doom.z_as_relative = false
	_doom.draw.connect(_draw_doom)
	main.world.add_child(_doom)
	_doom_smoke = CPUParticles2D.new()
	_doom_smoke.amount = 260
	_doom_smoke.lifetime = 1.6
	_doom_smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	_doom_smoke.emission_sphere_radius = _doom_r
	_doom_smoke.direction = Vector2(0, -1)
	_doom_smoke.spread = 180.0
	_doom_smoke.initial_velocity_min = 40.0
	_doom_smoke.initial_velocity_max = 90.0
	_doom_smoke.radial_accel_min = 20.0
	_doom_smoke.radial_accel_max = 50.0
	_doom_smoke.gravity = Vector2(0, -10)
	_doom_smoke.texture = Fx.soft()
	_doom_smoke.scale_amount_min = 1.2
	_doom_smoke.scale_amount_max = 2.6
	var g := Gradient.new()
	g.set_color(0, Color(0.0, 0.0, 0.0, 0.95))
	g.add_point(0.6, Color(0.03, 0.01, 0.05, 0.8))
	g.set_color(g.get_point_count() - 1, Color(0.08, 0.05, 0.1, 0.0))
	_doom_smoke.color_ramp = g
	_doom.add_child(_doom_smoke)
	_doom_smoke.emitting = true


func _spread_doom(delta: float) -> void:
	_doom_t += delta
	_doom_r += lerpf(DOOM_SPEED.x, DOOM_SPEED.y, clampf(_doom_t / 3.0, 0.0, 1.0)) * delta
	_doom_smoke.emission_sphere_radius = _doom_r
	_doom.queue_redraw()
	for v in _vagrants:
		if is_instance_valid(v) and v.global_position.distance_to(_doom.position) < _doom_r:
			v.modulate.a = move_toward(v.modulate.a, 0.0, delta * 3.0)
	if witch.global_position.distance_to(_doom.position) < _doom_r - 8.0 and not witch.frozen:
		_consumed()


func _draw_doom() -> void:
	# a dense core with a soft, churning edge
	for layer in 4:
		var grow: float = [1.12, 1.07, 1.03, 1.0][layer]
		var alpha: float = [0.25, 0.45, 0.7, 0.97][layer]
		var pts := PackedVector2Array()
		for k in 72:
			var a := k / 72.0 * TAU
			var r := _doom_r * grow * (1.0 + 0.05 * sin(a * 7.0 + _doom_t * (3.0 + layer)) + 0.03 * sin(a * 13.0 - _doom_t * 5.0))
			pts.append(Vector2(cos(a), sin(a)) * r)
		_doom.draw_colored_polygon(pts, Color(0.0, 0.0, 0.01, alpha))


## Swallowed. (Later this sends her back to her cabin; for now Limbo starts over.)
func _consumed() -> void:
	witch.frozen = true
	Sfx.play("singularity", 0.0, -4.0, 0.4)
	var t := _flash.create_tween()
	_flash.color = Color(0, 0, 0, 0)
	t.tween_property(_flash, "color:a", 1.0, 1.0)
	await t.finished
	await _wait(1.0)
	Game.change_level("limbo")


# ---------- the way in ----------
## Invisible walls that narrow toward him, steering her in; they lift once they've met.
func _build_funnel() -> void:
	_funnel = StaticBody2D.new()
	_funnel.collision_layer = 8
	add_child(_funnel)
	var top := WARDEN_AT.y + 190.0
	for side in [-1.0, 1.0]:
		for seg in [[Vector2(470, -350), Vector2(170, top)], [Vector2(170, top), Vector2(300, WARDEN_AT.y + 40.0)]]:
			var col := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(seg[0].x * side, seg[0].y)
			sh.b = Vector2(seg[1].x * side, seg[1].y)
			col.shape = sh
			_funnel.add_child(col)


# ---------- the portal ----------
## A doorway behind the Warden: lined with black smoke, blinding light inside. Whiskey slips through it.
func _build_portal() -> void:
	_portal = Node2D.new()
	_portal.position = PORTAL_AT
	_portal.draw.connect(_draw_portal)
	main.world.add_child(_portal)
	var glow := PointLight2D.new()
	glow.texture = Fx.soft()
	glow.texture_scale = 7.0
	glow.color = Color(1.0, 0.92, 0.6)
	glow.energy = 1.4
	glow.position = Vector2(0, -26)
	_portal.add_child(glow)
	var pts := PackedVector2Array()
	var normals := PackedVector2Array()
	# hugging the frame: points just outside its edge
	for k in 48:
		var t := k / 48.0
		if t < 0.3:
			pts.append(Vector2(-19, -t / 0.3 * 42.0))
			normals.append(Vector2.LEFT)
		elif t < 0.7:
			var a := PI + (t - 0.3) / 0.4 * PI
			pts.append(Vector2(cos(a) * 19.0, -42.0 + sin(a) * 17.0))
			normals.append(Vector2(cos(a), sin(a)))
		else:
			pts.append(Vector2(19, -(1.0 - (t - 0.7) / 0.3) * 42.0))
			normals.append(Vector2.RIGHT)
	var smoke := CPUParticles2D.new()
	smoke.amount = 140
	smoke.lifetime = 0.9
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_DIRECTED_POINTS
	smoke.emission_points = pts
	smoke.emission_normals = normals
	smoke.spread = 20.0
	smoke.initial_velocity_min = 3.0
	smoke.initial_velocity_max = 8.0
	smoke.gravity = Vector2(0, -10)
	smoke.texture = Fx.soft()
	smoke.scale_amount_min = 0.12
	smoke.scale_amount_max = 0.3
	var g := Gradient.new()
	g.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	g.add_point(0.15, Color(0.02, 0.0, 0.03, 0.9))
	g.add_point(0.7, Color(0.05, 0.03, 0.07, 0.5))
	g.set_color(g.get_point_count() - 1, Color(0.2, 0.18, 0.22, 0.0))
	smoke.color_ramp = g
	_portal.add_child(smoke)
	# fire-smoke: billowing up and away off the top and upper sides, faintly ember-lit at its root
	var plume := CPUParticles2D.new()
	plume.amount = 60
	plume.lifetime = 1.8
	plume.emission_shape = CPUParticles2D.EMISSION_SHAPE_DIRECTED_POINTS
	var up_pts := PackedVector2Array()
	var up_n := PackedVector2Array()
	for k in 16:
		var a := PI + 0.15 + k / 15.0 * (PI - 0.3)
		up_pts.append(Vector2(cos(a) * 19.0, -42.0 + sin(a) * 17.0))
		up_n.append(Vector2(cos(a) * 0.6, -1.0).normalized())
	plume.emission_points = up_pts
	plume.emission_normals = up_n
	plume.spread = 18.0
	plume.initial_velocity_min = 10.0
	plume.initial_velocity_max = 24.0
	plume.gravity = Vector2(0, -16)
	plume.damping_min = 2.0
	plume.damping_max = 6.0
	plume.texture = Fx.soft()
	plume.scale_amount_min = 0.25
	plume.scale_amount_max = 0.55
	var pc := Curve.new()
	pc.add_point(Vector2(0, 0.4))
	pc.add_point(Vector2(1, 1.6))
	plume.scale_amount_curve = pc
	var pg := Gradient.new()
	pg.set_color(0, Color(0.45, 0.12, 0.04, 0.0))
	pg.add_point(0.08, Color(0.35, 0.08, 0.03, 0.7))
	pg.add_point(0.3, Color(0.06, 0.02, 0.02, 0.75))
	pg.add_point(0.7, Color(0.12, 0.1, 0.12, 0.4))
	pg.set_color(pg.get_point_count() - 1, Color(0.3, 0.28, 0.3, 0.0))
	plume.color_ramp = pg
	_portal.add_child(plume)
	_portal_block = StaticBody2D.new()
	_portal_block.collision_layer = 1
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(34, 10)
	col.shape = r
	_portal_block.add_child(col)
	_portal.add_child(_portal_block)


func _draw_portal() -> void:
	var pulse := 0.5 + 0.5 * sin(_portal_t * 3.0)
	# the frame, then the light filling it: gold only along the arch and sides, white at the heart and threshold
	_door(Vector2.ZERO, 18.0, 42.0, Color(0.0, 0.0, 0.01))
	var cols := [Color(1.0, 0.78, 0.3), Color(1.0, 0.88, 0.5), Color(1.0, 0.95, 0.75), Color(1.0, 0.99, 0.94), Color(1, 1, 1)]
	for i in cols.size():
		_door(Vector2.ZERO, 15.0 - i * 2.6, 38.0 - i * 3.0, cols[i].lerp(Color.WHITE, 0.15 * pulse))


func _door(base: Vector2, half: float, h: float, c: Color) -> void:
	var pts := PackedVector2Array([base + Vector2(-half, 0)])
	for k in 13:
		var a := PI + k / 12.0 * PI
		pts.append(base + Vector2(cos(a) * half, -h + sin(a) * half * 0.9))
	pts.append(base + Vector2(half, 0))
	_portal.draw_colored_polygon(pts, c)


func _open_portal() -> void:
	if is_instance_valid(_portal_block):
		_portal_block.queue_free()


## Through the door: a blinding flash. (Layer 2 later; for now Limbo starts over.)
func _enter_portal() -> void:
	witch.frozen = true
	var fade := witch.create_tween()
	fade.tween_property(witch, "global_position", PORTAL_AT + Vector2(0, -3), 0.5).set_trans(Tween.TRANS_SINE)
	fade.parallel().tween_property(witch, "modulate:a", 0.0, 0.6)
	await fade.finished
	Sfx.play("arrive_flash", 0.0, -6.0)
	_flash.color = Color(1, 1, 1, 0)
	var t := _flash.create_tween()
	t.tween_property(_flash, "color:a", 1.0, 0.8)
	await t.finished
	await _wait(0.6)
	Game.change_level("limbo")


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
	warden.add_to_group("immune")
	warden.set_meta("radius", 30.0)
	warden.set_meta("on_hit", _warden_hit)
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
	var col := CollisionPolygon2D.new()
	var pts := PackedVector2Array()
	for k in 24:
		var a := k / 24.0 * TAU
		pts.append(CLOAK_C + Vector2(cos(a) * CLOAK_R.x, sin(a) * CLOAK_R.y))
	col.polygon = pts
	body.add_child(col)
	warden.add_child(body)
