extends Node3D
const Rules = preload("res://scripts/rules.gd")
const Art = preload("res://scripts/art.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Field = preload("res://scripts/combat_field.gd")
const HUD = preload("res://scripts/hud.gd")
const Traversal = preload("res://scripts/traversal.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Weapons = preload("res://scripts/weapons.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
var weapons: Node3D
var weapon_fx: Node3D
var weapon_choices: Array = []
var guardians_defeated := 0
var qa_sector_limit := 3
var traversal = Traversal.new()
var campaign: Node3D
var campaign_active := false
var player_marker: MeshInstance3D
var world_environment: Environment
var qa_jump_held := false
var qa_damage_events: Array = []
var qa_boss_entry: Dictionary = {}
var rules = Rules.new()
var rng := RandomNumberGenerator.new()
var state := "title"
var previous_state := "run"
var settings_origin := "title"
var settings: Dictionary = {"volume":0.65,"shake":0.45,"assist":false,"low_effects":false,"best":0,"practiced":false}
var bindings: Dictionary = {"left":KEY_A,"right":KEY_D,"up":KEY_W,"down":KEY_S,"dash":KEY_SPACE,"pulse":KEY_E,"jump":KEY_F,"weapon":KEY_Q}
var rebind_action := ""
var player_node: Node3D
var player_position: Vector3:
	get: return player_node.position if is_instance_valid(player_node) else Vector3.ZERO
var player_previous := Vector3.ZERO
var player_velocity := Vector3.ZERO
var facing := Vector3.FORWARD
var dash_direction := Vector3.FORWARD
var dash_hit: Array = []
var enemies: Array = []
var boss_ref: Node3D
var camera_home := Vector3(0,24,29)
var camera: Camera3D
var key_light: DirectionalLight3D
var pulse_light: OmniLight3D
var pulse_light_time := 0.0
var pulse_light_strength := 0.0
var field: Node3D
var ui: CanvasLayer
var sound: Node
var run_time := 0.0
var spawn_timer := 1.0
var auto_timer := 0.0
var trail_timer := 0.0
var last_upgrade := 0
var upgrade_choices: Array = []
var shake := 0.0
var harvest_flash := 0.0
var practice := false
var practice_step := 0
var practice_pulse_hit := false
var practice_timer := 0.0
var practice_start := Vector3.ZERO
var next_core := 45.0
var core_node: Node3D
var core_time := 0.0
var boss_intro := 0.0
var ending_delay := 0.0
var display_time := 0.0
var qa_mode := false
var qa_passive := false
var qa_fast := false
var qa_elapsed := 0.0
var qa_captured: Dictionary = {}
var qa_health_start := 100.0
var qa_last_absorbed := 0
var qa_dash_wait := 0.0
var qa_render_frames: Array[float] = []
var qa_last_frame_usec := 0
var qa_output_dir := ""
var qa_simulation := false
var qa_segments: Dictionary = {}
var hard_mode := false
var next_gunner_wave := 0
var last_render_state := ""

func _ready() -> void:
	rng.randomize()
	load_settings()
	configure_input()
	setup_world()
	Art.build_arena(self)
	field = Field.new(); field.game = self; add_child(field)
	player_node = Art.player(); add_child(player_node)
	weapon_fx = CombatFX.new(); add_child(weapon_fx)
	weapons = Weapons.new(); weapons.game = self; add_child(weapons)
	weapons.reset()
	player_marker = field.ring(0.62,Color(0.46,1,0.87,0.65)); add_child(player_marker)
	campaign = Campaign.new(); campaign.game = self; add_child(campaign)
	ui = HUD.new(); add_child(ui)
	ui.set_bindings(bindings)
	ui.action.connect(on_ui_action)
	get_window().focus_exited.connect(pause_on_focus_loss)
	if ResourceLoader.exists("res://scripts/audio_director.gd"):
		sound = load("res://scripts/audio_director.gd").new()
		add_child(sound)
		if sound.has_method("set_volume"): sound.set_volume(settings.volume)
	apply_settings()
	ui.show_title(settings.best,settings.practiced)
	show_title_scene()
	var args := OS.get_cmdline_user_args()
	qa_mode = args.has("--qa")
	qa_passive = args.has("--qa-passive")
	qa_fast = args.has("--qa-fast")
	qa_simulation = qa_fast or DisplayServer.get_name()=="headless" or OS.get_cmdline_args().has("--fixed-fps")
	qa_output_dir = ProjectSettings.globalize_path("res://qa")
	for arg in args:
		if arg.begins_with("--qa-dir="): qa_output_dir=arg.trim_prefix("--qa-dir=")
		if arg.begins_with("--qa-sectors="): qa_sector_limit=maxi(3,int(arg.trim_prefix("--qa-sectors=")))
	if qa_mode:
		settings.assist=args.has("--qa-assist")
		settings.overdrive=args.has("--qa-overdrive")
		rng.seed = 42 if args.has("--qa-alt") else 271828
		if args.has("--qa-alt"): qa_captured["alternate"]=true
		if args.has("--qa-campaign"): start_campaign(int(rng.seed))
		else: start_run(false)
		if args.has("--qa-alt"):
			rng.seed=42
			qa_captured["alternate"]=true
		if args.has("--qa-boss"):
			run_time = 360.0
			last_upgrade = 5
			for id in ["capacitor","echo","chain","wake","siphon"]: rules.apply_upgrade(id)
	if args.has("--capture-title"):
		await get_tree().create_timer(1.5).timeout
		capture("title")
		get_tree().quit()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if qa_mode and not qa_simulation and state in ["run","boss"] and qa_last_frame_usec>0 and run_time>3:
		var frame_ms := float(now-qa_last_frame_usec)/1000.0
		if last_render_state in ["run","boss"]:
			qa_render_frames.append(frame_ms)
			var segment := "boss" if state=="boss" else "sector_%d" % (campaign.sector+1) if campaign_active else "minute_%d" % (1+int(run_time/60))
			if not qa_segments.has(segment): qa_segments[segment]=[]
			qa_segments[segment].append(frame_ms)
	qa_last_frame_usec=now
	last_render_state=state

func pause_on_focus_loss() -> void:
	if not qa_mode and state in ["run","boss"]:
		previous_state=state
		state="paused"
		ui.show_pause()

func setup_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("071323")
	sky_material.sky_horizon_color = Color("375667")
	sky_material.ground_bottom_color = Color("0a1825")
	sky_material.ground_horizon_color = Color("375667")
	sky_material.sky_curve = 0.2
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7a92ca")
	env.ambient_light_energy = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("142344")
	env.fog_density = 0.0015
	world.environment = env
	world_environment = env
	add_child(world)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-58,-28,0)
	key_light.light_color = Color("dbe5ff")
	key_light.light_energy = 1.3
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 90
	add_child(key_light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-25,140,0)
	rim.light_color = Color("8d69ff")
	rim.light_energy = 0.55
	add_child(rim)
	pulse_light = OmniLight3D.new()
	pulse_light.light_color = Color("67dfff")
	pulse_light.light_energy = 0.0
	pulse_light.omni_range = 9.0
	pulse_light.shadow_enabled = false
	pulse_light.visible = false
	add_child(pulse_light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 41
	camera.position = Vector3(0,27,24)
	camera.far = 200
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true

func configure_input() -> void:
	for id in bindings:
		if not InputMap.has_action(id): InputMap.add_action(id)
		InputMap.action_erase_events(id)
		var event := InputEventKey.new()
		event.physical_keycode = int(bindings[id])
		InputMap.action_add_event(id,event)
	# Arrow keys remain an ergonomic alternate unless explicitly rebound elsewhere.
	for pair in [["left",KEY_LEFT],["right",KEY_RIGHT],["up",KEY_UP],["down",KEY_DOWN]]:
		if int(pair[1]) in bindings.values(): continue
		var event := InputEventKey.new(); event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0],event)
	if is_instance_valid(ui): ui.set_bindings(bindings)
	if is_instance_valid(ui) and practice: refresh_practice_hint()
	if campaign_active and is_instance_valid(campaign): campaign.refresh_target_label()

func key_name(id: String) -> String:
	return OS.get_keycode_string(int(bindings[id]))

func load_settings() -> void:
	if ResourceLoader.exists("res://scripts/save_store.gd"):
		var store = load("res://scripts/save_store.gd")
		var data: Dictionary = store.load_data()
		settings.merge(data,true)
		if data.has("bindings"): bindings.merge(data.bindings,true)

func save_settings() -> void:
	if qa_mode: return
	settings.bindings = bindings.duplicate()
	if ResourceLoader.exists("res://scripts/save_store.gd"):
		load("res://scripts/save_store.gd").save_data(settings)

func apply_settings() -> void:
	if sound and sound.has_method("set_volume"): sound.set_volume(float(settings.volume))
	key_light.shadow_enabled = not settings.get("low_effects",false)
	if is_instance_valid(weapon_fx): weapon_fx.low_effects=bool(settings.get("low_effects",false))
	if is_instance_valid(pulse_light):
		pulse_light.visible = pulse_light_time > 0.0 and not settings.get("low_effects",false)

func show_title_scene() -> void:
	campaign.clear()
	campaign.stage = Campaign.Visuals.build_stage(campaign,0)
	var pedestal: Node3D = Campaign.Visuals.hero_display()
	campaign.stage.add_child(pedestal)
	pedestal.position = Vector3(8,0,3)
	set_sector_lighting(0)
	player_node.position = Vector3(8,0,3)
	player_node.scale = Vector3.ONE*5.8
	player_node.rotation = Vector3(0,0.35,0)
	player_node.visible = true
	player_marker.visible = false
	camera.size = 34
	camera.position = Vector3(0,17,29)
	camera.look_at(Vector3.ZERO)

func set_sector_lighting(index: int) -> void:
	var colors := [Color("dbe5ff"),Color("ffe1c0"),Color("e4d9ff")]
	var fogs := [Color("142344"),Color("321c36"),Color("241735")]
	key_light.light_color = colors[index]
	world_environment.fog_light_color = fogs[index]
	var sky_material: ProceduralSkyMaterial = world_environment.sky.sky_material
	sky_material.sky_horizon_color = fogs[index].lightened(0.025)
	sky_material.ground_horizon_color = fogs[index]
	sky_material.sky_top_color = fogs[index].darkened(0.78)

func start_campaign(seed: int = -1) -> void:
	var chosen_seed: int = seed if seed>=0 else 271828 if qa_mode else int(rng.randi())
	start_run(false)
	campaign_active = true
	campaign.start(chosen_seed)
	ui.show_hint("FIND THE AIR RELAYS  /  Upgrade your weapon at each checkpoint. Keep diving deeper.",7)

func complete_sector() -> void:
	state = "sector_complete"
	field.clear()
	weapons.clear_projectiles()
	rules.dash_time = 0
	player_node.visible = true
	var next_stage: Dictionary=Campaign.Generator.generate(campaign.run_seed,campaign.sector+1)
	ui.show_sector_complete(campaign.sector,campaign.current_stage.name,run_time,campaign.total_relays,{
		"next":next_stage.name,"route":next_stage.route,"modifier":next_stage.modifier.label,
		"seed":campaign.run_seed,"guardians":guardians_defeated,"weapon":Weapons.PROFILES[weapons.mode].name,
		"rank":Weapons.roman(weapons.tier())})
	if qa_mode: print("QA sector complete: ",campaign.sector+1," at ",run_time)

func next_sector() -> void:
	if state != "sector_complete": return
	clear_run()
	campaign.enter_sector(campaign.sector+1)
	show_weapon_draft()

func show_weapon_draft() -> void:
	weapon_choices=weapons.draft(rng)
	state="weapon_upgrade"
	var data: Array=[]
	for id in weapon_choices: data.append(weapons.offer(id))
	ui.show_weapon_upgrades(weapon_choices,data)
	cue("upgrade")

func choose_weapon(id: String) -> void:
	if state!="weapon_upgrade" or id not in weapon_choices: return
	weapons.install(id)
	weapon_choices.clear()
	cue("weapon_install")
	upgrade_choices=rules.upgrade_options(rng)
	if not upgrade_choices.is_empty():
		state="upgrade"
		ui.show_upgrades(upgrade_choices)
	else:
		rules.health=minf(100,rules.health+20)
		rules.energy=minf(100,rules.energy+25)
		rules.recovery=2.0
		state="run"
		ui.show_game()
		ui.show_hint("WEAPON INSTALLED  /  REACTOR SERVICED +20 HULL +25 CHARGE",4)

func bank_run() -> void:
	if state=="sector_complete": finish(guardians_defeated>0,true)

func begin_campaign_boss() -> void:
	for enemy in enemies: enemy.queue_free()
	enemies.clear()
	field.clear()
	weapons.clear_projectiles()
	if is_instance_valid(core_node): core_node.queue_free()
	core_node = null
	rules.health = minf(100,rules.health+25)
	rules.energy = maxf(40,rules.energy)
	rules.recovery = 2.0
	for gate in campaign.gates:
		gate.open=1.0
		gate.previous_open=1.0
		Campaign.Visuals.animate_gate(gate.node,1.0,campaign.elapsed)
	boss_ref = spawn_enemy("boss",Vector3(0,0,-2.8))
	boss_ref.hp = 1800.0*(1.2 if hard_mode else 1.0)*(1.0+minf(1.5,float(campaign.sector/3)*0.2))
	boss_ref.max_hp = boss_ref.hp
	qa_boss_entry = {"time":run_time,"health":rules.health,"position":str(player_position)}
	state = "boss"
	announce("THE REACTOR GUARDIAN", "Jump its shock zones. Land to steal its volleys.")
	cue("boss")

func start_run(is_practice: bool = false) -> void:
	clear_run()
	qa_damage_events.clear()
	qa_boss_entry.clear()
	campaign_active = false
	campaign.clear()
	traversal.reset()
	set_sector_lighting(0)
	rules.reset()
	weapons.reset()
	weapon_choices.clear()
	guardians_defeated=0
	practice = is_practice
	state = "run"
	run_time = 0
	spawn_timer = 1.2
	auto_timer = 0.3
	last_upgrade = 0
	next_gunner_wave=0
	next_core = 45
	practice_step = 0
	practice_pulse_hit=false
	practice_timer = 0
	hard_mode=bool(settings.get("overdrive",false)) and not is_practice
	practice_start = Vector3.ZERO
	player_node.position = Vector3.ZERO
	player_node.scale = Vector3.ONE * 1.35
	camera.size = 31.8
	camera.position = camera_home
	camera.look_at(Vector3.ZERO)
	player_node.rotation = Vector3.ZERO
	player_previous = Vector3.ZERO
	player_velocity = Vector3.ZERO
	facing = Vector3.FORWARD
	ui.show_game()
	ui.objective_text.text = ""
	if practice:
		ui.show_hint("MOVE  /  Use %s or the arrow keys to explore the deck." % ui.movement_keys(),60)
	else:
		announce("WELCOME TO THE SKYFORGE", "Survive six minutes. Break the guardian.")
		ui.show_hint("%s dashes through orange shots. %s spends stolen energy." % [key_name("dash"),key_name("pulse")],7)

func clear_run() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	boss_ref = null
	field.clear()
	if is_instance_valid(weapons): weapons.clear_projectiles()
	if is_instance_valid(weapon_fx): weapon_fx.clear()
	pulse_light_time = 0.0
	if is_instance_valid(pulse_light):
		pulse_light.light_energy = 0.0
		pulse_light.visible = false
	if is_instance_valid(core_node): core_node.queue_free()
	core_node = null
	core_time = 0
	ending_delay = 0
	dash_hit.clear()

func on_ui_action(action: String, value: Variant) -> void:
	match action:
		"start": start_run(false)
		"campaign": start_campaign()
		"next_sector": next_sector()
		"weapon_upgrade": choose_weapon(value)
		"bank": bank_run()
		"quit": save_settings(); get_tree().quit()
		"restart":
			if campaign_active: start_campaign(campaign.run_seed)
			else: start_run(false)
		"overdrive": settings.overdrive=value; save_settings()
		"practice": start_run(true)
		"resume": state = previous_state; ui.show_game()
		"title":
			clear_run(); state = "title"
			campaign_active = false
			campaign.clear()
			traversal.reset()
			show_title_scene()
			ui.show_title(settings.best,settings.practiced)
		"settings":
			settings_origin = state
			state = "settings"; ui.show_settings(settings,bindings)
		"back":
			state = settings_origin
			if state == "title": ui.show_title(settings.best,settings.practiced)
			else: state = "paused"; ui.show_pause()
		"setting":
			settings[value.key] = value.value
			apply_settings(); save_settings()
		"rebind": state = "rebind"; rebind_action = value; ui.show_rebind(value)
		"reset_controls":
			bindings = {"left":KEY_A,"right":KEY_D,"up":KEY_W,"down":KEY_S,"dash":KEY_SPACE,"pulse":KEY_E,"jump":KEY_F,"weapon":KEY_Q}
			configure_input(); save_settings(); ui.show_settings(settings,bindings)
		"upgrade": choose_upgrade(value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "rebind":
			var key: int = event.physical_keycode if event.physical_keycode else event.keycode
			if key == KEY_ESCAPE:
				state = "settings"; ui.show_settings(settings,bindings); return
			if key in [KEY_ENTER,KEY_KP_ENTER,KEY_TAB,KEY_1,KEY_2,KEY_3,KEY_F11]: return
			for id in bindings:
				if bindings[id] == key: bindings[id] = bindings[rebind_action]
			bindings[rebind_action] = key
			configure_input(); save_settings()
			state = "settings"; ui.show_settings(settings,bindings); return
		if event.keycode == KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
			return
		if event.keycode == KEY_ESCAPE:
			if state in ["run","boss"]:
				previous_state = state; state = "paused"; ui.show_pause()
			elif state == "paused": on_ui_action("resume",null)
			elif state == "settings": on_ui_action("back",null)
			return
		if state == "weapon_upgrade" and event.keycode in [KEY_1,KEY_2,KEY_3]:
			var index: int = event.keycode - KEY_1
			if index < weapon_choices.size(): choose_weapon(weapon_choices[index])
			return
		if state == "upgrade" and event.keycode in [KEY_1,KEY_2,KEY_3]:
			var index: int = event.keycode - KEY_1
			if index < upgrade_choices.size(): choose_upgrade(upgrade_choices[index])
	if state in ["run","boss"]:
		if event.is_action_pressed("dash"): dash()
		if event.is_action_pressed("pulse"): pulse()
		if event.is_action_pressed("jump"): traversal.request_jump()
		if event.is_action_pressed("weapon"):
			if weapons.cycle():
				cue("ready",0.6)
				ui.show_hint("EQUIPPED  /  "+Weapons.PROFILES[weapons.mode].name,2)
			else: ui.show_hint("UNLOCK ANOTHER WEAPON AT THE NEXT SECTOR CHECKPOINT",3)

func _physics_process(delta: float) -> void:
	display_time += delta
	update_battle_audio()
	if state not in ["run","boss"]:
		if state == "title":
			player_node.rotation.y += delta * 0.25
			player_node.position.y = sin(display_time*1.5)*0.05
			Art.animate_player(player_node,delta,0.0,true,true,false,display_time)
			player_marker.visible = false
			Campaign.Visuals.animate_stage(campaign.stage,delta,display_time)
		if qa_mode and state == "weapon_upgrade":
			choose_weapon(weapon_choices[1] if qa_captured.has("alternate") else weapon_choices[0])
		if qa_mode and state == "upgrade":
			var preferred := ["capacitor","siphon","echo","chain","radius","ignite","collector","wake","frost"]
			if qa_captured.has("alternate"): preferred=["wake","frost","ignite","collector","radius","capacitor","echo","chain","siphon"]
			for id in preferred:
				if id in upgrade_choices: choose_upgrade(id); break
		if qa_mode and state == "sector_complete":
			if campaign.sector+1>=qa_sector_limit: bank_run()
			else: next_sector()
		return
	var step := delta
	if qa_fast: step = delta * 4
	qa_elapsed += delta
	player_previous = player_position
	var movement := Vector3(Input.get_axis("left","right"),0,Input.get_axis("up","down"))
	if qa_mode: movement = pilot(step)
	movement.y = 0
	movement = movement.limit_length(1.0)
	traversal.step(step,qa_jump_held if qa_mode else Input.is_action_pressed("jump"))
	if traversal.jumped: cue("dash",0.5)
	if traversal.landed:
		player_node.set_meta("landing_impact",clampf(traversal.landing_speed/12.0,0.2,1.0))
		add_effect(Vector3(player_position.x,0,player_position.z),Color("a0fff0"),0.95)
		cue("ready",0.32)
	if movement.length_squared()>0.01: facing = movement.normalized()
	if rules.dash_time > 0:
		var dash_speed := 30.0 * (0.85 if rules.upgrades.has("collector") else 1.0)
		player_velocity = dash_direction * dash_speed
	else:
		player_velocity = movement * (9.0 if traversal.gliding else 7.0)
	player_node.position += player_velocity * step
	player_node.position.x = clampf(player_node.position.x,-14.4,14.4)
	player_node.position.z = clampf(player_node.position.z,-14.4,14.4)
	player_node.position.y = traversal.height
	if campaign_active: player_node.position = campaign.resolve_gates(player_previous,player_position)
	player_node.rotation.y = lerp_angle(player_node.rotation.y,atan2(facing.x,facing.z),minf(1,step*18))
	Art.animate_player(player_node,step,movement.length(),not traversal.grounded,traversal.gliding,rules.dash_time>0,display_time)
	player_marker.visible = true
	player_marker.position = Vector3(player_position.x,0.06,player_position.z)
	player_marker.scale = Vector3.ONE*(1.0+traversal.height*0.12)
	player_node.visible = not (rules.recovery>0 and sin(display_time*45)>0.7)
	trail_timer -= step
	if rules.dash_time>0 and trail_timer<=0:
		trail_timer = 0.045
		add_trail(player_position,Color(0.38,1,0.83,0.65),0.65)
		if traversal.height<0.45 and (rules.upgrades.has("wake") or rules.upgrades.has("frost")):
			field.add_field(player_position,rules.upgrades.has("wake"))
		if rules.upgrades.has("ignite"):
			for enemy in enemies:
				if not enemy.dead and not dash_hit.has(enemy) and enemy.position.distance_to(player_position)<1.2:
					dash_hit.append(enemy); enemy.take_hit(24,true)
	weapons.record_enemy_positions()
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.update(step)
	field.update(step)
	weapons.update(step)
	weapon_fx.update(step)
	pulse_light_time = maxf(0.0,pulse_light_time-step)
	pulse_light.visible = pulse_light_time > 0.0 and not settings.get("low_effects",false)
	pulse_light.light_energy = pulse_light_strength*pow(pulse_light_time/0.26,2)
	for i in range(enemies.size()-1,-1,-1):
		if enemies[i].dead:
			enemies[i].queue_free(); enemies.remove_at(i)
	auto_timer -= step
	if auto_timer <= 0 and (not practice or practice_step >= 3):
		auto_timer = 0.0
		auto_shoot()
	if practice: update_practice(step)
	elif campaign_active:
		run_time += step
		campaign.update(step)
	else: update_director(step)
	update_core(step)
	var previous_charges: int=rules.dash_charges
	rules.tick(step)
	if rules.dash_charges>previous_charges: cue("ready",0.6)
	harvest_flash = maxf(0,harvest_flash-step)
	shake = maxf(0,shake-step*2.5)
	camera.position = camera_home+Vector3(sin(display_time*83),0,cos(display_time*69))*shake*float(settings.shake)
	var boss_hp := 0.0
	var boss_max := 0.0
	if is_instance_valid(boss_ref) and not boss_ref.dead:
		boss_hp = boss_ref.hp; boss_max = boss_ref.max_hp
	ui.update_game(rules,run_time,boss_hp,boss_max,practice)
	ui.update_traversal(traversal)
	ui.update_weapon(weapons)
	if campaign_active:
		ui.status_text.text = "%02d / ENDLESS   %s" % [campaign.sector+1,campaign.current_stage.name]
		ui.objective_text.text = campaign.objective()
	if rules.health<=0:
		finish(false)
	elif ending_delay > 0:
		ending_delay -= step
		if ending_delay <= 0:
			if campaign_active:
				campaign.mark_guardian_defeated()
				campaign.completed=true
				campaign.record_checkpoint(run_time)
				complete_sector()
			else: finish(true)
	if qa_mode:
		for checkpoint in [15,90,190,365]:
			if run_time >= checkpoint and not qa_captured.has(checkpoint):
				qa_captured[checkpoint] = true
				capture.call_deferred("run-%d" % checkpoint)
		if run_time > maxf(570,qa_sector_limit*180): finish(false)

func dash() -> void:
	if not rules.try_dash(): return
	if not qa_mode:
		var direction:=Vector3(Input.get_axis("left","right"),0,Input.get_axis("up","down"))
		if direction.length_squared()>0.01: facing=direction.normalized()
	dash_direction = facing
	dash_hit.clear()
	trail_timer = 0
	cue("dash")
	add_effect(player_position,Color("76f7df"),1.2)

func pulse() -> void:
	var power: float = rules.spend_pulse()
	if power<=0:
		ui.show_hint("Need 30 energy. Dash THROUGH orange shots to steal charge.",2.4)
		return
	pulse_at(player_position,power,false)
	if rules.upgrades.has("echo"):
		field.delayed.append({"kind":"echo","origin":player_position,"power":power,"timer":0.45})

func pulse_at(at: Vector3, power: float, echo: bool = false) -> void:
	var radius := (4.0+power*0.044)*(1.35 if rules.upgrades.has("radius") else 1.0)
	var damage := (27.0+power*0.82)*(1.2 if rules.upgrades.has("ignite") else 1.0)
	if echo: damage *= 0.45
	weapon_fx.pulse(at,power,radius,echo)
	pulse_light.position = at+Vector3(0,1.8,0)
	pulse_light.omni_range = radius+1.0
	pulse_light_time = 0.26
	pulse_light_strength = (0.5 if echo else 1.5)*lerpf(0.6,1.0,clampf(power/100.0,0.0,1.0))
	cue("pulse",0.45 if echo else lerpf(0.65,1.0,power/100.0))
	shake = 0.32 if not echo else 0.12
	var hit: Array = []
	for enemy in enemies:
		if not enemy.dead and enemy.spawning<=0 and enemy.position.distance_to(at)<radius+enemy.radius:
			enemy.take_hit(damage,true,(enemy.position-at).normalized(),"plasma")
			hit.append(enemy)
	if practice and practice_step==2 and not echo:
		practice_pulse_hit=not hit.is_empty()
		if not practice_pulse_hit:
			ui.show_hint("PULSE MISSED  /  Let the machines land, harvest more orange shots, then press %s nearby." % key_name("pulse"),60)
	if rules.upgrades.has("chain"):
		var jumps := 0
		for enemy in enemies:
			if enemy.dead or enemy in hit or jumps>=4: continue
			if enemy.position.distance_to(at)<radius+5:
				weapon_fx.arc_link(at+Vector3(0,0.8,0),enemy.position+Vector3(0,0.8,0),3)
				enemy.take_hit(damage*0.7,true)
				jumps += 1

func update_battle_audio() -> void:
	if not sound or not sound.has_method("set_battle_state"): return
	if state not in ["run","boss"]:
		sound.set_battle_state(0.0,0.0,0.0,false,false)
		return
	var nearby := 0.0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			nearby += clampf(1.0-enemy.position.distance_to(player_position)/18.0,0.0,1.0)
	var incoming := 0.0
	for bullet in field.bullets:
		var offset: Vector3 = player_position-bullet.node.position
		if offset.length_squared() < 100.0 and offset.dot(bullet.velocity) > 0.0:
			incoming += 1.0
	sound.set_battle_state(nearby/6.0,incoming/12.0,rules.energy/100.0,state=="boss",true)

func auto_shoot() -> void:
	if weapons.cooldown>0: return
	var target: Node3D = null
	var best_hp := INF
	for enemy in enemies:
		if not enemy.dead and enemy.spawning<=0 and enemy.position.distance_to(player_position)<float(Weapons.PROFILES[weapons.mode].range):
			var from: Vector3 = Art.muzzle_position(player_node)
			var to: Vector3 = enemy.position+Vector3(0,1.45 if enemy.kind=="boss" else 0.85,0)
			if campaign_active and campaign.resolve_gates(from,to).distance_to(to)>0.05: continue
			if enemy.hp<best_hp: target=enemy; best_hp=enemy.hp
	if target: weapons.fire(target)

func spawn_enemy(kind: String, at: Vector3) -> Node3D:
	if enemies.size()>=27: return null
	var enemy := Enemy.new()
	add_child(enemy)
	enemy.setup(self,kind,Vector3(at.x,0,at.z))
	if campaign_active and campaign.sector>=3 and kind!="boss":
		enemy.hp*=1.0+minf(1.1,float(campaign.sector-2)*0.06)
		enemy.max_hp=enemy.hp
	enemies.append(enemy)
	return enemy

func update_director(delta: float) -> void:
	run_time += delta
	if state == "run":
		var minute := int(run_time/60)
		if minute>last_upgrade and minute<=5:
			last_upgrade = minute
			upgrade_choices = rules.upgrade_options(rng)
			show_weapon_draft()
			return
		if run_time>=360:
			for enemy in enemies: enemy.queue_free()
			enemies.clear(); field.clear()
			if is_instance_valid(core_node): core_node.queue_free()
			core_node=null
			player_node.position = Vector3(0,0,8)
			player_previous = player_position
			rules.health = minf(100,rules.health+25)
			rules.energy = maxf(30,rules.energy)
			boss_ref=spawn_enemy("boss",Vector3(0,0,-6))
			state="boss"
			announce("THE REACTOR GUARDIAN", "Steal its volleys. Break its core.")
			cue("boss")
			return
		spawn_timer -= delta
		if spawn_timer<=0:
			spawn_timer = maxf(1.65,3.0-float(minute)*0.25)*(0.78 if hard_mode else 1.0)
			var number := 1 if minute<2 else 2
			for i in range(number):
				var angle := rng.randf()*TAU
				var at := Vector3(cos(angle),0,sin(angle))*13.7
				if at.distance_to(player_position)<5: at=-at
				var kind := "gunner"
				var roll := rng.randf()
				if roll>0.6 and run_time>18: kind="charger"
				if roll>0.8 and run_time>110: kind="bruiser"
				# Scheduled anchor gunners preserve harvesting opportunities;
				# killing one never causes an immediate reactive replacement.
				if next_gunner_wave%3==0: kind="gunner"
				next_gunner_wave+=1
				spawn_enemy(kind,at)
		if run_time>=next_core:
			next_core+=60
			spawn_core()

func update_practice(delta: float) -> void:
	practice_timer += delta
	if practice_step == 0 and Vector2(player_position.x,player_position.z).length()>2:
		practice_step = 1
		spawn_enemy("gunner",Vector3(0,0,-7))
		ui.show_hint("HARVEST  /  Face the orange shots and press %s to dash THROUGH them." % key_name("dash"),60)
	elif practice_step == 1 and rules.absorbed>=1:
		practice_step=2
		rules.energy=maxf(40,rules.energy)
		for x in [-2,0,2]: spawn_enemy("gunner",player_position+Vector3(x,0,-4))
		ui.show_hint("PULSE  /  Press %s near the machines. More charge makes a bigger blast." % key_name("pulse"),60)
	elif practice_step == 2 and practice_pulse_hit:
		practice_step=3
		practice_timer=0
		spawn_enemy("charger",Vector3(9,0,-8))
		ui.show_hint("YOU HAVE THE CORE MOVE. Try a charger; break its line before it lunges.",15)
	elif practice_step==3 and practice_timer>12:
		settings.practiced=true; save_settings()
		state="practice_complete"
		ui.show_practice_complete()
	# Practice is forgiving but teaches actual collisions and the same controls.
	rules.health=maxf(35,rules.health)

func refresh_practice_hint() -> void:
	match practice_step:
		0: ui.show_hint("MOVE  /  Use %s or the arrow keys to explore the deck." % ui.movement_keys(),60)
		1: ui.show_hint("HARVEST  /  Face the orange shots and press %s to dash THROUGH them." % key_name("dash"),60)
		2: ui.show_hint("PULSE  /  Press %s near the machines. More charge makes a bigger blast." % key_name("pulse"),60)

func choose_upgrade(id: String) -> void:
	if state!="upgrade" or id not in upgrade_choices: return
	rules.apply_upgrade(id)
	rules.health=minf(100,rules.health+20)
	upgrade_choices.clear()
	state="run"
	ui.show_game()
	rules.recovery=1.0
	ui.show_hint("INSTALLED  /  "+Rules.UPGRADE_DATA[id].name+"  /  +20 HULL",3)
	if qa_mode: print("QA upgrade: "+id)

func spawn_core() -> void:
	if is_instance_valid(core_node): core_node.queue_free()
	core_node=Node3D.new(); add_child(core_node)
	var at := Vector3(-9 if player_position.x>0 else 9,0,-6 if player_position.z>0 else 6)
	core_node.position=at
	var ring_node := make_ring(1,Color("ffbe83")); core_node.add_child(ring_node)
	ring_node.position.y=0.1
	var jewel := MeshInstance3D.new()
	var mesh := PrismMesh.new(); mesh.size=Vector3(0.7,0.9,0.7)
	jewel.mesh=mesh; jewel.material_override=field.glow_material(Color("ffbe83"))
	jewel.position.y=1.1
	core_node.add_child(jewel)
	core_time=12
	ui.show_hint("BONUS CORE  /  Reach the amber beacon for hull repair and energy.",4)

func update_core(delta: float) -> void:
	if not is_instance_valid(core_node): return
	core_time-=delta
	core_node.rotation.y+=delta*1.6
	if player_position.distance_to(core_node.position)<1.2:
		rules.health=minf(100,rules.health+22)
		rules.energy=minf(100,rules.energy+20)
		rules.score+=150
		cue("core"); add_effect(core_node.position,Color("ffbe83"),2)
		core_node.queue_free(); core_node=null
		ui.show_hint("CORE SECURED  /  +22 HULL  +20 ENERGY",3)
	elif core_time<=0:
		core_node.queue_free(); core_node=null

func enemy_defeated(enemy: Node3D) -> void:
	var value := 80 if enemy.kind=="bruiser" else 45 if enemy.kind=="charger" else 30
	rules.register_kill(value)
	cue("guardian_break" if enemy.kind=="boss" else "machine_break",1.0 if enemy.kind=="boss" else 0.7)
	if enemy.kind=="boss":
		rules.score+=2500
		guardians_defeated+=1
		ending_delay=1.8
		field.clear.call_deferred()

func hit_player(amount: float, ground_hazard: bool = false) -> void:
	if rules.damage(amount,ground_hazard):
		if qa_mode:
			qa_damage_events.append({"time":run_time,"damage":amount,"ground":ground_hazard,"health":rules.health,"position":str(player_position)})
		shake=0.22
		cue("hit")
		add_effect(player_position,Color("ff6c7c"),1.5)

func finish(won: bool, retired: bool = false) -> void:
	if state=="result": return
	state="result"
	settings.best=maxi(int(settings.best),rules.score)
	if won: settings.won=true
	if not practice: save_settings()
	player_node.visible=true
	ui.show_result(won,{"score":rules.score,"best":settings.best,"kills":rules.kills,"absorbed":rules.absorbed,"pulses":rules.pulses,"time":run_time,"upgrades":rules.upgrades,"overdrive":hard_mode,"campaign":campaign_active,"relays":campaign.total_relays if campaign_active else 0,"sector":campaign.sector+1 if campaign_active else 0,"retired":retired,"seed":campaign.run_seed,"guardians":guardians_defeated,"weapon":Weapons.PROFILES[weapons.mode].name,"rank":Weapons.roman(weapons.tier())})
	cue("victory" if won or retired else "defeat")
	if qa_mode:
		write_qa(won)
		await get_tree().create_timer(0.6).timeout
		capture("result")
		get_tree().quit()

func cue(name: String, strength: float = 1.0) -> void:
	if sound and sound.has_method("play_cue"): sound.play_cue(name,strength)

func make_ring(radius: float, color: Color) -> MeshInstance3D: return field.ring(radius,color)
func add_effect(at: Vector3,color: Color,size: float) -> void: field.add_effect(at,color,size)
func add_trail(at: Vector3,color: Color,size: float) -> void: field.add_effect(at,color,size,0.23)
func hit_spark(at: Vector3,color: Color) -> void: field.spark(at,color)
func fire_volley(origin: Vector3,direction: Vector3,count: int,speed: float) -> void: field.fire(origin,direction,count,speed)
func add_hazard(at: Vector3,radius: float,warning: float) -> void: field.add_hazard(at,radius,warning)
func queue_volley(origin: Vector3,direction: Vector3,count: int,speed: float,delay: float) -> void:
	field.delayed.append({"kind":"volley","origin":origin,"direction":direction,"count":count,"speed":speed,"timer":delay})
func announce(title: String,subtitle: String) -> void: ui.show_banner(title,subtitle)

func pilot(delta: float) -> Vector3:
	# Deterministic test driver; it uses the same abilities/collision, never invulnerability.
	qa_jump_held = false
	if campaign_active and not campaign.boss_started:
		var destination := Vector3.ZERO
		var navigating := false
		if is_instance_valid(campaign.target):
			destination = campaign.target.position
			navigating = true
		elif campaign.gate_open:
			destination = Vector3(0,0,-14)
			navigating = true
		if navigating:
			var route: Vector3 = destination-player_position
			route.y = 0
			qa_jump_held = true
			if traversal.grounded and route.length()<6.2 and (not campaign.requires_glide() or traversal.fuel>=0.45): traversal.request_jump()
			if traversal.grounded and campaign.resolve_gates(player_position,player_position+route.normalized()).distance_to(player_position+route.normalized())>0.1:
				traversal.request_jump()
			if rules.energy>=40: pulse()
			return route.normalized() if route.length()>0.2 else Vector3.ZERO
	qa_dash_wait=maxf(0,qa_dash_wait-delta)
	var move := Vector3(cos(run_time*0.32),0,sin(run_time*0.32))
	var target: Node3D = null
	var distance := INF
	for enemy in enemies:
		if not enemy.dead:
			var d: float=Vector2(enemy.position.x-player_position.x,enemy.position.z-player_position.z).length()
			if d<distance: distance=d; target=enemy
	if target:
		var toward: Vector3=(target.position-player_position).normalized()
		toward.y=0
		toward=toward.normalized()
		move=toward.rotated(Vector3.UP,1.25)
		if distance>6: move=toward
		if distance<(4.5 if campaign_active and target.kind=="boss" else 3.0): move=-toward
	if absf(player_position.x)>11 or absf(player_position.z)>11:
		move=(-player_position).normalized()
	if is_instance_valid(core_node) and rules.health<80:
		move=(core_node.position-player_position).normalized()
	for hazard in field.hazards:
		if player_position.distance_to(hazard.node.position)<hazard.radius+1:
			move=(player_position-hazard.node.position).normalized()
			if campaign_active and not qa_passive and traversal.grounded and hazard.timer<0.55:
				traversal.request_jump()
	if not qa_passive:
		# React to the same visible, committed charger lane a player can read.
		for enemy in enemies:
			if enemy.dead or enemy.kind!="charger": continue
			if not (enemy.charge_time>0 or (enemy.windup>0 and enemy.windup<0.28)): continue
			var relative: Vector3=player_position-enemy.position
			var along: float=relative.dot(enemy.charge_direction)
			var across: Vector3=relative-enemy.charge_direction*along
			if along>0 and along<8 and across.length()<1.9:
				move=enemy.charge_direction.rotated(Vector3.UP,PI*0.5)
				if move.dot(player_position)>0: move=-move
				if rules.dash_charges>0 and rules.dash_time<=0 and qa_dash_wait<=0:
					facing=move; dash(); qa_dash_wait=0.45
		var bullet_distance:=INF
		var bullet_at:=Vector3.ZERO
		for bullet in field.bullets:
			var d:float=bullet.node.position.distance_to(player_position+Vector3(0,0.85,0))
			if d<bullet_distance: bullet_distance=d; bullet_at=bullet.node.position
		if bullet_distance<3.5 and player_position.y<1.0 and rules.dash_charges>0 and rules.dash_time<=0 and qa_dash_wait<=0:
			facing=(bullet_at-player_position).normalized(); facing.y=0
			facing=facing.normalized()
			if campaign_active and is_instance_valid(boss_ref):
				var near: Vector3=Geometry3D.get_closest_point_to_segment(boss_ref.position,Vector3(player_position.x,0,player_position.z),Vector3(player_position.x,0,player_position.z)+facing*5.4)
				if near.distance_to(boss_ref.position)<3.0:
					facing=(Vector3(player_position.x,0,player_position.z)-boss_ref.position).normalized()
			dash(); qa_dash_wait=0.45
		if rules.energy>=40 and distance<6.5: pulse()
		if campaign_active and is_instance_valid(boss_ref):
			var away: Vector3=Vector3(player_position.x,0,player_position.z)-boss_ref.position
			if away.length()<4.3: move=away.normalized()
	return move

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var directory := qa_output_dir+"/captures"
	DirAccess.make_dir_recursive_absolute(directory)
	image.save_png(directory+"/"+label+("-passive" if qa_passive else "")+".png")

func write_qa(won: bool) -> void:
	qa_render_frames.sort()
	var render_p95: Variant = null
	var render_median: Variant = null
	var render_p99: Variant = null
	if not qa_render_frames.is_empty():
		render_p95=qa_render_frames[int(qa_render_frames.size()*0.95)]
		render_median=qa_render_frames[int(qa_render_frames.size()*0.5)]
		render_p99=qa_render_frames[int(qa_render_frames.size()*0.99)]
	var segments: Dictionary={}
	for id in qa_segments:
		var samples: Array=qa_segments[id]
		samples.sort()
		segments[id]={"samples":samples.size(),"median_ms":samples[int(samples.size()*0.5)],"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)]}
	var report := {"win":won,"time":run_time,"score":rules.score,"health":rules.health,"kills":rules.kills,"absorbed":rules.absorbed,"pulses":rules.pulses,"upgrades":rules.upgrades,"passive":qa_passive,"simulation":qa_simulation,"accelerated":qa_fast,"render_frame_p95_ms":render_p95,"render_frame_median_ms":render_median,"render_frame_p99_ms":render_p99,"render_samples":qa_render_frames.size(),"segments":segments,"warmup_excluded_seconds":3,"settings":{"assist":settings.assist,"low_effects":settings.low_effects,"shake":settings.shake,"volume":settings.volume,"overdrive":hard_mode},"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"memory":OS.get_memory_info(),"os":OS.get_name()+" "+OS.get_version(),"viewport":str(get_viewport().get_visible_rect().size),"window_pixels":str(get_window().size)}
	report["weapons"] = {"equipped":weapons.mode,"ranks":weapons.ranks,"overclocks":weapons.overclocks,"shots":weapons.shots_fired,"hits":weapons.hits,"kills":weapons.kills}
	report["mode"] = "skybound" if campaign_active else "classic"
	if campaign_active:
		report["sector"] = campaign.sector+1
		report["run_seed"] = campaign.run_seed
		report["active_objects"] = {"enemies":enemies.size(),"projectiles":weapons.projectiles.size(),"fx":weapon_fx.counts(),"gates":campaign.gates.size(),"hazards":field.hazards.size(),"checkpoint_history":campaign.checkpoint_times.size()}
		report["guardians_defeated"] = guardians_defeated
		report["route"] = campaign.route_name()
		report["air_relays"] = campaign.total_relays
		report["sector_checkpoints"] = campaign.checkpoint_times
		report["boss_started"] = campaign.boss_started
		report["boss_entry"] = qa_boss_entry
		report["damage_events"] = qa_damage_events
		report["boss_health_remaining"] = boss_ref.hp if is_instance_valid(boss_ref) else 0.0
	print("QA_RESULT "+JSON.stringify(report))
	DirAccess.make_dir_recursive_absolute(qa_output_dir)
	var file := FileAccess.open(qa_output_dir+"/"+("passive" if qa_passive else "active")+"-metrics.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"  "))
