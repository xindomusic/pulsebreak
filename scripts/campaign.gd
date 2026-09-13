extends Node3D
## Authored three-sector heist. Objective progress is spatial, never a timer skip.
const Visuals = preload("res://scripts/showcase_art.gd")
const SECTORS := [
	{"name":"SKYPORT", "subtitle":"Take the high road.", "color":Color("76f7df"), "kills":4,
	 "targets":[Vector3(0,2.6,4),Vector3(-7,2.6,-1),Vector3(5,2.6,-7)]},
	{"name":"SOLAR FOUNDRY", "subtitle":"Ride the current. Thread the shutters.", "color":Color("ffd18a"), "kills":8,
	 "targets":[Vector3(-7,2.6,4),Vector3(6,2.6,-1),Vector3(-5,2.6,-8)]},
	{"name":"STORM CORE", "subtitle":"Cut the locks. Steal the storm.", "color":Color("bfa3ff"), "kills":0,
	 "targets":[Vector3(6,2.6,3),Vector3(-6,2.6,-3),Vector3(0,2.6,-9)]}
]
var game: Node3D
var sector := 0
var elapsed := 0.0
var relays := 0
var total_relays := 0
var start_kills := 0
var gate_open := false
var exit_openness := 0.0
var completed := false
var boss_started := false
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

func start() -> void:
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
	sector = clampi(index,0,2)
	elapsed = 0
	relays = 0
	start_kills = game.rules.kills
	gate_open = false
	exit_openness = 0
	completed = false
	boss_started = false
	spawn_clock = 6.0 if sector == 0 else 2.5
	wave = 0
	hazard_clock = 5.5 if sector==1 else 1.6
	hazard_waves = 0
	feedback_clock = 0
	stage = Visuals.build_stage(self,sector)
	exit_gate = Visuals.gate()
	add_child(exit_gate)
	exit_gate.position = Vector3(0,0,-12.5)
	Visuals.animate_gate(exit_gate,0,0)
	for at in ([Vector3(0,0,-3.7)] if sector == 0 else [Vector3(-3,0,1),Vector3(3,0,-5)]):
		var gate := Visuals.gate("TIMED SHUTTER / JUMP OR WAIT","SHUTTER OPEN")
		add_child(gate)
		gate.position = at
		gates.append({"node":gate,"open":0.0,"previous_open":0.0,"phase":float(gates.size())*PI})
	create_target()
	game.player_node.position = Vector3(0,0,10)
	game.player_previous = game.player_position
	game.traversal.reset()
	game.player_velocity = Vector3.ZERO
	game.rules.dash_time = 0
	game.rules.recovery = 2.0
	game.camera.size = 31.8
	game.set_sector_lighting(sector)
	game.announce("0%d  /  %s" % [sector+1,SECTORS[sector].name],SECTORS[sector].subtitle)
	game.ui.show_hint("%s: jump. Hold in the air to glide. Fly through the cyan relay." % game.key_name("jump"),9)

func create_target() -> void:
	if is_instance_valid(target):
		remove_child(target)
		target.queue_free()
		target = null
	if relays >= 3: return
	target = Visuals.target_ring()
	add_child(target)
	target.position = SECTORS[sector].targets[relays]
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
	if boss_started: return "FINAL OBJECTIVE  /  BREAK THE GUARDIAN"
	if relays < 3:
		return "%s RELAY %d / 3  ·  %s" % ["GLIDE THROUGH" if requires_glide() else "JUMP THROUGH",relays+1,"HOLD " + game.key_name("jump") + " IN AIR" if requires_glide() else game.key_name("jump") + " JUMP / HOLD TO GLIDE"]
	var remaining := maxi(0,int(SECTORS[sector].kills)-(game.rules.kills-start_kills))
	if remaining > 0: return "CLEAR THE DECK  /  %d MACHINES REMAIN  ·  DASH → PULSE" % remaining
	return "SECTOR SECURED  /  ENTER THE NORTH GATE ↑"

func requires_glide() -> bool:
	return sector == 1 and relays == 1

func update(delta: float) -> void:
	elapsed += delta
	feedback_clock = maxf(0,feedback_clock-delta)
	Visuals.animate_stage(stage,delta,elapsed)
	for gate in gates:
		gate.previous_open = gate.open
		# Long open windows let players time a walk, dash, or jump over the low doors.
		gate.open = 1.0 if boss_started else clampf(0.45+sin(elapsed*(0.75+sector*0.14)+gate.phase)*0.8,0,1)
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
			game.ui.show_hint("RELAY %d / 3  ·  +18 CHARGE  +8 HULL" % relays,2.5)
			create_target()
	if completed: return
	if relays == 3 and sector == 2 and not boss_started:
		boss_started = true
		game.begin_campaign_boss()
	if not boss_started:
		update_route_hazards(delta)
		spawn_clock -= delta
		if spawn_clock <= 0 and not gate_open:
			spawn_clock = 3.7-sector*0.5
			var angles := [0.25,2.5,4.2,5.5,1.3,3.4]
			var angle: float = angles[wave%angles.size()]
			var at := Vector3(cos(angle)*12.8,0,sin(angle)*12.8)
			var kind := "gunner" if wave%3==0 or sector==0 and wave<3 else "charger"
			if sector>0 and wave%4==3: kind="bruiser"
			if game.enemies.size()<12+sector*3: game.spawn_enemy(kind,at)
			wave += 1
		if relays >= 3 and game.rules.kills-start_kills >= int(SECTORS[sector].kills) and sector < 2:
			if not gate_open:
				gate_open = true
				game.announce("ROUTE UNLOCKED", "Enter the north gate for your next sector.")
				game.cue("upgrade")
		exit_openness = move_toward(exit_openness,1.0 if gate_open else 0.0,delta*0.8)
		Visuals.animate_gate(exit_gate,exit_openness,elapsed)
		if gate_open and exit_openness>0.8 and absf(game.player_position.x)<2.3 and game.player_position.z < -12.6:
			completed = true
			checkpoint_times.append(game.run_time)
			game.complete_sector()

func update_route_hazards(delta: float) -> void:
	if sector==0 or relays==0 or gate_open or completed or boss_started: return
	hazard_clock-=delta
	if hazard_clock>0: return
	hazard_clock=7.0
	hazard_waves+=1
	# Authored pads leave the central lane open. Their red warnings last >=1.35s.
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
