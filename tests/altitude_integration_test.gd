extends SceneTree

var checks := 0
var failures := 0
var game: Node3D

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run_checks")

func reset_case(from: Vector3 = Vector3.ZERO, to: Vector3 = Vector3.ZERO) -> void:
	game.start_run(false)
	game.player_previous = from
	game.player_node.position = to
	game.traversal.height = to.y
	game.traversal.previous_height = from.y
	game.traversal.grounded = to.y <= 0.0

func shot(at: Vector3 = Vector3(0.0,0.85,0.0), velocity: Vector3 = Vector3.ZERO) -> void:
	game.field.fire(Vector3.ZERO,Vector3.RIGHT,1,0.0)
	game.field.bullets.back().node.position = at
	game.field.bullets.back().velocity = velocity

func active_hazard(duration: float = 0.45) -> void:
	game.field.add_hazard(Vector3.ZERO,2.0,0.0)
	game.field.hazards.back().active = true
	game.field.hazards.back().timer = duration

func charger_at(at: Vector3) -> Node3D:
	var charger: Node3D = game.spawn_enemy("charger",at)
	charger.spawning = 0.0
	charger.charge_direction = Vector3.RIGHT
	charger.charge_time = 0.65
	return charger

func closed_gate() -> void:
	game.campaign_active = true
	var gate := Node3D.new()
	game.campaign.add_child(gate)
	game.campaign.gates.append({"node":gate,"open":0.0,"previous_open":0.0})

func run_checks() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = true

	reset_case(Vector3(-4,0,0),Vector3(4,0,0))
	game.rules.try_dash()
	shot()
	game.field.update(0.016)
	check(game.rules.absorbed == 1 and game.rules.energy == 10.0, "ground dash still harvests a crossed shot")
	check(game.field.bullets.is_empty() and game.field.pool.size() >= 1, "harvest still returns the projectile to its bounded pool")
	reset_case(Vector3(-4,2.5,0),Vector3(4,2.5,0))
	game.rules.try_dash()
	game.rules.apply_upgrade("collector")
	shot()
	game.field.update(0.016)
	check(game.rules.absorbed == 0 and game.rules.energy == 0.0, "air dash cannot harvest ground shots even with Wide Receiver")
	check(game.rules.health == 100.0 and game.field.bullets.size() == 1, "a shot passing under the flyer remains active and causes no damage")
	reset_case(Vector3(-4,0,0),Vector3(4,0,0))
	shot()
	game.field.update(0.016)
	check(game.rules.health == 88.0 and game.field.bullets.is_empty(), "grounded swept projectile damage is preserved")
	reset_case(Vector3(-4,0,0),Vector3(4,4,0))
	shot()
	game.field.update(0.016)
	check(game.rules.health == 100.0, "takeoff clears a shot if feet are high enough at the actual crossing")
	reset_case(Vector3(-4,0.2,0),Vector3(4,1,0))
	shot()
	game.field.update(0.016)
	check(game.rules.health == 88.0, "a low jump still takes projectile damage")
	reset_case()
	shot(Vector3(-4,0.85,0),Vector3(80,0,0))
	game.field.update(0.1)
	check(game.rules.health == 88.0, "fast moving shots cannot tunnel through a stationary player")

	reset_case(Vector3(0,2,0),Vector3(0,2,0))
	var charger := charger_at(Vector3(-3,0,0))
	charger.update(0.4)
	check(charger.position.x > 2.0 and game.rules.health == 100.0, "a committed charger passes beneath an airborne player")
	reset_case()
	charger = charger_at(Vector3(-3,0,0))
	charger.update(0.4)
	check(game.rules.health == 82.0, "the same charger sweep hits a grounded player between its endpoints")
	reset_case(Vector3(0,1.4,0),Vector3(0,1.4,0))
	charger = charger_at(Vector3(-3,0,0))
	charger.update(0.4)
	check(game.rules.health == 82.0, "a partial jump below enemy body height does not grant invulnerability")
	reset_case(Vector3(0,2.5,0),Vector3(0,2.5,0))
	var boss: Node3D = game.spawn_enemy("boss",Vector3.ZERO)
	boss.spawning = 0.0
	boss.update(0.016)
	check(game.rules.health == 76.0, "flying into the guardian torso still causes contact damage")
	reset_case(Vector3(0,3,0),Vector3(0,3,0))
	boss = game.spawn_enemy("boss",Vector3.ZERO)
	boss.spawning = 0.0
	boss.update(0.016)
	check(game.rules.health == 100.0, "a full height jump clears the guardian body")

	reset_case(Vector3(0,1,0),Vector3(0,1,0))
	active_hazard()
	game.field.update(0.016)
	check(game.rules.health == 100.0, "flight over the full shockwave disk avoids low ground damage")
	reset_case(Vector3(1.95,0.69,0),Vector3(1.95,0.69,0))
	active_hazard()
	game.field.update(0.016)
	check(game.rules.health == 80.0, "hazard disk uses horizontal radius instead of a diagonal sphere")
	reset_case(Vector3(0,0.5,0),Vector3(0,1,0))
	active_hazard()
	game.field.update(0.016)
	check(game.rules.health == 80.0, "taking off through an already active hazard still registers the low-height crossing")
	reset_case(Vector3(0,1,0),Vector3(0,0.5,0))
	active_hazard()
	game.field.update(0.016)
	check(game.rules.health == 80.0, "landing into an active hazard registers ground contact")
	reset_case(Vector3(0,0,0),Vector3(0,2,0))
	game.field.add_hazard(Vector3.ZERO,2.0,0.05)
	game.field.update(0.1)
	check(game.rules.health == 100.0, "a warning cannot retroactively damage the low part of a jump before activation")
	reset_case(Vector3(0,2,0),Vector3(0,0,0))
	active_hazard(0.025)
	game.field.update(0.1)
	check(game.rules.health == 100.0 and game.field.hazards.is_empty(), "landing after hazard expiry is safe and removes the expired volume")
	reset_case()
	game.rules.try_dash()
	active_hazard()
	game.field.update(0.016)
	check(game.rules.health == 80.0, "ground shockwaves retain their original ability to damage a grounded dash")
	reset_case()
	game.field.add_hazard(Vector3.ZERO,2.0,0.5)
	game.field.update(0.016)
	check(game.rules.health == 100.0 and not game.field.hazards.back().active, "telegraph warning remains harmless")
	game.field.add_field(Vector3(2,0.4,3),true)
	check(is_equal_approx(game.field.fields.back().node.position.y,0.12), "a near-ground dash leaves its burning field on the deck")

	reset_case(Vector3(0,0,-3),Vector3(0,0,-3))
	closed_gate()
	charger = charger_at(Vector3(0,0,3))
	charger.charge_direction = Vector3.FORWARD
	charger.update(0.4)
	check(charger.position.z >= 0.69 and charger.charge_time == 0.0 and game.rules.health == 100.0, "a closed shutter blocks and stops a committed enemy charge")
	reset_case(Vector3(0,0,-3),Vector3(0,0,-3))
	closed_gate()
	charger = charger_at(Vector3(0,0,3))
	charger.charge_time = 0.0
	charger.cooldown = 0.0
	charger.update(0.016)
	check(charger.warning_lane.get_node("LaneFill").mesh.size.z < 3.0, "charger warning lanes stop at the same solid shutter as the attack")
	reset_case(Vector3(0,0,-3),Vector3(0,0,-3))
	closed_gate()
	charger = charger_at(Vector3(0,0,1))
	charger.charge_time = 0.0
	charger.cooldown = 100.0
	charger.update(0.2)
	check(absf(charger.position.x) > 0.1 and charger.position.z >= 0.7, "regular enemy movement seeks a shutter edge instead of walking into its face")
	reset_case(Vector3(0,0,-2.5),Vector3(0,0,-2.5))
	closed_gate()
	shot(Vector3(0,0.85,3),Vector3(0,0,-60))
	game.field.update(0.1)
	check(game.rules.health == 100.0 and game.field.bullets.is_empty(), "a nearer solid shutter absorbs a shot before it can hit a player behind it")
	reset_case(Vector3(0,0,-2.5),Vector3(0,0,-2.5))
	closed_gate()
	game.rules.try_dash()
	shot(Vector3(0,0.85,3),Vector3(0,0,-60))
	game.field.update(0.1)
	check(game.rules.absorbed == 0 and game.field.bullets.is_empty(), "a dash behind a closed gate cannot harvest a blocked shot")
	reset_case(Vector3(0,0,-0.7),Vector3(0,0,-0.7))
	closed_gate()
	game.rules.apply_upgrade("collector")
	game.rules.try_dash()
	shot(Vector3(0,0.85,0.7))
	game.field.update(0.016)
	check(game.rules.absorbed == 0 and game.field.bullets.size() == 1, "Wide Receiver cannot harvest through a closed shutter even inside its expanded radius")
	reset_case(Vector3(0,0,1.5),Vector3(0,0,1.5))
	closed_gate()
	game.rules.apply_upgrade("collector")
	game.rules.try_dash()
	shot(Vector3(0,0.85,0.7))
	game.field.update(0.016)
	check(game.rules.absorbed == 1, "Wide Receiver still harvests an unobstructed shot on the same side of a shutter")
	reset_case(Vector3(0,0,1.5),Vector3(0,0,1.5))
	closed_gate()
	shot(Vector3(0,0.85,3),Vector3(0,0,-60))
	game.field.update(0.1)
	check(game.rules.health == 88.0, "projectile collision before a farther gate still damages the player")
	reset_case(Vector3(0,0,-2.5),Vector3(0,0,-2.5))
	closed_gate()
	game.campaign.gates[0].open = 1.0
	game.campaign.gates[0].previous_open = 1.0
	shot(Vector3(0,0.85,3),Vector3(0,0,-60))
	game.field.update(0.1)
	check(game.rules.health == 88.0, "opening the gate restores projectile passage through its center")

	reset_case()
	game.traversal.request_jump()
	for i in range(120): game.traversal.step(1.0/120.0,true)
	game.player_node.position.y = game.traversal.height
	var paused_height: float = game.traversal.height
	var paused_fuel: float = game.traversal.fuel
	var paused_velocity: float = game.traversal.vertical_velocity
	game.state = "paused"
	game._physics_process(0.5)
	check(game.traversal.height == paused_height and game.traversal.fuel == paused_fuel and game.traversal.vertical_velocity == paused_velocity, "the actual game pause route freezes altitude, descent and wing fuel")
	game.start_run(false)
	check(game.player_position.y == 0.0 and game.traversal.grounded and game.traversal.fuel == 1.0 and not game.traversal.gliding, "restart resets both the real model position and traversal resources")
	check(game.field.bullets.is_empty() and game.field.hazards.is_empty() and game.field.fields.is_empty(), "restart clears all hostile and ground effect remnants")

	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	print("Altitude integration: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
