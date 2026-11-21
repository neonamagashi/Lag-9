class_name Menu
extends CanvasLayer

var _panel: PanelContainer
var _root: Control
var _level_buttons := {}


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	# a full-screen dimmer that centres the panel, whatever the monitor's resolution
	_root = ColorRect.new()
	_root.color = Color(0.02, 0.01, 0.04, 0.55)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.1, 0.96)
	sb.border_color = Color(0.5, 0.42, 0.75)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.custom_minimum_size = Vector2(220, 0)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	box.add_child(_label("Settings", 18))
	box.add_child(_label("Level", 11))
	for id in Game.LEVELS:
		var b := _button(Game.LEVELS[id])
		b.toggle_mode = true
		b.button_pressed = Game.level_choice == id
		b.pressed.connect(func(): Game.change_level(id))
		_level_buttons[id] = b
		box.add_child(b)
	box.add_child(_label("", 4))
	var resume := _button("Resume")
	resume.pressed.connect(toggle)
	box.add_child(resume)
	var restart := _button("Restart level")
	restart.pressed.connect(func(): Game.change_level(Game.level_choice))
	box.add_child(restart)
	var quit := _button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	_root.visible = false


func _label(t: String, size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	return l


func _button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size = Vector2(0, 20)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_root.visible = not _root.visible
	get_tree().paused = _root.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _root.visible else Input.MOUSE_MODE_HIDDEN
