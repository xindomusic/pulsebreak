extends SceneTree

const Traversal = preload("res://scripts/traversal.gd")
const DT := 1.0 / 120.0
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	var t = Traversal.new()
	check(t.grounded and t.height == 0.0 and t.fuel == 1.0, "starts grounded with charged wings")
	t.request_jump()
	t.step(DT, false)
	check(t.jumped and not t.grounded and t.vertical_velocity > 0.0, "buffered input starts a jump")
	var apex: float = t.height
	var landing_count := 0
	for i in range(150):
		t.step(DT, false)
		apex = maxf(apex, t.height)
		if t.landed:
			landing_count += 1
			check(t.landing_speed > 10.0, "landing reports impact speed for animation")
	check(apex > 3.0 and apex < 3.3, "jump clears low targets with a three meter apex")
	check(t.grounded and t.height == 0.0 and t.vertical_velocity == 0.0, "ballistic jump returns exactly to the deck")
	check(landing_count == 1, "landing fires once instead of every grounded step")

	t.reset()
	t.request_jump()
	for i in range(100): t.step(DT, false)
	t.request_jump()
	for i in range(12): t.step(DT, false)
	check(t.vertical_velocity < 0.0, "airborne input cannot grant a double jump")
	for i in range(50): t.step(DT, false)
	check(t.grounded, "an early buffered press expires before landing")
	t.request_jump()
	for i in range(122): t.step(DT, false)
	t.request_jump()
	var buffered_takeoff := false
	for i in range(18):
		t.step(DT, false)
		buffered_takeoff = buffered_takeoff or t.jumped
	check(buffered_takeoff and not t.grounded, "a press just before landing buffers a responsive next jump")

	t.reset()
	t.request_jump()
	var glide_seen := false
	var exhausted_in_air := false
	var held_landing_count := 0
	var flight_duration := 0.0
	for i in range(520):
		t.step(DT, true)
		glide_seen = glide_seen or t.gliding
		if not t.grounded: flight_duration += DT
		if t.fuel == 0.0 and not t.grounded:
			exhausted_in_air = true
			check(not t.gliding, "exhausted wings stop gliding")
			break
	check(glide_seen, "holding jump deploys wings at the jump apex")
	check(exhausted_in_air and t.height > 0.3, "fuel is finite even while jump stays held")
	for i in range(240):
		t.step(DT, true)
		if not t.grounded: flight_duration += DT
		if t.landed: held_landing_count += 1
	check(t.grounded and held_landing_count == 1, "holding jump cannot auto-hop or sustain endless flight")
	check(flight_duration > 2.5 and flight_duration < 3.5, "wing flight creates a useful traversal window")
	check(t.fuel > 0.8 and t.fuel <= 1.0, "grounded wings recharge within the resource cap")

	t.reset()
	t.request_jump()
	for i in range(120): t.step(DT, true)
	check(t.gliding and t.fuel < 1.0, "mid-flight state has active wings and used fuel")
	var paused_height: float = t.height
	var paused_fuel: float = t.fuel
	var paused_velocity: float = t.vertical_velocity
	t.step(0.0, false)
	t.step(-1.0, false)
	check(t.height == paused_height and t.fuel == paused_fuel and t.vertical_velocity == paused_velocity, "no elapsed simulation time preserves paused flight")
	t.step(DT, false)
	check(not t.gliding and t.vertical_velocity < paused_velocity, "releasing jump immediately restores gravity")
	t.reset()
	check(t.height == 0.0 and t.previous_height == 0.0 and t.vertical_velocity == 0.0 and t.grounded and not t.gliding and t.fuel == 1.0 and not t.landed and not t.jumped, "restart clears height, events and fuel state")
	t.step(DT, true)
	check(t.grounded, "reset also clears buffered input")

	var sixty = Traversal.new()
	var one_twenty = Traversal.new()
	sixty.request_jump()
	one_twenty.request_jump()
	for i in range(72): sixty.step(1.0 / 60.0, true)
	for i in range(144): one_twenty.step(DT, true)
	check(is_equal_approx(sixty.height, one_twenty.height) and is_equal_approx(sixty.fuel, one_twenty.fuel), "60 and 120 Hz produce the same traversal state")

	check(Traversal.overlaps_height(0.0, 0.0, 0.3), "ground shockwave hits a grounded player")
	check(not Traversal.overlaps_height(0.31, 0.0, 0.3), "jumping above shockwave height avoids it")
	check(Traversal.overlaps_height(1.3, 0.0, 1.5), "an incomplete jump still contacts a tall enemy")
	check(not Traversal.overlaps_height(2.0, 0.0, 1.5), "clearing enemy height makes passing overhead safe")
	var start := Vector3(-4.0, 0.0, 0.0)
	var finish := Vector3(4.0, 0.0, 0.0)
	var shot := Vector3(0.0, 0.85, 0.0)
	check(Traversal.swept_body_hit(start, finish, shot, shot, 0.48, -0.2, 0.2), "a ground dash detects a projectile between endpoints")
	check(not Traversal.swept_body_hit(start + Vector3.UP * 2.5, finish + Vector3.UP * 2.5, shot, shot, 0.48, -0.2, 0.2), "an air dash clears a low projectile at the swept crossing")
	check(Traversal.swept_body_hit(Vector3(0.0, 3.0, 0.0), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, 0.5, 0.0, 1.5), "landing onto a target detects vertical crossing")
	check(not Traversal.swept_body_hit(Vector3(-4.0, 0.0, 0.0), Vector3(4.0, 4.0, 0.0), shot, shot, 0.48, -0.2, 0.2), "height is evaluated during horizontal crossing rather than at the old grounded position")
	check(not Traversal.swept_body_hit(Vector3(-4.0, 4.0, 0.0), Vector3(4.0, 0.0, 0.0), shot, shot, 0.48, -0.2, 0.2), "landing after passing a shot cannot cause a retroactive hit")
	check(Traversal.swept_body_hit(Vector3(-4.0, 0.0, 0.0), Vector3(4.0, 1.0, 0.0), shot, shot, 0.48, -0.2, 0.2), "a jump too low during crossing still collides")
	check(Traversal.swept_body_hit(Vector3.ZERO, Vector3.ZERO, Vector3(-5.0, 0.85, 0.0), Vector3(5.0, 0.85, 0.0), 0.48, -0.2, 0.2), "moving projectiles sweep against a stationary player")
	check(not Traversal.swept_body_hit(Vector3(0.0, 0.0, 2.0), Vector3(1.0, 0.0, 2.0), shot, shot, 0.48, -0.2, 0.2), "horizontal near misses remain safe")
	check(is_equal_approx(Traversal.crossing_fraction(start, finish, shot, shot), 0.5), "effects can locate the middle of a swept dash crossing")
	print("Traversal: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
