extends Node3D

const PLUSH := preload("res://shaders/plush.gdshader")
const WAIST := 0.62
const HIP := 0.28
const ANKLE := 0.05
const STRIDE := 0.34
const LIFT := 0.07
const BLEND_TIME := 0.35

const HAIR: Array[Color] = [
	Color(0.06, 0.04, 0.03), Color(0.2, 0.12, 0.06), Color(0.42, 0.26, 0.12),
	Color(0.7, 0.55, 0.3), Color(0.12, 0.08, 0.06),
]

var _rng := RandomNumberGenerator.new()
var _rig: Node3D
var _torso: Node3D
var _head: Node3D
var _skirt: MeshInstance3D
var _arms: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _feet: Array[Node3D] = []
var _last := Vector3.ZERO
var _has_last := false
var _speed := 0.0
var _step_goal := 0.0
var ground: Callable

var _time := 0.0
var _seed := 0.0
var _action := "idle"
var _from: Array = []
var _blend := 1.0
var _custom: Array = [Vector3.ZERO, Vector3.ZERO, 0.25, 0.25]
var _walk_phase := 0.0
var _walk := 0.0
var _lean_goal := Vector3.ZERO
var _lean := Vector3.ZERO
var _look_point := Vector3.ZERO
var _look_goal := 0.0
var _look_weight := 0.0
var _look := Vector2.ZERO
var _hop_goal := 0.0
var _hop := 0.0
var _sway := 0.0


func setup(skin: Color, stole: Color, seed_value: int, rector := false) -> void:
	_rng.seed = seed_value
	_seed = _rng.randf() * TAU
	var gown_color := Color(0.42, 0.06, 0.08) if rector else Color(0.07, 0.075, 0.1)
	var gown := _cloth(gown_color, 0.78)
	var lining := _cloth(stole.darkened(0.15), 0.6)
	var stole_mat := _cloth(stole, 0.55)
	var gold := _shiny(Color(0.85, 0.66, 0.22), 0.35, 0.7)
	var skin_mat := _skin(skin)
	var hair_color := HAIR[_rng.randi() % HAIR.size()]
	var hair := _cloth(hair_color, 0.65)

	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)

	var trousers := _cloth(Color(0.05, 0.05, 0.06), 0.8)
	var polish := _shiny(Color(0.05, 0.05, 0.06), 0.14, 0.7)
	var sole := _cloth(Color(0.02, 0.02, 0.02), 0.9)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.name = "LegL" if side < 0.0 else "LegR"
		leg.position = Vector3(side * 0.07, HIP, 0.0)
		_rig.add_child(leg)
		_legs.append(leg)
		var shin := HIP - ANKLE
		_capsule(leg, 0.045, shin, Vector3(0.0, -shin * 0.5, 0.0), trousers)
		var foot := Node3D.new()
		foot.name = "FootL" if side < 0.0 else "FootR"
		foot.position = Vector3(side * 0.07, 0.0, 0.0)
		add_child(foot)
		_feet.append(foot)
		_blob(foot, Vector3(0.05, 0.032, 0.1), Vector3(0.0, 0.032, 0.035), polish)
		_box(foot, Vector3(0.09, 0.012, 0.19), Vector3(0.0, 0.006, 0.03), sole)

	_skirt = MeshInstance3D.new()
	_skirt.name = "Saia"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.16
	cone.bottom_radius = 0.27
	cone.height = 0.78
	cone.radial_segments = 40
	_skirt.mesh = cone
	_skirt.position = Vector3(0.0, 0.57, 0.0)
	_skirt.scale = Vector3(1.0, 1.0, 0.82)
	_skirt.material_override = gown
	_rig.add_child(_skirt)
	for i in 7:
		var a := -0.9 + float(i) * 0.3
		var outward := Vector3(sin(a), 0.0, cos(a))
		var pleat := _capsule(_skirt, 0.012, 0.7, outward * 0.205 + Vector3(0.0, -0.02, 0.0), gown)
		var up := (Vector3.UP * cone.height - outward * (cone.bottom_radius - cone.top_radius)).normalized()
		var side := up.cross(outward).normalized()
		pleat.basis = Basis(side, up, side.cross(up))

	_torso = Node3D.new()
	_torso.name = "Torso"
	_torso.position = Vector3(0.0, WAIST, 0.0)
	_rig.add_child(_torso)
	var w := Vector3(0.0, WAIST, 0.0)
	_blob(_torso, Vector3(0.17, 0.2, 0.13), Vector3(0.0, 0.12, 0.0), gown)
	_blob(_torso, Vector3(0.21, 0.15, 0.15), Vector3(0.0, 0.94, 0.0) - w, gown)
	_blob(_torso, Vector3(0.04, 0.28, 0.02), Vector3(0.0, 0.72, 0.148) - w, lining)
	for side in [-1.0, 1.0]:
		var band := _box(_torso, Vector3(0.06, 0.5, 0.01), Vector3(side * 0.065, 0.8, 0.142) - w, stole_mat)
		band.rotation = Vector3(-0.06, 0.0, -side * 0.18)
		_box(band, Vector3(0.008, 0.5, 0.012), Vector3(side * 0.03, 0.0, 0.0), gold)
		_box(_torso, Vector3(0.07, 0.025, 0.012), Vector3(side * 0.11, 0.56, 0.158) - w, gold)
	_blob(_torso, Vector3(0.11, 0.03, 0.1), Vector3(0.0, 1.02, 0.02) - w, _cloth(Color(0.93, 0.92, 0.88), 0.6))
	if rector:
		var medal := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.035
		disc.bottom_radius = 0.035
		disc.height = 0.01
		medal.mesh = disc
		medal.rotation.x = PI / 2.0
		medal.position = Vector3(0.0, 0.84, 0.205) - w
		medal.material_override = gold
		_torso.add_child(medal)
		var chain := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.1
		ring.outer_radius = 0.115
		chain.mesh = ring
		chain.position = Vector3(0.0, 0.98, 0.04) - w
		chain.rotation.x = 0.5
		chain.material_override = gold
		_torso.add_child(chain)

	for side in [-1.0, 1.0]:
		_build_arm(side, gown, stole_mat, skin_mat)

	_capsule(_torso, 0.042, 0.1, Vector3(0.0, 1.06, 0.0) - w, skin_mat)
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 1.18, 0.02) - w
	_torso.add_child(_head)
	_build_head(skin, skin_mat, hair, hair_color, gold)
	_from = _pose_for("idle")


func _build_arm(side: float, gown: Material, stole_mat: Material, skin_mat: Material) -> void:
	var arm := Node3D.new()
	arm.name = "ArmL" if side < 0.0 else "ArmR"
	arm.position = Vector3(side * 0.2, 0.97 - WAIST, 0.0)
	_torso.add_child(arm)
	_arms.append(arm)
	_blob(arm, Vector3(0.065, 0.065, 0.065), Vector3.ZERO, gown)
	var upper := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.05
	tube.bottom_radius = 0.064
	tube.height = 0.21
	tube.radial_segments = 24
	upper.mesh = tube
	upper.position = Vector3(side * 0.006, -0.1, 0.0)
	upper.material_override = gown
	arm.add_child(upper)
	var elbow := Node3D.new()
	elbow.name = "Elbow"
	elbow.position = Vector3(side * 0.012, -0.2, 0.0)
	arm.add_child(elbow)
	_elbows.append(elbow)
	_blob(elbow, Vector3(0.064, 0.06, 0.064), Vector3.ZERO, gown)
	var sleeve := MeshInstance3D.new()
	var bell := CylinderMesh.new()
	bell.top_radius = 0.064
	bell.bottom_radius = 0.088
	bell.height = 0.17
	bell.radial_segments = 28
	sleeve.mesh = bell
	sleeve.position = Vector3(side * 0.006, -0.08, 0.0)
	sleeve.material_override = gown
	elbow.add_child(sleeve)
	var cuff := MeshInstance3D.new()
	var cuff_ring := TorusMesh.new()
	cuff_ring.inner_radius = 0.07
	cuff_ring.outer_radius = 0.088
	cuff.mesh = cuff_ring
	cuff.position = Vector3(side * 0.012, -0.155, 0.0)
	cuff.material_override = stole_mat
	elbow.add_child(cuff)
	var hand := Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(side * 0.018, -0.205, 0.02)
	elbow.add_child(hand)
	_blob(hand, Vector3(0.035, 0.045, 0.028), Vector3.ZERO, skin_mat)
	var thumb := _capsule(hand, 0.012, 0.045, Vector3(-side * 0.025, 0.005, 0.02), skin_mat)
	thumb.rotation.z = side * 0.6


func _build_head(skin: Color, skin_mat: Material, hair: Material, hair_color: Color, gold: Material) -> void:
	_blob(_head, Vector3(0.105, 0.12, 0.105), Vector3.ZERO, skin_mat)
	_blob(_head, Vector3(0.08, 0.05, 0.07), Vector3(0.0, -0.06, 0.03), skin_mat)
	for side in [-1.0, 1.0]:
		_blob(_head, Vector3(0.018, 0.028, 0.014), Vector3(side * 0.103, -0.005, 0.0), skin_mat)
	_blob(_head, Vector3(0.112, 0.07, 0.112), Vector3(0.0, 0.055, -0.012), hair)
	_blob(_head, Vector3(0.1, 0.1, 0.06), Vector3(0.0, 0.0, -0.06), hair)
	if _rng.randf() < 0.45:
		_blob(_head, Vector3(0.1, 0.13, 0.05), Vector3(0.0, -0.08, -0.07), hair)

	var white := _shiny(Color(0.95, 0.95, 0.93), 0.3, 0.0)
	var iris := _shiny(Color(0.18, 0.11, 0.06).lerp(Color(0.15, 0.3, 0.4), _rng.randf() * 0.5), 0.15, 0.0)
	var brow := _cloth(hair_color.darkened(0.2), 0.7)
	for side in [-1.0, 1.0]:
		_blob(_head, Vector3(0.022, 0.026, 0.01), Vector3(side * 0.038, 0.012, 0.096), white)
		_blob(_head, Vector3(0.012, 0.015, 0.006), Vector3(side * 0.037, 0.01, 0.105), iris)
		var arch := _box(_head, Vector3(0.036, 0.008, 0.01), Vector3(side * 0.04, 0.045, 0.1), brow)
		arch.rotation.z = -side * 0.12
		_blob(_head, Vector3(0.018, 0.01, 0.006), Vector3(side * 0.058, -0.03, 0.093), _cloth(skin.lerp(Color(0.9, 0.4, 0.4), 0.35), 0.8))
	_blob(_head, Vector3(0.013, 0.018, 0.014), Vector3(0.0, -0.012, 0.11), skin_mat)
	var smile := MeshInstance3D.new()
	var arc := TorusMesh.new()
	arc.inner_radius = 0.022
	arc.outer_radius = 0.028
	smile.mesh = arc
	smile.position = Vector3(0.0, -0.035, 0.1)
	smile.rotation = Vector3(PI / 2.0 - 0.2, 0.0, 0.0)
	smile.scale = Vector3(1.0, 1.0, 0.5)
	smile.material_override = _cloth(Color(0.45, 0.15, 0.15), 0.7)
	_head.add_child(smile)

	var cap_mat := _cloth(Color(0.04, 0.045, 0.06), 0.55)
	var cap := Node3D.new()
	cap.name = "Capelo"
	cap.position = Vector3(0.0, 0.1, -0.01)
	cap.rotation = Vector3(-0.08, _rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.06, 0.06))
	_head.add_child(cap)
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


func hand(right := true) -> Node3D:
	return _elbows[1 if right else 0].get_node("Hand") as Node3D


func head_node() -> Node3D:
	return _head


func act(action: String) -> void:
	if action == _action:
		return
	_from = _current_pose()
	_action = action
	_blend = 0.0


func set_arms(left: Vector3, right: Vector3, elbow_left := 0.25, elbow_right := 0.25) -> void:
	_custom = [left, right, elbow_left, elbow_right]
	act("custom")


func set_step(amount: float) -> void:
	_step_goal = amount


func set_lean(lean: Vector3) -> void:
	_lean_goal = lean


func set_hop(height: float) -> void:
	_hop_goal = height


func set_sway(amount: float) -> void:
	_sway = amount


func look_at_point(point: Vector3, weight := 1.0) -> void:
	_look_point = point
	_look_goal = weight


func _process(delta: float) -> void:
	if _torso == null:
		return
	_time += delta
	_blend = minf(_blend + delta / BLEND_TIME, 1.0)
	var soft := 1.0 - exp(-delta * 7.0)
	_lean = _lean.lerp(_lean_goal, soft)
	_hop = lerpf(_hop, _hop_goal, 1.0 - exp(-delta * 14.0))
	_look_weight = lerpf(_look_weight, _look_goal, 1.0 - exp(-delta * 4.0))
	_update_feet(delta, soft)

	var stride := sin(_walk_phase)
	var breath := sin(_time * 1.7 + _seed)
	_skirt.rotation.z = _sway + stride * 0.05 * _walk
	_skirt.rotation.x = -_walk * 0.06

	_torso.position.y = WAIST + breath * 0.004
	_torso.rotation = _lean + Vector3(
		breath * 0.012 + _walk * 0.05,
		stride * 0.09 * _walk + sin(_time * 0.45 + _seed) * 0.03,
		sin(_time * 0.6 + _seed * 1.3) * 0.02 - stride * 0.03 * _walk)

	var aim := Vector2(sin(_time * 0.5 + _seed * 2.0) * 0.12, sin(_time * 0.8 + _seed) * 0.05)
	if _look_weight > 0.01:
		var to := _torso.to_local(_look_point) - _head.position
		var flat := Vector2(to.x, to.z).length()
		var target := Vector2(clampf(atan2(to.x, to.z), -1.2, 1.2), clampf(-atan2(to.y, flat), -0.6, 0.5))
		aim = aim.lerp(target, _look_weight)
	_look = _look.lerp(aim, 1.0 - exp(-delta * 6.0))
	var twist := clampf(_look.x * 0.3, -0.3, 0.3)
	_torso.rotation.y += twist
	_head.rotation = Vector3(_look.y + sin(_time * 1.1 + _seed) * 0.02, _look.x - twist, sin(_time * 0.7 + _seed) * 0.04)

	var pose := _pose_for(_action)
	if _blend < 1.0:
		var k := smoothstep(0.0, 1.0, _blend)
		pose = [
			(_from[0] as Vector3).lerp(pose[0], k), (_from[1] as Vector3).lerp(pose[1], k),
			lerpf(_from[2], pose[2], k), lerpf(_from[3], pose[3], k),
		]
	var swing := stride * 0.42 * _walk
	_arms[0].rotation = (pose[0] as Vector3) + Vector3(swing, 0.0, 0.0)
	_arms[1].rotation = (pose[1] as Vector3) + Vector3(-swing, 0.0, 0.0)
	_elbows[0].rotation = Vector3(-float(pose[2]) - maxf(swing, 0.0) * 0.4, 0.0, 0.0)
	_elbows[1].rotation = Vector3(-float(pose[3]) - maxf(-swing, 0.0) * 0.4, 0.0, 0.0)


func _update_feet(delta: float, soft: float) -> void:
	var here := global_position
	var moved := 0.0
	if _has_last:
		moved = minf(Vector2(here.x - _last.x, here.z - _last.z).length(), 0.05)
	_last = here
	_has_last = true
	_speed = lerpf(_speed, moved / maxf(delta, 0.001), soft)
	var travel := clampf(_speed / 0.4, 0.0, 1.0)
	_walk = lerpf(_walk, maxf(travel, _step_goal), soft)
	_walk_phase += moved / STRIDE * PI
	if travel < 0.3:
		_walk_phase += _step_goal * delta * 7.0
	var reach := lerpf(0.03, STRIDE * 0.5, travel) * _walk
	_rig.position.y = _hop + (1.0 - absf(cos(_walk_phase))) * 0.012 * _walk
	for i in 2:
		var p := fposmod(_walk_phase + (PI if i == 1 else 0.0), TAU)
		var foot := _feet[i]
		var z := 0.0
		var lift := 0.0
		var floor_y := 0.0
		if p < PI:
			z = lerpf(reach, -reach, p / PI)
			floor_y = _floor_at(foot.position.x, z)
		else:
			var s := (p - PI) / PI
			var glide := smoothstep(0.0, 1.0, s)
			z = lerpf(-reach, reach, glide)
			var from_y := _floor_at(foot.position.x, -reach)
			var to_y := _floor_at(foot.position.x, reach)
			floor_y = lerpf(from_y, to_y, smoothstep(0.1, 0.7, s))
			lift = sin(s * PI) * (LIFT * _walk + maxf(to_y - from_y, 0.0) * 0.5)
		foot.position = Vector3(foot.position.x, floor_y + lift + _hop, z)
		foot.rotation.x = -lift * 2.2
		var leg := _legs[i]
		var hip := _rig.position + leg.position
		var span := foot.position + Vector3(0.0, ANKLE, 0.02) - hip
		leg.rotation.x = -atan2(span.z, -span.y)
		leg.scale.y = span.length() / (HIP - ANKLE)


func _floor_at(x: float, z: float) -> float:
	if not ground.is_valid():
		return 0.0
	return float(ground.call(to_global(Vector3(x, 0.0, z + 0.03)))) - global_position.y


func _current_pose() -> Array:
	if _arms.is_empty():
		return _pose_for("idle")
	return [_arms[0].rotation, _arms[1].rotation, -_elbows[0].rotation.x, -_elbows[1].rotation.x]


func _pose_for(action: String) -> Array:
	var t := _time
	var idle := sin(t * 1.3 + _seed) * 0.04
	match action:
		"custom":
			return _custom
		"clap":
			var beat := sin(t * 13.0 + _seed)
			return [
				Vector3(-0.95, 0.0, 0.32 + beat * 0.16), Vector3(-0.95, 0.0, -0.32 - beat * 0.16),
				1.15 + beat * 0.08, 1.15 + beat * 0.08,
			]
		"wave":
			var wave := sin(t * 8.0 + _seed)
			return [
				Vector3(0.05 + idle, 0.0, -0.14), Vector3(-0.25, 0.0, 2.45 + wave * 0.22),
				0.3, 0.55 + wave * 0.25,
			]
		"cheer":
			var pump := sin(t * 7.0 + _seed)
			return [
				Vector3(-0.2, 0.0, -2.5 - pump * 0.2), Vector3(-0.2, 0.0, 2.5 + pump * 0.2),
				0.35 + pump * 0.2, 0.35 + pump * 0.2,
			]
		"polite":
			var beat := sin(t * 9.0 + _seed)
			return [
				Vector3(-0.6, 0.0, 0.28 + beat * 0.1), Vector3(-0.6, 0.0, -0.28 - beat * 0.1),
				1.25, 1.25,
			]
	return [Vector3(0.05 + idle, 0.0, -0.12), Vector3(0.05 - idle, 0.0, 0.12), 0.22, 0.22]


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
