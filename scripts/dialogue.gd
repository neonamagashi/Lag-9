class_name Dialogue
extends Node2D

const CPS := 28.0

## Fires when typing reaches an *action* in the line, e.g. "*buuurp*".
signal cue(action: String)

var text := ""
var voice := "babble"
var pitch := 1.0
var color := Color(0.12, 0.1, 0.16)
var size := 8
var hold := 2.2
var height := 46.0
var _label: Label
var _shown := 0.0
var _blip := 0
var _done_t := 0.0
var cps := CPS
var _cue_at := {}


static func say(speaker: Node2D, line: String, v := "babble", p := 1.0, c := Color(0.12, 0.1, 0.16), h := 46.0, font := 8) -> Dialogue:
	for old in speaker.get_children():
		if old is Dialogue:
			old.queue_free()
	var d := Dialogue.new()
	d.text = line
	d.voice = v
	d.pitch = p
	d.color = c
	d.height = h
	d.size = font
	d.hold = 1.6 + line.length() * 0.05
	speaker.add_child(d)
	return d


func _ready() -> void:
	z_index = 30
	z_as_relative = false
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", size)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(160, 0)
	_label.position = Vector2(-80, -height)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.visible_characters = 0
	var i := text.find("*")
	while i >= 0:
		var j := text.find("*", i + 1)
		if j < 0:
			break
		_cue_at[i] = text.substr(i + 1, j - i - 1)
		i = text.find("*", j + 1)
	_label.text = text
	add_child(_label)


func _process(delta: float) -> void:
	if _shown < text.length():
		var before := int(_shown)
		_shown += delta * cps
		var n := int(_shown)
		_label.visible_characters = n
		for k in _cue_at:
			if k >= before and k < n:
				cue.emit(_cue_at[k])
		if n / 2 > _blip and n <= text.length() and text[mini(n, text.length()) - 1] != " ":
			_blip = n / 2
			if voice != "":
				Sfx.play(voice, 0.12, -14.0 if voice == "mumble" else -10.0, pitch)
		return
	_done_t += delta
	if _done_t > hold:
		modulate.a -= delta * 2.0
		if modulate.a <= 0.0:
			queue_free()


func finished() -> bool:
	return _shown >= text.length() and _done_t > hold


## Typed out and given a moment to be read.
func read() -> bool:
	return _shown >= text.length() and _done_t > minf(hold, 0.9 + text.length() * 0.03)
