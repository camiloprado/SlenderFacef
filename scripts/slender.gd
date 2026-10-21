extends CharacterBody3D

signal player_caught(reason: String)

var active := false
var aggression := 0.12
var static_level := 0.0
var held := false
var watch_behind := false
var relentless := false
var speed_scale := 1.0
var blink_scale := 1.0
var blink_closer := 1.0
var move_while_watched := 0.0
var static_scale := 1.0
var catch_distance := 1.45

var presence := 0.0
var behind := 0.0

var _player: CharacterBody3D
var _teleport_timer := 4.0
var _static_hold := 0.0
var _eye_mat: ShaderMaterial
var _costume: Node3D
var _stride := 0.0
var _player_idle := 0.0
const IDLE_HUNT := 3.0
var _steps: Array[AudioStreamWAV] = []
var _squeak: AudioStreamWAV

func _ready() -> void:
	add_to_group("slender")
	floor_snap_length = 0.4
	_build_body()


func bind_player(player: CharacterBody3D) -> void:
	_player = player


func set_pages(count: int) -> void:
	aggression = clampf(0.12 + float(count) / 8.0 * 0.88, 0.0, 1.0)
	if _eye_mat:
		_eye_mat.set_shader_parameter("glow", lerpf(0.15, 1.4, aggression))


func apply_curse(id: String) -> void:
	match id:
		"tcc":
			speed_scale += 0.45
		"estagio":
			watch_behind = true
		"relatorio":
			blink_scale += 0.95
			blink_closer = minf(blink_closer, 0.62)
		"integrador":
			move_while_watched = maxf(move_while_watched, 0.5)
		"artigo":
			static_scale += 0.9
		"prova":
			catch_distance += 0.55
		"colacao":
			relentless = true
			speed_scale += 0.25


func _physics_process(delta: float) -> void:
	var breath := get_node_or_null("Breath") as AudioStreamPlayer3D
	if not active or held or _player == null:
		presence = move_toward(presence, 0.0, delta)
		behind = move_toward(behind, 0.0, delta * 2.0)
		if breath and breath.playing and not active:
			breath.stop()
		return
	if breath and not breath.playing:
		breath.play()

	var looking := _player_is_looking()
	var dist := _flat_distance()
	_update_static(delta, looking, dist)
	_update_presence(delta, looking, dist)
	if breath:
		breath.volume_db = lerpf(-10.0, 2.0, aggression)

	var staring := _in_flashlight()
	if Vector2(_player.velocity.x, _player.velocity.z).length() < 0.4:
		_player_idle += delta
	else:
		_player_idle = 0.0
	if watch_behind and (not staring or relentless) and _is_in_front() and not _hunting():
		_teleport_timer = minf(_teleport_timer, 0.6)
	var speed := lerpf(2.1, 6.4, aggression) * speed_scale
	if _player.sprinting:
		speed *= 1.15
	if staring and not relentless:
		speed *= move_while_watched
	var dir := _chase_direction()
	if speed <= 0.05 or dir == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, delta * 24.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 24.0)
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	if not staring or relentless:
		_teleport_timer -= delta * (1.35 if _player.sprinting else 1.0) * blink_scale
		if _teleport_timer <= 0.0:
			_teleport_timer = lerpf(6.2, 1.9, aggression) / blink_scale
			_blink_closer()

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	_face_player()
	var moved := Vector2(velocity.x, velocity.z).length()
	_costume.walk(delta, moved)
	_stride += moved * delta
	if _stride > 0.95:
		_stride = 0.0
		_play_step()

	var safe: bool = _player.hidden or _player.hide_grace > 0.0 or _god_mode()
	if _god_mode():
		static_level = minf(static_level, 0.2)
		_static_hold = 0.0
	elif dist < catch_distance and not safe:
		_catch("O mascote alcançou você.")
	elif static_level >= 0.99 and not safe:
		_static_hold += delta
		if _static_hold > 0.4:
			_catch("A estática consumiu você.")
	else:
		_static_hold = maxf(_static_hold - delta, 0.0)


func _god_mode() -> bool:
	var game := get_parent()
	return game != null and bool(game.get("debug_god"))


func _catch(reason: String) -> void:
	if not active or _god_mode():
		return
	active = false
	velocity = Vector3.ZERO
	player_caught.emit(reason)


func _update_static(delta: float, looking: bool, dist: float) -> void:
	var target := 0.0
	if looking:
		var closeness := 1.0 - clampf(dist / 26.0, 0.0, 1.0)
		target = pow(closeness, 1.15)
	var rate := (2.2 * static_scale) if target > static_level else 1.6
	static_level = move_toward(static_level, target, delta * rate)


func _update_presence(delta: float, looking: bool, dist: float) -> void:
	var near := 1.0 - clampf((dist - 1.5) / 13.0, 0.0, 1.0)
	presence = move_toward(presence, near, delta * 2.0)
	var cam: Camera3D = _player.get_camera()
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	var to_him := global_position - _player.global_position
	to_him.y = 0.0
	var unseen := 1.0
	if forward.length_squared() > 0.001 and to_him.length_squared() > 0.01:
		var dot := forward.normalized().dot(to_him.normalized())
		unseen = clampf((0.35 - dot) / 0.7, 0.0, 1.0)
	if looking:
		unseen = 0.0
	var target := pow(near, 1.3) * unseen
	behind = move_toward(behind, target, delta * (2.5 if target > behind else 1.2))


func _play_step() -> void:
	var feet := get_node_or_null("Steps") as AudioStreamPlayer3D
	if feet == null or _steps.is_empty():
		return
	feet.stream = _steps[randi() % _steps.size()]
	feet.pitch_scale = randf_range(0.88, 1.08)
	feet.volume_db = lerpf(0.0, 6.0, aggression)
	feet.play()
	if randf() < 0.3:
		var squeak := get_node_or_null("Squeak") as AudioStreamPlayer3D
		if squeak:
			squeak.pitch_scale = randf_range(0.9, 1.15)
			squeak.play()


func _is_in_front() -> bool:
	var cam: Camera3D = _player.get_camera()
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return false
	forward = forward.normalized()
	var to_him := global_position - _player.global_position
	to_him.y = 0.0
	if to_him.length_squared() < 0.2:
		return false
	return forward.dot(to_him.normalized()) > 0.2


func _hunting() -> bool:
	return _player_idle > IDLE_HUNT


func _follow_distance() -> float:
	return catch_distance + lerpf(4.0, 2.6, aggression)


func _chase_direction() -> Vector3:
	var goal := _player.global_position
	if watch_behind and not _hunting():
		goal = _behind_spot(_follow_distance())
		if _flat_distance() < _follow_distance() - 0.3:
			return Vector3.ZERO
	var dir := goal - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.12:
		return Vector3.ZERO
	return dir.normalized()


func _behind_spot(distance: float) -> Vector3:
	var cam: Camera3D = _player.get_camera()
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var scales: Array[float] = [1.0, 0.82, 1.18, 0.65, 1.35]
	for scale in scales:
		var pos: Vector3 = _player.global_position - forward * distance * scale
		pos.y = 0.1
		if pos.distance_to(_player.global_position) < catch_distance + 1.5:
			continue
		if _walkable(pos):
			return pos
	var fallback := _player.global_position - forward * distance
	fallback.y = 0.1
	return fallback


func _walkable(pos: Vector3) -> bool:
	var game := get_parent()
	if game and game.has_method("is_position_clear"):
		return game.is_position_clear(pos, 0.6)
	return true


func _blink_closer() -> void:
	if _player == null:
		return
	if watch_behind and not _hunting():
		var spot := _behind_spot(_follow_distance() + 0.8)
		if _walkable(spot) and spot.distance_to(_player.global_position) > catch_distance + 1.5:
			global_position = spot
			velocity = Vector3.ZERO
			_play_blink()
		return
	var origin := _player.global_position
	var cam: Camera3D = _player.get_camera()
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var behind := -forward
	var current := _flat_distance()
	var desired := clampf(current * lerpf(0.7, 0.42, aggression), lerpf(7.5, 2.8, aggression), 14.0) * blink_closer
	var best := global_position
	var best_score := -999.0
	for i in 18:
		var ang := randf() * TAU
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		dir = (dir + behind * 1.6).normalized()
		var pos := origin + dir * randf_range(desired * 0.85, desired * 1.15)
		pos.y = 0.1
		if not _destination_clear(pos):
			continue
		var to_player := pos - origin
		to_player.y = 0.0
		var view := forward.dot(to_player.normalized()) if to_player.length_squared() > 0.01 else 1.0
		var score := -view * 3.0 - absf(to_player.length() - desired) * 0.08
		if score > best_score:
			best_score = score
			best = pos
	if best_score < -100.0:
		return
	global_position = best
	velocity = Vector3.ZERO
	if _flat_distance() < 18.0:
		_play_blink()


func _destination_clear(pos: Vector3) -> bool:
	if pos.distance_to(_player.global_position) < maxf(1.7, 2.8 * blink_closer):
		return false
	var game := get_parent()
	if game and game.has_method("is_position_clear"):
		return game.is_position_clear(pos, 1.3)
	return true


func _player_is_looking() -> bool:
	return _visible_from(_player.get_camera(), 28.0, 0.62)


func _in_flashlight() -> bool:
	if not _player.flashlight_on or _player.battery <= 0.0:
		return false
	var light: SpotLight3D = _player.light
	return _visible_from(light, light.spot_range, cos(deg_to_rad(light.spot_angle + 6.0)))


func _visible_from(eye: Node3D, reach: float, min_facing: float) -> bool:
	var cam: Camera3D = _player.get_camera()
	var target := global_position + Vector3(0.0, 1.55, 0.0)
	var to := target - eye.global_position
	var dist := to.length()
	if dist > reach or dist < 0.05:
		return false
	var dir := to / dist
	var facing := (-cam.global_transform.basis.z).dot(dir)
	if facing < min_facing:
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, target)
	query.exclude = [_player.get_rid()]
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.collider == self


func _flat_distance() -> float:
	var a := global_position
	var b := _player.global_position
	a.y = 0.0
	b.y = 0.0
	return a.distance_to(b)


func _flat_direction() -> Vector3:
	var dir := _player.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return Vector3.ZERO
	return dir.normalized()


func _face_player() -> void:
	var flat := _player.global_position - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.001:
		return
	look_at(global_position + flat, Vector3.UP)


func _play_blink() -> void:
	var player := get_node_or_null("Blink")
	if player == null:
		return
	player.stream = _whoosh()
	player.play()


func _build_body() -> void:
	var body_col := CollisionShape3D.new()
	body_col.name = "Collision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.05
	body_col.shape = capsule
	body_col.position.y = 1.03
	add_child(body_col)

	_costume = Node3D.new()
	_costume.set_script(load("res://scripts/costume.gd"))
	_costume.name = "Mascot"
	# The costume faces +Z. The body looks along -Z.
	_costume.rotation.y = PI
	add_child(_costume)
	_eye_mat = _costume.eye_material

	var blink := AudioStreamPlayer3D.new()
	blink.name = "Blink"
	blink.unit_size = 8.0
	blink.max_distance = 24.0
	blink.volume_db = 3.0
	add_child(blink)

	for i in 3:
		_steps.append(_step_sound(i))
	_squeak = _squeak_sound()
	var feet := AudioStreamPlayer3D.new()
	feet.name = "Steps"
	feet.unit_size = 5.0
	feet.max_distance = 30.0
	add_child(feet)
	var squeak := AudioStreamPlayer3D.new()
	squeak.name = "Squeak"
	squeak.stream = _squeak
	squeak.unit_size = 3.0
	squeak.max_distance = 18.0
	squeak.volume_db = -8.0
	add_child(squeak)
	var breath := AudioStreamPlayer3D.new()
	breath.name = "Breath"
	breath.stream = _breath_sound()
	breath.unit_size = 2.2
	breath.max_distance = 13.0
	breath.position.y = 1.7
	add_child(breath)


func set_dormant(dormant: bool) -> void:
	visible = not dormant
	active = false
	velocity = Vector3.ZERO
	(get_node("Collision") as CollisionShape3D).disabled = dormant


func _tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var mix := 22050
	var count := int(float(mix) * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(mix)
		var env := pow(1.0 - t / duration, 2.0)
		var sample := sin(TAU * freq * t) * env * volume
		var v := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix
	wav.stereo = false
	wav.data = data
	return wav


func _step_sound(variant: int) -> AudioStreamWAV:
	var mix := 22050.0
	var count := int(mix * 0.26)
	var out := PackedFloat32Array()
	out.resize(count)
	var low := 0.0
	var high := 0.0
	var hits: Array[Vector2] = [Vector2(0.0, 1.0)]
	if variant == 1:
		hits.append(Vector2(0.045, 0.55))
	elif variant == 2:
		hits = [Vector2(0.0, 0.8), Vector2(0.03, 0.7)]
	for i in count:
		var t := float(i) / mix
		var noise := randf_range(-1.0, 1.0)
		low += (noise - low) * 0.12
		high += (noise - high) * 0.6
		var s := 0.0
		for hit in hits:
			var u := t - hit.x
			if u < 0.0:
				continue
			s += low * exp(-u * 26.0) * 1.8 * hit.y
			s += sin(TAU * 105.0 * u) * exp(-u * 30.0) * 0.45 * hit.y
			s += sin(TAU * 210.0 * u) * exp(-u * 36.0) * 0.3 * hit.y
			s += (high - low) * exp(-u * 48.0) * 0.35 * hit.y
		out[i] = s
	return _wav_from(out)


func _squeak_sound() -> AudioStreamWAV:
	var mix := 22050.0
	var length := 0.13
	var count := int(mix * length)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / mix
		var freq := 1450.0 + 520.0 * t / length + sin(TAU * 34.0 * t) * 90.0
		phase += TAU * freq / mix
		var env := pow(sin(PI * t / length), 1.5)
		out[i] = (sin(phase) + 0.3 * sin(phase * 2.0)) * env * 0.5
	return _wav_from(out)


func _breath_sound() -> AudioStreamWAV:
	var mix := 22050.0
	var length := 3.1
	var count := int(mix * length)
	var out := PackedFloat32Array()
	out.resize(count)
	var a := 0.0
	var b := 0.0
	for i in count:
		var t := float(i) / mix
		var noise := randf_range(-1.0, 1.0)
		var s := 0.0
		if t < 1.15:
			a += (noise - a) * 0.35
			b += (noise - b) * 0.05
			s = (a - b) * pow(sin(PI * t / 1.15), 1.3) * 0.5
		elif t > 1.4 and t < 2.75:
			a += (noise - a) * 0.2
			b += (noise - b) * 0.03
			var u := (t - 1.4) / 1.35
			var rasp := 0.7 + 0.3 * sin(TAU * 41.0 * t)
			s = (a - b) * pow(sin(PI * u), 0.8) * 0.85 * rasp
		out[i] = s
	var wav := _wav_from(out)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	return wav


func _whoosh() -> AudioStreamWAV:
	var mix := 22050.0
	var length := 0.55
	var count := int(mix * length)
	var out := PackedFloat32Array()
	out.resize(count)
	var a := 0.0
	var b := 0.0
	var phase := 0.0
	for i in count:
		var t := float(i) / mix
		var u := t / length
		var noise := randf_range(-1.0, 1.0)
		a += (noise - a) * lerpf(0.55, 0.06, u)
		b += (noise - b) * 0.02
		phase += TAU * lerpf(190.0, 70.0, u) / mix
		var env := (1.0 - exp(-t * 28.0)) * exp(-t * 5.5)
		out[i] = ((a - b) * 0.9 + sin(phase) * 0.35 + sin(phase * 2.0) * 0.2) * env
	return _wav_from(out)


func _wav_from(samples: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.9 / peak
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = data
	return wav
