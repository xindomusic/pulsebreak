extends SceneTree
## Independent approved-track container and adaptive gain checks. No listening is claimed.
const Director = preload("res://scripts/audio_director.gd")
const MUSIC_PATH := "res://assets/audio/elevenlabs/music_reactor_rush.ogg"
const APPROVED_CUES := ["kinetic_fire", "plasma_fire", "armor_impact", "machine_break", "pulse"]
const RATE := 44100
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run_checks")

func ogg_header(path: String) -> Dictionary:
	# Read source identification and end-granule fields, independently of the
	# generator's report and the engine import metadata. This is not PCM analysis.
	var file := FileAccess.open(path, FileAccess.READ)
	if not file: return {}
	var channels := 0
	var rate := 0
	var frames := -1
	var serial := -1
	var pages := 0
	var ended := false
	while file.get_position() + 27 <= file.get_length():
		if file.get_buffer(4).get_string_from_ascii() != "OggS": return {}
		if file.get_8() != 0: return {}
		var flags := file.get_8()
		var granule := file.get_64()
		var page_serial := file.get_32()
		file.get_32()
		file.get_32()
		var segments := file.get_8()
		var body_size := 0
		for index in range(segments): body_size += file.get_8()
		if file.get_position() + body_size > file.get_length(): return {}
		var body := file.get_buffer(body_size)
		if serial == -1: serial = page_serial
		if page_serial != serial: return {}
		if pages == 0:
			if body.size() < 16 or body[0] != 1 or body.slice(1, 7).get_string_from_ascii() != "vorbis": return {}
			channels = int(body[11])
			rate = int(body[12]) | (int(body[13]) << 8) | (int(body[14]) << 16) | (int(body[15]) << 24)
		if flags & 4:
			frames = granule
			ended = true
		pages += 1
	if file.get_position() != file.get_length() or not ended: return {}
	return {"channels": channels, "rate": rate, "frames": frames, "pages": pages}

func levels_valid(levels: PackedFloat32Array) -> bool:
	if levels.size() != 1: return false
	for level in levels:
		if not is_finite(level) or level < -80.0 or level > 6.0: return false
	return true

func same_levels(first: PackedFloat32Array, second: PackedFloat32Array) -> bool:
	if first.size() != second.size(): return false
	for index in range(first.size()):
		if absf(first[index] - second[index]) > 0.001: return false
	return true

func settle(director: Node, seconds: float = 8.0) -> void:
	for index in range(roundi(seconds * 60.0)):
		director._process(1.0 / 60.0)

func peak_target(director: Node, enemies: float, incoming: float, charge: float, boss: bool = false, active: bool = true) -> float:
	director.set_battle_state(enemies, incoming, charge, boss, active)
	settle(director)
	return director.get_intensity()

func production_audio_checks() -> void:
	# Exercise the real callback order. A director-only test cannot catch a
	# later Classic director overwriting the battle target with elapsed time.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.qa_mode = true
	game.start_run(false)
	game.qa_mode = false
	game.sound.set_process(false)
	game.auto_timer = 999.0
	game.spawn_timer = 999.0
	game.next_core = 999.0
	game.last_upgrade = 5
	game.run_time = 10.0
	game.rules.energy = 0.0
	game.player_node.position = Vector3.ZERO
	game.player_previous = Vector3.ZERO
	game.update_battle_audio()
	var calm_target: float = game.sound._intensity
	game._physics_process(0.0)
	check(absf(game.sound._intensity - calm_target) < 0.001, "the complete Classic callback retains its battle-driven calm target")
	var enemy = game.spawn_enemy("gunner", Vector3(0, 0, 3))
	enemy.spawning = 0.0
	enemy.cooldown = 999.0
	game._physics_process(0.0)
	check(game.sound._intensity > calm_target + 0.02, "nearby threats still raise intensity after the complete Classic callback")
	game.enemies.clear()
	enemy.queue_free()
	game.run_time = 310.0
	game._physics_process(0.0)
	check(absf(game.sound._intensity - calm_target) < 0.001, "a late quiet Classic encounter is not forced loud by elapsed time")
	var playback = game.sound._music.get_stream_playback()
	game.state = "paused"
	game._physics_process(0.0)
	check(is_zero_approx(game.sound._intensity) and game.sound._music.get_stream_playback() == playback, "the actual paused callback requests calm without restarting music")
	playback = null
	game.qa_mode = true
	game.queue_free()
	await process_frame
	await process_frame

func run_checks() -> void:
	check(Director.MUSIC_PATH == MUSIC_PATH, "runtime selects the user-approved first candidate")
	var header := ogg_header(MUSIC_PATH)
	check(not header.is_empty(), "the approved first candidate has readable complete source Ogg/Vorbis pages")
	if not header.is_empty():
		check(header.channels == 2 and header.rate == RATE, "the approved music source is stereo 44.1 kHz")
		check(header.frames > 43 * RATE and header.frames < 45 * RATE, "the release retains the approved track's roughly 44-second duration")

	var director = Director.new()
	root.add_child(director)
	await process_frame
	director.set_process(false)
	var music := director._music.stream as AudioStreamOggVorbis
	check(music != null, "the approved music plays as one Ogg track")
	if music == null:
		director.queue_free()
		await process_frame
		quit(1)
		return
	check(music.loop and is_zero_approx(music.loop_offset), "the approved music explicitly loops from its prepared origin")
	check(is_zero_approx(music.bpm) and music.beat_count == 0, "runtime metadata does not claim an unmeasured tempo or beat count")
	if not header.is_empty():
		check(absf(music.get_length() - float(header.frames) / RATE) <= 1.0 / RATE, "engine decoding preserves the approved source end-granule duration")
	check(director._music.playing and director._music.get_stream_playback() != null, "the approved track actually starts playback")
	var playback = director._music.get_stream_playback()
	for cue: String in APPROVED_CUES:
		var stream := director._streams.get(cue) as AudioStreamWAV
		check(stream != null and stream.resource_path.begins_with("res://assets/audio/elevenlabs/"), cue + " resolves to the accepted generated release effects")

	director.set_volume(1.0)
	var inactive := peak_target(director, 1.0, 1.0, 1.0, true, false)
	var inactive_levels: PackedFloat32Array = director.mix_levels()
	check(inactive < 0.01 and levels_valid(inactive_levels), "inactive play returns to a finite calm mix despite previous threat")
	var calm := peak_target(director, 0.0, 0.0, 0.0)
	var calm_levels: PackedFloat32Array = director.mix_levels()
	check(calm > 0.2 and calm < 0.4, "active calm play retains a deliberate groove floor")
	check(director._music.volume_db > -32.0, "the approved track remains present in the active calm mix")
	var enemies := peak_target(director, 1.0, 0.0, 0.0)
	var incoming := peak_target(director, 0.0, 1.0, 0.0)
	var charged := peak_target(director, 0.0, 0.0, 1.0)
	var boss := peak_target(director, 0.0, 0.0, 0.0, true)
	check(enemies > calm + 0.15, "nearby enemy pressure increases the musical response")
	check(incoming > calm + 0.1, "incoming attacks increase the musical response independently")
	check(charged > calm + 0.04, "stored charge contributes independently to the musical response")
	check(boss > calm + 0.1, "Guardian combat has an independent musical lift")
	var saturated := peak_target(director, 5.0, 5.0, 5.0, true)
	var high_levels: PackedFloat32Array = director.mix_levels()
	check(saturated <= 1.0 and saturated > 0.95 and levels_valid(high_levels), "extreme pressure remains a bounded finite high-intensity mix")
	check(high_levels[0] > calm_levels[0] + 1.0 and high_levels[0] - calm_levels[0] < 8.0, "combat raises the approved track gain within a bounded range")
	check(absf(director._music.volume_db - high_levels[0]) < 0.01, "the declared single music gain is applied once at full user volume")
	check(peak_target(director, -4.0, -4.0, -4.0) >= calm - 0.01, "negative pressure does not erase the active groove floor")
	var invalid_target := peak_target(director, NAN, INF, -INF)
	check(is_finite(invalid_target) and invalid_target > 0.2 and invalid_target < 0.4 and levels_valid(director.mix_levels()), "non-finite battle inputs cannot poison the music gains")
	director.set_intensity(NAN)
	settle(director)
	check(is_finite(director.get_intensity()) and director.get_intensity() < 0.01, "non-finite direct intensity safely returns to calm")

	peak_target(director, 0.0, 0.0, 0.0, false, false)
	director.set_intensity(1.0)
	check(director.get_intensity() < 0.01, "an intensity request does not abruptly replace the smoothed value")
	director._process(1.0 / 60.0)
	check(director.get_intensity() > 0.0 and director.get_intensity() < 0.35, "the first frame eases into an intensity increase")
	settle(director)
	check(director.get_intensity() > 0.98, "sustained intensity converges to its requested state")
	director.set_intensity(-1.0)
	settle(director)
	check(director.get_intensity() >= 0.0 and director.get_intensity() < 0.02, "negative direct intensity converges safely to zero")
	check(director._music.get_stream_playback() == playback and director._music.playing, "combat and gain changes keep the same live playback instead of restarting music")

	director.set_intensity(0.6)
	settle(director)
	var before_duck: float = director._music.volume_db
	var unducked_gain: PackedFloat32Array = director.mix_levels()
	director._last_cue.clear()
	director.play_cue("pulse", 1.0)
	director._process(0.0)
	check(director._music.volume_db < before_duck - 3.0, "a charged pulse makes immediate room in the music mix")
	check(same_levels(director.mix_levels(), unducked_gain), "pulse ducking preserves the gain requested by combat intensity")
	settle(director, 2.0)
	check(absf(director._music.volume_db - before_duck) < 0.1, "music returns after the pulse envelope without a stuck duck")
	var routine_duck: float = director._music.volume_db
	director._last_cue.clear()
	director.play_cue("kinetic_fire")
	director._process(0.0)
	check(absf(director._music.volume_db - routine_duck) < 0.1, "routine automatic fire does not repeatedly suppress the groove")

	director.set_muted(true)
	check(director._music.volume_db <= -80.0 and director._music.playing, "mute silences the approved track without stopping playback")
	director.set_muted(false)
	director.set_volume(0.0)
	check(director._music.volume_db <= -80.0, "zero volume silences the approved music player")
	director.set_volume(NAN)
	check(is_zero_approx(director._volume) and is_finite(director._music.volume_db) and director._music.volume_db <= -80.0, "an invalid volume cannot send non-finite gain to the audio server")
	director.set_volume(0.5)
	check(director._music.volume_db > -50.0 and director._music.get_stream_playback() == playback, "restoring volume resumes the existing musical position")
	var finite_levels := levels_valid(director.mix_levels()) and is_finite(director._music.volume_db)
	check(finite_levels, "all exposed and applied levels remain finite after transitions")

	var limiter_ok := false
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		for index in range(AudioServer.get_bus_effect_count(master)):
			var effect := AudioServer.get_bus_effect(master, index) as AudioEffectHardLimiter
			if effect != null and AudioServer.is_bus_effect_enabled(master, index):
				limiter_ok = effect.ceiling_db <= -1.0 and effect.pre_gain_db <= 0.0
	check(limiter_ok, "the active Master bus has a limiter with at least 1 dB output headroom and no pre-boost")
	check(director._voices.size() == 12, "adaptive music does not expand the effect-voice pool")
	playback = null
	director.queue_free()
	await process_frame
	await process_frame
	await production_audio_checks()
	print("Release audio: %d checks, %d failures; container and runtime state checks, no audition" % [checks, failures])
	quit(1 if failures else 0)
