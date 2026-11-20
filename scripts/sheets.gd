class_name Sheets
extends RefCounted

static var _cache := {}


static func add(sf: SpriteFrames, anim: String, path: String, fw: int, fh: int, count: int, fps: float, loop: bool, vertical := false, region := Rect2i(), first := 0) -> void:
	var tex: Texture2D = load(path)
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	for i in range(first, first + count):
		var at := AtlasTexture.new()
		at.atlas = tex
		var r := Rect2(0, i * fh, fw, fh) if vertical else Rect2(i * fw, 0, fw, fh)
		if region.size != Vector2i.ZERO:
			r = Rect2(r.position.x + region.position.x, r.position.y + region.position.y, region.size.x, region.size.y)
		at.region = r
		sf.add_frame(anim, at)


static func strip(path: String, fw: int, fh: int) -> Array[Texture2D]:
	var tex: Texture2D = load(path)
	var out: Array[Texture2D] = []
	for i in tex.get_width() / fw:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		out.append(at)
	return out
