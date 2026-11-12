class_name ControlsMenu
extends CanvasLayer

var _buttons := {}
var _listening := ""
var _sens: HSlider
var _sens_label: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.07, 0.14, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.9, 0.72, 0.3)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Controls"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.35))
	col.add_child(title)
	var hint := Label.new()
	hint.text = "Click a binding, then press a key or mouse button. Esc cancels."
	hint.add_theme_color_override("font_color", Color(0.7, 0.66, 0.8))
	col.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)
	for a in Controls.ACTIONS:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = a[1]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 32)
		b.pressed.connect(_listen.bind(a[0]))
		row.add_child(b)
		rows.add_child(row)
		_buttons[a[0]] = b
	var sens_row := HBoxContainer.new()
	_sens_label = Label.new()
	_sens_label.custom_minimum_size = Vector2(220, 0)
	sens_row.add_child(_sens_label)
	_sens = HSlider.new()
	_sens.min_value = 0.0005
	_sens.max_value = 0.008
	_sens.step = 0.0001
	_sens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sens.value_changed.connect(_on_sens)
	sens_row.add_child(_sens)
	col.add_child(sens_row)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.pressed.connect(func():
		Controls.reset_defaults()
		_refresh())
	actions.add_child(reset)
	var resume := Button.new()
	resume.text = "Resume"
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(close)
	actions.add_child(resume)
	col.add_child(actions)


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close() -> void:
	_listening = ""
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Controls.save()


func _refresh() -> void:
	for a in _buttons:
		_buttons[a].text = Controls.label(a)
	_sens.set_value_no_signal(Controls.sensitivity)
	_sens_label.text = "Mouse sensitivity  %.4f" % Controls.sensitivity


func _listen(action: String) -> void:
	_listening = action
	_buttons[action].text = "Press a key or button…"


func _on_sens(v: float) -> void:
	Controls.sensitivity = v
	_sens_label.text = "Mouse sensitivity  %.4f" % v


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _listening != "":
		var new_event: InputEvent = null
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				_listening = ""
				_refresh()
				get_viewport().set_input_as_handled()
				return
			new_event = InputEventKey.new()
			new_event.physical_keycode = event.physical_keycode
		elif event is InputEventMouseButton and event.pressed and event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			new_event = InputEventMouseButton.new()
			new_event.button_index = event.button_index
		if new_event:
			Controls.bind(_listening, new_event)
			_listening = ""
			_refresh()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
