extends Node3D

var duct_index := 0
var _grate: Node3D
var _clang: AudioStreamPlayer3D


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
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.45, 0.48, 0.5)
	metal.metallic = 0.75
	metal.roughness = 0.35
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.13, 0.14)
	dark.metallic = 0.4
	dark.roughness = 0.55
	var rim := MeshInstance3D.new()
	var rim_box := BoxMesh.new()
	rim_box.size = Vector3(0.92, 0.06, 0.92)
	rim.mesh = rim_box
	rim.position = Vector3(0.0, -0.22, 0.0)
	rim.material_override = metal
	add_child(rim)
	_grate = Node3D.new()
	_grate.position = Vector3(0.0, -0.26, 0.42)
	add_child(_grate)
	var panel := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(0.78, 0.04, 0.78)
	panel.mesh = panel_box
	panel.position = Vector3(0.0, 0.0, -0.39)
	panel.material_override = dark
	_grate.add_child(panel)
	for i in 4:
		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(0.7, 0.025, 0.04)
		bar.mesh = bar_box
		bar.position = Vector3(0.0, -0.03, -0.16 - float(i) * 0.14)
		bar.material_override = metal
		_grate.add_child(bar)
	_clang = AudioStreamPlayer3D.new()
	_clang.stream = load("res://assets/audio/portas/doorOpen_1.ogg")
	_clang.unit_size = 6.0
	_clang.max_distance = 22.0
	_clang.volume_db = -2.0
	add_child(_clang)
