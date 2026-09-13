extends RefCounted
## Feet-height simulation shared by movement, combat collision and animation.
## Call only while the game is active. Horizontal movement/dash remain independent.

const GRAVITY := 22.0
const JUMP_SPEED := 11.8
const JUMP_BUFFER := 0.16
const GLIDE_FALL_SPEED := 0.85
const GLIDE_GRAVITY := 2.8
const FUEL_DRAIN := 0.48
const FUEL_RECHARGE := 0.72
const PLAYER_HEIGHT := 1.65
const MAX_SUBSTEP := 1.0 / 120.0

var height := 0.0
var previous_height := 0.0
var vertical_velocity := 0.0
var grounded := true
var gliding := false
var fuel := 1.0
var landed := false
var jumped := false
var landing_speed := 0.0
var airborne_time := 0.0
var _jump_buffer := 0.0

func reset() -> void:
	height = 0.0
	previous_height = 0.0
	vertical_velocity = 0.0
	grounded = true
	gliding = false
	fuel = 1.0
	landed = false
	jumped = false
	landing_speed = 0.0
	airborne_time = 0.0
	_jump_buffer = 0.0

func request_jump() -> void:
	# Input queues intent; it never grants another jump while airborne.
	_jump_buffer = JUMP_BUFFER

func step(delta: float, jump_held: bool) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return
	previous_height = height
	landed = false
	jumped = false
	landing_speed = 0.0
	# Small deterministic steps preserve apex and landing behavior during QA's
	# accelerated simulation as well as normal fixed physics updates.
	var remaining := delta
	while remaining > 0.000001:
		var dt := minf(remaining, MAX_SUBSTEP)
		_advance(dt, jump_held)
		remaining -= dt

func _advance(delta: float, jump_held: bool) -> void:
	if grounded and _jump_buffer > 0.0:
		vertical_velocity = JUMP_SPEED
		grounded = false
		jumped = true
		airborne_time = 0.0
		_jump_buffer = 0.0
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	if grounded:
		gliding = false
		fuel = minf(1.0, fuel + FUEL_RECHARGE * delta)
		return
	airborne_time += delta
	gliding = jump_held and vertical_velocity <= 0.0 and height > 0.15 and fuel > 0.000001
	if gliding:
		# Wings catch a fall immediately but never create free upward thrust.
		var glide_dt := minf(delta, fuel / FUEL_DRAIN)
		var old_speed := maxf(vertical_velocity, -GLIDE_FALL_SPEED)
		vertical_velocity = maxf(old_speed - GLIDE_GRAVITY * glide_dt, -GLIDE_FALL_SPEED)
		height += (old_speed + vertical_velocity) * 0.5 * glide_dt
		fuel = maxf(0.0, fuel - FUEL_DRAIN * glide_dt)
		var fall_dt := delta - glide_dt
		if fall_dt > 0.0:
			height += vertical_velocity * fall_dt - 0.5 * GRAVITY * fall_dt * fall_dt
			vertical_velocity -= GRAVITY * fall_dt
		if fuel <= 0.000001:
			fuel = 0.0
			gliding = false
	else:
		height += vertical_velocity * delta - 0.5 * GRAVITY * delta * delta
		vertical_velocity -= GRAVITY * delta
	if height <= 0.0:
		landing_speed = maxf(landing_speed, -vertical_velocity)
		height = 0.0
		vertical_velocity = 0.0
		grounded = true
		gliding = false
		landed = true
		airborne_time = 0.0

static func overlaps_height(player_height: float, obstacle_bottom: float = 0.0, obstacle_top: float = 1.5, body_height: float = PLAYER_HEIGHT) -> bool:
	return player_height <= obstacle_top and player_height + body_height >= obstacle_bottom

static func crossing_fraction(player_from: Vector3, player_to: Vector3, obstacle_from: Vector3, obstacle_to: Vector3) -> float:
	## Time of closest horizontal approach, useful for impact/harvest effects.
	var offset := Vector2(player_from.x - obstacle_from.x, player_from.z - obstacle_from.z)
	var motion := Vector2(player_to.x - obstacle_to.x, player_to.z - obstacle_to.z) - offset
	if motion.length_squared() < 0.00000001:
		return 0.0
	return clampf(-offset.dot(motion) / motion.length_squared(), 0.0, 1.0)

static func swept_body_hit(player_from: Vector3, player_to: Vector3, obstacle_from: Vector3, obstacle_to: Vector3, horizontal_radius: float, obstacle_bottom: float = 0.0, obstacle_top: float = 1.5, body_height: float = PLAYER_HEIGHT) -> bool:
	## Continuous overlap of a vertical player column and a moving obstacle.
	## Obstacle heights are offsets from obstacle_from/to.y. Both the horizontal
	## overlap and vertical overlap must happen at the SAME time in this step.
	## This avoids airborne harvest and damage from a dash crossing low shots.
	if horizontal_radius < 0.0 or obstacle_top < obstacle_bottom or body_height < 0.0:
		return false
	var relative_start := player_from - obstacle_from
	var relative_end := player_to - obstacle_to
	var start := Vector2(relative_start.x, relative_start.z)
	var motion := Vector2(relative_end.x, relative_end.z) - start
	var enter := 0.0
	var leave := 1.0
	var a := motion.length_squared()
	var c := start.length_squared() - horizontal_radius * horizontal_radius
	if a < 0.00000001:
		if c > 0.0:
			return false
	else:
		var b := 2.0 * start.dot(motion)
		var discriminant := b * b - 4.0 * a * c
		if discriminant < 0.0:
			return false
		var root := sqrt(discriminant)
		enter = maxf(enter, (-b - root) / (2.0 * a))
		leave = minf(leave, (-b + root) / (2.0 * a))
		if enter > leave:
			return false
	var lower := obstacle_bottom - body_height
	var upper := obstacle_top
	var vertical_motion := relative_end.y - relative_start.y
	if absf(vertical_motion) < 0.00000001:
		return relative_start.y >= lower and relative_start.y <= upper
	var vertical_enter := (lower - relative_start.y) / vertical_motion
	var vertical_leave := (upper - relative_start.y) / vertical_motion
	if vertical_enter > vertical_leave:
		var swap := vertical_enter
		vertical_enter = vertical_leave
		vertical_leave = swap
	enter = maxf(enter, vertical_enter)
	leave = minf(leave, vertical_leave)
	return enter <= leave
