extends SceneTree
## Handoff fixtures exercise production transitions; they are not combat playthroughs.
const Store = preload("res://scripts/save_store.gd")
var game: Node3D
var checks := 0
var failures := 0
var fixture := ""

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+description)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--quit-screen="):
			call_deferred("run_quit_child",argument.trim_prefix("--quit-screen="))
			return
	call_deferred("run_checks")

func find_button(node: Node, needle: String) -> Button:
	if node is Button and node.text.to_upper().contains(needle.to_upper()): return node
	for child in node.get_children():
		var found := find_button(child,needle)
		if found: return found
	return null

func continue_button() -> Button:
	var found := find_button(game.ui.modal,"DIVE")
	if not found: found=find_button(game.ui.modal,"CONTINUE")
	return found

func finish_guardian_at(index: int) -> void:
	game.clear_run()
	game.campaign.enter_sector(index)
	game.state = "run"
	game.campaign.relays = game.campaign.relay_goal()
	game.campaign.create_target()
	game.campaign.update(0.016)
	check(game.state=="boss" and is_instance_valid(game.boss_ref),"sector%d objective completion starts its guardian encounter" % (index+1))
	if not is_instance_valid(game.boss_ref): return
	game.boss_ref.spawning = 0.0
	game.boss_ref.take_hit(game.boss_ref.hp+1.0,true)
	check(game.ending_delay>0.0,"guardian damage uses the real defeat callback and conclusion delay")
	game._physics_process(2.0)
	await process_frame
	check(game.state=="sector_complete" and game.campaign.boss_defeated,"guardian conclusion reaches an extraction checkpoint instead of ending the campaign")

func resolve_drafts() -> void:
	check(game.state=="weapon_upgrade" and game.weapon_choices.size()==3,"continuation offers three real weapon choices")
	if game.state!="weapon_upgrade" or game.weapon_choices.is_empty(): return
	var chosen: String = game.weapon_choices[0]
	game.on_ui_action("weapon_upgrade",chosen)
	if game.state=="upgrade": game.on_ui_action("upgrade",game.upgrade_choices[0])
	check(game.state=="run","weapon and reactor selection returns to active play")

func run_checks() -> void:
	fixture = "res://qa/endless-settings-%d.json" % OS.get_process_id()
	var original_save: String = Store.save_path
	Store.save_path = fixture
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = false
	game.start_campaign(12345)
	for i in range(3): game.weapons.install("plasma")
	game.rules.apply_upgrade("echo")
	game.rules.apply_upgrade("radius")
	game.campaign.total_relays = 9
	var ranks_before: Dictionary = game.weapons.ranks.duplicate()
	var upgrades_before: Array = game.rules.upgrades.duplicate()
	await finish_guardian_at(2)
	check(game.guardians_defeated==1 and game.campaign.run_seed==12345,"first guardian completion preserves the seeded run and records its defeat")
	check(game.weapons.ranks==ranks_before and game.rules.upgrades==upgrades_before,"guardian conclusion preserves weapon ranks and reactor build")
	var next := continue_button()
	check(next!=null,"guardian checkpoint exposes a continuation button")
	if next: next.pressed.emit()
	check(game.campaign.sector==3 and game.campaign.current_stage.generated and game.state=="weapon_upgrade","the third sector continues into the first generated fourth sector")
	check(game.campaign.total_relays==9 and game.campaign.run_seed==12345 and game.weapons.ranks==ranks_before,"generated handoff keeps seed, collected relays and weapon investment")
	check(game.rules.upgrades==upgrades_before and game.weapons.projectiles.is_empty() and game.weapon_fx.active.is_empty(),"travel keeps reactor upgrades and clears old projectiles and debris")
	var draft_time: float = game.run_time
	game._physics_process(0.5)
	check(game.state=="weapon_upgrade" and game.run_time==draft_time,"the weapon draft pauses gameplay time without the QA pilot choosing automatically")
	game.choose_weapon("invalid-offer")
	check(game.state=="weapon_upgrade","an invalid weapon offer cannot bypass the draft")
	resolve_drafts()
	check(game.weapons.ranks.plasma==4 and game.rules.upgrades.size()==3,"checkpoint choices actually improve the carried weapon and reactor build")
	await finish_guardian_at(5)
	check(game.guardians_defeated==2 and game.campaign.sector==5,"a second guardian checkpoint is reachable in the same run")
	var bank := find_button(game.ui.modal,"BANK")
	check(bank!=null,"guardian checkpoint offers banking instead of forcing another sector")
	if bank: bank.pressed.emit()
	check(game.state=="result" and Store.load_data().won,"banking a guardian run produces a saved result and victory unlock")
	var banked_seed: int = game.campaign.run_seed
	game.on_ui_action("restart",null)
	check(game.campaign.run_seed==banked_seed and game.campaign.sector==0,"run restart reuses the shown seed for reproducible routes")
	check(game.weapons.ranks=={"kinetic":1,"scatter":0,"arc":0,"plasma":0} and game.rules.upgrades.is_empty() and game.guardians_defeated==0,"restart clears ranks, reactor upgrades and guardian count")
	game.rng.seed = 555
	game.on_ui_action("title",null)
	game.on_ui_action("campaign",null)
	check(game.campaign.run_seed!=banked_seed and game.campaign.sector==0,"starting a new run from the title chooses a new seed")
	await finish_guardian_at(5)
	next = continue_button()
	if next: next.pressed.emit()
	check(game.campaign.sector==6 and game.campaign.theme_index==0 and game.campaign.current_stage.generated,"the sixth sector continues into generated sector seven with a cycled theme")
	resolve_drafts()

	# Exhaustion is a normal endless-run state, not a reason to show an empty UI.
	game.start_campaign(991)
	for id in game.Rules.UPGRADE_DATA: game.rules.apply_upgrade(id)
	game.show_weapon_draft()
	game.rules.health = 50.0
	game.rules.energy = 10.0
	game.choose_weapon(game.weapon_choices[0])
	check(game.state=="run" and game.rules.upgrades.size()==9,"all nine reactor upgrades exhausted still returns to play after weapon selection")
	check(game.rules.health==70.0 and game.rules.energy==35.0 and game.weapons.ranks.kinetic==2,"exhausted reactor draft services resources while the weapon still gains a rank")
	for id in game.Weapons.PROFILES: game.weapons.ranks[id]=5
	game.weapons.overclocks = 10
	game.rules.health = 30.0
	game.rules.energy = 0.0
	game.show_weapon_draft()
	var service_choice: String = game.weapon_choices[0]
	check(game.weapons.offer(service_choice).action.contains("SERVICE"),"a fully ranked and overclocked arsenal offers a useful service choice")
	game.choose_weapon(service_choice)
	check(game.state=="run" and game.rules.health==80.0 and game.rules.energy==25.0,"maximum weapon service and exhausted reactor service apply then resume play")
	check(game.weapons.overclocks==10 and game.weapons.tier()==5,"late-run services preserve weapon and overclock caps")

	game.start_run(false)
	game.run_time = 59.99
	game.update_director(0.02)
	check(not game.campaign_active and game.state=="weapon_upgrade","classic minute checkpoints use the weapon draft without entering campaign mode")
	resolve_drafts()
	check(not game.campaign_active and game.last_upgrade==1 and game.run_time>=60.0,"classic draft completion preserves its survival timer and checkpoint index")
	game.start_run(false)
	var target: Node3D = game.spawn_enemy("gunner",Vector3(0,0,-5))
	target.spawning = 0.0
	game.auto_shoot()
	check(not game.weapons.projectiles.is_empty() and not game.weapon_fx.active.is_empty(),"pause fixture contains a real travelling player shot and muzzle effects")
	var shot_position: Vector3 = game.weapons.projectiles[0].node.position
	var reload: float = game.weapons.cooldown
	var effect_clock: float = game.weapon_fx.elapsed
	game.previous_state = "run"
	game.state = "paused"
	game.ui.show_pause()
	game._physics_process(0.5)
	check(game.weapons.projectiles[0].node.position==shot_position and game.weapons.cooldown==reload and game.weapon_fx.elapsed==effect_clock,"pause freezes projectile travel, weapon reload and combat effects together")
	game.on_ui_action("resume",null)
	game._physics_process(0.016)
	check(game.weapons.projectiles[0].node.position!=shot_position and game.weapons.cooldown<reload and game.weapon_fx.elapsed>effect_clock,"resuming advances both projectiles and combat effects")

	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	Store.save_path = original_save
	# Execute the actual quit buttons in isolated engine processes. If a button
	# doesn't terminate its process, the child explicitly fails on the next frame.
	for screen in ["title","pause","result","checkpoint"]:
		var output: Array = []
		var result := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),"--quit-after","6000","--script","res://tests/endless_test.gd","--","--quit-screen="+screen]),output,true)
		var log := "\n".join(output)
		check(result==0 and log.contains("QUIT_CALLBACK:"+screen) and not log.contains("FAIL:") and not log.contains("SCRIPT ERROR"),"the %s quit button terminates an isolated real engine process" % screen)
		if result!=0 or log.contains("FAIL:") or log.contains("SCRIPT ERROR"): print(log)
	print("Endless handoffs: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func run_quit_child(screen: String) -> void:
	fixture = "res://qa/endless-quit-%d.json" % OS.get_process_id()
	Store.save_path = fixture
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = false
	match screen:
		"title": game.on_ui_action("title",null)
		"pause":
			game.start_campaign(42)
			game.previous_state = "run"
			game.state = "paused"
			game.ui.show_pause()
		"result":
			game.start_campaign(42)
			game.finish(false)
		"checkpoint":
			game.start_campaign(42)
			game.complete_sector()
	var button := find_button(game.ui.modal,"QUIT")
	if not button or button.disabled:
		push_error("FAIL: missing usable quit button on "+screen)
		quit(1)
		return
	game.qa_mode = true
	if FileAccess.file_exists(fixture): DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	print("QUIT_CALLBACK:"+screen)
	button.pressed.emit()
	await process_frame
	push_error("FAIL: quit callback did not exit on "+screen)
	quit(1)
