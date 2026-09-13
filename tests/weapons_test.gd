extends SceneTree
## Independent behavioral checks for projectiles, weapon roles and state boundaries.
## Fixtures control encounter geometry; these are not human feel or audio tests.
const Art = preload("res://scripts/art.gd")
var checks := 0
var failures := 0
var game

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+description)

func _initialize() -> void: call_deferred("run_checks")

func arena(mode: String = "kinetic", rank: int = 1) -> void:
	game.start_run(false)
	game.weapons.ranks[mode] = rank
	game.weapons.mode = mode
	game.weapons.refresh_model()
	game.player_node.position = Vector3.ZERO
	game.player_previous = Vector3.ZERO
	game.player_node.rotation = Vector3.ZERO

func machine(at: Vector3, hp: float = 500.0):
	var enemy = game.spawn_enemy("gunner",at)
	enemy.spawning = 0.0
	enemy.model.scale = Vector3.ONE
	enemy.hp = hp
	enemy.max_hp = hp
	return enemy

func settle(duration: float = 0.75) -> void:
	game.weapons.record_enemy_positions()
	for frame in range(ceili(duration*120.0)):
		game.weapons.update(1.0/120.0)
		game.weapon_fx.update(1.0/120.0)

func covered_arena(mode: String, rank: int = 1) -> void:
	arena(mode,rank)
	game.campaign_active = true
	game.campaign.start(713)
	game.player_node.position = Vector3(0,0,5)
	game.player_previous = game.player_position
	var gate: Dictionary = game.campaign.gates[0]
	gate.node.position = Vector3.ZERO
	gate.open = 0.0
	gate.previous_open = 0.0

func production_cadence(rank: int) -> float:
	arena("kinetic",rank)
	game.qa_mode=false
	game.auto_timer=0.0
	game.spawn_timer=999.0
	var target=machine(Vector3(0,0,8),5000.0)
	target.cooldown=999.0
	var previous_count: int=game.weapons.shots_fired
	var first_frame := -1
	for frame in range(90):
		game._physics_process(1.0/60.0)
		if game.weapons.shots_fired>previous_count:
			if first_frame>=0:
				game.qa_mode=true
				return float(frame-first_frame)/60.0
			first_frame=frame
			previous_count=game.weapons.shots_fired
	game.qa_mode=true
	return INF

func run_checks() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = true
	game.settings.overdrive = false
	arena()
	var w = game.weapons
	var enemy = machine(Vector3(0,0,7))
	check(w.fire(enemy),"a live visible machine accepts a carbine shot")
	check(enemy.hp==500 and w.projectiles.size()==1,"firing creates travel before damage instead of immediate laser damage")
	w.record_enemy_positions()
	w.update(0.02)
	check(enemy.hp==500,"a distant machine is not hit before the projectile reaches it")
	settle()
	check(enemy.hp<500 and w.projectiles.is_empty(),"carbine contact deals damage and consumes its projectile")
	var after_hit: float = enemy.hp
	settle()
	check(enemy.hp==after_hit,"an expired projectile cannot damage again")

	arena()
	enemy = machine(Vector3(0,0,8))
	check(w.fire(enemy),"range boundary fixture launches a valid projectile")
	# Move the intended victim beyond the complete projectile range before the
	# next step; this isolates range clipping from target acquisition distance.
	enemy.position.z = 14.0
	w.record_enemy_positions()
	w.update(0.5)
	check(enemy.hp==500 and w.projectiles.is_empty(),"a large final step cannot hit beyond remaining projectile range (hull=%s, shots=%s, remainder=%s)" % [enemy.hp,w.projectiles.size(),w.projectiles[0].range if not w.projectiles.is_empty() else 0])
	arena()
	enemy = machine(Vector3(0,0,15))
	check(not w.fire(enemy) and w.projectiles.is_empty(),"target acquisition rejects an out-of-range machine")

	arena()
	enemy = machine(Vector3(0,0,6))
	check(w.fire(enemy),"moving-target fixture launches toward the crossing lane")
	enemy.position.x = -3.0
	w.record_enemy_positions()
	enemy.position.x = 3.0
	w.update(0.3)
	check(enemy.hp<500,"swept projectile collision hits a machine crossing between frame endpoints")
	arena()
	enemy = machine(Vector3(0,0,6))
	w.fire(enemy)
	# Raise the whole flight path above a normal machine's body volume.
	var shot: Dictionary = w.projectiles[0]
	shot.node.position = Vector3(0,4,0)
	shot.velocity = Vector3(0,0,29)
	w.record_enemy_positions()
	w.update(0.3)
	check(enemy.hp==500,"horizontal crossing alone does not damage a machine below a projectile")
	arena()
	enemy = machine(Vector3(0,0,6))
	w.fire(enemy)
	shot = w.projectiles[0]
	shot.node.position = Vector3(0,0.85,0)
	shot.velocity = Vector3(0,0,29)
	shot.range = 2.0
	enemy.position = Vector3(-4,0,1.2)
	w.record_enemy_positions()
	enemy.position = Vector3(4,0,1.2)
	w.update(1.0)
	check(enemy.hp==500,"an enemy crossing after projectile range expiry is not compressed into the earlier collision interval")

	covered_arena("kinetic")
	enemy = machine(Vector3(0,0,-3))
	check(not w.fire(enemy) and w.projectiles.is_empty(),"closed visible shutters reject direct fire through cover")
	var gate: Dictionary = game.campaign.gates[0]
	gate.open = 1.0
	gate.previous_open = 1.0
	check(w.fire(enemy),"an open shutter permits projectile fire")
	gate.open = 0.0
	gate.previous_open = 0.0
	settle()
	check(enemy.hp==500 and w.projectiles.is_empty(),"a shutter closing during flight intercepts the existing projectile")
	game.player_node.position.y = 3.0
	w.cooldown = 0.0
	check(w.fire(enemy),"a physically clear airborne line can fire above a low shutter")
	settle()
	check(enemy.hp<500,"airborne cover clearance still produces a real projectile hit")

	arena("scatter")
	var center = machine(Vector3(0,0,8))
	var left = machine(Vector3(-1.2,0,8))
	var right = machine(Vector3(1.2,0,8))
	var outside = machine(Vector3(3.5,0,8))
	w.fire(center)
	settle()
	check(center.hp<500 and left.hp<500 and right.hp<500,"scatter fire damages a central machine and both flanks in its cone")
	check(outside.hp==500,"scatter fire does not damage a machine beyond its visible cone")

	arena("kinetic",1)
	var front = machine(Vector3(0,0,5))
	var rear = machine(Vector3(0,0,7))
	w.fire(front)
	settle()
	check(front.hp<500 and rear.hp==500,"base carbine stops on its first machine")
	arena("kinetic",3)
	front = machine(Vector3(0,0,5))
	rear = machine(Vector3(0,0,7))
	w.fire(front)
	settle()
	check(front.hp<500 and rear.hp<500,"rankIII carbine penetrates to a second aligned machine")
	arena("plasma",1)
	var row: Array = []
	for z in [6,8,10,12]: row.append(machine(Vector3(0,0,z)))
	w.fire(row[0])
	settle(1.0)
	check(row[0].hp<500 and row[1].hp<500 and row[2].hp<500 and row[3].hp==500,"base plasma pierces a line of three machines and then stops")

	arena("arc",1)
	row.clear()
	for x in [0,2,4,6]: row.append(machine(Vector3(x,0,5)))
	w.fire(row[0])
	settle()
	check(row[0].hp<500 and row[1].hp<500 and row[2].hp<500 and row[3].hp==500,"base arc branches through two nearby additional machines")
	covered_arena("arc")
	front = machine(Vector3(0,0,1.5))
	rear = machine(Vector3(0,0,-1.5))
	w.fire(front)
	settle()
	check(front.hp<500 and rear.hp==500,"arc links respect a closed shutter between adjacent machines")
	covered_arena("plasma",3)
	front = machine(Vector3(0,0,0.8))
	rear = machine(Vector3(0,0,-0.8))
	var neighbor = machine(Vector3(1.1,0,0.8))
	w.blast(Vector3(0,0.85,0.8),{"mode":"plasma","tier":3,"damage":100.0},front)
	check(neighbor.hp<500 and rear.hp==500,"upgraded splash damages a nearby exposed machine while respecting closed cover")

	arena()
	enemy = machine(Vector3(0,0,7))
	w.ranks.arc = 1
	w.fire(enemy)
	var pending_reload: float = w.cooldown
	check(w.cycle() and w.mode=="arc" and is_equal_approx(w.cooldown,pending_reload),"cycling owned weapons preserves the current reload")
	check(not w.fire(enemy),"weapon cycling cannot bypass reload with an immediate second shot")
	settle()
	check(w.fire(enemy),"the newly equipped weapon fires after reload finishes")
	check(game.player_node.get_meta("weapon_mode")=="arc","equipped weapon state reaches the visible courier model")
	w.clear_projectiles()
	w.ranks={"kinetic":1,"scatter":0,"arc":0,"plasma":0}
	w.mode="kinetic"
	check(not w.cycle(),"cycling with only one owned weapon is a safe no-op")

	arena()
	enemy = machine(Vector3(0,0,6))
	neighbor = machine(Vector3(4,0,6))
	w.fire(enemy)
	w.record_enemy_positions()
	w.update(0.3)
	check(enemy.flash_active and enemy.hit_reaction>0 and not neighbor.flash_active,"projectile contact starts a localized reaction without flashing another machine")
	enemy.update(0.016)
	var body: Node3D = enemy.model.get_node("Body")
	check(body.rotation.length()>0.001,"a nonlethal contact drives articulated body recoil")
	enemy.update(0.12)
	var restored := true
	for part: Dictionary in enemy.flash_parts:
		restored = restored and part.node.material_overlay==part.original
	check(not enemy.flash_active and restored,"brief contact flash restores each original material overlay")
	arena()
	enemy = machine(Vector3(0,0,6),1.0)
	w.fire(enemy)
	settle(0.3)
	check(enemy.dead and not enemy.model.visible and not enemy.telegraph.visible and game.rules.kills==1,"lethal projectile contact replaces the live machine and warning with a single registered kill")
	var death_effects: int = game.weapon_fx.active.size()
	enemy.take_hit(100,false)
	check(game.rules.kills==1 and game.weapon_fx.active.size()==death_effects,"a dead machine cannot repeat kill rewards or destruction effects")
	game.enemies.erase(enemy)
	enemy.queue_free()
	await process_frame
	var surviving_debris := false
	for effect: Dictionary in game.weapon_fx.active:
		if effect.style=="debris" and is_instance_valid(effect.node): surviving_debris=true
	check(surviving_debris,"destruction fragments survive removal of their source enemy")
	game.weapon_fx.update(2.0)
	check(game.weapon_fx.active.is_empty(),"destruction fragments and smoke expire after their bounded lifetime")

	arena()
	game.rules.health = 40
	for index in range(35): w.install("kinetic")
	check(w.tier()==5 and w.overclocks==10 and game.rules.health<=100,"repeated upgrades cap rank and overclock while servicing hull safely")
	var before_rank: int = w.tier()
	check(not w.install("invalid") and w.tier()==before_rank,"invalid weapon upgrades cannot corrupt the build")
	var options: Array = w.draft(game.rng)
	check(options.size()==3 and options.has(w.mode) and options[0]!=options[1] and options[0]!=options[2] and options[1]!=options[2],"drafts remain usable distinct choices after the equipped weapon is capped")

	arena()
	enemy = machine(Vector3(0,0,8),10000)
	for index in range(100):
		w.cooldown=0
		w.fire(enemy)
	check(w.projectiles.size()==w.MAX_PROJECTILES,"rapid fire saturates the projectile budget without allocating unbounded shots")
	w.cooldown=0
	check(not w.fire(enemy) and w.projectiles.size()==w.MAX_PROJECTILES,"a saturated projectile pool rejects further shots cleanly")
	w.clear_projectiles()
	check(w.projectiles.is_empty() and w.previous_enemies.is_empty(),"clearing projectiles removes active and previous-position state")

	arena("arc",3)
	enemy = machine(Vector3(0,0,7))
	w.fire(enemy)
	var at: Vector3 = w.projectiles[0].node.position
	var remaining: float = w.cooldown
	var fx_time: float = game.weapon_fx.elapsed
	game.state="paused"
	game._physics_process(0.75)
	check(w.projectiles.size()==1 and w.projectiles[0].node.position.is_equal_approx(at) and is_equal_approx(w.cooldown,remaining),"pause freezes projectile travel and reload through the production game callback")
	check(is_equal_approx(game.weapon_fx.elapsed,fx_time),"pause also freezes combat effect time")
	game.clear_run()
	check(w.projectiles.is_empty() and game.weapon_fx.active.is_empty(),"run cleanup removes travelling shots and active impact effects")
	check(w.mode=="arc" and w.tier()==3,"transient cleanup preserves equipped weapon and rank for travel")
	game.start_run(false)
	check(w.mode=="kinetic" and w.tier()==1 and w.ranks.arc==0 and w.overclocks==0,"starting a fresh run resets weapon ownership and progression")
	var base_cadence := production_cadence(1)
	var evolved_cadence := production_cadence(5)
	check(absf(base_cadence-0.28)<=1.0/60.0+0.001,"production autofire meets the advertised base cadence within one physics step (actual=%s)" % base_cadence)
	check(evolved_cadence<base_cadence-0.001,"rankV cadence improvement survives production target-acquisition scheduling (base=%s, rankV=%s)" % [base_cadence,evolved_cadence])

	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	print("Weapons: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
