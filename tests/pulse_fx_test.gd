extends SceneTree
## Pulse geometry and lifecycle checks. Native captures assess appearance.
const FX = preload("res://scripts/combat_fx.gd")
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+description)

func _initialize() -> void:
	call_deferred("run_checks")

func layer(fx: Node, style: String) -> Dictionary:
	for entry: Dictionary in fx.active:
		if entry.style==style: return entry
	return {}

func snapshot(fx: Node) -> String:
	var data: Array = [fx.elapsed]
	for entry: Dictionary in fx.active:
		data.append([entry.life,entry.node.global_transform,entry.node.transparency,entry.node.visible])
	return var_to_str(data)

func geometry_inside(fx: Node, at: Vector3, radius: float) -> bool:
	var vertices_checked := 0
	for entry: Dictionary in fx.active:
		if not entry.node.visible: continue
		var node: MeshInstance3D = entry.node
		for vertex: Vector3 in node.mesh.get_faces():
			vertices_checked+=1
			if (node.global_transform*vertex).distance_to(at)>radius+0.002: return false
	return vertices_checked>0

func target(game: Node, at: Vector3) -> Node3D:
	var enemy: Node3D = game.spawn_enemy("gunner",at)
	enemy.spawning=0.0
	enemy.hp=500.0
	enemy.max_hp=500.0
	enemy.cooldown=100.0
	return enemy

func integration_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode=false
	game.settings.overdrive=false
	game.settings.low_effects=false
	game.start_run(false)
	game.apply_settings()
	var inside := target(game,Vector3(5.96,0,0))
	var outside := target(game,Vector3(6.0,0,0))
	var spawning := target(game,Vector3(1,0,0))
	spawning.spawning=0.5
	game.rules.energy=30.0
	var field_effects: int = game.field.effects.size()
	game.pulse()
	check(is_equal_approx(inside.hp,448.4) and is_equal_approx(outside.hp,500.0),"production pulse preserves damage and enemy-body overlap at the original radius boundary")
	check(is_equal_approx(spawning.hp,500.0),"new pulse visuals do not damage enemies during their arrival warning")
	check(game.rules.energy==0 and game.rules.pulses==1,"production pulse spends energy exactly once")
	check(is_equal_approx(layer(game.weapon_fx,"pulse_front").radius,5.32),"production VFX receives the real spent-power radius")
	check(game.field.effects.size()==field_effects,"the new pulse replaces the previous generic expanding-ring effects")
	game.clear_run()
	game.rules.upgrades.append("radius")
	inside=target(game,Vector3(11.97,0,0))
	outside=target(game,Vector3(12.02,0,0))
	game.pulse_at(Vector3.ZERO,100)
	check(is_equal_approx(inside.hp,391.0) and is_equal_approx(outside.hp,500.0),"radius upgrade keeps the same production damage boundary")
	check(is_equal_approx(layer(game.weapon_fx,"pulse_front").radius,11.34),"radius upgrade is passed to all pulse layers")
	game.clear_run()
	inside=target(game,Vector3(3,0,0))
	game.pulse_at(Vector3.ZERO,100,true)
	check(is_equal_approx(inside.hp,450.95),"echo preserves45percent production damage")
	check(layer(game.weapon_fx,"pulse_front").echo and is_equal_approx(layer(game.weapon_fx,"pulse_front").radius,11.34),"production echo changes presentation without reducing its damage radius")
	game.clear_run()
	game.rules.upgrades.clear()
	inside=target(game,Vector3(4,0,0))
	outside=target(game,Vector3(5.5,0,0))
	game.pulse_at(Vector3(0,3.2,0),30)
	check(is_equal_approx(inside.hp,448.4) and is_equal_approx(outside.hp,500.0),"airborne production pulse retains three-dimensional damage distance")
	check(layer(game.weapon_fx,"pulse_front").base.x<5.32,"airborne production effect projects a smaller shock circle onto the floor")
	game.clear_run()
	game.pulse_at(Vector3.ZERO,100)
	game.auto_timer=100
	game.spawn_timer=100
	game._physics_process(0.02)
	check(game.pulse_light.visible and game.pulse_light.light_energy>0,"production discharge activates its bounded local light")
	var frozen := snapshot(game.weapon_fx)
	var light_time: float = game.pulse_light_time
	var light_energy: float = game.pulse_light.light_energy
	game.previous_state="run"
	game.state="paused"
	game._physics_process(0.75)
	check(snapshot(game.weapon_fx)==frozen and game.pulse_light_time==light_time and game.pulse_light.light_energy==light_energy,"production pause freezes pulse meshes and the matching light envelope together")
	game.settings.low_effects=true
	game.apply_settings()
	check(not game.pulse_light.visible and game.weapon_fx.low_effects,"switching to Low Effects while paused hides the optional pulse light immediately")
	game.on_ui_action("resume",null)
	game._physics_process(0.04)
	check(game.pulse_light_time<light_time and snapshot(game.weapon_fx)!=frozen,"production resume advances pulse and light time again")
	game.settings.low_effects=false
	game.apply_settings()
	game.clear_run()
	check(game.weapon_fx.active.is_empty() and game.pulse_light_time==0.0 and not game.pulse_light.visible and game.pulse_light.light_energy==0.0,"transition cleanup removes pulse layers and resets the local light")
	game.pulse_at(Vector3.ZERO,100)
	game.start_run(false)
	check(game.weapon_fx.active.is_empty() and not game.pulse_light.visible and game.pulse_light_time==0.0,"fresh runs cannot inherit a previous pulse or flash")
	game.clear_run()
	game.free()

func run_checks() -> void:
	var fx := FX.new()
	root.add_child(fx)
	fx.pulse(Vector3.ZERO,100,8.4)
	check(fx.active.size()==9,"a charged pulse composes nine pooled mesh layers")
	check(layer(fx,"pulse_core").node.visible and layer(fx,"pulse_front").node.visible,"core and shock give immediate confirmation at damage time")
	check(layer(fx,"pulse_boundary").essential and layer(fx,"pulse_boundary").node.visible,"the true radius is visible before the expanding front reaches it")
	check(not layer(fx,"pulse_shards").node.visible and not layer(fx,"pulse_after").node.visible,"delayed layers do not flash at full size on their creation frame")
	var above_deck := true
	var gather_node: MeshInstance3D = layer(fx,"pulse_gather").node
	for vertex: Vector3 in gather_node.mesh.get_faces():
		above_deck=above_deck and (gather_node.global_transform*vertex).y>0.055
	check(above_deck,"gathering filaments clear the flush deck paint instead of disappearing inside it")
	var gather_start: float = layer(fx,"pulse_gather").node.scale.x
	var core_start: float = layer(fx,"pulse_core").node.scale.x
	fx.update(0.045)
	check(layer(fx,"pulse_gather").node.scale.x<gather_start,"energy filaments travel inward during gathering")
	check(layer(fx,"pulse_core").node.scale.x>core_start,"the core peaks sharply during the first45ms")
	check(layer(fx,"pulse_shards").node.visible,"sculpted radial shards follow the initial impact")
	fx.update(0.04)
	check(layer(fx,"pulse_gather").is_empty(),"inward streaks expire before the outward shock settles")
	check(layer(fx,"pulse_arcs").node.visible,"broken violet arcs join the discharge after its core")
	fx.update(0.135)
	var front: Dictionary = layer(fx,"pulse_front")
	check(is_equal_approx(front.node.scale.x,front.base.x),"the ground shock reaches its actual radius at220ms")
	check(layer(fx,"pulse_core").is_empty() and layer(fx,"pulse_after").node.visible,"the bright core gives way to a restrained aftermath")
	fx.update(0.24)
	check(fx.active.size()==1 and fx.active[0].style=="pulse_after","only the fading aftermath remains after460ms")
	var aftermath_alpha: float = fx.active[0].node.transparency
	fx.update(0.15)
	check(fx.active[0].node.transparency>aftermath_alpha,"aftermath visibility fades monotonically")
	fx.update(0.22)
	check(fx.active.is_empty(),"all charged pulse layers expire within820ms")
	fx.clear()
	fx.pulse(Vector3.ZERO,30,5.32)
	var weak_size: float = layer(fx,"pulse_core").base.x
	var weak_brightness: float = layer(fx,"pulse_front").opacity
	var weak_layers: int = fx.active.size()
	fx.clear()
	fx.pulse(Vector3.ZERO,100,5.32)
	check(layer(fx,"pulse_core").base.x>weak_size and layer(fx,"pulse_front").opacity>weak_brightness,"spent energy strengthens core size and shock visibility independently of radius")
	check(fx.active.size()>weak_layers,"high power adds a distinct warm peak crown")
	var full_size: float = layer(fx,"pulse_core").base.x
	var full_brightness: float = layer(fx,"pulse_front").opacity
	var full_radius: float = layer(fx,"pulse_front").base.x
	fx.clear()
	fx.pulse(Vector3.ZERO,100,5.32,true)
	check(fx.active.size()==6 and layer(fx,"pulse_core").base.x<full_size,"echo is a smaller core with fewer layers")
	check(layer(fx,"pulse_front").opacity<full_brightness,"echo has lower visual intensity")
	check(is_equal_approx(layer(fx,"pulse_front").base.x,full_radius),"weaker echo still communicates its unchanged actual damage radius")
	fx.update(0.60)
	check(fx.active.is_empty(),"echo aftermath is shorter than the main discharge")
	fx.clear()
	fx.low_effects=true
	fx.pulse(Vector3.ZERO,100,8.4)
	check(fx.active.size()==6,"Low Effects keeps a compact six-layer pulse")
	check(layer(fx,"pulse_core").essential and layer(fx,"pulse_front").essential and layer(fx,"pulse_boundary").essential,"Low Effects preserves essential hit and radius cues")
	fx.low_effects=false
	var all_inside := true
	var ground_projection := true
	for origin: Vector3 in [Vector3.ZERO,Vector3(2,3.2,-4),Vector3(0,12,0)]:
		for radius: float in [0.01,5.32,11.34]:
			fx.clear()
			fx.pulse(origin,100,radius)
			var ground_front: Dictionary = layer(fx,"pulse_front")
			if origin.y==3.2 and radius>3.2:
				ground_projection = ground_projection and ground_front.base.x<radius and is_equal_approx(ground_front.origin.y,0.075)
			elif origin.y==12.0 and radius<12.0:
				ground_projection = ground_projection and is_equal_approx(ground_front.origin.y,origin.y)
			for advance: float in [0.0,0.03,0.035,0.055,0.10,0.14,0.28]:
				fx.update(advance)
				all_inside = all_inside and geometry_inside(fx,origin,radius)
	check(all_inside,"sampled actual mesh vertices remain inside small, normal and upgraded damage spheres throughout the pulse")
	check(ground_projection,"airborne shock paint uses the sphere's floor intersection and never paints unreachable ground")
	fx.clear()
	fx.position=Vector3(3,2,-5)
	fx.pulse(Vector3(2,3.2,-4),80,7.52)
	fx.update(0.12)
	check(geometry_inside(fx,Vector3(2,3.2,-4),7.52),"pulse origins remain correct under a translated FX parent")
	fx.position=Vector3.ZERO
	fx.clear()
	fx.pulse(Vector3.ZERO,100,8.4)
	fx.update(0.06)
	var frozen := snapshot(fx)
	await process_frame
	await process_frame
	check(snapshot(fx)==frozen,"pulse animation has no independent timers and freezes when the director stops updating")
	fx.update(0.0)
	check(snapshot(fx)==frozen,"zero delta does not change pulse visibility, positions or lifetimes")
	fx.update(0.04)
	check(snapshot(fx)!=frozen,"explicit updates resume pulse animation")
	var coarse := FX.new()
	var fine := FX.new()
	root.add_child(coarse)
	root.add_child(fine)
	coarse.pulse(Vector3.ZERO,100,8.4)
	fine.pulse(Vector3.ZERO,100,8.4)
	coarse.update(0.12)
	for frame in range(12): fine.update(0.01)
	check(layer(coarse,"pulse_front").node.transform.is_equal_approx(layer(fine,"pulse_front").node.transform),"shock geometry is independent of update step size")
	coarse.free()
	fine.free()
	fx.clear()
	for burst in range(300):
		fx.impact(Vector3.ZERO,Vector3.BACK,"plasma")
		fx.pulse(Vector3.ZERO,100,8.4,burst%2==0)
	check(fx.active.size()<=FX.MAX_EFFECTS and fx.counts().allocated<=FX.MAX_EFFECTS,"mixed repeated pulses and weapon effects respect the shared allocation cap")
	fx.low_effects=true
	for burst in range(200): fx.pulse(Vector3.ZERO,100,8.4)
	check(fx.active.size()<=FX.LOW_EFFECTS_LIMIT,"repeated Low Effects pulses remain within their active cap")
	var latest: int = fx.emitted-3
	var latest_essential := 0
	for entry: Dictionary in fx.active:
		if entry.get("pulse_serial",-1)==latest and entry.essential: latest_essential+=1
	check(latest_essential==3,"saturation retains the newest pulse's core, front and radius cues")
	fx.clear()
	check(fx.active.is_empty() and fx.elapsed==0.0,"run cleanup resets pulse lifetimes and visible effects")
	fx.pulse(Vector3.ZERO,0,5)
	fx.pulse(Vector3.ZERO,30,0)
	fx.pulse(Vector3.ZERO,30,NAN)
	fx.pulse(Vector3(NAN,0,0),30,5)
	check(fx.active.is_empty(),"invalid or zero-energy pulse requests emit nothing")
	fx.pulse(Vector3.ZERO,30,5.32)
	check(layer(fx,"pulse_core").node.visible and not layer(fx,"pulse_after").node.visible,"reused pool nodes reset delayed visibility for the next run")
	fx.free()
	await integration_checks()
	print("Pulse FX: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
