class_name Actor
extends CharacterBody2D

const FLASH := preload("res://scripts/flash.gdshader")
const Z_GRAVITY := 520.0

var z := 0.0
var vz := 0.0
var hp := 100.0
var max_hp := 100.0
var facing := 1
var flash := 0.0
var squash := 0.0
var shadow_size := Vector2(8, 3)
var draw_shadow := true
var visual: Node2D
var sprite: AnimatedSprite2D
var anchors := {}
var _mat: ShaderMaterial


func _build_visual(frames: SpriteFrames) -> void:
	visual = Node2D.new()
	add_child(visual)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	visual.add_child(sprite)
	_mat = ShaderMaterial.new()
	_mat.shader = FLASH
	sprite.material = _mat
	var sh := Node2D.new()
	sh.z_index = -1
	sh.draw.connect(func():
		if draw_shadow:
			var k := clampf(1.0 - z / 60.0, 0.45, 1.0)
			var s := shadow_size * k
			var pts := PackedVector2Array()
			for i in 16:
				var a := i / 16.0 * TAU
				pts.append(Vector2(cos(a) * s.x, sin(a) * s.y))
			sh.draw_colored_polygon(pts, Color(0, 0, 0, 0.35 * k)))
	add_child(sh)
	set_meta("shadow", sh)


func play(anim: String, restart := false) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim or restart or not sprite.is_playing():
		sprite.play(anim)
		if restart:
			sprite.frame = 0
			sprite.frame_progress = 0.0


func _update_visual(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 6.0)
	_mat.set_shader_parameter("flash", flash)
	_mat.set_shader_parameter("squash_tint", squash)
	var a: Vector3 = anchors.get(sprite.animation, Vector3(16, 16, 32))
	sprite.flip_h = facing < 0
	sprite.offset = Vector2(-(a.z - a.x) if facing < 0 else -a.x, -a.y)
	visual.position = Vector2(0, -z)
	visual.scale = Vector2(1.0 + squash * 0.35, 1.0 - squash * 0.4)
	(get_meta("shadow") as Node2D).queue_redraw()


func _update_z(delta: float) -> float:
	if z <= 0.0 and vz <= 0.0:
		z = 0.0
		vz = 0.0
		return 0.0
	vz -= Z_GRAVITY * delta
	z += vz * delta
	if z <= 0.0:
		var impact := -vz
		z = 0.0
		vz = 0.0
		return impact
	return 0.0
