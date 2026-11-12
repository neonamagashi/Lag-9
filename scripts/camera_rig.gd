class_name CameraRig
extends Node3D

var target: Node3D
var yaw := 0.0
var pitch := -0.32
var pitch_node: Node3D
var arm: SpringArm3D
var camera: Camera3D


func _ready() -> void:
	top_level = true
	pitch_node = Node3D.new()
	add_child(pitch_node)
	arm = SpringArm3D.new()
	arm.spring_length = 6.0
	arm.collision_mask = 1
	arm.margin = 0.25
	arm.position = Vector3(0.7, 0, 0)
	pitch_node.add_child(arm)
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	arm.shape = probe
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.far = 250.0
	arm.add_child(camera)
	camera.make_current()
	if target is CollisionObject3D:
		arm.add_excluded_object(target.get_rid())
	if target:
		global_position = target.global_position + Vector3(0, 1.7, 0)


func forward() -> Vector3:
	return -camera.global_basis.z


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * Controls.sensitivity
		pitch = clampf(pitch - event.relative.y * Controls.sensitivity, -1.25, 0.65)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = maxf(2.5, arm.spring_length - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = minf(11.0, arm.spring_length + 0.5)


func _process(delta: float) -> void:
	if not target:
		return
	var goal := target.get_global_transform_interpolated().origin + Vector3(0, 1.7, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-delta * 18.0))
	rotation.y = yaw
	pitch_node.rotation.x = pitch
