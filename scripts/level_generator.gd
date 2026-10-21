extends RefCounted
## Seeded route grammar: authored safe lanes, bounded variations and explicit rules.
## Every relay can be reached using the base jump/glide, with recharge space below.

const VERSION := 2
const MAX_ENEMIES := 18
const MAX_KILLS := 14
const MAX_GATES := 3
const MIN_WARNING := 1.35
const HISTORY_LIMIT := 32
const THEMES := [
	{"name":"SKYPORT","color":Color("c3d5e0")},
	{"name":"SOLAR FOUNDRY","color":Color("e0a458")},
	{"name":"TEMPEST CORE","color":Color("8fb0c9")}
]
const ONBOARDING := [
	{"name":"SKYPORT", "subtitle":"Take the high road.", "color":Color("c3d5e0"), "kills":4,
	 "targets":[Vector3(0,2.6,4),Vector3(-7,2.6,-1),Vector3(5,2.6,-7)]},
	{"name":"SOLAR FOUNDRY", "subtitle":"Ride the current. Thread the shutters.", "color":Color("ffd18a"), "kills":8,
	 "targets":[Vector3(-7,2.6,4),Vector3(6,2.6,-1),Vector3(-5,2.6,-8)]},
	{"name":"TEMPEST CORE", "subtitle":"Cut the locks. Steal the storm.", "color":Color("8fb0c9"), "kills":0,
	 "targets":[Vector3(6,2.6,3),Vector3(-6,2.6,-3),Vector3(0,2.6,-9)]}
]
const ROUTES := [
	{"name":"SWITCHBACK","xs":[-6.0,6.0,-5.0]},
	{"name":"OUTER CIRCUIT","xs":[6.5,6.0,-4.5]},
	{"name":"CENTER WEAVE","xs":[0.0,-6.0,0.0]},
	{"name":"CROSS CURRENT","xs":[-5.5,0.0,6.0]},
	{"name":"TWIN SPURS","xs":[6.0,-6.0,5.0]},
	{"name":"DIRECT APPROACH","xs":[-1.5,1.5,-1.5]},
	{"name":"NORTH RIDGE","xs":[-7.0,7.0,0.0]},
	{"name":"PINBALL","xs":[7.0,-7.0,7.0]},
	{"name":"LOW SLALOM","xs":[-3.5,3.5,-3.5]}
]
const MODIFIERS := [
	{"id":"long_windows","label":"LONG WINDOWS","description":"Shutters stay open longer. Use the clear lanes."},
	{"id":"synchronized","label":"SYNCHRONIZED GATES","description":"Shutters share a beat. Cross together or take flight."},
	{"id":"surge","label":"REINFORCEMENT SURGE","description":"Machines arrive faster. Keep moving between relays."},
	{"id":"shock_pairs","label":"PAIRED SHOCK PADS","description":"Two side lanes pulse together. The center remains clear."},
	{"id":"flight_test","label":"FLIGHT CIRCUIT","description":"Two relays require deployed wings. Land between flights."}
]

static func generate(run_seed: int, stage_index: int) -> Dictionary:
	var index := maxi(0,stage_index)
	var theme := index%3
	var rng := RandomNumberGenerator.new()
	# String hashing avoids overflow when a long-running campaign reaches a
	# very large stage number, and doesn't consume the combat RNG's sequence.
	var layout_seed := ("pulsebreak:%d:%d:%d" % [VERSION,run_seed,index]).hash()
	rng.seed = layout_seed
	if index < ONBOARDING.size():
		return onboarding_stage(index,run_seed,layout_seed)
	# Coprime index cycles make repeats impossible in any short window while
	# staying a pure O(1) function of (run seed, absolute stage): the route
	# cannot repeat for 9 stages, the modifier for 5, so consecutive sectors
	# always differ in route, modifier and theme rotation combined.
	var cycle_rng := RandomNumberGenerator.new()
	cycle_rng.seed = ("pulsebreak-v2-cycle:%d" % run_seed).hash()
	var route: Dictionary = ROUTES[(cycle_rng.randi_range(0,ROUTES.size()-1) + index*4) % ROUTES.size()]
	var modifier_index := (cycle_rng.randi_range(0,MODIFIERS.size()-1) + index*2) % MODIFIERS.size()
	var modifier: Dictionary = MODIFIERS[modifier_index].duplicate(true)
	var second_id := ""
	if index >= 7:
		second_id = str(MODIFIERS[(modifier_index+2) % MODIFIERS.size()].id)
		modifier["second_id"] = second_id
		modifier.label = "%s + %s" % [modifier.label, MODIFIERS[(modifier_index+2) % MODIFIERS.size()].label]
	var mirror := -1.0 if rng.randi_range(0,1)==0 else 1.0
	var relay_count := 4 if index>=6 and rng.randi_range(0,2)==0 else 3
	var targets: Array[Vector3] = []
	for relay in range(relay_count):
		var route_x: float = float(route.xs[relay]) if relay<3 else -float(route.xs[0])*0.7
		var x: float = clampf(route_x*mirror+rng.randf_range(-1.1,1.1),-7.5,7.5)
		var z: float = (4.0-float(relay)*6.0 if relay_count==3 else 5.2-float(relay)*4.2)+rng.randf_range(-0.2,0.2)
		targets.append(Vector3(x,2.6,z))
	var pressure := mini(index-2,12)
	var gate_count := rng.randi_range(1,MAX_GATES)
	var gate_rows: Array = [1.0,-5.0,7.0] if relay_count==3 else [3.1,-1.1,-5.3]
	var gate_specs: Array[Dictionary] = []
	var shared_speed := rng.randf_range(0.66,0.94)
	var shared_swing := rng.randf_range(0.72,0.88)
	var shared_bias := 0.68 if modifier.id=="long_windows" or second_id=="long_windows" else rng.randf_range(0.40,0.50)
	for gate_index in range(gate_count):
		var phase: float = float(gate_index)*PI+rng.randf_range(-0.25,0.25)
		if modifier.id=="synchronized" or second_id=="synchronized": phase=0.0
		gate_specs.append({"position":Vector3(rng.randf_range(-2.5,2.5),0,gate_rows[gate_index]),
			"phase":phase,"speed":shared_speed if modifier.id=="synchronized" or second_id=="synchronized" else rng.randf_range(0.66,0.94),
			"bias":shared_bias,"swing":shared_swing if modifier.id=="synchronized" or second_id=="synchronized" else rng.randf_range(0.72,0.88)})
	var glide_relays: Array[int] = [rng.randi_range(0,relay_count-1)]
	if modifier.id=="flight_test" or second_id=="flight_test":
		if relay_count > 2:
			glide_relays = [0, 2]
		else:
			glide_relays = [0]
	var interval := maxf(1.9,3.4-float(pressure)*0.10)
	if modifier.id=="surge" or second_id=="surge": interval=maxf(1.8,interval*0.84)
	var hazard_interval := maxf(4.8,7.5-float(pressure)*0.14)
	var paired: bool = modifier.id=="shock_pairs" or second_id=="shock_pairs" or theme==2
	var hazard_sets: Array = [
		[Vector3(-6,0,-2),Vector3(6,0,-2),Vector3(-6,0,4),Vector3(6,0,4)],
		[Vector3(6,0,-4),Vector3(-6,0,-4),Vector3(6,0,2),Vector3(-6,0,2)],
		[Vector3(-6,0,-6),Vector3(6,0,0),Vector3(-6,0,6),Vector3(6,0,-6)],
		[Vector3(6,0,6),Vector3(-6,0,-6),Vector3(6,0,-1),Vector3(-6,0,5)]]
	var hazard_sites: Array[Vector3] = []
	hazard_sites.assign(hazard_sets[rng.randi_range(0,hazard_sets.size()-1)])
	return {
		"index":index,"theme":theme,"seed":run_seed,"layout_seed":layout_seed,"generated":true,
		"name":THEMES[theme].name,"color":THEMES[theme].color,"route":route.name,
		"subtitle":modifier.description + ("" if second_id.is_empty() else " Also: " + str(MODIFIERS[(modifier_index+2) % MODIFIERS.size()].description).split(".")[0] + "."),"modifier":modifier,"targets":targets,"relay_goal":relay_count,"glide_relays":glide_relays,
		"gates":gate_specs,"boss":index%3==2,"kills":0 if index%3==2 else mini(MAX_KILLS,6+pressure),
		"spawn_interval":interval,"spawn_grace":5.0,"enemy_cap":mini(MAX_ENEMIES,12+pressure/2),
		"enemy_order":[["gunner","charger","splitter","bruiser","gunner","charger"],["charger","splitter","gunner","charger","bruiser"],["splitter","gunner","bruiser","charger","splitter"],["gunner","bruiser","charger","gunner","splitter","charger"]][rng.randi_range(0,3)] if theme!=0 else ["gunner","charger","gunner","bruiser"],
		"hazard_interval":hazard_interval,"hazard_grace":4.5,"hazard_warning":rng.randf_range(1.4,1.75),
		"hazard_radius":2.6 if paired else 3.0,"hazard_count":2 if paired else 1,"hazard_sites":hazard_sites,
		"hazard_phase":rng.randi_range(0,3)
	}

static func onboarding_stage(index: int, run_seed: int, layout_seed: int) -> Dictionary:
	var data: Dictionary = ONBOARDING[index].duplicate(true)
	var gate_specs: Array[Dictionary] = []
	var positions: Array = [Vector3(0,0,-3.7)] if index==0 else [Vector3(-3,0,1),Vector3(3,0,-5)]
	for at in positions:
		gate_specs.append({"position":at,"phase":float(gate_specs.size())*PI,"speed":0.75+float(index)*0.14,"bias":0.45,"swing":0.8})
	data.merge({
		"index":index,"theme":index,"seed":run_seed,"layout_seed":layout_seed,"generated":false,
		"route":["FIRST FLIGHT","FOUNDRY CROSSING","GUARDIAN APPROACH"][index],
		"modifier":{"id":"onboarding","label":"FIRST FLIGHT" if index==0 else "FLIGHT LESSON" if index==1 else "GUARDIAN LOCKS","description":data.subtitle},
		"gates":gate_specs,"boss":index==2,"relay_goal":3,"glide_relays":[1] if index==1 else [],
		"spawn_interval":3.7-float(index)*0.5,"spawn_grace":6.0 if index==0 else 2.5,"enemy_cap":12+index*3,
		"enemy_order":["gunner","charger","charger","bruiser","charger","charger"],
		"hazard_interval":7.0,"hazard_grace":5.5 if index==1 else 1.6,"hazard_warning":MIN_WARNING,
		"hazard_radius":3.0 if index==1 else 2.6,"hazard_count":0 if index==0 else 1 if index==1 else 2,
		"hazard_sites":[Vector3(-6,0,-2 if index==1 else -3),Vector3(6,0,-2 if index==1 else -3),Vector3(6,0,3),Vector3(-6,0,3)],"hazard_phase":0
	})
	return data
