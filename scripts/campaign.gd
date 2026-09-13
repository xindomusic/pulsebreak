extends Node3D
## Three authored flight lessons followed by endlessly generated, seeded routes.
const Visuals = preload("res://scripts/showcase_art.gd")
const Generator = preload("res://scripts/level_generator.gd")
const SECTORS = Generator.ONBOARDING
var game: Node3D
var sector := 0
var theme_index := 0
var run_seed := 1337
var current_stage: Dictionary = {}
var elapsed := 0.0
var relays := 0
var total_relays := 0
var start_kills := 0
var gate_open := false
var exit_openness := 0.0
var completed := false
var boss_started := false
var boss_defeated := false
var stage: Node3D
var target: Node3D
var exit_gate: Node3D
var gates: Array = []
var spawn_clock := 2.4
var wave := 0
var hazard_clock := 0.0
var hazard_waves := 0
var feedback_clock := 0.0
var checkpoint_times: Array = []

func start(seed: int = 1337) -> void:
	run_seed = seed
	total_relays = 0
	checkpoint_times.clear()
	enter_sector(0)

func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	gates.clear()
	stage = null
	target = null
	exit_gate = null

func enter_sector(index: int) -> void:
	clear()
	sector = maxi(0,index)
	current_stage = Generator.generate(run_seed,sector)
	theme_index = int(current_stage.theme)
	elapsed = 0
	relays = 0
	start_kills = game.rules.kills
	gate_open = false
	exit_openness = 0
	completed = false
	boss_started = false
	boss_defeated = false
	spawn_clock = float(current_stage.spawn_grace)
	wave = 0
	hazard_clock = float(current_stage.hazard_grace)
	hazard_waves = 0
	feedback_clock = 0
	stage = Visuals.build_stage(self,theme_index)
	if current_stage.generated: Visuals.apply_generated_dressing(stage,current_stage)
	exit_gate = Visuals.gate()
	add_child(exit_gate)
	exit_gate.position = Vector3(0,0,-12.5)
	Visuals.animate_gate(exit_gate,0,0)
	for spec in current_stage.gates:
		var gate := Visuals.gate("TIMED SHUTTER / JUMP OR WAIT" if sector==0 else "SHUTTER","OPEN")
		if sector>0:
			var status: Label3D = gate.get_meta("status")
			status.font_size = 30
			status.position = Vector3(-5.2,3.0,0.52)
		add_child(gate)
		gate.position = spec.position
		gates.append({"node":gate,"open":0.0,"previous_open":0.0,"phase":spec.phase,"speed":spec.speed,"bias":spec.bias,"swing":spec.swing})
	create_target()
	game.player_node.position = Vector3(0,0,10)
	game.player_previous = game.player_position
	game.traversal.reset()
	game.player_velocity = Vector3.ZERO
	game.rules.dash_time = 0
	game.rules.recovery = 2.0
	game.camera.size = 31.8
	game.set_sector_lighting(theme_index)
	game.announce("%02d  /  %s" % [sector+1,current_stage.name],current_stage.subtitle)
	if current_stage.generated:
		game.ui.show_hint("%s  /  %s  ·  %d AERIAL RELAYS" % [route_name(),current_stage.modifier.label,relay_goal()],9)
	else:
		game.ui.show_hint("%s: jump. Hold in the air to glide. Fly through the cyan relay." % game.key_name("jump"),9)

func route_name() -> String:
	return str(current_stage.get("route","FIRST FLIGHT"))

func relay_goal() -> int:
	return int(current_stage.get("relay_goal",3))

func record_checkpoint(time: float) -> void:
	if checkpoint_times.size() >= Generator.HISTORY_LIMIT: checkpoint_times.pop_front()
	checkpoint_times.append(time)

func mark_guardian_defeated() -> void:
	# The game may offer extraction/continuation immediately, or let the player
	# walk into this now-open exit. Either route preserves the same run seed.
	boss_defeated = true
	gate_open = true

func create_target() -> void:
	if is_instance_valid(target):
		remove_child(target)
		target.queue_free()
		target = null
	if relays >= relay_goal(): return
	target = Visuals.target_ring()
	add_child(target)
	target.position = current_stage.targets[relays]
	var number := Label3D.new()
	number.name = "RelayLabel"
	number.position.y = 1.65
	number.font_size = 52
	number.pixel_size = 0.011
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.modulate = Color("aaffee")
	target.add_child(number)
	refresh_target_label()

func refresh_target_label() -> void:
	if not is_instance_valid(target): return
	var label: Label3D = target.get_node("RelayLabel")
	label.text = "%02d  /  GLIDE\nHOLD %s" % [relays+1,game.key_name("jump")] if requires_glide() else "%02d" % (relays+1)
	label.modulate = Color("ffd18a") if requires_glide() else Color("aaffee")
	label.font_size = 40 if requires_glide() else 52

func objective() -> String:
	if boss_started and not boss_defeated: return "GUARDIAN LOCK  /  BREAK THE GUARDIAN"
	if boss_defeated: return "GUARDIAN DOWN  /  EXTRACT OR DIVE DEEPER"
	if relays < relay_goal():
		return "%s RELAY %d / %d  ·  %s" % ["GLIDE THROUGH" if requires_glide() else "JUMP THROUGH",relays+1,relay_goal(),"HOLD " + game.key_name("jump") + " IN AIR" if requires_glide() else game.key_name("jump") + " JUMP / HOLD TO GLIDE"]
	var remaining := maxi(0,int(current_stage.kills)-(game.rules.kills-start_kills))
	if remaining > 0: return "CLEAR THE DECK  /  %d MACHINES REMAIN  ·  DASH → PULSE" % remaining
	return "SECTOR SECURED  /  ENTER THE NORTH GATE ↑"

func requires_glide() -> bool:
	return relays in current_stage.get("glide_relays",[])

func update(delta: float) -> void:
	elapsed += delta
	feedback_clock = maxf(0,feedback_clock-delta)
	Visuals.animate_stage(stage,delta,elapsed)
	for gate in gates:
		gate.previous_open = gate.open
		# Long open windows let players time a walk, dash, or jump over the low doors.
		gate.open = 1.0 if boss_started else clampf(float(gate.bias)+sin(elapsed*float(gate.speed)+float(gate.phase))*float(gate.swing),0,1)
		Visuals.animate_gate(gate.node,gate.open,elapsed)
	if is_instance_valid(target):
		Visuals.animate_target(target,elapsed)
		if target_crossed(game.player_previous,game.player_position) and requires_glide() and not game.traversal.gliding and feedback_clock<=0:
			game.ui.show_hint("HOLD %s AS YOU FALL TO UNFOLD YOUR WINGS. GLIDE THROUGH THIS RELAY." % game.key_name("jump"),4.0)
			feedback_clock = 3.0
		if target_crossed(game.player_previous,game.player_position) and (not requires_glide() or game.traversal.gliding):
			relays += 1
			total_relays += 1
			game.rules.energy = minf(100,game.rules.energy+18)
			game.rules.health = minf(100,game.rules.health+8)
			game.rules.score += 300
			game.add_effect(target.position,Color("76f7df"),2.2)
			game.cue("core")
			game.ui.show_hint("RELAY %d / %d  ·  +18 CHARGE  +8 HULL" % [relays,relay_goal()],2.5)
			create_target()
	if completed: return
	if relays >= relay_goal() and current_stage.boss and not boss_started:
		boss_started = true
		game.begin_campaign_boss()
	if not boss_started:
		update_route_hazards(delta)
		spawn_clock -= delta
		if spawn_clock <= 0 and not gate_open:
			spawn_clock = float(current_stage.spawn_interval)
			var angles := [0.25,2.5,4.2,5.5,1.3,3.4]
			var angle: float = angles[wave%angles.size()]
			var at := Vector3(cos(angle)*12.8,0,sin(angle)*12.8)
			var kind := "gunner" if wave%3==0 or sector==0 and wave<3 else "charger"
			if sector>0 and wave%4==3: kind="bruiser"
			if current_stage.generated: kind=current_stage.enemy_order[wave%current_stage.enemy_order.size()]
			if game.enemies.size()<int(current_stage.enemy_cap): game.spawn_enemy(kind,at)
			wave += 1
		if relays >= relay_goal() and game.rules.kills-start_kills >= int(current_stage.kills) and not current_stage.boss:
			if not gate_open:
				gate_open = true
				game.announce("ROUTE UNLOCKED", "Enter the north gate for your next sector.")
				game.cue("upgrade")
	exit_openness = move_toward(exit_openness,1.0 if gate_open else 0.0,delta*0.8)
	Visuals.animate_gate(exit_gate,exit_openness,elapsed)
	if gate_open and exit_openness>0.8 and absf(game.player_position.x)<2.3 and game.player_position.z < -12.6:
		completed = true
		record_checkpoint(game.run_time)
		game.complete_sector()

func update_route_hazards(delta: float) -> void:
	if int(current_stage.hazard_count)==0 or relays==0 or gate_open or completed or boss_started: return
	hazard_clock-=delta
	if hazard_clock>0: return
	hazard_clock=float(current_stage.hazard_interval)
	hazard_waves+=1
	# Authored pads leave the central lane open. Their red warnings last >=1.35s.
	if current_stage.generated:
		var sites: Array = current_stage.hazard_sites
		for offset in range(int(current_stage.hazard_count)):
			var site: int = ((hazard_waves-1)*int(current_stage.hazard_count)+int(current_stage.hazard_phase)+offset)%sites.size()
			game.add_hazard(sites[site],float(current_stage.hazard_radius),float(current_stage.hazard_warning)+float(offset)*0.25)
	else:
		var side := -1.0 if hazard_waves%2 else 1.0
		game.add_hazard(Vector3(side*6,0,-2 if sector==1 else -3),3.0 if sector==1 else 2.6,1.35)
		if sector==2: game.add_hazard(Vector3(-side*6,0,3),2.6,1.6)
	game.ui.show_hint("SHOCK PADS  /  JUMP THE RED RINGS OR USE THE CLEAR CENTER LANE.",3.0)
	game.cue("warning",0.6)

func target_crossed(from: Vector3, to: Vector3) -> bool:
	if not is_instance_valid(target): return false
	# Compare a swept chest center with the ring center. Grounded walking is excluded.
	var chest_from := from+Vector3(0,0.9,0)
	var chest_to := to+Vector3(0,0.9,0)
	var nearest := Geometry3D.get_closest_point_to_segment(target.position,chest_from,chest_to)
	return nearest.y>1.9 and nearest.distance_to(target.position)<1.05

func resolve_gates(from: Vector3, to: Vector3) -> Vector3:
	var result := to
	for gate in gates:
		result = block_gate(from,result,gate.node.position,minf(gate.open,gate.previous_open))
	if is_instance_valid(exit_gate): result = block_gate(from,result,exit_gate.position,exit_openness)
	return result

static func block_gate(from: Vector3, to: Vector3, at: Vector3, openness: float) -> Vector3:
	var result := to
	var start := from-at
	var end := to-at
	for side in [-1.0,1.0]:
		var center: float = side*(2.5+5.0*openness)
		var low := Vector2(center-2.92,-0.67)
		var high := Vector2(center+2.92,0.67)
		var entry := 0.0
		var leave := 1.0
		for axis in [0,2]:
			var a: float = start[axis]
			var d: float = end[axis]-a
			var lower: float = low.x if axis==0 else low.y
			var upper: float = high.x if axis==0 else high.y
			if absf(d)<0.00001:
				if a<lower or a>upper: entry=2.0
			else:
				var first := (lower-a)/d
				var last := (upper-a)/d
				entry=maxf(entry,minf(first,last))
				leave=minf(leave,maxf(first,last))
		if entry<=leave and entry<=1 and lerpf(start.y,end.y,entry)<1.85:
			result.z=at.z+(-0.7 if start.z<0 else 0.7)
	return result
