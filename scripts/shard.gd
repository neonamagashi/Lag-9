class_name Shard
extends Node3D

static var _mesh: BoxMesh
static var _mat: StandardMaterial3D

var velocity := Vector3.ZERO
var damage_pct := 0.3
var ignore: Node = null
var _life := 2.0


func _ready() -> void:
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = Vector3(0.25, 0.25, 0.4)
		_mat = Art.mat(Color(0.12, 0.08, 0.18), Color(0.45, 0.25, 0.8))
	Art.mesh(_mesh, _mat, Vector3.ZERO, self)


func _physics_process(delta: float) -> void:
	_life -= delta
	velocity.y -= 14.0 * delta
	global_position += velocity * delta
	rotation += Vector3(9, 6, 4) * delta
	if _life <= 0.0 or global_position.y < -1.0:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == ignore or e.is_queued_for_deletion():
			continue
		if (e.global_position + Vector3(0, 0.6, 0)).distance_to(global_position) < 0.9:
			var lvl: int = e.level
			var dmg := damage_pct * Game.hp_for_level(Game.balance.witch_level) * Game.gap_mod(lvl - Game.balance.witch_level)
			e.take_damage(dmg, "shard")
			e.knock(velocity * 0.4, 0.3)
			queue_free()
			return
