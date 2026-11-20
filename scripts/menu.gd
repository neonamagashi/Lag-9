class_name Menu
extends CanvasLayer

var _panel: PanelContainer
var _level_buttons := {}


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.1, 0.94)
	sb.border_color = Color(0.5, 0.42, 0.75)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(150, 60)
	_panel.custom_minimum_size = Vector2(180, 0)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	box.add_child(_label("Settings", 12))
	box.add_child(_label("Level", 8))
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
	_panel.visible = false


func _label(t: String, size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	return l


func _button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 8)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_panel.visible = not _panel.visible
	get_tree().paused = _panel.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_HIDDEN
