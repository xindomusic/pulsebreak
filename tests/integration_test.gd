extends SceneTree
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode=true
	check(game.ui.health_bar.size.y<=10,"health bar respects thin HUD geometry")
	print("HUD_BAR_SIZE ",game.ui.health_bar.size," min ",game.ui.health_bar.get_combined_minimum_size())
	game.start_run(false)
	check(game.state=="run" and game.rules.health==100,"start resets state")
	game.player_node.position=Vector3(4,0,0)
	game.player_previous=Vector3(-4,0,0)
	game.rules.try_dash()
	game.field.fire(Vector3(-3,0,0),Vector3.RIGHT,1,0)
	game.field.update(0.016)
	check(game.rules.absorbed==1,"swept dash absorbs a crossed projectile")
	check(game.field.bullets.is_empty(),"absorbed projectile leaves active collection")
	check(game.field.pool.size()==1,"projectile returned to pool")
	game.state="paused"
	var paused_time: float=game.run_time
	var paused_recharge: float=game.rules.dash_recharge
	game._physics_process(0.5)
	check(game.run_time==paused_time and game.rules.dash_recharge==paused_recharge,"pause freezes director and combat cooldown")
	game.state="run"
	game.run_time=59.99
	game.update_director(0.02)
	check(game.state=="upgrade" and game.upgrade_choices.size()==3,"minute checkpoint pauses for three upgrades")
	var choice: String=game.upgrade_choices[0]
	game.rules.health=50
	game.choose_upgrade(choice)
	check(game.state=="run" and game.rules.upgrades.has(choice),"upgrade applies and resumes")
	check(game.rules.health==70,"upgrade checkpoints repair hull for every build")
	game.field.fire(Vector3.ZERO,Vector3.RIGHT,3,3)
	game.run_time=359.99
	game.last_upgrade=5
	game.rules.health=50
	game.update_director(0.02)
	check(game.state=="boss" and game.enemies.size()==1,"boss replaces wave actors")
	check(game.field.bullets.is_empty(),"boss transition clears old projectiles")
	check(game.rules.health==75 and game.rules.energy>=30,"boss transition supplies recovery and charge")
	game.boss_ref.spawning=0
	game.boss_ref.hp=1
	game.boss_ref.take_hit(100,true)
	check(game.ending_delay>0 and game.rules.score>=2500,"boss defeat triggers victory delay")
	game.start_run(false)
	check(game.enemies.is_empty() and game.rules.upgrades.is_empty() and game.boss_ref==null,"restart clears actors and build")
	game.on_ui_action("settings",null)
	check(game.state=="settings","settings opens")
	game.on_ui_action("back",null)
	check(game.state=="paused","settings from active run safely returns paused")
	game.start_run(true)
	game.practice_step=3
	game.practice_timer=13
	game.update_practice(0.1)
	check(game.state=="practice_complete","practice finishes in dedicated completion screen")
	game.on_ui_action("start",null)
	check(game.state=="run" and not game.practice,"practice completion starts full challenge")
	game.bindings.pulse=KEY_Q
	game.configure_input()
	game.ui.update_game(game.rules,0,0,0,false)
	check(game.ui.energy_text.text.begins_with("Q"),"HUD reflects remapped pulse key")
	game.start_run(true)
	game.practice_step=2
	game.bindings.pulse=KEY_R
	game.configure_input()
	check(game.ui.hint.text.contains("R near"),"in-progress practice hint refreshes after remap")
	game.start_run(false)
	var charger=game.spawn_enemy("charger",Vector3(6,0,-4))
	charger.spawning=0; charger.cooldown=0
	charger.update(0.016)
	check(charger.warning_lane.visible,"charger exposes lane during windup")
	check(is_equal_approx(charger.warning_lane.get_node("LaneFill").mesh.size.x,2.14),"charger warning covers contact width")
	var saved_direction: Vector3=charger.charge_direction
	game.player_node.position=Vector3(-10,0,-10)
	charger.update(0.1)
	check(charger.charge_direction.is_equal_approx(saved_direction),"charger commits to the telegraphed lane")
	game.start_run(false)
	game.qa_mode=false
	game.facing=Vector3.FORWARD
	Input.action_press("right")
	game.dash()
	Input.action_release("right")
	game.qa_mode=true
	check(game.dash_direction.is_equal_approx(Vector3.RIGHT),"direction pressed immediately before dash is sampled without an old physics frame")
	game.start_run(false)
	charger=game.spawn_enemy("charger",Vector3(13,0,0))
	charger.spawning=0
	charger.charge_direction=Vector3(1,0,1).normalized()
	charger.charge_time=0.65
	charger.update(0.3)
	check(charger.charge_time==0 and is_equal_approx(charger.position.x,14.5) and is_equal_approx(charger.position.z,1.5),"charger stops at first wall rather than sliding beyond its warning")
	charger.position=Vector3.ZERO
	charger.charge_direction=Vector3.RIGHT
	charger.charge_time=0.65
	charger.slow=1.0
	charger.update(0.1)
	check(is_equal_approx(charger.position.x,0.7),"Static Field slows committed charger movement by fifty percent")
	game.qa_mode=false
	game.get_window().focus_exited.emit()
	check(game.state=="paused" and game.previous_state=="run","switching away pauses a live human run")
	game.qa_mode=true
	game.start_run(true)
	game.practice_step=2
	game.rules.energy=40
	game.pulse()
	game.update_practice(0.01)
	check(game.practice_step==2,"empty pulse does not complete the impact lesson")
	var lesson_target=game.spawn_enemy("gunner",Vector3(0,0,-3))
	game.rules.energy=40
	game.pulse()
	game.update_practice(0.01)
	check(game.practice_step==2,"pulse against a spawning immune target does not complete the lesson")
	lesson_target.spawning=0
	game.rules.energy=40
	game.pulse()
	game.update_practice(0.01)
	check(game.practice_step==3,"pulse damage to a real target completes the lesson")
	game.start_run(false)
	# Exercise the real result/save/restart route without touching a user's save.
	var store=load("res://scripts/save_store.gd")
	var original_path: String=store.save_path
	store.save_path="res://qa/integration-result-%d.json" % OS.get_process_id()
	game.qa_mode=false
	game.finish(true)
	check(game.state=="result" and store.load_data().won,"victory screen persists Overdrive unlock")
	game.on_ui_action("overdrive",true)
	check(store.load_data().overdrive,"Overdrive preference persists")
	game.qa_mode=true
	for attempt in range(3):
		game.on_ui_action("restart",null)
		check(game.state=="run" and game.hard_mode and game.enemies.is_empty() and game.rules.pulses==0,"repeated result restart resets a clean Overdrive run")
		game.spawn_enemy("gunner",Vector3(0,0,-8))
		game.field.fire(Vector3.ZERO,Vector3.RIGHT,3,4)
		game.clear_run()
		await process_frame
		check(game.field.bullets.is_empty() and game.field.hazards.is_empty(),"repeated restart clears hostile remnants")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_path))
	store.save_path=original_path
	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	print("Integration: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
