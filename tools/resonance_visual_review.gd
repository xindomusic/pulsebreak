extends "res://tools/overdrive_visual_review.gd"
## Current-iteration appearance review. Reuses deterministic combat stepping,
## but never overwrites the earlier Overdrive evidence or user preferences.


func review() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Resonance visual review requires native rendering.")
		quit(1)
		return
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.qa_mode = true
	game.qa_simulation = true
	game.settings.shake = 0.0
	game.settings.volume = 0.0
	game.settings.low_effects = false
	game.apply_settings()
	output = ProjectSettings.globalize_path("res://qa/resonance-visual")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-dir="): output = arg.trim_prefix("--qa-dir=")
	game.qa_output_dir = output
	await _capture("title")
	await _hero_palette()
	for sector: int in [0, 1, 2]:
		await _sector_palette(sector)
	await _busy_fight(false)
	await _busy_fight(true)
	await _pulse_scene(100.0, false, false, [0.0, 0.06, 0.18, 0.45])
	await _pulse_scene(100.0, false, true, [0.0, 0.06, 0.18, 0.45])
	await _pulse_scene(30.0, false, false, [0.06, 0.18])
	await _pulse_scene(100.0, true, false, [0.06, 0.18])
	await _finish_review()


func _hero_palette() -> void:
	_reset_scene()
	game.ui.visible = false
	game.player_node.position = Vector3.ZERO
	game.player_node.rotation.y = 0.25
	game.Art.aim_weapon(game.player_node, Vector3(0.35, 0, 1).normalized())
	_advance(0.15)
	game.camera.size = 6.1
	game.camera.position = Vector3(2.8, 3.0, 6.6)
	game.camera.look_at(Vector3(0, 1.05, 0.25))
	await _capture("hero-cobalt-close")
	for step: int in range(30):
		game.Art.animate_player(game.player_node, 1.0 / 60.0, 1.0, true, true, false, float(step) / 60.0)
	game.camera.size = 8.8
	await _capture("hero-cobalt-glide")


func _advance(seconds: float) -> void:
	super._advance(seconds)
	# The staged director is frozen. Advance its short pooled light explicitly,
	# alongside the same elapsed time used by the inherited combat/FX clocks.
	game.pulse_light_time = maxf(0.0, game.pulse_light_time - seconds)
	game.pulse_light.visible = game.pulse_light_time > 0.0 and not game.settings.low_effects
	game.pulse_light.light_energy = game.pulse_light_strength * pow(game.pulse_light_time / 0.26, 2)


func _sector_palette(sector: int) -> void:
	_reset_scene()
	game.start_campaign(74921)
	game.campaign.enter_sector(sector)
	game.ui.banner.text = ""
	game.ui.hint.text = ""
	game.player_node.position = Vector3(-1.0, 0, 8.0)
	game.player_previous = game.player_position
	game.player_marker.position = Vector3(-1.0, 0.06, 8.0)
	game.player_marker.visible = true
	_target("gunner", Vector3(-8, 0, -1))
	_target("charger", Vector3(5, 0, -3))
	_target("bruiser", Vector3(7, 0, 7))
	game.campaign.update(0.35)
	_advance(0.35)
	game.ui.objective_text.text = game.campaign.objective()
	await _capture("sector-%02d-palette" % (sector + 1))


func _pulse_scene(power: float, echo: bool, low: bool, times: Array) -> void:
	_reset_scene()
	game.start_campaign(74921)
	game.campaign.enter_sector(2)
	game.ui.banner.text = ""
	game.ui.hint.text = ""
	game.settings.low_effects = low
	game.apply_settings()
	game.player_node.position = Vector3(0, 0, 5)
	game.player_previous = game.player_position
	game.player_marker.position = Vector3(0, 0.06, 5)
	game.player_marker.visible = true
	for index: int in range(8):
		var angle: float = TAU * float(index) / 8.0
		var at := Vector3(sin(angle) * 6.3, 0, 5 + cos(angle) * 6.3)
		var enemy := _target(["gunner", "charger", "bruiser"][index % 3], at, 50.0 if index < 2 else 450.0)
		if enemy.kind == "gunner":
			game.field.fire(at, (game.player_position - at).normalized(), 7, 7.8)
		if enemy.kind == "charger": enemy.cooldown = 0.01
	game.field.add_hazard(Vector3(-7.0, 0, 5), 2.1, 1.0)
	game.campaign.update(0.18)
	_advance(0.15)
	game.rules.energy = power
	if echo:
		game.rules.energy = 0.0
		game.pulse_at(game.player_position, power, true)
	else:
		game.pulse()
	var previous_time := 0.0
	for moment: float in times:
		_advance(moment - previous_time)
		previous_time = moment
		game.ui.objective_text.text = "PULSE %03d / %s / %s" % [int(power), "ECHO" if echo else "MAIN", "LOW EFFECTS" if low else "FULL EFFECTS"]
		await _capture("pulse-%03d-%s-%s-%03d" % [int(power), "echo" if echo else "main", "low" if low else "full", roundi(moment * 1000.0)])
