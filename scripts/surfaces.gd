class_name Surfaces
extends RefCounted

const ROOT := "res://assets/textures/"

static var _pbr_cache := {}
static var _flat_cache := {}
static var _boxes := {}


class Batch:
	var cell := Vector2(10.0, 12.2)
	var _tools := {}
	var _mats := {}
	var _owners := {}

	func box(parent: Node3D, size: Vector3, xform: Transform3D, mat: Material) -> void:
		add(parent, Surfaces.box_mesh(size), xform, mat)

	func add(parent: Node3D, mesh: Mesh, xform: Transform3D, mat: Material) -> void:
		var key := "%d|%d" % [parent.get_instance_id(), mat.get_instance_id()]
		if cell != Vector2.ZERO:
			key += "|%d|%d" % [floori(xform.origin.x / cell.x), floori(xform.origin.z / cell.y)]
		var st: SurfaceTool = _tools.get(key)
		if st == null:
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_tools[key] = st
			_mats[key] = mat
			_owners[key] = parent
		st.append_from(mesh, 0, xform)

	func flush() -> void:
		for key in _tools:
			var node := MeshInstance3D.new()
			node.mesh = (_tools[key] as SurfaceTool).commit()
			node.material_override = _mats[key]
			(_owners[key] as Node3D).add_child(node)
		_tools.clear()
		_mats.clear()
		_owners.clear()


static func box_mesh(size: Vector3) -> BoxMesh:
	var key := "%.4f|%.4f|%.4f" % [size.x, size.y, size.z]
	if _boxes.has(key):
		return _boxes[key]
	var box := BoxMesh.new()
	box.size = size
	_boxes[key] = box
	return box


static func tex(set_name: String, map: String) -> Texture2D:
	var path := "%s%s/%s_%s.jpg" % [ROOT, set_name, set_name, map]
	if not ResourceLoader.exists(path):
		return null
	return load(path)


static func pbr(set_name: String, tint := Color.WHITE, scale := 1.0, metal := 0.0, rough := 1.0, bump := 1.0, world := true) -> ShaderMaterial:
	var key := "%s|%s|%.3f|%.2f|%.2f|%.2f|%s" % [set_name, tint.to_html(), scale, metal, rough, bump, world]
	if _pbr_cache.has(key):
		return _pbr_cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/box_pbr.gdshader")
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("albedo_tex", tex(set_name, "Color"))
	mat.set_shader_parameter("normal_tex", tex(set_name, "NormalGL"))
	mat.set_shader_parameter("rough_tex", tex(set_name, "Roughness"))
	var metal_map := tex(set_name, "Metalness")
	if metal_map:
		mat.set_shader_parameter("metal_tex", metal_map)
	mat.set_shader_parameter("scale", scale)
	mat.set_shader_parameter("metal", metal)
	mat.set_shader_parameter("rough", rough)
	mat.set_shader_parameter("bump", bump)
	mat.set_shader_parameter("local_space", not world)
	_pbr_cache[key] = mat
	return mat


static func tiled(set_name: String, tint: Color, repeat: Vector2, metal := 0.0, rough := 1.0, bump := 1.0) -> StandardMaterial3D:
	var mat := _maps(set_name, tint, metal, rough, bump)
	mat.uv1_scale = Vector3(repeat.x, repeat.y, 1.0)
	return mat


static func _maps(set_name: String, tint: Color, metal: float, rough: float, bump: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = tex(set_name, "Color")
	var normal := tex(set_name, "NormalGL")
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
		mat.normal_scale = bump
	var rough_map := tex(set_name, "Roughness")
	mat.roughness = rough
	if rough_map:
		mat.roughness_texture = rough_map
	var metal_map := tex(set_name, "Metalness")
	mat.metallic = metal
	if metal_map and metal > 0.0:
		mat.metallic_texture = metal_map
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


static func flat(color: Color, rough := 0.86, metal := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), rough, metal]
	if _flat_cache.has(key):
		return _flat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	_flat_cache[key] = mat
	return mat
