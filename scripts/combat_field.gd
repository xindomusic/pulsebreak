extends Node3D
## Bounded visual effects, pooled projectiles and swept collision.
const Traversal = preload("res://scripts/traversal.gd")
const HAZARD_HEIGHT := 0.7
var game: Node3D
var bullets: Array = []
var pool: Array[MeshInstance3D] = []
var effects: Array = []
var hazards: Array = []
var fields: Array = []
var delayed: Array = []
var shot_mesh: SphereMesh
var shot_material: StandardMaterial3D
const MAX_BULLETS := 220

func _ready() -> void:
	shot_mesh = SphereMesh.new()
	shot_mesh.radius = 0.2
	shot_mesh.height = 0.4
	shot_mesh.radial_segments = 4
	shot_mesh.rings = 1
	shot_material = glow_material(Color("ffb465"))

func glow_material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(color.r, color.g, color.b)
	m.emission_energy_multiplier = 1.4
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = false
	return m

func ring(radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.01, radius - 0.065)
	mesh.outer_radius = radius + 0.065
	mesh.rings = 40
	mesh.ring_segments = 6
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = glow_material(color, color.a < 1)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func fire(origin: Vector3, direction: Vector3, count: int, speed: float) -> void:
	for i in range(count):
		if bullets.size() >= MAX_BULLETS: break
		var angle := (float(i) - float(count - 1) * 0.5) * 0.155
		var velocity := direction.rotated(Vector3.UP, angle) * speed
		var node: MeshInstance3D
		if pool.is_empty():
			node = MeshInstance3D.new()
			node.mesh = shot_mesh
			node.material_override = shot_material
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(node)
		else:
			node = pool.pop_back()
		node.visible = true
		node.position = origin + direction * 0.9 + Vector3(0,0.85,0)
		bullets.append({"node":node,"velocity":velocity,"life":7.0})

func discard_bullet(index: int) -> void:
	var node: MeshInstance3D = bullets[index].node
	node.visible = false
	pool.append(node)
	bullets.remove_at(index)

func add_effect(at: Vector3, color: Color, size: float, duration: float = 0.4) -> void:
	if effects.size() >= (32 if game.settings.get("low_effects",false) else 70): return
	var node := ring(1.0,color)
	add_child(node)
	node.position = at + Vector3(0,0.08,0)
	node.scale = Vector3.ONE * 0.1
	effects.append({"node":node,"life":duration,"total":duration,"size":size,"style":"ring"})

func spark(at: Vector3, color: Color) -> void:
	if effects.size() >= 65: return
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.11
	mesh.height = 0.22
	mesh.radial_segments = 6
	mesh.rings = 2
	node.mesh = mesh
	node.material_override = glow_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position = at
	effects.append({"node":node,"life":0.18,"total":0.18,"size":1.0,"style":"spark"})

func line(from: Vector3, to: Vector3, color: Color, width: float = 0.04) -> void:
	if effects.size() > 65: return
	var dist := from.distance_to(to)
	if dist < 0.01: return
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = width
	mesh.bottom_radius = width
	mesh.height = dist
	mesh.radial_segments = 5
	node.mesh = mesh
	node.material_override = glow_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position = (from+to)*0.5
	var up := (to-from).normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.1: right = up.cross(Vector3.RIGHT).normalized()
	node.basis = Basis(right, up, right.cross(up)).orthonormalized()
	effects.append({"node":node,"life":0.09,"total":0.09,"size":1.0,"style":"line"})

func add_hazard(at: Vector3, radius: float, warning: float) -> void:
	if hazards.size() >= 5: return
	var node := ring(radius,Color(1,0.28,0.39,0.9))
	add_child(node)
	node.position = Vector3(clampf(at.x,-12,12),0.10,clampf(at.z,-12,12))
	hazards.append({"node":node,"radius":radius,"timer":warning,"warning":warning,"active":false})

func add_field(at: Vector3, burning: bool) -> void:
	if fields.size() >= 22: return
	var color := Color(0.3,0.85,1,0.5) if not burning else Color(1,0.62,0.22,0.7)
	var node := ring(0.8,color)
	add_child(node)
	node.position = Vector3(at.x,0.12,at.z)
	fields.append({"node":node,"timer":2.0,"burning":burning})

func update(delta: float) -> void:
	for i in range(bullets.size()-1,-1,-1):
		var b: Dictionary = bullets[i]
		var node: MeshInstance3D = b.node
		var previous := node.position
		node.position += b.velocity * delta
		var player_end: Vector3 = game.player_position
		var gate_hit := false
		if game.campaign_active:
			var blocked: Vector3 = game.campaign.resolve_gates(previous,node.position)
			gate_hit = not blocked.is_equal_approx(node.position)
			if gate_hit:
				# Resolve the nearer gate first, then test only the time before
				# impact. A target behind a solid shutter cannot steal the shot.
				var travel_z := node.position.z-previous.z
				var fraction := clampf((blocked.z-previous.z)/travel_z,0.0,1.0) if absf(travel_z)>0.00001 else 0.0
				node.position = previous.lerp(node.position,fraction)
				player_end = game.player_previous.lerp(game.player_position,fraction)
		node.rotate_y(delta * 5)
		b.life -= delta
		# Match horizontal AND vertical overlap at the swept crossing. Flight
		# above a low volley must avoid both damage and free remote harvesting.
		var reach := 1.55 if game.rules.upgrades.has("collector") else 0.82
		var harvest_hit: bool = game.rules.dash_time > 0 and Traversal.swept_body_hit(game.player_previous,player_end,previous,node.position,reach,-0.2,0.2)
		if harvest_hit and game.campaign_active:
			# Wide Receiver's radius reaches across a shut door. Require an
			# unobstructed link at closest approach, not at the frame endpoint.
			var crossing := Traversal.crossing_fraction(game.player_previous,player_end,previous,node.position)
			var shot_at := previous.lerp(node.position,crossing)
			var receiver_at: Vector3 = game.player_previous.lerp(player_end,crossing)+Vector3(0,0.85,0)
			harvest_hit = game.campaign.resolve_gates(shot_at,receiver_at).is_equal_approx(receiver_at)
		if harvest_hit:
			game.rules.harvest(15 if game.rules.upgrades.has("capacitor") else 10)
			line(node.position,game.player_position+Vector3(0,1,0),Color("76f7df"),0.06)
			game.cue("absorb",0.65)
			game.harvest_flash = 0.25
			discard_bullet(i)
		elif Traversal.swept_body_hit(game.player_previous,player_end,previous,node.position,0.48,-0.2,0.2):
			game.hit_player(12)
			discard_bullet(i)
		elif gate_hit:
			spark(node.position,Color("ffb465"))
			discard_bullet(i)
		elif b.life <= 0 or absf(node.position.x)>20 or absf(node.position.z)>20:
			discard_bullet(i)
	for i in range(effects.size()-1,-1,-1):
		var e: Dictionary = effects[i]
		e.life -= delta
		if e.life <= 0:
			e.node.queue_free(); effects.remove_at(i); continue
		var ratio: float = e.life / e.total
		if e.style == "ring":
			e.node.scale = Vector3.ONE * lerpf(float(e.size),0.1,ratio*ratio)
			var material: StandardMaterial3D = e.node.material_override
			if material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = ratio
		elif e.style == "spark":
			e.node.scale = Vector3.ONE * (1+ratio*2)
	for i in range(hazards.size()-1,-1,-1):
		var h: Dictionary = hazards[i]
		var timer_before: float = h.timer
		var active_start := 0.0
		var active_end := 1.0
		h.timer -= delta
		h.node.scale = Vector3.ONE * (1.0 + sin(h.timer*16)*0.03)
		if h.timer <= 0 and not h.active:
			h.active = true
			h.timer += 0.45
			if delta > 0.0:
				active_start = clampf(timer_before/delta,0.0,1.0)
				active_end = clampf((timer_before+0.45)/delta,0.0,1.0)
			add_effect(h.node.position,Color("ff5272"),h.radius,0.45)
			game.cue("hit",0.35)
		elif h.active and delta > 0.0:
			active_end = clampf(timer_before/delta,0.0,1.0)
		if h.active:
			# Telegraph rings cover an XZ disk with a low damage volume. Clip
			# the sweep to the active part of this step so warning time is safe.
			var ground: Vector3 = Vector3(h.node.position.x,0.0,h.node.position.z)
			var from: Vector3 = game.player_previous.lerp(game.player_position,active_start)
			var to: Vector3 = game.player_previous.lerp(game.player_position,active_end)
			if Traversal.swept_body_hit(from,to,ground,ground,h.radius,0.0,HAZARD_HEIGHT):
				game.hit_player(20,true)
			if h.timer<=0:
				h.node.queue_free(); hazards.remove_at(i)
	for i in range(fields.size()-1,-1,-1):
		var f: Dictionary = fields[i]
		f.timer -= delta
		for enemy in game.enemies:
			if not enemy.dead and enemy.position.distance_to(f.node.position)<1.2:
				if f.burning: enemy.take_hit(delta*18,true)
				if game.rules.upgrades.has("frost"): enemy.slow = 0.2
		if f.timer<=0:
			f.node.queue_free(); fields.remove_at(i)
	for i in range(delayed.size()-1,-1,-1):
		var d: Dictionary = delayed[i]
		d.timer -= delta
		if d.timer<=0:
			delayed.remove_at(i)
			if d.kind == "volley": fire(d.origin,d.direction,d.count,d.speed)
			elif d.kind == "echo": game.pulse_at(d.origin,d.power,true)

func clear() -> void:
	for i in range(bullets.size()-1,-1,-1): discard_bullet(i)
	for collection in [effects,hazards,fields]:
		for entry in collection: entry.node.queue_free()
		collection.clear()
	delayed.clear()
