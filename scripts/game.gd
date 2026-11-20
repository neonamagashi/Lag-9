extends Node

const LEVELS := {"limbo": "Limbo (Circle 1)", "ruins": "Ancient Ruins (test arena)"}

var level_choice := "limbo"
var _reverb_bus := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioServer.add_bus()
	_reverb_bus = AudioServer.bus_count - 1
	AudioServer.set_bus_name(_reverb_bus, "World")
	AudioServer.set_bus_send(_reverb_bus, "Master")
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.9
	rv.damping = 0.25
	rv.spread = 1.0
	rv.wet = 0.38
	rv.dry = 0.85
	rv.predelay_msec = 40.0
	AudioServer.add_bus_effect(_reverb_bus, rv)
	set_reverb(false)


func set_reverb(on: bool) -> void:
	AudioServer.set_bus_effect_enabled(_reverb_bus, 0, on)


func change_level(id: String) -> void:
	level_choice = id
	get_tree().paused = false
	get_tree().reload_current_scene()
