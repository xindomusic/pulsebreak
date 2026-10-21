extends CanvasLayer
const Rules = preload("res://scripts/rules.gd")
const Palette = preload("res://scripts/palette.gd")
signal action(name: String, value: Variant)
## One color-token set for the whole game: deep-navy ink, mint-cyan player,
## amber harvest, coral threat. The 3D palette in art.gd uses the same hues.
# Theme tokens snapshot at build; game rebuilds the HUD after a theme swap.
var INK: Color = Palette.INK
var CYAN: Color = Palette.MINT
var MUTED: Color = Palette.MUTED
var WHITE: Color = Palette.WHITE
var AMBER: Color = Palette.AMBER
var CORAL: Color = Palette.CORAL
var SIGNAL: Color = Palette.SIGNAL
var root: Control
var modal: Control
var hud: Control
var health_bar: ProgressBar
var energy_bar: ProgressBar
var health_text: Label
var energy_text: Label
var dash_text: Label
var time_text: Label
var score_text: Label
var status_text: Label
var hint: Label
var banner: Label
var boss_bar: ProgressBar
var boss_name: Label
var build_text: Label
var theme_ui: Theme
var regular: Font
var heavy: Font
var mono: Font
var hint_time := 0.0
var banner_time := 0.0
var offers: Array = []
var key_names: Dictionary = {"left":"A","right":"D","up":"W","down":"S","dash":"Space","pulse":"E","jump":"F","weapon":"Q"}
var harvest_guide: Label
var flight_bar: ProgressBar
var flight_text: Label
var altitude_text: Label
var objective_text: Label
var weapon_text: Label
var weapon_detail: Label
var combo_text: Label
var combo_bar: ProgressBar
var dash_pips: Control
var low_hull := false
var pulse_ready_ratio := 0.3
var boss_plate: Panel
var banner_plate: Panel
var motion_enabled := true
var settings_note := ""
var update_bar: ProgressBar
var update_status: Label
var effects_low := false

## Drawn vector icon set. One stroke language for upgrades, perks and marks,
## replacing unicode glyphs whose sizes and weights never matched.
class Glyph:
	extends Control
	var kind := ""
	var color := Color.WHITE
	var width_scale := 1.0
	var ringed := false
	var bold := false
	var cut := Color(0, 0, 0, 0)
	func _init(k: String = "", c: Color = Color.WHITE, s: float = 48.0) -> void:
		kind = k
		color = c
		custom_minimum_size = Vector2(s, s)
		size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.42
		var w := maxf(2.0, minf(size.x, size.y) * 0.055) * width_scale
		if bold and kind == "echo":
			# Three offset crescents: the blast and its two repeats.
			for i in range(3):
				var cc := c + Vector2(-r * 0.45 + float(i) * r * 0.45, r * 0.3 - float(i) * r * 0.3)
				var rr := r * (0.62 - float(i) * 0.13)
				draw_circle(cc, rr, color)
				draw_circle(cc + Vector2(rr * 0.45, -rr * 0.25), rr * 0.78, cut if cut.a > 0.0 else Color(0.05, 0.06, 0.07))
			return
		if bold:
			w *= 1.9
			var cutc: Color = cut if cut.a > 0.0 else Color(0.05, 0.06, 0.07)
			match kind:
				"collector":
					draw_arc(c + Vector2(r * 0.3, 0), r * 0.68, PI * 0.55, PI * 1.45, 28, color, w * 1.15, true)
					draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.5, -r * 0.3), c + Vector2(r * 0.95, 0), c + Vector2(r * 0.5, r * 0.3), c + Vector2(r * 0.15, 0)]), color)
					return
				"siphon":
					draw_circle(c, r * 0.85, color)
					draw_line(c + Vector2(-r * 0.42, 0), c + Vector2(r * 0.42, 0), cutc, w * 1.1, true)
					draw_line(c + Vector2(0, -r * 0.42), c + Vector2(0, r * 0.42), cutc, w * 1.1, true)
					return
				"frost":
					var hex := PackedVector2Array()
					for i in range(6):
						hex.append(c + Vector2.RIGHT.rotated(TAU * float(i) / 6.0 - PI * 0.5) * r * 0.98)
					draw_colored_polygon(hex, color)
					for i in range(2):
						var yy := c.y - r * 0.3 + float(i) * r * 0.44
						draw_polyline(PackedVector2Array([Vector2(c.x - r * 0.36, yy), Vector2(c.x, yy + r * 0.28), Vector2(c.x + r * 0.36, yy)]), cutc, w, true)
					return
				"ignite":
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.92, r * 0.78), c + Vector2(-r * 0.92, r * 0.78)]), color)
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.25), c + Vector2(r * 0.3, r * 0.38), c + Vector2(0, r * 0.58), c + Vector2(-r * 0.3, r * 0.38)]), cutc)
					return
				"hull":
					var plate := PackedVector2Array([c + Vector2(-r * 0.55, -r * 0.88), c + Vector2(r * 0.55, -r * 0.88), c + Vector2(r * 0.92, -r * 0.3), c + Vector2(r * 0.92, r * 0.45), c + Vector2(r * 0.4, r * 0.92), c + Vector2(-r * 0.4, r * 0.92), c + Vector2(-r * 0.92, r * 0.45), c + Vector2(-r * 0.92, -r * 0.3)])
					draw_colored_polygon(plate, color)
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.38), c + Vector2(r * 0.3, r * 0.08), c + Vector2(0, r * 0.52), c + Vector2(-r * 0.3, r * 0.08)]), cutc)
					return
				"battery":
					draw_rect(Rect2(c - Vector2(r * 0.88, r * 0.62), Vector2(r * 1.76, r * 1.24)), color)
					draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.92), Vector2(r * 0.6, r * 0.3)), color)
					draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.18, -r * 0.44), c + Vector2(-r * 0.34, r * 0.08), c + Vector2(-r * 0.02, r * 0.08), c + Vector2(-r * 0.18, r * 0.44), c + Vector2(r * 0.34, -r * 0.08), c + Vector2(r * 0.02, -r * 0.08)]), cutc)
					return
		if ringed:
			# Reactor seal: every system glyph sits inside the broken sigil ring.
			var ring_color := color
			ring_color.a *= 0.75
			draw_arc(c, r * 1.12, 0.5, TAU - 1.3, 44, ring_color, w * 0.8, true)
			draw_arc(c, r * 1.12, TAU - 0.9, TAU - 0.1, 12, ring_color, w * 0.8, true)
			draw_circle(c + Vector2.RIGHT.rotated(0.5) * r * 1.12, w * 0.55, ring_color)
			r *= 0.62
		match kind:
			"collector":
				draw_arc(c + Vector2(r * 0.25, 0), r * 0.85, PI * 0.55, PI * 1.45, 28, color, w, true)
				draw_arc(c + Vector2(r * 0.25, 0), r * 0.55, PI * 0.6, PI * 1.4, 24, color, w, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.55, -r * 0.22), c + Vector2(r * 0.85, 0), c + Vector2(r * 0.55, r * 0.22), c + Vector2(r * 0.28, 0)]), color)
				draw_circle(c + Vector2(-r * 0.35, 0), w * 0.7, color)
				draw_circle(c + Vector2(r * 0.02, 0), w * 0.5, color)
			"capacitor":
				var p := PackedVector2Array([c + Vector2(r * 0.25, -r), c + Vector2(-r * 0.55, r * 0.18), c + Vector2(-r * 0.05, r * 0.18), c + Vector2(-r * 0.25, r), c + Vector2(r * 0.55, -r * 0.18), c + Vector2(r * 0.05, -r * 0.18)])
				draw_colored_polygon(p, color)
			"siphon":
				draw_arc(c, r, 0, TAU, 40, color, w, true)
				draw_line(c + Vector2(-r * 0.45, 0), c + Vector2(r * 0.45, 0), color, w * 1.6, true)
				draw_line(c + Vector2(0, -r * 0.45), c + Vector2(0, r * 0.45), color, w * 1.6, true)
			"echo":
				for i in range(3):
					var start := -0.6 + float(i) * 1.15
					draw_arc(c, r * (0.38 + 0.3 * float(i)), start, start + TAU * 0.74, 36, color, w, true)
				draw_circle(c, w, color)
			"radius":
				draw_arc(c, r * 0.72, 0, TAU, 40, color, w, true)
				for i in range(8):
					var a := TAU * float(i) / 8.0
					draw_line(c + Vector2.RIGHT.rotated(a) * r * 0.84, c + Vector2.RIGHT.rotated(a) * r * 1.05, color, w, true)
			"chain":
				var nodes := [c + Vector2(-r, r * 0.4), c + Vector2(-r * 0.33, -r * 0.35), c + Vector2(r * 0.33, r * 0.35), c + Vector2(r, -r * 0.4)]
				draw_polyline(PackedVector2Array(nodes), color, w, true)
				for n in nodes: draw_circle(n, w * 1.05, color)
			"wake":
				var pts := PackedVector2Array()
				for i in range(25):
					var t := float(i) / 24.0
					pts.append(Vector2(lerpf(c.x - r, c.x + r, t), c.y + sin(t * TAU * 1.5) * r * 0.45))
				draw_polyline(pts, color, w, true)
				draw_circle(pts[24], w, color)
			"frost":
				var hex := PackedVector2Array()
				for i in range(6):
					hex.append(c + Vector2.RIGHT.rotated(TAU * float(i) / 6.0 - PI * 0.5) * r * 0.95)
				hex.append(hex[0])
				draw_polyline(hex, color, w, true)
				for i in range(2):
					var yy := c.y - r * 0.28 + float(i) * r * 0.42
					draw_polyline(PackedVector2Array([Vector2(c.x - r * 0.34, yy), Vector2(c.x, yy + r * 0.26), Vector2(c.x + r * 0.34, yy)]), color, w, true)
			"ignite":
				var tri := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.9, r * 0.75), c + Vector2(-r * 0.9, r * 0.75), c + Vector2(0, -r)])
				draw_polyline(tri, color, w, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.3), c + Vector2(r * 0.3, r * 0.35), c + Vector2(0, r * 0.55), c + Vector2(-r * 0.3, r * 0.35)]), color)
			"hull":
				var plate := PackedVector2Array([c + Vector2(-r * 0.55, -r * 0.85), c + Vector2(r * 0.55, -r * 0.85), c + Vector2(r * 0.9, -r * 0.3), c + Vector2(r * 0.9, r * 0.45), c + Vector2(r * 0.4, r * 0.9), c + Vector2(-r * 0.4, r * 0.9), c + Vector2(-r * 0.9, r * 0.45), c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(-r * 0.55, -r * 0.85)])
				draw_polyline(plate, color, w, true)
				draw_line(c + Vector2(-r * 0.9, r * 0.05), c + Vector2(r * 0.9, r * 0.05), color, w * 0.8, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.3), c + Vector2(r * 0.24, r * 0.05), c + Vector2(0, r * 0.45), c + Vector2(-r * 0.24, r * 0.05)]), color)
				for rivet in [Vector2(-0.68, -0.62), Vector2(0.68, -0.62), Vector2(-0.68, 0.62), Vector2(0.68, 0.62)]:
					draw_circle(c + rivet * r, w * 0.45, color)
			"dash":
				var wing := PackedVector2Array([c + Vector2(-r * 0.85, r * 0.55), c + Vector2(-r * 0.2, -r * 0.15), c + Vector2(r * 0.95, -r * 0.85), c + Vector2(r * 0.55, r * 0.05), c + Vector2(r * 0.75, -r * 0.02), c + Vector2(r * 0.25, r * 0.5), c + Vector2(r * 0.35, r * 0.62), c + Vector2(-r * 0.35, r * 0.72), c + Vector2(-r * 0.85, r * 0.55)])
				draw_polyline(wing, color, w, true)
				draw_line(c + Vector2(-r * 0.2, -r * 0.15), c + Vector2(r * 0.25, r * 0.5), color, w * 0.8, true)
				draw_line(c + Vector2(-r * 0.95, r * 0.85), c + Vector2(-r * 0.45, r * 0.85), color, w, true)
			"harvest":
				draw_arc(c + Vector2(-r * 0.35, 0), r * 0.6, 0, TAU, 32, color, w, true)
				draw_arc(c + Vector2(r * 0.35, 0), r * 0.6, 0, TAU, 32, color, w, true)
				draw_circle(c, w, color)
			"battery":
				draw_rect(Rect2(c - Vector2(r * 0.85, r * 0.62), Vector2(r * 1.7, r * 1.24)), color, false, w)
				draw_line(c + Vector2(-r * 0.3, -r * 0.62), c + Vector2(-r * 0.3, -r * 0.92), color, w, true)
				draw_line(c + Vector2(r * 0.3, -r * 0.62), c + Vector2(r * 0.3, -r * 0.92), color, w, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.38), c + Vector2(r * 0.3, 0), c + Vector2(0, r * 0.38), c + Vector2(-r * 0.3, 0)]), color)
			"armory":
				var gun := PackedVector2Array([c + Vector2(-r * 0.95, r * 0.08), c + Vector2(-r * 0.3, -r * 0.08), c + Vector2(r * 0.55, -r * 0.08), c + Vector2(r * 0.95, r * 0.02), c + Vector2(r * 0.55, r * 0.14), c + Vector2(-r * 0.05, r * 0.16), c + Vector2(r * 0.02, r * 0.52), c + Vector2(-r * 0.22, r * 0.52), c + Vector2(-r * 0.28, r * 0.14), c + Vector2(-r * 0.95, r * 0.08)])
				draw_polyline(gun, color, w, true)
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.35, -r * 0.42), c + Vector2(0, -r * 0.78), c + Vector2(r * 0.35, -r * 0.42)]), color, w, true)
				draw_circle(c + Vector2(-r * 0.55, r * 0.08), w * 0.55, color)
			"combo":
				draw_arc(c + Vector2(0, r * 0.55), r * 1.05, PI * 1.08, PI * 1.92, 32, color, w, true)
				for i in range(5):
					var a := PI * (1.15 + 0.175 * float(i))
					draw_line(c + Vector2(0, r * 0.55) + Vector2.RIGHT.rotated(a) * r * 0.9, c + Vector2(0, r * 0.55) + Vector2.RIGHT.rotated(a) * r * 1.05, color, w, true)
				draw_line(c + Vector2(0, r * 0.55), c + Vector2(0, r * 0.55) + Vector2.RIGHT.rotated(PI * 1.68) * r * 0.95, color, w * 1.4, true)
				draw_line(c + Vector2(-r * 0.8, r * 0.75), c + Vector2(r * 0.8, r * 0.75), color, w, true)
				draw_circle(c + Vector2(0, r * 0.55), w * 0.8, color)
			"core":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0)]), color)
			"sigil":
				draw_arc(c, r, 0.5, TAU - 1.3, 44, color, w, true)
				draw_arc(c, r * 0.78, 2.4, TAU + 1.1, 40, color, w, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.42), c + Vector2(r * 0.3, 0), c + Vector2(0, r * 0.42), c + Vector2(-r * 0.3, 0)]), color)
				draw_circle(c + Vector2.RIGHT.rotated(0.5) * r, w * 0.9, color)
			_:
				draw_arc(c, r, 0, TAU, 36, color, w, true)
				draw_circle(c, w, color)

## Corner-bracket instrument frame drawn over a panel's edges.
class Frame:
	extends Control
	var color := Color(0.9, 0.9, 0.9, 0.55)
	var accent := Color.WHITE
	var bracket := 14.0
	func _init(ac: Color = Color.WHITE) -> void:
		accent = ac
		color = Color(ac, 0.5)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var s := size
		if s.x < 8.0 or s.y < 8.0: return
		var l := bracket
		var w := 2.0
		var pts := [Vector2(1, 1), Vector2(s.x - 1, 1), Vector2(s.x - 1, s.y - 1), Vector2(1, s.y - 1)]
		var dirs := [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
		for i in range(4):
			var p: Vector2 = pts[i]
			var d: Vector2 = dirs[i]
			draw_line(p, p + Vector2(d.x * l, 0), color, w, true)
			draw_line(p, p + Vector2(0, d.y * l), color, w, true)
		draw_line(Vector2(1, 1), Vector2(minf(49.0, s.x - 1.0), 1), accent, w, true)

## Segment ticks overlaid on a meter, with an optional threshold notch.
class Ticks:
	extends Control
	var divisions := 10
	var threshold := -1.0
	var notch := Color("e3b04b")
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var ink := Color(0.03, 0.04, 0.05, 0.6)
		for i in range(1, divisions):
			var x := size.x * float(i) / float(divisions)
			draw_line(Vector2(x, 1), Vector2(x, size.y - 1), ink, 1.0)
		if threshold > 0.0:
			var x := size.x * clampf(threshold, 0.0, 1.0)
			draw_line(Vector2(x, -2), Vector2(x, size.y + 2), notch, 2.0, true)

## Hairlines and leader lines tying labels to the scene.
class Lines:
	extends Control
	var points: Array = []
	var color := Color(1, 1, 1, 0.4)
	var dot_end := false
	func _init(pts: Array = [], c: Color = Color(1, 1, 1, 0.4), dot: bool = false) -> void:
		points = pts
		color = c
		dot_end = dot
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if points.size() < 2: return
		draw_polyline(PackedVector2Array(points), color, 1.5, true)
		if dot_end: draw_circle(points[points.size() - 1], 3.5, color)

## Weapon side-elevation on graph paper, matching the held mesh silhouettes.
class Blueprint:
	extends Control
	var wid := ""
	var color := Color.WHITE
	func _init(i: String = "", c: Color = Color.WHITE) -> void:
		wid = i
		color = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var grid := Color(1, 1, 1, 0.07)
		var x := 0.0
		while x <= size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1.0)
			x += 15.0
		var y := 0.0
		while y <= size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1.0)
			y += 15.0
		var fill := Color(color, 0.30)
		var edge := Color(color.lightened(0.25), 0.95)
		var detail := Color(color, 0.85)
		var shapes: Array = []
		match wid:
			"kinetic":
				shapes = [
					[Vector2(36, 40), Vector2(96, 33), Vector2(168, 33), Vector2(214, 40), Vector2(252, 44), Vector2(252, 54), Vector2(168, 57), Vector2(118, 60), Vector2(104, 80), Vector2(86, 80), Vector2(82, 58), Vector2(40, 56)],
					[Vector2(118, 24), Vector2(156, 24), Vector2(156, 33), Vector2(118, 33)],
					[Vector2(36, 40), Vector2(26, 36), Vector2(26, 58), Vector2(40, 56)]]
			"scatter":
				shapes = [
					[Vector2(34, 34), Vector2(92, 28), Vector2(150, 30), Vector2(158, 38), Vector2(158, 58), Vector2(150, 66), Vector2(98, 68), Vector2(84, 82), Vector2(64, 82), Vector2(58, 62), Vector2(36, 56)],
					[Vector2(158, 32), Vector2(234, 30), Vector2(250, 26), Vector2(250, 44), Vector2(234, 42), Vector2(158, 42)],
					[Vector2(158, 54), Vector2(234, 54), Vector2(250, 52), Vector2(250, 70), Vector2(234, 66), Vector2(158, 64)]]
			"arc":
				shapes = [
					[Vector2(40, 34), Vector2(104, 30), Vector2(132, 36), Vector2(132, 58), Vector2(102, 62), Vector2(92, 80), Vector2(74, 80), Vector2(68, 60), Vector2(42, 56)],
					[Vector2(196, 32), Vector2(238, 38), Vector2(262, 48), Vector2(238, 58), Vector2(196, 64), Vector2(206, 48)]]
			"plasma":
				shapes = [
					[Vector2(32, 30), Vector2(104, 24), Vector2(146, 32), Vector2(146, 64), Vector2(104, 72), Vector2(84, 84), Vector2(64, 84), Vector2(58, 64), Vector2(34, 58)],
					[Vector2(146, 32), Vector2(238, 30), Vector2(268, 48), Vector2(238, 66), Vector2(146, 64), Vector2(158, 48)],
					[Vector2(146, 38), Vector2(228, 40), Vector2(228, 56), Vector2(146, 58)]]
			_:
				shapes = [[Vector2(36, 36), Vector2(180, 32), Vector2(250, 42), Vector2(250, 54), Vector2(110, 60), Vector2(96, 80), Vector2(78, 80), Vector2(72, 58), Vector2(38, 54)]]
		for shape in shapes:
			var pts := PackedVector2Array(shape)
			draw_colored_polygon(pts, fill)
			pts.append(pts[0])
			draw_polyline(pts, edge, 2.0, true)
		match wid:
			"kinetic":
				draw_line(Vector2(168, 45), Vector2(246, 49), detail, 2.0, true)
				draw_colored_polygon(PackedVector2Array([Vector2(96, 38), Vector2(104, 47), Vector2(96, 56), Vector2(88, 47)]), detail)
			"scatter":
				draw_line(Vector2(166, 37), Vector2(240, 36), detail, 2.0, true)
				draw_line(Vector2(166, 59), Vector2(240, 60), detail, 2.0, true)
				draw_arc(Vector2(92, 48), 11, 0, TAU, 24, detail, 2.0, true)
			"arc":
				draw_line(Vector2(132, 40), Vector2(204, 40), detail, 2.0, true)
				draw_line(Vector2(132, 56), Vector2(204, 56), detail, 2.0, true)
				for cx in [148.0, 172.0]:
					draw_line(Vector2(cx, 34), Vector2(cx, 62), detail, 2.4, true)
				draw_polyline(PackedVector2Array([Vector2(136, 48), Vector2(156, 38), Vector2(166, 52), Vector2(182, 40), Vector2(198, 48)]), detail, 2.0, true)
				draw_circle(Vector2(86, 46), 4, detail)
			"plasma":
				draw_line(Vector2(152, 48), Vector2(254, 48), detail, 2.0, true)
				draw_colored_polygon(PackedVector2Array([Vector2(92, 34), Vector2(106, 48), Vector2(92, 62), Vector2(78, 48)]), detail)
				for cx in [176.0, 210.0, 244.0]:
					draw_line(Vector2(cx, 38), Vector2(cx, 58), detail, 1.6, true)
		draw_line(Vector2(20, size.y - 6), Vector2(size.x - 20, size.y - 6), Color(color, 0.5), 1.0)
		draw_line(Vector2(20, size.y - 10), Vector2(20, size.y - 2), Color(color, 0.5), 1.0)
		draw_line(Vector2(size.x - 20, size.y - 10), Vector2(size.x - 20, size.y - 2), Color(color, 0.5), 1.0)

## Diamond pips for dash charges and upgrade marks.
class Pips:
	extends Control
	var filled := 0
	var total := 3
	var color := Color.WHITE
	var empty := Color(1, 1, 1, 0.25)
	var pip := 5.0
	var gap := 7.0
	func _init(f: int = 0, t: int = 3, c: Color = Color.WHITE) -> void:
		filled = f
		total = t
		color = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(total * (pip * 2.0 + gap), pip * 2.0 + 4.0)
	func _draw() -> void:
		for i in range(total):
			var cx := pip + 2.0 + float(i) * (pip * 2.0 + gap)
			var cy := size.y * 0.5
			var d := PackedVector2Array([Vector2(cx, cy - pip), Vector2(cx + pip, cy), Vector2(cx, cy + pip), Vector2(cx - pip, cy)])
			if i < filled: draw_colored_polygon(d, color)
			else:
				d.append(d[0])
				draw_polyline(d, empty, 1.5, true)

func set_bindings(bindings: Dictionary) -> void:
	for id in bindings: key_names[id]=OS.get_keycode_string(int(bindings[id]))

func movement_keys() -> String:
	return "%s%s%s%s" % [key_names.up,key_names.left,key_names.down,key_names.right]

func _ready() -> void:
	layer = 10
	# Staged captures and the QA driver need first-frame-final UI, no fades.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa"): motion_enabled = false
	# Embedded OFL type: Barlow for text, Barlow Condensed for display,
	# IBM Plex Mono for instruments (timer, score, costs).
	regular = load("res://assets/fonts/Barlow-Medium.ttf") as Font
	if regular == null:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial"])
		regular = fallback
	heavy = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf") as Font
	if heavy == null: heavy = regular
	mono = load("res://assets/fonts/IBMPlexMono-Medium.ttf") as Font
	if mono == null: mono = regular
	theme_ui = Theme.new()
	theme_ui.default_font = regular
	theme_ui.default_font_size = 18
	theme_ui.set_color("font_color", "Label", WHITE)
	theme_ui.set_color("font_color", "Button", WHITE)
	theme_ui.set_color("font_hover_color", "Button", WHITE)
	theme_ui.set_color("font_focus_color", "Button", WHITE)
	theme_ui.set_color("font_pressed_color", "Button", Palette.SIGNAL_SOFT)
	theme_ui.set_color("font_disabled_color", "Button", Color(Palette.MUTED, 0.9))
	theme_ui.set_font("font", "Button", heavy)
	theme_ui.set_font_size("font_size", "Button", 20)
	theme_ui.set_stylebox("normal", "Button", panel(Color(Palette.PANEL_RAISED,0.92), Color(WHITE, 0.24)))
	theme_ui.set_stylebox("hover", "Button", panel(Palette.PANEL_RAISED, Color(WHITE, 0.55)))
	theme_ui.set_stylebox("pressed", "Button", panel(Color("2a2f36"), SIGNAL))
	theme_ui.set_stylebox("disabled", "Button", panel(Color(Palette.PANEL_INSET,0.7), Color(Palette.PANEL_LINE,0.5)))
	theme_ui.set_stylebox("focus", "Button", panel(Color(0,0,0,0), SIGNAL, 2))
	# Sliders: thin track, signal fill, drawn ring grabber (no default Godot chrome).
	var track := StyleBoxLine.new()
	track.color = Palette.PANEL_LINE
	track.thickness = 4
	var filled_track := StyleBoxLine.new()
	filled_track.color = WHITE
	filled_track.thickness = 4
	theme_ui.set_stylebox("slider", "HSlider", track)
	theme_ui.set_stylebox("grabber_area", "HSlider", filled_track)
	theme_ui.set_stylebox("grabber_area_highlight", "HSlider", filled_track)
	theme_ui.set_icon("grabber", "HSlider", ring_texture(22, WHITE, Palette.PANEL))
	theme_ui.set_icon("grabber_highlight", "HSlider", ring_texture(22, SIGNAL, WHITE))
	theme_ui.set_icon("grabber_disabled", "HSlider", ring_texture(22, Palette.MUTED, Palette.PANEL))
	# Switches: pill toggles drawn to match the instrument panels.
	for state in ["normal", "hover", "pressed", "focus"]:
		theme_ui.set_stylebox(state, "CheckButton", theme_ui.get_stylebox(state, "Button"))
	# The pill icon alone encodes ON; a pressed switch must not also wear the focus outline.
	theme_ui.set_stylebox("pressed", "CheckButton", panel(Palette.PANEL_RAISED, Palette.PANEL_LINE))
	theme_ui.set_color("font_color", "CheckButton", WHITE)
	theme_ui.set_color("font_hover_color", "CheckButton", WHITE)
	theme_ui.set_color("font_focus_color", "CheckButton", WHITE)
	theme_ui.set_color("font_pressed_color", "CheckButton", WHITE)
	theme_ui.set_icon("checked", "CheckButton", pill_texture(true))
	theme_ui.set_icon("unchecked", "CheckButton", pill_texture(false))
	theme_ui.set_constant("h_separation", "CheckButton", 14)
	var sep := StyleBoxLine.new()
	sep.color = Palette.HAIRLINE
	sep.thickness = 1
	theme_ui.set_stylebox("separator", "HSeparator", sep)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_ui
	add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	build_hud()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)

func ring_texture(diameter: int, ring: Color, center: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var c := Vector2(diameter, diameter) * 0.5
	for y in range(diameter):
		for x in range(diameter):
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			if d <= float(diameter) * 0.5 - 1.0:
				img.set_pixel(x, y, ring if d > float(diameter) * 0.28 else center)
	return ImageTexture.create_from_image(img)

func pill_texture(on: bool) -> ImageTexture:
	var w := 46
	var h := 26
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var knob := Vector2(33, 13) if on else Vector2(13, 13)
	for y in range(h):
		for x in range(w):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var nearest := Vector2(clampf(p.x, 13.0, 33.0), 13.0)
			var body := p.distance_to(nearest)
			if body <= 12.0:
				var col: Color = WHITE if on else Palette.PANEL_RAISED
				if body > 10.5: col = WHITE if on else Palette.PANEL_LINE
				if p.distance_to(knob) <= 8.0: col = Palette.INK if on else Palette.MUTED
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func add_frame(parent: Control, accent: Color) -> Control:
	var f := Frame.new(accent)
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(f)
	return f

func family_color(family: String) -> Color:
	return {"HARVEST": Palette.FAM_HARVEST, "ECHO": Palette.FAM_ECHO, "WAKE": Palette.FAM_WAKE}.get(family, WHITE)

func panel(fill: Color, border: Color = Color(0,0,0,0), width: int = 1) -> StyleBoxFlat:
	if border.a == 0.0: border = Palette.PANEL_LINE
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(3)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 3)
	return s

func label_at(parent: Node, text: String, pos: Vector2, font_size: int = 18, color: Color = Color.WHITE) -> Label:
	if color == Color.WHITE: color = WHITE
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func text_line(text: String, size: int = 20, color: Color = Color.WHITE) -> Label:
	if color == Color.WHITE: color = WHITE
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func display_line(text: String, size: int = 40, color: Color = Color.WHITE) -> Label:
	var l := text_line(text, size, color)
	l.add_theme_font_override("font", heavy)
	return l

func mono_line(text: String, size: int = 14, color: Color = Color.WHITE) -> Label:
	var l := text_line(text, size, color)
	l.add_theme_font_override("font", mono)
	return l

func centered_label(text: String, y: float, size: int, color: Color, font: Font = null) -> Label:
	var l := label_at(modal, text, Vector2(220, y), size, color)
	l.size = Vector2(1000, size + 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font: l.add_theme_font_override("font", font)
	return l

func hairline(parent: Node, from: Vector2, to: Vector2, color: Color = Color(0,0,0,0)) -> Control:
	if color.a == 0.0: color = Palette.HAIRLINE
	var lines := Lines.new([from, to], color)
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(lines)
	return lines

func frame_over(card: Control, accent: Color) -> void:
	# Sibling overlay: children of a PanelContainer get inset by its margins.
	var frame := Frame.new(accent)
	frame.position = card.position
	frame.size = card.size
	modal.add_child(frame)
	var sync := func() -> void:
		frame.position = card.position
		frame.size = card.size
		frame.queue_redraw()
	card.resized.connect(sync)
	sync.call_deferred()

func sheet(pos: Vector2, width: float, accent: Color = Color(0,0,0,0)) -> VBoxContainer:
	if accent.a == 0.0: accent = SIGNAL
	var card := PanelContainer.new()
	var style := panel(Color(Palette.PANEL, 0.97), Palette.PANEL_LINE)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	card.add_theme_stylebox_override("panel", style)
	card.position = pos
	card.custom_minimum_size.x = width
	card.size.x = width
	modal.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	frame_over(card, accent)
	return box

func stage(rect: Rect2) -> void:
	var back := Panel.new()
	back.position = rect.position
	back.size = rect.size
	back.add_theme_stylebox_override("panel", panel(Color(Palette.PANEL_INSET, 0.55), Palette.HAIRLINE))
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(back)
	frame_over(back, Color(WHITE, 0.35))

func perk_line(id: String, rank: int) -> String:
	match id:
		"hull": return "NOW +%d MAX HULL  →  NEXT +%d" % [10 * rank, 10 * (rank + 1)]
		"dash": return "NOW ×%.2f RECHARGE TIME  →  NEXT ×%.2f" % [pow(0.92, rank), pow(0.92, rank + 1)]
		"harvest": return "NOW +%d ENERGY / SHOT  →  NEXT +%d" % [rank, rank + 1]
		"battery": return "NOW +%d START ENERGY  →  NEXT +%d" % [10 * rank, 10 * (rank + 1)]
		"armory": return "NOW +%.1f%% WEAPON DAMAGE  →  NEXT +%.1f%%" % [2.5 * rank, 2.5 * (rank + 1)]
		"combo": return "NOW +%.1fs COMBO WINDOW  →  NEXT +%.1fs" % [0.4 * rank, 0.4 * (rank + 1)]
	return ""

func animate_modal() -> void:
	if not motion_enabled or effects_low:
		modal.modulate.a = 1.0
		return
	modal.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(modal, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func card_hit_area(card: Control, accent: Color, callback: Callable) -> void:
	# No corner frame here: the stage is framed, and the white hover outline
	# below stays the only card-level selection cue.
	var hit := Button.new()
	hit.text = ""
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.position = card.position
	hit.size = card.size
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", panel(Color(0, 0, 0, 0), WHITE, 2))
	hit.add_theme_stylebox_override("pressed", panel(Color(WHITE, 0.08), WHITE, 2))
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(callback)
	modal.add_child(hit)

func nowrap(l: Label, min_width: float = 120.0) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size.x = min_width
	return l

func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 54
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		b.add_theme_stylebox_override("normal", panel(WHITE, WHITE))
		b.add_theme_stylebox_override("hover", panel(WHITE, SIGNAL, 2))
		b.add_theme_stylebox_override("focus", panel(WHITE, WHITE, 2))
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", INK)
		b.add_theme_color_override("font_focus_color", INK)
	b.pressed.connect(callback)
	b.mouse_entered.connect(func() -> void:
		if not motion_enabled or effects_low or b.disabled: return
		b.pivot_offset = b.size * 0.5
		var tw := create_tween()
		tw.tween_property(b, "scale", Vector2.ONE * 1.018, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	b.mouse_exited.connect(func() -> void:
		if not motion_enabled or effects_low: return
		b.pivot_offset = b.size * 0.5
		var tw := create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	return b

func bar_at(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("23282f")
	background.border_color = Palette.PANEL_LINE
	background.set_border_width_all(1)
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	var ticks := Ticks.new()
	ticks.name = "Ticks"
	ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(ticks)
	parent.add_child(bar)
	# Assign geometry after disabling percentage text; its default font minimum
	# would otherwise clamp the height and retain it after styles are updated.
	bar.size = size
	return bar

func build_hud() -> void:
	var top_shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0,Color(0.02,0.02,0.02,0.82))
	gradient.set_color(1,Color(0.02,0.02,0.02,0))
	var texture := GradientTexture2D.new()
	texture.gradient=gradient
	texture.fill_from=Vector2.ZERO
	texture.fill_to=Vector2(0,1)
	top_shade.texture=texture
	top_shade.size=Vector2(1440,195)
	top_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_shade)
	var screen_frame := Frame.new(Color(WHITE, 0.65))
	screen_frame.set("bracket", 34.0)
	screen_frame.position = Vector2(12, 12)
	screen_frame.size = Vector2(1416, 876)
	hud.add_child(screen_frame)
	health_text = label_at(hud, "HULL · 100", Vector2(35, 24), 19)
	health_text.add_theme_font_override("font", mono)
	health_bar = bar_at(hud, Vector2(35, 58), Vector2(260, 10), WHITE)
	(health_bar.get_node("Ticks") as Control).set("divisions", 5)
	status_text = label_at(hud, "SKYFORGE   /   SECTOR 07", Vector2(35, 82), 13, Color(WHITE, 0.65))
	time_text = label_at(hud, "00:00", Vector2(640, 14), 34)
	time_text.size = Vector2(160, 44)
	time_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_text.add_theme_font_override("font", mono)
	var time_caption := label_at(hud, "RUN TIME", Vector2(640, 60), 11, Color(WHITE, 0.65))
	time_caption.size = Vector2(160, 16)
	time_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text = label_at(hud, "000000 · SCORE", Vector2(1180, 32), 18)
	score_text.size = Vector2(225, 28)
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_text.add_theme_font_override("font", mono)
	combo_text = label_at(hud, "", Vector2(1180, 92), 20, WHITE)
	combo_text.size = Vector2(225, 28)
	combo_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_text.add_theme_font_override("font", mono)
	combo_bar = bar_at(hud, Vector2(1230, 124), Vector2(175, 5), SIGNAL)
	combo_bar.visible = false
	var esc_text := label_at(hud, "ESC  PAUSE", Vector2(1180, 66), 13, MUTED)
	esc_text.size = Vector2(225, 20)
	esc_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var reactor := Panel.new()
	reactor.position = Vector2(500, 785)
	reactor.size = Vector2(440, 91)
	reactor.add_theme_stylebox_override("panel", panel(Color(Palette.PANEL,0.92)))
	reactor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(reactor)
	add_frame(reactor, SIGNAL)
	energy_text = label_at(reactor, "E · PULSE 0", Vector2(22, 12), 16, CYAN)
	energy_text.add_theme_font_override("font", mono)
	energy_bar = bar_at(reactor, Vector2(22, 44), Vector2(250, 9), CYAN)
	(energy_bar.get_node("Ticks") as Control).set("threshold", pulse_ready_ratio)
	dash_text = label_at(reactor, "SPACE  DASH", Vector2(302, 12), 16, WHITE)
	dash_pips = Pips.new(2, 2, WHITE)
	dash_pips.position = Vector2(302, 40)
	dash_pips.size = Vector2(90, 16)
	reactor.add_child(dash_pips)
	harvest_guide=label_at(reactor, "DASH THROUGH ORANGE SHOTS TO CHARGE", Vector2(22, 62), 12, MUTED)
	var armory := Panel.new()
	armory.position = Vector2(35, 785)
	armory.size = Vector2(420, 91)
	armory.add_theme_stylebox_override("panel", panel(Color(Palette.PANEL,0.92)))
	armory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(armory)
	add_frame(armory, Palette.ICE)
	weapon_text=label_at(armory,"VECTOR CARBINE · I",Vector2(18,10),18,WHITE)
	weapon_text.add_theme_font_override("font", heavy)
	weapon_detail=label_at(armory,"RAPID FIRE",Vector2(18,38),12,MUTED)
	build_text = label_at(armory, "", Vector2(18, 58), 13, Color(WHITE, 0.78))
	build_text.size = Vector2(384, 30)
	build_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint = label_at(hud, "", Vector2(360, 712), 20)
	hint.size = Vector2(720, 58)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_plate = Panel.new()
	banner_plate.position = Vector2(440, 146)
	banner_plate.size = Vector2(560, 72)
	banner_plate.add_theme_stylebox_override("panel", panel(Color(Palette.PANEL_INSET, 0.42), Palette.HAIRLINE))
	banner_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_plate.visible = false
	hud.add_child(banner_plate)
	add_frame(banner_plate, SIGNAL)
	banner = label_at(hud, "", Vector2(450, 152), 24, WHITE)
	banner.size = Vector2(540, 72)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", heavy)
	boss_plate = Panel.new()
	boss_plate.position = Vector2(408, 80)
	boss_plate.size = Vector2(624, 58)
	boss_plate.add_theme_stylebox_override("panel", panel(Color(Palette.PANEL_INSET, 0.88), CORAL.darkened(0.35)))
	boss_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_plate.visible = false
	hud.add_child(boss_plate)
	add_frame(boss_plate, CORAL)
	boss_name = label_at(hud, "THE REACTOR GUARDIAN", Vector2(430, 88), 18, CORAL)
	boss_name.size = Vector2(580, 20)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_override("font", heavy)
	boss_bar = bar_at(hud, Vector2(430, 120), Vector2(580, 8), CORAL)
	(boss_bar.get_node("Ticks") as Control).set("threshold", 0.5)
	(boss_bar.get_node("Ticks") as Control).set("notch", CORAL)
	boss_bar.visible = false
	boss_name.visible = false
	objective_text = label_at(hud,"",Vector2(280,142),16,WHITE)
	objective_text.size = Vector2(880,52)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position.y = 152
	var flight := Panel.new()
	flight.position = Vector2(983,785)
	flight.size = Vector2(305,91)
	flight.add_theme_stylebox_override("panel",panel(Color(Palette.PANEL,0.92)))
	flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flight)
	add_frame(flight, Palette.ICE)
	flight_text = label_at(flight,"F  JUMP / HOLD TO GLIDE",Vector2(18,12),14,WHITE)
	flight_bar = bar_at(flight,Vector2(18,44),Vector2(268,7),Palette.ICE)
	altitude_text = label_at(flight,"WINGS READY",Vector2(18,62),11,MUTED)

func clear_modal() -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.visible = true
	offers.clear()

func shade(alpha: float = 0.92) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02,0.02,0.02,alpha)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(bg)

func column(pos: Vector2, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = pos
	box.size.x = width
	box.add_theme_constant_override("separation", 16)
	modal.add_child(box)
	return box

func show_title(best: int, practiced: bool, cores: int = 0) -> void:
	clear_modal()
	hud.visible = false
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.02,0.05,0.08,0.98))
	gradient.set_color(1, Color(0.02,0.05,0.08,0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2.ZERO
	tex.fill_to = Vector2(1.05,0)
	var veil := TextureRect.new()
	veil.texture = tex
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(veil)
	var sigil := Glyph.new("sigil", SIGNAL, 30)
	sigil.position = Vector2(63, 52)
	modal.add_child(sigil)
	label_at(modal, "O V E R D R I V E  ·  THE ENDLESS SKY HEIST", Vector2(104, 60), 13, SIGNAL)
	var edition := label_at(modal, "MAC · UNIVERSAL", Vector2(1150, 60), 12, MUTED)
	edition.size = Vector2(225, 20)
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	edition.add_theme_font_override("font", mono)
	var title := label_at(modal, "PULSE\nBREAK", Vector2(58, 115), 104)
	title.add_theme_font_override("font", heavy)
	title.add_theme_constant_override("line_spacing", -25)
	label_at(modal, "STEAL THE STORM.", Vector2(65, 386), 25, SIGNAL)
	var desc := label_at(modal, "Leap the gates. Unfold your wings.\nBuild your arsenal. Break the next horizon.", Vector2(65, 418), 19, MUTED)
	desc.size.x = 490
	var box := column(Vector2(65, 478), 385)
	box.add_theme_constant_override("separation",9)
	var play := button("BEGIN SKYBOUND    →", func(): action.emit("campaign", false), true)
	box.add_child(play)
	box.add_child(button("PRACTICE THE HEIST", func(): action.emit("practice", true)))
	box.add_child(button("CLASSIC · SIX-MINUTE SURVIVAL", func(): action.emit("start", false)))
	box.add_child(button("HANGAR · %d SALVAGE CORES" % cores, func(): action.emit("hangar", null)))
	var controls:=HBoxContainer.new()
	controls.add_theme_constant_override("separation",9)
	for item in [["SETTINGS","settings"],["QUIT GAME","quit"]]:
		var control:=button(item[0],func(): action.emit(item[1],null))
		control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		controls.add_child(control)
	box.add_child(controls)
	play.grab_focus()
	add_frame(play, SIGNAL)
	var captions := ["ENDLESS GENERATED SECTORS", "LEARN TO HARVEST SHOTS", "ONE ARENA, ONE GUARDIAN", "SPEND CORES ON PERMANENT PERKS"]
	for i in range(captions.size()):
		var tick := Lines.new([Vector2(456, 505 + i * 63), Vector2(470, 505 + i * 63)], Color(WHITE, 0.5), true)
		tick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		modal.add_child(tick)
		var cap := label_at(modal, captions[i], Vector2(478, 496 + i * 63), 13, Color(WHITE, 0.82))
		cap.add_theme_color_override("font_shadow_color", Color(Palette.INK, 0.9))
		cap.add_theme_constant_override("shadow_offset_x", 1)
		cap.add_theme_constant_override("shadow_offset_y", 1)
	hairline(modal, Vector2(65, 798), Vector2(1375, 798))
	label_at(modal, "PERSONAL BEST · %06d" % best, Vector2(65, 812), 14, MUTED)
	var best_mono := label_at(modal, "SALVAGE CORES · %d" % cores, Vector2(330, 812), 14, AMBER)
	best_mono.add_theme_font_override("font", mono)
	label_at(modal, "%s  MOVE    %s  DASH    %s  PULSE    %s  JUMP · GLIDE" % [movement_keys(),key_names.dash.to_upper(),key_names.pulse.to_upper(),key_names.jump.to_upper()], Vector2(65, 856), 12, MUTED)
	var rail := label_at(modal, "03 SECTORS. THEN THE UNKNOWN.\nNEW ROUTES · EVOLVING WEAPONS", Vector2(975, 812), 14, MUTED)
	rail.size = Vector2(400, 48)
	rail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_at(modal,"COURIER MK.III\nVECTOR WING SYSTEM",Vector2(612,84),14,MUTED)
	var leader := Lines.new([Vector2(612, 128), Vector2(880, 128), Vector2(972, 282)], Color(WHITE, 0.45), true)
	leader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(leader)
	if not practiced:
		label_at(modal, "FIRST RUN? PRACTICE TEACHES HARVESTING. SKYBOUND TEACHES FLIGHT.", Vector2(65, 834), 10, SIGNAL)
	animate_modal()

func show_game() -> void:
	modal.visible = false
	hud.visible = true
	banner_time = 0.0
	banner.modulate.a = 0.0
	banner_plate.visible = false
	if motion_enabled and not effects_low:
		hud.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(hud, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		hud.modulate.a = 1.0

func show_pause() -> void:
	clear_modal(); shade(0.86)
	var box := sheet(Vector2(472, 212), 496)
	box.add_child(mono_line("PAUSED  /  RUN HELD", 12, SIGNAL))
	box.add_child(display_line("TAKE A BREATH", 42, WHITE))
	box.add_child(text_line("The foundry can wait.", 19, MUTED))
	box.add_child(HSeparator.new())
	var resume_button := button("RESUME    →", func(): action.emit("resume", null), true)
	box.add_child(resume_button)
	box.add_child(button("SETTINGS", func(): action.emit("settings", null)))
	box.add_child(button("RESTART RUN", func(): action.emit("restart", null)))
	box.add_child(button("RETURN TO TITLE", func(): action.emit("title", null)))
	box.add_child(button("QUIT GAME", func(): action.emit("quit", null)))
	resume_button.grab_focus()
	animate_modal()

func show_practice_complete() -> void:
	clear_modal(); shade(0.86)
	hud.visible = false
	var box := sheet(Vector2(65, 170), 590)
	var p_lockup := HBoxContainer.new()
	p_lockup.add_theme_constant_override("separation", 12)
	var p_sigil := Glyph.new("sigil", SIGNAL, 30)
	p_sigil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p_lockup.add_child(p_sigil)
	var p_lock_text := mono_line("PRACTICE COMPLETE", 12, SIGNAL)
	p_lock_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p_lockup.add_child(nowrap(p_lock_text, 240))
	box.add_child(p_lockup)
	box.add_child(display_line("READY FOR THE HEIST", 40, WHITE))
	box.add_child(text_line("You have the core move: harvest, reposition, pulse.\nTake flight, build an arsenal, and dive into endless sectors.", 19, MUTED))
	box.add_child(HSeparator.new())
	for lesson in [["dash", "DASH THROUGH ORANGE SHOTS", "Steal their energy mid-flight."], ["radius", "SPEND IT AS A PULSE", "Bigger charge, bigger blast."], ["wake", "JUMP, THEN HOLD TO GLIDE", "Reach the airborne relays."]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var lg := Glyph.new(lesson[0], SIGNAL, 38)
		lg.set("bold", true)
		lg.set("cut", Palette.PANEL)
		row.add_child(lg)
		var lt := VBoxContainer.new()
		lt.add_theme_constant_override("separation", 2)
		lt.add_child(nowrap(display_line(lesson[1], 17), 400))
		lt.add_child(nowrap(text_line(lesson[2], 14, MUTED), 400))
		row.add_child(lt)
		box.add_child(row)
	box.add_child(HSeparator.new())
	var start := button("BEGIN SKYBOUND    →",func():action.emit("campaign",false),true)
	box.add_child(start)
	box.add_child(button("PRACTICE AGAIN",func():action.emit("practice",true)))
	box.add_child(button("RETURN TO TITLE",func():action.emit("title",null)))
	start.grab_focus()
	animate_modal()

func show_hangar(settings: Dictionary, perk_data: Dictionary) -> void:
	clear_modal(); shade(0.88)
	hud.visible = false
	var cores: int = int(settings.get("cores",0))
	var perks: Dictionary = settings.get("perks",{})
	var hangar_title := label_at(modal, "THE HANGAR", Vector2(65, 58), 46, WHITE)
	hangar_title.add_theme_font_override("font", heavy)
	label_at(modal, "Salvage cores are earned on every run and never lost. Permanent perks apply to every future run.", Vector2(65, 126), 16, MUTED)
	hairline(modal, Vector2(65, 118), Vector2(430, 118), Color(SIGNAL, 0.7))
	var hold_glyph := Glyph.new("core", AMBER, 26)
	hold_glyph.position = Vector2(1018, 68)
	modal.add_child(hold_glyph)
	var hold := label_at(modal, "YOU HOLD %d CORES" % cores, Vector2(1052, 70), 22, AMBER)
	hold.add_theme_font_override("font", mono)
	var ids: Array = perk_data.keys()
	for i in range(ids.size()):
		var id: String = ids[i]
		var data: Dictionary = perk_data[id]
		var rank: int = int(perks.get(id,0))
		var card := PanelContainer.new()
		card.position = Vector2(65 + (i%3)*440, 168 + (i/3)*258)
		card.size = Vector2(424, 240)
		card.add_theme_stylebox_override("panel", panel(Palette.PANEL, Palette.PANEL_LINE))
		modal.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)
		var head_row := HBoxContainer.new()
		head_row.add_theme_constant_override("separation", 14)
		var perk_glyph := Glyph.new(id, SIGNAL if rank < 3 else AMBER, 44)
		perk_glyph.set("bold", true)
		perk_glyph.set("cut", Palette.PANEL)
		head_row.add_child(perk_glyph)
		var head_text := VBoxContainer.new()
		head_text.add_theme_constant_override("separation", 4)
		var name_line := display_line(data.name, 20)
		name_line.custom_minimum_size.y = 52
		name_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head_text.add_child(name_line)
		var pip_row := HBoxContainer.new()
		pip_row.add_theme_constant_override("separation", 10)
		pip_row.add_child(Pips.new(rank, 3, SIGNAL))
		pip_row.add_child(nowrap(mono_line("RANK %d / 3" % rank, 11, MUTED), 90))
		head_text.add_child(pip_row)
		head_row.add_child(head_text)
		box.add_child(head_row)
		var desc := text_line(data.description, 16, MUTED)
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(desc)
		if rank < 3:
			box.add_child(nowrap(mono_line(perk_line(id, rank), 12, WHITE), 340))
		if rank >= 3:
			box.add_child(nowrap(mono_line("ACTIVE  ·  " + perk_line(id, 3).split("→")[0].strip_edges().trim_prefix("NOW "), 12, WHITE), 340))
			var mastered_band := button("◆ MASTERED — ALWAYS ON", func(): pass)
			mastered_band.disabled = true
			mastered_band.focus_mode = Control.FOCUS_NONE
			mastered_band.add_theme_color_override("font_disabled_color", AMBER)
			box.add_child(mastered_band)
		else:
			var cost: int = int(data.cost[rank])
			var price_row := HBoxContainer.new()
			price_row.add_theme_constant_override("separation", 8)
			price_row.add_child(Glyph.new("core", AMBER, 16))
			price_row.add_child(nowrap(mono_line("%d SALVAGE CORES" % cost, 15, AMBER if cores >= cost else WHITE), 300))
			box.add_child(price_row)
			var buy := button("INSTALL RANK %d" % (rank+1) if cores >= cost else "NEED %d MORE CORES" % (cost - cores), func(): action.emit("buy_perk", id))
			buy.disabled = cores < cost
			box.add_child(buy)
		frame_over(card, AMBER if rank >= 3 else SIGNAL)
	var prestige: int = int(settings.get("prestige",0))
	var prestige_cost: int = int(40 * pow(1.5, prestige))
	var prestige_button := button("OVERCHARGE CELL %d · +%d%% SCORE FOREVER · %d CORES" % [prestige+1, prestige+1, prestige_cost], func(): action.emit("buy_prestige", null))
	prestige_button.position = Vector2(505, 694); prestige_button.size = Vector2(864, 52)
	prestige_button.disabled = cores < prestige_cost
	modal.add_child(prestige_button)
	var back := button("BACK TO TITLE", func(): action.emit("title", null))
	back.position = Vector2(65, 694); back.size = Vector2(424, 52)
	hairline(modal, Vector2(65, 674), Vector2(1375, 674))
	var mastered := 0
	for pid in perk_data:
		if int(perks.get(pid, 0)) >= 3: mastered += 1
	var summary := label_at(modal, "PERKS MASTERED %d / %d  ·  OVERCHARGE +%d%% SCORE" % [mastered, perk_data.size(), prestige], Vector2(850, 768), 13, MUTED)
	summary.size = Vector2(525, 22)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.add_theme_font_override("font", mono)
	centered_label("ESC  BACK", 838, 11, MUTED, mono)
	modal.add_child(back)
	var first_buy: Button = null
	for child in modal.get_children():
		if child is PanelContainer:
			for sub in child.get_children():
				for node in sub.get_children():
					if node is Button and not node.disabled and first_buy == null: first_buy = node
	(first_buy if first_buy else back).grab_focus()
	animate_modal()


func show_settings(settings: Dictionary, bindings: Dictionary) -> void:
	clear_modal(); shade(0.86)
	var box := sheet(Vector2(342, 8), 756)
	box.add_theme_constant_override("separation", 5)
	box.add_child(display_line("SETTINGS", 38, WHITE))
	box.add_child(text_line(settings_note if not settings_note.is_empty() else "Settings save automatically.", 16, SIGNAL if not settings_note.is_empty() else MUTED))
	for item in [["volume", "VOLUME"], ["shake", "SCREEN SHAKE"]]:
		var row := HBoxContainer.new()
		var label := text_line(item[1], 16)
		label.custom_minimum_size.x = 210
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0; slider.max_value = 1; slider.step = 0.05
		slider.value = settings.get(item[0], 0.6)
		slider.custom_minimum_size = Vector2(360,34)
		slider.value_changed.connect(func(value): action.emit("setting", {"key":item[0],"value":value}))
		row.add_child(slider)
		var readout := text_line(str(int(round(slider.value*100.0))), 14, MUTED)
		readout.add_theme_font_override("font", mono)
		readout.custom_minimum_size.x = 40
		slider.value_changed.connect(func(value): readout.text = str(int(round(value*100.0))))
		row.add_child(readout)
		box.add_child(row)
	var assist := CheckButton.new()
	assist.text = "ASSIST · slower enemy attacks"
	assist.text += "  ·  ON" if settings.get("assist", false) else "  ·  OFF"
	assist.button_pressed = settings.get("assist", false)
	assist.custom_minimum_size.y = 40
	assist.add_theme_font_size_override("font_size", 14)
	assist.toggled.connect(func(value): action.emit("setting", {"key":"assist","value":value}))
	box.add_child(assist)
	if settings.get("won",false):
		var overdrive:=CheckButton.new()
		overdrive.text="OVERDRIVE · tougher enemies + waves, next run" + ("  ·  ON" if settings.get("overdrive",false) else "  ·  OFF")
		overdrive.button_pressed=settings.get("overdrive",false)
		overdrive.custom_minimum_size.y = 40
		overdrive.add_theme_font_size_override("font_size", 14)
		overdrive.toggled.connect(func(value):action.emit("overdrive",value))
		box.add_child(overdrive)
	var upd := CheckButton.new()
	upd.text = "UPDATE CHECK · look for new versions on launch" + ("  ·  ON" if settings.get("update_check", true) else "  ·  OFF")
	upd.button_pressed = settings.get("update_check", true)
	upd.custom_minimum_size.y = 40
	upd.add_theme_font_size_override("font_size", 14)
	upd.toggled.connect(func(value): action.emit("setting", {"key":"update_check","value":value}))
	box.add_child(upd)
	var low := CheckButton.new()
	low.text = "LOW EFFECTS · reduced particles and shadows" + ("  ·  ON" if settings.get("low_effects", false) else "  ·  OFF")
	low.button_pressed = settings.get("low_effects", false)
	low.custom_minimum_size.y = 40
	low.add_theme_font_size_override("font_size", 14)
	low.toggled.connect(func(value): action.emit("setting", {"key":"low_effects","value":value}))
	box.add_child(low)
	box.add_child(text_line("UI THEME · applies immediately, saved on this Mac", 15, MUTED))
	var theme_row := HBoxContainer.new()
	theme_row.add_theme_constant_override("separation", 8)
	var active_theme: String = str(settings.get("theme", "aerospace"))
	for theme_id in Palette.theme_ids():
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 8)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mark := Glyph.new("core", Palette.THEMES[theme_id]["SIGNAL"], 18)
		mark.set("bold", true)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(mark)
		var tb := button(str(Palette.THEME_NAMES[theme_id]), func(): action.emit("theme", theme_id), theme_id == active_theme)
		tb.custom_minimum_size = Vector2(0, 40)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(tb)
		theme_row.add_child(cell)
	box.add_child(theme_row)
	box.add_child(text_line("KEYBOARD · select an action, then press a key", 15, MUTED))
	var keys := GridContainer.new()
	keys.columns = 2
	keys.add_theme_constant_override("h_separation", 12)
	keys.add_theme_constant_override("v_separation", 6)
	for id in ["left","right","up","down","dash","pulse","jump","weapon"]:
		var key_name := OS.get_keycode_string(int(bindings[id]))
		var key_button := button(id.to_upper() + "   [" + key_name + "]", func(): action.emit("rebind", id))
		key_button.custom_minimum_size = Vector2(336,34)
		key_button.add_theme_font_override("font", mono)
		key_button.add_theme_font_size_override("font_size", 13)
		keys.add_child(key_button)
	box.add_child(keys)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	var reset_controls := button("RESET CONTROLS", func(): action.emit("reset_controls", null))
	reset_controls.custom_minimum_size.y = 42
	reset_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(reset_controls)
	var check_now := button("CHECK FOR UPDATES", func(): action.emit("check_update", null))
	check_now.custom_minimum_size.y = 42
	check_now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(check_now)
	box.add_child(bottom_row)
	var back := button("BACK", func(): action.emit("back", null))
	back.custom_minimum_size.y = 42
	box.add_child(back)
	back.grab_focus()
	animate_modal()

func show_update(info: Dictionary, current_version: String) -> void:
	clear_modal(); shade(0.88)
	var box := sheet(Vector2(425, 236), 590)
	box.add_child(Glyph.new("sigil", SIGNAL, 40))
	box.add_child(mono_line("UPDATE AVAILABLE  /  %s → %s" % [current_version, str(info.get("version",""))], 12, SIGNAL))
	box.add_child(display_line("A NEW PULSEBREAK IS READY", 34, WHITE))
	box.add_child(text_line("Download it now and the game replaces itself and relaunches. Your saves and settings stay put.", 17, MUTED))
	update_bar = ProgressBar.new()
	update_bar.show_percentage = false
	update_bar.custom_minimum_size = Vector2(0, 9)
	update_bar.max_value = 100
	update_bar.value = 0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("23282f")
	bg.set_corner_radius_all(2)
	var fl := StyleBoxFlat.new()
	fl.bg_color = SIGNAL
	fl.set_corner_radius_all(2)
	update_bar.add_theme_stylebox_override("background", bg)
	update_bar.add_theme_stylebox_override("fill", fl)
	update_bar.visible = false
	box.add_child(update_bar)
	update_status = mono_line("", 12, MUTED)
	box.add_child(update_status)
	var install := button("DOWNLOAD & INSTALL    →", func(): action.emit("update_install", null), true)
	box.add_child(install)
	box.add_child(button("LATER", func(): action.emit("update_later", null)))
	install.grab_focus()
	animate_modal()

func update_download(fraction: float, message: String = "") -> void:
	if not is_instance_valid(update_bar):
		return
	if fraction < 0.0:
		update_status.text = message
		return
	update_bar.visible = true
	update_bar.value = fraction * 100.0
	update_status.text = "DOWNLOADING… %d%%" % int(round(fraction * 100.0)) if fraction < 1.0 else "VERIFIED — RESTARTING TO INSTALL…"

func show_rebind(id: String) -> void:
	clear_modal(); shade(0.88)
	var box := sheet(Vector2(470, 266), 500)
	box.add_child(mono_line("KEYBOARD  /  REBIND", 12, SIGNAL))
	box.add_child(display_line("BIND " + id.to_upper(), 40, WHITE))
	box.add_child(display_line("[  ?  ]", 34, SIGNAL))
	box.add_child(text_line("Press a keyboard key.\nEsc cancels. Reserved menu keys cannot be assigned.", 19, MUTED))
	animate_modal()

func show_upgrades(ids: Array, levels: Dictionary = {}) -> void:
	clear_modal(); shade(0.88)
	offers = ids.duplicate()
	centered_label("CHECKPOINT · COMBAT PAUSED · +20 HULL ON INSTALL", 138, 12, SIGNAL, mono)
	centered_label("REACTOR EVOLUTION", 162, 42, WHITE, heavy)
	hairline(modal, Vector2(560, 224), Vector2(880, 224), Color(SIGNAL, 0.7))
	stage(Rect2(146, 222, 1148, 486))
	for i in range(ids.size()):
		var id: String = ids[i]
		var data: Dictionary = Rules.UPGRADE_DATA[id]
		var fam: Color = family_color(data.family)
		var card := PanelContainer.new()
		card.position = Vector2(176 + i * 368, 240)
		card.size = Vector2(352, 452)
		card.add_theme_stylebox_override("panel", panel(Palette.PANEL, Palette.PANEL_LINE))
		modal.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 9)
		card.add_child(box)
		var current: int = int(levels.get(id,0))
		var mark_names := ["MK I","MK II","MK III"]
		box.add_child(mono_line("0%d · %s · %s" % [i+1,data.family,mark_names[mini(current,2)]], 12, MUTED))
		var glyph := Glyph.new(id, fam, 88)
		glyph.set("bold", true)
		glyph.set("cut", Palette.PANEL)
		box.add_child(glyph)
		box.add_child(display_line(data.name, 27))
		var pip_row := HBoxContainer.new()
		pip_row.add_theme_constant_override("separation", 10)
		pip_row.add_child(Pips.new(current, 3, fam))
		pip_row.add_child(nowrap(mono_line("MARK %d OF 3" % current, 11, MUTED), 110))
		box.add_child(pip_row)
		box.add_child(HSeparator.new())
		var mark_text: String = data.marks[mini(current,2)]
		var split_at := mark_text.find(". ")
		var lead := text_line(mark_text.substr(0, split_at + 1) if split_at > 0 else mark_text, 18, WHITE)
		box.add_child(lead)
		var rest := text_line(mark_text.substr(split_at + 2) if split_at > 0 else data.description, 14, MUTED)
		box.add_child(rest)
		if current < 2:
			var next_text: String = data.marks[current + 1]
			var next_end := next_text.find(". ")
			box.add_child(mono_line("NEXT %s → %s" % [mark_names[current + 1], next_text.substr(0, next_end + 1) if next_end > 0 else next_text], 11, MUTED))
		var fam_owned := 0
		for fam_id in Rules.FAMILIES[data.family]:
			if int(levels.get(fam_id,0))>0 or fam_id==id: fam_owned += 1
		var resonance_text: String = {"HARVEST":"+1 DASH CHARGE","ECHO":"PULSE RADIUS +8%","WAKE":"COMBO WINDOW +25%"}[data.family]
		box.add_child(mono_line("%s %d/3  ·  RESONANCE: %s" % [data.family, fam_owned, resonance_text], 12, fam if fam_owned>=3 else MUTED))
		var foot_spacer := Control.new()
		foot_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(foot_spacer)
		var choose := button("[%d]  %s" % [i+1, "INSTALL" if current==0 else "RAISE TO " + mark_names[mini(current,2)]], func(): action.emit("upgrade", id))
		box.add_child(choose)
		if i == 0: choose.grab_focus()
		var ghost := Glyph.new(id, Color(fam, 0.06), 168)
		ghost.set("ringed", true)
		ghost.set("width_scale", 0.55)
		ghost.position = card.position + Vector2(184, 104)
		modal.add_child(ghost)
		card_hit_area(card, fam, func(): action.emit("upgrade", id))
	centered_label("EACH SYSTEM HAS THREE MARKS · OWN ALL THREE OF A FAMILY FOR ITS RESONANCE", 738, 12, MUTED, mono)
	animate_modal()

func show_weapon_upgrades(ids: Array, data: Array) -> void:
	clear_modal(); shade(0.88)
	centered_label("CHECKPOINT ARMORY  /  NEW HARDWARE", 96, 12, SIGNAL, mono)
	centered_label("THE ARMORY", 120, 42, WHITE, heavy)
	hairline(modal, Vector2(560, 182), Vector2(880, 182), Color(SIGNAL, 0.7))
	centered_label("New hardware. New ways to break the storm.", 196, 18, MUTED)
	stage(Rect2(146, 222, 1148, 552))
	for i in range(ids.size()):
		var id: String=ids[i]
		var item: Dictionary=data[i]
		var card:=PanelContainer.new()
		card.position=Vector2(176+i*368,240)
		card.size=Vector2(352,516)
		card.add_theme_stylebox_override("panel",panel(Palette.PANEL,Palette.PANEL_LINE))
		modal.add_child(card)
		var box:=VBoxContainer.new()
		box.add_theme_constant_override("separation",10)
		card.add_child(box)
		box.add_child(mono_line("0%d  /  %s" % [i+1,item.family],12,item.color))
		var preview:=Control.new()
		preview.custom_minimum_size=Vector2(300,88)
		preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.add_child(preview)
		weapon_blueprint(preview,id,item.color)
		box.add_child(display_line(item.name,26,WHITE))
		var rank_row:=HBoxContainer.new()
		rank_row.add_theme_constant_override("separation",10)
		rank_row.add_child(Pips.new(int(item.get("rank",0)),5,item.color))
		rank_row.add_child(nowrap(mono_line("NOT OWNED" if int(item.get("rank",0))==0 else "RANK %s OF V" % ["","I","II","III","IV","V"][clampi(int(item.get("rank",0)),0,5)],11,MUTED), 110))
		box.add_child(rank_row)
		box.add_child(text_line(item.action,16,SIGNAL))
		box.add_child(mono_line(item.benefit,12,WHITE))
		meter_row(box,"DMG",float(item.get("damage",10.0))/60.0,WHITE)
		meter_row(box,"RATE",(1.1-float(item.get("interval",0.6)))/0.95,WHITE)
		meter_row(box,"RANGE",float(item.get("range",10.0))/14.0,WHITE)
		var desc:=text_line(item.description,16,MUTED)
		desc.size_flags_vertical=Control.SIZE_EXPAND_FILL
		box.add_child(desc)
		var choose:=button("[%d]  EQUIP & EVOLVE" % (i+1),func():action.emit("weapon_upgrade",id))
		box.add_child(choose)
		if i==0: choose.grab_focus()
		card_hit_area(card,item.color,func():action.emit("weapon_upgrade",id))
	centered_label("KEEP EVERY UNLOCK  /  %s SWITCHES WEAPONS DURING COMBAT  /  RANKS III & V TRANSFORM YOUR GUN" % key_names.weapon.to_upper(),790,12,MUTED,mono)
	animate_modal()

func weapon_blueprint(parent: Control, id: String, color: Color) -> void:
	var bp := Blueprint.new(id, color)
	bp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bp)

func update_weapon(weapons) -> void:
	var profile: Dictionary=weapons.PROFILES[weapons.mode]
	weapon_text.text="%s · %s" % [profile.name,weapons.roman(weapons.tier())]
	weapon_text.add_theme_color_override("font_color",profile.color)
	weapon_detail.text="%s  ·  %s SWITCH  ·  +%d%% POWER" % [profile.role,key_names.weapon.to_upper(),roundi((weapons.damage_scale()-1)*100)]

func stat_row(grid: GridContainer, name: String, value: String, value_color: Color = Color.WHITE) -> void:
	grid.add_child(nowrap(mono_line(name, 13, MUTED), 260))
	var v := mono_line(value, 15, value_color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(v)

func meter_row(box: VBoxContainer, name: String, ratio: float, color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(nowrap(mono_line(name, 11, MUTED), 56))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = 100
	bar.value = clampf(ratio, 0.0, 1.0) * 100.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("23282f")
	bg.set_corner_radius_all(2)
	var fl := StyleBoxFlat.new()
	fl.bg_color = color
	fl.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fl)
	row.add_child(bar)
	box.add_child(row)

func show_result(won: bool, data: Dictionary) -> void:
	clear_modal(); shade(0.86)
	hud.visible = false
	var box := sheet(Vector2(65, 18), 660, SIGNAL if won or data.get("retired",false) else CORAL)
	box.add_theme_constant_override("separation",10)
	var lockup := HBoxContainer.new()
	lockup.add_theme_constant_override("separation", 12)
	lockup.alignment = BoxContainer.ALIGNMENT_BEGIN
	var lock_sigil := Glyph.new("sigil", SIGNAL if won or data.get("retired",false) else CORAL, 30)
	lock_sigil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lockup.add_child(lock_sigil)
	var lock_text := mono_line("RUN RECORD · DEBRIEF", 12, SIGNAL if won or data.get("retired",false) else CORAL)
	lock_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lockup.add_child(nowrap(lock_text, 260))
	box.add_child(lockup)
	box.add_child(display_line("RUN BANKED" if data.get("retired",false) else "REACTOR SECURED" if won else "SIGNAL LOST",44,WHITE if won or data.get("retired",false) else CORAL))
	box.add_child(text_line("The storm keeps moving. So will you.",18,MUTED))
	box.add_child(HSeparator.new())
	box.add_child(mono_line("FINAL SCORE", 11, MUTED))
	var score_value := display_line("%06d" % data.score, 48, WHITE)
	box.add_child(score_value)
	box.add_child(mono_line("◆ NEW PERSONAL BEST" if int(data.score) >= int(data.best) and int(data.score) > 0 else "PERSONAL BEST · %06d" % data.best, 13, SIGNAL if int(data.score) >= int(data.best) and int(data.score) > 0 else MUTED))
	box.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 7)
	stat_row(grid, "MACHINES BROKEN", str(data.kills))
	stat_row(grid, "SHOTS STOLEN", str(data.absorbed))
	stat_row(grid, "PULSES RELEASED", str(data.pulses))
	stat_row(grid, "BEST COMBO", "×%d" % data.get("best_combo",0))
	stat_row(grid, "RUN TIME", "%02d:%02d" % [int(data.time)/60,int(data.time)%60])
	stat_row(grid, "SALVAGE CORES", "+%d  (HOLD %d)" % [data.get("cores_earned",0),data.get("cores",0)], AMBER)
	stat_row(grid, "WEAPON", "%s · RANK %s" % [data.get("weapon","VECTOR CARBINE"),data.get("rank","I")], WHITE)
	if data.get("campaign",false):
		stat_row(grid, "CAMPAIGN", "SECTOR %02d · %d RELAYS · %d GUARDIANS" % [data.sector,data.relays,data.get("guardians",0)])
		stat_row(grid, "ROUTE SEED", str(data.get("seed",0)))
	box.add_child(grid)
	if won: box.add_child(text_line("OVERDRIVE UNLOCKED  /  Enable it in Settings for a tougher heist.",13,SIGNAL))
	var result_levels: Dictionary = data.get("levels",{})
	if data.upgrades.is_empty():
		box.add_child(text_line("Your next weapon is waiting at the next checkpoint.",13,MUTED))
	else:
		box.add_child(mono_line("REACTOR BUILD", 11, MUTED))
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 8)
		chips.add_theme_constant_override("v_separation", 8)
		for id in data.upgrades:
			var lv: int = int(result_levels.get(id,1))
			var chip := PanelContainer.new()
			var chip_style := panel(Palette.PANEL_INSET, Palette.PANEL_LINE)
			chip_style.content_margin_left = 10
			chip_style.content_margin_right = 10
			chip_style.content_margin_top = 5
			chip_style.content_margin_bottom = 5
			chip.add_theme_stylebox_override("panel", chip_style)
			var chip_row := HBoxContainer.new()
			chip_row.add_theme_constant_override("separation", 6)
			chip_row.add_child(Glyph.new("core", family_color(Rules.UPGRADE_DATA[id].family), 14))
			chip_row.add_child(nowrap(mono_line(Rules.UPGRADE_DATA[id].name + ("" if lv<=1 else " Mk" + str(lv)), 11, WHITE), 10))
			chip.add_child(chip_row)
			chips.add_child(chip)
		box.add_child(chips)
	var again := button("RUN IT BACK    →",func():action.emit("restart",null),true)
	box.add_child(again)
	box.add_child(button("RETURN TO TITLE",func():action.emit("title",null)))
	box.add_child(button("QUIT GAME",func():action.emit("quit",null)))
	again.grab_focus()
	animate_modal()

func show_sector_complete(index: int, sector_name: String, elapsed: float, relays: int, data: Dictionary = {}) -> void:
	clear_modal(); shade(0.86)
	hud.visible = false
	var box := sheet(Vector2(65, 116), 700)
	box.add_theme_constant_override("separation",13)
	var s_lockup := HBoxContainer.new()
	s_lockup.add_theme_constant_override("separation", 12)
	var s_sigil := Glyph.new("sigil", SIGNAL, 30)
	s_sigil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s_lockup.add_child(s_sigil)
	var s_lock_text := mono_line("SECTOR %02d · SECURED" % (index+1),13,SIGNAL)
	s_lock_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s_lockup.add_child(nowrap(s_lock_text, 280))
	box.add_child(s_lockup)
	box.add_child(display_line(sector_name,48,WHITE))
	box.add_child(text_line("The next horizon is yours to take.",20,MUTED))
	box.add_child(mono_line("%d AIR RELAYS · %d GUARDIANS · %02d:%02d" % [relays,data.get("guardians",0),int(elapsed)/60,int(elapsed)%60],15,WHITE))
	var route_row := HBoxContainer.new()
	route_row.add_theme_constant_override("separation", 8)
	route_row.add_child(nowrap(mono_line("ROUTE", 11, MUTED), 52))
	for node_i in range(maxi(index + 2, 3)):
		var node := Glyph.new("core", SIGNAL if node_i <= index else Color(WHITE, 0.25), 13)
		node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		route_row.add_child(node)
		if node_i < maxi(index + 2, 3) - 1:
			var link := ColorRect.new()
			link.color = Color(WHITE, 0.25)
			link.custom_minimum_size = Vector2(26, 2)
			link.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			route_row.add_child(link)
	route_row.add_child(nowrap(mono_line("SECTOR %02d NEXT" % (index + 2), 11, MUTED), 130))
	box.add_child(route_row)
	box.add_child(mono_line("CARRYING · %s · RANK %s" % [data.get("weapon","VECTOR CARBINE"), data.get("rank","I")], 13, Color(WHITE, 0.8)))
	box.add_child(HSeparator.new())
	box.add_child(mono_line("NEXT · %s" % data.get("next","THE NEXT HORIZON"),13,MUTED))
	box.add_child(text_line("%s · %s" % [data.get("route","NEW ROUTE"),data.get("modifier","NEW HARDWARE")],20,WHITE))
	box.add_child(text_line("Keep your arsenal. Install a weapon upgrade. Continue as far as you can.",18,MUTED))
	var next := button("UPGRADE & DIVE DEEPER    →",func():action.emit("next_sector",null),true)
	box.add_child(next)
	box.add_child(button("BANK SCORE & END RUN",func():action.emit("bank",null)))
	box.add_child(button("QUIT GAME",func():action.emit("quit",null)))
	box.add_child(mono_line("ROUTE SEED %s · RESTART REPEATS THIS ROUTE" % str(data.get("seed",0)),11,MUTED))
	next.grab_focus()
	animate_modal()

func update_traversal(traversal) -> void:
	flight_bar.value = traversal.fuel*100.0
	flight_text.text = "%s · JUMP, HOLD TO GLIDE" % key_names.jump.to_upper()
	if traversal.gliding:
		altitude_text.text = "GLIDING · %.1f m · RELEASE TO DROP" % traversal.height
	elif not traversal.grounded:
		altitude_text.text = "AIRBORNE · %.1f m · %s" % [traversal.height,"WINGS EMPTY" if traversal.fuel<0.01 else "HOLD TO GLIDE"]
	else:
		altitude_text.text = "WINGS READY · JUMP OVER LOW SHOTS & GATES" if traversal.fuel>=0.99 else "RECHARGING WINGS · STAY ON THE DECK"

func show_hint(text: String, seconds: float = 4) -> void:
	hint.text = text
	hint_time = seconds
	hint.modulate.a = 1

func show_banner(title: String, subtitle: String) -> void:
	banner.text = title + "\n" + subtitle
	banner_time = 3.5
	banner.modulate.a = 1
	banner_plate.visible = true
	banner_plate.modulate.a = 1

func update_game(rules, run_time: float, boss_hp: float, boss_max: float, practice: bool) -> void:
	health_bar.max_value = rules.max_health
	health_bar.value = rules.health
	health_text.text = "HULL · %03d" % ceili(rules.health)
	health_bar.get_theme_stylebox("fill").bg_color = WHITE if rules.health > 0.3*rules.max_health else CORAL
	energy_bar.value = rules.energy
	var charged: bool = rules.energy >= 85
	var pulse_color := Palette.AMBER_HOT if charged else CYAN
	energy_bar.get_theme_stylebox("fill").bg_color = pulse_color
	energy_text.add_theme_color_override("font_color",Palette.SIGNAL_SOFT if charged else WHITE)
	energy_text.text = "%s · PULSE %03d%s" % [key_names.pulse.to_upper(),int(rules.energy), "  OVERLOAD" if charged else "  READY" if rules.energy >= rules.pulse_threshold() else ""]
	var energy_ticks := energy_bar.get_node("Ticks") as Control
	var new_ratio: float = rules.pulse_threshold() / 100.0
	if not is_equal_approx(float(energy_ticks.get("threshold")), new_ratio):
		energy_ticks.set("threshold", new_ratio)
		energy_ticks.queue_redraw()
	low_hull = rules.health <= 0.3 * rules.max_health and rules.health > 0.0
	var dash_cap: int = rules.max_dash_charges + (1 if rules.family_complete("HARVEST") else 0)
	dash_text.text = key_names.dash.to_upper()+"  DASH"
	if dash_pips:
		dash_pips.set("filled", rules.dash_charges)
		dash_pips.set("total", dash_cap)
		dash_pips.queue_redraw()
	time_text.text = "%02d:%02d" % [int(run_time)/60,int(run_time)%60]
	score_text.text = "%06d · SCORE" % rules.score
	status_text.text = "PRACTICE · LEARN THE HEIST" if practice else "SKYFORGE · THREAT %02d" % (1+int(run_time/60))
	boss_bar.visible = boss_max > 0
	boss_name.visible = boss_max > 0
	boss_plate.visible = boss_max > 0
	time_text.add_theme_color_override("font_color", Color(WHITE, 0.85) if boss_max > 0 else WHITE)
	objective_text.position.y = 162 if boss_max > 0 else 142
	if boss_max > 0: boss_bar.value = boss_hp / boss_max * 100
	combo_text.text = "COMBO ×%d  +%d%%" % [rules.combo, int(round((rules.combo_multiplier()-1.0)*100.0))] if rules.combo>=2 else ""
	combo_bar.visible = rules.combo >= 2
	if combo_bar.visible:
		combo_bar.value = clampf(rules.combo_timer / (rules.combo_window * 1.25), 0.0, 1.0) * 100.0
	var names: PackedStringArray = []
	for id in rules.upgrades:
		var lv: int = rules.level(id)
		names.append(Rules.UPGRADE_DATA[id].name + ("" if lv<=1 else " Mk"+str(lv)))
	for family in Rules.FAMILIES:
		if rules.family_complete(family): names.append(family+" RESONANCE")
	build_text.text = " · ".join(names) if not names.is_empty() else "EVOLVE YOUR WEAPON AT THE NEXT CHECKPOINT"

func _process(delta: float) -> void:
	if health_text:
		health_text.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)) if low_hull else 1.0
	if hint_time > 0:
		hint_time -= delta
		hint.modulate.a = clampf(hint_time,0,1)
	if banner_time > 0:
		banner_time -= delta
		banner.modulate.a = clampf(banner_time,0,1)
		banner_plate.modulate.a = banner.modulate.a
		if banner_time <= 0: banner_plate.visible = false
	if banner_plate.visible and banner.text.strip_edges().is_empty():
		banner_plate.visible = false
		banner_time = 0.0
	# Canvas items scale together to a consistent 1440 x 900 design space.
	var viewport_size := get_viewport().get_visible_rect().size
	root.scale = Vector2(viewport_size.x / 1440.0, viewport_size.y / 900.0)
	root.size = Vector2(1440,900)
