extends SceneTree
## Reforge: marks, combo, splitter/mites, elites, salvage cores and Hangar perks.
const Store = preload("res://scripts/save_store.gd")
var game: Node3D
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var fixture := "res://qa/reforge-settings-%d.json" % OS.get_process_id()
	var original_save: String = Store.save_path
	Store.save_path = fixture
	# Save validation: cores/perks survive round-trip and clamp to sane ranges.
	var data: Dictionary = Store.default_data()
	data.cores = 500
	data.perks = {"hull": 9, "dash": 2, "bogus": 3, "combo": -4}
	check(Store.save_data(data), "reforge save writes")
	var loaded: Dictionary = Store.load_data()
	check(loaded.cores == 500 and loaded.perks.hull == 3 and loaded.perks.dash == 2 and not loaded.perks.has("bogus") and loaded.perks.combo == 0, "perk ranks clamp to 0..3 and unknown perks drop")

	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = false
	game.settings.cores = 500
	game.settings.perks = {}

	# Hangar purchases spend cores, cap at rank 3, and persist.
	game.buy_perk("hull")
	game.buy_perk("hull")
	check(game.perk_rank("hull") == 2 and int(game.settings.cores) == 500 - 24 - 48, "hangar buys two hull ranks at listed costs")
	game.buy_perk("hull"); game.buy_perk("hull")
	check(game.perk_rank("hull") == 3, "perks cap at rank 3")
	check(Store.load_data().perks.hull == 3, "purchases persist to the validated save")
	var cores_before: int = int(game.settings.cores)
	game.settings.cores = 0
	game.buy_perk("dash")
	check(game.perk_rank("dash") == 0, "insufficient cores cannot buy a perk")
	game.settings.cores = cores_before

	# Perks apply at run start.
	game.start_run(false)
	check(is_equal_approx(game.rules.max_health, 130.0) and is_equal_approx(game.rules.health, 130.0), "hull perk raises max hull on a fresh run")
	check(game.state == "run", "run starts with perks applied")

	# Splitter splits into two mites through the real defeat callback.
	var splitter = game.spawn_enemy("splitter", Vector3(3, 0, -3))
	check(splitter != null and splitter.kind == "splitter", "splitter spawns")
	splitter.spawning = 0.0
	var before: int = game.enemies.size()
	splitter.take_hit(9999.0, true)
	var mites := 0
	for enemy in game.enemies:
		if enemy.kind == "mite": mites += 1
	check(splitter.dead and mites == 2 and game.enemies.size() == before + 2, "killing a splitter releases exactly two mites")
	check(game.rules.combo >= 1 and game.rules.best_combo >= 1, "kills feed the combo counter")

	# Marks change real numbers: Mk III capacitor harvests more per shot.
	game.rules.reset()
	game.rules.try_dash()
	var base_gain: float = game.rules.harvest(10.0)
	game.rules.reset()
	for i in range(3): game.rules.apply_upgrade("capacitor")
	game.rules.try_dash()
	for i in range(6): game.rules.harvest(22.0)
	check(base_gain == 10.0 and game.rules.harvested_this_dash > 60.0, "capacitor marks raise the per-dash harvest cap (got %s)" % game.rules.harvested_this_dash)

	# Damage numbers and ghosts stay bounded.
	game.weapon_fx.low_effects = false
	for i in range(40): game.weapon_fx.damage_number(Vector3.ZERO, 25.0)
	check(game.weapon_fx.numbers.size() <= game.weapon_fx.MAX_NUMBERS, "damage numbers are capped")
	for i in range(10): game.weapon_fx.dash_ghost(game.player_node)
	check(game.weapon_fx.active.size() <= game.weapon_fx.MAX_EFFECTS, "dash ghosts share the bounded FX pool")
	game.weapon_fx.clear()
	check(game.weapon_fx.numbers.is_empty() and game.weapon_fx.active.is_empty(), "FX clear releases numbers and ghosts")

	# Cores are earned on finish and shown on the result payload.
	game.start_run(false)
	game.rules.kills = 40
	game.rules.score = 3000
	game.finish(false)
	check(game.cores_earned == int((40/6 + 3000/5000) * 0.6), "a lost run pays 60%% salvage (got %d)" % game.cores_earned)
	check(int(Store.load_data().cores) >= game.cores_earned, "earned cores persist after the run")

	# Regression: practice must not strip perks from the next real run.
	game.start_run(true)
	check(is_equal_approx(game.rules.max_health, 100.0), "practice runs at base hull without hangar perks")
	game.start_run(false)
	check(is_equal_approx(game.rules.max_health, 130.0), "real run after practice keeps hangar hull")

	# Regression: Capacitor Mk III vent drains energy, so it cannot repeat free.
	game.rules.reset()
	for i in range(3): game.rules.apply_upgrade("capacitor")
	game.rules.energy = 100.0
	game.dash()
	check(is_equal_approx(game.rules.energy, 70.0), "capacitor vent spends 30 energy (got %s)" % game.rules.energy)

	# Regression: elites keep their scale after the spawn-in animation.
	game.start_run(false)
	var elite = game.spawn_enemy("gunner", Vector3(2,0,-2))
	elite.elite = "swift"; elite.base_scale = 1.25; elite.spawning = 0.01
	elite.update(0.05)
	check(elite.model.scale.is_equal_approx(Vector3.ONE*1.25), "elite scale survives spawn-in (got %s)" % elite.model.scale)
	check(elite.telegraph.visible, "elite keeps a visible affix ring after spawning")

	# Regression: boss-death bursts survive the deferred field clear.
	game.field.delayed.append({"kind":"burst","origin":Vector3.ZERO,"timer":5.0})
	game.field.clear(true)
	check(game.field.delayed.size() == 1 and game.field.delayed[0].kind == "burst", "boss bursts survive an opt-in field clear")
	game.field.clear()
	check(game.field.delayed.is_empty(), "a plain field clear drops leftover bursts")

	# Regression: capacitor marks raise the pulse threshold and spend_pulse honors it.
	game.rules.reset()
	for i in range(3): game.rules.apply_upgrade("capacitor")
	check(is_equal_approx(game.rules.pulse_threshold(), 39.0), "capacitor Mk III threshold is 39 (got %s)" % game.rules.pulse_threshold())
	game.rules.energy = 35.0
	check(game.rules.spend_pulse() == 0.0 and is_equal_approx(game.rules.energy, 35.0), "pulse refuses below the raised threshold")

	# Prestige sink: repeatable purchase, rising cost, persists.
	game.settings.cores = 500
	game.buy_prestige()
	check(int(game.settings.prestige) == 1 and int(game.settings.cores) == 460, "prestige cell buys at base cost")
	check(game.prestige_cost() == 60, "prestige cost rises per cell (got %d)" % game.prestige_cost())
	check(int(Store.load_data().prestige) == 1, "prestige persists in the validated save")

	# Regression: overheal bank is not clipped by ordinary heals.
	game.rules.reset()
	game.rules.apply_upgrade("siphon"); game.rules.apply_upgrade("siphon")
	game.rules.health = 108.0
	game.rules.health = minf(game.rules.heal_ceiling(), game.rules.health + 20.0)
	check(is_equal_approx(game.rules.health, 110.0), "heals respect the siphon overheal ceiling (got %s)" % game.rules.health)
	game.rules.reset()
	check(is_equal_approx(game.rules.pulse_threshold(), 30.0), "base pulse threshold stays 30 without capacitor")

	Store.save_path = original_save
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	game.queue_free()
	await process_frame
	print("Reforge: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
