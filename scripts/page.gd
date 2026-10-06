extends Node3D

signal picked_up(doc_id: String)

const DOC_SIZE := Vector2(0.26, 0.37)
const NOTE_SIZE := Vector2(0.24, 0.175)
const STAMPS: Array[String] = ["PENDENTE", "URGENTE", "EM ATRASO", "NÃO ENTREGUE"]

var doc_id := ""
var doc_title := "Documento"
var pinned := false
var taken := false
var _t := 0.0
var _paper: MeshInstance3D
var _paper_mat: ShaderMaterial
var _glow: OmniLight3D
var _pin: Node3D


func _ready() -> void:
	add_to_group("pages")
	_t = randf() * TAU
	_build()


func can_pick(player_pos: Vector3) -> bool:
	return not taken and global_position.distance_to(player_pos) < 2.4


func pick() -> void:
	if taken:
		return
	taken = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.active = false
	var slender := get_tree().get_first_node_in_group("slender")
	if slender:
		slender.held = true
		slender.velocity = Vector3.ZERO
	_play_rustle()
	var dust := get_node_or_null("Dust") as CPUParticles3D
	if dust:
		dust.emitting = false
	var cam := _player_camera()
	if cam == null or _paper == null:
		_finish_grab()
		return
	if _pin:
		_drop_pin()
	_paper.reparent(cam, true)
	_paper.name = "GrabbedNotebook"
	var target := Vector3(0.0, -0.01, -0.3) if pinned else Vector3(0.0, -0.015, -0.36)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_paper, "position", target, 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_paper, "rotation", Vector3(0.0, 0.0, -0.03), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_flutter, 0.035, 0.0, 0.72)
	if _glow:
		tween.tween_property(_glow, "light_energy", 0.0, 0.4)
	tween.chain().tween_interval(0.12)
	tween.chain().tween_callback(_finish_grab)


func _process(delta: float) -> void:
	_t += delta
	if taken or _paper == null:
		return
	if pinned:
		if _pin:
			_pin.rotation.z = 0.06 + sin(_t * 1.3) * 0.035 + sin(_t * 3.1) * 0.01
	else:
		_paper.position.y = 1.18 + sin(_t * 1.5) * 0.03
		_paper.rotation = Vector3(-0.3 + sin(_t * 1.1) * 0.05, sin(_t * 0.55) * 0.4, sin(_t * 0.9) * 0.04)
	if _glow:
		_glow.light_energy = (0.1 if pinned else 0.2) + sin(_t * 2.0) * (0.03 if pinned else 0.07)


func _set_flutter(value: float) -> void:
	if _paper_mat:
		_paper_mat.set_shader_parameter("flutter", value)


func _build() -> void:
	if pinned:
		_build_note()
	else:
		_build_document()


func _build_document() -> void:
	var wood := _mat(Color(0.34, 0.24, 0.14))
	var dark := _mat(Color(0.22, 0.16, 0.1))
	var desk := StaticBody3D.new()
	add_child(desk)
	_box(desk, Vector3(1.15, 0.06, 0.7), Vector3(0.0, 0.75, 0.0), wood)
	for x in [-0.52, 0.52]:
		for z in [-0.3, 0.3]:
			_box(desk, Vector3(0.06, 0.72, 0.06), Vector3(x, 0.36, z), dark)
	_box(desk, Vector3(0.6, 0.14, 0.62), Vector3(0.2, 0.65, 0.0), dark)
	_box(desk, Vector3(0.12, 0.025, 0.02), Vector3(0.2, 0.65, 0.32), _mat(Color(0.6, 0.55, 0.4)))
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(1.15, 0.78, 0.7)
	shape.shape = col
	shape.position.y = 0.39
	desk.add_child(shape)

	var folder := Node3D.new()
	folder.position = Vector3(-0.05, 0.786, 0.02)
	folder.rotation.y = 0.25
	add_child(folder)
	var manila := _mat(Color(0.78, 0.62, 0.36))
	_box(folder, Vector3(0.36, 0.01, 0.27), Vector3.ZERO, manila)
	_box(folder, Vector3(0.12, 0.01, 0.03), Vector3(-0.1, 0.0, -0.145), manila)
	_box(folder, Vector3(0.32, 0.004, 0.24), Vector3(0.015, 0.008, 0.008), _mat(Color(0.92, 0.9, 0.84)))
	_box(folder, Vector3(0.36, 0.01, 0.27), Vector3(0.01, 0.015, 0.0), manila).rotation.y = 0.05

	var view := _sheet_viewport(Vector2i(420, 600))
	_paint_document(view)
	_paper = _paper_mesh(DOC_SIZE, view, 0.006, 0.0)
	_paper.position = Vector3(0.0, 1.18, 0.0)
	_paper.rotation.x = -0.3
	add_child(_paper)
	_add_dust(Vector3(0.0, 1.15, 0.0))
	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.98, 0.88, 0.62)
	_glow.light_energy = 0.2
	_glow.omni_range = 2.6
	_glow.position = Vector3(0.0, 1.25, 0.25)
	_glow.shadow_enabled = false
	add_child(_glow)


func _build_note() -> void:
	_pin = Node3D.new()
	_pin.name = "Pin"
	_pin.position = Vector3(0.0, NOTE_SIZE.y * 0.42, 0.0)
	add_child(_pin)
	var view := _sheet_viewport(Vector2i(440, 320))
	_paint_note(view)
	_paper = _paper_mesh(NOTE_SIZE, view, 0.004, 0.03)
	_paper.position = Vector3(0.0, -NOTE_SIZE.y * 0.42, 0.0)
	_pin.add_child(_paper)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.011
	sphere.height = 0.022
	head.mesh = sphere
	head.position = Vector3(0.0, 0.0, 0.014)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.78, 0.07, 0.07)
	red.roughness = 0.25
	red.metallic = 0.1
	head.material_override = red
	head.name = "PinHead"
	_pin.add_child(head)
	var needle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0015
	cyl.bottom_radius = 0.0015
	cyl.height = 0.03
	needle.mesh = cyl
	needle.rotation.x = PI / 2.0
	needle.material_override = _mat(Color(0.7, 0.7, 0.72))
	head.add_child(needle)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.95, 0.88, 0.65)
	_glow.light_energy = 0.1
	_glow.omni_range = 1.1
	_glow.position = Vector3(0.0, 0.0, 0.35)
	_glow.shadow_enabled = false
	add_child(_glow)


func _drop_pin() -> void:
	var head := _pin.get_node_or_null("PinHead") as Node3D
	if head == null:
		return
	head.reparent(self, true)
	var fall := create_tween()
	fall.set_parallel(true)
	fall.tween_property(head, "position", head.position + Vector3(0.05, -global_position.y + 0.02, 0.18), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(head, "rotation", Vector3(2.4, 0.6, 1.2), 0.5)


func _paper_mesh(size: Vector2, view: SubViewport, flutter: float, tear: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = "Paper"
	var quad := QuadMesh.new()
	quad.size = size
	quad.subdivide_width = 10
	quad.subdivide_depth = 14
	mesh.mesh = quad
	_paper_mat = ShaderMaterial.new()
	_paper_mat.shader = load("res://shaders/paper.gdshader")
	_paper_mat.set_shader_parameter("page_tex", view.get_texture())
	_paper_mat.set_shader_parameter("flutter", flutter)
	_paper_mat.set_shader_parameter("tear", tear)
	_paper_mat.set_shader_parameter("seed", randf() * 50.0)
	_paper_mat.set_shader_parameter("glow", 0.22 if pinned else 0.3)
	mesh.material_override = _paper_mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


func _sheet_viewport(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size = size
	view.disable_3d = true
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	return view


func _paint_document(view: SubViewport) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(doc_id)
	var size := Vector2(view.size)
	_rect(view, Vector2.ZERO, size, Color(0.95, 0.925, 0.85))
	var aged := StyleBoxFlat.new()
	aged.bg_color = Color(0, 0, 0, 0)
	aged.border_color = Color(0.8, 0.72, 0.56, 0.45)
	aged.set_border_width_all(12)
	var frame := Panel.new()
	frame.size = size
	frame.add_theme_stylebox_override("panel", aged)
	view.add_child(frame)
	_ring(view, Vector2(rng.randf_range(250, 330), rng.randf_range(120, 300)), 46.0, Color(0.55, 0.38, 0.2, 0.22))

	var logo := TextureRect.new()
	logo.texture = load("res://assets/unifacef_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.position = Vector2(26, 26)
	logo.size = Vector2(176, 40)
	view.add_child(logo)
	var office := _text(view, "SECRETARIA ACADÊMICA", Vector2(214, 26), 180, 13, Color(0.3, 0.3, 0.36))
	office.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var protocol := _text(view, "Protocolo nº %04d/2026" % rng.randi_range(100, 9999), Vector2(214, 46), 180, 12, Color(0.42, 0.4, 0.4))
	protocol.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rect(view, Vector2(26, 78), Vector2(368, 3), Color(0.12, 0.22, 0.55))
	_text(view, doc_title, Vector2(26, 94), 368, 36, Color(0.1, 0.08, 0.07), _font(0.0, 0.5))
	_text(view, "Requisito obrigatório para a colação de grau", Vector2(26, 196), 368, 14, Color(0.42, 0.36, 0.3))
	for i in 12:
		var width := rng.randf_range(220.0, 368.0) if i % 4 != 3 else rng.randf_range(90.0, 180.0)
		_rect(view, Vector2(26, 232 + i * 21), Vector2(width, 6), Color(0.32, 0.3, 0.27, 0.5))

	var stamp_style := StyleBoxFlat.new()
	stamp_style.bg_color = Color(0, 0, 0, 0)
	stamp_style.border_color = Color(0.72, 0.08, 0.08)
	stamp_style.set_border_width_all(4)
	stamp_style.set_corner_radius_all(8)
	stamp_style.content_margin_left = 14
	stamp_style.content_margin_right = 14
	stamp_style.content_margin_top = 2
	stamp_style.content_margin_bottom = 2
	var stamp := PanelContainer.new()
	stamp.add_theme_stylebox_override("panel", stamp_style)
	stamp.position = Vector2(rng.randf_range(170, 215), rng.randf_range(430, 455))
	stamp.rotation = rng.randf_range(-0.3, -0.14)
	stamp.modulate.a = 0.82
	view.add_child(stamp)
	var stamp_text := Label.new()
	stamp_text.text = STAMPS[rng.randi() % STAMPS.size()]
	stamp_text.add_theme_font_override("font", _font(0.0, 0.8))
	stamp_text.add_theme_font_size_override("font_size", 30)
	stamp_text.add_theme_color_override("font_color", Color(0.72, 0.08, 0.08))
	stamp.add_child(stamp_text)

	_text(view, "Facefinho", Vector2(40, 514), 220, 24, Color(0.12, 0.16, 0.45), _font(0.3, 0.2))
	_rect(view, Vector2(26, 548), Vector2(180, 2), Color(0.2, 0.18, 0.16))
	_text(view, "assinatura do responsável", Vector2(26, 554), 220, 11, Color(0.4, 0.36, 0.32))


func _paint_note(view: SubViewport) -> void:
	var size := Vector2(view.size)
	_rect(view, Vector2.ZERO, size, Color(0.93, 0.88, 0.7))
	for y in range(74, int(size.y), 30):
		_rect(view, Vector2(0, y), Vector2(size.x, 2), Color(0.45, 0.58, 0.8, 0.35))
	_rect(view, Vector2(56, 0), Vector2(2, size.y), Color(0.8, 0.3, 0.3, 0.5))
	_ring(view, Vector2(340, 70), 40.0, Color(0.5, 0.36, 0.2, 0.2))
	var ink := Color(0.13, 0.11, 0.1)
	_text(view, "AVISO", Vector2(70, 8), 340, 58, Color(0.62, 0.05, 0.05), _font(0.26, 1.0))
	_text(view, "Não mexa nas coisas dele.", Vector2(70, 92), 350, 30, ink, _font(0.26, 0.3))
	_text(view, "Se você tirou este bilhete,\nele já sabe.", Vector2(70, 160), 350, 24, ink, _font(0.26, 0.2))
	var drop := Panel.new()
	var blot := StyleBoxFlat.new()
	blot.bg_color = Color(0.5, 0.03, 0.03, 0.6)
	blot.set_corner_radius_all(18)
	drop.add_theme_stylebox_override("panel", blot)
	drop.position = Vector2(372, 246)
	drop.size = Vector2(30, 36)
	view.add_child(drop)


func _rect(view: Node, pos: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	view.add_child(rect)


func _ring(view: Node, center: Vector2, radius: float, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(radius))
	var ring := Panel.new()
	ring.add_theme_stylebox_override("panel", style)
	ring.position = center - Vector2(radius, radius)
	ring.size = Vector2(radius, radius) * 2.0
	view.add_child(ring)


func _text(view: Node, text: String, pos: Vector2, width: float, size: int, color: Color, font: Font = null) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, 0)
	label.custom_minimum_size = Vector2(width, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if font:
		label.add_theme_font_override("font", font)
	view.add_child(label)
	return label


func _font(slant: float, bold: float) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = bold
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(slant, 1.0), Vector2.ZERO)
	return font


func _add_dust(pos: Vector3) -> void:
	var dust := CPUParticles3D.new()
	dust.name = "Dust"
	var mote := QuadMesh.new()
	mote.size = Vector2(0.012, 0.012)
	dust.mesh = mote
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.vertex_color_use_as_albedo = true
	dust.material_override = mat
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	fade.colors = PackedColorArray([Color(1.0, 0.85, 0.5, 0.0), Color(1.0, 0.85, 0.5, 0.8), Color(1.0, 0.85, 0.5, 0.0)])
	dust.color_ramp = fade
	dust.amount = 18
	dust.lifetime = 2.8
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.28
	dust.direction = Vector3.UP
	dust.spread = 60.0
	dust.gravity = Vector3(0.0, 0.03, 0.0)
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.07
	dust.position = pos
	add_child(dust)


func _play_rustle() -> void:
	var sfx := AudioStreamPlayer.new()
	var mix := 22050.0
	var count := int(mix * 0.42)
	var data := PackedByteArray()
	data.resize(count * 2)
	var low := 0.0
	var crack := 0.0
	for i in count:
		var t := float(i) / mix
		if randf() < 0.006:
			crack = randf_range(0.4, 1.0)
		crack *= 0.996
		var noise := randf_range(-1.0, 1.0)
		low += (noise - low) * 0.3
		var env := pow(sin(PI * t / 0.42), 0.6)
		var s := ((noise - low) * crack * 0.8 + (noise - low) * 0.12) * env
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = data
	sfx.stream = wav
	sfx.volume_db = -3.0
	add_child(sfx)
	sfx.play()


func _player_camera() -> Camera3D:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_camera"):
		return player.get_camera()
	return null


func _finish_grab() -> void:
	picked_up.emit(doc_id if doc_id != "" else doc_title)
	queue_free()


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat
