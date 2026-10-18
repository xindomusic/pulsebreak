extends SceneTree

var count := 0
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)
	count += 1

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/rules.gd"):
		push_error("FAIL: combat rules are not implemented")
		quit(1)
		return
	var r = load("res://scripts/rules.gd").new()
	check(r.try_dash(), "first dash")
	r.dash_time = 0
	check(r.try_dash(), "second dash")
	r.dash_time = 0
	check(not r.try_dash(), "third dash rejected")
	r.tick(1.5)
	check(r.dash_charges == 1, "sequential recharge")
	check(r.try_dash(), "recharged dash")
	for i in range(8): r.harvest(10)
	check(r.energy == 40, "per dash harvesting cap")
	r.energy = 99
	r.harvested_this_dash = 0
	r.harvest(10)
	check(r.energy == 100, "total energy cap")
	r.energy = 29
	check(r.spend_pulse() == 0 and r.energy == 29, "pulse threshold preserves energy")
	r.energy = 100
	check(r.spend_pulse() == 100 and r.energy == 0, "pulse spends exact charge")
	r.reset()
	check(r.damage(20), "first hit lands")
	check(not r.damage(20), "overlap recovery protects")
	check(r.health == 80, "no duplicate damage")
	r.tick(1.0)
	check(r.damage(20), "recovery expires")
	r.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(5):
		var options: Array = r.upgrade_options(rng)
		check(options.size() == 3, "three upgrade offers")
		check(not r.upgrades.has(options[0]), "first offer is always a new system while new systems remain")
		check(options.count(options[0]) == 1, "offers never repeat a card")
		r.apply_upgrade(options[0])
	check(r.upgrades.size() == 5, "five distinct upgrades")
	# Marks: raising one system three times caps at Mk III without duplicating it.
	r.reset()
	for i in range(4): r.apply_upgrade("echo")
	check(r.level("echo") == 3 and r.upgrades.size() == 1, "marks cap at three on one distinct upgrade")
	for id in r.UPGRADE_DATA:
		for i in range(3): r.apply_upgrade(id)
	check(r.upgrade_options(rng).is_empty(), "27 total picks exhaust the reactor pool")
	check(r.family_complete("ECHO") and r.family_complete("HARVEST"), "family resonance detects complete families")
	# Combo: kills build a decaying score multiplier; damage breaks it.
	r.reset()
	r.register_kill(100); r.register_kill(100)
	check(r.combo == 2 and r.score > 200, "combo multiplies kill score")
	r.tick(10.0)
	check(r.combo == 0, "combo decays after its window")
	r.reset()
	check(r.upgrades.is_empty() and r.health == 100 and r.dash_charges == 2, "restart reset")
	print("Combat rules: %d checks, %d failures" % [count, failures])
	quit(1 if failures else 0)
