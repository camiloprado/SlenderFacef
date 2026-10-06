extends Node3D

const EYE_HEIGHT := 1.82
const BLUE := Color(0.07, 0.19, 0.64)
const PAGE := Color(0.86, 0.87, 0.89)
const GLOVE := Color(0.9, 0.9, 0.9)
const BLACK := Color(0.035, 0.035, 0.04)
const BOOKS := [
	{"size": Vector3(0.98, 0.44, 0.66), "y": 0.82, "x": 0.0, "yaw": 0.0},
	{"size": Vector3(0.94, 0.44, 0.64), "y": 1.26, "x": 0.025, "yaw": 0.05},
	{"size": Vector3(0.96, 0.52, 0.64), "y": 1.74, "x": -0.01, "yaw": -0.035},
]

var eye_material: ShaderMaterial
var _phase := 0.0
var _meshes := {}


func _ready() -> void:
	if get_node_or_null("Body") == null:
		_build()
	pose_standing()


func pose_standing() -> void:
	var body := get_node("Body") as Node3D
	body.position = Vector3.ZERO
	body.rotation = Vector3.ZERO
	for i in BOOKS.size():
		var book := get_node("Body/Book%d" % i) as Node3D
		book.position = Vector3(BOOKS[i]["x"], BOOKS[i]["y"], 0.0)
		book.rotation = Vector3(0.0, BOOKS[i]["yaw"], 0.0)
	for side in ["L", "R"]:
		var sign := -1.0 if side == "L" else 1.0
		var arm := get_node("Body/Arm" + side) as Node3D
		arm.rotation = Vector3(0.0, 0.0, sign * 0.38)
		arm.scale = Vector3.ONE
		var leg := get_node("Leg" + side) as Node3D
		leg.rotation = Vector3.ZERO
		leg.scale = Vector3.ONE
		(get_node("Leg" + side + "/Foot") as Node3D).rotation = Vector3(0.0, sign * 0.12, 0.0)


func pose_hanging() -> void:
	pose_standing()
	var tilt := [0.05, -0.04, 0.09]
	for i in BOOKS.size():
		var book := get_node("Body/Book%d" % i) as Node3D
		book.rotation.x = tilt[i]
		book.rotation.z = 0.03 * (i - 1)
	for side in ["L", "R"]:
		var sign := -1.0 if side == "L" else 1.0
		var arm := get_node("Body/Arm" + side) as Node3D
		arm.rotation = Vector3(0.08, 0.0, sign * 0.04)
		arm.scale = Vector3(0.75, 1.0, 0.75)
		var leg := get_node("Leg" + side) as Node3D
		leg.rotation = Vector3(0.08, 0.0, -sign * 0.04)
		leg.scale = Vector3(0.55, 0.95, 0.55)
		(get_node("Leg" + side + "/Foot") as Node3D).rotation = Vector3(0.75, sign * 0.2, 0.0)


func walk(delta: float, speed: float) -> void:
	if speed < 0.2:
		return
	_phase += delta * speed * 2.1
	var swing := sin(_phase)
	(get_node("LegL") as Node3D).rotation.x = swing * 0.42
	(get_node("LegR") as Node3D).rotation.x = -swing * 0.42
	(get_node("Body/ArmL") as Node3D).rotation.x = -swing * 0.3
	(get_node("Body/ArmR") as Node3D).rotation.x = swing * 0.3
	var body := get_node("Body") as Node3D
	body.position.y = absf(cos(_phase)) * 0.035
	body.rotation.z = swing * 0.035
	for i in BOOKS.size():
		(get_node("Body/Book%d" % i) as Node3D).rotation.z = swing * 0.018 * (i - 1)


func _build() -> void:
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)

	var blue := _plush(BLUE, 0.55, 0.22, 0.006, 0.3, 0.012)
	var page := _plush(PAGE, 0.3, 0.15, 0.0, 0.35, 0.004)
	var line := _plush(Color(0.55, 0.56, 0.6), 0.1, 0.05, 0.0, 0.2, 0.0)
	var glove := _plush(GLOVE, 0.5, 0.25, 0.004, 0.4, 0.008)
	var black := _plush(BLACK, 0.4, 0.1, 0.0, 0.0, 0.006)
	black.set_shader_parameter("brightness", 1.0)

	for i in BOOKS.size():
		var size: Vector3 = BOOKS[i]["size"]
		var book := Node3D.new()
		book.name = "Book%d" % i
		body.add_child(book)
		_rounded(book, size, Vector3.ZERO, blue, 0.2)
		var pages := Vector3(size.x + 0.05, size.y * 0.7, size.z - 0.05)
		_rounded(book, pages, Vector3(0.0, 0.0, -0.05), page, 0.1)
		for k in 3:
			var ly := (k - 1) * pages.y * 0.27
			for side in [-1.0, 1.0]:
				_box(book, Vector3(0.004, 0.006, pages.z * 0.86), Vector3(side * (pages.x * 0.5 + 0.001), ly, -0.05), line)
			_box(book, Vector3(pages.x * 0.86, 0.006, 0.004), Vector3(0.0, ly, -0.05 - pages.z * 0.5 - 0.001), line)
	_build_face(get_node("Body/Book2") as Node3D, BOOKS[2]["size"])

	for side in ["L", "R"]:
		var sign := -1.0 if side == "L" else 1.0
		var arm := Node3D.new()
		arm.name = "Arm" + side
		arm.position = Vector3(sign * 0.47, 1.3, 0.04)
		body.add_child(arm)
		_capsule(arm, 0.07, 0.42, Vector3(0.0, -0.16, 0.0), black)
		_blob(arm, Vector3(0.095, 0.06, 0.095), Vector3(0.0, -0.37, 0.0), glove)
		var hand := Node3D.new()
		hand.position = Vector3(0.0, -0.47, 0.02)
		arm.add_child(hand)
		_blob(hand, Vector3(0.11, 0.1, 0.055), Vector3.ZERO, glove)
		for f in 3:
			var finger := _capsule(hand, 0.038, 0.17, Vector3((f - 1) * 0.06, -0.1, 0.0), glove)
			finger.rotation.z = (f - 1) * 0.18
		var thumb := _capsule(hand, 0.036, 0.13, Vector3(-sign * 0.1, -0.01, 0.03), glove)
		thumb.rotation.z = -sign * 0.9

		var leg := Node3D.new()
		leg.name = "Leg" + side
		leg.position = Vector3(sign * 0.18, 0.62, 0.0)
		add_child(leg)
		_capsule(leg, 0.085, 0.62, Vector3(0.0, -0.26, 0.0), black)
		var foot := Node3D.new()
		foot.name = "Foot"
		foot.position = Vector3(0.0, -0.5, 0.0)
		leg.add_child(foot)
		_blob(foot, Vector3(0.13, 0.095, 0.22), Vector3(0.0, 0.0, 0.06), blue)
		_blob(foot, Vector3(0.115, 0.07, 0.085), Vector3(0.0, -0.01, 0.22), glove)
		_blob(foot, Vector3(0.14, 0.035, 0.235), Vector3(0.0, -0.065, 0.065), glove)
		_box(foot, Vector3(0.11, 0.012, 0.03), Vector3(0.0, 0.08, 0.08), glove)
		_box(foot, Vector3(0.11, 0.012, 0.03), Vector3(0.0, 0.065, 0.13), glove)


func _build_face(book: Node3D, size: Vector3) -> void:
	var front := size.z * 0.5
	var white := _plush(Color(0.93, 0.93, 0.92), 0.0, 0.05, 0.0, 0.2, 0.0)
	white.set_shader_parameter("gloss", 0.75)
	var pupil := _plush(Color(0.02, 0.02, 0.025), 0.0, 0.0, 0.0, 0.0, 0.0)
	pupil.set_shader_parameter("gloss", 0.95)
	pupil.set_shader_parameter("brightness", 1.0)
	pupil.set_shader_parameter("glow", 0.15)
	pupil.set_shader_parameter("glow_color", Color(0.02, 0.015, 0.02))
	eye_material = pupil
	var brow := _plush(BLACK, 0.5, 0.1, 0.0, 0.0, 0.0)
	brow.set_shader_parameter("brightness", 1.0)
	var mouth_mat := _plush(Color(0.16, 0.02, 0.03), 0.2, 0.1, 0.0, 0.0, 0.0)
	mouth_mat.set_shader_parameter("brightness", 1.0)
	var tongue := _plush(Color(0.75, 0.08, 0.1), 0.3, 0.3, 0.0, 0.15, 0.0)
	var teeth := _plush(Color(0.92, 0.92, 0.9), 0.1, 0.1, 0.0, 0.2, 0.0)

	for side in [-1.0, 1.0]:
		var ex: float = side * 0.12
		var eye := _blob(book, Vector3(0.12, 0.155, 0.05), Vector3(ex, 0.08, front + 0.005), white)
		eye.name = "Eye"
		_blob(book, Vector3(0.048, 0.07, 0.025), Vector3(ex - side * 0.035, 0.06, front + 0.046), pupil)
		var arch := _capsule(book, 0.03, 0.2, Vector3(ex + side * 0.02, 0.25, front + 0.01), brow)
		arch.rotation = Vector3(0.0, 0.0, PI * 0.5 - side * 0.25)

	var mouth := Node3D.new()
	mouth.name = "Mouth"
	mouth.position = Vector3(0.0, -0.13, front + 0.004)
	book.add_child(mouth)
	_blob(mouth, Vector3(0.25, 0.1, 0.035), Vector3(0.0, -0.03, 0.0), mouth_mat)
	_blob(book, Vector3(0.27, 0.05, 0.05), mouth.position + Vector3(0.0, 0.035, 0.008), _plush(BLUE, 0.55, 0.22, 0.0, 0.3, 0.0))
	_blob(mouth, Vector3(0.15, 0.05, 0.03), Vector3(0.03, -0.08, 0.012), tongue)
	_box(mouth, Vector3(0.3, 0.035, 0.02), Vector3(0.0, -0.025, 0.03), teeth)


func _plush(color: Color, fuzz: float, softness: float, puff: float, grime: float, lumps: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/plush.gdshader")
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("fuzz", fuzz)
	mat.set_shader_parameter("softness", softness)
	mat.set_shader_parameter("gloss", 0.04)
	mat.set_shader_parameter("puff", puff)
	mat.set_shader_parameter("grime", grime)
	mat.set_shader_parameter("lumps", lumps)
	return mat


func _rounded(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, roundness: float) -> MeshInstance3D:
	var key := "%s|%s" % [size, roundness]
	if not _meshes.has(key):
		_meshes[key] = _superquadric(size * 0.5, roundness)
	var mesh := MeshInstance3D.new()
	mesh.mesh = _meshes[key]
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _superquadric(half: Vector3, e: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 32
	var segs := 48
	for i in rings + 1:
		var v := -PI * 0.5 + PI * i / rings
		for j in segs + 1:
			var u := -PI + TAU * j / segs
			var cv := cos(v)
			var sv := sin(v)
			var cu := cos(u)
			var su := sin(u)
			var n := Vector3(
				_spow(cv, 2.0 - e) * _spow(cu, 2.0 - e) / half.x,
				_spow(sv, 2.0 - e) / half.y,
				_spow(cv, 2.0 - e) * _spow(su, 2.0 - e) / half.z)
			st.set_normal(n.normalized() if n.length() > 0.0001 else Vector3(0.0, signf(sv), 0.0))
			st.add_vertex(Vector3(
				half.x * _spow(cv, e) * _spow(cu, e),
				half.y * _spow(sv, e),
				half.z * _spow(cv, e) * _spow(su, e)))
	for i in rings:
		for j in segs:
			var a := i * (segs + 1) + j
			var b := a + segs + 1
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(b + 1)
			st.add_index(b)
	return st.commit()


func _spow(x: float, e: float) -> float:
	return signf(x) * pow(absf(x), e)


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	mesh.mesh = capsule
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _blob(parent: Node3D, radii: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	mesh.mesh = sphere
	mesh.scale = radii
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
