extends SceneTree
## Staged native UI/scene screenshots, not a playthrough or frame benchmark.

func _initialize() -> void: call_deferred("capture_states")

func capture_states() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode=true
	game.qa_output_dir=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-dir="): game.qa_output_dir=arg.trim_prefix("--qa-dir=")
	if game.qa_output_dir.is_empty():
		push_error("Provide -- --qa-dir=/absolute/output/directory for staged captures.")
		quit(1)
		return
	game.ui.show_title(0,false)
	await game.capture("staged-title")
	game.settings.won=true
	game.state="settings"
	game.ui.show_settings(game.settings,game.bindings)
	await game.capture("staged-settings-unlocked")
	game.ui.show_upgrades(["echo","collector","frost"])
	await game.capture("staged-upgrades")
	game.start_run(true)
	game.ui.show_practice_complete()
	await game.capture("staged-practice-complete")
	game.start_run(false)
	game.rules.energy=85
	game.rules.upgrades=["echo","radius","wake"]
	game.ui.hint.text=""
	game.ui.banner.text=""
	for item in [["charger",Vector3(6,0,-4)],["gunner",Vector3(-6,0,-6)],["bruiser",Vector3(-6,0,3)]]:
		var enemy=game.spawn_enemy(item[0],item[1])
		enemy.spawning=0
		enemy.model.scale=Vector3.ONE
		enemy.cooldown=0
		enemy.update(0.016)
	game.field.fire(Vector3(-6,0,-6),Vector3(1,0,1).normalized(),5,7.8)
	game.field.update(0.3)
	game.ui.update_game(game.rules,195,0,0,false)
	await game.capture("staged-combat")
	game.clear_run()
	game.player_node.position=Vector3(0,0,7)
	var boss=game.spawn_enemy("boss",Vector3(0,0,-5))
	boss.spawning=0
	boss.model.scale=Vector3.ONE
	boss.hp=boss.max_hp*0.45
	boss.update(0.016)
	game.field.fire(boss.position,Vector3.BACK,9,8.5)
	game.field.add_hazard(Vector3(-4,0,5),3.5,1.25)
	game.field.update(0.4)
	game.ui.update_game(game.rules,395,boss.hp,boss.max_hp,false)
	await game.capture("staged-boss")
	game.ui.show_result(true,{"score":12830,"best":12830,"kills":266,"absorbed":373,"pulses":102,"time":405.6,"upgrades":["ignite","echo","capacitor","siphon","chain"],"overdrive":false})
	await game.capture("staged-result")
	game.clear_run()
	game.queue_free()
	await process_frame
	print("Staged native visual captures complete. No user preferences saved.")
	quit()
