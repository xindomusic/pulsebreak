extends RefCounted
## Pure combat state. Render and input code cannot bypass these resource limits.

const UPGRADE_DATA := {
	"collector": {"name": "WIDE RECEIVER", "family": "HARVEST", "description": "Absorb shots from twice as far away. Dash travels 15% less.", "icon": "◎"},
	"capacitor": {"name": "HOT CAPACITOR", "family": "HARVEST", "description": "Each stolen shot gives 15 energy. Harvest up to 60 per dash.", "icon": "ϟ"},
	"siphon": {"name": "LIFE CIRCUIT", "family": "HARVEST", "description": "Harvesting heals 2 hull per shot. Turn a close call into a comeback.", "icon": "+"},
	"echo": {"name": "AFTERSHOCK", "family": "ECHO", "description": "Your pulse repeats after 0.45s with the same radius and 45% damage.", "icon": "≋"},
	"radius": {"name": "HORIZON RING", "family": "ECHO", "description": "Pulse radius grows 35%. Catch an entire formation.", "icon": "◯"},
	"chain": {"name": "CHAIN REACTION", "family": "ECHO", "description": "Pulse arcs jump to 4 extra targets outside the blast, dealing 70% damage.", "icon": "⋈"},
	"wake": {"name": "PLASMA WAKE", "family": "WAKE", "description": "Dashing leaves a 2-second trail that burns enemies crossing it.", "icon": "∿"},
	"frost": {"name": "STATIC FIELD", "family": "WAKE", "description": "Dashing leaves a field that slows enemy movement by 50%.", "icon": "✧"},
	"ignite": {"name": "FLARE DRIVE", "family": "WAKE", "description": "Dash through enemies to deal 24 damage. Pulses deal 20% more.", "icon": "△"}
}

var health := 100.0
var energy := 0.0
var dash_charges := 2
var dash_recharge := 0.0
var dash_time := 0.0
var recovery := 0.0
var harvested_this_dash := 0.0
var upgrades: Array = []
var score := 0
var kills := 0
var absorbed := 0
var pulses := 0

func reset() -> void:
	health = 100.0
	energy = 0.0
	dash_charges = 2
	dash_recharge = 0.0
	dash_time = 0.0
	recovery = 0.0
	harvested_this_dash = 0.0
	upgrades.clear()
	score = 0
	kills = 0
	absorbed = 0
	pulses = 0

func tick(delta: float) -> void:
	dash_time = maxf(0, dash_time - delta)
	recovery = maxf(0, recovery - delta)
	if dash_charges < 2:
		dash_recharge += delta
		while dash_recharge >= 1.5 and dash_charges < 2:
			dash_recharge -= 1.5
			dash_charges += 1
		if dash_charges == 2:
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
	var limit := 60.0 if upgrades.has("capacitor") else 40.0
	var gain := minf(amount, minf(100.0 - energy, limit - harvested_this_dash))
	gain = maxf(0, gain)
	energy += gain
	harvested_this_dash += gain
	absorbed += 1
	if upgrades.has("siphon"):
		health = minf(100.0, health + 2.0)
	return gain

func spend_pulse() -> float:
	if energy < 30:
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
	return true

func register_kill(value: int) -> void:
	kills += 1
	score += value
	energy = minf(100, energy + 5)

func apply_upgrade(id: String) -> void:
	if UPGRADE_DATA.has(id) and not upgrades.has(id):
		upgrades.append(id)

func upgrade_options(rng: RandomNumberGenerator) -> Array:
	var available: Array = []
	for id in UPGRADE_DATA:
		if not upgrades.has(id): available.append(id)
	var options: Array = []
	while options.size() < 3 and not available.is_empty():
		var index := rng.randi_range(0, available.size() - 1)
		options.append(available[index])
		available.remove_at(index)
	return options
