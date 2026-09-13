extends RefCounted
## Original, procedural sky-foundry scenery and machine silhouettes.
## All actors face +Z and have their origin at ground level.

static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}

const PALETTE: Dictionary = {
	"deck": Color("344653"),
	"deck_alt": Color("30414f"),
	"seam": Color("152430"),
	"steel": Color("202d3d"),
	"edge": Color("526778"),
	"dark": Color("101b2b"),
	"distant": Color("182337"),
	"teal_dim": Color("237881"),
	"teal": Color("3bd7db"),
	"cyan": Color("72f7ff"),
	"white": Color("e2f4f3"),
	"white_shadow": Color("94b9c6"),
	"amber": Color("edb256"),
	"orange": Color("f78239"),
	"hot": Color("ffdf99"),
	"magenta": Color("e8498c"),
	"pink": Color("ff93be"),
	"purple": Color("6961a1"),
	"violet": Color("bc98f7"),
	"ceramic": Color("d9eeed"),
	"titanium": Color("73919c"),
	"visor": Color("052d39"),
	"solar": Color("ffc56a"),
	"storm": Color("ae82f4"),
	"deck_deep": Color("233744"),
	"deck_mark": Color("6e929e"),
	"solar_dim": Color("847259"),
	"storm_dim": Color("655780"),
}


static func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var result: StandardMaterial3D = StandardMaterial3D.new()
	result.albedo_color = PALETTE.get(key, Color.WHITE)
	result.roughness = 0.78
	result.metallic = 0.24
	if key in ["dark", "steel", "edge"]:
		result.metallic = 0.55
		result.roughness = 0.63
	if key in ["teal", "cyan", "hot", "pink", "violet"]:
		result.emission_enabled = true
		result.emission = result.albedo_color
		result.emission_energy_multiplier = 1.3 if key == "teal" else 1.8
	if key == "teal_dim":
		result.emission_enabled = true
		result.emission = result.albedo_color
		result.emission_energy_multiplier = 0.35
	if key == "ceramic":
		result.roughness = 0.32
		result.metallic = 0.18
	if key in ["titanium", "visor"]:
		result.roughness = 0.26
		result.metallic = 0.72
	if key in ["solar", "storm"]:
		result.emission_enabled = true
		result.emission = result.albedo_color
		result.emission_energy_multiplier = 1.4
	_materials[key] = result
	return result


static func _mesh(key: String) -> Mesh:
	if _meshes.has(key):
		return _meshes[key] as Mesh
	var result: Mesh
	match key:
		"armor":
			result = _chamfered_box()
		"wing":
			result = _wing_mesh()
		"cylinder", "octagon", "cone":
			var cylinder: CylinderMesh = CylinderMesh.new()
			cylinder.top_radius = 0.68 if key == "cone" else 1.0
			cylinder.bottom_radius = 1.0
			cylinder.height = 1.0
			cylinder.radial_segments = 8 if key == "octagon" else 12
			cylinder.rings = 1
			result = cylinder
		"sphere":
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			sphere.radial_segments = 12
			sphere.rings = 6
			result = sphere
		"prism":
			var prism: PrismMesh = PrismMesh.new()
			prism.size = Vector3.ONE
			result = prism
		_:
			var box: BoxMesh = BoxMesh.new()
			box.size = Vector3.ONE
			result = box
	_meshes[key] = result
	return result


static func _mesh_face(builder: SurfaceTool, points: Array[Vector3], normal: Vector3) -> void:
	# Explicit face normals keep each bevel readable. Godot uses clockwise front faces.
	var reverse: bool = (points[1] - points[0]).cross(points[2] - points[0]).dot(normal) > 0.0
	for index: int in range(1, points.size() - 1):
		for vertex: int in [0, index + 1 if reverse else index, index if reverse else index + 1]:
			builder.set_normal(normal)
			builder.add_vertex(points[vertex])


static func _chamfered_box() -> ArrayMesh:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var inset: float = 0.37
	for axis: int in range(3):
		var a: Vector3 = axes[axis]
		var b: Vector3 = axes[(axis + 1) % 3]
		var c: Vector3 = axes[(axis + 2) % 3]
		for side: float in [-1.0, 1.0]:
			var center: Vector3 = a * side * 0.5
			_mesh_face(builder, [center + b * inset + c * inset, center - b * inset + c * inset, center - b * inset - c * inset, center + b * inset - c * inset], a * side)
			for edge: float in [-1.0, 1.0]:
				_mesh_face(builder, [a * side * 0.5 + b * edge * inset + c * inset, a * side * inset + b * edge * 0.5 + c * inset, a * side * inset + b * edge * 0.5 - c * inset, a * side * 0.5 + b * edge * inset - c * inset], (a * side + b * edge).normalized())
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				_mesh_face(builder, [Vector3(x * 0.5, y * inset, z * inset), Vector3(x * inset, y * 0.5, z * inset), Vector3(x * inset, y * inset, z * 0.5)], Vector3(x, y, z).normalized())
	return builder.commit()


static func _wing_mesh() -> ArrayMesh:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline: Array[Vector3] = [Vector3(0, 0, 0.17), Vector3(0.72, 0, 0.12), Vector3(1.36, 0, -0.46), Vector3(0.40, 0, -0.32), Vector3(0, 0, -0.20)]
	for side: float in [-1.0, 1.0]:
		var face: Array[Vector3] = []
		for point: Vector3 in outline:
			face.append(point + Vector3.UP * side * 0.035)
		_mesh_face(builder, face, Vector3.UP * side)
	for index: int in range(outline.size()):
		var a: Vector3 = outline[index]
		var b: Vector3 = outline[(index + 1) % outline.size()]
		var normal: Vector3 = Vector3(-(b - a).z, 0, (b - a).x).normalized()
		_mesh_face(builder, [a + Vector3.UP * 0.035, b + Vector3.UP * 0.035, b - Vector3.UP * 0.035, a - Vector3.UP * 0.035], normal)
	return builder.commit()


static func _part(parent: Node3D, shape: String, at: Vector3, size: Vector3, material_key: String, angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = _mesh(shape)
	part.material_override = _material(material_key)
	part.position = at
	part.rotation = angles
	part.scale = size
	parent.add_child(part)
	return part


static func _group(parent: Node3D, node_name: String, at: Vector3 = Vector3.ZERO) -> Node3D:
	var group: Node3D = Node3D.new()
	group.name = node_name
	group.position = at
	parent.add_child(group)
	return group


static func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float, material_key: String) -> MeshInstance3D:
	var delta: Vector3 = to - from
	var part: MeshInstance3D = _part(parent, "cylinder", (from + to) * 0.5, Vector3(radius, delta.length(), radius), material_key)
	part.quaternion = Quaternion(Vector3.UP, delta.normalized())
	return part


static func _transform(at: Vector3, size: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(size), at)


static func _batch(parent: Node3D, node_name: String, shape: String, material_key: String, transforms: Array[Transform3D], shadows: bool = true) -> void:
	if transforms.is_empty():
		return
	var mesh: MultiMesh = MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.mesh = _mesh(shape)
	mesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		mesh.set_instance_transform(index, transforms[index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = mesh
	instance.material_override = _material(material_key)
	if not shadows:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


static func _ring(parent: Node3D, radius: float, width: float, height: float, material_key: String, count: int = 32, gap: float = 0.0) -> void:
	var transforms: Array[Transform3D] = []
	var segment_length: float = TAU * radius / float(count) * (1.0 - gap)
	for index: int in range(count):
		var angle: float = TAU * float(index) / float(count)
		transforms.append(_transform(Vector3(sin(angle) * radius, 0, cos(angle) * radius), Vector3(segment_length, height, width), angle))
	_batch(parent, "Segments", "box", material_key, transforms, false)


static func _label(parent: Node3D, message: String, at: Vector3, font_size: int, color_key: String, yaw: float = 0.0) -> void:
	var label: Label3D = Label3D.new()
	label.text = message
	label.name = "DeckLettering"
	label.position = at
	label.rotation = Vector3(-PI * 0.5, yaw, 0)
	label.font_size = font_size
	label.pixel_size = 0.014
	label.modulate = PALETTE.get(color_key, Color.WHITE)
	label.outline_size = 0
	label.no_depth_test = false
	label.shaded = true
	parent.add_child(label)


static func build_arena(parent: Node3D) -> void:
	var arena: Node3D = _group(parent, "Skyforge")
	var deck: Node3D = _group(arena, "Deck")
	# The tile tops are precisely y=0; all raised scenery is outside ±15.
	_part(deck, "box", Vector3(0, -0.49, 0), Vector3(32.6, 0.84, 32.6), "seam")
	_part(deck, "box", Vector3(0, -0.98, 0), Vector3(31.7, 0.16, 31.7), "edge")
	var tiles_a: Array[Transform3D] = []
	var tiles_b: Array[Transform3D] = []
	for x: int in range(8):
		for z: int in range(8):
			var tile: Transform3D = _transform(Vector3(-14.0 + float(x) * 4.0, -0.035, -14.0 + float(z) * 4.0), Vector3(3.967, 0.07, 3.967))
			if (x + z) % 3 == 0:
				tiles_b.append(tile)
			else:
				tiles_a.append(tile)
	_batch(deck, "DeckTiles", "box", "deck", tiles_a)
	_batch(deck, "DeckTilesVariation", "box", "deck_alt", tiles_b)
	var grooves: Array[Transform3D] = []
	var pips: Array[Transform3D] = []
	var fasteners: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		grooves.append(_transform(Vector3(side * 14.8, 0.009, 0), Vector3(0.035, 0.014, 27.8)))
		grooves.append(_transform(Vector3(0, 0.009, side * 14.8), Vector3(27.8, 0.014, 0.035)))
		for position: float in [-12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0]:
			pips.append(_transform(Vector3(side * 15.58, 0.036, position), Vector3(0.11, 0.035, 0.48)))
			pips.append(_transform(Vector3(position, 0.036, side * 15.58), Vector3(0.48, 0.035, 0.11)))
		for position: float in [-12.0, -4.0, 4.0, 12.0]:
			grooves.append(_transform(Vector3(side * 12.8, 0.009, position), Vector3(2.0, 0.013, 0.032)))
			grooves.append(_transform(Vector3(side * 11.8, 0.009, position + side * 0.5), Vector3(0.032, 0.013, 1.0)))
	for x: int in range(9):
		for z: int in range(9):
			fasteners.append(_transform(Vector3(-15.82 + float(x) * 3.96, 0.013, -15.82 + float(z) * 3.96), Vector3(0.065, 0.017, 0.065)))
	_batch(deck, "CircuitInlays", "box", "teal_dim", grooves, false)
	_batch(deck, "NavigationLights", "box", "teal", pips, false)
	_batch(deck, "FlushFasteners", "octagon", "edge", fasteners, false)
	for radius: float in [4.0, 8.0]:
		var circle: Node3D = _group(deck, "EtchedServiceRing", Vector3(0, 0.012, 0))
		_ring(circle, radius, 0.024, 0.009, "teal_dim", 96, 0.13)
	var center: Node3D = _group(deck, "CenterMarker", Vector3(0, 0.014, 0))
	_ring(center, 0.58, 0.038, 0.012, "edge", 8, 0.28)
	_build_perimeter(arena)
	_build_supports(arena)
	_build_backdrop(arena)
	_label(deck, "S K Y F O R G E    /    0 7", Vector3(0, 0.042, -15.56), 46, "white_shadow")
	_label(deck, "REACTOR TRANSFER DECK", Vector3(0, 0.042, 15.54), 30, "white_shadow")
	_label(deck, "07", Vector3(-13.7, 0.042, 12.8), 100, "edge")
	_label(deck, "+", Vector3(13.7, 0.042, -12.8), 76, "edge")


static func _build_perimeter(arena: Node3D) -> void:
	var perimeter: Node3D = _group(arena, "Perimeter")
	var rail_posts: Array[Transform3D] = []
	var hazard_bars: Array[Transform3D] = []
	var vents: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		_part(perimeter, "box", Vector3(side * 16.24, -0.025, 0), Vector3(0.4, 0.15, 32.4), "edge")
		_part(perimeter, "box", Vector3(0, -0.025, side * 16.24), Vector3(32.4, 0.15, 0.4), "edge")
		# Deliberate gaps and a low sill maintain visibility from the fixed camera.
		for offset: float in [-11.0, 0.0, 11.0]:
			_part(perimeter, "box", Vector3(side * 16.36, 0.40, offset), Vector3(0.12, 0.10, 6.6), "steel")
			_part(perimeter, "box", Vector3(offset, 0.40, side * 16.36), Vector3(6.6, 0.10, 0.12), "steel")
			for post_offset: float in [-3.1, 3.1]:
				rail_posts.append(_transform(Vector3(side * 16.36, 0.19, offset + post_offset), Vector3(0.16, 0.42, 0.16)))
				rail_posts.append(_transform(Vector3(offset + post_offset, 0.19, side * 16.36), Vector3(0.16, 0.42, 0.16)))
		for corner: float in [-1.0, 1.0]:
			var corner_at: Vector3 = Vector3(side * 15.8, 0.13, corner * 15.8)
			_part(perimeter, "octagon", corner_at, Vector3(0.5, 0.24, 0.5), "steel")
			_part(perimeter, "octagon", corner_at + Vector3(0, 0.14, 0), Vector3(0.32, 0.035, 0.32), "amber")
		for index: int in range(14):
			var along: float = -2.35 + float(index) * 0.36
			hazard_bars.append(_transform(Vector3(side * 15.78, 0.048, along), Vector3(0.30, 0.025, 0.10), -side * PI * 0.25))
			hazard_bars.append(_transform(Vector3(along, 0.048, side * 15.78), Vector3(0.10, 0.025, 0.30), -side * PI * 0.25))
		for index: int in range(14):
			var along: float = -2.1 + float(index) * 0.32
			vents.append(_transform(Vector3(side * 15.96, -0.49, along), Vector3(0.025, 0.38, 0.13)))
	_batch(perimeter, "RailPosts", "box", "steel", rail_posts)
	_batch(perimeter, "HazardHatching", "box", "amber", hazard_bars, false)
	_batch(perimeter, "EdgeVentSlits", "box", "dark", vents, false)


static func _build_supports(arena: Node3D) -> void:
	var supports: Node3D = _group(arena, "SuspendedUnderstructure")
	for x: float in [-11.0, 0.0, 11.0]:
		_part(supports, "box", Vector3(x, -1.4, 0), Vector3(0.55, 1.1, 31.4), "steel")
		_part(supports, "box", Vector3(0, -1.6, x), Vector3(31.4, 0.8, 0.48), "steel")
	for x: float in [-13.0, 13.0]:
		for z: float in [-13.0, 13.0]:
			_part(supports, "octagon", Vector3(x, -2.25, z), Vector3(1.5, 2.5, 1.5), "steel")
			_part(supports, "cone", Vector3(x, -4.15, z), Vector3(1.2, 1.3, 1.2), "dark", Vector3(PI, 0, 0))
			_part(supports, "octagon", Vector3(x, -3.4, z), Vector3(1.26, 0.10, 1.26), "teal_dim")
			_beam(supports, Vector3(x, -3.0, z), Vector3(x * 0.52, -0.95, z), 0.17, "edge")
			_beam(supports, Vector3(x, -3.0, z), Vector3(x, -0.95, z * 0.52), 0.17, "edge")
	# Pipes terminate in the outer reactor housings, clear of the deck surface.
	for side: float in [-1.0, 1.0]:
		_beam(supports, Vector3(side * 14.5, -0.75, -9), Vector3(side * 21.5, -0.75, -9), 0.32, "steel")
		_beam(supports, Vector3(side * 14.5, -1.2, 7), Vector3(side * 20.0, -1.2, 7), 0.19, "edge")


static func _turbine(parent: Node3D, at: Vector3, yaw: float, size: float) -> void:
	var turbine: Node3D = _group(parent, "OctagonalTurbine", at)
	turbine.rotation.y = yaw
	turbine.scale = Vector3.ONE * size
	_part(turbine, "octagon", Vector3(0, -0.55, 0), Vector3(2.65, 1.2, 2.65), "dark")
	_part(turbine, "octagon", Vector3(0, 0.22, 0), Vector3(2.4, 0.7, 2.4), "steel")
	_part(turbine, "octagon", Vector3(0, 0.62, 0), Vector3(2.26, 0.10, 2.26), "edge")
	_part(turbine, "cylinder", Vector3(0, 0.71, 0), Vector3(1.97, 0.12, 1.97), "dark")
	var blades: Array[Transform3D] = []
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0
		blades.append(_transform(Vector3(sin(angle) * 1.28, 0.86, cos(angle) * 1.28), Vector3(0.4, 0.12, 1.0), angle + 0.36))
	_batch(turbine, "TurbineBlades", "box", "edge", blades)
	_part(turbine, "cone", Vector3(0, 0.95, 0), Vector3(0.57, 0.56, 0.57), "steel")
	_part(turbine, "octagon", Vector3(0, 1.24, 0), Vector3(0.24, 0.07, 0.24), "teal")
	var lip: Node3D = _group(turbine, "Rim", Vector3(0, 0.78, 0))
	_ring(lip, 2.13, 0.075, 0.10, "teal_dim", 16, 0.15)
	for side: float in [-1.0, 1.0]:
		_part(turbine, "box", Vector3(side * 2.28, 0.65, 0), Vector3(0.22, 0.20, 1.0), "amber")
		_part(turbine, "box", Vector3(side * 1.0, -1.9, 0), Vector3(0.44, 2.5, 1.0), "steel")


static func _build_backdrop(arena: Node3D) -> void:
	var backdrop: Node3D = _group(arena, "SkyFoundryBackground")
	_turbine(backdrop, Vector3(-20.2, -0.3, -8.8), -0.18, 1.0)
	_turbine(backdrop, Vector3(20.2, -0.6, 7.0), 0.3, 0.85)
	_turbine(backdrop, Vector3(18.9, -0.8, -15.7), 0.25, 0.8)
	# Tall architecture sits behind the arena; near-side scenery stays low.
	var tower: Node3D = _group(backdrop, "MainReactor", Vector3(-9.8, -2.0, -23.0))
	_part(tower, "octagon", Vector3(0, 1.0, 0), Vector3(3.4, 2.0, 3.4), "dark")
	_part(tower, "octagon", Vector3(0, 3.0, 0), Vector3(2.4, 3.0, 2.4), "steel")
	_part(tower, "octagon", Vector3(0, 4.67, 0), Vector3(2.7, 0.35, 2.7), "edge")
	_part(tower, "cone", Vector3(0, 5.3, 0), Vector3(2.22, 1.0, 2.22), "steel")
	_part(tower, "octagon", Vector3(0, 5.86, 0), Vector3(1.55, 0.12, 1.55), "teal")
	var ribs: Array[Transform3D] = []
	var windows: Array[Transform3D] = []
	for index: int in range(8):
		var angle: float = TAU * float(index) / 8.0
		ribs.append(_transform(Vector3(sin(angle) * 2.43, 3.1, cos(angle) * 2.43), Vector3(0.24, 3.1, 0.32), angle))
		windows.append(_transform(Vector3(sin(angle) * 2.45, 3.5, cos(angle) * 2.45), Vector3(0.36, 1.2, 0.035), angle))
	_batch(tower, "ReactorRibs", "box", "edge", ribs)
	_batch(tower, "ReactorSlits", "box", "teal_dim", windows, false)
	_part(backdrop, "box", Vector3(5, -0.3, -24), Vector3(16.8, 0.6, 3.0), "steel")
	for x: float in [-1.0, 10.0]:
		_part(backdrop, "box", Vector3(x, -3.5, -24), Vector3(1.4, 6.0, 2.0), "dark")
		_part(backdrop, "box", Vector3(x, 1.3, -25), Vector3(0.3, 3.0, 0.4), "edge")
	_part(backdrop, "box", Vector3(4.5, 2.6, -25), Vector3(12.0, 0.38, 0.6), "edge")
	_part(backdrop, "box", Vector3(4.5, 2.4, -24.7), Vector3(7.0, 0.07, 0.05), "teal_dim")
	var distant: Array[Transform3D] = []
	var city_lights: Array[Transform3D] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 70831
	for index: int in range(22):
		var x: float = -68.0 + float(index) * 6.4
		var z: float = rng.randf_range(-64.0, -42.0)
		var height: float = rng.randf_range(5.0, 17.0)
		var width: float = rng.randf_range(2.3, 5.5)
		distant.append(_transform(Vector3(x, height * 0.5 - 11.0, z), Vector3(width, height, width * 0.7)))
		city_lights.append(_transform(Vector3(x, height - 10.9, z), Vector3(0.06, 0.18, 0.06)))
		if index % 3 == 0:
			distant.append(_transform(Vector3(x + 3.0, -4.0, z), Vector3(10.0, 0.65, 1.0)))
	_batch(backdrop, "DistantMegastructures", "box", "distant", distant, false)
	_batch(backdrop, "DistantBeaconLights", "box", "teal_dim", city_lights, false)
	var motes: Array[Transform3D] = []
	for index: int in range(35):
		var x: float = rng.randf_range(-27.0, 27.0)
		var z: float = rng.randf_range(-28.0, 24.0)
		if absf(x) < 16.8 and absf(z) < 16.8:
			continue
		var radius: float = rng.randf_range(0.018, 0.042)
		motes.append(_transform(Vector3(x, rng.randf_range(-3.0, 3.0), z), Vector3(radius, radius, radius)))
	_batch(backdrop, "AtmosphericMotes", "sphere", "teal_dim", motes, false)


static func player() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CourierModel"
	var body: Node3D = _group(root, "Body")
	var rig: Dictionary = {"body": body, "hips": [], "knees": [], "shoulders": [], "elbows": [], "wings": [], "plumes": []}
	# Ceramic shells are separate from the graphite skeleton. Every major limb
	# pivots at an anatomical joint, so running is a gait rather than a body bob.
	_part(body, "armor", Vector3(0, 0.88, 0), Vector3(0.41, 0.23, 0.31), "dark")
	_part(body, "armor", Vector3(0, 0.92, 0.165), Vector3(0.34, 0.12, 0.085), "titanium")
	_part(body, "box", Vector3(0, 0.925, 0.216), Vector3(0.12, 0.045, 0.025), "cyan")
	var torso: Node3D = _group(body, "Torso", Vector3(0, 0.97, 0))
	rig["torso"] = torso
	_part(torso, "armor", Vector3(0, 0.21, 0), Vector3(0.50, 0.47, 0.32), "dark", Vector3(-0.06, 0, 0))
	_part(torso, "armor", Vector3(0, 0.31, 0.085), Vector3(0.59, 0.32, 0.30), "ceramic", Vector3(-0.10, 0, 0))
	_part(torso, "armor", Vector3(0, 0.08, 0.16), Vector3(0.35, 0.20, 0.13), "titanium", Vector3(-0.16, 0, 0))
	for side: float in [-1.0, 1.0]:
		_part(torso, "armor", Vector3(side * 0.155, 0.32, 0.246), Vector3(0.15, 0.19, 0.042), "white")
		_part(torso, "box", Vector3(side * 0.17, 0.405, 0.255), Vector3(0.14, 0.025, 0.025), "cyan")
		_part(torso, "armor", Vector3(side * 0.23, 0.16, -0.08), Vector3(0.105, 0.23, 0.30), "titanium")
	_part(torso, "armor", Vector3(0, 0.33, 0.255), Vector3(0.10, 0.24, 0.055), "visor")
	_part(torso, "box", Vector3(0, 0.35, 0.289), Vector3(0.045, 0.11, 0.025), "cyan")
	# Off-center orange mission stripe gives the silhouette a recognizable accent.
	_part(torso, "box", Vector3(-0.19, 0.31, 0.272), Vector3(0.047, 0.16, 0.016), "amber")
	for side: float in [-1.0, 1.0]:
		var suffix: String = "Left" if side < 0 else "Right"
		var hip: Node3D = _group(body, "Hip" + suffix, Vector3(side * 0.165, 0.85, 0))
		rig.hips.append(hip)
		_part(hip, "sphere", Vector3.ZERO, Vector3.ONE * 0.112, "titanium")
		_part(hip, "armor", Vector3(0, -0.18, -0.005), Vector3(0.185, 0.30, 0.20), "dark")
		_part(hip, "armor", Vector3(side * 0.018, -0.16, 0.064), Vector3(0.20, 0.26, 0.15), "ceramic", Vector3(-0.06, 0, side * 0.045))
		_part(hip, "box", Vector3(side * 0.112, -0.16, 0.02), Vector3(0.027, 0.16, 0.075), "teal")
		var knee: Node3D = _group(hip, "Knee" + suffix, Vector3(0, -0.34, 0))
		rig.knees.append(knee)
		_part(knee, "cylinder", Vector3.ZERO, Vector3(0.09, 0.20, 0.09), "dark", Vector3(0, 0, PI * 0.5))
		_part(knee, "armor", Vector3(0, -0.02, 0.10), Vector3(0.18, 0.16, 0.09), "titanium")
		_part(knee, "armor", Vector3(0, -0.19, -0.005), Vector3(0.17, 0.27, 0.19), "dark")
		_part(knee, "armor", Vector3(0, -0.19, 0.075), Vector3(0.195, 0.28, 0.12), "ceramic", Vector3(0.04, 0, 0))
		_part(knee, "box", Vector3(0, -0.18, 0.145), Vector3(0.041, 0.17, 0.022), "teal")
		var ankle: Node3D = _group(knee, "Ankle" + suffix, Vector3(0, -0.37, 0))
		_part(ankle, "armor", Vector3(0, -0.035, 0.09), Vector3(0.245, 0.19, 0.40), "dark")
		_part(ankle, "armor", Vector3(0, 0.012, 0.16), Vector3(0.225, 0.13, 0.24), "ceramic", Vector3(-0.08, 0, 0))
		_part(ankle, "box", Vector3(0, -0.115, 0.09), Vector3(0.22, 0.021, 0.32), "titanium")
		_part(ankle, "box", Vector3(0, -0.065, -0.114), Vector3(0.14, 0.039, 0.023), "cyan")
		var shoulder: Node3D = _group(torso, "Shoulder" + suffix, Vector3(side * 0.355, 0.36, 0))
		rig.shoulders.append(shoulder)
		_part(shoulder, "sphere", Vector3.ZERO, Vector3.ONE * 0.105, "dark")
		_part(shoulder, "armor", Vector3(side * 0.025, 0.032, 0), Vector3(0.26, 0.20, 0.32), "ceramic", Vector3(0, 0, -side * 0.15))
		_part(shoulder, "box", Vector3(side * 0.148, 0.025, 0.035), Vector3(0.025, 0.063, 0.13), "amber" if side < 0 else "cyan")
		_part(shoulder, "armor", Vector3(side * 0.025, -0.15, 0), Vector3(0.135, 0.23, 0.15), "dark")
		var elbow: Node3D = _group(shoulder, "Elbow" + suffix, Vector3(side * 0.025, -0.27, 0))
		rig.elbows.append(elbow)
		_part(elbow, "sphere", Vector3.ZERO, Vector3.ONE * 0.077, "titanium")
		_part(elbow, "armor", Vector3(0, -0.12, 0.024), Vector3(0.18, 0.26, 0.21), "ceramic", Vector3(-0.10, 0, 0))
		_part(elbow, "box", Vector3(0, -0.12, 0.137), Vector3(0.068, 0.10, 0.018), "visor")
		_part(elbow, "box", Vector3(0, -0.10, 0.151), Vector3(0.045, 0.04, 0.012), "cyan")
		_part(elbow, "armor", Vector3(0, -0.287, 0.041), Vector3(0.15, 0.13, 0.17), "dark")
	var head: Node3D = _group(torso, "Head", Vector3(0, 0.63, 0.015))
	rig["head"] = head
	_part(head, "cylinder", Vector3(0, -0.09, 0), Vector3(0.086, 0.12, 0.086), "dark")
	_part(head, "armor", Vector3(0, 0.09, -0.005), Vector3(0.40, 0.40, 0.36), "ceramic", Vector3(-0.06, 0, 0))
	_part(head, "armor", Vector3(0, 0.088, 0.163), Vector3(0.37, 0.17, 0.13), "visor", Vector3(-0.12, 0, 0))
	_part(head, "armor", Vector3(0, 0.107, 0.231), Vector3(0.30, 0.055, 0.023), "cyan")
	_part(head, "armor", Vector3(0, -0.027, 0.168), Vector3(0.20, 0.10, 0.14), "titanium", Vector3(-0.20, 0, 0))
	_part(head, "box", Vector3(-0.075, 0.279, -0.015), Vector3(0.06, 0.021, 0.19), "amber")
	for side: float in [-1.0, 1.0]:
		_part(head, "cylinder", Vector3(side * 0.211, 0.08, -0.008), Vector3(0.083, 0.055, 0.083), "titanium", Vector3(0, 0, PI * 0.5))
		_part(head, "cylinder", Vector3(side * 0.243, 0.08, -0.008), Vector3(0.042, 0.016, 0.042), "teal", Vector3(0, 0, PI * 0.5))
	var reactor: Node3D = _group(root, "Reactor", Vector3(0, 1.22, -0.28))
	rig["reactor"] = reactor
	_part(reactor, "armor", Vector3(0, 0.02, -0.04), Vector3(0.43, 0.43, 0.22), "dark")
	_part(reactor, "armor", Vector3(0, 0.10, -0.14), Vector3(0.30, 0.30, 0.08), "titanium")
	_part(reactor, "cylinder", Vector3(0, 0.085, -0.205), Vector3(0.128, 0.075, 0.128), "dark", Vector3(PI * 0.5, 0, 0))
	_part(reactor, "octagon", Vector3(0, 0.085, -0.252), Vector3(0.091, 0.028, 0.091), "cyan", Vector3(PI * 0.5, 0, 0))
	for side: float in [-1.0, 1.0]:
		var suffix: String = "Left" if side < 0 else "Right"
		var wing: Node3D = _group(reactor, "Wing" + suffix, Vector3(side * 0.19, 0.15, -0.11))
		rig.wings.append(wing)
		var panels: Node3D = _group(wing, "Panels")
		panels.scale.x = side
		_part(panels, "wing", Vector3.ZERO, Vector3.ONE, "titanium")
		_part(panels, "wing", Vector3(0.04, 0.045, -0.012), Vector3(0.94, 0.6, 0.80), "ceramic")
		_beam(panels, Vector3(0.19, 0.07, 0.10), Vector3(0.72, 0.07, 0.07), 0.023, "cyan")
		_beam(panels, Vector3(0.74, 0.07, 0.046), Vector3(1.21, 0.07, -0.39), 0.025, "cyan")
		for index: int in range(3):
			_part(panels, "armor", Vector3(0.35 + float(index) * 0.18, 0.066, -0.12), Vector3(0.08, 0.026, 0.16), "visor", Vector3(0, -0.25, 0))
		var thruster: Node3D = _group(reactor, "Thruster" + suffix, Vector3(side * 0.205, -0.17, -0.035))
		_part(thruster, "cone", Vector3.ZERO, Vector3(0.12, 0.25, 0.12), "titanium")
		_part(thruster, "cylinder", Vector3(0, -0.13, 0), Vector3(0.093, 0.06, 0.093), "dark")
		_part(thruster, "cylinder", Vector3(0, -0.166, 0), Vector3(0.068, 0.021, 0.068), "cyan")
		var plume: Node3D = _group(thruster, "Plume", Vector3(0, -0.18, 0))
		_part(plume, "prism", Vector3(0, -0.21, 0), Vector3(0.11, 0.42, 0.11), "cyan", Vector3(0, 0, PI))
		_part(plume, "prism", Vector3(0, -0.30, 0), Vector3(0.060, 0.60, 0.060), "white", Vector3(0, 0, PI))
		rig.plumes.append(plume)
	var ring: Node3D = _group(root, "Ring", Vector3(0, 1.02, 0))
	_ring(ring, 0.49, 0.025, 0.032, "cyan", 12, 0.62)
	rig["ring"] = ring
	root.set_meta("rig", rig)
	root.set_meta("gait_phase", 0.0)
	root.set_meta("wing_deployment", 0.0)
	animate_player(root, 1.0, 0.0, false, false, false, 0.0)
	return root


static func animate_player(model: Node3D, delta: float, speed_fraction: float, airborne: bool, gliding: bool, dashing: bool, time: float) -> void:
	if not model.has_meta("rig"):
		return
	var rig: Dictionary = model.get_meta("rig")
	var speed: float = clampf(speed_fraction, 0.0, 1.0)
	var blend: float = 1.0 - exp(-delta * 14.0)
	var phase: float = float(model.get_meta("gait_phase", 0.0)) + delta * lerpf(5.0, 15.0, speed)
	model.set_meta("gait_phase", fmod(phase, TAU))
	var deployment: float = lerpf(float(model.get_meta("wing_deployment", 0.0)), 1.0 if gliding else (0.38 if airborne or dashing else 0.0), blend)
	model.set_meta("wing_deployment", deployment)
	var landing: float = float(model.get_meta("landing_impact", 0.0))
	model.set_meta("landing_impact", maxf(0.0, landing - delta * 3.8))
	var body: Node3D = rig.body
	var bob: float = (absf(sin(phase)) * 0.048 * speed) if not airborne else 0.035
	body.position.y = lerpf(body.position.y, bob - landing * 0.10, blend)
	body.rotation.x = lerpf(body.rotation.x, 0.60 if gliding else (0.36 if dashing else (0.10 if airborne else speed * 0.12)), blend)
	body.rotation.z = lerpf(body.rotation.z, cos(phase) * speed * 0.028 if not airborne else sin(time * 2.4) * 0.035, blend)
	var torso: Node3D = rig.torso
	torso.rotation.y = sin(phase) * speed * 0.07 if not airborne and not dashing else 0.0
	var head: Node3D = rig.head
	head.rotation.x = -body.rotation.x * 0.5
	for index: int in range(2):
		var side: float = -1.0 if index == 0 else 1.0
		var stride: float = sin(phase + float(index) * PI)
		var hip: Node3D = rig.hips[index]
		var knee: Node3D = rig.knees[index]
		var shoulder: Node3D = rig.shoulders[index]
		var elbow: Node3D = rig.elbows[index]
		var wing: Node3D = rig.wings[index]
		var plume: Node3D = rig.plumes[index]
		var hip_target: float = stride * speed * 0.67
		var knee_target: float = -maxf(0.0, -stride) * speed * 0.94 - 0.055
		var shoulder_target: float = -stride * speed * 0.60
		if airborne:
			hip_target = 0.24 if gliding else (-0.30 if index == 0 else 0.39)
			knee_target = -0.36 if gliding else (-0.82 if index == 0 else -0.52)
			shoulder_target = 0.28 if gliding else -0.48
		elif dashing:
			hip_target = -0.35 if index == 0 else 0.58
			knee_target = -0.42
			shoulder_target = 0.48
		if not airborne:
			hip_target += landing * 0.42
			knee_target -= landing * 1.0
		hip.rotation.x = lerpf(hip.rotation.x, hip_target, blend)
		knee.rotation.x = lerpf(knee.rotation.x, knee_target, blend)
		shoulder.rotation.x = lerpf(shoulder.rotation.x, shoulder_target, blend)
		shoulder.rotation.z = lerpf(shoulder.rotation.z, side * (0.70 if gliding else 0.10), blend)
		elbow.rotation.x = lerpf(elbow.rotation.x, -0.36 if airborne else (-0.25 - speed * 0.40), blend)
		wing.rotation = Vector3(0.0, side * lerpf(0.66, 0.04, deployment), -side * lerpf(1.30, -0.08, deployment))
		plume.visible = airborne or dashing
		plume.scale = Vector3(1.0, (0.85 if gliding else 1.25) + sin(time * 45.0 + float(index)) * 0.15, 1.0)
	var reactor: Node3D = rig.reactor
	reactor.position = body.position + Basis(Vector3.RIGHT, body.rotation.x) * Vector3(0, 1.22, -0.28)
	reactor.rotation = body.rotation
	var ring: Node3D = rig.ring
	ring.position.y = 1.02 + body.position.y


static func enemy(kind: String) -> Node3D:
	match kind:
		"charger":
			return _charger()
		"bruiser":
			return _bruiser()
		_:
			return _gunner()


static func _gunner() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "GunnerModel"
	var body: Node3D = _group(root, "Body")
	for index: int in range(3):
		var angle: float = TAU * float(index) / 3.0 + PI
		var foot: Vector3 = Vector3(sin(angle) * 0.44, 0.10, cos(angle) * 0.44)
		var knee: Vector3 = Vector3(sin(angle) * 0.38, 0.42, cos(angle) * 0.38)
		_beam(body, Vector3(sin(angle) * 0.17, 0.76, cos(angle) * 0.17), knee, 0.065, "orange")
		_beam(body, knee, foot, 0.052, "edge")
		_part(body, "box", foot, Vector3(0.19, 0.14, 0.27), "dark", Vector3(0, angle, 0))
		_part(body, "sphere", knee, Vector3.ONE * 0.091, "dark")
	_part(body, "octagon", Vector3(0, 0.73, 0), Vector3(0.23, 0.20, 0.23), "dark")
	_part(body, "octagon", Vector3(0, 0.98, 0), Vector3(0.34, 0.48, 0.34), "orange", Vector3(0, PI * 0.125, 0))
	_part(body, "octagon", Vector3(0, 1.235, 0), Vector3(0.27, 0.055, 0.27), "dark")
	_part(body, "box", Vector3(0, 1.1, 0.323), Vector3(0.32, 0.115, 0.10), "dark")
	_part(body, "box", Vector3(0, 1.115, 0.383), Vector3(0.23, 0.040, 0.017), "hot")
	_part(body, "cylinder", Vector3(0, 0.9, 0.33), Vector3(0.13, 0.33, 0.13), "steel", Vector3(PI * 0.5, 0, 0))
	_part(body, "octagon", Vector3(0, 0.9, 0.505), Vector3(0.105, 0.035, 0.105), "hot", Vector3(PI * 0.5, 0, 0))
	_part(body, "box", Vector3(-0.18, 1.36, -0.09), Vector3(0.034, 0.23, 0.034), "edge")
	_part(body, "sphere", Vector3(-0.18, 1.455, -0.09), Vector3.ONE * 0.036, "hot")
	var reactor: Node3D = _group(root, "Reactor", Vector3(0, 0.9, -0.30))
	_part(reactor, "box", Vector3.ZERO, Vector3(0.18, 0.20, 0.10), "amber")
	return root


static func _charger() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ChargerModel"
	var body: Node3D = _group(root, "Body")
	for side: float in [-1.0, 1.0]:
		for front: float in [-1.0, 1.0]:
			var z: float = front * 0.25
			_beam(body, Vector3(side * 0.21, 0.65, z), Vector3(side * 0.28, 0.29, z - 0.10), 0.073, "purple")
			_beam(body, Vector3(side * 0.28, 0.29, z - 0.10), Vector3(side * 0.28, 0.10, z + 0.08), 0.05, "dark")
			_part(body, "prism", Vector3(side * 0.28, 0.09, z + 0.11), Vector3(0.17, 0.15, 0.25), "magenta")
	_part(body, "box", Vector3(0, 0.69, -0.09), Vector3(0.41, 0.30, 0.69), "dark", Vector3(-0.13, 0, 0))
	_part(body, "prism", Vector3(0, 0.86, -0.14), Vector3(0.51, 0.34, 0.65), "magenta", Vector3(-0.13, 0, 0))
	_part(body, "box", Vector3(0, 0.75, 0.3), Vector3(0.40, 0.28, 0.30), "magenta", Vector3(-0.22, 0, 0))
	_part(body, "prism", Vector3(0, 0.69, 0.45), Vector3(0.28, 0.18, 0.24), "dark", Vector3(0, 0, PI))
	for side: float in [-1.0, 1.0]:
		_part(body, "box", Vector3(side * 0.12, 0.79, 0.448), Vector3(0.08, 0.045, 0.025), "pink")
		_part(body, "prism", Vector3(side * 0.15, 0.96, 0.24), Vector3(0.10, 0.27, 0.17), "purple", Vector3(-0.28, 0, side * -0.12))
	_part(body, "prism", Vector3(0, 0.87, -0.41), Vector3(0.08, 0.35, 0.24), "purple", Vector3(-0.4, 0, 0))
	var reactor: Node3D = _group(root, "Reactor", Vector3(0, 1.026, -0.10))
	_part(reactor, "box", Vector3.ZERO, Vector3(0.055, 0.04, 0.37), "pink")
	return root


static func _bruiser() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BruiserModel"
	var body: Node3D = _group(root, "Body")
	for side: float in [-1.0, 1.0]:
		_part(body, "box", Vector3(side * 0.24, 0.12, 0.045), Vector3(0.30, 0.23, 0.43), "dark")
		_part(body, "box", Vector3(side * 0.24, 0.4, 0), Vector3(0.23, 0.37, 0.25), "purple", Vector3(0, 0, side * -0.1))
		_part(body, "box", Vector3(side * 0.24, 0.45, 0.15), Vector3(0.19, 0.13, 0.07), "edge")
	_part(body, "box", Vector3(0, 0.73, 0), Vector3(0.59, 0.23, 0.34), "dark")
	_part(body, "box", Vector3(0, 0.99, 0), Vector3(0.67, 0.48, 0.44), "purple")
	for side: float in [-1.0, 1.0]:
		_part(body, "box", Vector3(side * 0.39, 1.075, 0), Vector3(0.26, 0.28, 0.40), "purple", Vector3(0, 0, side * -0.15))
		_part(body, "box", Vector3(side * 0.4, 0.84, 0.12), Vector3(0.19, 0.30, 0.25), "steel")
	_part(body, "box", Vector3(0, 1.33, 0.02), Vector3(0.40, 0.25, 0.31), "steel")
	_part(body, "box", Vector3(0, 1.37, 0.185), Vector3(0.28, 0.043, 0.025), "violet")
	var shield: Node3D = _group(root, "Shield", Vector3(0, 0.75, 0.33))
	_part(shield, "box", Vector3.ZERO, Vector3(0.70, 0.94, 0.15), "dark", Vector3(0.10, 0, 0))
	_part(shield, "box", Vector3(0, 0, 0.096), Vector3(0.59, 0.84, 0.09), "purple", Vector3(0.10, 0, 0))
	for side: float in [-1.0, 1.0]:
		_part(shield, "box", Vector3(side * 0.30, 0, 0.14), Vector3(0.035, 0.73, 0.025), "violet")
	_part(shield, "box", Vector3(0, 0.23, 0.157), Vector3(0.40, 0.04, 0.023), "violet")
	_part(shield, "prism", Vector3(0, -0.09, 0.169), Vector3(0.23, 0.28, 0.032), "edge", Vector3(0, 0, PI))
	var reactor: Node3D = _group(root, "Reactor", Vector3(0, 1.02, -0.26))
	_part(reactor, "cylinder", Vector3.ZERO, Vector3(0.14, 0.10, 0.14), "violet", Vector3(PI * 0.5, 0, 0))
	return root


static func boss() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ReactorGuardianModel"
	var body: Node3D = _group(root, "Body")
	for side: float in [-1.0, 1.0]:
		_part(body, "box", Vector3(side * 0.56, 0.20, 0.16), Vector3(0.70, 0.36, 0.95), "dark")
		_part(body, "box", Vector3(side * 0.56, 0.29, 0.44), Vector3(0.58, 0.15, 0.34), "edge")
		_part(body, "box", Vector3(side * 0.54, 0.76, 0), Vector3(0.47, 0.77, 0.50), "steel", Vector3(0, 0, side * -0.08))
		_part(body, "box", Vector3(side * 0.55, 0.90, 0.29), Vector3(0.41, 0.33, 0.18), "amber")
	_part(body, "octagon", Vector3(0, 1.18, 0), Vector3(0.72, 0.29, 0.58), "dark")
	_part(body, "octagon", Vector3(0, 1.72, 0), Vector3(0.90, 0.92, 0.64), "steel", Vector3(0, PI * 0.125, 0))
	_part(body, "box", Vector3(0, 2.14, 0.15), Vector3(1.42, 0.20, 0.86), "edge")
	for side: float in [-1.0, 1.0]:
		_part(body, "octagon", Vector3(side * 1.0, 1.93, 0), Vector3(0.36, 0.66, 0.41), "amber", Vector3(0, 0, side * -0.24))
		_part(body, "box", Vector3(side * 1.12, 1.43, 0.10), Vector3(0.46, 0.67, 0.61), "steel", Vector3(-0.20, 0, side * -0.08))
		_part(body, "box", Vector3(side * 1.12, 1.24, 0.33), Vector3(0.40, 0.32, 0.33), "dark")
		_part(body, "box", Vector3(side * 1.12, 1.68, 0.44), Vector3(0.25, 0.06, 0.032), "hot")
		_part(body, "prism", Vector3(side * 0.68, 2.30, -0.08), Vector3(0.32, 0.56, 0.45), "steel", Vector3(0, 0, side * -0.3))
	_part(body, "box", Vector3(0, 2.43, 0.02), Vector3(0.83, 0.47, 0.57), "dark")
	_part(body, "prism", Vector3(0, 2.75, 0.01), Vector3(0.89, 0.32, 0.58), "steel")
	_part(body, "box", Vector3(0, 2.48, 0.317), Vector3(0.65, 0.105, 0.044), "orange")
	_part(body, "box", Vector3(0, 2.49, 0.345), Vector3(0.39, 0.038, 0.019), "hot")
	var reactor: Node3D = _group(root, "Reactor", Vector3(0, 1.77, 0.65))
	_part(reactor, "octagon", Vector3.ZERO, Vector3(0.45, 0.13, 0.45), "dark", Vector3(PI * 0.5, 0, 0))
	_part(reactor, "octagon", Vector3(0, 0, 0.08), Vector3(0.34, 0.07, 0.34), "orange", Vector3(PI * 0.5, 0, 0))
	_part(reactor, "octagon", Vector3(0, 0, 0.126), Vector3(0.24, 0.045, 0.24), "hot", Vector3(PI * 0.5, 0, 0))
	_part(reactor, "box", Vector3(0, 0, 0.16), Vector3(0.05, 0.42, 0.03), "amber")
	_part(body, "octagon", Vector3(0, 1.65, -0.65), Vector3(0.53, 0.32, 0.53), "steel", Vector3(PI * 0.5, 0, 0))
	var ring: Node3D = _group(root, "Ring", Vector3(0, 2.26, -0.08))
	_ring(ring, 1.34, 0.12, 0.09, "orange", 16, 0.36)
	return root
