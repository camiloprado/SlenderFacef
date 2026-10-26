extends CharacterBody3D

const WALK_SPEED := 3.4
const SPRINT_SPEED := 5.6
const CROUCH_SPEED := 1.7
const STAND_EYE := 1.58
const CROUCH_EYE := 0.95
const STAND_HEIGHT := 1.6
const CROUCH_HEIGHT := 0.95
const MOUSE_SENS := 0.0022
const BATTERY_DRAIN := 2.4
const BATTERY_RECHARGE := 6.0

var active := false
var hidden := false
var hide_grace := 0.0
var noise := 0.0
var breath := 4.5
var breath_max := 4.5
var holding_breath := false
var sprinting := false
var crouching := false
var flashlight_on := true
var battery := 100.0
var drain_scale := 1.0

var _yaw := 0.0
var _pitch := 0.0
var _bob := 0.0
var _fear := 0.0
var _slender_dist := 99.0
var _flicker := 0.0
var _eye := STAND_EYE

var camera: Camera3D
var _body: CollisionShape3D
var _capsule: CapsuleShape3D
var light: SpotLight3D


func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.3
	_build()


func _build() -> void:
	_body = CollisionShape3D.new()
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.35
	_capsule.height = STAND_HEIGHT
	_body.shape = _capsule
	_body.position.y = STAND_HEIGHT * 0.5 + 0.05
	add_child(_body)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, STAND_EYE, 0.0)
	camera.fov = 75.0
	camera.current = true
	camera.near = 0.08
	camera.far = 120.0
	add_child(camera)

	light = SpotLight3D.new()
	light.light_color = Color(1.0, 0.94, 0.82)
	light.light_energy = 7.5
	light.spot_range = 24.0
	light.spot_angle = 28.0
	light.spot_attenuation = 0.7
	light.shadow_enabled = true
	light.shadow_bias = 0.05
	light.position = Vector3(0.22, -0.18, 0.0)
	camera.add_child(light)


func get_camera() -> Camera3D:
	return camera


func apply_fear(level: float, slender_dist: float) -> void:
	_fear = level
	_slender_dist = slender_dist


func _unhandled_input(event: InputEvent) -> void:
	if not active or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * MOUSE_SENS
		_pitch -= event.relative.y * MOUSE_SENS
		_pitch = clampf(_pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = _yaw
		camera.rotation.x = _pitch
	elif event.is_action_pressed("flashlight"):
		flashlight_on = not flashlight_on


func _physics_process(delta: float) -> void:
	if holding_breath:
		noise = 0.0
	elif noise > 0.0:
		noise = maxf(noise - delta * 4.5, 0.0)
	if hide_grace > 0.0:
		hide_grace = maxf(hide_grace - delta, 0.0)
	if not active or hidden:
		velocity = Vector3.ZERO
		if crouching:
			_set_crouch(false)
		if hidden:
			_update_flashlight(delta)
		return

	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch != crouching and (wants_crouch or _can_stand()):
		_set_crouch(wants_crouch)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	sprinting = not crouching and Input.is_action_pressed("sprint") and input_dir.length_squared() > 0.1
	var speed := WALK_SPEED
	if crouching:
		speed = CROUCH_SPEED
	elif sprinting:
		speed = SPRINT_SPEED
	velocity.x = wish.x * speed
	velocity.z = wish.z * speed
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	_eye = lerpf(_eye, CROUCH_EYE if crouching else STAND_EYE, minf(delta * 10.0, 1.0))
	var moving := wish.length_squared() > 0.1 and is_on_floor()
	if moving:
		_bob += delta * speed * 1.8
		camera.position.y = _eye + sin(_bob * 2.0) * (0.02 if crouching else 0.035)
	else:
		camera.position.y = lerpf(camera.position.y, _eye, minf(delta * 10.0, 1.0))
	var target_fov := 84.0 if sprinting else 75.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 6.0)

	if _fear > 0.62:
		var shake := (_fear - 0.62) * 0.08
		camera.h_offset = randf_range(-shake, shake)
		camera.v_offset = randf_range(-shake, shake)
	else:
		camera.h_offset = lerpf(camera.h_offset, 0.0, delta * 8.0)
		camera.v_offset = lerpf(camera.v_offset, 0.0, delta * 8.0)

	_update_flashlight(delta)


func _set_crouch(down: bool) -> void:
	crouching = down
	_capsule.height = CROUCH_HEIGHT if down else STAND_HEIGHT
	_body.position.y = _capsule.height * 0.5 + 0.05


func _can_stand() -> bool:
	var tall := CapsuleShape3D.new()
	tall.radius = _capsule.radius - 0.02
	tall.height = STAND_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = tall
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0.0, STAND_HEIGHT * 0.5 + 0.08, 0.0))
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _update_flashlight(delta: float) -> void:
	if flashlight_on and battery > 0.0:
		battery = maxf(battery - BATTERY_DRAIN * drain_scale * delta, 0.0)
	elif not flashlight_on:
		battery = minf(battery + BATTERY_RECHARGE * delta, 100.0)

	light.position.x = 0.0 if hidden else 0.22
	var energy := 0.0
	if flashlight_on and battery > 0.0:
		energy = 7.5
		if battery < 18.0:
			energy *= 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.02))
		if _slender_dist < 6.0 and randf() < delta * 3.5:
			_flicker = 0.08
		if _flicker > 0.0:
			_flicker -= delta
			energy = 0.4
	light.light_energy = energy
	light.visible = energy > 0.2
