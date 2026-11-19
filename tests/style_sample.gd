extends Node3D

const TOON := preload("res://shaders/style/toon.gdshader")
const OUTLINE := preload("res://shaders/style/outline.gdshader")
const POST := preload("res://shaders/style/post.gdshader")
const RUINS := "res://assets/environment/Ultimate Modular Ruins Pack/FBX/"
const NATURE := "res://assets/environment/Stylized Nature MegaKit/glTF/"

var mode := "sable"
var retro := false
var cam: Camera3D
var frames := 0
var ink := Color(0.16, 0.11, 0.1)
var pastel := 0.15


func _ready() -> void:
	mode = OS.get_environment("STYLE")
	retro = OS.get_environment("RETRO") == "1"
	_world()
	_ground()
	_props()
	_witch()
	_enemy("res://models/acolyte/acolyte.glb", Vector3(-3.5, 0, -9.0), 1.8, 0.6)
	_enemy("res://models/seer/seer.glb", Vector3(4.5, 0.4, -13.0), 2.3, -0.5)
	_enemy("res://models/gnawling/gnawling.glb", Vector3(1.4, 0, -6.0), 0.65, 0.3)
	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 400
	add_child(cam)
	cam.position = Vector3(1.9, 1.75, 3.2)
	cam.look_at(Vector3(-0.6, 1.3, -5.0))
	if mode == "sable":
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1, 1)
		q.mesh = qm
		q.extra_cull_margin = 16384.0
		var pm := ShaderMaterial.new()
		pm.shader = POST
		pm.set_shader_parameter("line_color", ink)
		pm.set_shader_parameter("retro", retro)
		q.material_override = pm
		cam.add_child(q)
		q.position.z = -1.0


func _world() -> void:
	var env := Environment.new()
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	if mode == "sable":
		var sky := Sky.new()
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = Color(0.66, 0.78, 0.8)
		sm.sky_horizon_color = Color(0.98, 0.9, 0.76)
		sm.ground_horizon_color = Color(0.98, 0.9, 0.76)
		sm.ground_bottom_color = Color(0.9, 0.78, 0.62)
		sm.sun_angle_max = 8.0
		sm.sun_curve = 0.05
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.fog_enabled = true
		env.fog_light_color = Color(0.97, 0.89, 0.76)
		env.fog_density = 0.012
		env.fog_sky_affect = 0.0
		sun.rotation_degrees = Vector3(-32, 40, 0)
		sun.light_color = Color(1.0, 0.97, 0.9)
		sun.light_energy = 0.85
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.19, 0.2, 0.29)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.58, 0.6, 0.78)
		env.ambient_light_energy = 0.55
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.fog_enabled = true
		env.fog_light_color = Color(0.21, 0.22, 0.32)
		env.fog_density = 0.03
		sun.rotation_degrees = Vector3(-52, -35, 0)
		sun.light_color = Color(1.0, 0.94, 0.85)
		sun.light_energy = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	add_child(sun)


func _ground() -> void:
	var n := FastNoiseLite.new()
	n.frequency = 0.012
	n.seed = 7
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var size := 260.0
	var res := 130
	var step := size / res
	for z in res:
		for x in res:
			var p := [Vector2(x, z), Vector2(x + 1, z), Vector2(x + 1, z + 1), Vector2(x, z), Vector2(x + 1, z + 1), Vector2(x, z + 1)]
			for g in p:
				var wx: float = g.x * step - size * 0.5
				var wz: float = g.y * step - size * 0.5
				st.add_vertex(Vector3(wx, _h(n, wx, wz), wz))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	add_child(mi)
	_style(mi, Color(0.86, 0.62, 0.42), null, false)


func _h(n: FastNoiseLite, x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var dune := absf(n.get_noise_2d(x, z)) * 9.0 + n.get_noise_2d(x * 3.0, z * 3.0) * 0.6
	return dune * smoothstep(6.0, 40.0, d)


func _place(path: String, pos: Vector3, rot := 0.0, scale := 1.0) -> Node3D:
	var n: Node3D = (load(path) as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = rot
	n.scale = Vector3.ONE * scale
	add_child(n)
	_style_tree(n)
	return n


func _props() -> void:
	_place(RUINS + "Wall_ArchRound_Broken.fbx", Vector3(-1.0, -0.2, -16), 0.15, 1.6)
	_place(RUINS + "Wall_Broken.fbx", Vector3(-8.5, -0.3, -15), 0.4, 1.6)
	_place(RUINS + "Column_Round.fbx", Vector3(7, -0.2, -10), 0.0, 1.6)
	_place(RUINS + "Column_Round_Short.fbx", Vector3(-6, -0.2, -6), 0.0, 1.6)
	_place(RUINS + "Arch_Gothic.fbx", Vector3(18, -0.5, -40), -0.5, 3.0)
	_place(RUINS + "Statue_Stag.fbx", Vector3(-20, 1.0, -48), 0.6, 3.5)
	_place(RUINS + "Skull.fbx", Vector3(-1.6, 0.0, -2.6), 0.8, 1.6)
	_place(RUINS + "Pot2_Broken.fbx", Vector3(2.8, 0.0, -3.0), 0.0, 1.4)
	_place(NATURE + "DeadTree_2.gltf", Vector3(11, 0, -20), 0.3, 1.2)
	_place(NATURE + "DeadTree_4.gltf", Vector3(-15, 0, -24), 1.0, 1.4)
	_place(NATURE + "Rock_Medium_1.gltf", Vector3(5, -0.2, -5.5), 0.0, 0.45)
	_place(NATURE + "Rock_Medium_3.gltf", Vector3(-9, -0.2, -12), 2.0, 0.7)


func _witch() -> void:
	var root := Node3D.new()
	root.position = Vector3(0, 0.35, 0)
	root.rotation.y = 0.75
	add_child(root)
	var w: Node3D = (load("res://models/witch/witch_rigged.fbx") as PackedScene).instantiate()
	root.add_child(w)
	var sk: Skeleton3D = w.find_children("*", "Skeleton3D", true, false)[0]
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	sk.add_child(att)
	var hair: Node3D = (load("res://models/witch/witch_hair.glb") as PackedScene).instantiate()
	att.add_child(hair)
	hair.transform = sk.get_bone_global_rest(sk.find_bone("Head")).affine_inverse()
	var staff: Node3D = (load("res://models/witch/staff.glb") as PackedScene).instantiate()
	var holder := Node3D.new()
	holder.position = Vector3(0, 1.0, -0.3)
	holder.rotation.z = -deg_to_rad(40)
	root.add_child(holder)
	staff.rotation.y = PI / 2
	holder.add_child(staff)
	var src: Node = (load("res://animations/Universal Animation Library 2/Unreal-Godot/UAL2_Standard.glb") as PackedScene).instantiate()
	var sap: AnimationPlayer = src.find_children("*", "AnimationPlayer", true, false)[0]
	var lib := AnimationLibrary.new()
	lib.add_animation("idle", sap.get_animation("Idle_FoldArms"))
	src.free()
	var ap := AnimationPlayer.new()
	w.add_child(ap)
	ap.root_node = ap.get_path_to(w)
	ap.add_animation_library("", lib)
	ap.play("idle")
	ap.seek(0.8, true)
	pastel = 0.0
	_style_tree(root)
	pastel = 0.15


func _enemy(path: String, pos: Vector3, height: float, rot: float) -> void:
	var n: Node3D = (load(path) as PackedScene).instantiate()
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = rot
	add_child(holder)
	holder.add_child(n)
	n.rotation.y = -PI / 2
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = m.get_aabb()
		box = a if first else box.merge(a)
		first = false
	var s := height / maxf(box.size.y, 0.01)
	n.scale = Vector3.ONE * s
	n.position.y = -box.position.y * s
	_style_tree(holder)


func _style_tree(root: Node) -> void:
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = m
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i) as BaseMaterial3D
			var tex: Texture2D = src.albedo_texture if src else null
			var col: Color = src.albedo_color if src else Color.WHITE
			if mode == "sable":
				mi.set_surface_override_material(i, _toon(col, tex))


func _style(mi: MeshInstance3D, col: Color, tex: Texture2D, _unused: bool) -> void:
	if mode == "sable":
		mi.material_override = _toon(col, tex)
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.55, 0.55, 0.65)
		mi.material_override = m


func _toon(col: Color, tex: Texture2D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", col)
	m.set_shader_parameter("use_tex", tex != null)
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	if retro:
		m.set_shader_parameter("snap", 160.0)
	var o := ShaderMaterial.new()
	o.shader = OUTLINE
	o.set_shader_parameter("line_color", ink)
	o.set_shader_parameter("width", 1.0 if retro else 1.6)
	if OS.get_environment("NOOUT") != "1":
		m.next_pass = o
	m.set_shader_parameter("pastel", pastel)
	return m


func _process(_d: float) -> void:
	frames += 1
	if frames == 20:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT"))
		get_tree().quit()
