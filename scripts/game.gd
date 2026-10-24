extends Node3D

enum State { MENU, PLAYING, READING, CUTSCENE, ENDED }

const NOTE_ID := "bilhete"
const PLAYER_SPAWN := Vector3(0, 0.1, 21.5)
const HANG_PEG := Vector3(-1.97, 2.55, 9.6)
const BLOCKS: Array[float] = [0.0, -24.4, -48.8]
const BLOCK_NAMES: Array[String] = ["BLOCO A", "BLOCO B", "BLOCO C"]
const SOUTH_Z := 12.2
const NORTH_Z := -61.0
const INNER_X := 16.2
const OUTER_X := 19.6
const WAKE_SPOT := Vector3(0, 0.1, -40.0)

const DOCS: Array[Dictionary] = [
	{
		"id": NOTE_ID,
		"title": "Bilhete de aviso",
		"pos": Vector3(-1.21, 1.53, 9.58),
		"yaw": PI / 2.0,
		"pinned": true,
		"kicker": "BILHETE ENCONTRADO",
		"close": "Guardar o bilhete",
		"lore": "Estava preso com um alfinete no peito da fantasia, escrito à mão: \"Não mexa nas coisas dele. Se você tirou este bilhete do lugar, a fantasia não está mais vazia. Ele vai buscar os oito documentos junto com você.\"",
		"effect": "O Facefinho acordou. A perseguição começou.",
	},
	{
		"id": "tcc",
		"title": "TCC",
		"pos": Vector3(11, 0, 8),
		"yaw": PI / 2.0,
		"lore": "A ata da banca está quase em branco. No rodapé, há uma letra que não é sua: o orientador não espera ninguém. Cada página que você entrega deixa o passo dele mais longo.",
		"effect": "Ele corre mais rápido para perseguir você.",
	},
	{
		"id": "estagio",
		"title": "Estágio obrigatório",
		"pos": Vector3(-14, 0, -0.9),
		"yaw": PI / 2.0,
		"lore": "O termo de compromisso exige acompanhamento integral. A assinatura no fim não é um nome. É uma ordem: ele fica sempre atrás de você, observando. O supervisor só intervém quando o estagiário para de trabalhar.",
		"effect": "Ele passa a seguir você de perto, sempre atrás, observando. Se ficar parado por alguns segundos, ele avança.",
	},
	{
		"id": "relatorio",
		"title": "Relatório de estágio",
		"pos": Vector3(-10, 0, -56.8),
		"yaw": PI / 2.0,
		"lore": "O relatório descreve visitas de que você não se lembra. Ele aprendeu a ouvir o corredor. Um passo longe demais e ele sabe em que bloco você entrou.",
		"effect": "Ele escuta mais longe e fecha a distância mais rápido.",
	},
	{
		"id": "horas",
		"title": "Horas complementares",
		"pos": Vector3(11, 0, -31.4),
		"yaw": PI / 2.0,
		"lore": "A planilha de horas não fecha. Onde deveriam estar os comprovantes, está escrito que a luz que você gasta conta como presença. A lanterna se apaga mais cedo.",
		"effect": "A bateria da lanterna acaba mais rápido.",
	},
	{
		"id": "integrador",
		"title": "Projeto integrador",
		"pos": Vector3(13.4, 0, -24.4),
		"yaw": PI / 2.0,
		"lore": "O projeto pede que todas as partes andem ao mesmo tempo. Nem a luz da lanterna interrompe o passo. Ele continua vindo mesmo enquanto você o ilumina.",
		"effect": "Ele anda mesmo com a lanterna apontada para ele.",
	},
	{
		"id": "artigo",
		"title": "Artigo científico",
		"pos": Vector3(-10, 0, -8),
		"yaw": 0.0,
		"lore": "O resumo avisa que a observação prolongada invalida o experimento. Quanto mais tempo seus olhos ficam nele, mais a imagem se desfaz em estática.",
		"effect": "A estática sobe mais rápido enquanto você o encara.",
	},
	{
		"id": "prova",
		"title": "Prova substitutiva",
		"pos": Vector3(-10, 0, 8),
		"yaw": PI / 2.0,
		"lore": "A prova substitui a regra antiga. Já não é preciso que ele encoste em você. Chegar perto basta, e a margem que protegia você encolheu.",
		"effect": "Ele alcança você de uma distância maior.",
	},
	{
		"id": "colacao",
		"title": "Colação de grau",
		"pos": Vector3(7, 0, -58.8),
		"yaw": 0.0,
		"lore": "Seu nome está na lista de formandos, ao lado do dele. Depois da colação, a cerimônia não para. Nem a lanterna interrompe mais os passos dele.",
		"effect": "Ele não para mais sob a luz da lanterna.",
	},
]

const MIX_RATE := 22050.0

var state := State.MENU
var pages := 0
var debug_mode := false
var debug_god := false
var _god_button: Button
var _debug_hidden_by_scare := false

var _player: CharacterBody3D
var _slender: CharacterBody3D
var _locker: Node3D
var _breath_bar: ProgressBar
var _breath_threat := false
var _breath_slip := 0.0
var _pulling := false
var _vents: Array[Node3D] = []
var _duct_pts: Array[Vector3] = []
var _duct_links: Array[PackedInt32Array] = []
var _grace := 8.0
var _awake := false
var _hang_pivot: Node3D
var _hang_costume: Node3D
var _hang_t := 0.0
var _hang_swing := 0.02
var _read_kicker: Label
var _read_close: Button
var _hint_timer := 0.0
var _audio_phase := 0.0
var _heart_phase := 0.0
var _music_t := 0.0

const _MELODY: Array[int] = [
	0, 2, 4, 7, 4, 7, 9, 7, 4, 5, 7, 4, 2, 0, 2, 4,
	7, 9, 11, 12, 11, 9, 7, 5, 4, 5, 7, 4, 2, 0, 4, 7,
]
const _BASS: Array[int] = [
	-12, -12, -5, -12, -12, -12, -5, -7, -12, -8, -5, -7, -10, -12, -8, -5,
	-12, -12, -5, -7, -12, -8, -5, -3, -5, -7, -5, -8, -12, -12, -5, -7,
]

var _static_mat: ShaderMaterial
var _pages_label: Label
var _battery_label: Label
var _hint_label: Label
var _prompt_label: Label
var _todo_label: Label
var _menu: Control
var _hud: Control
var _debug_panel: PanelContainer
var _debug_stats: Label
var _debug_log_label: Label
var _static_bar: ProgressBar
var _end_panel: PanelContainer
var _end_message: Label
var _read_panel: Control
var _read_title: Label
var _read_lore: Label
var _read_effect: Label
var _reading: Dictionary = {}
var _rules: PackedStringArray = []
var _audio: AudioStreamPlayer
var _debug_log: PackedStringArray = []
var _fade: ColorRect
var _ceremony: Node3D
var _ceremony_cam: Camera3D
var _face_point := Vector3.ZERO
var _zoom_from := Vector3.ZERO
var _zoom_to := Vector3.ZERO
var _zoom := 0.0
var _zooming := false
var _scare := 0.0
var _cut_t := 0.0
var _cut_hold := -1.0
var _cut_done := false
var _hero: Node3D
var _crowd: Array[Node3D] = []
var _canudo: Node3D
var _canudo_held := false
var _hero_from := Vector3(0.0, 0.0, 1.2)
var _hero_to := Vector3(0.02, 0.48, -1.28)
var _rector: Node3D
var _face_node: Node3D
var _mouth: Node3D
var _tone_t := 0.0
var _grad_seed := 0
var _cer_hi := 0.0
var _cer_lo := 0.0
var _clap := 0.0
var _wall_mats := {}
var _props := Surfaces.Batch.new()
var _chalk_mat: ShaderMaterial
var _read_card: PanelContainer
var _read_style: StyleBoxFlat
var _read_logo: TextureRect
var _read_rule: ColorRect
var _read_stamp: PanelContainer
var _vignette: TextureRect
var _behind_warned := false
var _mouth_scale := Vector3.ONE
var _mouth_pos := Vector3.ZERO
var _stage_spot: SpotLight3D
var _fill_light: OmniLight3D
var _aisle_light: OmniLight3D
var _sick_light: OmniLight3D
var _confetti: CPUParticles3D
var _flashes: Array[OmniLight3D] = []
var _cam_attr: CameraAttributesPractical
var _quiet_end := false
var _caught_scare := 0.0
var _caught_reason := ""
var _catcher: Node3D
var _catcher_mouth: Node3D
var _catcher_mouth_scale := Vector3.ONE
var _catcher_mouth_pos := Vector3.ZERO
var _catcher_light: OmniLight3D
var _catch_forward := Vector3.FORWARD
var _face_local := Vector3(3.22, 1.8, 4.28)
const DOLLY_END := Vector3(3.08, 1.8, 3.1)

const CUT_CLIMB := 2.6
const CUT_WALK := 5.8
const CUT_HAND := 9.6
const CUT_TURN := 11.3
const CUT_PAN := 14.4
const CUT_FOCUS := 18.0
const CUT_DOLLY := 26.6


func _ready() -> void:
	_ensure_actions()
	_build_world()
	_build_player()
	_build_slender()
	_build_ui()
	_build_pages()
	_props.flush()
	_settle_vents()
	_refresh_list()
	_build_audio()


func _process(delta: float) -> void:
	_pump_audio()
	if _vignette and state != State.PLAYING:
		_vignette.modulate.a = 0.0
	if state == State.CUTSCENE:
		_update_cutscene(delta)
		return
	if _caught_scare > 0.0:
		if debug_god:
			_abort_caught_scare()
		else:
			_update_caught_scare(delta)
			return
	_sway_hanger(delta)
	if state != State.PLAYING:
		return
	if _awake and _grace > 0.0:
		_grace -= delta
		if _grace <= 0.0:
			_slender.active = true
			_show_hint("Ele está andando pela faculdade.")
	_update_breath(delta)
	if debug_god and _slender.active and not _player.hidden and not _slender.venting:
		var close := _player.global_position.distance_to(_slender.global_position)
		if close < _slender.catch_distance + 0.4:
			_slender.static_level = minf(_slender.static_level, 0.15)
			_slender._static_hold = 0.0
			_debug_shove_mascot()
	if _hint_timer > 0.0:
		_hint_timer -= delta
	else:
		_hint_label.modulate.a = move_toward(_hint_label.modulate.a, 0.0, delta * 0.7)

	_player.apply_fear(_slender.static_level, _slender.global_position.distance_to(_player.global_position))
	_static_mat.set_shader_parameter("intensity", _slender.static_level)
	_update_vignette()
	_pages_label.text = "Documentos  %d / 8" % pages
	_battery_label.text = "Lanterna  %d%%" % int(_player.battery)
	_update_prompt()
	if debug_mode:
		_refresh_debug()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.READING and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel")):
		_close_reading()
	elif state == State.MENU and event.is_action_pressed("ui_accept"):
		_start_game(false)
	elif state == State.ENDED and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif state == State.PLAYING and event.is_action_pressed("debug_toggle"):
		if not debug_mode:
			_set_debug(true)
		elif _debug_panel:
			_debug_panel.visible = not _debug_panel.visible
	elif state == State.PLAYING and event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if state != State.PLAYING or not (event is InputEventMouseButton and event.pressed):
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if get_viewport().gui_get_hovered_control() == null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	if state != State.PLAYING:
		return
	if not Input.is_action_just_pressed("interact"):
		return
	if _player.hidden:
		if _breath_threat or _pulling:
			return
		if _locker:
			_locker.leave(_player)
		return
	for node in get_tree().get_nodes_in_group("pages"):
		if node.can_pick(_player.global_position) and _can_take(node):
			node.pick()
			return
	var locker := _nearest_locker()
	if locker:
		_locker = locker
		locker.enter(_player)


func _can_take(page: Node) -> bool:
	return _awake or page.doc_id == NOTE_ID


func is_position_clear(pos: Vector3, radius: float) -> bool:
	if not _walkable(pos):
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = minf(radius, 0.5)
	params.shape = sphere
	params.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0.0, 1.0, 0.0))
	params.collide_with_areas = false
	if _slender:
		params.exclude = [_slender.get_rid(), _player.get_rid()]
	return space.intersect_shape(params, 1).is_empty()


func _start_game(as_debug: bool) -> void:
	if state != State.MENU:
		return
	state = State.PLAYING
	_player.active = true
	_menu.visible = false
	_hud.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not as_debug:
		debug_god = false
	_set_debug(as_debug)
	_sync_god_button()
	if as_debug:
		_debug_note("Modo debug ligado. Esc solta o mouse.")
	_show_hint("Entre na faculdade." if not as_debug else "Debug ativo. F3 esconde o painel.")


func _on_page_picked(doc_id: String) -> void:
	var doc := _doc_by_id(doc_id)
	if doc_id != NOTE_ID:
		pages += 1
		_slender.set_pages(pages)
	_play_tone(520.0, 0.12, 0.35)
	_refresh_list()
	_pages_label.text = "Documentos  %d / 8" % pages
	_open_reading(doc)


func _doc_by_id(doc_id: String) -> Dictionary:
	for doc in DOCS:
		if doc.id == doc_id:
			return doc
	return {"id": doc_id, "title": doc_id, "lore": "", "effect": ""}


func _open_reading(doc: Dictionary) -> void:
	_reading = doc
	state = State.READING
	_player.active = false
	_slender.held = true
	_slender.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_read_kicker.text = str(doc.get("kicker", "DOCUMENTO ENCONTRADO"))
	_read_close.text = str(doc.get("close", "Guardar o documento"))
	_read_title.text = doc.title
	_read_lore.text = doc.lore
	_read_effect.text = doc.effect
	_style_reading(doc.get("pinned", false))
	_read_panel.visible = true
	_animate_reading()
	_prompt_label.text = ""
	if _debug_panel:
		_debug_panel.visible = false
	var notebook: Node = _player.camera.get_node_or_null("GrabbedNotebook")
	if notebook:
		notebook.queue_free()


func _close_reading() -> void:
	if state != State.READING:
		return
	var doc: Dictionary = _reading
	_read_panel.visible = false
	if doc.id == NOTE_ID:
		_return_to_play()
		_wake_mascot()
		_show_hint("A fantasia sumiu do cabide.")
		return
	_apply_doc_curse(str(doc.id))
	_rules.append(str(doc.title))
	_debug_note(str(doc.title) + ": " + str(doc.effect))
	if pages >= 8:
		_start_ceremony()
		return
	_return_to_play()
	_grace = 0.0
	_slender.active = true
	_slender.hear(_player.global_position)
	_show_hint(str(doc.effect))


func _update_vignette() -> void:
	var back: float = _slender.behind
	var beat := 0.0
	if _heart_phase < 0.1:
		beat = sin(_heart_phase / 0.1 * PI)
	elif _heart_phase > 0.14 and _heart_phase < 0.24:
		beat = sin((_heart_phase - 0.14) / 0.1 * PI) * 0.6
	var near: float = _slender.presence
	_vignette.modulate.a = clampf(back * (0.7 + 0.3 * beat) + near * 0.15 * beat, 0.0, 1.0)
	if back > 0.55 and not _behind_warned:
		_behind_warned = true
		_show_hint("Você sente alguém logo atrás de você...")


func _return_to_play() -> void:
	state = State.PLAYING
	_player.active = true
	_slender.held = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if debug_mode and _debug_panel:
		_debug_panel.visible = true


func _wake_mascot() -> void:
	if _awake:
		return
	_awake = true
	if _hang_costume:
		_hang_costume.queue_free()
		_hang_costume = null
	_hang_swing = 0.32
	_slender.global_position = WAKE_SPOT
	_slender.set_dormant(false)
	_grace = 2.0 if debug_mode else 3.5
	_refresh_list()
	_debug_note("Mascote acordado pelo bilhete")


func _sway_hanger(delta: float) -> void:
	if _hang_pivot == null:
		return
	_hang_t += delta
	if _awake:
		_hang_swing = move_toward(_hang_swing, 0.012, delta * 0.03)
	_hang_pivot.rotation.x = sin(_hang_t * (2.1 if _awake else 0.7)) * _hang_swing


func _apply_doc_curse(id: String) -> void:
	if id == "horas":
		_player.drain_scale += 1.15
		return
	_slender.apply_curse(id)


func _on_caught(reason: String) -> void:
	if debug_god and state != State.CUTSCENE and state != State.ENDED:
		_slender.active = true
		_slender.static_level = minf(_slender.static_level, 0.15)
		_slender._static_hold = 0.0
		if _caught_scare > 0.0:
			_abort_caught_scare()
		_debug_shove_mascot()
		_debug_note("Captura ignorada: " + reason)
		_show_hint("Debug: captura ignorada.")
		return
	_debug_note(reason)
	_start_caught_scare(reason)


func _abort_caught_scare() -> void:
	_caught_scare = 0.0
	if _catcher:
		_catcher.queue_free()
		_catcher = null
	_catcher_mouth = null
	_catcher_light = null
	if _slender:
		_slender.visible = true
		if state == State.PLAYING:
			_slender.active = true
	if _player and state == State.PLAYING:
		_player.active = true
		_player.camera.fov = 75.0
		_player.camera.h_offset = 0.0
		_player.camera.v_offset = 0.0
	if _fade:
		_fade.color = Color(0, 0, 0, 0)
		_fade.visible = false
	if _hud and state == State.PLAYING:
		_hud.visible = true
	if _static_mat:
		_static_mat.set_shader_parameter("intensity", 0.0)
	if _debug_panel and debug_mode and _debug_hidden_by_scare:
		_debug_panel.visible = true
	_debug_hidden_by_scare = false


func _start_caught_scare(reason: String) -> void:
	_caught_reason = reason
	_caught_scare = 1.55
	_player.active = false
	_hud.visible = false
	_prompt_label.text = ""
	if _debug_panel:
		_debug_hidden_by_scare = _debug_panel.visible
		_debug_panel.visible = false
	var cam: Camera3D = _player.camera
	_catch_forward = -cam.global_basis.z
	_catch_forward.y = 0.0
	_catch_forward = _catch_forward.normalized() if _catch_forward.length() > 0.01 else Vector3.FORWARD
	_slender.visible = false
	_catcher = _slender.get_node("Mascot").duplicate() as Node3D
	_catcher.name = "CatchScare"
	add_child(_catcher)
	_catcher.pose_standing()
	_catcher_mouth = _catcher.find_child("Mouth", true, false) as Node3D
	if _catcher_mouth:
		_catcher_mouth_scale = _catcher_mouth.scale
		_catcher_mouth_pos = _catcher_mouth.position
	_catcher_light = OmniLight3D.new()
	_catcher_light.position = Vector3(0.0, 1.8, 0.9)
	_catcher_light.omni_range = 3.2
	_catcher_light.light_color = Color(0.45, 0.85, 0.55)
	_catcher.add_child(_catcher_light)
	_fade.visible = true
	_apply_caught_scare()


func _place_catcher(distance: float, drop: float, tilt: float) -> void:
	var cam: Camera3D = _player.camera
	var side := _catch_forward.cross(Vector3.UP)
	var base: Vector3 = cam.global_position + _catch_forward * distance + side * 0.14
	base.y = cam.global_position.y - 1.8 - drop
	_catcher.global_position = base
	_catcher.rotation = Vector3(tilt, atan2(-_catch_forward.x, -_catch_forward.z), 0.0)


func _update_caught_scare(delta: float) -> void:
	_caught_scare -= delta
	if _caught_scare > 0.0:
		_apply_caught_scare()
		return
	_caught_scare = 0.0
	_player.camera.h_offset = 0.0
	_player.camera.v_offset = 0.0
	_fade.color = Color(0, 0, 0, 1)
	_end_game(_caught_reason)
	var layer := _fade.get_parent()
	layer.move_child(_end_panel, layer.get_child_count() - 1)


func _apply_caught_scare() -> void:
	var cam: Camera3D = _player.camera
	cam.h_offset = 0.0
	cam.v_offset = 0.0
	if _caught_scare > 1.32:
		_place_catcher(1.52, 0.0, 0.0)
		cam.fov = 30.0
		cam.look_at(_catcher.to_global(Vector3(0.0, 1.8, 0.34)), Vector3.UP)
		_fade.color = Color(0, 0, 0, 0.2)
		_static_mat.set_shader_parameter("intensity", 0.0)
		_catcher_light.light_energy = 2.5
		return
	if _caught_scare > 0.78:
		_place_catcher(0.98, 0.06, 0.12)
		if _catcher_mouth:
			_catcher_mouth.scale = _catcher_mouth_scale * Vector3(1.3, 2.7, 1.4)
			_catcher_mouth.position = _catcher_mouth_pos + Vector3(0.0, -0.1, -0.01)
		cam.fov = 62.0
		cam.look_at(_catcher.to_global(Vector3(-0.02, 1.62, 0.44)), Vector3.UP)
		cam.h_offset = randf_range(-0.04, 0.04)
		cam.v_offset = randf_range(-0.03, 0.03)
		_static_mat.set_shader_parameter("intensity", 0.58)
		_fade.color = Color(0.45, 0.02, 0.03, 0.18)
		_catcher_light.light_energy = 7.0
		return
	_fade.color = Color(0, 0, 0, 1)
	_static_mat.set_shader_parameter("intensity", 0.0)


func _end_game(message: String) -> void:
	if state == State.ENDED:
		return
	state = State.ENDED
	_player.active = false
	_slender.active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end_message.text = message
	_end_panel.visible = true
	_prompt_label.text = ""
	if _debug_panel:
		_debug_panel.visible = false
	if pages >= 8:
		_static_mat.set_shader_parameter("intensity", 0.0 if _quiet_end else 0.15)
		if not _quiet_end:
			_play_tone(330.0, 0.4, 0.4)
	else:
		_static_mat.set_shader_parameter("intensity", 1.0)
		_play_tone(60.0, 0.45, 0.7)


func _start_ceremony() -> void:
	state = State.CUTSCENE
	_player.active = false
	_slender.active = false
	_slender.held = true
	_hud.visible = false
	if _debug_panel:
		_debug_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_static_mat.set_shader_parameter("intensity", 0.0)
	_build_ceremony()
	_player.camera.current = false
	_ceremony_cam.current = true
	_fade.visible = true
	_fade.color = Color(0, 0, 0, 1)
	var fade_in := create_tween()
	fade_in.tween_property(_fade, "color:a", 0.0, 0.55)
	_zoom = 0.0
	_zooming = false
	_scare = 0.0
	_cut_t = 0.0
	_cut_hold = -1.0
	_cut_done = false
	_canudo_held = false


func _build_ceremony() -> void:
	_ceremony = Node3D.new()
	_ceremony.name = "Ceremony"
	_ceremony.position = Vector3(0, 50, 0)
	add_child(_ceremony)
	_stage_box(Vector3(12.0, 0.12, 12.0), Vector3(0, 0.06, 0.9), Color(0.11, 0.07, 0.05))
	_stage_box(Vector3(0.9, 0.025, 2.2), Vector3(0, 0.13, 1.85), Color(0.48, 0.07, 0.1))
	_stage_box(Vector3(8.6, 0.48, 4.4), Vector3(0, 0.24, -2.35), Color(0.32, 0.18, 0.09))
	_stage_box(Vector3(0.95, 0.02, 2.3), Vector3(0, 0.5, -1.2), Color(0.55, 0.08, 0.11))
	_wood_step(Vector3(1.7, 0.16, 0.4), Vector3(0, 0.08, 0.78))
	_wood_step(Vector3(1.7, 0.16, 0.4), Vector3(0, 0.24, 0.4))
	_wood_step(Vector3(1.7, 0.16, 0.4), Vector3(0, 0.4, 0.02))
	_stage_box(Vector3(8.4, 3.3, 0.16), Vector3(0, 1.65, -4.45), Color(0.04, 0.05, 0.08))
	_stage_box(Vector3(10.5, 3.2, 0.14), Vector3(0.2, 1.6, 5.75), Color(0.035, 0.04, 0.055))
	_stage_box(Vector3(1.15, 2.15, 0.08), Vector3(3.25, 1.08, 5.66), Color(0.02, 0.045, 0.03))
	var banner := Label3D.new()
	banner.text = "COLAÇÃO DE GRAU"
	banner.font_size = 48
	banner.pixel_size = 0.012
	banner.position = Vector3(0, 2.65, -4.32)
	banner.modulate = Color(0.95, 0.84, 0.45)
	banner.outline_size = 8
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ceremony.add_child(banner)
	var exit_sign := Label3D.new()
	exit_sign.text = "SAÍDA"
	exit_sign.font_size = 28
	exit_sign.pixel_size = 0.008
	exit_sign.position = Vector3(3.25, 2.32, 5.58)
	exit_sign.rotation.y = PI
	exit_sign.modulate = Color(0.35, 0.95, 0.45)
	exit_sign.outline_size = 0
	_ceremony.add_child(exit_sign)
	_stage_box(Vector3(2.7, 0.07, 0.62), Vector3(0, 0.98, -1.88), Color(0.28, 0.15, 0.08))
	_crowd.clear()
	var columns: Array[float] = [-2.15, -1.25, 1.25, 2.15]
	var seat := 0
	for row in 3:
		for column in columns:
			var skin := Color(0.42, 0.28, 0.2).lerp(Color(0.9, 0.74, 0.58), float(seat % 5) / 4.0)
			var stole := Color(0.16, 0.22, 0.55) if seat % 2 == 0 else Color(0.72, 0.58, 0.18)
			var grad := _make_graduate(skin, stole)
			grad.position = Vector3(column, 0.0, 1.75 + float(row) * 0.92)
			_ceremony.add_child(grad)
			_crowd.append(grad)
			seat += 1
	_hero = _make_graduate(Color(0.9, 0.72, 0.55), Color(0.16, 0.28, 0.62))
	_hero.name = "Formando"
	_hero.position = _hero_from
	_ceremony.add_child(_hero)
	_rector = _make_graduate(Color(0.72, 0.56, 0.42), Color(0.62, 0.48, 0.12), true)
	_rector.name = "Reitor"
	_rector.position = Vector3(0.0, 0.48, -2.28)
	_ceremony.add_child(_rector)
	for side in [-0.95, 0.95]:
		var member := _make_graduate(Color(0.55, 0.38, 0.28), Color(0.2, 0.24, 0.4))
		member.position = Vector3(side, 0.48, -2.22)
		_ceremony.add_child(member)
	_canudo = _make_canudo()
	_ceremony.add_child(_canudo)
	var rector_hand := _rector.get_node("ArmR/Hand") as Node3D
	_canudo.reparent(rector_hand)
	_canudo.position = Vector3(0.02, -0.14, 0.02)
	_canudo.rotation_degrees = Vector3(75, 10, 8)
	_face_node = _slender.get_node("Mascot").duplicate() as Node3D
	_face_node.name = "Facefinho"
	_face_node.position = Vector3(3.22, 0.0, 4.62)
	_face_node.rotation.y = PI
	_ceremony.add_child(_face_node)
	_face_node.pose_standing()
	_mouth = _face_node.find_child("Mouth", true, false) as Node3D
	if _mouth:
		_mouth_scale = _mouth.scale
		_mouth_pos = _mouth.position
	_face_point = _ceremony.to_global(_face_local)
	_stage_spot = SpotLight3D.new()
	_stage_spot.position = Vector3(0.2, 3.5, -0.4)
	_stage_spot.rotation_degrees = Vector3(-62, 0, 0)
	_stage_spot.light_energy = 10.0
	_stage_spot.light_color = Color(1.0, 0.78, 0.48)
	_stage_spot.spot_range = 16.0
	_stage_spot.spot_angle = 42.0
	_ceremony.add_child(_stage_spot)
	_fill_light = OmniLight3D.new()
	_fill_light.position = Vector3(0, 2.5, -1.4)
	_fill_light.light_energy = 1.8
	_fill_light.omni_range = 9.0
	_fill_light.light_color = Color(1.0, 0.82, 0.55)
	_ceremony.add_child(_fill_light)
	var stair_light := OmniLight3D.new()
	stair_light.position = Vector3(0.2, 1.15, 1.4)
	stair_light.light_energy = 5.0
	stair_light.omni_range = 4.5
	stair_light.light_color = Color(1.0, 0.82, 0.55)
	_ceremony.add_child(stair_light)
	_aisle_light = OmniLight3D.new()
	_aisle_light.position = Vector3(0.1, 2.1, 1.3)
	_aisle_light.light_energy = 1.3
	_aisle_light.omni_range = 7.0
	_aisle_light.light_color = Color(1.0, 0.86, 0.62)
	_ceremony.add_child(_aisle_light)
	_sick_light = OmniLight3D.new()
	_sick_light.position = _face_local
	_sick_light.light_energy = 0.0
	_sick_light.omni_range = 3.2
	_sick_light.light_color = Color(0.45, 0.85, 0.55)
	_ceremony.add_child(_sick_light)
	_flashes.clear()
	for flash_at in [Vector3(-1.4, 1.6, 2.2), Vector3(1.6, 1.55, 2.8), Vector3(-0.4, 1.7, 3.5), Vector3(2.0, 1.5, 1.9)]:
		var flash := OmniLight3D.new()
		flash.position = flash_at
		flash.light_energy = 0.0
		flash.omni_range = 2.4
		flash.light_color = Color(0.9, 0.95, 1.0)
		_ceremony.add_child(flash)
		_flashes.append(flash)
	_build_confetti()
	_ceremony_cam = Camera3D.new()
	_ceremony_cam.fov = 46.0
	_ceremony_cam.current = false
	_ceremony_cam.position = Vector3(0.48, 0.2, 1.45)
	_ceremony.add_child(_ceremony_cam)
	_cam_attr = CameraAttributesPractical.new()
	_cam_attr.dof_blur_amount = 0.0
	_ceremony_cam.attributes = _cam_attr
	_ceremony_cam.look_at(_ceremony.to_global(_hero_from + Vector3(0, 0.05, 0)), Vector3.UP)


func _wood_step(size: Vector3, pos: Vector3) -> void:
	_stage_box(size, pos, Color(0.42, 0.24, 0.11))


func _build_confetti() -> void:
	_confetti = CPUParticles3D.new()
	var chip := QuadMesh.new()
	chip.size = Vector2(0.045, 0.028)
	_confetti.mesh = chip
	var paper := StandardMaterial3D.new()
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	paper.albedo_color = Color(1, 1, 1)
	_confetti.material_override = paper
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	colors.colors = PackedColorArray([
		Color(0.95, 0.82, 0.28),
		Color(0.95, 0.95, 0.92),
		Color(0.25, 0.42, 0.85),
	])
	_confetti.color_ramp = colors
	_confetti.amount = 140
	_confetti.lifetime = 3.4
	_confetti.explosiveness = 0.0
	_confetti.randomness = 0.7
	_confetti.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_confetti.emission_box_extents = Vector3(3.4, 0.2, 2.6)
	_confetti.position = Vector3(0.1, 3.35, 1.6)
	_confetti.direction = Vector3(0, -1, 0)
	_confetti.spread = 28.0
	_confetti.gravity = Vector3(0, -0.7, 0)
	_confetti.initial_velocity_min = 0.25
	_confetti.initial_velocity_max = 1.05
	_confetti.angular_velocity_min = -5.0
	_confetti.angular_velocity_max = 5.0
	_confetti.scale_amount_min = 0.45
	_confetti.scale_amount_max = 1.15
	_confetti.emitting = false
	_ceremony.add_child(_confetti)


func _make_graduate(skin: Color, stole_color: Color, rector := false) -> Node3D:
	var person := Node3D.new()
	person.set_script(load("res://scripts/graduate.gd"))
	_grad_seed += 1
	person.setup(skin, stole_color, _grad_seed * 7919, rector)
	return person


func _make_canudo() -> Node3D:
	var root := Node3D.new()
	root.name = "Canudo"
	var tube := CylinderMesh.new()
	tube.top_radius = 0.034
	tube.bottom_radius = 0.034
	tube.height = 0.34
	var paper := MeshInstance3D.new()
	paper.mesh = tube
	paper.material_override = _flat(Color(0.94, 0.89, 0.74))
	root.add_child(paper)
	var ribbon := CylinderMesh.new()
	ribbon.top_radius = 0.042
	ribbon.bottom_radius = 0.042
	ribbon.height = 0.055
	var band := MeshInstance3D.new()
	band.mesh = ribbon
	band.material_override = _flat(Color(0.62, 0.1, 0.12))
	root.add_child(band)
	return root


func _pose_arms(person: Node3D, lift: float, swing: float) -> void:
	var left := person.get_node("ArmL") as Node3D
	var right := person.get_node("ArmR") as Node3D
	left.rotation.z = -lift
	right.rotation.z = lift
	left.rotation.x = swing
	right.rotation.x = -swing


func _give_canudo() -> void:
	if _canudo_held or _hero == null or _canudo == null:
		return
	_canudo_held = true
	var hand := _hero.get_node("ArmR/Hand") as Node3D
	_canudo.reparent(hand)
	_canudo.position = Vector3(0.0, -0.2, 0.0)
	_canudo.rotation = Vector3.ZERO
	_canudo.scale = Vector3(1.35, 1.35, 1.35)


func _reach(person: Node3D, left_x: float, right_x: float, left_z: float, right_z: float) -> void:
	var left := person.get_node("ArmL") as Node3D
	var right := person.get_node("ArmR") as Node3D
	left.rotation = Vector3(left_x, 0.0, left_z)
	right.rotation = Vector3(right_x, 0.0, right_z)


func _sway_gown(person: Node3D, amount: float) -> void:
	var skirt := person.get_node_or_null("Saia") as MeshInstance3D
	if skirt:
		skirt.rotation.z = amount


func _look_local(point: Vector3) -> void:
	_ceremony_cam.look_at(_ceremony.to_global(point), Vector3.UP)


func _update_cutscene(delta: float) -> void:
	if _scare > 0.0:
		_scare -= delta
		_apply_jumpscare()
		if _scare <= 0.0:
			_finish_ceremony()
		return
	if _ceremony_cam == null:
		return
	if _cut_hold >= 0.0:
		_cut_t = _cut_hold
	else:
		var rate := 0.36 if _cut_t >= 7.25 and _cut_t < 7.85 else 1.0
		_cut_t += delta * rate
	_apply_ceremony_pose(_cut_t)
	if _cut_hold < 0.0 and not _cut_done and _cut_t >= CUT_DOLLY:
		_cut_done = true
		_jumpscare()


func _apply_ceremony_pose(t: float) -> void:
	_pose_people(t)
	_pose_camera(t)
	_pose_lights(t)


func _pose_people(t: float) -> void:
	if _hero:
		_sway_gown(_hero, 0.0)
		if t < CUT_CLIMB:
			var u := smoothstep(0.0, 1.0, t / CUT_CLIMB)
			var z := lerpf(1.2, -0.05, u)
			var step_y := 0.0
			if z < 0.78:
				step_y = 0.16
			if z < 0.4:
				step_y = 0.32
			if z < 0.02:
				step_y = 0.48
			_hero.position = Vector3(0.0, step_y, z)
			_hero.position.y += absf(sin(t * 9.0)) * 0.02
			_hero.rotation = Vector3(lerpf(0.22, 0.0, u), PI, 0.0)
			_pose_arms(_hero, 0.2, sin(t * 9.0) * 0.55)
			_sway_gown(_hero, sin(t * 8.0) * 0.07)
		elif t < CUT_WALK:
			var u := smoothstep(0.0, 1.0, (t - CUT_CLIMB) / (CUT_WALK - CUT_CLIMB))
			_hero.position = Vector3(0.0, 0.48, lerpf(-0.05, _hero_to.z, u))
			_hero.position.y += absf(sin(t * 8.0)) * 0.03
			_hero.rotation = Vector3(0.0, PI, 0.0)
			_pose_arms(_hero, 0.22, sin(t * 8.0) * 0.4)
			_sway_gown(_hero, sin(t * 8.0) * 0.06)
		elif t < CUT_HAND:
			var u := clampf((t - CUT_WALK) / 1.1, 0.0, 1.0)
			_hero.position = _hero_to
			_hero.rotation = Vector3(0.0, PI, 0.0)
			_reach(_hero, lerpf(0.0, -1.15, u), lerpf(0.0, -1.05, u), 0.2, -0.15)
			if _rector:
				_reach(_rector, lerpf(0.0, -1.05, u), lerpf(0.0, -1.2, u), -0.1, 0.2)
			if t >= 7.35:
				_give_canudo()
		else:
			var spin := smoothstep(0.0, 1.0, (t - CUT_HAND) / (CUT_TURN - CUT_HAND))
			var lift := smoothstep(0.15, 0.85, spin)
			_hero.position = _hero_to + Vector3(0, sin(t * 8.0) * 0.05 * lift, 0)
			_hero.rotation = Vector3(0.0, lerpf(PI, 0.0, spin), 0.0)
			_pose_arms(_hero, lerpf(0.3, 2.2, lift), -0.25)
			_give_canudo()
	if _rector and t >= CUT_HAND:
		_pose_arms(_rector, 0.35, 0.0)
	var cheer := 0.0 if t < CUT_HAND else smoothstep(0.0, 1.0, (t - CUT_HAND) / 0.8)
	for grad in _crowd:
		grad.rotation.y = PI + sin(t * 1.2 + grad.position.x) * 0.04
		if cheer > 0.2:
			_pose_arms(grad, 0.9, sin(t * 16.0 + grad.position.x * 3.0) * 0.35)
		else:
			_pose_arms(grad, 0.16, 0.0)
	if _confetti:
		_confetti.emitting = t >= CUT_HAND and t < CUT_DOLLY


func _pose_camera(t: float) -> void:
	if _ceremony_cam == null or _hero == null:
		return
	_ceremony_cam.fov = 46.0
	if _cam_attr:
		_cam_attr.dof_blur_amount = 0.0
	if t < CUT_CLIMB:
		var u := smoothstep(0.0, 1.0, clampf((t - 1.0) / (CUT_CLIMB - 1.0), 0.0, 1.0))
		var beside := Vector3(0.95, 0.58, _hero.position.z + 0.45)
		var front := Vector3(0.28, 1.42, _hero.position.z - 0.78)
		_ceremony_cam.position = beside.lerp(front, u)
		_ceremony_cam.fov = lerpf(42.0, 36.0, u)
		var feet := _hero.position + Vector3(0.02, 0.045, 0.02)
		_look_local(feet.lerp(_hero.position + Vector3(0, 1.48, -0.08), u))
	elif t < CUT_WALK:
		_ceremony_cam.position = Vector3(-0.95, 1.12, _hero.position.z + 1.2)
		_ceremony_cam.fov = 48.0
		_look_local(_hero.position + Vector3(0, 1.05, -0.55))
	elif t < CUT_HAND:
		_ceremony_cam.position = Vector3(1.45, 1.4, -1.42)
		_ceremony_cam.fov = 36.0
		_look_local(Vector3(0.05, 1.18, -1.9))
	elif t < CUT_PAN:
		var pan := 0.0 if t < CUT_TURN else smoothstep(0.0, 1.0, (t - CUT_TURN) / (CUT_PAN - CUT_TURN))
		_ceremony_cam.position = Vector3(0.35, 1.48, 0.35)
		_ceremony_cam.fov = lerpf(40.0, 56.0, pan)
		var face_look := _hero.position + Vector3(0, 1.52, 0)
		_look_local(face_look.lerp(Vector3(0.4, 1.3, 4.9), pan))
	elif t < CUT_FOCUS:
		var u := smoothstep(0.0, 1.0, (t - CUT_PAN) / (CUT_FOCUS - CUT_PAN))
		_ceremony_cam.position = Vector3(0.15, 1.62, -0.2).lerp(Vector3(0.55, 1.58, 0.85), u)
		_ceremony_cam.fov = 52.0
		_look_local(Vector3(1.4, 1.35, 3.2).lerp(_face_local, u * 0.35))
		if _cam_attr:
			_cam_attr.dof_blur_amount = 0.22
			_cam_attr.dof_blur_near_enabled = true
			_cam_attr.dof_blur_far_enabled = true
			_cam_attr.dof_blur_near_distance = lerpf(0.4, 5.5, u)
			_cam_attr.dof_blur_far_distance = lerpf(3.2, 14.0, u)
			_cam_attr.dof_blur_near_transition = 1.4
			_cam_attr.dof_blur_far_transition = 2.0
	else:
		var u := smoothstep(0.0, 1.0, clampf((t - CUT_FOCUS) / (CUT_DOLLY - CUT_FOCUS), 0.0, 1.0))
		var eased := u * u
		_ceremony_cam.position = Vector3(0.15, 1.6, 0.6).lerp(DOLLY_END, eased)
		_ceremony_cam.fov = lerpf(54.0, 30.0, eased)
		_look_local(_face_local)
		if _cam_attr:
			_cam_attr.dof_blur_amount = lerpf(0.22, 0.05, eased)


func _pose_lights(t: float) -> void:
	var dim := 1.0
	if t >= CUT_FOCUS:
		dim = lerpf(1.0, 0.03, smoothstep(0.0, 1.0, (t - CUT_FOCUS) / 4.5))
	if _stage_spot:
		_stage_spot.light_energy = 10.0 * dim
	if _fill_light:
		_fill_light.light_energy = 1.8 * dim
	if _aisle_light:
		_aisle_light.light_energy = 1.3 * dim
	if _sick_light:
		var sick := 0.0 if t < CUT_PAN else smoothstep(0.0, 1.0, (t - CUT_PAN) / 6.0)
		_sick_light.light_energy = sick * 4.2
		_sick_light.position = _face_local
	for flash in _flashes:
		flash.light_energy = 0.0
		if t >= CUT_TURN and t < CUT_FOCUS:
			var pulse := pow(maxf(sin(t * 17.0 + flash.position.x * 4.0), 0.0), 10.0)
			flash.light_energy = pulse * 8.0
	if t >= CUT_TURN and t < CUT_PAN:
		var burst := pow(maxf(sin(t * 15.0), 0.0), 14.0)
		_fade.color = Color(1, 1, 1, burst * 0.45)
	elif t >= CUT_FOCUS:
		var vignette := smoothstep(0.0, 1.0, (t - CUT_FOCUS) / (CUT_DOLLY - CUT_FOCUS))
		_fade.color = Color(0, 0, 0, vignette * 0.5)
		_static_mat.set_shader_parameter("intensity", vignette * vignette * 0.08)
	elif t > 0.7:
		_fade.color = Color(0, 0, 0, 0)
		_static_mat.set_shader_parameter("intensity", 0.0)


func _jumpscare() -> void:
	_scare = 1.55
	if _cam_attr:
		_cam_attr.dof_blur_amount = 0.0


func _apply_jumpscare() -> void:
	if _ceremony_cam == null:
		return
	_ceremony_cam.h_offset = 0.0
	_ceremony_cam.v_offset = 0.0
	if _scare > 1.32:
		_ceremony_cam.position = DOLLY_END
		_ceremony_cam.fov = 30.0
		_look_local(_face_local)
		_fade.color = Color(0, 0, 0, 0.2)
		_static_mat.set_shader_parameter("intensity", 0.0)
		return
	if _scare > 0.78:
		_ceremony_cam.h_offset = randf_range(-0.04, 0.04)
		_ceremony_cam.v_offset = randf_range(-0.03, 0.03)
		_ceremony_cam.position = DOLLY_END
		_ceremony_cam.fov = 62.0
		if _face_node:
			_face_node.position = Vector3(3.22, -0.06, 4.08)
			_face_node.rotation.x = 0.12
		if _mouth:
			_mouth.scale = _mouth_scale * Vector3(1.3, 2.7, 1.4)
			_mouth.position = _mouth_pos + Vector3(0.0, -0.1, -0.01)
		_face_point = _ceremony.to_global(Vector3(3.24, 1.56, 3.64))
		_ceremony_cam.look_at(_face_point, Vector3.UP)
		_static_mat.set_shader_parameter("intensity", 0.58)
		_fade.color = Color(0.45, 0.02, 0.03, 0.18)
		if _sick_light:
			_sick_light.light_energy = 7.0
		return
	_ceremony_cam.h_offset = 0.0
	_ceremony_cam.v_offset = 0.0
	_fade.color = Color(0, 0, 0, 1)
	_static_mat.set_shader_parameter("intensity", 0.0)


func _finish_ceremony() -> void:
	_quiet_end = true
	_static_mat.set_shader_parameter("intensity", 0.0)
	if _fade:
		_fade.color = Color(0, 0, 0, 1)
	_end_game("A colação de grau acabou.\nO Facefinho estava no fundo.")
	if _end_panel and _fade:
		var layer := _fade.get_parent()
		layer.move_child(_end_panel, layer.get_child_count() - 1)


func _stage_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = _flat(color)
	_ceremony.add_child(mesh)


func _flat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	return mat


func _show_hint(text: String) -> void:
	_hint_label.text = text
	_hint_label.modulate.a = 1.0
	_hint_timer = 4.5


func _update_breath(delta: float) -> void:
	if _player == null or _slender == null or _breath_bar == null:
		return
	_player.breath_max = lerpf(4.5, 2.8, _slender.aggression)
	if _player.breath > _player.breath_max:
		_player.breath = _player.breath_max
	var dist := _player.global_position.distance_to(_slender.global_position)
	var mode := str(_slender.get("_mode"))
	var hunting := mode == "hunt" or mode == "search"
	var close := dist < (9.0 if _breath_threat else 7.0)
	_breath_threat = (
		_player.hidden
		and not _pulling
		and not _slender.venting
		and _slender.active
		and hunting
		and close
	)
	if _breath_threat:
		var holding := Input.is_action_pressed("breath")
		_player.holding_breath = holding
		if holding:
			_player.breath = maxf(_player.breath - delta, 0.0)
			_player.noise = 0.0
			_breath_slip = 0.0
			if _player.breath <= 0.0:
				_fail_breath()
		elif dist < 4.5:
			_breath_slip += delta
			if _breath_slip >= 0.8:
				_fail_breath()
		else:
			_breath_slip = 0.0
	else:
		_player.holding_breath = false
		_breath_slip = 0.0
		if not _pulling:
			_player.breath = minf(_player.breath + delta * 1.6, _player.breath_max)
	var show: bool = _player.hidden and (_breath_threat or _player.breath < _player.breath_max - 0.15)
	_breath_bar.visible = show and state == State.PLAYING
	_breath_bar.value = _player.breath / maxf(_player.breath_max, 0.1)


func _fail_breath() -> void:
	if _pulling:
		return
	_breath_threat = false
	_player.holding_breath = false
	_breath_slip = 0.0
	if debug_god or _locker == null:
		_player.breath = _player.breath_max * 0.45
		return
	_pulling = true
	_player.noise = 22.0
	_slender.hear(_locker.global_position)
	_locker.drag_out(_player, _slender)


func _on_locker_pulled() -> void:
	if debug_god:
		_slender.held = false
		_pulling = false
		_player.breath = _player.breath_max
		return
	_start_caught_scare("O mascote abriu o armário.")


func _update_prompt() -> void:
	if _player.hidden:
		if _pulling:
			_prompt_label.text = ""
		elif _breath_threat:
			_prompt_label.text = "Segure Espaço  —  prender a respiração"
		else:
			_prompt_label.text = "E  —  Sair do armário"
		return
	var prompt := ""
	for node in get_tree().get_nodes_in_group("pages"):
		if node.can_pick(_player.global_position):
			if _can_take(node):
				prompt = "E  —  " + node.doc_title
			else:
				prompt = "Leia primeiro o bilhete preso na fantasia da entrada."
			break
	if prompt == "" and _nearest_locker():
		prompt = "E  —  Entrar no armário"
	_prompt_label.text = prompt


func _nearest_locker() -> Node:
	var best: Node = null
	var best_dist := 1.45
	for node in get_tree().get_nodes_in_group("lockers"):
		if not node.can_enter(_player.global_position):
			continue
		var dist: float = node.to_global(Vector3(0.0, 0.1, 0.75)).distance_to(_player.global_position)
		if dist < best_dist:
			best_dist = dist
			best = node
	return best


func _refresh_list() -> void:
	if _todo_label == null:
		return
	var lines: PackedStringArray = []
	for node in get_tree().get_nodes_in_group("pages"):
		if node.taken:
			continue
		lines.append(node.doc_title)
	_todo_label.text = "Faltam\n" + "\n".join(lines)


func _walkable(pos: Vector3) -> bool:
	var x := pos.x
	var z := pos.z
	var ax := absf(x)
	if ax < 1.55 and z < 11.3 and z > NORTH_Z + 0.9:
		return true
	if ax > INNER_X + 0.55 and ax < OUTER_X - 1.05 and z < SOUTH_Z - 0.75 and z > NORTH_Z + 0.75:
		return true
	for c: float in BLOCKS:
		var lz := z - c
		if absf(lz) > 12.2:
			continue
		if absf(lz) < 1.55 and ax < OUTER_X - 1.05:
			return true
		if ax > 2.7 and ax < INNER_X - 0.9 and absf(lz) > 2.7 and absf(lz) < 11.3:
			return true
		if ax > 1.35 and ax < 2.9 and (absf(lz + 8.0) < 1.2 or absf(lz - 6.0) < 1.2):
			return true
		if absf(ax - 11.0) < 0.9 and absf(lz) > 1.35 and absf(lz) < 2.9:
			return true
	if ax < 1.0 and z > 11.0 and z < 12.9:
		return true
	if absf(x) < 13.2 and z > 12.9 and z < 23.6:
		return true
	return false


func _build_world() -> void:
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.015, 0.025, 0.07)
	sky_mat.sky_horizon_color = Color(0.07, 0.09, 0.15)
	sky_mat.ground_horizon_color = Color(0.05, 0.06, 0.08)
	sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.015)
	sky_mat.sky_energy_multiplier = 0.6
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.07, 0.08, 0.12)
	env.ambient_light_energy = 0.22
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_density = 0.02
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_hdr_threshold = 1.6
	env.glow_bloom = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	_add_floor()
	_add_ceiling()
	_add_school_walls()
	_add_room_floors()
	_add_signs()
	_add_furniture()
	_add_ducts()
	_add_school_lights()
	_add_outside()
	_add_hanging_costume()


func _add_floor() -> void:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(OUTER_X * 2.0, SOUTH_Z - NORTH_Z)
	mesh.mesh = plane
	mesh.position.z = (SOUTH_Z + NORTH_Z) * 0.5
	mesh.material_override = _floor_material(Color(0.24, 0.25, 0.27), 0.6, 0.6)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(OUTER_X * 2.0 + 8.0, 0.4, SOUTH_Z - NORTH_Z + 8.0)
	shape.shape = box
	shape.position = Vector3(0, -0.2, (SOUTH_Z + NORTH_Z) * 0.5)
	body.add_child(mesh)
	body.add_child(shape)
	add_child(body)


func _wall_material(color: Color) -> ShaderMaterial:
	var key := color.to_html()
	if _wall_mats.has(key):
		return _wall_mats[key]
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/wall.gdshader")
	mat.set_shader_parameter("tint", color.lightened(0.28))
	mat.set_shader_parameter("trim", Color(0.07, 0.12, 0.24).lerp(color, 0.25))
	mat.set_shader_parameter("plaster", Surfaces.tex("Plaster001", "Color"))
	mat.set_shader_parameter("plaster_normal", Surfaces.tex("Plaster001", "NormalGL"))
	mat.set_shader_parameter("plaster_rough", Surfaces.tex("Plaster001", "Roughness"))
	_wall_mats[key] = mat
	return mat


func _floor_material(color: Color, tile: float, gloss: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/floor.gdshader")
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("tile", tile)
	mat.set_shader_parameter("gloss", gloss)
	mat.set_shader_parameter("grain_normal", Surfaces.tex("Plaster001", "NormalGL"))
	return mat


func _leaf_material(color: Color, lumps := 0.16) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/plush.gdshader")
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("fuzz", 0.7)
	mat.set_shader_parameter("softness", 0.3)
	mat.set_shader_parameter("gloss", 0.05)
	mat.set_shader_parameter("puff", 0.0)
	mat.set_shader_parameter("brightness", 1.1)
	mat.set_shader_parameter("grime", 0.6)
	mat.set_shader_parameter("lumps", lumps)
	mat.set_shader_parameter("lump_scale", 3.2)
	return mat


func _add_ceiling() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(OUTER_X * 2.0 + 0.4, SOUTH_Z - NORTH_Z + 0.4)
	mesh.mesh = plane
	mesh.position = Vector3(0, 3.14, (SOUTH_Z + NORTH_Z) * 0.5)
	mesh.rotation.x = PI
	var tile := 2.4
	mesh.material_override = Surfaces.tiled("OfficeCeiling001", Color(0.42, 0.43, 0.45), plane.size / tile, 0.0, 1.0, 0.8)
	add_child(mesh)
	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(plane.size.x, 0.1, plane.size.y)
	slab.mesh = box
	slab.position = Vector3(0, 3.2, mesh.position.z)
	slab.material_override = Surfaces.flat(Color(0.05, 0.05, 0.06), 1.0)
	add_child(slab)


func _add_school_walls() -> void:
	var outer := Color(0.16, 0.18, 0.22)
	var length := SOUTH_Z - NORTH_Z
	var mid_z := (SOUTH_Z + NORTH_Z) * 0.5
	var side_piece := OUTER_X - 1.3
	_wall(Vector3(OUTER_X * 2.0 + 0.4, 3.2, 0.4), Vector3(0, 1.6, NORTH_Z), outer)
	_wall(Vector3(side_piece, 3.2, 0.4), Vector3(-(1.3 + side_piece * 0.5), 1.6, SOUTH_Z), outer)
	_wall(Vector3(side_piece, 3.2, 0.4), Vector3(1.3 + side_piece * 0.5, 1.6, SOUTH_Z), outer)
	_wall(Vector3(2.6, 0.7, 0.4), Vector3(0, 2.85, SOUTH_Z), outer)
	_wall(Vector3(0.4, 3.2, length + 0.4), Vector3(-OUTER_X, 1.6, mid_z), outer)
	_wall(Vector3(0.4, 3.2, length + 0.4), Vector3(OUTER_X, 1.6, mid_z), outer)
	var inner := Color(0.2, 0.22, 0.26)
	for c: float in BLOCKS:
		for x in [-2.2, 2.2]:
			_wall(Vector3(0.35, 3.0, 2.8), Vector3(x, 1.5, c - 10.6), inner)
			_wall(Vector3(0.35, 3.0, 4.8), Vector3(x, 1.5, c - 4.4), inner)
			_wall(Vector3(0.35, 3.0, 2.8), Vector3(x, 1.5, c + 3.4), inner)
			_wall(Vector3(0.35, 3.0, 4.8), Vector3(x, 1.5, c + 9.6), inner)
		for sx in [-1.0, 1.0]:
			for sz in [-2.2, 2.2]:
				_wall(Vector3(7.5, 3.0, 0.35), Vector3(sx * 6.05, 1.5, c + sz), inner)
				_wall(Vector3(3.8, 3.0, 0.35), Vector3(sx * 14.1, 1.5, c + sz), inner)
			_wall(Vector3(0.35, 3.0, 10.2), Vector3(sx * INNER_X, 1.5, c + 7.1), inner)
			_wall(Vector3(0.35, 3.0, 10.2), Vector3(sx * INNER_X, 1.5, c - 7.1), inner)
			if c - 12.2 > NORTH_Z + 0.5:
				_wall(Vector3(14.0, 3.0, 0.35), Vector3(sx * 9.2, 1.5, c - 12.2), inner)


func _wall(size: Vector3, pos: Vector3, color: Color, surface: Material = null) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = surface if surface else _wall_material(color)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	body.add_child(mesh)
	body.add_child(shape)
	add_child(body)


func _add_outside() -> void:
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(40, 0.4, 16)
	ground_shape.shape = ground_box
	ground_shape.position = Vector3(0, -0.2, 20.0)
	ground.add_child(ground_shape)
	add_child(ground)
	_floor_patch(Vector3(0, 0.0, 19.0), Vector2(OUTER_X * 2.0 + 2.0, 13.2), Color(0.06, 0.11, 0.06), 0.0, 0.0)
	_floor_patch(Vector3(0, 0.012, 18.5), Vector2(3.0, 12.0), Color(0.32, 0.31, 0.3), 0.75, 0.15)
	_floor_patch(Vector3(0, 0.014, 13.9), Vector2(9.0, 2.8), Color(0.36, 0.35, 0.34), 0.9, 0.2)

	var facade := Color(0.46, 0.46, 0.48)
	var piece := OUTER_X + 0.2 - 1.3
	var facade_skin := _wall_material(facade)
	_box(self, Vector3(piece, 4.4, 0.1), Vector3(-(1.3 + piece * 0.5), 2.2, 12.45), facade, false, facade_skin)
	_box(self, Vector3(piece, 4.4, 0.1), Vector3(1.3 + piece * 0.5, 2.2, 12.45), facade, false, facade_skin)
	_box(self, Vector3(2.6, 1.9, 0.1), Vector3(0, 3.45, 12.45), facade, false, facade_skin)
	_wall(Vector3(OUTER_X * 2.0 + 0.4, 1.2, 0.5), Vector3(0, 3.8, 12.2), facade.darkened(0.2))
	var frame := Color(0.12, 0.13, 0.15)
	_box(self, Vector3(0.14, 2.5, 0.2), Vector3(-1.37, 1.25, 12.5), frame)
	_box(self, Vector3(0.14, 2.5, 0.2), Vector3(1.37, 1.25, 12.5), frame)
	_box(self, Vector3(2.88, 0.14, 0.2), Vector3(0, 2.5, 12.5), frame)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.05, 0.08, 0.14)
	glass.metallic = 0.6
	glass.roughness = 0.12
	for x in [-17.5, -14.0, -10.5, -7.0, -3.6, 3.6, 7.0, 10.5, 14.0, 17.5]:
		var pane := MeshInstance3D.new()
		var pane_box := BoxMesh.new()
		pane_box.size = Vector3(1.8, 1.1, 0.04)
		pane.mesh = pane_box
		pane.position = Vector3(x, 1.75, 12.52)
		pane.material_override = glass
		add_child(pane)
		_box(self, Vector3(1.95, 0.08, 0.12), Vector3(x, 1.18, 12.54), frame)

	_box(self, Vector3(4.2, 0.14, 1.8), Vector3(0, 2.7, 13.35), facade.darkened(0.1))
	_lamp(Vector3(0, 2.45, 13.4), Color(1.0, 0.85, 0.6), 0.8, 5.0)
	var board := MeshInstance3D.new()
	var board_box := BoxMesh.new()
	board_box.size = Vector3(3.6, 0.9, 0.06)
	board.mesh = board_box
	board.position = Vector3(0, 3.35, 12.54)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.92, 0.92, 0.9)
	board_mat.emission_enabled = true
	board_mat.emission = Color(0.85, 0.87, 0.9)
	board_mat.emission_energy_multiplier = 0.35
	board.material_override = board_mat
	add_child(board)
	var logo := Sprite3D.new()
	logo.texture = load("res://assets/unifacef_logo.png")
	logo.pixel_size = 3.3 / 860.0
	logo.position = Vector3(0, 3.35, 12.58)
	logo.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(logo)

	for x in [-2.6, 2.6]:
		_street_lamp(Vector3(x, 0, 18.0))
	for spot in [Vector3(-7.0, 0, 16.5), Vector3(7.5, 0, 17.0), Vector3(-10.5, 0, 21.0), Vector3(10.0, 0, 21.5)]:
		_tree(spot)

	var hedge := Color(0.05, 0.13, 0.06)
	_wall(Vector3(0.9, 1.3, 11.6), Vector3(-13.7, 0.65, 18.4), hedge, _leaf_material(hedge, 0.0))
	_wall(Vector3(0.9, 1.3, 11.6), Vector3(13.7, 0.65, 18.4), hedge, _leaf_material(hedge, 0.0))
	_wall(Vector3(11.4, 1.3, 0.9), Vector3(-8.0, 0.65, 24.1), hedge, _leaf_material(hedge, 0.0))
	_wall(Vector3(11.4, 1.3, 0.9), Vector3(8.0, 0.65, 24.1), hedge, _leaf_material(hedge, 0.0))
	var gate := Node3D.new()
	gate.position = Vector3(0, 0, 24.1)
	add_child(gate)
	var iron := Color(0.06, 0.06, 0.07)
	for i in 15:
		_box(gate, Vector3(0.05, 2.0, 0.05), Vector3(-2.3 + float(i) * 0.33, 1.0, 0), iron)
	_box(gate, Vector3(4.7, 0.08, 0.08), Vector3(0, 1.9, 0), iron)
	_box(gate, Vector3(4.7, 0.08, 0.08), Vector3(0, 0.25, 0), iron)
	var bars := StaticBody3D.new()
	bars.position = Vector3(0, 1.0, 24.1)
	var bars_shape := CollisionShape3D.new()
	var bars_box := BoxShape3D.new()
	bars_box.size = Vector3(4.7, 2.0, 0.3)
	bars_shape.shape = bars_box
	bars.add_child(bars_shape)
	add_child(bars)
	_sign("PORTÃO FECHADO", Vector3(0, 1.45, 23.96), PI, 1.2)
	_lamp(Vector3(-1.2, 2.7, 9.6), Color(1.0, 0.8, 0.55), 0.55, 4.0)
	_sign("ACHADOS E PERDIDOS", Vector3(-2.0, 2.92, 9.6), PI / 2.0, 1.4)


func _street_lamp(pos: Vector3) -> void:
	var metal := Color(0.1, 0.11, 0.12)
	var post := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.06
	tube.bottom_radius = 0.09
	tube.height = 3.6
	post.mesh = tube
	post.position = pos + Vector3(0, 1.8, 0)
	post.material_override = _flat(metal)
	add_child(post)
	_box(self, Vector3(0.5, 0.12, 0.3), pos + Vector3(0, 3.62, 0), metal)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 3.45, 0)
	light.light_color = Color(1.0, 0.78, 0.5)
	light.light_energy = 1.5
	light.omni_range = 9.0
	add_child(light)
	var bulb := MeshInstance3D.new()
	var bulb_box := BoxMesh.new()
	bulb_box.size = Vector3(0.42, 0.04, 0.24)
	bulb.mesh = bulb_box
	bulb.position = pos + Vector3(0, 3.55, 0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.85, 0.6)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.8, 0.5)
	glow.emission_energy_multiplier = 2.0
	bulb.material_override = glow
	add_child(bulb)


func _tree(pos: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rng.randf() * TAU
	add_child(body)
	var bark := Surfaces.pbr("Bark007", Color(0.42, 0.33, 0.25), 1.6, 0.0, 1.0, 1.4)
	var height := rng.randf_range(2.9, 3.5)
	var lean := Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12))
	var top := Vector3(lean.x, height, lean.z)
	_limb(body, Vector3.ZERO, top * 0.55, 0.22, 0.17, bark)
	_limb(body, top * 0.55, top, 0.17, 0.1, bark)
	for i in 5:
		var ang := TAU * float(i) / 5.0 + rng.randf() * 0.7
		var root_end := Vector3(cos(ang) * 0.48, -0.02, sin(ang) * 0.48)
		_limb(body, Vector3(cos(ang) * 0.06, 0.32, sin(ang) * 0.06), root_end, 0.08, 0.02, bark)
	var clusters: Array[Vector3] = []
	for i in 6:
		var ang := TAU * float(i) / 6.0 + rng.randf_range(-0.35, 0.35)
		var tilt := rng.randf_range(0.6, 1.0)
		var dir := Vector3(cos(ang) * sin(tilt), cos(tilt), sin(ang) * sin(tilt))
		var base := top * rng.randf_range(0.62, 0.92)
		var length := rng.randf_range(1.1, 1.6)
		var tip := base + dir * length
		_limb(body, base, tip, 0.065, 0.025, bark)
		for k in 2:
			var twist := ang + (float(k) - 0.5) * rng.randf_range(0.8, 1.3)
			var twig_dir := (dir + Vector3(cos(twist), 0.5, sin(twist)) * 0.7).normalized()
			var from := base + dir * length * rng.randf_range(0.5, 0.8)
			var twig_tip := from + twig_dir * rng.randf_range(0.5, 0.8)
			_limb(body, from, twig_tip, 0.03, 0.01, bark)
			clusters.append(twig_tip)
		clusters.append(tip)
	clusters.append(top + Vector3(0, 0.5, 0))
	clusters.append(top + Vector3(rng.randf_range(-0.4, 0.4), 0.1, rng.randf_range(-0.4, 0.4)))
	var tints: Array[Color] = [Color(0.62, 0.7, 0.5), Color(0.5, 0.62, 0.42), Color(0.7, 0.74, 0.52)]
	var leaves := _leaf_card_material(tints[rng.randi() % tints.size()])
	for spot in clusters:
		var size := rng.randf_range(1.3, 1.9)
		var quad := QuadMesh.new()
		quad.size = Vector2(size, size)
		for c in 4:
			var at := spot + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.1, 0.15), rng.randf_range(-0.2, 0.2))
			var turn := Vector3(rng.randf_range(-0.45, 0.45), float(c) * PI / 4.0 + rng.randf() * 0.5, rng.randf() * TAU)
			_prop(body, quad, Transform3D(Basis.from_euler(turn), at), leaves)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.25
	cylinder.height = height
	shape.shape = cylinder
	shape.position.y = height * 0.5
	body.add_child(shape)


func _limb(parent: Node3D, from: Vector3, to: Vector3, r0: float, r1: float, surface: Material) -> void:
	var span := to - from
	var length := span.length()
	if length < 0.01:
		return
	var tube := CylinderMesh.new()
	tube.bottom_radius = r0
	tube.top_radius = r1
	tube.height = length
	tube.radial_segments = 10 if r0 > 0.05 else 6
	tube.rings = 1
	var up := span / length
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	_prop(parent, tube, Transform3D(Basis(side, up, side.cross(up)), from + span * 0.5), surface)


func _prop(parent: Node3D, mesh: Mesh, local: Transform3D, surface: Material) -> void:
	_props.add(self, mesh, global_transform.affine_inverse() * parent.global_transform * local, surface)


func _leaf_card_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/LeafSet009/LeafSet009_Card.png")
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.45
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.85
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.backlight_enabled = true
	mat.backlight = Color(0.18, 0.24, 0.1)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


func _add_hanging_costume() -> void:
	var rack := Color(0.3, 0.2, 0.12)
	_box(self, Vector3(0.06, 0.14, 1.3), Vector3(-1.99, 2.55, 9.6), rack)
	_box(self, Vector3(0.12, 0.04, 0.04), Vector3(-1.92, 2.55, 9.6), rack)
	_hang_pivot = Node3D.new()
	_hang_pivot.name = "Cabide"
	_hang_pivot.position = HANG_PEG
	add_child(_hang_pivot)
	var wood := Color(0.36, 0.24, 0.13)
	_box(_hang_pivot, Vector3(0.05, 0.04, 1.0), Vector3(0.36, -0.36, 0), wood)
	var rope := MeshInstance3D.new()
	var cord := CylinderMesh.new()
	cord.top_radius = 0.008
	cord.bottom_radius = 0.008
	cord.height = 0.51
	rope.mesh = cord
	rope.position = Vector3(0.18, -0.18, 0)
	rope.rotation.z = PI / 4.0
	rope.material_override = _flat(Color(0.5, 0.45, 0.35))
	_hang_pivot.add_child(rope)
	_hang_costume = Node3D.new()
	_hang_costume.set_script(load("res://scripts/costume.gd"))
	_hang_costume.name = "FantasiaPendurada"
	_hang_costume.position = Vector3(0.36, -2.38, 0)
	_hang_costume.rotation.y = PI / 2.0
	_hang_pivot.add_child(_hang_costume)
	_hang_costume.pose_hanging()


func _add_room_floors() -> void:
	var palettes := [
		[Color(0.16, 0.2, 0.18), Color(0.24, 0.22, 0.18), Color(0.18, 0.2, 0.24), Color(0.22, 0.18, 0.16)],
		[Color(0.2, 0.12, 0.12), Color(0.26, 0.25, 0.22), Color(0.17, 0.19, 0.22), Color(0.17, 0.19, 0.22)],
		[Color(0.2, 0.19, 0.15), Color(0.14, 0.1, 0.09), Color(0.18, 0.21, 0.2), Color(0.18, 0.21, 0.2)],
	]
	for b in BLOCKS.size():
		var c := BLOCKS[b]
		var colors: Array = palettes[b]
		_floor_patch(Vector3(-9.0, 0.02, c - 7.1), Vector2(13.4, 9.4), colors[0])
		_floor_patch(Vector3(9.0, 0.02, c - 7.1), Vector2(13.4, 9.4), colors[1])
		_floor_patch(Vector3(-9.0, 0.02, c + 7.1), Vector2(13.4, 9.4), colors[2])
		_floor_patch(Vector3(9.0, 0.02, c + 7.1), Vector2(13.4, 9.4), colors[3])


func _floor_patch(pos: Vector3, size: Vector2, color: Color, tile := 0.5, gloss := 0.3) -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mesh.mesh = plane
	mesh.position = pos
	mesh.material_override = _floor_material(color, tile, gloss)
	add_child(mesh)


func _add_signs() -> void:
	var rooms := [
		["BIBLIOTECA", "SECRETARIA", "SALA DE AULA", "COORDENAÇÃO", "NÚCLEO DE ESTÁGIOS", "LABORATÓRIO"],
		["AUDITÓRIO", "CANTINA", "SALA 12", "SALA 14", "SALA DOS PROFESSORES", "LAB. DE INFORMÁTICA"],
		["ARQUIVO", "REITORIA", "SALA 21", "SALA 23", "CENTRO ACADÊMICO", "ALMOXARIFADO"],
	]
	for b in BLOCKS.size():
		var c := BLOCKS[b]
		var names: Array = rooms[b]
		_sign(names[0], Vector3(-1.95, 2.05, c - 8), PI / 2.0, 1.5)
		_sign(names[1], Vector3(1.95, 2.05, c - 8), -PI / 2.0, 1.5)
		_sign(names[2], Vector3(-1.95, 2.05, c + 6), PI / 2.0, 1.5)
		_sign(names[3], Vector3(1.95, 2.05, c + 6), -PI / 2.0, 1.5)
		_sign(names[4], Vector3(-OUTER_X + 0.25, 2.05, c), PI / 2.0, 1.7)
		_sign(names[5], Vector3(OUTER_X - 0.25, 2.05, c), -PI / 2.0, 1.7)
		_sign(names[0], Vector3(-11.0, 2.45, c - 2.0), 0.0, 1.3)
		_sign(names[1], Vector3(11.0, 2.45, c - 2.0), 0.0, 1.3)
		_sign(names[2], Vector3(-11.0, 2.45, c + 2.0), PI, 1.3)
		_sign(names[3], Vector3(11.0, 2.45, c + 2.0), PI, 1.3)
		_sign(BLOCK_NAMES[b], Vector3(1.95, 2.3, c + 10.6), -PI / 2.0, 1.1)
		_sign(BLOCK_NAMES[b], Vector3(-1.95, 2.3, c - 11.0), PI / 2.0, 1.1)
		for sx in [-1.0, 1.0]:
			_sign(BLOCK_NAMES[b], Vector3(sx * (INNER_X + 0.2), 2.3, c + 3.2), sx * PI / 2.0, 1.0)


func _sign(text: String, pos: Vector3, rot_y: float, max_width: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 32
	label.pixel_size = _fit_pixel_size(text, 32, max_width, 0.12)
	label.position = pos
	label.rotation.y = rot_y
	label.modulate = Color(0.92, 0.94, 0.98)
	label.outline_size = 2
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


func _fit_pixel_size(text: String, font_size: int, max_width: float, max_height: float) -> float:
	var measured := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var width := maxf(measured.x, 1.0)
	return minf(max_width / width, max_height / float(font_size))


func _add_furniture() -> void:
	var oak := Color(0.34, 0.24, 0.15)
	var dark_wood := Color(0.24, 0.16, 0.1)
	var seat := Color(0.34, 0.1, 0.1)
	for x in [-14.0, -11.0, -8.0, -5.0]:
		_shelf(Vector3(x, 0.9, -10.7), Vector3(0.7, 1.8, 2.2), dark_wood)
	for i in 3:
		_desk(Vector3(-12.5 + float(i) * 2.2, 0.38, 6.5), Vector3(1.2, 0.75, 0.7), oak)
		_desk(Vector3(-12.5 + float(i) * 2.2, 0.38, 9.2), Vector3(1.2, 0.75, 0.7), oak)
	_long_table(Vector3(10.5, 0.52, -11.0), Vector3(3.2, 1.05, 0.6), oak)
	_desk(Vector3(12.5, 0.39, 9.5), Vector3(1.6, 0.78, 0.8), Color(0.36, 0.22, 0.13))
	_board(Vector3(-10.3, 1.6, 11.9), Vector3(3.0, 1.0, 0.1))

	var b := BLOCKS[1]
	for row in 4:
		var rz := b - 5.0 - float(row) * 1.4
		_bench(Vector3(-13.3, 0.28, rz), Vector3(1.8, 0.55, 0.5), seat)
		_bench(Vector3(-7.3, 0.28, rz), Vector3(4.6, 0.55, 0.5), seat)
	_plinth(Vector3(-9.0, 0.2, b - 11.2), Vector3(8.0, 0.4, 1.4), Color(0.22, 0.15, 0.09))
	for tx in [5.5, 8.0, 14.0]:
		for tz in [b - 5.0, b - 9.5]:
			_desk(Vector3(tx, 0.38, tz), Vector3(1.4, 0.75, 0.9), oak)
	_long_table(Vector3(10.5, 0.52, b - 11.3), Vector3(4.5, 1.05, 0.6), Color(0.62, 0.63, 0.64))

	for c: float in [BLOCKS[1], BLOCKS[2]]:
		for sx in [-1.0, 1.0]:
			for i in 3:
				var dx: float = sx * (8.1 + float(i) * 2.2)
				_desk(Vector3(dx, 0.38, c + 6.5), Vector3(1.2, 0.75, 0.7), oak)
				_desk(Vector3(dx, 0.38, c + 9.2), Vector3(1.2, 0.75, 0.7), oak)
			_board(Vector3(sx * 10.3, 1.6, c + 11.9), Vector3(3.0, 1.0, 0.1))

	var a := BLOCKS[2]
	for sz in [a - 5.0, a - 10.8]:
		_cabinet(Vector3(-13.6, 1.0, sz), Vector3(3.0, 2.0, 0.6), Color(0.34, 0.36, 0.38))
		_cabinet(Vector3(-6.6, 1.0, sz), Vector3(3.0, 2.0, 0.6), Color(0.34, 0.36, 0.38))
	_long_table(Vector3(10.5, 0.4, a - 8.5), Vector3(2.8, 0.8, 1.2), Color(0.4, 0.28, 0.16))
	for cx in [9.6, 11.4]:
		_chair(Vector3(cx, 0.45, a - 10.0), Vector3(0.7, 0.9, 0.7), Color(0.16, 0.08, 0.06))

	for c: float in BLOCKS:
		for sx in [-1.0, 1.0]:
			for sz in [-7.0, 7.0]:
				_closed_lockers(Vector3(sx * (OUTER_X - 0.45), 0.95, c + sz), Vector3(0.5, 1.9, 5.0), sx)
	_add_lockers()


func _furn_body(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	body.add_child(shape)
	add_child(body)
	return body


func _chip(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rough := 0.86, metal := 0.0, surface: Material = null) -> void:
	var mat := surface if surface else Surfaces.flat(color, rough, metal)
	var xform := global_transform.affine_inverse() * parent.global_transform * Transform3D(Basis.IDENTITY, pos)
	_props.box(self, size, xform, mat)


func _skin(parent: Node3D, size: Vector3, pos: Vector3, surface: Material) -> void:
	_chip(parent, size, pos, Color.WHITE, 0.8, 0.0, surface)


func _wood(color: Color, set_name := "Wood049") -> Material:
	var gain := 2.1 if set_name == "Wood049" else 2.6
	var tint := Color(minf(color.r * gain, 1.0), minf(color.g * gain, 1.0), minf(color.b * gain, 1.0))
	return Surfaces.pbr(set_name, tint, 1.1, 0.0, 0.8, 0.7)


func _desk(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	var top_h := 0.04
	var top_y := size.y * 0.5 - top_h * 0.5
	_skin(body, Vector3(size.x - 0.02, top_h, size.z - 0.02), Vector3(0.0, top_y, 0.0), _wood(color.lightened(0.08)))
	var band := Color(0.08, 0.07, 0.06)
	_chip(body, Vector3(size.x, top_h * 0.8, 0.012), Vector3(0.0, top_y, size.z * 0.5 - 0.004), band, 0.5)
	_chip(body, Vector3(size.x, top_h * 0.8, 0.012), Vector3(0.0, top_y, -size.z * 0.5 + 0.004), band, 0.5)
	_chip(body, Vector3(0.012, top_h * 0.8, size.z), Vector3(size.x * 0.5 - 0.004, top_y, 0.0), band, 0.5)
	_chip(body, Vector3(0.012, top_h * 0.8, size.z), Vector3(-size.x * 0.5 + 0.004, top_y, 0.0), band, 0.5)
	var frame := Surfaces.pbr("PaintedMetal004", Color(0.12, 0.13, 0.14), 1.6, 0.35, 0.8)
	var rail_y := top_y - top_h * 0.5 - 0.02
	_skin(body, Vector3(size.x - 0.12, 0.035, 0.025), Vector3(0.0, rail_y, size.z * 0.5 - 0.06), frame)
	_skin(body, Vector3(size.x - 0.12, 0.035, 0.025), Vector3(0.0, rail_y, -size.z * 0.5 + 0.06), frame)
	_chip(body, Vector3(size.x - 0.16, 0.012, size.z - 0.16), Vector3(0.0, rail_y - 0.09, 0.0), Color(0.1, 0.1, 0.11), 0.6, 0.4)
	var leg_h := size.y - top_h
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var foot := Vector3(sx * (size.x * 0.5 - 0.07), -top_h * 0.5, sz * (size.z * 0.5 - 0.06))
			_skin(body, Vector3(0.035, leg_h, 0.035), foot, frame)
			_chip(body, Vector3(0.045, 0.02, 0.045), Vector3(foot.x, -size.y * 0.5 + 0.01, foot.z), Color(0.04, 0.04, 0.04), 0.9)
		_skin(body, Vector3(0.025, 0.025, size.z - 0.12), Vector3(sx * (size.x * 0.5 - 0.07), -size.y * 0.3, 0.0), frame)


func _shelf(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	var side := _wood(color, "Wood066")
	var board := _wood(color.lightened(0.06), "Wood066")
	_skin(body, Vector3(size.x, size.y, 0.06), Vector3(0.0, 0.0, -size.z * 0.5 + 0.03), side)
	_skin(body, Vector3(size.x, size.y, 0.06), Vector3(0.0, 0.0, size.z * 0.5 - 0.03), side)
	_skin(body, Vector3(0.03, size.y - 0.04, size.z - 0.1), Vector3(-size.x * 0.5 + 0.015, 0.0, 0.0), board)
	_skin(body, Vector3(size.x * 0.92, 0.05, size.z), Vector3(0.04, -size.y * 0.5 + 0.04, 0.0), side)
	_skin(body, Vector3(size.x + 0.03, 0.05, size.z + 0.04), Vector3(0.015, size.y * 0.5 - 0.025, 0.0), side)
	_chip(body, Vector3(0.02, 0.08, size.z - 0.12), Vector3(size.x * 0.5 - 0.01, -size.y * 0.5 + 0.08, 0.0), color.darkened(0.4), 0.8)
	var covers: Array[Color] = [
		Color(0.08, 0.13, 0.28), Color(0.42, 0.1, 0.12), Color(0.12, 0.26, 0.16),
		Color(0.28, 0.18, 0.1), Color(0.55, 0.48, 0.32), Color(0.1, 0.16, 0.24),
		Color(0.22, 0.1, 0.16), Color(0.16, 0.2, 0.22), Color(0.36, 0.14, 0.08),
	]
	for shelf_i in 3:
		var y := -size.y * 0.28 + float(shelf_i) * size.y * 0.26
		_skin(body, Vector3(size.x * 0.9, 0.035, size.z - 0.12), Vector3(0.04, y, 0.0), board)
		var cursor := -size.z * 0.42
		var limit := size.z * 0.4
		if shelf_i > 0:
			limit -= 0.38
		var n := 0
		while cursor < limit and n < 40:
			var thick := 0.03 + float((n * 5 + shelf_i * 3) % 7) * 0.008
			var tall := 0.2 + float((n * 3 + shelf_i) % 5) * 0.03
			var lean := deg_to_rad(float((n % 5) - 2) * 2.1)
			var pull := 0.035 if n % 6 == 3 else 0.0
			var deep := size.x * 0.5 + float((n + shelf_i) % 3) * 0.025
			_book(body, Vector3(0.03 + pull, y + 0.02 + tall * 0.5, cursor + thick * 0.5), tall, thick, deep, covers[(n + shelf_i * 2) % covers.size()], lean, n + shelf_i * 4)
			cursor += thick + 0.006
			n += 1
		if shelf_i > 0:
			_book_stack(body, Vector3(0.04, y + 0.02, limit + 0.2), covers[shelf_i * 3])


func _bench(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	var seats := maxi(2, int(size.x / 0.55))
	var seat_w := size.x / float(seats)
	var frame := Surfaces.pbr("PaintedMetal004", Color(0.1, 0.1, 0.11), 1.6, 0.35, 0.8)
	_skin(body, Vector3(size.x, 0.03, 0.05), Vector3(0.0, size.y * 0.5 - 0.11, 0.0), frame)
	for i in seats:
		var x := -size.x * 0.5 + seat_w * (float(i) + 0.5)
		_chip(body, Vector3(seat_w - 0.05, 0.07, size.z - 0.04), Vector3(x, size.y * 0.5 - 0.06, -0.02), color.lightened(0.05), 0.95)
		_chip(body, Vector3(seat_w - 0.05, 0.3, 0.06), Vector3(x, 0.05, size.z * 0.5 - 0.06), color.darkened(0.1), 0.95)
		_chip(body, Vector3(seat_w - 0.09, 0.004, size.z - 0.12), Vector3(x, size.y * 0.5 - 0.024, -0.02), color.darkened(0.25), 0.95)
	for i in seats + 1:
		var x := -size.x * 0.5 + seat_w * float(i)
		x = clampf(x, -size.x * 0.5 + 0.02, size.x * 0.5 - 0.02)
		_skin(body, Vector3(0.04, size.y - 0.08, 0.04), Vector3(x, -0.04, size.z * 0.5 - 0.1), frame)
		_skin(body, Vector3(0.03, 0.12, 0.03), Vector3(x, size.y * 0.5 - 0.14, -0.12), frame)


func _long_table(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	var along_x := size.x >= size.z
	var length := size.x if along_x else size.z
	var depth := size.z if along_x else size.x
	var top_h := 0.055
	var top_y := size.y * 0.5 - top_h * 0.5
	var top := Vector3(size.x + 0.06, top_h, size.z + 0.06)
	_skin(body, top, Vector3(0.0, top_y, 0.0), _wood(color.lightened(0.1)))
	var apron_y := top_y - top_h * 0.5 - 0.035
	if along_x:
		_chip(body, Vector3(size.x - 0.08, 0.06, 0.04), Vector3(0.0, apron_y, depth * 0.5 - 0.04), color.darkened(0.18), 0.7)
		_chip(body, Vector3(size.x - 0.08, 0.06, 0.04), Vector3(0.0, apron_y, -depth * 0.5 + 0.04), color.darkened(0.18), 0.7)
	else:
		_chip(body, Vector3(0.04, 0.06, size.z - 0.08), Vector3(depth * 0.5 - 0.04, apron_y, 0.0), color.darkened(0.18), 0.7)
		_chip(body, Vector3(0.04, 0.06, size.z - 0.08), Vector3(-depth * 0.5 + 0.04, apron_y, 0.0), color.darkened(0.18), 0.7)
	var seam := Vector3(0.012, 0.004, size.z * 0.72) if along_x else Vector3(size.x * 0.72, 0.004, 0.012)
	_chip(body, seam, Vector3(0.0, top_y + top_h * 0.5 + 0.001, 0.0), color.darkened(0.22), 0.6)
	var pairs := maxi(2, int(length / 1.4))
	var leg_h := size.y - top_h
	var leg_c := color.darkened(0.38)
	for i in pairs:
		var along := lerpf(-length * 0.5 + 0.14, length * 0.5 - 0.14, (float(i) + 0.5) / float(pairs))
		for s in [-1.0, 1.0]:
			var across := float(s) * (depth * 0.5 - 0.08)
			var leg_at := Vector3(along, -top_h * 0.5, across) if along_x else Vector3(across, -top_h * 0.5, along)
			_chip(body, Vector3(0.05, leg_h, 0.05), leg_at, leg_c, 0.7)
			var shoe := Vector3(along, -size.y * 0.5 + 0.015, across) if along_x else Vector3(across, -size.y * 0.5 + 0.015, along)
			_chip(body, Vector3(0.09, 0.028, 0.09), shoe, leg_c.darkened(0.1), 0.65)
		var brace := Vector3(along, -size.y * 0.18, 0.0) if along_x else Vector3(0.0, -size.y * 0.18, along)
		var bar := Vector3(0.03, 0.03, depth - 0.22) if along_x else Vector3(depth - 0.22, 0.03, 0.03)
		_chip(body, bar, brace, leg_c, 0.75)
	if depth > 0.9:
		var surface := top_y + top_h * 0.5
		_book_stack(body, Vector3(-0.42, surface, 0.12), Color(0.1, 0.16, 0.3))
		_open_book(body, Vector3(0.38, surface + 0.006, -0.05), Color(0.32, 0.12, 0.1))


func _board(pos: Vector3, size: Vector3) -> void:
	var body := _furn_body(size, pos)
	var metal := Surfaces.pbr("Metal009", Color(0.7, 0.72, 0.74), 2.5, 0.6, 0.7, 0.5)
	_skin(body, size, Vector3.ZERO, metal)
	var face := -size.z * 0.5 - 0.012
	_skin(body, Vector3(size.x + 0.03, 0.05, 0.028), Vector3(0.0, size.y * 0.5, face), metal)
	_skin(body, Vector3(size.x + 0.03, 0.05, 0.028), Vector3(0.0, -size.y * 0.5 + 0.08, face), metal)
	_skin(body, Vector3(0.045, size.y, 0.028), Vector3(-size.x * 0.5, 0.0, face), metal)
	_skin(body, Vector3(0.045, size.y, 0.028), Vector3(size.x * 0.5, 0.0, face), metal)
	var opening := Vector3(size.x - 0.12, size.y - 0.2, 0.01)
	_chip(body, opening, Vector3(0.0, 0.03, face - 0.012), Color(0.02, 0.05, 0.03), 0.8)
	var board_z := face - 0.02
	_skin(body, Vector3(opening.x - 0.02, opening.y - 0.02, 0.008), Vector3(0.0, 0.03, board_z), _chalk_surface())
	var chalk := Color(0.9, 0.9, 0.84)
	var rows: Array = [
		[-1.15, 0.24, [0.36, 0.2, 0.44, 0.16, 0.3]],
		[-1.12, 0.08, [0.24, 0.5, 0.18, 0.34]],
		[-1.15, -0.08, [0.42, 0.16, 0.28, 0.22, 0.2]],
		[-0.9, -0.24, [0.28, 0.18, 0.34]],
	]
	for row in rows:
		var x: float = row[0]
		var y: float = row[1]
		var words: Array = row[2]
		var word_i := 0
		for w in words:
			var width := float(w)
			_chip(body, Vector3(width, 0.009, 0.003), Vector3(x + width * 0.5, y, board_z - 0.006), chalk, 0.9)
			var stems := 2 + word_i % 3
			for s in stems:
				var sx := x + width * (0.18 + float(s) * 0.24)
				var sh := 0.02 + float((s + word_i) % 3) * 0.008
				_chip(body, Vector3(0.007, sh, 0.003), Vector3(sx, y + sh * 0.42, board_z - 0.007), chalk, 0.9)
			x += width + 0.075
			word_i += 1
	var chart_x := 1.02
	var chart_y := -0.2
	_chip(body, Vector3(0.52, 0.006, 0.003), Vector3(chart_x, chart_y, board_z - 0.006), chalk, 0.96)
	_chip(body, Vector3(0.006, 0.4, 0.003), Vector3(chart_x - 0.24, chart_y + 0.2, board_z - 0.006), chalk, 0.96)
	var bars: Array[float] = [0.08, 0.15, 0.11, 0.24, 0.18]
	for i in bars.size():
		var h: float = bars[i]
		_chip(body, Vector3(0.05, h, 0.003), Vector3(chart_x - 0.16 + float(i) * 0.09, chart_y + h * 0.5, board_z - 0.007), chalk, 0.96)
	var tray_y := -size.y * 0.5 + 0.03
	var tray_z := face - 0.04
	_chip(body, Vector3(size.x - 0.2, 0.03, 0.07), Vector3(0.0, tray_y, tray_z), Color(0.24, 0.15, 0.08), 0.78)
	_chip(body, Vector3(size.x - 0.22, 0.02, 0.012), Vector3(0.0, tray_y + 0.018, tray_z - 0.03), Color(0.18, 0.11, 0.06), 0.8)
	_chip(body, Vector3(0.07, 0.016, 0.016), Vector3(-0.85, tray_y + 0.03, tray_z), chalk, 0.55)
	_chip(body, Vector3(0.045, 0.014, 0.014), Vector3(-0.74, tray_y + 0.028, tray_z + 0.01), Color(0.92, 0.82, 0.35), 0.55)
	_chip(body, Vector3(0.1, 0.026, 0.04), Vector3(0.9, tray_y + 0.032, tray_z), Color(0.1, 0.1, 0.1), 0.9)
	_chip(body, Vector3(0.1, 0.008, 0.042), Vector3(0.9, tray_y + 0.048, tray_z), Color(0.45, 0.32, 0.18), 0.7)


func _chalk_surface() -> ShaderMaterial:
	if _chalk_mat == null:
		_chalk_mat = ShaderMaterial.new()
		_chalk_mat.shader = load("res://shaders/chalkboard.gdshader")
	return _chalk_mat


func _cabinet(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	var shell := Surfaces.pbr("PaintedMetal004", color.darkened(0.1), 0.8, 0.35)
	var door := Surfaces.pbr("PaintedMetal004", color.lightened(0.05), 0.8, 0.35)
	var slot := Color(0.04, 0.045, 0.05)
	_skin(body, Vector3(size.x, size.y - 0.1, size.z), Vector3(0.0, 0.05, 0.0), shell)
	_chip(body, Vector3(size.x - 0.06, 0.1, size.z - 0.06), Vector3(0.0, -size.y * 0.5 + 0.05, 0.0), slot, 0.8)
	_skin(body, Vector3(size.x + 0.04, 0.04, size.z + 0.04), Vector3(0.0, size.y * 0.5 - 0.02, 0.0), shell)
	var face := size.z * 0.5 + 0.0125
	var leaf_w := size.x * 0.5 - 0.04
	var leaf_h := size.y - 0.22
	for sx in [-1.0, 1.0]:
		var cx := float(sx) * (leaf_w * 0.5 + 0.015)
		var at := Vector3(cx, 0.05, face)
		_skin(body, Vector3(leaf_w, leaf_h, 0.025), at, door)
		for row in 2:
			var panel_y := leaf_h * (0.24 if row == 0 else -0.24)
			_chip(body, Vector3(leaf_w - 0.16, 0.006, 0.006), at + Vector3(0.0, panel_y + leaf_h * 0.2, 0.014), slot, 0.6)
			_chip(body, Vector3(leaf_w - 0.16, 0.006, 0.006), at + Vector3(0.0, panel_y - leaf_h * 0.2, 0.014), slot, 0.6)
			_chip(body, Vector3(0.006, leaf_h * 0.4, 0.006), at + Vector3(-(leaf_w * 0.5 - 0.08), panel_y, 0.014), slot, 0.6)
			_chip(body, Vector3(0.006, leaf_h * 0.4, 0.006), at + Vector3(leaf_w * 0.5 - 0.08, panel_y, 0.014), slot, 0.6)
		for hinge_y in [-0.6, 0.6]:
			_chip(body, Vector3(0.02, 0.09, 0.02), Vector3(float(sx) * (size.x * 0.5 - 0.005), 0.05 + hinge_y, face + 0.004), Color(0.5, 0.52, 0.54), 0.35, 0.8)
		_chip(body, Vector3(0.022, 0.2, 0.022), Vector3(float(sx) * 0.07, 0.08, face + 0.03), Color(0.7, 0.71, 0.72), 0.25, 0.9)
		_chip(body, Vector3(0.02, 0.02, 0.03), Vector3(float(sx) * 0.07, 0.17, face + 0.018), Color(0.7, 0.71, 0.72), 0.25, 0.9)
		_chip(body, Vector3(0.02, 0.02, 0.03), Vector3(float(sx) * 0.07, -0.01, face + 0.018), Color(0.7, 0.71, 0.72), 0.25, 0.9)
	_chip(body, Vector3(0.012, 0.03, 0.01), Vector3(0.0, 0.25, face + 0.016), Color(0.62, 0.52, 0.32), 0.3, 0.85)


func _chair(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	var seat_y := -0.02
	var wood := _wood(color.lightened(0.15), "Wood066")
	_skin(body, Vector3(size.x * 0.86, 0.05, size.z * 0.86), Vector3(0.0, seat_y, 0.0), wood)
	_chip(body, Vector3(size.x * 0.8, 0.025, size.z * 0.8), Vector3(0.0, seat_y + 0.035, 0.0), Color(0.22, 0.08, 0.07), 0.95)
	for i in 3:
		_skin(body, Vector3(size.x * 0.78, 0.07, 0.035), Vector3(0.0, size.y * (0.12 + float(i) * 0.12), -size.z * 0.38), wood)
	for sx in [-1.0, 1.0]:
		_skin(body, Vector3(0.045, size.y * 0.5, 0.045), Vector3(sx * size.x * 0.36, size.y * 0.22, -size.z * 0.38), wood)
		for sz in [-1.0, 1.0]:
			_skin(body, Vector3(0.045, size.y * 0.48, 0.045), Vector3(sx * size.x * 0.34, -size.y * 0.26, sz * size.z * 0.34), wood)
		_skin(body, Vector3(0.025, 0.025, size.z * 0.66), Vector3(sx * size.x * 0.34, -size.y * 0.36, 0.0), wood)


func _book(parent: Node3D, at: Vector3, tall: float, thick: float, deep: float, cover: Color, lean: float, kind: int) -> void:
	var book := Node3D.new()
	book.position = at
	book.rotation.x = lean
	parent.add_child(book)
	var pages := Color(0.95, 0.92, 0.84)
	var board_t := 0.007
	var page_t := maxf(thick - board_t * 2.2, 0.01)
	_chip(book, Vector3(deep * 0.9, tall * 0.94, page_t), Vector3(-deep * 0.035, 0.0, 0.0), pages, 0.94)
	for line in 3:
		var z := (float(line) - 1.0) * page_t * 0.22
		_chip(book, Vector3(deep * 0.72, 0.002, 0.0025), Vector3(-deep * 0.05, tall * 0.47, z), pages.darkened(0.18), 0.9)
	var finish := 0.32 if kind % 3 == 0 else 0.82
	_chip(book, Vector3(deep, tall, board_t), Vector3(0.0, 0.0, thick * 0.5), cover, finish)
	_chip(book, Vector3(deep, tall, board_t), Vector3(0.0, 0.0, -thick * 0.5), cover.darkened(0.08), finish)
	var spine := cover.darkened(0.12)
	var spine_x := deep * 0.5
	_chip(book, Vector3(board_t, tall, thick + 0.002), Vector3(spine_x, 0.0, 0.0), spine, finish)
	var cloth := cover.lightened(0.28)
	if kind % 4 == 0:
		cloth = Color(0.78, 0.64, 0.32)
	elif kind % 4 == 1:
		cloth = Color(0.9, 0.88, 0.8)
	elif kind % 4 == 2:
		cloth = cover.lightened(0.45)
	_chip(book, Vector3(0.003, tall * 0.1, thick * 0.72), Vector3(spine_x + 0.005, tall * 0.16, 0.0), cloth, 0.4)
	if kind % 3 != 2:
		_chip(book, Vector3(0.003, tall * 0.045, thick * 0.5), Vector3(spine_x + 0.006, -tall * 0.08, 0.0), cloth.darkened(0.15), 0.45)
	_chip(book, Vector3(0.003, 0.01, thick * 0.82), Vector3(spine_x + 0.005, tall * 0.44, 0.0), Color(0.62, 0.18, 0.16), 0.5)
	_chip(book, Vector3(0.003, 0.008, thick * 0.82), Vector3(spine_x + 0.005, -tall * 0.44, 0.0), Color(0.62, 0.18, 0.16), 0.5)
	_chip(book, Vector3(0.003, 0.016, 0.012), Vector3(spine_x + 0.006, -tall * 0.28, 0.0), cloth, 0.4)


func _book_stack(parent: Node3D, at: Vector3, cover: Color) -> void:
	var pages := Color(0.95, 0.92, 0.84)
	var tones: Array[Color] = [cover, cover.darkened(0.2), Color(0.14, 0.18, 0.28)]
	for i in 3:
		var y := float(i) * 0.034
		var slide := float(i - 1) * 0.012
		var tone := tones[i]
		_chip(parent, Vector3(0.3, 0.006, 0.21), at + Vector3(slide, y, 0.0), tone.darkened(0.12), 0.7)
		_chip(parent, Vector3(0.27, 0.02, 0.17), at + Vector3(slide - 0.008, y + 0.014, 0.0), pages, 0.94)
		for edge in 4:
			var ez := -0.06 + float(edge) * 0.03
			_chip(parent, Vector3(0.24, 0.002, 0.002), at + Vector3(slide - 0.008, y + 0.012 + float(edge) * 0.004, ez), pages.darkened(0.12), 0.9)
		_chip(parent, Vector3(0.3, 0.007, 0.21), at + Vector3(slide, y + 0.026, 0.0), tone, 0.62)
		_chip(parent, Vector3(0.004, 0.018, 0.15), at + Vector3(slide + 0.132, y + 0.014, 0.0), pages.darkened(0.04), 0.9)
	_chip(parent, Vector3(0.012, 0.004, 0.09), at + Vector3(0.04, 0.1, 0.02), Color(0.7, 0.15, 0.14), 0.45)


func _open_book(parent: Node3D, at: Vector3, cover: Color) -> void:
	var pages := Color(0.96, 0.94, 0.88)
	var ink := Color(0.22, 0.22, 0.26)
	_chip(parent, Vector3(0.46, 0.008, 0.32), at, cover.darkened(0.15), 0.7)
	_chip(parent, Vector3(0.2, 0.006, 0.28), at + Vector3(-0.12, 0.006, 0.0), pages, 0.92)
	_chip(parent, Vector3(0.2, 0.006, 0.28), at + Vector3(0.12, 0.008, 0.0), pages, 0.92)
	_chip(parent, Vector3(0.014, 0.012, 0.3), at + Vector3(0.0, 0.004, 0.0), cover.darkened(0.3), 0.8)
	for side_v in [-1.0, 1.0]:
		var side := float(side_v)
		for line in 5:
			var width := 0.13 if line % 4 != 3 else 0.08
			_chip(parent, Vector3(width, 0.003, 0.004), at + Vector3(side * 0.12, 0.012, -0.08 + float(line) * 0.032), ink, 0.9)


func _plinth(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _furn_body(size, pos)
	_skin(body, size, Vector3.ZERO, _wood(color, "Wood066"))
	_chip(body, Vector3(size.x + 0.02, 0.05, size.z + 0.02), Vector3(0.0, size.y * 0.5 - 0.02, 0.0), color.lightened(0.1), 0.7)


func _closed_lockers(pos: Vector3, size: Vector3, side: float) -> void:
	var body := _furn_body(size, pos)
	body.add_to_group("closed_lockers")
	var shell := Surfaces.pbr("PaintedMetal004", Color(0.2, 0.24, 0.28), 0.8, 0.35)
	var door := Surfaces.pbr("PaintedMetal004", Color(0.34, 0.4, 0.46), 0.8, 0.35)
	var lip := Surfaces.pbr("PaintedMetal004", Color(0.28, 0.33, 0.38), 0.8, 0.35)
	var slot := Color(0.04, 0.045, 0.05)
	_skin(body, Vector3(size.x - 0.04, size.y, size.z), Vector3(side * 0.02, 0.0, 0.0), shell)
	var face := -side * (size.x * 0.5 - 0.01)
	var out := -side
	_skin(body, Vector3(0.04, 0.06, size.z + 0.02), Vector3(face + out * 0.006, size.y * 0.5 - 0.03, 0.0), lip)
	_chip(body, Vector3(0.03, 0.08, size.z), Vector3(face + out * 0.004, -size.y * 0.5 + 0.04, 0.0), slot, 0.7)
	var count := 4
	var gap := 0.045
	var door_w := (size.z - gap * float(count + 1)) / float(count)
	var door_h := size.y - 0.2
	for i in count:
		var z := -size.z * 0.5 + gap + door_w * 0.5 + float(i) * (door_w + gap)
		var at := Vector3(face, 0.02, z)
		_skin(body, Vector3(0.028, door_h, door_w), at, door)
		for edge in [-1.0, 1.0]:
			_skin(body, Vector3(0.034, door_h, 0.022), at + Vector3(0.0, 0.0, float(edge) * (door_w * 0.5 - 0.011)), lip)
			_skin(body, Vector3(0.034, 0.022, door_w), at + Vector3(0.0, float(edge) * (door_h * 0.5 - 0.011), 0.0), lip)
		for slit in 5:
			var slit_y := door_h * 0.4 - float(slit) * 0.035
			_chip(body, Vector3(0.01, 0.013, door_w * 0.62), at + Vector3(out * 0.016, slit_y, 0.0), slot, 0.7)
		for slit in 3:
			var slit_y := -door_h * 0.36 - float(slit) * 0.035
			_chip(body, Vector3(0.01, 0.013, door_w * 0.62), at + Vector3(out * 0.016, slit_y, 0.0), slot, 0.7)
		var latch := side * door_w * 0.3
		_chip(body, Vector3(0.016, 0.12, 0.03), at + Vector3(out * 0.02, 0.02, latch), Color(0.68, 0.64, 0.52), 0.25, 0.75)
		_chip(body, Vector3(0.012, 0.03, 0.03), at + Vector3(out * 0.02, 0.12, latch), Color(0.6, 0.52, 0.32), 0.3, 0.85)
		_chip(body, Vector3(0.006, 0.05, 0.11), at + Vector3(out * 0.017, door_h * 0.24, 0.0), Color(0.62, 0.52, 0.32), 0.3, 0.8)
		_chip(body, Vector3(0.004, 0.028, 0.08), at + Vector3(out * 0.021, door_h * 0.24, 0.0), Color(0.12, 0.1, 0.08), 0.7)
		for hinge_y in [-0.6, 0.0, 0.6]:
			_chip(body, Vector3(0.024, 0.08, 0.024), at + Vector3(out * 0.018, hinge_y, -side * (door_w * 0.5 - 0.004)), Color(0.5, 0.52, 0.54), 0.35, 0.8)


func _add_lockers() -> void:
	var script := load("res://scripts/locker.gd")
	var spots: Array = [
		[Vector3(-15.45, 0.0, -6.4), PI / 2.0],
		[Vector3(15.45, 0.0, 5.6), -PI / 2.0],
		[Vector3(15.45, 0.0, -27.8), -PI / 2.0],
		[Vector3(-15.45, 0.0, -19.2), PI / 2.0],
		[Vector3(15.45, 0.0, -54.2), -PI / 2.0],
		[Vector3(-15.45, 0.0, -43.2), PI / 2.0],
	]
	for spot in spots:
		var locker := Node3D.new()
		locker.set_script(script)
		locker.position = spot[0]
		locker.rotation.y = spot[1]
		locker.pulled.connect(_on_locker_pulled)
		add_child(locker)


func _add_ducts() -> void:
	var metal := Surfaces.pbr("Metal032", Color(0.85, 0.87, 0.9), 0.9, 0.45, 1.0, 0.8)
	_duct_box(Vector3(0.9, 0.36, 62.0), Vector3(0.0, 2.95, -25.0), metal)
	for c: float in BLOCKS:
		_duct_box(Vector3(26.0, 0.36, 0.9), Vector3(0.0, 2.95, c), metal)
	_duct_trim(metal)
	var spine := PackedFloat32Array([6.0, 0.0, -12.0, -24.4, -36.0, -48.8, -56.0])
	var spine_ids: Array[int] = []
	for z in spine:
		spine_ids.append(_duct_point(Vector3(0.0, 2.95, z)))
	for i in spine_ids.size() - 1:
		_duct_join(spine_ids[i], spine_ids[i + 1])
	var vent_script := load("res://scripts/vent.gd")
	var mouths: Array[Vector3] = [
		Vector3(0.0, 2.95, 6.0),
		Vector3(0.0, 2.95, -12.0),
		Vector3(0.0, 2.95, -36.0),
		Vector3(0.0, 2.95, -56.0),
	]
	for c: float in BLOCKS:
		var junction := _duct_index_at(Vector3(0.0, 2.95, c))
		var left := _duct_point(Vector3(-13.0, 2.95, c))
		var right := _duct_point(Vector3(13.0, 2.95, c))
		_duct_join(left, junction)
		_duct_join(junction, right)
		mouths.append(Vector3(-13.0, 2.95, c))
		mouths.append(Vector3(13.0, 2.95, c))
	for mouth in mouths:
		var vent := Node3D.new()
		vent.set_script(vent_script)
		vent.position = mouth
		vent.duct_index = _duct_index_at(mouth)
		add_child(vent)
		_vents.append(vent)


func _settle_vents() -> void:
	for vent in _vents:
		if is_position_clear(vent.stand_global(), 0.45):
			continue
		var origin: Vector3 = vent.position
		var shifted := origin
		for _step in 12:
			shifted.x -= signf(origin.x) * 0.45
			vent.position = shifted
			if is_position_clear(vent.stand_global(), 0.45):
				break
		if not is_position_clear(vent.stand_global(), 0.45):
			vent.position = origin


func _duct_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	body.add_child(shape)
	add_child(body)


func _duct_trim(metal: Material) -> void:
	var flanges: Array[Transform3D] = []
	var straps: Array[Transform3D] = []
	var along_x := Basis(Vector3.UP, PI * 0.5)
	var z := 6.0 - 1.2
	while z > -56.0:
		if absf(z - BLOCKS[0]) > 0.6 and absf(z - BLOCKS[1]) > 0.6 and absf(z - BLOCKS[2]) > 0.6:
			flanges.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, z)))
			if int(roundf(z / 1.2)) % 2 == 0:
				straps.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, z + 0.6)))
		z -= 1.2
	for c: float in BLOCKS:
		var x := -12.6
		while x < 12.7:
			if absf(x) > 0.6:
				flanges.append(Transform3D(along_x, Vector3(x, 2.95, c)))
				if int(roundf(x / 1.2)) % 2 == 0:
					straps.append(Transform3D(along_x, Vector3(x + 0.6, 2.95, c)))
			x += 1.2
	var flange_mesh := BoxMesh.new()
	flange_mesh.size = Vector3(0.95, 0.4, 0.035)
	_multi(flange_mesh, metal, flanges)
	var strap_mesh := BoxMesh.new()
	strap_mesh.size = Vector3(0.96, 0.41, 0.025)
	_multi(strap_mesh, Surfaces.flat(Color(0.2, 0.21, 0.22), 0.6, 0.6), straps)
	var rods: Array[Transform3D] = []
	for strap in straps:
		var right := strap.basis.x
		rods.append(Transform3D(Basis.IDENTITY, strap.origin + right * 0.47 + Vector3(0, 0.1, 0)))
		rods.append(Transform3D(Basis.IDENTITY, strap.origin - right * 0.47 + Vector3(0, 0.1, 0)))
	var rod_mesh := CylinderMesh.new()
	rod_mesh.top_radius = 0.008
	rod_mesh.bottom_radius = 0.008
	rod_mesh.height = 0.3
	rod_mesh.radial_segments = 6
	_multi(rod_mesh, Surfaces.flat(Color(0.3, 0.31, 0.32), 0.5, 0.7), rods)
	var joints: Array[Transform3D] = []
	for c: float in BLOCKS:
		joints.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, c)))
	var joint_mesh := BoxMesh.new()
	joint_mesh.size = Vector3(1.08, 0.42, 1.08)
	_multi(joint_mesh, metal, joints)
	var caps: Array[Transform3D] = []
	for c: float in BLOCKS:
		for sx in [-1.0, 1.0]:
			caps.append(Transform3D(along_x, Vector3(float(sx) * 12.99, 2.95, c)))
	caps.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, 6.0 - 0.01)))
	caps.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, -56.0 + 0.01)))
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(0.96, 0.42, 0.05)
	_multi(cap_mesh, metal, caps)


func _multi(mesh: Mesh, surface: Material, transforms: Array[Transform3D]) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.material_override = surface
	add_child(node)


func _duct_point(point: Vector3) -> int:
	_duct_pts.append(point)
	_duct_links.append(PackedInt32Array())
	return _duct_pts.size() - 1


func _duct_join(a: int, b: int) -> void:
	var left := _duct_links[a]
	var right := _duct_links[b]
	left.append(b)
	right.append(a)
	_duct_links[a] = left
	_duct_links[b] = right


func _duct_index_at(point: Vector3) -> int:
	for i in _duct_pts.size():
		if _duct_pts[i].distance_to(point) < 0.2:
			return i
	return 0


func vent_shortcut(from: Vector3, goal: Vector3, player_pos: Vector3) -> Dictionary:
	if _vents.is_empty() or from.distance_to(goal) < 18.0:
		return {}
	var entry: Node3D = _nearest_vent(from)
	var exit: Node3D = _best_vent_exit(goal, player_pos)
	if entry == null or exit == null or entry == exit:
		return {}
	var path := _duct_path(entry.duct_index, exit.duct_index)
	if path.is_empty():
		return {}
	var run := 6.2
	var entry_stand: Vector3 = entry.stand_global()
	var exit_stand: Vector3 = exit.stand_global()
	var on_foot: float = from.distance_to(goal) / run
	var by_duct: float = from.distance_to(entry_stand) / run + _path_length(path) / 9.0 + exit_stand.distance_to(goal) / run + 1.4
	if by_duct >= on_foot:
		return {}
	return {"entry": entry, "exit": exit, "path": path}


func _nearest_vent(from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := 9999.0
	for vent in _vents:
		var gap := from.distance_to(vent.stand_global())
		if gap < best_d:
			best_d = gap
			best = vent
	return best


func _best_vent_exit(goal: Vector3, player_pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := 9999.0
	for vent in _vents:
		var stand: Vector3 = vent.stand_global()
		if stand.distance_to(player_pos) < 8.0:
			continue
		var gap := stand.distance_to(goal)
		if gap < best_d:
			best_d = gap
			best = vent
	return best


func _duct_path(start: int, finish: int) -> PackedVector3Array:
	var previous: PackedInt32Array = PackedInt32Array()
	previous.resize(_duct_pts.size())
	previous.fill(-1)
	var queue: Array[int] = [start]
	previous[start] = start
	var found := false
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == finish:
			found = true
			break
		for nxt in _duct_links[current]:
			if previous[nxt] != -1:
				continue
			previous[nxt] = current
			queue.append(nxt)
	if not found:
		return PackedVector3Array()
	var rev: Array[int] = []
	var cursor := finish
	while cursor != start:
		rev.append(cursor)
		cursor = previous[cursor]
	rev.append(start)
	rev.reverse()
	var path := PackedVector3Array()
	for idx in rev:
		path.append(_duct_pts[idx])
	return path


func _path_length(path: PackedVector3Array) -> float:
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	return total


func _add_school_lights() -> void:
	for c: float in BLOCKS:
		for pos in [
			Vector3(0, 2.75, c - 8),
			Vector3(0, 2.75, c),
			Vector3(0, 2.75, c + 8),
			Vector3(-8, 2.75, c),
			Vector3(8, 2.75, c),
		]:
			_lamp(pos, Color(0.75, 0.86, 1.0), 0.7, 8.0)
		_lamp(Vector3(-9, 2.7, c - 7), Color(0.7, 0.8, 0.75), 0.28, 6.0)
		_lamp(Vector3(9, 2.7, c - 7), Color(1.0, 0.82, 0.6), 0.45, 7.0)
		_lamp(Vector3(-9, 2.7, c + 7), Color(0.75, 0.82, 1.0), 0.35, 6.5)
		_lamp(Vector3(9, 2.7, c + 7), Color(1.0, 0.78, 0.55), 0.3, 6.0)
		for sx in [-1.0, 1.0]:
			_lamp(Vector3(sx * 17.9, 2.75, c + 6.0), Color(0.6, 0.72, 0.85), 0.32, 7.0)
			_lamp(Vector3(sx * 17.9, 2.75, c - 6.0), Color(0.6, 0.72, 0.85), 0.22, 6.0)


func _lamp(pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	add_child(light)
	var fixture := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.06, 0.25)
	fixture.mesh = box
	fixture.position = pos + Vector3(0, 0.2, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	fixture.material_override = mat
	add_child(fixture)
	var rim := Surfaces.pbr("Metal009", Color(0.7, 0.72, 0.74), 2.0, 0.6, 0.6, 0.5)
	for side in [-1.0, 1.0]:
		_skin(fixture, Vector3(0.9, 0.05, 0.04), Vector3(0.0, 0.01, float(side) * 0.145), rim)
		_skin(fixture, Vector3(0.04, 0.05, 0.25), Vector3(float(side) * 0.43, 0.01, 0.0), rim)
	for i in 3:
		_chip(fixture, Vector3(0.012, 0.012, 0.24), Vector3(-0.2 + float(i) * 0.2, -0.035, 0.0), Color(0.6, 0.62, 0.64), 0.4, 0.7)


func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.set_script(load("res://scripts/player.gd"))
	_player.position = PLAYER_SPAWN
	add_child(_player)


func _build_slender() -> void:
	_slender = CharacterBody3D.new()
	_slender.set_script(load("res://scripts/slender.gd"))
	_slender.position = WAKE_SPOT
	add_child(_slender)
	_slender.bind_player(_player)
	_slender.player_caught.connect(_on_caught)
	_slender.set_dormant(true)


func _build_pages() -> void:
	var page_script := load("res://scripts/page.gd")
	for doc in DOCS:
		var page := Node3D.new()
		page.set_script(page_script)
		page.doc_id = doc.id
		page.doc_title = doc.title
		page.pinned = doc.get("pinned", false)
		page.picked_up.connect(_on_page_picked)
		var chest := _hang_costume.get_node_or_null("Body/Book1") if page.pinned else null
		if chest:
			chest.add_child(page)
			page.position = Vector3(0.0, 0.1, 0.4)
			page.rotation = Vector3.ZERO
		else:
			page.position = doc.pos
			page.rotation.y = doc.yaw
			add_child(page)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var static_rect := ColorRect.new()
	static_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	static_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	static_rect.color = Color.WHITE
	_static_mat = ShaderMaterial.new()
	_static_mat.shader = load("res://shaders/static_overlay.gdshader")
	_static_mat.set_shader_parameter("intensity", 0.0)
	static_rect.material = _static_mat
	layer.add_child(static_rect)

	var edge := GradientTexture2D.new()
	edge.width = 256
	edge.height = 256
	edge.fill = GradientTexture2D.FILL_RADIAL
	edge.fill_from = Vector2(0.5, 0.5)
	edge.fill_to = Vector2(1.0, 1.0)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.34, 0.62, 1.0])
	ramp.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.3, 0, 0.02, 0), Color(0.55, 0.0, 0.04, 0.75), Color(0.2, 0.0, 0.01, 1.0)])
	edge.gradient = ramp
	_vignette = TextureRect.new()
	_vignette.texture = edge
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	layer.add_child(_vignette)

	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	layer.add_child(_hud)

	_pages_label = _label(_hud, Vector2.ZERO, 16)
	_box_label(_pages_label, 0.02, 0.03, 0.46, 0.07)
	_pages_label.text = "Documentos  0 / 8"
	_battery_label = _label(_hud, Vector2.ZERO, 14)
	_box_label(_battery_label, 0.02, 0.07, 0.32, 0.11)
	_battery_label.text = "Lanterna  100%"
	_hint_label = _label(_hud, Vector2.ZERO, 14)
	_box_label(_hint_label, 0.02, 0.11, 0.55, 0.18)
	_hint_label.modulate = Color(0.8, 0.8, 0.75)

	_prompt_label = _label(_hud, Vector2.ZERO, 16)
	_box_label(_prompt_label, 0.18, 0.88, 0.82, 0.96)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_breath_bar = ProgressBar.new()
	_breath_bar.min_value = 0.0
	_breath_bar.max_value = 1.0
	_breath_bar.value = 1.0
	_breath_bar.show_percentage = false
	_breath_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_breath_bar.visible = false
	_breath_bar.anchor_left = 0.36
	_breath_bar.anchor_right = 0.64
	_breath_bar.anchor_top = 0.8
	_breath_bar.anchor_bottom = 0.835
	var breath_fill := StyleBoxFlat.new()
	breath_fill.bg_color = Color(0.72, 0.86, 0.95)
	_breath_bar.add_theme_stylebox_override("fill", breath_fill)
	_hud.add_child(_breath_bar)

	_add_crosshair(_hud)
	_build_end_panel(layer)
	_build_debug_panel(layer)
	_build_read_panel(layer)
	_build_menu(layer)
	_todo_label = _label(_hud, Vector2.ZERO, 13)
	_box_label(_todo_label, 0.74, 0.03, 0.98, 0.34)
	_todo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.visible = false
	layer.add_child(_fade)


func _build_audio() -> void:
	_audio = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = int(MIX_RATE)
	gen.buffer_length = 0.25
	_audio.stream = gen
	_audio.volume_db = -6.0
	add_child(_audio)
	_audio.play()


func _pump_audio() -> void:
	var playback := _audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := playback.get_frames_available()
	var cheerful := state == State.MENU
	var ceremony := state == State.CUTSCENE
	var st := 0.0
	var aggr := 0.15
	var near := 0.0
	var back := 0.0
	if state == State.PLAYING and _slender:
		st = _slender.static_level
		aggr = _slender.aggression
		near = _slender.presence
		back = _slender.behind
	var fear := maxf(st, near)
	var bpm := lerpf(62.0, 156.0, fear)
	for _i in frames:
		if state == State.ENDED:
			playback.push_frame(Vector2.ZERO)
			continue
		if _caught_scare > 0.0:
			_music_t += 1.0 / MIX_RATE
			var shriek := _scream_sample() if _caught_scare > 0.78 and _caught_scare <= 1.32 else 0.0
			playback.push_frame(Vector2(shriek, shriek))
			continue
		if cheerful or ceremony:
			_music_t += 1.0 / MIX_RATE
			var sample := _cheerful_sample() if cheerful else _ceremony_sample()
			sample = clampf(sample, -1.0, 1.0)
			playback.push_frame(Vector2(sample, sample))
			continue
		_audio_phase += TAU * 46.0 / MIX_RATE
		_heart_phase = fmod(_heart_phase + (bpm / 60.0) / MIX_RATE, 1.0)
		var drone := sin(_audio_phase) * (0.03 + aggr * 0.05)
		var hiss := randf_range(-1.0, 1.0) * st * 0.2
		var hb := 0.0
		if _heart_phase < 0.08:
			hb = sin(_heart_phase / 0.08 * PI)
		elif _heart_phase > 0.14 and _heart_phase < 0.22:
			hb = sin((_heart_phase - 0.14) / 0.08 * PI) * 0.65
		_tone_t += 1.0 / MIX_RATE
		var thump := sin(TAU * 62.0 * _tone_t) * 0.5 + sin(TAU * 124.0 * _tone_t) * 0.45 + sin(TAU * 248.0 * _tone_t) * 0.22
		var ring := sin(TAU * 1320.0 * _tone_t) * (0.6 + 0.4 * sin(TAU * 5.0 * _tone_t))
		var tense := drone + sin(_audio_phase * 3.0) * aggr * 0.025 + hiss
		tense += hb * thump * fear * 0.55
		tense += ring * back * 0.035
		tense = clampf(tense, -1.0, 1.0)
		playback.push_frame(Vector2(tense, tense))


func _note_hz(semitone: float) -> float:
	return 261.6256 * pow(2.0, semitone / 12.0)


func _cheerful_sample() -> float:
	var beat := 60.0 / 118.0
	var loop := beat * float(_BASS.size())
	var t := fmod(_music_t, loop)
	var index := int(t / beat) % _BASS.size()
	var into := fmod(t, beat) / beat
	var pluck := pow(1.0 - into, 1.45)
	var mel_semi := float(_MELODY[index])
	var mel_hz := _note_hz(mel_semi)
	var mel := sin(TAU * mel_hz * _music_t)
	mel += 0.28 * sin(TAU * mel_hz * 2.0 * _music_t)
	var fifth := sin(TAU * _note_hz(mel_semi + 7.0) * _music_t)
	var bass := sin(TAU * _note_hz(float(_BASS[index])) * _music_t)
	bass += 0.2 * sin(TAU * _note_hz(float(_BASS[index])) * 2.0 * _music_t)
	return (mel * 0.34 + fifth * 0.12 + bass * 0.3) * pluck * 0.9


func _scream_sample() -> float:
	var scream := sin(TAU * 940.0 * _music_t) * 0.28
	scream += sin(TAU * 70.0 * _music_t) * 0.22
	scream += randf_range(-1.0, 1.0) * 0.34
	return scream


func _ceremony_sample() -> float:
	if state == State.ENDED or (_scare > 0.0 and (_scare > 1.32 or _scare <= 0.78)):
		return 0.0
	var t := _cut_t
	if _scare > 0.78:
		return _scream_sample()
	var noise := randf_range(-1.0, 1.0)
	_cer_hi += (noise - _cer_hi) * 0.45
	_cer_lo += (noise - _cer_lo) * 0.06
	var hum := sin(TAU * 110.0 * _music_t) * 0.012 + sin(TAU * 165.0 * _music_t) * 0.006
	if t < CUT_WALK:
		var step := fmod(t, 0.48)
		var knock := exp(-step * 38.0)
		var creak := sin(TAU * (240.0 + 60.0 * sin(step * 40.0)) * _music_t) * exp(-step * 9.0) * 0.07
		return hum + sin(TAU * 130.0 * _music_t) * knock * 0.3 + _cer_lo * knock * 0.4 + creak
	if t < CUT_HAND:
		var pulse := fmod(t, 0.9)
		var beat := sin(TAU * 70.0 * _music_t) * exp(-pulse * 14.0) * 0.25
		return hum * 0.5 + beat
	var clap_rate := 0.0
	var muffle := 0.0
	if t < CUT_FOCUS:
		clap_rate = 55.0 * smoothstep(CUT_HAND, CUT_HAND + 0.6, t)
	else:
		muffle = smoothstep(0.0, 1.0, (t - CUT_FOCUS) / maxf(CUT_DOLLY - CUT_FOCUS, 0.1))
		clap_rate = lerpf(40.0, 0.0, muffle)
	if randf() < clap_rate / MIX_RATE:
		_clap = randf_range(0.5, 1.0)
	_clap *= 0.9962
	var clap := lerpf(_cer_hi - _cer_lo, _cer_lo, muffle) * _clap * lerpf(0.55, 0.25, muffle)
	var cheer := 0.0
	if t < CUT_FOCUS:
		var chord := sin(TAU * _note_hz(0.0) * _music_t) + sin(TAU * _note_hz(4.0) * _music_t) * 0.8 + sin(TAU * _note_hz(7.0) * _music_t) * 0.7
		cheer = chord * 0.035 * smoothstep(CUT_HAND, CUT_TURN, t)
		if fmod(t, 0.41) < 0.06:
			cheer += sin(TAU * 2100.0 * _music_t) * 0.08
	var drone := (sin(TAU * 104.0 * _music_t) * 0.12 + sin(TAU * 157.0 * _music_t) * 0.06 + sin(TAU * 52.0 * _music_t) * 0.1) * muffle
	return clap + cheer + drone + hum * (1.0 - muffle)


func _play_tone(freq: float, duration: float, volume: float) -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = _slender._tone(freq, duration, volume)
	sfx.volume_db = -2.0
	add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()


func _menu_title(parent: Node, text: String, size: int, color: Color) -> Label:
	var label := _label(parent, Vector2.ZERO, size)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _label(parent: Node, pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _box_label(label: Label, left: float, top: float, right: float, bottom: float) -> void:
	label.anchor_left = left
	label.anchor_top = top
	label.anchor_right = right
	label.anchor_bottom = bottom
	label.offset_left = 0
	label.offset_top = 0
	label.offset_right = 0
	label.offset_bottom = 0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_contents = true


func _build_menu(layer: CanvasLayer) -> void:
	_menu = Control.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_menu)
	var sky := ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.1, 0.28, 0.62)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(sky)
	var band := ColorRect.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.offset_top = 0
	band.anchor_bottom = 0.42
	band.color = Color(0.16, 0.42, 0.82, 0.55)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(band)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(center)
	var card := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.97, 0.95, 0.9, 0.98)
	paper.border_color = Color(0.118, 0.102, 0.404)
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(18)
	paper.content_margin_left = 36
	paper.content_margin_right = 36
	paper.content_margin_top = 28
	paper.content_margin_bottom = 22
	paper.shadow_color = Color(0.02, 0.08, 0.2, 0.35)
	paper.shadow_size = 18
	card.add_theme_stylebox_override("panel", paper)
	card.custom_minimum_size = Vector2(860, 0)
	center.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/unifacef_logo.png")
	logo.custom_minimum_size = Vector2(740, 168)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo)
	var start := _menu_button("Iniciar", Color(0.118, 0.102, 0.404))
	start.name = "BtnStart"
	start.pressed.connect(_start_game.bind(false))
	column.add_child(start)
	var debug := _menu_button("Modo debug", Color(0.2, 0.62, 0.58))
	debug.name = "BtnDebug"
	debug.pressed.connect(_start_game.bind(true))
	column.add_child(debug)
	var credits := VBoxContainer.new()
	credits.visible = false
	credits.add_theme_constant_override("separation", 14)
	card.add_child(credits)
	_menu_title(credits, "Créditos", 34, Color(0.118, 0.102, 0.404))
	_menu_title(credits, "Desenvolvido por", 16, Color(0.35, 0.4, 0.5))
	for student in [
		"Ana Laura Silva Pereira - 24696",
		"Camilo Verissimo Garcia Prado - 24583",
		"Lucas Eduardo Alves Vizoto - 24691",
	]:
		_menu_title(credits, student, 22, Color(0.1, 0.12, 0.2))
	var back := _menu_button("Voltar", Color(0.118, 0.102, 0.404))
	back.pressed.connect(func() -> void:
		credits.visible = false
		column.visible = true)
	credits.add_child(back)
	var credits_button := _menu_button("Créditos", Color(0.86, 0.68, 0.28))
	credits_button.name = "BtnCredits"
	credits_button.pressed.connect(func() -> void:
		column.visible = false
		credits.visible = true)
	column.add_child(credits_button)
	var quit := _menu_button("Sair", Color(0.55, 0.38, 0.32))
	quit.name = "BtnQuit"
	quit.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit)
	_menu_title(column, "WASD para andar    Mouse para olhar\nShift para correr    F para a lanterna    E para pegar ou se esconder\nEsc solta o mouse    F3 abre o modo debug", 15, Color(0.35, 0.4, 0.5))


func _build_end_panel(layer: CanvasLayer) -> void:
	_end_panel = PanelContainer.new()
	_end_panel.visible = false
	_end_panel.set_anchors_preset(Control.PRESET_CENTER)
	_end_panel.offset_left = -200
	_end_panel.offset_top = -90
	_end_panel.offset_right = 200
	_end_panel.offset_bottom = 90
	_end_panel.add_theme_stylebox_override("panel", _card_style(Color(0.83, 0.66, 0.32)))
	layer.add_child(_end_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_end_panel.add_child(column)
	_end_message = _label(column, Vector2.ZERO, 20)
	_end_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_message.custom_minimum_size = Vector2(360, 48)
	var again := _menu_button("Voltar ao menu", Color(0.86, 0.68, 0.28))
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	column.add_child(again)


func _build_read_panel(layer: CanvasLayer) -> void:
	_read_panel = Control.new()
	_read_panel.name = "ReadPanel"
	_read_panel.visible = false
	_read_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_read_panel)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.03, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_read_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_read_panel.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.95, 0.925, 0.85, 0.99)
	paper.border_color = Color(0.78, 0.68, 0.5)
	paper.set_border_width_all(3)
	paper.border_width_bottom = 6
	paper.set_corner_radius_all(3)
	paper.content_margin_left = 30
	paper.content_margin_right = 30
	paper.content_margin_top = 22
	paper.content_margin_bottom = 18
	paper.shadow_color = Color(0, 0, 0, 0.55)
	paper.shadow_size = 22
	paper.shadow_offset = Vector2(6, 10)
	card.add_theme_stylebox_override("panel", paper)
	center.add_child(card)
	_read_card = card
	_read_style = paper
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	_read_logo = TextureRect.new()
	_read_logo.texture = load("res://assets/unifacef_logo.png")
	_read_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_read_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_read_logo.custom_minimum_size = Vector2(150, 34)
	header.add_child(_read_logo)
	var kicker := _paper_label(header, 12, Color(0.45, 0.28, 0.14))
	kicker.text = "DOCUMENTO ENCONTRADO"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kicker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_read_kicker = kicker
	var top_rule := ColorRect.new()
	top_rule.custom_minimum_size = Vector2(0, 3)
	top_rule.color = Color(0.12, 0.22, 0.55)
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top_rule)
	_read_rule = top_rule
	_read_title = _paper_label(column, 28, Color(0.12, 0.09, 0.07))
	_read_title.add_theme_font_override("font", _ink_font(0.0, 0.5))
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(0.55, 0.38, 0.16, 0.85)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	_read_lore = _paper_label(column, 16, Color(0.16, 0.12, 0.09))
	_read_lore.custom_minimum_size = Vector2(490, 0)
	_read_lore.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	var tag := _paper_label(column, 12, Color(0.55, 0.16, 0.12))
	tag.text = "A REGRA"
	_read_effect = _paper_label(column, 16, Color(0.42, 0.1, 0.08))
	_read_effect.custom_minimum_size = Vector2(490, 0)
	var close := _menu_button("Guardar o documento", Color(0.45, 0.28, 0.14))
	close.name = "BtnCloseRead"
	_read_close = close
	close.pressed.connect(_close_reading)
	column.add_child(close)
	var hint := _paper_label(column, 12, Color(0.38, 0.3, 0.22))
	hint.text = "Enter, E ou Esc"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(overlay)
	var stamp_style := StyleBoxFlat.new()
	stamp_style.bg_color = Color(0, 0, 0, 0)
	stamp_style.border_color = Color(0.72, 0.08, 0.08)
	stamp_style.set_border_width_all(4)
	stamp_style.set_corner_radius_all(8)
	stamp_style.content_margin_left = 12
	stamp_style.content_margin_right = 12
	var stamp := PanelContainer.new()
	stamp.add_theme_stylebox_override("panel", stamp_style)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.position = Vector2(370, 92)
	stamp.rotation = -0.2
	stamp.modulate.a = 0.0
	overlay.add_child(stamp)
	var stamp_text := Label.new()
	stamp_text.text = "RECEBIDO"
	stamp_text.add_theme_font_override("font", _ink_font(0.0, 0.8))
	stamp_text.add_theme_font_size_override("font_size", 24)
	stamp_text.add_theme_color_override("font_color", Color(0.72, 0.08, 0.08))
	stamp.add_child(stamp_text)
	_read_stamp = stamp


func _ink_font(slant: float, bold: float) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = bold
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(slant, 1.0), Vector2.ZERO)
	return font


func _style_reading(note: bool) -> void:
	_read_style.bg_color = Color(0.93, 0.88, 0.7, 0.99) if note else Color(0.95, 0.925, 0.85, 0.99)
	_read_style.border_color = Color(0.7, 0.58, 0.36) if note else Color(0.78, 0.68, 0.5)
	_read_logo.visible = not note
	_read_rule.color = Color(0.7, 0.2, 0.2, 0.7) if note else Color(0.12, 0.22, 0.55)
	_read_title.add_theme_font_override("font", _ink_font(0.26, 1.0) if note else _ink_font(0.0, 0.5))
	_read_title.add_theme_color_override("font_color", Color(0.62, 0.05, 0.05) if note else Color(0.12, 0.09, 0.07))
	_read_lore.add_theme_font_override("font", _ink_font(0.22, 0.2) if note else ThemeDB.fallback_font)
	_read_lore.add_theme_font_size_override("font_size", 18 if note else 16)
	_read_stamp.visible = not note


func _animate_reading() -> void:
	_read_card.modulate.a = 0.0
	_read_lore.visible_ratio = 0.0
	_read_effect.modulate.a = 0.0
	_read_stamp.modulate.a = 0.0
	_read_stamp.scale = Vector2(1.8, 1.8)
	await get_tree().process_frame
	_read_card.pivot_offset = _read_card.size * 0.5
	_read_card.scale = Vector2(0.86, 0.86)
	_read_card.rotation = -0.07
	_read_stamp.pivot_offset = _read_stamp.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_read_card, "modulate:a", 1.0, 0.22)
	tween.tween_property(_read_card, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_read_card, "rotation", -0.015, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var reveal := clampf(float(_read_lore.text.length()) * 0.014, 0.6, 2.2)
	tween.tween_property(_read_lore, "visible_ratio", 1.0, reveal).set_delay(0.25)
	tween.tween_property(_read_effect, "modulate:a", 1.0, 0.4).set_delay(0.25 + reveal)
	if _read_stamp.visible:
		tween.tween_property(_read_stamp, "modulate:a", 0.85, 0.08).set_delay(0.3 + reveal)
		tween.tween_property(_read_stamp, "scale", Vector2.ONE, 0.16).set_delay(0.3 + reveal)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _paper_label(parent: Node, size: int, color: Color) -> Label:
	var label := _label(parent, Vector2.ZERO, size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _build_debug_panel(layer: CanvasLayer) -> void:
	_debug_panel = PanelContainer.new()
	_debug_panel.visible = false
	_debug_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_debug_panel.position = Vector2(16, 148)
	_debug_panel.add_theme_stylebox_override("panel", _card_style(Color(0.45, 0.72, 0.78)))
	layer.add_child(_debug_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_debug_panel.add_child(column)
	var title := _label(column, Vector2.ZERO, 15)
	title.text = "DEBUG    F3 esconde"
	title.modulate = Color(0.55, 0.86, 0.9)
	_debug_stats = _label(column, Vector2.ZERO, 13)
	_debug_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_debug_stats.custom_minimum_size = Vector2(290, 156)
	_static_bar = ProgressBar.new()
	_static_bar.min_value = 0.0
	_static_bar.max_value = 1.0
	_static_bar.show_percentage = false
	_static_bar.custom_minimum_size = Vector2(0, 12)
	_static_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_static_bar)
	_debug_log_label = _label(column, Vector2.ZERO, 12)
	_debug_log_label.modulate = Color(0.78, 0.76, 0.68)
	_debug_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_debug_log_label.custom_minimum_size = Vector2(290, 72)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	_debug_action(grid, "Próximo doc", _debug_goto_next_doc)
	_debug_action(grid, "Acordar", _debug_wake)
	_debug_action(grid, "Congelar", _debug_freeze)
	_debug_action(grid, "Lanterna", _debug_refill_light)
	_god_button = _debug_action(grid, "Deus: desligado", _debug_toggle_god)
	_debug_action(grid, "Ir até ele", _debug_face_mascot)


func _set_debug(enabled: bool) -> void:
	debug_mode = enabled
	if _debug_panel:
		_debug_panel.visible = enabled and state == State.PLAYING


func _refresh_debug() -> void:
	if _debug_stats == null or _slender == null or _player == null:
		return
	var dist := _player.global_position.distance_to(_slender.global_position)
	var looking := false
	var lit := false
	if _slender.has_method("_player_is_looking"):
		looking = _slender._player_is_looking()
		lit = _slender._in_flashlight()
	_debug_stats.text = "\n".join([
		"FPS  %d" % Engine.get_frames_per_second(),
		"Você  " + _fmt_vec(_player.global_position),
		"Ele  " + _fmt_vec(_slender.global_position),
		"Distância  %.1f m" % dist,
		"Estático  %.0f%%" % (_slender.static_level * 100.0),
		"Agressão  %.0f%%     Graça  %.1f s" % [_slender.aggression * 100.0, _grace],
		"Olhando  %s     Na luz  %s" % ["sim" if looking else "não", "sim" if lit else "não"],
		"Cabeça  " + str(_slender.mind),
		"Ativo  %s     Deus  %s" % ["sim" if _slender.active else "não", "sim" if debug_god else "não"],
		"Lanterna  %s  %d%%" % ["ligada" if _player.flashlight_on else "desligada", int(_player.battery)],
		"Documentos  %d / 8" % pages,
		"Regras  " + (", ".join(_rules) if not _rules.is_empty() else "nenhuma"),
	])
	_static_bar.value = _slender.static_level
	_debug_log_label.text = "\n".join(_debug_log)


func _debug_note(text: String) -> void:
	if not debug_mode:
		return
	_debug_log.append(text)
	while _debug_log.size() > 5:
		_debug_log.remove_at(0)


func _debug_goto_next_doc() -> void:
	for node in get_tree().get_nodes_in_group("pages"):
		if node.taken:
			continue
		_player.global_position = node.global_position + Vector3(0.0, 0.1, 1.5)
		_player.velocity = Vector3.ZERO
		_debug_note("Teleporte: " + node.doc_title)
		return
	_debug_note("Nenhum documento restante")


func _debug_wake() -> void:
	_wake_mascot()
	_grace = 0.0
	_slender.active = true
	_debug_note("Mascote acordado")
	_show_hint("Debug: o mascote acordou.")


func _debug_freeze() -> void:
	_slender.active = not _slender.active
	_slender.velocity = Vector3.ZERO
	_debug_note("Mascote " + ("ativo" if _slender.active else "congelado"))


func _debug_refill_light() -> void:
	_player.battery = 100.0
	_player.flashlight_on = true
	_debug_note("Lanterna recarregada")


func _debug_toggle_god() -> void:
	debug_god = not debug_god
	if debug_god and _caught_scare > 0.0:
		_abort_caught_scare()
	_sync_god_button()
	_debug_note("Modo deus " + ("ligado" if debug_god else "desligado"))


func _sync_god_button() -> void:
	if _god_button:
		_god_button.text = "Deus: " + ("ligado" if debug_god else "desligado")


func _debug_face_mascot() -> void:
	var front := -_slender.global_transform.basis.z
	front.y = 0.0
	if front.length_squared() < 0.01:
		front = Vector3(0, 0, -1)
	front = front.normalized()
	_player.global_position = _slender.global_position + front * 3.2 + Vector3(0, 0.1, 0)
	_player.velocity = Vector3.ZERO
	_debug_note("Posicionado na frente do mascote")


func _debug_shove_mascot() -> void:
	var origin := _player.global_position
	var reaches: Array[float] = [8.0, 5.0, 3.2]
	var angles: Array[float] = [PI, PI * 0.5, -PI * 0.5, 0.0, PI * 0.25, -PI * 0.25]
	for reach in reaches:
		for ang in angles:
			var pos := origin + Vector3(sin(ang), 0.0, cos(ang)) * reach
			pos.y = 0.1
			if _walkable(pos) and pos.distance_to(origin) > _slender.catch_distance + 0.8:
				_slender.global_position = pos
				_slender.velocity = Vector3.ZERO
				return


func _fmt_vec(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]


func _add_crosshair(parent: Control) -> void:
	var cross := ColorRect.new()
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.color = Color(1, 1, 1, 0.8)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.size = Vector2(2, 14)
	cross.position = Vector2(-1, -7)
	parent.add_child(cross)
	var cross_h := ColorRect.new()
	cross_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross_h.color = Color(1, 1, 1, 0.8)
	cross_h.set_anchors_preset(Control.PRESET_CENTER)
	cross_h.size = Vector2(14, 2)
	cross_h.position = Vector2(-7, -1)
	parent.add_child(cross_h)


func _card_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.09, 0.9)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _menu_button(text: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.1, 0.16, 0.96)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = accent.darkened(0.18)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86))
	button.add_theme_color_override("font_hover_color", Color(0.08, 0.09, 0.12))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.09, 0.12))
	button.add_theme_font_size_override("font_size", 16)
	return button


func _debug_action(parent: GridContainer, text: String, callback: Callable) -> Button:
	var button := _menu_button(text, Color(0.45, 0.72, 0.78))
	button.custom_minimum_size = Vector2(140, 32)
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _solid(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	_box(parent, size, pos, color, true)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, solid := false, surface: Material = null) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = surface if surface else Surfaces.flat(color, 0.92)
	var holder: Node3D = mesh
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		parent.add_child(body)
		body.add_child(mesh)
		var shape := CollisionShape3D.new()
		var col := BoxShape3D.new()
		col.size = size
		shape.shape = col
		body.add_child(shape)
		return
	mesh.position = pos
	parent.add_child(holder)


func _ensure_actions() -> void:
	_bind("move_forward", KEY_W)
	_bind("move_back", KEY_S)
	_bind("move_left", KEY_A)
	_bind("move_right", KEY_D)
	_bind("sprint", KEY_SHIFT)
	_bind("flashlight", KEY_F)
	_bind("interact", KEY_E)
	_bind("breath", KEY_SPACE)
	_bind("restart", KEY_R)
	_bind("debug_toggle", KEY_F3)


func _bind(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, ev)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
