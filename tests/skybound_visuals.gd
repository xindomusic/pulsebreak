extends SceneTree
## Deliberately staged native renders for visual review; never playthrough evidence.
func _initialize() -> void: call_deferred("capture_states")

func capture_states() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode=true
	game.qa_output_dir=ProjectSettings.globalize_path("res://qa/skybound-visuals")
	await game.capture("title")
	game.state="settings"
	game.settings.won=true
	game.ui.show_settings(game.settings,game.bindings)
	await game.capture("settings")
	game.start_campaign()
	for sector in range(3):
		game.clear_run()
		game.campaign.enter_sector(sector)
		game.ui.show_game()
		game.ui.hint.text=""
		game.ui.banner.text=""
		game.player_node.position=Vector3(-1,2.1,3)
		game.player_node.rotation.y=0.4
		game.traversal.height=2.1
		game.traversal.grounded=false
		game.traversal.gliding=true
		game.player_marker.position=Vector3(-1,0.06,3)
		game.player_marker.visible=true
		for frame in range(45):
			game.Art.animate_player(game.player_node,0.016,1.0,true,true,false,frame*0.016)
			game.Campaign.Visuals.animate_stage(game.campaign.stage,0.016,frame*0.016)
		for gate in game.campaign.gates: game.Campaign.Visuals.animate_gate(gate.node,0.45,1.0)
		for item in [["charger",Vector3(6,0,-2)],["gunner",Vector3(-7,0,-6)],["bruiser",Vector3(7,0,6)]]:
			var enemy=game.spawn_enemy(item[0],item[1])
			enemy.spawning=0
			enemy.model.scale=Vector3.ONE
			enemy.cooldown=0
			enemy.update(0.016)
		game.field.fire(Vector3(-7,0,-6),Vector3(1,0,1).normalized(),5,7)
		game.field.update(0.4)
		game.rules.energy=72
		game.ui.update_game(game.rules,sector*65.0+12.0,0,0,false)
		game.ui.update_traversal(game.traversal)
		game.ui.status_text.text="0%d / 03   %s" % [sector+1,game.Campaign.SECTORS[sector].name]
		game.ui.objective_text.text=game.campaign.objective()
		await game.capture("sector-%d-flight" % (sector+1))
		if sector==1:
			game.campaign.relays=1
			game.campaign.create_target()
			game.campaign.hazard_clock=0
			game.campaign.update_route_hazards(0.016)
			game.ui.objective_text.text=game.campaign.objective()
			await game.capture("foundry-glide-lesson")
		if sector==2:
			game.campaign.relays=1
			game.campaign.hazard_clock=0
			game.campaign.update_route_hazards(0.016)
			game.settings.low_effects=true
			game.apply_settings()
			await game.capture("storm-low-effects")
			game.settings.low_effects=false
			game.apply_settings()
	game.ui.show_sector_complete(0,"SKYPORT",64.0,3)
	await game.capture("sector-clear")
	game.ui.show_upgrades(["echo","collector","frost"])
	await game.capture("upgrades")
	game.ui.show_game()
	game.campaign.relays=3
	game.campaign.boss_started=true
	game.campaign.create_target()
	game.begin_campaign_boss()
	game.boss_ref.spawning=0
	game.boss_ref.model.scale=Vector3.ONE
	game.ui.banner.text=""
	game.ui.objective_text.text="FINAL OBJECTIVE  /  BREAK THE GUARDIAN"
	game.ui.update_game(game.rules,185,1500,1800,false)
	game.ui.status_text.text="03 / 03   STORM CORE"
	await game.capture("guardian")
	game.clear_run()
	game.queue_free()
	await process_frame
	quit()
