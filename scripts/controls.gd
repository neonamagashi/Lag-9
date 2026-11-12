extends Node

const PATH := "user://controls.cfg"
const ACTIONS := [
	["move_forward", "Move forward"],
	["move_back", "Move back"],
	["move_left", "Move left"],
	["move_right", "Move right"],
	["jump", "Jump / gravity jump"],
	["sprint", "Sprint"],
	["snap", "Snap (dodge)"],
	["pierce", "Pierce"],
	["send", "Send"],
	["draw", "Draw"],
	["rend", "Rend"],
	["singularity", "Singularity"],
	["flip_gravity", "Flip crush / lift"],
	["toggle_field", "Field on / off"],
	["drink_whisky", "Drink whisky"],
]
const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "Mouse L",
	MOUSE_BUTTON_RIGHT: "Mouse R",
	MOUSE_BUTTON_MIDDLE: "Mouse Middle",
	MOUSE_BUTTON_XBUTTON1: "Mouse 4",
	MOUSE_BUTTON_XBUTTON2: "Mouse 5",
}

var sensitivity := 0.0025
var _defaults := {}
var _labels := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_defaults = {
		"move_forward": _key(KEY_W),
		"move_back": _key(KEY_S),
		"move_left": _key(KEY_A),
		"move_right": _key(KEY_D),
		"jump": _mouse(MOUSE_BUTTON_XBUTTON2),
		"sprint": _key(KEY_SHIFT),
		"snap": _key(KEY_SPACE),
		"pierce": _mouse(MOUSE_BUTTON_LEFT),
		"send": _mouse(MOUSE_BUTTON_RIGHT),
		"draw": _key(KEY_E),
		"rend": _key(KEY_R),
		"singularity": _key(KEY_G),
		"flip_gravity": _key(KEY_Q),
		"toggle_field": _key(KEY_F),
		"drink_whisky": _key(KEY_1),
	}
	for a in ACTIONS:
		if not InputMap.has_action(a[0]):
			InputMap.add_action(a[0])
	load_bindings()


func bind(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_labels[action] = _describe(event)


func reset_defaults() -> void:
	for a in ACTIONS:
		bind(a[0], _defaults[a[0]].duplicate())
	sensitivity = 0.0025
	save()


func load_bindings() -> void:
	var cfg := ConfigFile.new()
	var ok := cfg.load(PATH) == OK
	if ok:
		sensitivity = cfg.get_value("mouse", "sensitivity", sensitivity)
	for a in ACTIONS:
		var ev: InputEvent = _defaults[a[0]].duplicate()
		if ok and cfg.has_section_key("bindings", a[0]):
			var parsed := _decode(cfg.get_value("bindings", a[0]))
			if parsed:
				ev = parsed
		bind(a[0], ev)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("mouse", "sensitivity", sensitivity)
	for a in ACTIONS:
		var evs := InputMap.action_get_events(a[0])
		if not evs.is_empty():
			cfg.set_value("bindings", a[0], _encode(evs[0]))
	cfg.save(PATH)


func label(action: String) -> String:
	return _labels.get(action, "Unbound")


func _describe(e: InputEvent) -> String:
	if e is InputEventKey:
		return OS.get_keycode_string(e.physical_keycode)
	if e is InputEventMouseButton:
		return MOUSE_NAMES.get(e.button_index, "Mouse %d" % e.button_index)
	return e.as_text()


func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	return e


func _mouse(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	return e


func _encode(e: InputEvent) -> String:
	if e is InputEventKey:
		return "key:%d" % e.physical_keycode
	if e is InputEventMouseButton:
		return "mouse:%d" % e.button_index
	return ""


func _decode(s: String) -> InputEvent:
	var parts := s.split(":")
	if parts.size() != 2:
		return null
	if parts[0] == "key":
		return _key(int(parts[1]) as Key)
	if parts[0] == "mouse":
		return _mouse(int(parts[1]) as MouseButton)
	return null
