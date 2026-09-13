extends SceneTree
## Deliberately staged native renders from the actual game. The director is
## frozen; weapon, enemy, articulated model and FX clocks advance in fixed steps.
## These images demonstrate appearance/motion states, not a human playthrough.

var game: Node3D
var elapsed := 0.0
var evidence: Array[Dictionary] = []
var output := ""
var selection: PackedStringArray = []


func _initialize() -> void:
	call_deferred("review")


func review() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Visual review requires a native rendering window.")
		quit(1)
		return
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.qa_mode=true
	game.qa_simulation=true
	game.rng.seed=74921
	game.settings.shake=0.0
	game.settings.low_effects=false
	game.settings.volume=0.0
	game.weapon_fx.low_effects=false
	game.apply_settings()
	output=ProjectSettings.globalize_path("res://qa/overdrive-visual")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-dir="): output=arg.trim_prefix("--qa-dir=")
		if arg.begins_with("--review-only="): selection=arg.trim_prefix("--review-only=").split(",")
	game.qa_output_dir=output
	if not selection.is_empty():
		if "draft" in selection:
			game.start_campaign(74921)
			game.show_weapon_draft()
			await _capture("weapon-draft")
		if "generated" in selection: await _generated_stages()
		if "hit" in selection: await _hit_and_death()
		if "busy" in selection:
			await _busy_fight(false)
			await _busy_fight(true)
		await _finish_review()
		return
	await _capture("title")
	game.start_campaign(74921)
	game.show_weapon_draft()
	await _capture("weapon-draft")
	for mode: String in ["kinetic","scatter","arc","plasma"]:
		for rank: int in [1,3,5]:
			_reset_scene()
			game.ui.visible=false
			game.player_node.position=Vector3.ZERO
			game.player_previous=Vector3.ZERO
			game.weapons.ranks[mode]=rank
			game.weapons.mode=mode
			game.weapons.refresh_model()
			game.Art.aim_weapon(game.player_node,Vector3(0.28,0,1).normalized())
			_advance(0.12)
			game.camera.size=5.4
			game.camera.position=Vector3(2.8,3.0,6.6)
			game.camera.look_at(Vector3(0,1.05,0.25))
			await _capture("hero-%s-rank-%d-close" % [mode,rank])
			game.camera.size=10.0
			game.camera.position=Vector3(1.4,6.0,10.0)
			game.camera.look_at(Vector3(0,0.9,0.3))
			await _capture("hero-%s-rank-%d-mid" % [mode,rank])
		await _weapon_scene(mode)
	await _aim_scenes()
	await _hit_and_death()
	await _busy_fight(false)
	await _busy_fight(true)
	await _generated_stages()
	await _finish_review()


func _finish_review() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var saved: Array = evidence.duplicate()
	if not selection.is_empty() and FileAccess.file_exists(output+"/visual-evidence.json"):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(output+"/visual-evidence.json"))
		if previous is Dictionary:
			var labels: Array = evidence.map(func(entry: Dictionary) -> String: return entry.label)
			for entry: Dictionary in previous.get("captures",[]):
				if not entry.label in labels: saved.append(entry)
	var report := FileAccess.open(output+"/visual-evidence.json",FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({"kind":"staged_native_visual_review","engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"fixed_step_seconds":1.0/60.0,"captures":saved},"  "))
	game.clear_run()
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("Overdrive staged visual review: ",evidence.size()," captures in ",output,". No preferences saved.")
	quit()


func _reset_scene() -> void:
	game.start_run(false)
	game.set_physics_process(false)
	game.ui.visible=true
	game.ui.banner.text=""
	game.ui.hint.text=""
	game.ui.objective_text.text="STAGED COMBAT PRESENTATION / FIXED-STEP REVIEW"
	game.player_node.position=Vector3(-3.2,0,3.2)
	game.player_node.rotation.y=PI*0.65
	game.player_previous=game.player_position
	game.player_velocity=Vector3.ZERO
	game.rules.energy=68
	game.weapon_fx.low_effects=false
	game.settings.low_effects=false
	game.apply_settings()
	game.rng.seed=74921
	game.weapon_fx.rng.seed=541709
	elapsed=0.0


func _target(kind: String, at: Vector3, health: float = 500.0) -> Node3D:
	var target: Node3D = game.spawn_enemy(kind,at)
	target.spawning=0.0
	target.model.scale=Vector3.ONE
	target.hp=health
	target.max_hp=health
	target.cooldown=999.0
	target.speed=0.0
	target.telegraph.visible=false
	return target


func _advance(seconds: float) -> void:
	var remaining := seconds
	while remaining>0.00001:
		var delta := minf(1.0/60.0,remaining)
		game.rules.tick(delta)
		game.weapons.record_enemy_positions()
		for enemy: Node3D in game.enemies:
			if is_instance_valid(enemy): enemy.update(delta)
		game.weapons.update(delta)
		game.weapon_fx.update(delta)
		game.field.update(delta)
		elapsed+=delta
		game.Art.animate_player(game.player_node,delta,0.0,false,false,false,elapsed)
		remaining-=delta
	game.run_time=elapsed
	game.ui.update_game(game.rules,elapsed,0.0,0.0,false)
	game.ui.update_traversal(game.traversal)
	if game.campaign_active:
		game.ui.status_text.text="%02d / %s" % [game.campaign.sector+1,game.campaign.current_stage.name]
	if game.ui.has_method("update_weapon"):
		game.ui.update_weapon(game.weapons)


func _weapon_scene(mode: String) -> void:
	_reset_scene()
	game.weapons.ranks[mode]=3
	game.weapons.mode=mode
	game.weapons.refresh_model()
	var target := _target("gunner",Vector3(1,0,-2))
	_target("bruiser",Vector3(3.0,0,-2.2))
	_target("charger",Vector3(1.7,0,-4.0))
	game.ui.objective_text.text=game.Weapons.PROFILES[mode].name+" / RANK III / STAGED LIVE PROJECTILES"
	game.weapons.fire(target)
	var distance: float = game.Art.muzzle_position(game.player_node).distance_to(target.position+Vector3(0,0.85,0))
	var flight_time: float = distance/float(game.Weapons.PROFILES[mode].speed)
	_advance(0.025)
	await _capture(mode+"-muzzle")
	_advance(maxf(0.01,flight_time*0.48-0.025))
	await _capture(mode+"-in-flight")
	_advance(maxf(0.02,flight_time*0.52+0.005))
	await _capture(mode+"-contact")


func _aim_scenes() -> void:
	for direction: Vector3 in [Vector3.RIGHT,Vector3.FORWARD]:
		_reset_scene()
		game.ui.visible=false
		game.player_node.position=Vector3.ZERO
		game.player_node.rotation=Vector3.ZERO
		game.Art.aim_weapon(game.player_node,direction)
		_advance(0.10)
		game.camera.size=5.4
		game.camera.position=Vector3(3.0,3.5,6.0)
		game.camera.look_at(Vector3(0,1,0))
		await _capture("aim-rear" if direction==Vector3.FORWARD else "aim-side")


func _hit_and_death() -> void:
	_reset_scene()
	game.camera.size=14.0
	game.camera.position=Vector3(0,10,14)
	game.camera.look_at(Vector3(0,0.8,-0.5))
	var target := _target("bruiser",Vector3(0,0,-0.5),220.0)
	game.ui.objective_text.text="IMPACT / ARMOR FLASH, ARTICULATED REACTION, SPARKS"
	target.take_hit(30.0,true,Vector3(0.4,0,-1).normalized(),"plasma")
	await _capture("hit-000")
	_advance(0.08)
	await _capture("hit-080")
	_advance(0.12)
	await _capture("hit-200")
	game.ui.objective_text.text="DESTRUCTION / ORIGINAL ARMOR FRAGMENTS, CORE BURST, AFTERMATH"
	target.take_hit(1000.0,true,Vector3(0.4,0,-1).normalized(),"plasma")
	game.enemies.erase(target)
	target.queue_free()
	await process_frame
	_advance(0.08)
	await _capture("death-080")
	_advance(0.16)
	await _capture("death-240")
	_advance(0.36)
	await _capture("death-600")
	game.weapon_fx.low_effects=true
	game.settings.low_effects=true
	game.apply_settings()
	game.weapon_fx.impact(Vector3(0,1,0),Vector3.BACK,"arc",1.3)
	_advance(0.04)
	await _capture("low-effects-impact")


func _busy_fight(low: bool) -> void:
	_reset_scene()
	game.start_campaign(74921)
	game.campaign.enter_sector(4)
	game.ui.banner.text=""
	game.ui.hint.text=""
	game.ui.objective_text.text="MATCHED DENSITY SCENE / " + ("LOW EFFECTS" if low else "FULL EFFECTS")
	game.weapon_fx.low_effects=low
	game.settings.low_effects=low
	game.apply_settings()
	game.player_node.position=Vector3(-1,0,9)
	game.player_previous=game.player_position
	game.player_marker.position=Vector3(-1,0.06,9)
	game.player_marker.visible=true
	game.weapons.ranks.arc=5
	game.weapons.mode="arc"
	game.weapons.refresh_model()
	var specs: Array = [["gunner",Vector3(-10,0,-8)],["gunner",Vector3(9,0,-7)],["gunner",Vector3(-8,0,1)],["gunner",Vector3(8,0,2)],["charger",Vector3(-5,0,-4)],["charger",Vector3(5,0,-2)],["charger",Vector3(-6,0,6)],["charger",Vector3(6,0,7)],["bruiser",Vector3(3,0,9)],["bruiser",Vector3(-4,0,-1)],["gunner",Vector3(-11,0,-1)],["gunner",Vector3(10,0,0)]]
	var target: Node3D
	for spec: Array in specs:
		var enemy := _target(spec[0],spec[1],160.0)
		if spec[0]=="gunner": game.field.fire(enemy.position,(game.player_position-enemy.position).normalized(),7,7.8)
		if spec[0]=="charger": enemy.cooldown=0.01
		if enemy.position==Vector3(3,0,9): target=enemy
	var weak := _target("charger",Vector3(-2,0,0.5),10.0)
	game.field.add_hazard(Vector3(-2,0,4.2),2.4,1.0)
	game.campaign.update(0.38)
	_advance(0.16)
	game.weapons.fire(target)
	_advance(0.06)
	weak.take_hit(100.0,true,Vector3.BACK,"plasma")
	game.enemies.erase(weak)
	weak.queue_free()
	_advance(0.16)
	await _capture("busy-fight-low" if low else "busy-fight-full")
	game.settings.low_effects=false


func _generated_stages() -> void:
	for index: int in [3,4,6]:
		_reset_scene()
		game.start_campaign(74921)
		game.campaign.enter_sector(index)
		game.ui.banner.text=""
		game.ui.hint.text=""
		game.player_node.position=Vector3(0,1.8,8)
		game.player_previous=game.player_position
		game.traversal.height=1.8
		game.traversal.grounded=false
		game.traversal.gliding=true
		game.player_marker.visible=true
		game.player_marker.position=Vector3(0,0.06,8)
		_target("gunner",Vector3(5,0,-2))
		_target("charger",Vector3(-8,0,2))
		_target("bruiser",Vector3(8,0,7))
		game.campaign.update(0.35)
		_advance(0.35)
		for frame: int in range(30): game.Art.animate_player(game.player_node,1.0/60.0,1.0,true,true,false,float(frame)/60.0)
		game.ui.status_text.text="%02d / %s" % [index+1,game.campaign.current_stage.name]
		game.ui.objective_text.text=game.campaign.objective()
		game.ui.update_traversal(game.traversal)
		await _capture("generated-sector-%02d" % (index+1))


func _capture(label: String) -> void:
	await game.capture(label)
	evidence.append({"label":label,"simulation_seconds":elapsed,"weapon":game.weapons.mode,"rank":game.weapons.tier(),"weapon_projectiles":game.weapons.projectiles.size(),"enemy_projectiles":game.field.bullets.size(),"enemies":game.enemies.size(),"weapon_hits":game.weapons.hits,"fx":game.weapon_fx.counts(),"camera_size":game.camera.size,"sector":game.campaign.sector+1 if game.campaign_active else 0,"low_effects":bool(game.settings.low_effects),"shadows":game.key_light.shadow_enabled,"layout_seed":game.campaign.current_stage.get("layout_seed",0) if game.campaign_active else 0})
