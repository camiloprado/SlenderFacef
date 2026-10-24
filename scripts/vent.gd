extends Node3D

var duct_index := 0
var _grate: Node3D
var _clang: AudioStreamPlayer3D
var _parts := Surfaces.Batch.new()


func _ready() -> void:
	add_to_group("vents")
	_build()


func stand_global() -> Vector3:
	var spot := global_position
	spot.y = 0.1
	return spot


func inside_global() -> Vector3:
	return global_position


func open_grate() -> void:
	_swing(true)


func close_grate() -> void:
	_swing(false)


func _swing(open: bool) -> void:
	if _grate == null:
		return
	var tween := create_tween()
	tween.tween_property(_grate, "rotation:x", -1.35 if open else 0.0, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if open and _clang and _clang.stream:
		_clang.pitch_scale = randf_range(0.85, 1.05)
		_clang.play()


func _build() -> void:
	_parts.cell = Vector2.ZERO
	var metal := Surfaces.pbr("Metal009", Color(0.62, 0.64, 0.66), 2.0, 1.0, 1.0, 0.6, false)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.035, 0.04)
	dark.roughness = 0.9
	for side in [-1.0, 1.0]:
		_bar(self, Vector3(0.92, 0.06, 0.07), Vector3(0.0, -0.22, float(side) * 0.425), metal)
		_bar(self, Vector3(0.07, 0.06, 0.92), Vector3(float(side) * 0.425, -0.22, 0.0), metal)
	_bar(self, Vector3(0.78, 0.01, 0.78), Vector3(0.0, -0.19, 0.0), dark)
	_grate = Node3D.new()
	_grate.position = Vector3(0.0, -0.26, 0.42)
	add_child(_grate)
	for side in [-1.0, 1.0]:
		_bar(_grate, Vector3(0.78, 0.035, 0.03), Vector3(0.0, 0.0, -0.39 + float(side) * 0.375), metal)
		_bar(_grate, Vector3(0.03, 0.035, 0.78), Vector3(float(side) * 0.375, 0.0, -0.39), metal)
	for i in 9:
		_bar(_grate, Vector3(0.72, 0.006, 0.07), Vector3(0.0, 0.0, -0.06 - float(i) * 0.083), metal, 0.7)
	_bar(_grate, Vector3(0.02, 0.03, 0.72), Vector3(0.0, -0.005, -0.39), metal)
	for corner in [Vector3(-0.32, -0.02, -0.07), Vector3(0.32, -0.02, -0.07), Vector3(-0.32, -0.02, -0.71), Vector3(0.32, -0.02, -0.71)]:
		_bar(_grate, Vector3(0.018, 0.008, 0.018), corner, dark)
	_parts.flush()
	_clang = AudioStreamPlayer3D.new()
	_clang.stream = load("res://assets/audio/portas/doorOpen_1.ogg")
	_clang.unit_size = 6.0
	_clang.max_distance = 22.0
	_clang.volume_db = -2.0
	add_child(_clang)


func _bar(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, tilt := 0.0) -> void:
	_parts.box(parent, size, Transform3D(Basis(Vector3.RIGHT, tilt), pos), mat)
