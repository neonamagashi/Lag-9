class_name TiledLevel
extends RefCounted

var width := 0
var height := 0
var tile := 32
var solid := {}
var size := Vector2.ZERO
var astar := AStarGrid2D.new()


func build(json_path: String, below: Node2D, sorted: Node2D, statics: Node2D) -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	width = d.width
	height = d.height
	tile = d.tile
	size = Vector2(width * tile, height * tile)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile, tile)
	var sources: Array[TileSetAtlasSource] = []
	var remap := []
	for s in d.tilesets:
		var src := TileSetAtlasSource.new()
		src.texture = load(s.image)
		src.texture_region_size = Vector2i(tile, tile)
		ts.add_source(src)
		sources.append(src)
		remap.append({})
	var z := -20
	for layer in d.layers:
		var tl := TileMapLayer.new()
		tl.tile_set = ts
		tl.name = layer.name
		var is_wall: bool = layer.name == "wall-8"
		if is_wall:
			tl.y_sort_enabled = true
			sorted.add_child(tl)
		else:
			tl.z_index = z
			z += 1
			below.add_child(tl)
		for c in layer.cells:
			var si: int = c[2]
			var lid: int = remap[si].get(int(c[3]), int(c[3]))
			var cols: int = d.tilesets[si].columns
			var coords := Vector2i(lid % cols, lid / cols)
			var src := sources[si]
			if not src.has_tile(coords):
				src.create_tile(coords)
				var anim: Dictionary = d.tilesets[si].anims.get(str(lid), {})
				if not anim.is_empty():
					src.set_tile_animation_columns(coords, 0)
					src.set_tile_animation_frames_count(coords, anim.frames.size())
					for i in anim.frames.size():
						src.set_tile_animation_frame_duration(coords, i, anim.ms / 1000.0)
			var alt := 0
			if int(c[4]) & 1:
				alt |= TileSetAtlasSource.TRANSFORM_FLIP_H
			if int(c[4]) & 2:
				alt |= TileSetAtlasSource.TRANSFORM_FLIP_V
			tl.set_cell(Vector2i(c[0], c[1]), si, coords, alt)
	for i in d.solid:
		solid[int(i)] = true
	_collision(statics)
	astar.region = Rect2i(0, 0, width, height)
	astar.cell_size = Vector2(tile, tile)
	astar.offset = Vector2(tile, tile) * 0.5
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in height:
		for x in width:
			if is_solid(x, y):
				astar.set_point_solid(Vector2i(x, y))


func _collision(parent: Node2D) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	parent.add_child(body)
	for y in height:
		var x := 0
		while x < width:
			if not is_solid(x, y):
				x += 1
				continue
			var x0 := x
			while x < width and is_solid(x, y):
				x += 1
			var col := CollisionShape2D.new()
			var r := RectangleShape2D.new()
			r.size = Vector2((x - x0) * tile, tile)
			col.shape = r
			col.position = Vector2((x0 + x) * tile / 2.0, y * tile + tile / 2.0)
			body.add_child(col)
	var bounds := StaticBody2D.new()
	bounds.collision_layer = 8
	parent.add_child(bounds)
	for r in [Rect2(-40, -40, size.x + 80, 40), Rect2(-40, size.y, size.x + 80, 40), Rect2(-40, 0, 40, size.y), Rect2(size.x, 0, 40, size.y)]:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.get_center()
		bounds.add_child(col)


func is_solid(x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= width or y >= height or solid.has(y * width + x)


func open_at(p: Vector2) -> bool:
	return not is_solid(int(p.x / tile), int(p.y / tile))


func reachable_from(p: Vector2) -> Array[Vector2]:
	var start := Vector2i(int(p.x / tile), int(p.y / tile))
	var seen := {start: true}
	var q: Array[Vector2i] = [start]
	var out: Array[Vector2] = []
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		out.append(Vector2(c) * tile + Vector2(tile, tile) * 0.5)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not seen.has(n) and not is_solid(n.x, n.y):
				seen[n] = true
				q.append(n)
	return out


func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := Vector2i(clampi(int(from.x / tile), 0, width - 1), clampi(int(from.y / tile), 0, height - 1))
	var b := Vector2i(clampi(int(to.x / tile), 0, width - 1), clampi(int(to.y / tile), 0, height - 1))
	if astar.is_point_solid(a) or astar.is_point_solid(b):
		return PackedVector2Array()
	return astar.get_point_path(a, b)


func nearest_open(p: Vector2) -> Vector2:
	var best := p
	var best_d := INF
	var c := Vector2i(int(p.x / tile), int(p.y / tile))
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var n := c + Vector2i(dx, dy)
			if not is_solid(n.x, n.y):
				var q := Vector2(n) * tile + Vector2(tile, tile) * 0.5
				if q.distance_to(p) < best_d:
					best_d = q.distance_to(p)
					best = q
	return best
