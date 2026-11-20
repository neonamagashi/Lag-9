class_name Hud
extends CanvasLayer

const SLOTS := [["pierce", "LMB", "Pierce"], ["grab", "RMB", "Grab"], ["send", "F", "Send"], ["draw", "T", "Draw"], ["rend", "R", "Rend"], ["snap", "Spc", "Snap"], ["jump", "Shft", "Jump"], ["singularity", "G", "Sing."]]
const MAX_CD := {"pierce": Witch.PIERCE_CD, "grab": 0.4, "send": Witch.SEND_CD, "draw": Witch.DRAW_CD, "rend": Witch.REND_CD, "snap": Witch.SNAP_CD, "jump": 0.2, "singularity": Witch.SING_CD}
const INK := Color(0.07, 0.05, 0.09)
const HELP := "WASD move   LMB Pierce   RMB Grab, RMB again (hold) Release   F Send   T Draw   R Rend\nSpace Snap   Shift Jump (hold to charge)   Q Crush/Lift   G Singularity   1 Whisky   E Interact   Esc Settings"

var witch: Witch
var main: Node
var help := true
var show_abilities := true
var _canvas: Control
var _banner_t := 0.0
var _banner := ["", ""]
var _help_t := 7.0
var _help_auto := true


func _ready() -> void:
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)


func banner(title: String, sub: String) -> void:
	_banner = [title, sub]
	_banner_t = 2.5 if sub == "" else 9999.0


func _process(delta: float) -> void:
	_banner_t -= delta
	_help_t -= delta
	if _help_auto and _help_t < 0.0:
		help = false
		_help_auto = false
	_canvas.queue_redraw()


func _text(pos: Vector2, s: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := ThemeDB.fallback_font
	if align == HORIZONTAL_ALIGNMENT_RIGHT and width <= 0.0:
		pos.x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		align = HORIZONTAL_ALIGNMENT_LEFT
		width = -1.0
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_canvas.draw_string(f, pos + o, s, align, width, size, INK)
	_canvas.draw_string(f, pos, s, align, width, size, color)


func _bar(pos: Vector2, size: Vector2, k: float, color: Color) -> void:
	_canvas.draw_rect(Rect2(pos - Vector2(1, 1), size + Vector2(2, 2)), INK)
	_canvas.draw_rect(Rect2(pos, size), Color(0.18, 0.15, 0.22))
	_canvas.draw_rect(Rect2(pos, Vector2(size.x * clampf(k, 0, 1), size.y)), color)
	_canvas.draw_rect(Rect2(pos, Vector2(size.x * clampf(k, 0, 1), 1)), color.lightened(0.35))


func _draw_hud() -> void:
	if not witch:
		return
	var vs := _canvas.size
	if not show_abilities:
		_draw_common(vs)
		return
	_bar(Vector2(8, 8), Vector2(84, 6), witch.hp / witch.max_hp, Color(0.85, 0.3, 0.38))
	_bar(Vector2(8, 18), Vector2(84, 4), witch.mana / 100.0, Color(0.36, 0.8, 0.78))
	_text(Vector2(96, 15), "%d" % ceil(witch.hp), 8, Color(1, 0.9, 0.9))
	for i in witch.whisky:
		var p := Vector2(9 + i * 8, 26)
		_canvas.draw_rect(Rect2(p + Vector2(1, 3), Vector2(5, 6)), Color(0.6, 0.36, 0.16))
		_canvas.draw_rect(Rect2(p + Vector2(2, 0), Vector2(3, 3)), Color(0.5, 0.3, 0.12))
		_canvas.draw_rect(Rect2(p + Vector2(2, 5), Vector2(3, 2)), Color(0.9, 0.82, 0.72))
	_text(Vector2(10 + witch.whisky * 8, 34), "[1]", 7, Color(0.8, 0.75, 0.7))
	var mode := "CRUSH" if witch.mode == Witch.Mode.CRUSH else "LIFT"
	var mc := Witch.CRUSH_COLOR if witch.mode == Witch.Mode.CRUSH else Witch.LIFT_COLOR
	_text(Vector2(vs.x - 8, 15), "Field: %s  [Q]" % mode, 8, mc, HORIZONTAL_ALIGNMENT_RIGHT, 0)
	if main.wave >= 0:
		_text(Vector2(vs.x - 8, 26), "Wave %d/%d" % [main.wave + 1, main.waves.size()], 8, Color(0.9, 0.85, 0.95), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	var sw := 30.0
	var x0 := vs.x / 2.0 - SLOTS.size() * (sw + 3) / 2.0
	for i in SLOTS.size():
		var s: Array = SLOTS[i]
		var r := Rect2(x0 + i * (sw + 3), vs.y - 26, sw, 20)
		var cd: float = witch.cooldowns[s[0]]
		var ready: bool = cd <= 0.0 and (s[0] != "singularity" or witch.mana >= Witch.SING_COST)
		_canvas.draw_rect(r.grow(1), INK)
		_canvas.draw_rect(r, Color(0.2, 0.17, 0.26) if ready else Color(0.12, 0.1, 0.15))
		if cd > 0.0:
			var k: float = cd / MAX_CD[s[0]]
			_canvas.draw_rect(Rect2(r.position + Vector2(0, r.size.y * (1.0 - k)), Vector2(r.size.x, r.size.y * k)), Color(0.05, 0.04, 0.07, 0.75))
		var charge := {"send": [witch.send_charge, Witch.SEND_MAX_CHARGE], "draw": [witch.draw_charge, Witch.DRAW_MAX_CHARGE],
			"grab": [witch.throw_charge, Witch.THROW_MAX_CHARGE], "jump": [witch.jump_charge, Witch.JUMP_MAX_CHARGE]}
		if charge.has(s[0]) and charge[s[0]][0] >= 0.0:
			_canvas.draw_rect(Rect2(r.position, Vector2(r.size.x * charge[s[0]][0] / charge[s[0]][1], 2)), Color(0.75, 0.65, 1.0))
		var tc := Color(0.75, 1.0, 0.95) if ready else Color(0.5, 0.48, 0.55)
		var label: String = s[2]
		if s[0] == "grab" and witch.held:
			label = "Release"
			tc = Color(1.0, 0.85, 0.6)
		_text(r.position + Vector2(0, 9), label, 7 if label.length() < 7 else 6, tc, HORIZONTAL_ALIGNMENT_CENTER, sw)
		_text(r.position + Vector2(0, 18), s[1], 6, Color(0.7, 0.65, 0.75), HORIZONTAL_ALIGNMENT_CENTER, sw)
	_draw_common(vs)
	if witch.singularity_t > 0.0:
		_bar(Vector2(vs.x / 2.0 - 40, vs.y - 32), Vector2(80, 2), witch.singularity_t / Witch.SING_TIME, Witch.CRUSH_COLOR)



func _draw_common(vs: Vector2) -> void:
	if _banner_t > 0.0:
		var a := clampf(_banner_t, 0.0, 1.0)
		_text(Vector2(0, vs.y * 0.36), _banner[0], 16, Color(0.9, 0.85, 1.0, a), HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		if _banner[1] != "":
			_text(Vector2(0, vs.y * 0.36 + 14), _banner[1], 8, Color(0.8, 0.8, 0.85, a), HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	if witch.dead:
		_text(Vector2(0, vs.y * 0.4), "Whisky waits", 16, Color(1.0, 0.6, 0.6), HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		_text(Vector2(0, vs.y * 0.4 + 14), "F5 to try again", 8, Color(0.85, 0.8, 0.85), HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	if help and show_abilities:
		var lines := HELP.split("\n")
		_canvas.draw_rect(Rect2(0, vs.y - 58, vs.x, 26), Color(0.05, 0.04, 0.07, 0.6))
		for i in lines.size():
			_text(Vector2(0, vs.y - 48 + i * 10), lines[i], 7, Color(0.85, 0.82, 0.9), HORIZONTAL_ALIGNMENT_CENTER, vs.x)
