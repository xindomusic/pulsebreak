extends Node3D
## Enemy patterns expose windups before committing to an attack.
const Art = preload("res://scripts/art.gd")
var game: Node3D
var kind := "gunner"
var hp := 45.0
var max_hp := 45.0
var speed := 2.0
var cooldown := 1.6
var age := 0.0
var windup := 0.0
var charge_time := 0.0
var charge_direction := Vector3.ZERO
var shield_broken := 0.0
var slow := 0.0
var hurt := 0.0
var radius := 0.65
var model: Node3D
var telegraph: MeshInstance3D
var dead := false
var phase := 1
var attack_index := 0
var spawning := 0.85
var warning_lane: Node3D

func setup(owner_game: Node3D, enemy_kind: String, at: Vector3) -> void:
	game = owner_game
	kind = enemy_kind
	position = at
	if kind == "boss":
		hp = 3400; speed = 1.4; radius = 1.7
		model = Art.boss()
	elif kind == "charger":
		hp = 55; speed = 2.8
		model = Art.enemy(kind)
	elif kind == "bruiser":
		hp = 135; speed = 1.5; radius = 0.85
		model = Art.enemy(kind)
	else:
		hp = 44; speed = 1.9
		model = Art.enemy(kind)
	max_hp = hp
	if game.hard_mode: hp*=1.2; max_hp=hp; speed*=1.1
	add_child(model)
	model.scale = Vector3.ONE * 0.01
	cooldown += game.rng.randf_range(0, 1.1)
	telegraph = game.make_ring(radius + 0.5, Color(1, 0.53, 0.25, 0.8))
	add_child(telegraph)
	telegraph.position.y = 0.06
	if kind=="charger":
		warning_lane=Node3D.new()
		warning_lane.name="AttackLane"
		add_child(warning_lane)
		var stripe:=MeshInstance3D.new()
		var mesh:=BoxMesh.new()
		mesh.size=Vector3(2.14,0.025,8.8)
		stripe.name="LaneFill"
		stripe.mesh=mesh
		stripe.material_override=game.field.glow_material(Color(1,0.28,0.42,0.65),true)
		stripe.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stripe.position=Vector3(0,0.065,4.4)
		warning_lane.add_child(stripe)
		warning_lane.visible=false

func update(delta: float) -> void:
	if dead: return
	age += delta
	if spawning > 0:
		spawning -= delta
		model.scale = Vector3.ONE * clampf(1.0 - spawning / 0.85, 0.01, 1)
		telegraph.scale = Vector3.ONE * (1.1 + sin(age * 12) * 0.1)
		if spawning <= 0:
			telegraph.visible = false
		return
	shield_broken = maxf(0, shield_broken - delta)
	slow = maxf(0, slow - delta)
	hurt = maxf(0, hurt - delta)
	model.position.y = sin(age * 3.0) * 0.06 + hurt * 0.7
	var shield: Node3D = model.get_node_or_null("Shield")
	if shield: shield.visible = shield_broken <= 0
	var to_player: Vector3 = game.player_position - position
	to_player.y = 0
	var distance := to_player.length()
	var direction := to_player.normalized()
	var move_speed := speed * (0.5 if slow > 0 else 1.0)
	if charge_time > 0:
		charge_time -= delta
		var wanted:=delta*(14.0 if kind=="charger" else 9.0)
		if slow>0: wanted*=0.5
		var travel:=distance_to_wall(charge_direction,wanted)
		position+=charge_direction*travel
		if travel<wanted: charge_time=0
		game.add_trail(position, Color(1, 0.24, 0.42, 0.5), 0.4)
	elif windup > 0:
		windup -= delta
		telegraph.visible = true
		telegraph.scale = Vector3.ONE * (1.0 + sin(age * 22) * 0.08)
		if windup <= 0:
			telegraph.visible = false
			if warning_lane: warning_lane.visible=false
			perform_attack(direction)
	else:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 5)
		if kind == "gunner":
			if distance > 8.5: position += direction * move_speed * delta
			elif distance < 5.5: position -= direction * move_speed * delta * 0.75
		elif kind == "boss":
			if distance > 9: position += direction * move_speed * delta
		else:
			position += direction * move_speed * delta
		cooldown -= delta * (0.78 if game.settings.get("assist", false) else 1.0)
		if cooldown <= 0:
			windup = 0.8 if kind != "boss" else 1.0
			charge_direction = (to_player + game.player_velocity * 0.32).normalized()
			if warning_lane:
				warning_lane.visible=true
				warning_lane.rotation.y=atan2(charge_direction.x,charge_direction.z)-rotation.y
				var lane_length:=distance_to_wall(charge_direction,9.1)
				var fill: MeshInstance3D=warning_lane.get_node("LaneFill")
				fill.mesh.size.z=maxf(0.1,lane_length)
				fill.position.z=lane_length*0.5
			cooldown = 2.8 if kind == "gunner" else 3.4
			if kind == "boss": cooldown = 2.2 if phase == 2 else 2.9
			game.cue("warning", 0.5)
	position.x = clampf(position.x, -14.5, 14.5)
	position.z = clampf(position.z, -14.5, 14.5)
	if position.distance_to(game.player_position) < radius + 0.42:
		game.hit_player(18 if kind != "boss" else 24)
	if kind == "boss" and phase == 1 and hp < max_hp * 0.5:
		phase = 2
		game.announce("GUARDIAN // OVERDRIVE", "Offset volleys. Watch the marked ground.")
		game.cue("boss", 1.0)

func distance_to_wall(direction: Vector3, maximum: float) -> float:
	var distance:=maximum
	if absf(direction.x)>0.001:
		distance=minf(distance,maxf(0,((14.5 if direction.x>0 else -14.5)-position.x)/direction.x))
	if absf(direction.z)>0.001:
		distance=minf(distance,maxf(0,((14.5 if direction.z>0 else -14.5)-position.z)/direction.z))
	return distance

func perform_attack(direction: Vector3) -> void:
	if kind == "gunner":
		game.fire_volley(position, direction, 5, 7.8)
	elif kind == "charger":
		charge_time = 0.65
		rotation.y = atan2(charge_direction.x, charge_direction.z)
	elif kind == "bruiser":
		game.add_hazard(position + direction * 1.7, 2.3, 0.95)
		game.fire_volley(position, direction, 3, 5.5)
	elif kind == "boss":
		attack_index += 1
		if attack_index % 3 == 0:
			game.fire_volley(position,direction,5,6.8)
			game.add_hazard(game.player_position, 3.5, 1.25)
			if phase == 2:
				game.add_hazard(game.player_position + Vector3(5, 0, 0), 2.5, 1.5)
		else:
			game.fire_volley(position, direction, 9 if phase == 2 else 7, 8.5)
			if phase == 2:
				game.queue_volley(position, direction.rotated(Vector3.UP, 0.16), 8, 8.5, 0.38)
			if attack_index % 2 == 0:
				game.add_hazard(position + direction * 3, 2.8, 1.15)

func take_hit(amount: float, from_pulse: bool = false) -> void:
	if dead or spawning > 0: return
	if kind == "bruiser" and shield_broken <= 0:
		if from_pulse:
			shield_broken = 3.5
		else:
			var facing := Vector3(sin(rotation.y), 0, cos(rotation.y))
			if facing.dot((game.player_position - position).normalized()) > 0.1:
				amount *= 0.25
	hp -= amount
	hurt = 0.15
	game.hit_spark(position + Vector3(0, 0.8, 0), Color(1, 0.8, 0.5))
	if hp <= 0:
		dead = true
		game.enemy_defeated(self)
