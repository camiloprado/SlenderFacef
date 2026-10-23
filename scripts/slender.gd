extends CharacterBody3D

signal player_caught(reason: String)

var active := false
var aggression := 0.12
var static_level := 0.0
var held := false
var watch_behind := false
var relentless := false
var speed_scale := 1.0
var sense_scale := 1.0
var move_while_watched := 0.0
var static_scale := 1.0
var catch_distance := 1.45
var mind := "rondando"
var venting := false

var presence := 0.0
var behind := 0.0

var _player: CharacterBody3D
var _static_hold := 0.0
var _known := Vector3.ZERO
var _known_valid := false
var _seen := 0.0
var _mode := "patrol"
var _search_point := Vector3.ZERO
var _search_time := 0.0
var _patrol_i := 0
var _patrol_ready := false
var _sees := false
var _hears := false
var _vent_phase := ""
var _vent_time := 0.0
var _vent_lockout := 0.0
var _vent_entry: Node3D
var _vent_exit: Node3D
var _vent_path := PackedVector3Array()
var _vent_cursor := 0
var _vent_from := Vector3.ZERO
var _vent_stuck := 0.0
var _vent_best := 9999.0
var _patrol: Array[Vector3] = [
	Vector3(0.0, 0.1, -52.0),
	Vector3(0.0, 0.1, -32.0),
	Vector3(0.0, 0.1, -12.0),
	Vector3(0.0, 0.1, 4.0),
]
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
			sense_scale += 0.7
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
	_update_mind(delta)
	if _vent_lockout > 0.0:
		_vent_lockout = maxf(_vent_lockout - delta, 0.0)
	if not venting:
		_try_vent()
	if venting:
		_update_vent(delta)
		if venting:
			if _god_mode():
				static_level = minf(static_level, 0.2)
				_static_hold = 0.0
			return
	var speed := _pace(dist)
	if _hears and _player.sprinting:
		speed *= 1.1
	if staring and not relentless:
		speed *= move_while_watched
	if watch_behind and not _hunting() and _is_in_front() and (not staring or relentless):
		speed = maxf(speed, lerpf(3.6, 5.4, aggression) * speed_scale)
	var dir := _chase_direction()
	if speed <= 0.05 or dir == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, delta * 24.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 24.0)
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	_describe(speed, staring)

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	_face_along(dir, staring)
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


func hear(at: Vector3) -> void:
	_known = at
	_known.y = 0.1
	_known_valid = true
	_mode = "hunt"
	_search_time = 0.0


func _update_mind(delta: float) -> void:
	if not _patrol_ready:
		_patrol_ready = true
		_patrol_i = _nearest_patrol()
	_sees = _can_see_player()
	var hear_reach := _hearing_range()
	var muffled: bool = _player.hidden and bool(_player.get("holding_breath"))
	_hears = not muffled and hear_reach > 0.4 and _flat_distance() <= hear_reach
	if _sees:
		_seen = 2.4
		_mark(_player.global_position)
		_mode = "hunt"
	elif _hears:
		_mark(_player.global_position)
		_mode = "hunt"
		_seen = maxf(_seen - delta, 0.0)
	else:
		_seen = maxf(_seen - delta, 0.0)
	if _mode == "hunt" and _seen <= 0.0 and _known_valid and _arrived(_known):
		_mode = "search"
		_search_time = 0.0
		_search_point = _pick_around(_known, 5.0)
	if _mode == "search":
		_search_time += delta
		if _arrived(_search_point):
			var radius := lerpf(4.0, 9.0, clampf(_search_time / 8.0, 0.0, 1.0))
			_search_point = _pick_around(_known, radius)
		if _search_time > 9.5:
			_mode = "patrol"
			_patrol_i = _nearest_patrol()
	elif _mode == "patrol" and _arrived(_patrol[_patrol_i]):
		_patrol_i = (_patrol_i + 1) % _patrol.size()


func _try_vent() -> void:
	if _vent_lockout > 0.0 or _sees or get_parent() == null:
		return
	var game := get_parent()
	if not game.has_method("vent_shortcut"):
		return
	var route: Dictionary = game.vent_shortcut(global_position, _goal_position(), _player.global_position)
	if route.is_empty():
		return
	venting = true
	_vent_phase = "approach"
	_vent_time = 0.0
	_vent_entry = route["entry"]
	_vent_exit = route["exit"]
	_vent_path = route["path"]
	_vent_cursor = 0
	_vent_stuck = 0.0
	_vent_best = 9999.0
	mind = "no duto"


func _update_vent(delta: float) -> void:
	mind = "no duto"
	if _vent_entry == null or _vent_exit == null:
		venting = false
		return
	if _vent_phase == "approach":
		if _sees:
			venting = false
			_vent_lockout = 1.5
			return
		var stand: Vector3 = _vent_entry.stand_global()
		var gap := _flat_to(stand)
		if gap < 0.85:
			velocity = Vector3.ZERO
			_face_point(_vent_entry.inside_global())
			_vent_phase = "reach"
			_vent_time = 0.0
			_vent_stuck = 0.0
		else:
			if gap < _vent_best - 0.15:
				_vent_best = gap
				_vent_stuck = 0.0
			else:
				_vent_stuck += delta
			if _vent_stuck > 1.4:
				venting = false
				_vent_lockout = 2.0
				_costume.set_reach(0.0)
				return
			_step_toward(stand, _pace(_flat_distance()), delta)
		return
	if _vent_phase == "reach":
		velocity = Vector3.ZERO
		_vent_time += delta
		_costume.set_reach(clampf(_vent_time / 0.55, 0.0, 1.0))
		if _vent_time >= 0.55:
			_vent_phase = "open"
			_vent_time = 0.0
			_vent_entry.open_grate()
		return
	if _vent_phase == "open":
		_vent_time += delta
		if _vent_time >= 0.35:
			_vent_phase = "climb"
			_vent_time = 0.0
			_vent_from = global_position
			_set_body_collision(true)
		return
	if _vent_phase == "climb":
		_vent_time += delta
		var climb := clampf(_vent_time / 0.45, 0.0, 1.0)
		global_position = _vent_from.lerp(_vent_entry.inside_global(), climb)
		_costume.set_reach(1.0 - climb)
		if climb >= 1.0:
			_vent_entry.close_grate()
			visible = false
			_vent_phase = "ride"
			_vent_cursor = 0
			if not _vent_path.is_empty():
				global_position = _vent_path[0]
		return
	if _vent_phase == "ride":
		if _ride_path(delta):
			_vent_phase = "exit"
			_vent_time = 0.0
			visible = true
			global_position = _vent_exit.inside_global()
			_costume.set_reach(1.0)
			_vent_exit.open_grate()
		return
	if _vent_phase == "exit":
		_vent_time += delta
		if _vent_time >= 0.35:
			_vent_phase = "drop"
			_vent_time = 0.0
			_vent_from = global_position
		return
	_vent_time += delta
	var drop := clampf(_vent_time / 0.45, 0.0, 1.0)
	var land: Vector3 = _vent_exit.stand_global()
	global_position = _vent_from.lerp(land, drop)
	_costume.set_reach(1.0 - drop)
	if drop < 1.0:
		return
	_vent_exit.close_grate()
	_set_body_collision(false)
	visible = true
	venting = false
	_vent_lockout = 2.5
	_costume.set_reach(0.0)
	global_position = land
	velocity = Vector3.ZERO


func _step_toward(point: Vector3, speed: float, delta: float) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.04:
		velocity.x = move_toward(velocity.x, 0.0, delta * 24.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 24.0)
		dir = Vector3.ZERO
	else:
		dir = _steer(dir.normalized())
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	_face_along(dir, false)
	var moved := Vector2(velocity.x, velocity.z).length()
	_costume.walk(delta, moved)


func _ride_path(delta: float) -> bool:
	var left := 9.0 * delta
	while left > 0.0 and _vent_cursor < _vent_path.size():
		var target: Vector3 = _vent_path[_vent_cursor]
		var offset := target - global_position
		var gap := offset.length()
		if gap <= left:
			global_position = target
			left -= gap
			_vent_cursor += 1
		else:
			global_position += offset / gap * left
			left = 0.0
	_stride += 9.0 * delta
	if _stride > 0.95:
		_stride = 0.0
		_play_step()
	return _vent_cursor >= _vent_path.size()


func _flat_to(point: Vector3) -> float:
	var here := global_position
	var there := point
	here.y = 0.0
	there.y = 0.0
	return here.distance_to(there)


func _face_point(point: Vector3) -> void:
	var flat := point - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.001:
		return
	look_at(global_position + flat, Vector3.UP)


func _set_body_collision(disabled: bool) -> void:
	var shape := get_node_or_null("Collision") as CollisionShape3D
	if shape:
		shape.disabled = disabled


func _pace(dist: float) -> float:
	var far_boost := 1.0 + maxf(sense_scale - 1.0, 0.0) * 0.35
	var far_speed := lerpf(5.8, 7.4, aggression) * speed_scale * far_boost
	var creep := lerpf(1.2, 1.9, aggression) * speed_scale
	var charge := lerpf(4.8, 6.5, aggression) * speed_scale
	var commit := _sees and not (watch_behind and not _hunting())
	var close := charge if commit else creep
	if dist >= 16.0:
		return far_speed
	if dist <= 7.0:
		return close
	return lerpf(close, far_speed, (dist - 7.0) / 9.0)


func _describe(speed: float, staring: bool) -> void:
	if staring and not relentless and speed < 0.25:
		mind = "parado na luz"
	elif watch_behind and not _hunting() and (_sees or _hears or _seen > 0.0):
		mind = "atrás de você"
	elif _sees and _flat_distance() < 7.0:
		mind = "investindo"
	elif _mode == "search":
		mind = "procurando"
	elif _flat_distance() > 16.0:
		mind = "correndo"
	elif _flat_distance() < 7.0:
		mind = "espreitando"
	else:
		mind = "aproximando"


func _mark(at: Vector3) -> void:
	_known = at
	_known.y = 0.1
	_known_valid = true


func _goal_position() -> Vector3:
	var trailing := watch_behind and not _hunting() and (_sees or _hears or _seen > 0.0)
	if trailing:
		return _behind_spot(_follow_distance())
	if _seen > 0.0:
		return _player.global_position
	if _mode == "hunt" and _known_valid:
		return _known
	if _mode == "search":
		return _search_point
	return _patrol[_patrol_i]


func _chase_direction() -> Vector3:
	var goal := _goal_position()
	var trailing := watch_behind and not _hunting() and (_sees or _hears or _seen > 0.0)
	if trailing and _flat_distance() < _follow_distance() - 0.3 and not _is_in_front():
		return Vector3.ZERO
	var dir := goal - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.16:
		return Vector3.ZERO
	return _steer(dir.normalized())


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


func _arrived(point: Vector3) -> bool:
	var here := global_position
	var goal := point
	here.y = 0.0
	goal.y = 0.0
	return here.distance_to(goal) < 1.35


func _pick_around(origin: Vector3, radius: float) -> Vector3:
	for _i in 8:
		var ang := randf() * TAU
		var pos := origin + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(radius * 0.45, radius)
		pos.y = 0.1
		if _walkable(pos):
			return pos
	return origin


func _nearest_patrol() -> int:
	var best := 0
	var best_d := 9999.0
	for i in _patrol.size():
		var gap := global_position.distance_to(_patrol[i])
		if gap < best_d:
			best_d = gap
			best = i
	return best


func _hearing_range() -> float:
	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var reach := 0.0
	if _player.hidden:
		speed = 0.0
	if speed > 4.8:
		reach = lerpf(16.0, 22.0, aggression)
	elif speed > 0.45:
		reach = lerpf(7.0, 10.5, aggression)
	reach += float(_player.get("noise"))
	return reach * sense_scale


func _can_see_player() -> bool:
	if _player.hidden:
		return false
	var eye := global_position + Vector3(0.0, 1.7, 0.0)
	var chest := _player.global_position + Vector3(0.0, 1.2, 0.0)
	var to := chest - eye
	var gap := to.length()
	if gap < 0.2 or gap > 26.0:
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	var flat := Vector3(to.x, 0.0, to.z)
	if forward.length_squared() < 0.001 or flat.length_squared() < 0.001:
		return false
	if forward.normalized().dot(flat.normalized()) < 0.2:
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var query := PhysicsRayQueryParameters3D.create(eye, chest)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.collider == _player


func _steer(dir: Vector3) -> Vector3:
	if _clearance(dir) >= 1.25:
		return dir
	var side := dir.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		return dir
	side = side.normalized()
	var left := (dir * 0.25 - side).normalized()
	var right := (dir * 0.25 + side).normalized()
	if _clearance(left) >= _clearance(right):
		return left
	return right


func _clearance(dir: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return 2.4
	var from := global_position + Vector3(0.0, 1.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 2.4)
	query.exclude = [get_rid(), _player.get_rid()]
	query.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return 2.4
	var point: Vector3 = hit.position
	return from.distance_to(point)


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


func _face_along(dir: Vector3, staring: bool) -> void:
	if _sees or staring:
		_face_player()
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length_squared() < 0.04:
		flat = dir
	if flat.length_squared() < 0.001:
		return
	look_at(global_position + flat, Vector3.UP)


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
