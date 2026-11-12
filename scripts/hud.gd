class_name Hud
extends CanvasLayer

const ABILITIES := [
	["pierce", "Pierce"],
	["snap", "Snap"],
	["send", "Send"],
	["draw", "Draw"],
	["rend", "Rend"],
	["singularity", "Singularity"],
]

var _hp_bar: ProgressBar
var _hp_text: Label
var _whisky: Label
var _field: Label
var _level: Label
var _toast: Label
var _toast_t := 0.0
var _ability_labels := {}


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 26)
	cross.add_theme_color_override("font_color", Color(1, 0.92, 0.75, 0.9))
	cross.add_theme_constant_override("outline_size", 6)
	cross.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.position -= Vector2(8, 16)
	root.add_child(cross)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.position = Vector2(28, -150)
	bottom.add_theme_constant_override("separation", 6)
	root.add_child(bottom)
	_field = _label(24)
	bottom.add_child(_field)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(320, 22)
	_hp_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.12, 0.85)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.9, 0.72, 0.3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.22, 0.28)
	_hp_bar.add_theme_stylebox_override("background", bg)
	_hp_bar.add_theme_stylebox_override("fill", fill)
	bottom.add_child(_hp_bar)
	_hp_text = _label(18)
	bottom.add_child(_hp_text)
	_whisky = _label(20)
	bottom.add_child(_whisky)

	var abil := HBoxContainer.new()
	abil.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	abil.position = Vector2(-330, -100)
	abil.add_theme_constant_override("separation", 14)
	root.add_child(abil)
	for a in ABILITIES:
		var l := _label(17)
		l.custom_minimum_size = Vector2(100, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		abil.add_child(l)
		_ability_labels[a[0]] = l

	_level = _label(22)
	_level.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_level.position = Vector2(-120, 18)
	_level.custom_minimum_size = Vector2(240, 0)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_level)

	_toast = _label(24)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(-300, 60)
	_toast.custom_minimum_size = Vector2(600, 0)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	root.add_child(_toast)


func connect_witch(w: Witch) -> void:
	w.toast.connect(show_toast)
	w.hp_changed.connect(_on_hp)
	_on_hp(w.hp, Game.witch_max_hp())


func show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.2
	_toast.modulate.a = 1.0


func _on_hp(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = maxf(0.0, hp)
	_hp_text.text = "%d / %d" % [int(maxf(0.0, hp)), int(max_hp)]


func _process(delta: float) -> void:
	var w := Game.witch
	if not w:
		return
	_toast_t -= delta
	_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
	if not w.field_on:
		_field.text = "FIELD: OFF  [%s]" % Controls.label("toggle_field")
		_field.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	elif w.field_mode == Witch.FieldMode.CRUSH:
		_field.text = "FIELD: CRUSH  [%s]" % Controls.label("flip_gravity")
		_field.add_theme_color_override("font_color", Witch.CRUSH_COLOR)
	else:
		_field.text = "FIELD: LIFT  [%s]" % Controls.label("flip_gravity")
		_field.add_theme_color_override("font_color", Witch.LIFT_COLOR)
	_whisky.text = "Whisky x%d  [%s]" % [w.whisky, Controls.label("drink_whisky")]
	_level.text = "Witch LV %d   ·   %d defeated" % [Game.balance.witch_level, Game.kills]
	for a in ABILITIES:
		var l: Label = _ability_labels[a[0]]
		var key := Controls.label(a[0])
		var cd := 0.0
		if a[0] == "pierce":
			cd = w.pierce_cd
		elif a[0] == "snap":
			cd = w.snap_cd
		if a[0] in ["send", "draw", "rend", "singularity"]:
			l.text = "%s\n[%s]\nsoon" % [a[1], key]
			l.modulate = Color(1, 1, 1, 0.4)
		elif cd > 0.05:
			l.text = "%s\n[%s]\n%.1fs" % [a[1], key, cd]
			l.modulate = Color(1, 1, 1, 0.6)
		else:
			l.text = "%s\n[%s]\nready" % [a[1], key]
			l.modulate = Color(1, 1, 1, 1)


func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
