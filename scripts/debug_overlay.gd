class_name DebugOverlay
extends CanvasLayer

const SCALES := [0.33, 0.5, 0.75, 1.0]

var _label: Label
var _panel: PanelContainer
var _t := 0.0
var _scale_i := 1


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.1, 0.8)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.9, 0.72, 0.3, 0.6)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = Vector2(16, 16)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 15)
	_panel.add_child(_label)
	_scale_i = SCALES.find(get_viewport().scaling_3d_scale)
	if _scale_i < 0:
		_scale_i = 1


func toggle() -> void:
	_panel.visible = not _panel.visible


func cycle_scale() -> float:
	_scale_i = (_scale_i + 1) % SCALES.size()
	get_viewport().scaling_3d_scale = SCALES[_scale_i]
	return SCALES[_scale_i]


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0 or not _panel.visible:
		return
	_t = 0.25
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var lines := PackedStringArray([
		"FPS              %d" % Engine.get_frames_per_second(),
		"Frame (process)  %.2f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0),
		"Physics step     %.2f ms" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0),
		"Draw calls       %d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"Objects drawn    %d" % Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"Primitives       %d" % Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"Video memory     %.1f MB" % (Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0),
		"Static memory    %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0),
		"Nodes            %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"Orphan nodes     %d%s" % [orphans, "  << LEAK" if orphans > 0 else ""],
		"Enemies          %d" % get_tree().get_nodes_in_group("enemies").size(),
		"3D render        %d×%d (%d%%)" % [int(size.x * vp.scaling_3d_scale), int(size.y * vp.scaling_3d_scale), int(vp.scaling_3d_scale * 100)],
		"",
		"Pierce hits to kill by gap:",
		"  %s" % _hits_row(),
		"",
		"F1 overlay   F2 spawn wave   F3 render scale",
		"F4 clear foes   [ / ] witch level   F6 heal",
		"F7 snap rank %d   F8 pierce rank %d   F9 reset cooldowns" % [Game.balance.snap_rank + 1, Game.balance.pierce_rank + 1],
		"F10 send/draw rank %d   F11 rend rank %d   Esc controls" % [Game.balance.send_rank + 1, Game.balance.rend_rank + 1],
	])
	_label.text = "\n".join(lines)
	_label.add_theme_color_override("font_color", Color(1, 0.55, 0.5) if orphans > 0 else Color(0.92, 0.9, 0.98))


func _hits_row() -> String:
	var parts := PackedStringArray()
	for g in [0, 1, 2, 3, 4, 5, 8]:
		parts.append("%+d:%d" % [g, Game.pierce_hits_to_kill(g)])
	return "  ".join(parts)
