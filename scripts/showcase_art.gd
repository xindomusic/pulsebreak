extends RefCounted
## Original sector scenery and readable traversal props. All collision is owned
## by the director; these factories never introduce invisible physics bodies.

const Art = preload("res://scripts/art.gd")
const SECTOR_ACCENTS: Array[String] = ["cyan", "solar", "storm"]
const SECTOR_NAMES: Array[String] = ["SKYPORT", "SOLAR FOUNDRY", "STORM CORE"]
const SECTOR_INLAYS: Array[String] = ["sky_inlay", "solar_inlay", "storm_inlay"]
const SECTOR_LAMPS: Array[String] = ["sky_lamp", "solar_lamp", "storm_lamp"]
const MAX_GENERATED_PAINT := 160
static var _light_wash_shader: Shader
static var _light_wash_mesh: QuadMesh
static var _light_wash_materials: Dictionary = {}


static func hero_display() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CourierDisplay"
	Art._part(root, "octagon", Vector3(0, -0.31, 0), Vector3(3.4, 0.6, 3.4), "dark", Vector3(0, PI * 0.125, 0))
	Art._part(root, "octagon", Vector3(0, -0.035, 0), Vector3(3.1, 0.12, 3.1), "titanium", Vector3(0, PI * 0.125, 0))
	Art._part(root, "octagon", Vector3(0, 0.036, 0), Vector3(2.9, 0.035, 2.9), "deck_deep", Vector3(0, PI * 0.125, 0))
	var halo: Node3D = Art._group(root, "DisplayHalo", Vector3(0, 0.067, 0))
	Art._ring(halo, 2.65, 0.055, 0.018, "teal", 48, 0.22)
	Art._ring(halo, 2.1, 0.032, 0.018, "teal_dim", 48, 0.08)
	for index: int in range(8):
		var angle: float = TAU * float(index) / 8.0
		Art._part(root, "box", Vector3(sin(angle) * 3.18, 0.04, cos(angle) * 3.18), Vector3(0.62, 0.035, 0.12), "cyan", Vector3(0, angle, 0))
	return root


static func build_stage(parent: Node3D, sector_index: int) -> Node3D:
	var sector: int = clampi(sector_index, 0, 2)
	var stage: Node3D = Art._group(parent, "SectorScenery")
	var accent: String = SECTOR_ACCENTS[sector]
	stage.set_meta("sector", sector)
	stage.set_meta("rotors", [])
	stage.set_meta("orbitals", [])
	stage.set_meta("beacons", [])
	var original_backdrop: Node3D = parent.get_node_or_null("Skyforge/SkyFoundryBackground") as Node3D
	if not original_backdrop and is_instance_valid(parent.get_parent()):
		original_backdrop = parent.get_parent().get_node_or_null("Skyforge/SkyFoundryBackground") as Node3D
	if original_backdrop:
		original_backdrop.visible = sector == 0
	_build_sector_deck(stage, sector)
	_build_navigation(stage, sector, accent)
	_build_light_frame(stage, sector)
	match sector:
		0:
			_build_skyport(stage)
		1:
			_build_solar(stage)
		2:
			_build_storm(stage)
	return stage


static func _build_sector_deck(stage: Node3D, sector: int) -> void:
	# All graphics are flush paint/insets below actors and combat warnings. Large
	# shapes carry each sector's identity without creating implied collision.
	var deck: Node3D = Art._group(stage, "SectorDeckGraphics")
	var inlay: String = SECTOR_INLAYS[sector]
	var hatching: Array[Transform3D] = []
	var panels: Array[Transform3D] = []
	match sector:
		0:
			Art._part(deck, "box", Vector3(0, 0.022, 0), Vector3(7.6, 0.012, 28.0), inlay)
			Art._part(deck, "octagon", Vector3(0, 0.030, 0), Vector3(7.8, 0.012, 7.8), inlay, Vector3(0, PI * 0.125, 0))
			var landing: Node3D = Art._group(deck, "LaunchPad", Vector3(0, 0.043, 0))
			Art._ring(landing, 7.55, 0.052, 0.012, "deck_mark", 48, 0.10)
			Art._ring(landing, 6.85, 0.11, 0.012, "teal_dim", 12, 0.62)
			for side: float in [-1.0, 1.0]:
				for z: float in [-12.5, -10.5, -8.5, 8.5, 10.5, 12.5]:
					hatching.append(Art._transform(Vector3(side * 3.45, 0.039, z), Vector3(0.075, 0.012, 1.0)))
				for index: int in range(6):
					var x: float = side * (8.6 + float(index) * 0.32)
					hatching.append(Art._transform(Vector3(x, 0.032, 6.8), Vector3(0.16, 0.012, 2.1), side * 0.34))
				panels.append(Art._transform(Vector3(side * 11.3, 0.023, -6.0), Vector3(4.8, 0.01, 9.8)))
			Art._batch(deck, "ServiceIslands", "armor", inlay, panels, false)
			Art._batch(deck, "RunwayMarkings", "box", "deck_mark", hatching, false)
			Art._label(deck, "VECTOR / 01", Vector3(-10.8, 0.055, -8.5), 58, "deck_mark")
			Art._label(deck, "LANDING ZONE", Vector3(0, 0.058, 6.0), 34, "deck_mark")
		1:
			Art._part(deck, "box", Vector3(0, 0.022, 0), Vector3(28.0, 0.012, 6.2), inlay)
			Art._part(deck, "box", Vector3(0, 0.024, 0), Vector3(5.7, 0.012, 28.0), inlay)
			for side: float in [-1.0, 1.0]:
				for z: float in [-8.2, 8.2]:
					var grille: Node3D = Art._group(deck, "HeatExchangerGrille", Vector3(side * 9.6, 0.036, z))
					Art._part(grille, "armor", Vector3.ZERO, Vector3(6.0, 0.012, 5.2), "titanium")
					Art._part(grille, "box", Vector3(0, 0.012, 0), Vector3(5.7, 0.012, 4.9), inlay)
					var slots: Array[Transform3D] = []
					for index: int in range(12):
						slots.append(Art._transform(Vector3(-2.5 + float(index) * 0.45, 0.026, 0), Vector3(0.065, 0.012, 4.4)))
					Art._batch(grille, "VentSlats", "box", "edge", slots, false)
					Art._part(grille, "box", Vector3(0, 0.03, -2.30), Vector3(5.3, 0.012, 0.11), "solar_dim")
				Art._part(deck, "box", Vector3(side * 3.1, 0.041, 0), Vector3(0.10, 0.012, 27.0), "solar_dim")
				Art._part(deck, "box", Vector3(0, 0.043, side * 3.35), Vector3(27.0, 0.012, 0.10), "solar_dim")
				for index: int in range(8):
					hatching.append(Art._transform(Vector3(side * 3.6, 0.041, -1.4 + float(index) * 0.4), Vector3(0.40, 0.012, 0.12), side * -0.5))
			Art._batch(deck, "ThermalHatching", "box", "solar_dim", hatching, false)
			Art._label(deck, "SOLAR / 02", Vector3(0, 0.058, 10.5), 66, "solar_dim")
			Art._label(deck, "HEAT TRANSFER", Vector3(0, 0.058, -9.5), 36, "solar_dim")
		2:
			Art._part(deck, "octagon", Vector3(0, 0.027, 0), Vector3(11.8, 0.013, 11.8), inlay, Vector3(0, PI * 0.125, 0))
			for radius: float in [4.8, 8.2, 11.3]:
				var containment: Node3D = Art._group(deck, "ContainmentTrack", Vector3(0, 0.042, 0))
				Art._ring(containment, radius, 0.075, 0.012, "storm_dim", 64, 0.06)
			for index: int in range(12):
				var angle: float = TAU * float(index) / 12.0
				var direction: Vector3 = Vector3(sin(angle), 0, cos(angle))
				panels.append(Art._transform(direction * 9.65 + Vector3(0, 0.046, 0), Vector3(0.6, 0.014, 2.5), angle))
				for side: float in [-1.0, 1.0]:
					var offset: Vector3 = direction.rotated(Vector3.UP, PI * 0.5) * side * 0.37
					hatching.append(Art._transform(direction * 9.65 + offset + Vector3(0, 0.049, 0), Vector3(0.055, 0.012, 2.5), angle))
			Art._batch(deck, "RadialArmor", "armor", "edge", panels, false)
			Art._batch(deck, "ContainmentConduits", "box", "storm_dim", hatching, false)
			Art._label(deck, "CONTAINMENT / 03", Vector3(0, 0.058, 7.0), 50, "storm_dim")
			Art._label(deck, "STORM CORE", Vector3(0, 0.058, -7.0), 40, "storm_dim")


static func _build_navigation(stage: Node3D, sector: int, accent: String) -> void:
	var marks: Array[Transform3D] = []
	var stripes: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		for z: float in [-11.0, -7.0, -3.0, 1.0, 5.0, 9.0, 13.0]:
			marks.append(Art._transform(Vector3(side * 13.8, 0.05, z), Vector3(0.36, 0.021, 0.06)))
		for x: float in [-12.0, -11.6, -11.2, -10.8]:
			stripes.append(Art._transform(Vector3(x * side, 0.054, -13.8), Vector3(0.14, 0.02, 0.75), -0.6 * side))
		var mast: Node3D = Art._group(stage, "SectorBeacon", Vector3(side * 17.6, -0.4, 12.8))
		Art._part(mast, "armor", Vector3(0, 0.24, 0), Vector3(1.6, 0.48, 1.6), "dark")
		Art._part(mast, "armor", Vector3(0, 1.12, 0), Vector3(0.46, 1.65, 0.56), "titanium")
		Art._part(mast, "box", Vector3(0, 1.22, 0.29), Vector3(0.22, 0.85, 0.025), accent)
		var beacon: Node3D = Art._group(mast, "LightCrown", Vector3(0, 2.06, 0))
		Art._ring(beacon, 0.43, 0.11, 0.10, accent, 8, 0.18)
		(stage.get_meta("beacons") as Array).append(beacon)
	Art._batch(stage, "SectorNavigation", "box", accent, marks, false)
	Art._batch(stage, "LandingHatching", "box", "titanium", stripes, false)
	Art._label(stage, "%02d" % (sector + 1), Vector3(12.4, 0.065, 12.8), 136, accent)
	stage.get_child(-1).name = "SectorNumber"
	Art._label(stage, "FLIGHT SYSTEMS / " + SECTOR_NAMES[sector], Vector3(0, 0.065, 13.85), 26, accent)
	stage.get_child(-1).name = "FlightSystemsLabel"


static func _build_light_frame(stage: Node3D, sector: int) -> void:
	# Recessed power rails are below and outside the entire playable deck. Their
	# saturated silhouette frames the fight without adding floor-level warnings.
	var frame: Node3D = Art._group(stage, "StageLightFrame")
	var housings: Array[Transform3D] = []
	var primary: Array[Transform3D] = []
	var secondary: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		for z: float in [-12.0, -4.0, 4.0, 12.0]:
			housings.append(Art._transform(Vector3(side * 16.65, -0.50, z), Vector3(0.64, 0.56, 6.8)))
			primary.append(Art._transform(Vector3(side * 16.66, -0.20, z), Vector3(0.14, 0.06, 6.2)))
			secondary.append(Art._transform(Vector3(side * 16.97, -0.46, z), Vector3(0.05, 0.17, 5.4)))
	for x: float in [-12.0, -4.0, 4.0, 12.0]:
		housings.append(Art._transform(Vector3(x, -0.50, 16.65), Vector3(6.8, 0.56, 0.64)))
		primary.append(Art._transform(Vector3(x, -0.20, 16.66), Vector3(6.2, 0.06, 0.14)))
		secondary.append(Art._transform(Vector3(x, -0.46, 16.97), Vector3(5.4, 0.17, 0.05)))
	Art._batch(frame, "PowerRailHousing", "armor", "dark", housings, false)
	Art._batch(frame, "SectorPowerRail", "box", SECTOR_LAMPS[sector], primary, false)
	Art._batch(frame, "ReturnPowerRail", "box", "storm_lamp" if sector == 0 else "sky_lamp", secondary, false)
	for side: float in [-1.0, 1.0]:
		var wash := MeshInstance3D.new()
		wash.name = "ApronLightWash"
		if not _light_wash_mesh:
			_light_wash_mesh = QuadMesh.new()
			_light_wash_mesh.size = Vector2.ONE
		wash.mesh = _light_wash_mesh
		wash.material_override = _light_wash_material(SECTOR_LAMPS[sector] if side < 0 else "storm_lamp" if sector == 0 else "sky_lamp")
		wash.position = Vector3(side * 21.4, -2.1, 2.0)
		wash.rotation.x = -PI * 0.5
		wash.scale = Vector3(11.0, 24.0, 1.0)
		wash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		frame.add_child(wash)


static func _light_wash_material(key: String) -> ShaderMaterial:
	if _light_wash_materials.has(key): return _light_wash_materials[key]
	if not _light_wash_shader:
		_light_wash_shader = Shader.new()
		# A pair of soft, depth-tested exterior washes supplies local atmosphere
		# without post-processing, texture assets, extra lights or a TIME clock.
		_light_wash_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color;
void fragment() {
	float r = length((UV - vec2(0.5)) * 2.0);
	float falloff = 1.0 - smoothstep(0.0, 1.0, r);
	ALBEDO = tint.rgb;
	ALPHA = falloff * falloff * 0.34;
}
"""
	var material := ShaderMaterial.new()
	material.shader = _light_wash_shader
	material.set_shader_parameter("tint", Art.PALETTE[key])
	_light_wash_materials[key] = material
	return material


static func apply_generated_dressing(stage: Node3D, current_stage: Dictionary) -> void:
	if not is_instance_valid(stage) or not current_stage.get("generated",false): return
	var old_deck: Node = stage.get_node_or_null("SectorDeckGraphics")
	if old_deck:
		stage.remove_child(old_deck)
		old_deck.queue_free()
	var deck: Node3D = Art._group(stage,"SectorDeckGraphics")
	deck.set_meta("generated",true)
	var cosmetic_seed: int = ("deck-dressing-v1:%d" % int(current_stage.layout_seed)).hash()
	var cosmetic_rng := RandomNumberGenerator.new()
	cosmetic_rng.seed = cosmetic_seed
	var muted: String = ["deck_mark","solar_dim","storm_dim"][int(current_stage.theme)]
	var inlay: String = SECTOR_INLAYS[int(current_stage.theme)]
	var inlays: Array[Transform3D] = []
	var islands: Array[Transform3D] = []
	var dashes: Array[Transform3D] = []
	var edge_ticks: Array[Transform3D] = []
	var route: String = current_stage.route
	var targets: Array = current_stage.targets
	var path: Array[Vector3] = [Vector3(0,0,10)]
	for at: Vector3 in targets: path.append(Vector3(at.x,0,at.z))
	path.append(Vector3(0,0,-11.4))
	# Broad flat paint carries route identity at the gameplay camera's scale.
	# These shapes have no edge height, collision or shadows: they are deck inlays.
	match route:
		"OUTER CIRCUIT":
			var side: float = signf(targets[0].x)
			inlays.append(Art._transform(Vector3(side*7.4,0.020,-1),Vector3(5.5,0.010,23)))
			inlays.append(Art._transform(Vector3(-side*2,0.020,-8.0),Vector3(14,0.010,4.2)))
			inlays.append(Art._transform(Vector3(0,0.020,7.6),Vector3(17,0.010,3.2)))
		"CENTER WEAVE":
			inlays.append(Art._transform(Vector3(0,0.020,0),Vector3(4.6,0.010,23)))
			for at: Vector3 in targets:
				inlays.append(Art._transform(Vector3(at.x*0.5,0.020,at.z),Vector3(absf(at.x)+5.0,0.010,3.4)))
		"TWIN SPURS":
			for side: float in [-1,1]:
				inlays.append(Art._transform(Vector3(side*6.0,0.020,-1),Vector3(4.3,0.010,23)))
			inlays.append(Art._transform(Vector3(0,0.020,targets[1].z),Vector3(16,0.010,2.8)))
		"DIRECT APPROACH":
			inlays.append(Art._transform(Vector3(0,0.020,0),Vector3(6.4,0.010,23)))
			for side: float in [-1,1]:
				inlays.append(Art._transform(Vector3(side*7.0,0.020,side*cosmetic_rng.randf_range(3.8,6.0)),Vector3(5.6,0.010,5.0)))
		_:
			# Switchback and Cross Current follow their visibly different
			# traversals with stepped or wider diagonal painted service lanes.
			for index in range(path.size()-1):
				var direction: Vector3 = path[index+1]-path[index]
				var middle: Vector3 = (path[index]+path[index+1])*0.5
				middle.y = 0.020
				inlays.append(Art._transform(middle,Vector3(4.4 if route=="CROSS CURRENT" else 2.8,0.010,direction.length()),atan2(direction.x,direction.z)))
	for index in range(targets.size()):
		var at: Vector3 = targets[index]
		var width := 5.7 if route=="SWITCHBACK" else 4.4
		islands.append(Art._transform(Vector3(at.x,0.027,at.z),Vector3(width,0.008,3.2),PI*0.25 if route=="CROSS CURRENT" else 0.0))
		# Tiny edge marks read as floor maintenance paint, not hazard warnings.
		for side: float in [-1,1]:
			for tick in range(3):
				edge_ticks.append(Art._transform(Vector3(at.x+side*(width*0.5+0.18),0.041,at.z-0.7+float(tick)*0.7),Vector3(0.34,0.008,0.06)))
	for index in range(path.size()-1):
		var direction: Vector3 = path[index+1]-path[index]
		var count := int(direction.length()/1.55)
		for dash in range(1,count):
			var at: Vector3 = path[index].lerp(path[index+1],float(dash)/float(count))
			var clear := true
			for gate in current_stage.gates:
				if absf(at.z-float(gate.position.z))<1.2: clear=false
			for target: Vector3 in targets:
				if Vector2(at.x-target.x,at.z-target.z).length()<1.2: clear=false
			if not clear: continue
			at.y = 0.041
			dashes.append(Art._transform(at,Vector3(0.075,0.008,0.62),atan2(direction.x,direction.z)))
	for batch: Array in [["RouteInlays","box",inlay,inlays],["RelayIslands","octagon",inlay,islands],["RouteDashes","box",muted,dashes],["IslandTicks","box",muted,edge_ticks]]:
		if batch[3].is_empty(): continue
		Art._batch(deck,batch[0],batch[1],batch[2],batch[3],false)
		# Retain the bounded input transforms for headless geometry validation;
		# Godot's dummy renderer cannot read MultiMesh instance transforms back.
		deck.get_child(-1).set_meta("paint_transforms",batch[3].duplicate())
	Art._label(deck,"%s / %02d" % [route,int(current_stage.index)+1],Vector3(0,0.051,11.8),35,muted)
	deck.get_child(-1).name = "GeneratedRouteLabel"
	var number: Label3D = stage.get_node("SectorNumber")
	number.text = "%02d" % (int(current_stage.index)+1)
	number.font_size = maxi(40,136-maxi(0,number.text.length()-2)*18)
	var systems: Label3D = stage.get_node("FlightSystemsLabel")
	systems.text = "FLIGHT SYSTEMS / %s / DECK %02d" % [current_stage.name,int(current_stage.index)+1]
	stage.set_meta("cosmetic_seed",cosmetic_seed)
	stage.set_meta("generated_paint_instances",inlays.size()+islands.size()+dashes.size()+edge_ticks.size())
	# The existing apron landmarks remain outside the arena. Retain authored
	# transforms so reapplying a seed never accumulates drift or consumes game RNG.
	for child in stage.get_children():
		if not child is Node3D: continue
		var family := ""
		if child.has_node("Rotor") and absf(child.position.x)>19.0 and absf(child.position.z)<14.0: family="turbine"
		elif child.has_node("SolarPanel"): family="panel"
		elif child.has_node("ContainmentCrown"): family="conductor"
		elif child.has_node("LightCrown"): family="beacon"
		elif child.name in ["SolarCollector","StormLandmark"]: family="landmark"
		if family.is_empty(): continue
		if not child.has_meta("dressing_origin"): child.set_meta("dressing_origin",child.transform)
		var original: Transform3D = child.get_meta("dressing_origin")
		child.transform = original
		child.position.x += signf(original.origin.x)*cosmetic_rng.randf_range(0.25,0.55)
		child.position.z += cosmetic_rng.randf_range(-1.2,1.2) if family!="beacon" else cosmetic_rng.randf_range(-0.5,0.5)
		child.rotation.y += cosmetic_rng.randf_range(-0.06,0.06) if family=="landmark" else cosmetic_rng.randf_range(-0.14,0.14)
		child.set_meta("generated_landmark",true)


static func _rotor(stage: Node3D, at: Vector3, radius: float, accent: String, vertical: bool = false) -> Node3D:
	var housing: Node3D = Art._group(stage, "TurbineHousing", at)
	if vertical:
		housing.rotation.x = PI * 0.5
	Art._ring(housing, radius, 0.15, 0.28, "titanium", 32, 0.02)
	Art._ring(housing, radius * 0.91, 0.055, 0.065, accent, 24, 0.24)
	var rotor: Node3D = Art._group(housing, "Rotor")
	Art._part(rotor, "cone", Vector3.ZERO, Vector3(radius * 0.18, 0.45, radius * 0.18), "ceramic")
	var blades: Array[Transform3D] = []
	for index: int in range(9):
		var angle: float = TAU * float(index) / 9.0
		blades.append(Art._transform(Vector3(sin(angle), 0, cos(angle)) * radius * 0.54, Vector3(radius * 0.15, 0.11, radius * 0.66), angle + 0.42))
	Art._batch(rotor, "Blades", "armor", "edge", blades)
	(stage.get_meta("rotors") as Array).append(rotor)
	return housing


static func _build_skyport(stage: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		var x: float = side * 21.8
		Art._part(stage, "armor", Vector3(x, -1.2, 2), Vector3(6.2, 1.1, 15.0), "steel")
		Art._part(stage, "box", Vector3(x, -0.62, 2), Vector3(5.4, 0.08, 12.6), "deck")
		_rotor(stage, Vector3(x, -0.48, 0), 2.35, "cyan")
		Art._beam(stage, Vector3(side * 16.3, -1.0, 7), Vector3(x, -2.8, 7), 0.25, "titanium")
		for z: float in [-4.0, 7.0]:
			Art._part(stage, "armor", Vector3(x, -0.15, z), Vector3(4.8, 0.22, 0.8), "ceramic")
			Art._part(stage, "box", Vector3(x, -0.018, z + 0.1), Vector3(2.0, 0.04, 0.06), "cyan")
	var arch: Node3D = Art._group(stage, "DockingGantry", Vector3(11, 0, -21))
	for side: float in [-1.0, 1.0]:
		Art._part(arch, "armor", Vector3(side * 4.0, 1.6, 0), Vector3(0.7, 5.0, 1.1), "titanium")
		Art._beam(arch, Vector3(side * 4.0, 3.8, 0), Vector3(side * 2.6, 5.1, 0), 0.18, "edge")
	Art._part(arch, "armor", Vector3(0, 5.05, 0), Vector3(5.7, 0.5, 0.75), "ceramic")
	Art._part(arch, "box", Vector3(0, 4.91, 0.39), Vector3(3.8, 0.065, 0.035), "cyan")
	_rotor(stage, Vector3(11, 2.9, -21.0), 1.85, "cyan", true)


static func _build_solar(stage: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		for index: int in range(3):
			if side < 0.0 and index == 0:
				continue
			var at: Vector3 = Vector3(side * (20.0 + float(index) * 2.1), -1.4, -10.0 + float(index) * 8.5)
			var bank: Node3D = Art._group(stage, "Heliostat", at)
			Art._part(bank, "octagon", Vector3(0, 0.3, 0), Vector3(1.3, 0.6, 1.3), "dark")
			Art._part(bank, "cylinder", Vector3(0, 1.3, 0), Vector3(0.23, 2.0, 0.23), "titanium")
			var panel: Node3D = Art._group(bank, "SolarPanel", Vector3(0, 2.7, 0))
			panel.rotation = Vector3(-0.22, side * 0.32, side * 0.14)
			Art._part(panel, "armor", Vector3.ZERO, Vector3(4.7, 0.18, 3.7), "titanium")
			var cells: Array[Transform3D] = []
			var conductors: Array[Transform3D] = []
			for x: int in range(6):
				for z: int in range(5):
					cells.append(Art._transform(Vector3(-1.87 + float(x) * 0.75, 0.12, -1.35 + float(z) * 0.68), Vector3(0.68, 0.06, 0.61)))
				conductors.append(Art._transform(Vector3(-1.87 + float(x) * 0.75, 0.158, 0), Vector3(0.032, 0.01, 3.3)))
			Art._batch(panel, "PhotovoltaicCells", "box", "visor", cells)
			Art._batch(panel, "SolarConductors", "box", "solar", conductors, false)
	# Side-apron landmarks stay in the gameplay camera's frame; rear towers would
	# project behind the HUD at this elevation. Their full footprints clear ±16.3.
	var furnace: Node3D = Art._group(stage, "SolarCollector", Vector3(-21.8, -1.4, -10.0))
	furnace.scale = Vector3.ONE * 0.8
	Art._part(furnace, "octagon", Vector3(0, -1.3, 0), Vector3(5.8, 1.1, 5.8), "dark")
	Art._part(furnace, "octagon", Vector3(0, 0.5, 0), Vector3(2.6, 3.0, 2.6), "steel")
	Art._part(furnace, "octagon", Vector3(0, 2.25, 0), Vector3(3.15, 0.55, 3.15), "titanium")
	Art._part(furnace, "octagon", Vector3(0, 3.1, 0), Vector3(1.72, 1.3, 1.72), "solar")
	Art._part(furnace, "cone", Vector3(0, 4.0, 0), Vector3(2.3, 0.6, 2.3), "steel")
	for height: float in [2.6, 3.35, 4.65]:
		var collar: Node3D = Art._group(furnace, "CollectorCollar", Vector3(0, height, 0))
		Art._ring(collar, 2.65 if height < 4.0 else 3.75, 0.12, 0.15, "solar", 16, 0.30)
		(stage.get_meta("orbitals") as Array).append(collar)
	for side: float in [-1.0, 1.0]:
		Art._beam(furnace, Vector3(side * 5.0, -0.8, 0), Vector3(side * 3.0, 4.8, 0), 0.28, "titanium")
		Art._part(furnace, "armor", Vector3(side * 3.0, 4.9, 0), Vector3(0.6, 0.5, 0.8), "ceramic")
	_build_distant_spires(stage, "solar", 93)


static func _build_storm(stage: Node3D) -> void:
	var landmark: Node3D = Art._group(stage, "StormLandmark", Vector3(22.0, -1.8, -10.0))
	landmark.scale = Vector3.ONE * 0.8
	var core: Node3D = Art._group(landmark, "StormEngine", Vector3(0, 4.3, 0))
	Art._part(core, "sphere", Vector3.ZERO, Vector3.ONE * 1.6, "visor")
	Art._part(core, "octagon", Vector3(0, 0, 1.3), Vector3(0.68, 0.2, 0.68), "storm", Vector3(PI * 0.5, 0, 0))
	for index: int in range(3):
		var halo: Node3D = Art._group(core, "Gyroscope", Vector3.ZERO)
		halo.rotation = Vector3(PI * 0.5 + float(index) * 0.65, float(index) * 0.7, 0)
		Art._ring(halo, 2.7 + float(index) * 0.58, 0.17, 0.14, "titanium", 48, 0.02)
		Art._ring(halo, 2.65 + float(index) * 0.58, 0.055, 0.2, "storm", 24, 0.32)
		(stage.get_meta("orbitals") as Array).append(halo)
	for side: float in [-1.0, 1.0]:
		for index: int in range(3):
			var height: float = 4.6 + float(index) * 1.4
			var at: Vector3 = Vector3(side * (19.0 + float(index) * 1.8), height * 0.5 - 1.8, 8.0 - float(index) * 13.0)
			var pylon: Node3D = Art._group(stage, "StormConductor", at)
			Art._part(pylon, "armor", Vector3.ZERO, Vector3(1.5, height, 1.9), "steel", Vector3(0, 0, -side * 0.085))
			Art._part(pylon, "armor", Vector3(0, height * 0.45, 0), Vector3(2.3, 0.7, 2.3), "titanium")
			Art._part(pylon, "box", Vector3(-side * 0.56, 0, 1.02), Vector3(0.10, height * 0.72, 0.05), "storm")
			var crown: Node3D = Art._group(pylon, "ContainmentCrown", Vector3(0, height * 0.6, 0))
			Art._ring(crown, 1.05, 0.12, 0.10, "storm", 12, 0.44)
			(stage.get_meta("beacons") as Array).append(crown)
		Art._beam(landmark, Vector3(side * 7.0, -1.4, 0), Vector3(side * 4.4, 7.9, 0), 0.4, "titanium")
		Art._part(landmark, "armor", Vector3(side * 4.4, 8.0, 0), Vector3(1.2, 0.7, 1.4), "storm")
	_build_distant_spires(stage, "storm", 319)


static func _build_distant_spires(stage: Node3D, accent: String, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var spires: Array[Transform3D] = []
	var lights: Array[Transform3D] = []
	for index: int in range(25):
		var at: Vector3 = Vector3(-75.0 + float(index) * 6.0, 0, rng.randf_range(-70.0, -43.0))
		var height: float = rng.randf_range(7.0, 23.0)
		at.y = height * 0.5 - 12.0
		spires.append(Art._transform(at, Vector3(rng.randf_range(1.5, 4.0), height, 3.0)))
		lights.append(Art._transform(at + Vector3(0, height * 0.32, 1.55), Vector3(0.10, height * 0.32, 0.025)))
	Art._batch(stage, "SectorSkyline", "armor", "distant", spires, false)
	Art._batch(stage, "SkylinePower", "box", accent, lights, false)


static func animate_stage(stage: Node3D, delta: float, time: float) -> void:
	if not is_instance_valid(stage):
		return
	for rotor: Node3D in stage.get_meta("rotors", []):
		rotor.rotate_y(delta * 1.25)
	var index: int = 0
	for orbital: Node3D in stage.get_meta("orbitals", []):
		orbital.rotate_y(delta * (0.16 + float(index) * 0.05) * (-1.0 if index % 2 else 1.0))
		index += 1
	for beacon: Node3D in stage.get_meta("beacons", []):
		beacon.rotation.y = time * 0.35


static func gate(closed_label: String = "LINK RELAYS TO UNLOCK", open_label: String = "TRANSFER READY  //  ENTER") -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TransferGate"
	var doors: Array[Node3D] = []
	# Exact visible barrier bounds when shut: x +/-5, y 0..1.8, z +/-.225.
	for side: float in [-1.0, 1.0]:
		var door: Node3D = Art._group(root, "DoorLeft" if side < 0 else "DoorRight", Vector3(side * 2.5, 0.9, 0))
		Art._part(door, "armor", Vector3.ZERO, Vector3(5.0, 1.8, 0.45), "steel")
		Art._part(door, "armor", Vector3(0, 0, 0.225), Vector3(4.6, 1.37, 0.04), "titanium")
		Art._part(door, "box", Vector3(0, 0.52, 0.26), Vector3(4.46, 0.05, 0.025), "amber")
		Art._part(door, "box", Vector3(0, -0.52, 0.26), Vector3(4.46, 0.05, 0.025), "amber")
		for index: int in range(4):
			var x: float = -1.5 + float(index) * 1.0
			Art._part(door, "box", Vector3(x, 0, 0.268), Vector3(0.12, 0.6, 0.025), "dark", Vector3(0, 0, -side * 0.52))
		Art._part(door, "box", Vector3(-side * 2.36, 0, 0.26), Vector3(0.10, 1.25, 0.035), "solar")
		doors.append(door)
		var pylon: Node3D = Art._group(root, "GatePylon", Vector3(side * 5.4, 0, 0))
		Art._part(pylon, "armor", Vector3(0, 0.2, 0), Vector3(1.05, 0.4, 1.2), "dark")
		Art._part(pylon, "armor", Vector3(0, 0.92, 0), Vector3(0.60, 1.60, 0.9), "titanium")
		Art._part(pylon, "box", Vector3(0, 0.96, 0.46), Vector3(0.19, 1.20, 0.035), "cyan")
		Art._part(pylon, "armor", Vector3(0, 1.71, 0), Vector3(1.0, 0.20, 1.15), "ceramic")
	# No overhead beam: an airborne courier must clear the visible geometry as
	# soon as the gameplay clearance test allows it to cross the low shutters.
	Art._part(root, "box", Vector3(0, 0.028, 0), Vector3(10.0, 0.045, 0.55), "dark")
	var guide: Node3D = Art._group(root, "PassageGuide", Vector3(0, 0.065, 0))
	for index: int in range(3):
		for side: float in [-1.0, 1.0]:
			Art._part(guide, "box", Vector3(side * 0.23, 0, 1.0 + float(index) * 0.55), Vector3(0.08, 0.023, 0.5), "cyan", Vector3(0, side * 0.65, 0))
	var label: Label3D = Label3D.new()
	label.name = "GateStatus"
	label.text = closed_label
	label.position = Vector3(0, 2.65, 0.52)
	label.font_size = 36
	label.pixel_size = 0.009
	label.modulate = Art.PALETTE.cyan
	label.outline_size = 5
	label.no_depth_test = false
	root.add_child(label)
	root.set_meta("doors", doors)
	root.set_meta("status", label)
	root.set_meta("guide", guide)
	root.set_meta("open_state", false)
	root.set_meta("closed_label", closed_label)
	root.set_meta("open_label", open_label)
	return root


static func animate_gate(model: Node3D, openness: float, time: float) -> void:
	var open: float = clampf(openness, 0.0, 1.0)
	var doors: Array = model.get_meta("doors", [])
	for index: int in range(doors.size()):
		var door: Node3D = doors[index]
		door.position.x = (-1.0 if index == 0 else 1.0) * (2.5 + 5.0 * open)
	var guide: Node3D = model.get_meta("guide")
	guide.visible = open > 0.5
	guide.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.045)
	var unlocked: bool = open > 0.94
	if unlocked != bool(model.get_meta("open_state", false)):
		model.set_meta("open_state", unlocked)
		var label: Label3D = model.get_meta("status")
		label.text = str(model.get_meta("open_label")) if unlocked else str(model.get_meta("closed_label"))


static func target_ring() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "FlightRelay"
	var visual: Node3D = Art._group(root, "Visual")
	var hoop: Node3D = Art._group(visual, "Hoop")
	hoop.rotation.x = PI * 0.5
	Art._ring(hoop, 1.1, 0.16, 0.18, "titanium", 48, 0.015)
	Art._ring(hoop, 1.0, 0.045, 0.20, "cyan", 36, 0.12)
	var orbit: Node3D = Art._group(visual, "Orbit")
	orbit.rotation.x = PI * 0.5
	Art._ring(orbit, 1.29, 0.035, 0.05, "teal", 12, 0.65)
	for side: float in [-1.0, 1.0]:
		Art._part(visual, "armor", Vector3(side * 1.12, 0, 0), Vector3(0.24, 0.42, 0.35), "ceramic")
		Art._part(visual, "box", Vector3(side * 1.12, 0, 0.19), Vector3(0.09, 0.18, 0.028), "cyan")
		Art._part(visual, "prism", Vector3(side * 0.55, -0.26, 0), Vector3(0.17, 0.24, 0.055), "cyan", Vector3(0, 0, -side * PI * 0.5))
	var pad: Node3D = Art._group(root, "GroundAnchor", Vector3(0, -2.55, 0))
	Art._part(pad, "octagon", Vector3(0, -0.02, 0), Vector3(0.60, 0.08, 0.60), "dark")
	Art._ring(pad, 0.57, 0.055, 0.04, "teal", 16, 0.18)
	Art._part(pad, "octagon", Vector3(0, 0.13, 0), Vector3(0.24, 0.22, 0.24), "titanium")
	Art._part(pad, "octagon", Vector3(0, 0.255, 0), Vector3(0.17, 0.035, 0.17), "cyan")
	# Interrupted light tether establishes the ring's altitude and ground location.
	for index: int in range(5):
		Art._part(pad, "box", Vector3(0, 0.43 + float(index) * 0.17, 0), Vector3(0.026, 0.08, 0.026), "teal_dim")
	root.set_meta("visual", visual)
	root.set_meta("orbit", orbit)
	root.set_meta("anchor", pad)
	root.set_meta("collected", false)
	return root


static func animate_target(model: Node3D, time: float, collected: bool = false) -> void:
	var visual: Node3D = model.get_meta("visual")
	var orbit: Node3D = model.get_meta("orbit")
	visual.position.y = sin(time * 2.0) * 0.045
	orbit.rotation.y = time * 0.72
	if collected != bool(model.get_meta("collected", false)):
		model.set_meta("collected", collected)
		visual.visible = not collected
		var anchor: Node3D = model.get_meta("anchor")
		anchor.scale = Vector3.ONE * (0.58 if collected else 1.0)
