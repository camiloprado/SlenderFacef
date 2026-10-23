extends Node3D

signal pulled

var occupied := false
var _door: Node3D
var _busy := false
var _creak: AudioStreamPlayer3D
var _glow: StandardMaterial3D
var _glow_t := 0.0


func _ready() -> void:
	add_to_group("lockers")
	_build()


func _process(delta: float) -> void:
	if _glow == null:
		return
	_glow_t += delta
	var pulse := 0.5 + 0.5 * sin(_glow_t * 1.7)
	var energy := lerpf(0.14, 0.32, pulse)
	if occupied:
		energy = 0.04
	_glow.emission_energy_multiplier = energy


func can_enter(player_pos: Vector3) -> bool:
	if occupied or _busy:
		return false
	return to_global(Vector3(0.0, 0.1, 0.75)).distance_to(player_pos) < 1.45


func enter(player: CharacterBody3D) -> void:
	if occupied or _busy:
		return
	occupied = true
	_busy = true
	player.noise = 16.0
	_swing(true)
	var slam := create_tween()
	slam.tween_interval(0.42)
	slam.tween_callback(func() -> void:
		_place(player, Vector3(0.0, 0.1, -0.08), rotation.y + PI)
		player.hidden = true
		_swing(false))
	slam.tween_interval(0.4)
	slam.tween_callback(func() -> void: _busy = false)


func leave(player: CharacterBody3D) -> void:
	if not occupied or _busy:
		return
	_busy = true
	_swing(true)
	var slam := create_tween()
	slam.tween_interval(0.32)
	slam.tween_callback(func() -> void:
		_place(player, Vector3(0.0, 0.1, 1.85), rotation.y + PI)
		player.hidden = false
		player.hide_grace = 0.9
		player.noise = 14.0
		occupied = false
		_swing(false))
	slam.tween_interval(0.4)
	slam.tween_callback(func() -> void: _busy = false)


func _place(player: CharacterBody3D, local_pos: Vector3, yaw: float) -> void:
	player.global_position = to_global(local_pos)
	player.velocity = Vector3.ZERO
	player._yaw = yaw
	player._pitch = 0.0
	player.rotation.y = yaw
	player.camera.rotation.x = 0.0


func drag_out(player: CharacterBody3D, mascot: CharacterBody3D) -> void:
	if not occupied or _busy:
		return
	_busy = true
	_swing(true, 0.18)
	mascot.velocity = Vector3.ZERO
	mascot.held = true
	mascot.global_position = to_global(Vector3(0.0, 0.1, 1.75))
	_face_locker(mascot)
	var costume := mascot.get_node_or_null("Mascot")
	if costume:
		costume.set_reach(0.1)
	var reach := create_tween()
	reach.tween_method(func(weight: float) -> void:
		if costume:
			costume.set_reach(weight)
	, 0.1, 1.0, 0.32)
	var from: Vector3 = player.global_position
	var out := to_global(Vector3(0.05, 0.1, 1.28))
	var yaw_from := player.rotation.y
	var yaw_to := rotation.y
	var turn := create_tween()
	turn.tween_method(func(u: float) -> void:
		player.rotation.y = yaw_from + (yaw_to - yaw_from) * u
		player._yaw = player.rotation.y
		player._pitch = lerpf(0.1, -0.22, u)
		player.camera.rotation.x = player._pitch
	, 0.0, 1.0, 0.22)
	var yank := create_tween()
	yank.tween_interval(0.2)
	yank.tween_method(func(u: float) -> void:
		var wobble := global_transform.basis.x * sin(u * TAU * 3.0) * 0.05 * (1.0 - u)
		player.global_position = from.lerp(out, u) + wobble
		player.velocity = Vector3.ZERO
		player.rotation.y = yaw_to
		player._yaw = yaw_to
		var pitch := lerpf(-0.22, -0.5, u)
		player._pitch = pitch
		player.camera.rotation.x = pitch
		player.camera.h_offset = sin(u * TAU * 4.0) * 0.05 * (1.0 - u)
		_face_locker(mascot)
	, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	yank.tween_callback(func() -> void:
		player.camera.h_offset = 0.0
		_place(player, Vector3(0.05, 0.1, 1.28), rotation.y)
		player.camera.rotation.x = -0.42
		player._pitch = -0.42
		player.hidden = false
		occupied = false
		_busy = false
		if costume:
			costume.set_reach(1.0)
		pulled.emit())


func _face_locker(mascot: CharacterBody3D) -> void:
	var look := to_global(Vector3(0.0, 1.15, 0.15))
	if mascot.global_position.distance_squared_to(look) < 0.04:
		return
	mascot.look_at(look, Vector3.UP)


func _swing(open: bool, duration := 0.38) -> void:
	if _door == null:
		return
	var tween := create_tween()
	tween.tween_property(_door, "rotation:y", -1.35 if open else 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _creak and _creak.stream:
		_creak.pitch_scale = randf_range(0.9, 1.08)
		_creak.play()


func _build() -> void:
	var steel := _mat(Color(0.16, 0.2, 0.24), 0.45)
	var dark := _mat(Color(0.05, 0.06, 0.07), 0.8)
	var inside := _mat(Color(0.07, 0.08, 0.09), 0.9)
	var shell := StaticBody3D.new()
	add_child(shell)
	_panel(shell, Vector3(0.96, 1.9, 0.06), Vector3(0.0, 1.0, -0.42), steel)
	_panel(shell, Vector3(0.06, 1.9, 0.84), Vector3(-0.48, 1.0, 0.0), steel)
	_panel(shell, Vector3(0.06, 1.9, 0.84), Vector3(0.48, 1.0, 0.0), steel)
	_panel(shell, Vector3(1.02, 0.08, 0.9), Vector3(0.0, 1.94, 0.0), steel)
	_panel(shell, Vector3(0.9, 0.06, 0.78), Vector3(0.0, 0.08, -0.02), dark)
	_visual(Vector3(0.8, 0.02, 0.5), Vector3(0.0, 1.15, -0.22), inside)
	_visual(Vector3(0.8, 1.7, 0.02), Vector3(0.0, 1.0, -0.36), inside)

	_door = AnimatableBody3D.new()
	_door.name = "Door"
	_door.position = Vector3(-0.44, 0.0, 0.42)
	add_child(_door)
	_panel(_door, Vector3(0.38, 1.78, 0.04), Vector3(0.21, 1.0, 0.0), steel)
	_panel(_door, Vector3(0.42, 1.78, 0.04), Vector3(0.69, 1.0, 0.0), steel)
	_visual_on(_door, Vector3(0.03, 0.16, 0.04), Vector3(0.8, 1.05, 0.04), _mat(Color(0.55, 0.5, 0.4), 0.35))
	_add_highlight()

	_creak = AudioStreamPlayer3D.new()
	_creak.stream = load("res://assets/audio/rangido/creak1.ogg")
	_creak.unit_size = 4.0
	_creak.max_distance = 14.0
	_creak.volume_db = -4.0
	add_child(_creak)


func _panel(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	_visual_on(parent, size, pos, mat)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	shape.position = pos
	parent.add_child(shape)


func _visual(size: Vector3, pos: Vector3, mat: Material) -> void:
	_visual_on(self, size, pos, mat)


func _visual_on(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)


func _add_highlight() -> void:
	_glow = StandardMaterial3D.new()
	_glow.albedo_color = Color(0.08, 0.12, 0.16)
	_glow.emission_enabled = true
	_glow.emission = Color(0.45, 0.68, 0.82)
	_glow.emission_energy_multiplier = 0.22
	_glow.roughness = 0.35
	_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var frame := Node3D.new()
	frame.name = "Highlight"
	add_child(frame)
	_visual_on(frame, Vector3(0.04, 2.02, 0.02), Vector3(-0.52, 1.02, 0.5), _glow)
	_visual_on(frame, Vector3(0.04, 2.02, 0.02), Vector3(0.52, 1.02, 0.5), _glow)
	_visual_on(frame, Vector3(1.08, 0.04, 0.02), Vector3(0.0, 2.02, 0.5), _glow)
	_visual_on(frame, Vector3(1.08, 0.04, 0.02), Vector3(0.0, 0.05, 0.5), _glow)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.35
	return mat
