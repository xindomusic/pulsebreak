extends SceneTree
## Production campaign progression, objectives, transitions, and gate collisions.
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+description)

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = true
	game.start_campaign()
	var c = game.campaign
	check(game.campaign_active and c.sector==0 and game.state=="run","primary campaign starts in Skyport")
	check(c.relays==0 and c.gates.size()==1,"opening sector has tutorial relay and one gate")
	var target: Vector3 = c.target.position
	check(not c.target_crossed(Vector3(target.x,0,target.z-2),Vector3(target.x,0,target.z+2)),"walking below airborne relay cannot collect it")
	check(c.target_crossed(Vector3(target.x,1.7,target.z-2),Vector3(target.x,1.7,target.z+2)),"fast airborne crossing collects a target between endpoints")
	check(not c.target_crossed(Vector3(target.x+3,1.7,target.z-2),Vector3(target.x+3,1.7,target.z+2)),"flying beside relay does not award it")
	game.traversal.request_jump()
	game.traversal.step(0.3,true)
	var height: float=game.traversal.height
	var timer: float=c.elapsed
	game.state="paused"
	game._physics_process(0.5)
	check(is_equal_approx(game.traversal.height,height) and is_equal_approx(c.elapsed,timer),"pause freezes flight and moving gates")
	game.state="run"
	var blocked: Vector3=c.block_gate(Vector3(2,0,2),Vector3(2,0,-2),Vector3.ZERO,0)
	check(blocked.z>0.6,"closed gate blocks a swept ground dash")
	var flying: Vector3=c.block_gate(Vector3(2,2.4,2),Vector3(2,2.4,-2),Vector3.ZERO,0)
	check(flying.z==-2,"flight above the door clears a closed gate")
	var open: Vector3=c.block_gate(Vector3(0,0,2),Vector3(0,0,-2),Vector3.ZERO,1)
	check(open.z==-2,"open gate admits a grounded player through its center")
	game.player_node.position=Vector3(2,0,-1.7)
	c.gates[0].open=0.0
	c.gates[0].previous_open=0.0
	var sheltered=game.spawn_enemy("gunner",Vector3(2,3,-5.7))
	sheltered.spawning=0
	check(sheltered.position.y==0,"ground machines spawned from aerial positions still land on the deck")
	var hp: float=sheltered.hp
	game.auto_shoot()
	check(sheltered.hp==hp,"closed shutters block the player's automatic beam")
	game.player_node.position.y=2.8
	game.auto_shoot()
	check(sheltered.hp<hp,"flying above the shutter opens a real line of fire")
	game.clear_run()
	for index in range(3):
		target=c.target.position
		game.player_previous=Vector3(target.x,1.7,target.z+2)
		game.player_node.position=Vector3(target.x,1.7,target.z-2)
		c.update(0.016)
	check(c.relays==3 and c.total_relays==3,"all three ordered aerial relays advance through real collection path")
	check(not c.gate_open,"relay completion alone does not bypass combat objective")
	game.rules.kills=c.start_kills+4
	c.update(1.5)
	check(c.gate_open and c.exit_openness>0.8,"completed objectives visibly open the exit")
	game.player_node.position=Vector3(0,0,-13.5)
	c.update(0.016)
	check(game.state=="sector_complete" and c.completed,"player must enter gate to finish the sector")
	game.next_sector()
	check(c.sector==1 and game.state=="upgrade","travel enters second sector with an upgrade choice")
	check(c.total_relays==3 and c.relays==0 and game.traversal.grounded,"travel preserves total progress and resets local flight")
	game.choose_upgrade(game.upgrade_choices[0])
	check(game.state=="run" and game.rules.upgrades.size()==1,"installing upgrade resumes second-sector gameplay")
	c.relays=1
	c.create_target()
	target=c.target.position
	game.player_previous=Vector3(target.x,1.7,target.z+2)
	game.player_node.position=Vector3(target.x,1.7,target.z-2)
	game.traversal.gliding=false
	c.update(0.016)
	check(c.relays==1 and c.objective().contains("GLIDE"),"flight lesson explicitly requires deployed glide")
	check(game.ui.hint.text.contains("UNFOLD YOUR WINGS"),"near miss explains why ordinary jump did not collect glide relay")
	game.bindings.jump=KEY_J
	game.configure_input()
	check(c.target.get_node("RelayLabel").text.contains("HOLD J"),"required glide marker updates after remapping")
	c.hazard_clock=0
	c.update_route_hazards(0.016)
	check(game.field.hazards.size()==1 and game.field.hazards[0].warning>=1.35,"Foundry teaches flight over a single well-telegraphed pad")
	game.traversal.gliding=true
	c.update(0.016)
	check(c.relays==2,"deployed glide through relay completes flight lesson")
	game.clear_run()
	c.enter_sector(2)
	game.state="run"
	c.relays=1
	c.hazard_clock=0
	c.update_route_hazards(0.016)
	check(game.field.hazards.size()==2,"Storm combines two shock pads with a safe central lane")
	c.relays=0
	for index in range(3):
		target=c.target.position
		game.player_previous=Vector3(target.x,1.7,target.z+2)
		game.player_node.position=Vector3(target.x,1.7,target.z-2)
		c.update(0.016)
	check(game.state=="boss" and c.boss_started and game.enemies.size()==1,"final locks summon a single Guardian and clear wave enemies")
	check(game.field.bullets.is_empty() and game.rules.energy>=40,"final encounter supplies charge and clears stale projectiles")
	game.on_ui_action("restart",null)
	check(game.campaign_active and c.sector==0 and c.total_relays==0 and game.rules.upgrades.is_empty(),"campaign restart resets sectors, totals and build")
	game.on_ui_action("start",null)
	check(not game.campaign_active and game.state=="run" and c.get_child_count()==0,"classic mode remains independently playable without campaign obstacles")
	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	print("Campaign: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
