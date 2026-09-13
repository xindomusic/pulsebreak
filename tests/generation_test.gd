extends SceneTree
## Verify generated route constraints across sampled seeds and stage indices.
const Generator = preload("res://scripts/level_generator.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Traversal = preload("res://scripts/traversal.gd")
var checks := 0
var failures := 0
var layouts_checked := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+description)

func _initialize() -> void:
	call_deferred("run_checks")

func gate_open(spec: Dictionary, time: float) -> float:
	return clampf(float(spec.bias)+sin(time*float(spec.speed)+float(spec.phase))*float(spec.swing),0.0,1.0)

func instance_transforms(node: MultiMeshInstance3D) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	if DisplayServer.get_name()=="headless":
		# The dummy renderer reads every instance as identity. Use the exact
		# inputs retained by generated paint batches; native runs use readback.
		if node.has_meta("paint_transforms"): transforms.assign(node.get_meta("paint_transforms"))
	else:
		for index in range(node.multimesh.instance_count): transforms.append(node.multimesh.get_instance_transform(index))
	return transforms

func paint_signature(deck: Node) -> String:
	var meshes: Array = []
	for child in deck.get_children():
		if not child is MultiMeshInstance3D: continue
		meshes.append([child.name,child.multimesh.mesh.get_aabb(),instance_transforms(child)])
	return var_to_str(meshes)

func landmark_signature(stage: Node) -> String:
	var transforms: Array[Transform3D] = []
	for child in stage.get_children():
		if child.has_meta("generated_landmark"): transforms.append(child.transform)
	return var_to_str(transforms)

func rendered_bounds(node: Node) -> Array[AABB]:
	var bounds: Array[AABB] = []
	if node is MeshInstance3D and node.mesh:
		bounds.append(node.global_transform*node.mesh.get_aabb())
	elif node is MultiMeshInstance3D and node.multimesh:
		for transform in instance_transforms(node):
			bounds.append((node.global_transform*transform)*node.multimesh.mesh.get_aabb())
	for child in node.get_children(): bounds.append_array(rendered_bounds(child))
	return bounds

func run_checks() -> void:
	var routes: Dictionary = {}
	var modifiers: Dictionary = {}
	var themes: Dictionary = {}
	var counts: Dictionary = {}
	var gate_counts: Dictionary = {}
	var fingerprints: Dictionary = {}
	var deterministic := true
	var inside_arena := true
	var ordered_and_spaced := true
	var gate_clearance := true
	var safe_entry_exit := true
	var bounded_pressure := true
	var visible_hazard_warning := true
	var clear_center_lane := true
	var synchronized := true
	var crossing_windows := true
	var valid_objectives := true
	for seed_value in range(32):
		for index in range(3,27):
			var data: Dictionary = Generator.generate(seed_value,index)
			layouts_checked += 1
			deterministic = deterministic and var_to_str(data)==var_to_str(Generator.generate(seed_value,index))
			routes[data.route] = true
			modifiers[data.modifier.id] = true
			themes[data.theme] = true
			counts[data.relay_goal] = true
			gate_counts[data.gates.size()] = true
			# Fingerprints contain physical geometry, not seed/name metadata.
			fingerprints[var_to_str([data.targets,data.gates])] = true
			valid_objectives = valid_objectives and data.targets.size()==int(data.relay_goal) and data.boss==(index%3==2)
			for glide in data.glide_relays:
				valid_objectives = valid_objectives and glide>=0 and glide<data.targets.size()
			var previous_z := 10.0
			for at: Vector3 in data.targets:
				inside_arena = inside_arena and absf(at.x)<=7.5 and absf(at.z)<=8.5 and is_equal_approx(at.y,2.6)
				ordered_and_spaced = ordered_and_spaced and previous_z-at.z>=3.79
				previous_z = at.z
				for spec in data.gates:
					gate_clearance = gate_clearance and absf(at.z-float(spec.position.z))>=1.899
			for spec in data.gates:
				inside_arena = inside_arena and absf(spec.position.x)<=2.5 and absf(spec.position.z)<=7.0
				var from := Vector3(0,0,10)
				var to := Vector3(0,0,-13.5)
				safe_entry_exit = safe_entry_exit and Campaign.block_gate(from,to,spec.position,1.0).is_equal_approx(to)
				var flight_to := to+Vector3.UP*2.2
				safe_entry_exit = safe_entry_exit and Campaign.block_gate(from+Vector3.UP*2.2,flight_to,spec.position,0.0).is_equal_approx(flight_to)
				var window := 0.0
				var longest_window := 0.0
				for sample in range(200):
					window = window+0.1 if gate_open(spec,float(sample)*0.1)>0.85 else 0.0
					longest_window = maxf(longest_window,window)
				crossing_windows = crossing_windows and longest_window>=0.9
				if data.modifier.id=="synchronized":
					for time in [0.0,0.5,2.0,5.0,20.0]:
						synchronized = synchronized and is_equal_approx(gate_open(spec,time),gate_open(data.gates[0],time))
			bounded_pressure = bounded_pressure and data.gates.size()<=Generator.MAX_GATES and int(data.enemy_cap)<=Generator.MAX_ENEMIES and int(data.kills)<=Generator.MAX_KILLS and float(data.spawn_interval)>=1.8 and float(data.hazard_interval)>=4.8 and int(data.hazard_count)<=2
			visible_hazard_warning = visible_hazard_warning and float(data.hazard_warning)>=Generator.MIN_WARNING
			for at: Vector3 in data.hazard_sites:
				clear_center_lane = clear_center_lane and absf(at.x)-float(data.hazard_radius)>=3.0
	check(deterministic,"seed and absolute stage reproduce all geometry and encounter settings")
	check(inside_arena,"768 generated layouts keep relay, gate and runway geometry inside the playable deck")
	check(ordered_and_spaced,"generated relay rows progress north with room to land and recharge between flights")
	check(gate_clearance,"every generated relay has at least1.9m clearance from each shutter plane")
	check(safe_entry_exit,"every layout permits a ground route through open gates and a base-height flight route over closed gates")
	check(crossing_windows,"every generated shutter provides a sustained crossing window")
	check(valid_objectives,"variable relay counts, required-glide indices and recurring boss objectives stay valid")
	check(bounded_pressure,"enemy density, spawn cadence, gates, kill goals and hazard pressure remain capped")
	check(visible_hazard_warning and clear_center_lane,"hazards always warn for at least1.35s and preserve the center escape lane")
	check(synchronized,"synchronized shutters share actual openness across time, not just initial phase")
	check(routes.size()==6 and modifiers.size()==5 and themes.size()==3,"seed sweep exercises all six route templates, five mechanics modifiers and three themes")
	check(counts.has(3) and counts.has(4) and gate_counts.size()==3,"generated objectives vary relay and shutter counts")
	check(fingerprints.size()>700,"different seeds produce distinct physical layouts rather than just changed labels")
	for index in range(3):
		var data: Dictionary = Generator.generate(991,index)
		check(not data.generated and data.targets==Generator.ONBOARDING[index].targets and data.kills==Generator.ONBOARDING[index].kills,"onboarding sector%d retains its authored route and combat goal" % (index+1))
	var future: Dictionary = Generator.generate(42,1000000000)
	check(future.index==1000000000 and future.theme==1 and future.generated,"a distant stage keeps its absolute index while cycling a bounded theme")
	check(future.enemy_cap<=18 and future.kills<=14 and future.spawn_interval>=1.8,"difficulty stays bounded after a billion stages")
	var copy: Dictionary = Generator.generate(42,12)
	copy.targets[0] = Vector3(999,999,999)
	copy.modifier.label = "MODIFIED"
	check(Generator.generate(42,12).targets[0].x<8 and Generator.generate(42,12).modifier.label!="MODIFIED","editing a generated stage cannot contaminate future seeded generations")
	var t = Traversal.new()
	t.request_jump()
	var glide_reaches_relay := false
	var clears_closed_gate := false
	for frame in range(360):
		t.step(1.0/120.0,true)
		clears_closed_gate = clears_closed_gate or t.height>2.2
		glide_reaches_relay = glide_reaches_relay or (t.gliding and absf(t.height+0.9-2.6)<1.0)
	check(clears_closed_gate and glide_reaches_relay,"unmodified jump and finite-fuel glide reach generated gate and relay heights")

	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = true
	game.start_campaign()
	var c = game.campaign
	c.run_seed = 42
	var flat_paint := true
	var paint_caps := true
	var safe_landmarks := true
	var repeatable_dressing := true
	var gameplay_unchanged := true
	var absolute_numbering := true
	for index in [3,4,5,6,31,1000000]:
		game.clear_run()
		var random_state: int = game.rng.state
		c.enter_sector(index)
		game.state = "run"
		check(c.sector==index and c.theme_index==index%3 and c.current_stage.index==index,"live campaign enters absolute stage%d without a three-sector clamp" % index)
		check(c.gates.size()==c.current_stage.gates.size() and c.target.position==c.current_stage.targets[0] and c.relay_goal()==c.current_stage.targets.size(),"live stage%d instantiates the seeded physical route" % index)
		var deck: Node = c.stage.get_node("SectorDeckGraphics")
		var original_paint := paint_signature(deck)
		var original_landmarks := landmark_signature(c.stage)
		var original_data := var_to_str(c.current_stage)
		gameplay_unchanged = gameplay_unchanged and game.rng.state==random_state and original_data==var_to_str(Generator.generate(c.run_seed,index))
		for box: AABB in rendered_bounds(deck):
			flat_paint=flat_paint and box.end.y<0.055
		flat_paint = flat_paint and deck.find_children("*","CollisionObject3D",true,false).is_empty()
		paint_caps = paint_caps and int(c.stage.get_meta("generated_paint_instances"))<=Campaign.Visuals.MAX_GENERATED_PAINT and deck.get_child_count()<=5
		for child in deck.get_children():
			if child is GeometryInstance3D and not child is Label3D: paint_caps=paint_caps and child.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for child in c.stage.get_children():
			if not child.has_meta("generated_landmark"): continue
			# Conservative authored radial envelopes cover batch geometry even
			# when the dummy renderer cannot expose its transforms. Direct meshes
			# are also checked below; native checks include every batch instance.
			var radius := 2.0
			if child.has_node("Rotor"): radius=2.6
			elif child.has_node("SolarPanel"): radius=3.4
			elif child.has_node("LightCrown"): radius=1.2
			elif child.name=="SolarCollector": radius=5.0
			elif child.name=="StormLandmark": radius=6.0
			safe_landmarks = safe_landmarks and absf(child.global_position.x)-radius>15.8
			for box: AABB in rendered_bounds(child):
				safe_landmarks = safe_landmarks and (box.position.x>15.8 or box.end.x< -15.8 or box.position.z>15.8 or box.end.z< -15.8)
		absolute_numbering = absolute_numbering and c.stage.get_node("SectorNumber").text=="%02d" % (index+1)
		Campaign.Visuals.apply_generated_dressing(c.stage,c.current_stage)
		repeatable_dressing = repeatable_dressing and original_paint==paint_signature(c.stage.get_node("SectorDeckGraphics")) and original_landmarks==landmark_signature(c.stage)
		gameplay_unchanged = gameplay_unchanged and original_data==var_to_str(c.current_stage) and game.rng.state==random_state
		await process_frame
	check(flat_paint,"generated route inlays stay below0.055m, underneath hazard paint, and add no collision objects")
	check(paint_caps,"generated dressing uses at most four shadow-free mesh batches plus one label and a bounded instance count")
	check(safe_landmarks,"varied landmarks retain conservative authored bounds beyond the arena and perimeter")
	check(repeatable_dressing,"reapplying a cosmetic seed reproduces actual floor meshes and landmark transforms without drift")
	check(gameplay_unchanged,"cosmetic dressing leaves generated gameplay data and the combat RNG state unchanged")
	check(absolute_numbering,"generated floor sector numbering uses absolute stage numbers instead of repeating theme indices")
	var cosmetic_routes: Dictionary = {}
	for seed_value in range(64):
		var data: Dictionary = Generator.generate(seed_value,6)
		if not cosmetic_routes.has(data.route): cosmetic_routes[data.route]=seed_value
		if cosmetic_routes.size()==6: break
	var macro_floors: Dictionary = {}
	for route in cosmetic_routes:
		game.clear_run()
		c.run_seed = cosmetic_routes[route]
		c.enter_sector(6)
		macro_floors[paint_signature(c.stage.get_node("SectorDeckGraphics"))] = true
		await process_frame
	check(macro_floors.size()==6,"six route templates create distinct physical floor paint layouts within the same biome")
	c.run_seed = 42
	game.clear_run()
	c.enter_sector(6)
	var initial_goal: int = c.relay_goal()
	c.relays = int(c.current_stage.glide_relays[0])
	c.create_target()
	var before_relay: int = c.relays
	var at: Vector3 = c.target.position
	game.traversal.request_jump()
	for frame in range(240):
		game.traversal.step(1.0/120.0,true)
		game.player_previous = Vector3(at.x,game.traversal.previous_height,at.z)
		game.player_node.position = Vector3(at.x,game.traversal.height,at.z)
		c.update(1.0/120.0)
		if c.relays>before_relay: break
	check(c.relays==before_relay+1 and game.traversal.gliding,"an actual generated glide relay is collectable with the base traversal resource")
	check(c.objective().contains("/ %d" % initial_goal) or c.relays==initial_goal,"objective text reflects the generated relay count")
	game.clear_run()
	c.enter_sector(1000000)
	c.relays = 1
	for i in range(int(c.current_stage.enemy_cap)): game.spawn_enemy("gunner",Vector3(12,0,12))
	c.spawn_clock = 0.0
	c.update(0.016)
	check(game.enemies.size()==int(c.current_stage.enemy_cap),"live generated director cannot exceed its enemy density cap")
	for i in range(12):
		c.hazard_clock = 0.0
		c.update_route_hazards(0.016)
	check(game.field.hazards.size()<=5,"repeated generated hazard waves respect the shared hazard pool cap")
	game.clear_run()
	c.enter_sector(5)
	c.relays = c.relay_goal()
	c.create_target()
	c.update(0.016)
	check(c.boss_started and game.state=="boss","the sixth sector summons another guardian instead of terminating progression")
	c.mark_guardian_defeated()
	c.update(1.5)
	check(c.boss_defeated and c.gate_open and c.exit_openness>0.8,"guardian victory exposes a continuation exit without summoning another boss")
	for i in range(100): c.record_checkpoint(float(i))
	check(c.checkpoint_times.size()==Generator.HISTORY_LIMIT and c.checkpoint_times[0]==68.0,"endless checkpoint history retains only the most recent32 entries")
	game.clear_run()
	c.start(991)
	check(c.run_seed==991 and c.sector==0 and c.total_relays==0 and c.checkpoint_times.is_empty() and c.wave==0 and c.hazard_waves==0 and not c.boss_defeated,"seeded restart clears campaign progress, history and encounter counters")
	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	print("Generation: %d layouts, %d checks, %d failures" % [layouts_checked,checks,failures])
	quit(1 if failures else 0)
