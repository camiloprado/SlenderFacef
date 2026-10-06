extends Node3D

const PLUSH := preload("res://shaders/plush.gdshader")

const HAIR: Array[Color] = [
	Color(0.06, 0.04, 0.03), Color(0.2, 0.12, 0.06), Color(0.42, 0.26, 0.12),
	Color(0.7, 0.55, 0.3), Color(0.12, 0.08, 0.06),
]

var _rng := RandomNumberGenerator.new()


func setup(skin: Color, stole: Color, seed_value: int, rector := false) -> void:
	_rng.seed = seed_value
	var gown_color := Color(0.42, 0.06, 0.08) if rector else Color(0.07, 0.075, 0.1)
	var gown := _cloth(gown_color, 0.78)
	var lining := _cloth(stole.darkened(0.15), 0.6)
	var stole_mat := _cloth(stole, 0.55)
	var gold := _shiny(Color(0.85, 0.66, 0.22), 0.35, 0.7)
	var skin_mat := _skin(skin)
	var hair_color := HAIR[_rng.randi() % HAIR.size()]
	var hair := _cloth(hair_color, 0.65)

	var trousers := _cloth(Color(0.05, 0.05, 0.06), 0.8)
	for side in [-1.0, 1.0]:
		_capsule(self, 0.045, 0.26, Vector3(side * 0.07, 0.14, 0.0), trousers)
	_add_shoes()

	var skirt := MeshInstance3D.new()
	skirt.name = "Saia"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.16
	cone.bottom_radius = 0.27
	cone.height = 0.78
	cone.radial_segments = 40
	skirt.mesh = cone
	skirt.position = Vector3(0.0, 0.57, 0.0)
	skirt.scale = Vector3(1.0, 1.0, 0.82)
	skirt.material_override = gown
	add_child(skirt)
	for i in 7:
		var a := -0.9 + float(i) * 0.3
		var outward := Vector3(sin(a), 0.0, cos(a))
		var pleat := _capsule(skirt, 0.012, 0.7, outward * 0.205 + Vector3(0.0, -0.02, 0.0), gown)
		var up := (Vector3.UP * cone.height - outward * (cone.bottom_radius - cone.top_radius)).normalized()
		var side := up.cross(outward).normalized()
		pleat.basis = Basis(side, up, side.cross(up))
	_blob(self, Vector3(0.21, 0.15, 0.15), Vector3(0.0, 0.94, 0.0), gown)
	_blob(self, Vector3(0.04, 0.28, 0.02), Vector3(0.0, 0.72, 0.148), lining)

	for side in [-1.0, 1.0]:
		var band := _box(self, Vector3(0.06, 0.5, 0.01), Vector3(side * 0.065, 0.8, 0.142), stole_mat)
		band.rotation = Vector3(-0.06, 0.0, -side * 0.18)
		_box(band, Vector3(0.008, 0.5, 0.012), Vector3(side * 0.03, 0.0, 0.0), gold)
		_box(self, Vector3(0.07, 0.025, 0.012), Vector3(side * 0.11, 0.56, 0.158), gold)
	_blob(self, Vector3(0.11, 0.03, 0.1), Vector3(0.0, 1.02, 0.02), _cloth(Color(0.93, 0.92, 0.88), 0.6))
	if rector:
		var medal := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.035
		disc.bottom_radius = 0.035
		disc.height = 0.01
		medal.mesh = disc
		medal.rotation.x = PI / 2.0
		medal.position = Vector3(0.0, 0.84, 0.205)
		medal.material_override = gold
		add_child(medal)
		var chain := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.1
		ring.outer_radius = 0.115
		chain.mesh = ring
		chain.position = Vector3(0.0, 0.98, 0.04)
		chain.rotation.x = 0.5
		chain.material_override = gold
		add_child(chain)

	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0.0 else "ArmR"
		arm.position = Vector3(side * 0.2, 0.97, 0.0)
		add_child(arm)
		_blob(arm, Vector3(0.065, 0.065, 0.065), Vector3.ZERO, gown)
		var sleeve := MeshInstance3D.new()
		var bell := CylinderMesh.new()
		bell.top_radius = 0.05
		bell.bottom_radius = 0.085
		bell.height = 0.34
		bell.radial_segments = 32
		sleeve.mesh = bell
		sleeve.position = Vector3(side * 0.015, -0.18, 0.0)
		sleeve.rotation.z = side * 0.06
		sleeve.material_override = gown
		arm.add_child(sleeve)
		var cuff := MeshInstance3D.new()
		var cuff_ring := TorusMesh.new()
		cuff_ring.inner_radius = 0.07
		cuff_ring.outer_radius = 0.088
		cuff.mesh = cuff_ring
		cuff.position = Vector3(side * 0.025, -0.35, 0.0)
		cuff.material_override = stole_mat
		arm.add_child(cuff)
		var hand := Node3D.new()
		hand.name = "Hand"
		hand.position = Vector3(side * 0.03, -0.4, 0.02)
		arm.add_child(hand)
		_blob(hand, Vector3(0.035, 0.045, 0.028), Vector3.ZERO, skin_mat)
		var thumb := _capsule(hand, 0.012, 0.045, Vector3(-side * 0.025, 0.005, 0.02), skin_mat)
		thumb.rotation.z = side * 0.6

	_capsule(self, 0.042, 0.1, Vector3(0.0, 1.06, 0.0), skin_mat)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 1.18, 0.02)
	add_child(head)
	_blob(head, Vector3(0.105, 0.12, 0.105), Vector3.ZERO, skin_mat)
	_blob(head, Vector3(0.08, 0.05, 0.07), Vector3(0.0, -0.06, 0.03), skin_mat)
	for side in [-1.0, 1.0]:
		_blob(head, Vector3(0.018, 0.028, 0.014), Vector3(side * 0.103, -0.005, 0.0), skin_mat)
	_blob(head, Vector3(0.112, 0.07, 0.112), Vector3(0.0, 0.055, -0.012), hair)
	_blob(head, Vector3(0.1, 0.1, 0.06), Vector3(0.0, 0.0, -0.06), hair)
	if _rng.randf() < 0.45:
		_blob(head, Vector3(0.1, 0.13, 0.05), Vector3(0.0, -0.08, -0.07), hair)

	var white := _shiny(Color(0.95, 0.95, 0.93), 0.3, 0.0)
	var iris := _shiny(Color(0.18, 0.11, 0.06).lerp(Color(0.15, 0.3, 0.4), _rng.randf() * 0.5), 0.15, 0.0)
	var brow := _cloth(hair_color.darkened(0.2), 0.7)
	for side in [-1.0, 1.0]:
		_blob(head, Vector3(0.022, 0.026, 0.01), Vector3(side * 0.038, 0.012, 0.096), white)
		_blob(head, Vector3(0.012, 0.015, 0.006), Vector3(side * 0.037, 0.01, 0.105), iris)
		var arch := _box(head, Vector3(0.036, 0.008, 0.01), Vector3(side * 0.04, 0.045, 0.1), brow)
		arch.rotation.z = -side * 0.12
		_blob(head, Vector3(0.018, 0.01, 0.006), Vector3(side * 0.058, -0.03, 0.093), _cloth(skin.lerp(Color(0.9, 0.4, 0.4), 0.35), 0.8))
	_blob(head, Vector3(0.013, 0.018, 0.014), Vector3(0.0, -0.012, 0.11), skin_mat)
	var smile := MeshInstance3D.new()
	var arc := TorusMesh.new()
	arc.inner_radius = 0.022
	arc.outer_radius = 0.028
	smile.mesh = arc
	smile.position = Vector3(0.0, -0.035, 0.1)
	smile.rotation = Vector3(PI / 2.0 - 0.2, 0.0, 0.0)
	smile.scale = Vector3(1.0, 1.0, 0.5)
	smile.material_override = _cloth(Color(0.45, 0.15, 0.15), 0.7)
	head.add_child(smile)

	var cap_mat := _cloth(Color(0.04, 0.045, 0.06), 0.55)
	var cap := Node3D.new()
	cap.name = "Capelo"
	cap.position = Vector3(0.0, 0.1, -0.01)
	cap.rotation = Vector3(-0.08, _rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.06, 0.06))
	head.add_child(cap)
	var skull := MeshInstance3D.new()
	var dome := CylinderMesh.new()
	dome.top_radius = 0.105
	dome.bottom_radius = 0.118
	dome.height = 0.07
	skull.mesh = dome
	skull.material_override = cap_mat
	cap.add_child(skull)
	_box(cap, Vector3(0.34, 0.018, 0.34), Vector3(0.0, 0.044, 0.0), cap_mat)
	_blob(cap, Vector3(0.016, 0.01, 0.016), Vector3(0.0, 0.058, 0.0), gold)
	var cord := _box(cap, Vector3(0.17, 0.006, 0.006), Vector3(0.085, 0.056, 0.03), gold)
	cord.rotation.y = -0.35
	var tassel := Node3D.new()
	tassel.name = "Tassel"
	tassel.position = Vector3(0.165, 0.05, 0.085)
	cap.add_child(tassel)
	_capsule(tassel, 0.01, 0.06, Vector3(0.0, -0.03, 0.0), gold)
	var fringe := MeshInstance3D.new()
	var tuft := CylinderMesh.new()
	tuft.top_radius = 0.012
	tuft.bottom_radius = 0.022
	tuft.height = 0.09
	fringe.mesh = tuft
	fringe.position = Vector3(0.0, -0.1, 0.0)
	fringe.material_override = gold
	tassel.add_child(fringe)


func _add_shoes() -> void:
	var polish := StandardMaterial3D.new()
	polish.albedo_color = Color(0.05, 0.05, 0.06)
	polish.roughness = 0.14
	polish.metallic = 0.7
	for side in [-1.0, 1.0]:
		_blob(self, Vector3(0.05, 0.032, 0.1), Vector3(side * 0.07, 0.032, 0.035), polish)
		_box(self, Vector3(0.09, 0.012, 0.19), Vector3(side * 0.07, 0.006, 0.03), _cloth(Color(0.02, 0.02, 0.02), 0.9))


func _cloth(color: Color, roughness: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PLUSH
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("brightness", 1.0)
	mat.set_shader_parameter("fuzz", 0.45)
	mat.set_shader_parameter("softness", 0.15)
	mat.set_shader_parameter("gloss", clampf(1.0 - roughness, 0.0, 1.0) * 0.6)
	mat.set_shader_parameter("puff", 0.0)
	return mat


func _shiny(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _skin(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.3
	mat.rim_enabled = true
	mat.rim = 0.15
	return mat


func _blob(parent: Node3D, radii: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 40
	sphere.rings = 20
	mesh.mesh = sphere
	mesh.scale = radii
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = maxf(height, radius * 2.0)
	mesh.mesh = capsule
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh
