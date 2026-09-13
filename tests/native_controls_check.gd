extends SceneTree
## Injects keyboard events through Godot's input route and advances real gameplay.
## Captures are native renders of those states, not a human playtest or benchmark.

const DT := 1.0 / 60.0
var game: Node3D
var checks := 0
var failures := 0
var captured := 0
var held_codes: Array[int] = []

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func key(code: Key, pressed: bool) -> void:
	await process_frame
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	if pressed and not held_codes.has(code): held_codes.append(code)
	if not pressed: held_codes.erase(code)

func advance(frames: int) -> void:
	for frame in range(frames):
		# macOS may release virtual keys during offscreen capture. Repeat held
		# keyboard state using echo events, which never retrigger jump/dash.
		for code in held_codes:
			var held := InputEventKey.new()
			held.keycode = code
			held.physical_keycode = code
			held.pressed = true
			held.echo = true
			Input.parse_input_event(held)
		game._physics_process(DT)

func capture_pose(label: String, closeup: bool = false) -> void:
	if DisplayServer.get_name() == "headless": return
	await game.capture(label)
	captured += 1
	if closeup:
		var original_camera: Transform3D = game.camera.transform
		var original_size: float = game.camera.size
		var original_ui: bool = game.ui.visible
		game.camera.size = 7.5
		game.camera.position = game.player_position+Vector3(5,7,9)
		game.camera.look_at(game.player_position+Vector3(0,1,0))
		game.ui.visible = false
		await game.capture(label+"-rig")
		captured += 1
		game.camera.transform = original_camera
		game.camera.size = original_size
		game.ui.visible = original_ui

func run_checks() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = false
	# Isolate render automation from incidental desktop focus changes. The
	# production callback is reconnected and explicitly tested below.
	game.get_window().focus_exited.disconnect(game.pause_on_focus_loss)
	Input.use_accumulated_input = false
	game.qa_output_dir = ProjectSettings.globalize_path("res://qa/skybound-controls")
	# The fixture is deterministic and never writes the user's settings. Rebind
	# input temporarily uses qa_mode only to suppress save_settings, not movement.
	game.bindings = {"left":KEY_A,"right":KEY_D,"up":KEY_W,"down":KEY_S,"dash":KEY_SPACE,"pulse":KEY_E,"jump":KEY_F}
	game.configure_input()
	game.start_campaign()
	game.rules.recovery = 0.0
	game.player_node.set_meta("gait_phase",0.0)
	game.campaign.spawn_clock = 1000.0
	game.ui.hint.text = ""
	game.ui.banner.text = ""
	check(game.campaign_active and game.campaign.sector == 0, "campaign begins at Skyport through its real start route")
	check(game.player_node.has_meta("rig"), "courier exposes its actual articulated animation rig")
	var rig: Dictionary = game.player_node.get_meta("rig")
	await capture_pose("01-ready")

	await key(KEY_D,true)
	check(Input.is_action_pressed("right"), "injected D keyboard press reaches the configured move action")
	var run_start: Vector3 = game.player_position
	advance(8)
	var hip_a: float = rig.hips[0].rotation.x
	var knee_a: float = rig.knees[0].rotation.x
	var alternating_a: float = absf(rig.hips[0].rotation.x-rig.hips[1].rotation.x)
	await capture_pose("02-gait-a",true)
	advance(12)
	var hip_b: float = rig.hips[0].rotation.x
	var knee_b: float = rig.knees[0].rotation.x
	await capture_pose("03-gait-b",true)
	check(game.player_position.x > run_start.x+2.0 and game.traversal.grounded, "held D moves the courier across the deck")
	check(absf(hip_b-hip_a)>0.15 and absf(knee_b-knee_a)>0.08, "successive walking frames articulate hips and knees into different gait poses")
	check(maxf(alternating_a,absf(rig.hips[0].rotation.x-rig.hips[1].rotation.x))>0.1, "the two legs alternate instead of moving as a rigid body")
	await key(KEY_D,false)

	await key(KEY_F,true)
	check(Input.is_action_pressed("jump"), "F keyboard press reaches the jump binding")
	advance(12)
	check(not game.traversal.grounded and game.player_position.y > 1.7, "real F input starts a jump and raises the actual model")
	check(rig.plumes[0].visible and rig.plumes[1].visible, "jumping activates both thruster plumes")
	await capture_pose("04-jump-ascent")
	advance(20)
	check(game.player_position.y > 3.0, "held jump reaches the intended apex")
	await capture_pose("05-apex")
	advance(18)
	check(game.traversal.gliding and game.traversal.fuel < 1.0, "continuing to hold F deploys powered glide and consumes fuel")
	check(float(game.player_node.get_meta("wing_deployment"))>0.9 and rig.body.rotation.x>0.5, "glide deploys the wings and pitches the actual torso into flight")
	await capture_pose("06-glide",true)
	var glide_fuel: float = game.traversal.fuel
	await key(KEY_F,false)
	advance(1)
	check(not Input.is_action_pressed("jump") and not game.traversal.gliding, "releasing F reaches the input action and stops powered glide")
	check(is_equal_approx(game.traversal.fuel,glide_fuel), "released wings stop draining fuel immediately")
	var landed := false
	for frame in range(100):
		advance(1)
		if game.traversal.landed:
			landed = true
			break
	check(landed and game.player_position.y == 0.0, "the released flight lands back on the physical deck")
	advance(3)
	check(float(game.player_node.get_meta("landing_impact",0.0)) > 0.0 and rig.body.position.y < 0.0, "landing drives the courier's impact compression pose")
	await capture_pose("07-landing",true)
	advance(20)
	check(not rig.plumes[0].visible and not rig.plumes[1].visible, "thruster plumes switch off after landing")

	# Direction and dash arrive without an intervening gameplay physics frame.
	await key(KEY_A,true)
	await key(KEY_SPACE,true)
	check(game.rules.dash_time > 0.0 and game.dash_direction.is_equal_approx(Vector3.LEFT), "Space samples newly pressed A immediately for the current-direction dash")
	advance(1)
	check(game.player_velocity.x < -29.0, "the keyboard-triggered dash applies its real horizontal speed")
	await key(KEY_SPACE,false)
	await key(KEY_A,false)
	advance(14)

	# Rebind through the same capture screen and keyboard handler as the UI.
	game.qa_mode = true
	game.on_ui_action("rebind","jump")
	await key(KEY_J,true)
	await key(KEY_J,false)
	game.qa_mode = false
	check(game.bindings.jump == KEY_J and game.state == "settings", "the rebind screen consumes J and updates the jump mapping")
	game.state = "run"
	game.ui.show_game()
	await key(KEY_F,true)
	advance(1)
	check(game.traversal.grounded, "the former F key no longer jumps after rebinding")
	await key(KEY_F,false)
	await key(KEY_J,true)
	advance(1)
	check(not game.traversal.grounded and Input.is_action_pressed("jump"), "the new J keyboard binding triggers and holds jump through actual input")
	await key(KEY_J,false)

	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	check(game.state == "paused", "Escape keyboard input pauses a live airborne campaign")
	var pause_height: float = game.traversal.height
	var pause_fuel: float = game.traversal.fuel
	var pause_time: float = game.run_time
	advance(30)
	check(game.traversal.height == pause_height and game.traversal.fuel == pause_fuel and game.run_time == pause_time, "pause freezes traversal resources and campaign time")
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	check(game.state == "run", "Escape resumes the previous active state")
	game.get_window().focus_exited.connect(game.pause_on_focus_loss)
	game.get_window().focus_exited.emit()
	check(game.state == "paused", "native focus-loss signal pauses an active campaign")
	game.on_ui_action("resume",null)
	check(game.state == "run", "the pause UI resume action returns to the campaign")
	game.campaign.total_relays = 2
	game.rules.energy = 75.0
	game.on_ui_action("restart",null)
	check(game.campaign_active and game.campaign.sector == 0 and game.campaign.total_relays == 0, "campaign restart resets sector objectives rather than entering survival")
	check(game.traversal.grounded and game.traversal.fuel == 1.0 and game.player_position.y == 0.0 and game.rules.energy == 0.0, "campaign restart clears airborne position and combat resources")
	check(game.bindings.jump == KEY_J, "campaign restart preserves the remapped control")

	game.qa_mode = true
	game.clear_run()
	game.queue_free()
	await process_frame
	await process_frame
	print("Native keyboard controls: %d checks, %d failures; %d native captures" % [checks,failures,captured])
	quit(1 if failures else 0)
