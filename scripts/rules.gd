extends RefCounted
## Pure combat state. Render and input code cannot bypass these resource limits.
## Reforge: every reactor upgrade has three marks. Marks scale the effect and
## its tradeoff; owning all three of a family grants a resonance bonus.

const MAX_MARK := 3
const FAMILIES := {
	"HARVEST": ["collector", "capacitor", "siphon"],
	"ECHO": ["echo", "radius", "chain"],
	"WAKE": ["wake", "frost", "ignite"]
}
const UPGRADE_DATA := {
	"collector": {"name": "WIDE RECEIVER", "family": "HARVEST", "icon": "◎",
		"description": "Absorb shots from twice as far away. Dash travels 15% less.",
		"marks": ["Absorb reach ×1.9. Dash 15% shorter.", "Absorb reach ×2.4 and stolen shots bend toward you mid-dash. Dash 20% shorter.", "Absorb reach ×3.0; harvesting also refunds a sliver of dash recharge. Dash 25% shorter."]},
	"capacitor": {"name": "HOT CAPACITOR", "family": "HARVEST", "icon": "ϟ",
		"description": "Each stolen shot gives 15 energy. Harvest up to 60 per dash.",
		"marks": ["15 energy per shot, 60 per dash. Pulse threshold +3 per Capacitor mark.", "18 energy per shot, 75 per dash. Pulse threshold +3 per Capacitor mark.", "22 energy per shot, 90 per dash. Dashing at a full battery vents 30 energy as a mini-pulse. Each Capacitor mark also raises the pulse threshold by 3."]},
	"siphon": {"name": "LIFE CIRCUIT", "family": "HARVEST", "icon": "+",
		"description": "Harvesting heals 2 hull per shot. Turn a close call into a comeback.",
		"marks": ["Heal 2 hull per stolen shot.", "Heal 3 hull per shot; overheal banks up to 10 spare hull.", "Heal 4 hull per shot; at full hull, healing becomes score and combo time."]},
	"echo": {"name": "AFTERSHOCK", "family": "ECHO", "icon": "≋",
		"description": "Your pulse repeats after 0.45s with the same radius and 45% damage.",
		"marks": ["Pulse repeats at 45% damage after 0.45s. The main blast deals 10% less.", "Repeats at 60% damage and knocks machines back.", "Two echoes: 60% then 35%, each centered on you."]},
	"radius": {"name": "HORIZON RING", "family": "ECHO", "icon": "◯",
		"description": "Pulse radius grows 35%. Catch an entire formation.",
		"marks": ["Pulse radius +35%, damage -5% (spread thinner).", "Pulse radius +55%, damage -10%. Enemies near the rim are pulled inward (not the Guardian).", "Pulse radius +80%, damage -15%. The rim lingers as a burning ring for 1.2s."]},
	"chain": {"name": "CHAIN REACTION", "family": "ECHO", "icon": "⋈",
		"description": "Pulse arcs jump to 4 extra targets outside the blast, dealing 70% damage.",
		"marks": ["Arcs jump to 4 extra targets at 70% damage. The main blast deals 5% less per Chain mark.", "6 jumps at 80% damage, preferring full-health targets.", "8 jumps at 90%; a jump that kills refunds 4 energy."]},
	"wake": {"name": "PLASMA WAKE", "family": "WAKE", "icon": "∿",
		"description": "Dashing leaves a 2-second trail that burns enemies crossing it.",
		"marks": ["Dash trail burns for 2s.", "Trail burns hotter and lasts 3s.", "Trail lasts 4s and your pulse ignites every live trail segment."]},
	"frost": {"name": "STATIC FIELD", "family": "WAKE", "icon": "✧",
		"description": "Dashing leaves a field that slows enemy movement by 50%.",
		"marks": ["Dash field slows enemies 50%.", "Slow 65% and slowed enemies take +15% weapon damage.", "Slow 75%; an enemy slowed for 1.5s shatters for bonus damage."]},
	"ignite": {"name": "FLARE DRIVE", "family": "WAKE", "icon": "△",
		"description": "Dash through enemies to deal 24 damage. Pulses deal 20% more.",
		"marks": ["Dash-through deals 24. Pulses +20%.", "Dash-through deals 36. Pulses +30%.", "Dash-through deals 50; a dash kill restores a dash charge. Pulses +40%."]}
}

var max_health := 100.0
var health := 100.0
var energy := 0.0
var max_dash_charges := 2
var dash_charges := 2
var dash_recharge := 0.0
var dash_recharge_time := 1.5
var dash_time := 0.0
var recovery := 0.0
var harvested_this_dash := 0.0
var upgrades: Array = []
var upgrade_levels: Dictionary = {}
var score := 0
var kills := 0
var absorbed := 0
var pulses := 0
var combo := 0
var combo_timer := 0.0
var combo_window := 3.0
var best_combo := 0
var harvest_bonus := 0.0
var score_bonus := 0.0

func reset() -> void:
	max_health = 100.0
	health = 100.0
	energy = 0.0
	max_dash_charges = 2
	dash_charges = 2
	dash_recharge = 0.0
	dash_recharge_time = 1.5
	dash_time = 0.0
	recovery = 0.0
	harvested_this_dash = 0.0
	upgrades.clear()
	upgrade_levels.clear()
	score = 0
	kills = 0
	absorbed = 0
	pulses = 0
	combo = 0
	combo_timer = 0.0
	combo_window = 3.0
	best_combo = 0
	harvest_bonus = 0.0
	score_bonus = 0.0

func level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))

func family_complete(family: String) -> bool:
	for id in FAMILIES.get(family, []):
		if level(id) <= 0: return false
	return true

func tick(delta: float) -> void:
	dash_time = maxf(0, dash_time - delta)
	recovery = maxf(0, recovery - delta)
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0: combo = 0
	var cap: int = max_dash_charges + (1 if family_complete("HARVEST") else 0)
	if dash_charges < cap:
		dash_recharge += delta
		while dash_recharge >= dash_recharge_time and dash_charges < cap:
			dash_recharge -= dash_recharge_time
			dash_charges += 1
		if dash_charges == cap:
			dash_recharge = 0

func try_dash() -> bool:
	if dash_charges <= 0 or dash_time > 0:
		return false
	dash_charges -= 1
	dash_time = 0.18
	harvested_this_dash = 0
	return true

func harvest(amount: float) -> float:
	if dash_time <= 0:
		return 0.0
	var cap_level: int = level("capacitor")
	var limit: float = [40.0, 60.0, 75.0, 90.0][cap_level]
	var gain := minf(amount + harvest_bonus, minf(100.0 - energy, limit - harvested_this_dash))
	gain = maxf(0, gain)
	energy += gain
	harvested_this_dash += gain
	absorbed += 1
	var siphon_level: int = level("siphon")
	if siphon_level > 0:
		var heal: float = [0.0, 2.0, 3.0, 4.0][siphon_level]
		var ceiling: float = heal_ceiling()
		if siphon_level >= 3 and health >= ceiling:
			score += 5
			combo_timer = minf(combo_window, combo_timer + 0.25)
		else:
			health = minf(ceiling, health + heal)
	if level("collector") >= 3:
		dash_recharge += 0.06
	return gain

func heal_ceiling() -> float:
	return max_health + (10.0 if level("siphon") >= 2 else 0.0)

func pulse_threshold() -> float:
	return 30.0 + 3.0 * float(level("capacitor"))

func spend_pulse() -> float:
	if energy < pulse_threshold():
		return 0
	var amount := energy
	energy = 0
	pulses += 1
	return amount

func damage(amount: float, ground_hazard: bool = false) -> bool:
	if health <= 0 or recovery > 0 or (dash_time > 0 and not ground_hazard):
		return false
	health = maxf(0, health - amount)
	recovery = 0.75
	combo = 0
	combo_timer = 0.0
	return true

func combo_multiplier() -> float:
	return 1.0 + float(mini(combo, 30)) * 0.04

func register_kill(value: int) -> void:
	kills += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	combo_timer = combo_window * (1.25 if family_complete("WAKE") else 1.0)
	score += int(round(float(value) * combo_multiplier() * (1.0 + score_bonus)))
	energy = minf(100, energy + 5)

func apply_upgrade(id: String) -> void:
	if not UPGRADE_DATA.has(id):
		return
	var current: int = level(id)
	if current >= MAX_MARK:
		return
	upgrade_levels[id] = current + 1
	if current == 0:
		upgrades.append(id)

func upgrade_options(rng: RandomNumberGenerator) -> Array:
	var fresh: Array = []
	var raiseable: Array = []
	for id in UPGRADE_DATA:
		if level(id) == 0: fresh.append(id)
		elif level(id) < MAX_MARK: raiseable.append(id)
	var options: Array = []
	# Always lead with something new while new systems remain; then mix in a
	# mark-up so long runs keep making real build decisions (27 total picks).
	if not fresh.is_empty():
		options.append(fresh.pop_at(rng.randi_range(0, fresh.size() - 1)))
	if not raiseable.is_empty() and options.size() < 3:
		options.append(raiseable.pop_at(rng.randi_range(0, raiseable.size() - 1)))
	var rest: Array = fresh + raiseable
	while options.size() < 3 and not rest.is_empty():
		options.append(rest.pop_at(rng.randi_range(0, rest.size() - 1)))
	return options
