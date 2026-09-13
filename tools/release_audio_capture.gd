extends SceneTree
## Records the shipped first-candidate mix after the production limiter.
## Separate release evidence; historical Resonance captures remain untouched.
## Automated campaign combat with explicitly logged weapon/charge injections;
## this is an engine-audio demonstration, not a human playthrough or benchmark.
## API: https://docs.godotengine.org/en/stable/classes/class_audioeffectrecord.html
## WAV: https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html

const ReleaseAudio = preload("res://scripts/audio_director.gd")
const APPROVED_MUSIC := "res://assets/audio/elevenlabs/music_reactor_rush.ogg"
const DURATION := 36.0
const HARD_DEADLINE := 50.0
const MODES: Array[String] = ["kinetic", "scatter", "arc", "plasma"]
const MODE_TIMES: Array[float] = [0.0, 4.5, 9.0, 13.5]
const PULSE_TIMES: Array[float] = [14.0, 31.0]
const GUARDIAN_TIME := 18.0

class CaptureGame:
	extends "res://scripts/game.gd"
	# Only capture lifecycle differs: gameplay uses the inherited production
	# callbacks; no profile writes or pending QA auto-quit can interrupt WAV save.
	func save_settings() -> void:
		pass
	func finish(won: bool, retired: bool = false) -> void:
		var was_qa := qa_mode
		qa_mode = false
		super.finish(won, retired)
		qa_mode = was_qa

var game: Node3D
var recorder: AudioEffectRecord
var recording: AudioStreamWAV
var master := -1
var output_dir := ""
var seed_value := 74921
var volume := 0.65
var boot_usec := 0
var started_usec := 0
var events: Array[Dictionary] = []
var telemetry: Array[Dictionary] = []
var bus_effects: Array[Dictionary] = []
var failure := ""
var guardian_staged := false
var loop_check: Dictionary = {}


func _initialize() -> void:
	boot_usec = Time.get_ticks_usec()
	call_deferred("capture_audio")


func capture_audio() -> void:
	output_dir = ProjectSettings.globalize_path("res://qa/release-native-audio")
	if DisplayServer.get_name() == "headless" or AudioServer.get_driver_name() == "Dummy":
		failure = "Native rendering and a real audio driver are required."
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--audio-dir="):
			output_dir = arg.trim_prefix("--audio-dir=")
		elif arg.begins_with("--audio-seed="):
			var seed_arg := arg.trim_prefix("--audio-seed=")
			if not seed_arg.is_valid_int() or int(seed_arg) < 0: failure = "Invalid --audio-seed."
			else: seed_value = int(seed_arg)
		elif arg.begins_with("--audio-volume="):
			var volume_arg := arg.trim_prefix("--audio-volume=")
			if not volume_arg.is_valid_float() or not is_finite(float(volume_arg)) or float(volume_arg) <= 0.0 or float(volume_arg) > 1.0:
				failure = "--audio-volume must be greater than 0 and at most 1."
			else: volume = float(volume_arg)
		else:
			failure = "Unsupported argument: %s. Use only --audio-dir/--audio-seed/--audio-volume; game QA/title switches conflict with this recorder." % arg
	for arg: String in OS.get_cmdline_args():
		if arg.begins_with("--fixed-fps") or arg.begins_with("--time-scale"):
			failure = "Recording requires normal wall-clock simulation, without --fixed-fps or --time-scale."
	if output_dir.begins_with("res://"): output_dir = ProjectSettings.globalize_path(output_dir)
	if not output_dir.is_absolute_path(): failure = "--audio-dir must be an absolute path or res:// path."
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK: failure = "Could not create the audio output directory."
	if not failure.is_empty():
		await finish_capture()
		return
	if ReleaseAudio.MUSIC_PATH != APPROVED_MUSIC or not ResourceLoader.exists(APPROVED_MUSIC):
		failure = "The accepted first-candidate release soundtrack is not available."
	for cue: String in ReleaseAudio.RELEASE_CUES:
		if not ResourceLoader.exists(ReleaseAudio.cue_path(cue)):
			failure = "Missing imported release cue: " + cue
	master = AudioServer.get_bus_index("Master")
	var limiter_found := false
	if master >= 0:
		for index: int in range(AudioServer.get_bus_effect_count(master)):
			var effect := AudioServer.get_bus_effect(master, index)
			var enabled := AudioServer.is_bus_effect_enabled(master, index)
			bus_effects.append({"index": index, "class": effect.get_class(), "enabled": enabled})
			if effect is AudioEffectHardLimiter and enabled: limiter_found = true
		if AudioServer.is_bus_bypassing_effects(master) or AudioServer.is_bus_mute(master):
			failure = "Master must have effects enabled and must not be muted."
	if not limiter_found: failure = "The production Master hard limiter must be enabled before recording."
	if not failure.is_empty():
		await finish_capture()
		return
	game = load("res://main.tscn").instantiate()
	game.set_script(CaptureGame)
	root.add_child(game)
	game.qa_mode = true
	game.qa_fast = false
	game.qa_simulation = false
	game.qa_sector_limit = 999
	game.qa_output_dir = output_dir
	# Suppress the director's unrelated timed screenshot requests.
	for checkpoint: int in [15, 90, 190, 365]: game.qa_captured[checkpoint] = true
	game.settings.volume = volume
	game.settings.assist = false
	game.settings.overdrive = false
	game.settings.low_effects = false
	game.settings.shake = 0.45
	game.apply_settings()
	if not is_instance_valid(game.sound):
		failure = "The production audio director did not initialize."
		await finish_capture()
		return
	await verify_music_loop()
	if not failure.is_empty():
		await finish_capture()
		return
	game.sound._music.stop()
	await create_timer(0.12).timeout
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	# Append, preserving every production bus effect and its order.
	AudioServer.add_bus_effect(master, recorder)
	bus_effects.append({"index": AudioServer.get_bus_effect_count(master) - 1, "class": "AudioEffectRecord", "enabled": true})
	recorder.set_recording_active(true)
	started_usec = Time.get_ticks_usec()
	game.sound._music.play(0.0)
	game.start_campaign(seed_value)
	log_event("start", {"campaign_seed": seed_value, "music_restarted_at_seconds": 0.0, "pilot": "production game.pilot", "volume": volume})
	var next_mode := 0
	var next_pulse := 0
	var next_sample := 0.0
	while elapsed() < DURATION:
		if float(Time.get_ticks_usec() - boot_usec) / 1000000.0 >= HARD_DEADLINE:
			failure = "The 50-second recording deadline was reached."
			break
		if game.state == "result":
			failure = "Campaign combat ended before the 36-second recording completed."
			break
		var now := elapsed()
		if game.state in ["run", "boss"]:
			if next_mode < MODES.size() and now >= MODE_TIMES[next_mode]:
				install_weapon(MODES[next_mode])
				next_mode += 1
			if not guardian_staged and now >= GUARDIAN_TIME:
				stage_guardian()
			if next_pulse < PULSE_TIMES.size() and now >= PULSE_TIMES[next_pulse]:
				game.rules.energy = 100.0
				game.pulse()
				log_event("scripted_full_charge_pulse", {"injected_energy": 100.0, "normal_game_pulse_called": true})
				next_pulse += 1
		if now >= next_sample:
			telemetry.append(combat_snapshot(now))
			next_sample += 1.0
		await process_frame
	if next_mode != MODES.size() or next_pulse != PULSE_TIMES.size():
		if failure.is_empty(): failure = "Not all scripted weapon/pulse events occurred."
	var hostile_shots_observed := false
	for sample: Dictionary in telemetry:
		if sample.hostile_shots > 0: hostile_shots_observed = true
	if not guardian_staged or not hostile_shots_observed:
		if failure.is_empty(): failure = "The staged Guardian encounter did not produce observed hostile projectiles."
	await finish_capture()


func verify_music_loop() -> void:
	# A separate transport check before recording: seek near the real stream end
	# and require the same live playback to wrap. No judgement of audible seam quality.
	var player: AudioStreamPlayer = game.sound._music
	var stream := player.stream as AudioStreamOggVorbis
	if stream == null or not stream.loop or not player.playing:
		failure = "Approved music did not start with an enabled Ogg loop."
		return
	var seek_position := maxf(0.0, stream.get_length() - 0.8)
	player.seek(seek_position)
	# AudioStreamPlayer may replace its playback during seek. Capture the
	# post-seek handle after the command reaches the native audio thread.
	await create_timer(0.12).timeout
	var playback = player.get_stream_playback()
	var position_before := player.get_playback_position()
	var has_counter: bool = playback.has_method("get_loop_count")
	var before_loops: int = int(playback.call("get_loop_count")) if has_counter else -1
	await create_timer(0.95).timeout
	var after_loops: int = int(playback.call("get_loop_count")) if has_counter else -1
	var position := player.get_playback_position()
	var same_playback: bool = player.get_stream_playback() == playback
	var near_end: bool = position_before > stream.get_length() - 0.9 and position_before < stream.get_length()
	var passed: bool = near_end and player.playing and same_playback and position >= 0.0 and position < 0.8
	loop_check = {"passed": passed, "seek_seconds": seek_position, "settle_seconds": 0.12, "wait_seconds": 0.95,
		"position_before_wait": position_before,
		"position_after_wait": position, "loop_counter_supported": has_counter,
		"loops_before": before_loops, "loops_after": after_loops, "same_playback": same_playback,
		"note": "Transport wrap verified before recording; no listening or beat-grid claim."}
	playback = null
	if not passed: failure = "Approved music failed the native loop-wrap transport check."


func elapsed() -> float:
	return float(Time.get_ticks_usec() - started_usec) / 1000000.0 if started_usec > 0 else 0.0


func log_event(kind: String, details: Dictionary) -> void:
	var entry := {"seconds": elapsed(), "kind": kind}
	entry.merge(details)
	events.append(entry)
	print("AUDIO_CAPTURE_EVENT ", JSON.stringify(entry))


func install_weapon(mode: String) -> void:
	game.weapons.ranks[mode] = 3
	game.weapons.mode = mode
	game.weapons.refresh_model()
	game.cue("weapon_install")
	# One explicitly staged opponent guarantees a target near each installation;
	# movement, telegraphs, projectile collision and damage then run normally.
	var at: Vector3 = game.player_position + Vector3(4.0, 0, -3.0)
	at = Vector3(clampf(at.x, -12.0, 12.0), 0, clampf(at.z, -12.0, 12.0))
	var target: Node3D = game.spawn_enemy("gunner", at)
	log_event("scripted_weapon_install", {"mode": mode, "rank": 3, "spawned_gunner": is_instance_valid(target), "spawn_position": [at.x, at.y, at.z]})


func stage_guardian() -> void:
	var health_before: float = game.rules.health
	# This explicit audition jump is not campaign progression. Complete only the
	# relay bookkeeping needed by the real boss-entry route: award no relay heals,
	# charge, score or upgrades. boss_started makes the production pilot fight
	# instead of following a relay, and prevents route spawns/early exit opening.
	game.campaign.enter_sector(2)
	game.campaign.relays = game.campaign.relay_goal()
	game.campaign.create_target()
	game.campaign.boss_started = true
	game.begin_campaign_boss()
	guardian_staged = true
	var escorts: Array[Dictionary] = []
	for spec: Array in [["gunner", Vector3(-8, 0, 2)], ["gunner", Vector3(8, 0, 2)], ["bruiser", Vector3(-10, 0, -6)], ["bruiser", Vector3(10, 0, -6)]]:
		var enemy: Node3D = game.spawn_enemy(spec[0], spec[1])
		if is_instance_valid(enemy): escorts.append({"kind": spec[0], "position": [spec[1].x, spec[1].y, spec[1].z]})
	log_event("scripted_guardian_encounter", {"sector_jump": 3, "relay_bookkeeping_skipped": game.campaign.relay_goal(), "production_entry": "game.begin_campaign_boss", "health_before": health_before, "health_after_production_entry": game.rules.health, "production_recovery_seconds": game.rules.recovery, "guardian_health": game.boss_ref.hp, "scripted_escorts": escorts, "intensity_source": "unmodified game.update_battle_audio; actual enemies and incoming projectiles"})


func combat_snapshot(now: float) -> Dictionary:
	var boss_alive: bool = is_instance_valid(game.boss_ref) and not game.boss_ref.dead
	return {"seconds": now, "game_seconds": game.run_time, "state": game.state, "sector": game.campaign.sector + 1, "health": game.rules.health, "enemies": game.enemies.size(), "hostile_shots": game.field.bullets.size(), "weapon": game.weapons.mode, "weapon_shots": game.weapons.shots_fired, "music_intensity": game.sound.get_intensity(), "boss_alive": boss_alive, "boss_health": game.boss_ref.hp if boss_alive else 0.0, "boss_phase": game.boss_ref.phase if boss_alive else 0}


func finish_capture() -> void:
	var record_seconds := elapsed()
	if is_instance_valid(game):
		game.set_physics_process(false)
		game.set_process(false)
	if recorder:
		recorder.set_recording_active(false)
		recording = recorder.get_recording()
		# Remove our exact effect only; retain the production limiter and bus state.
		for index: int in range(AudioServer.get_bus_effect_count(master) - 1, -1, -1):
			if AudioServer.get_bus_effect(master, index) == recorder:
				AudioServer.remove_bus_effect(master, index)
				break
		recorder = null
	var stats: Dictionary = {}
	var wav_path := output_dir.path_join("release-engine-audio.wav")
	if recording:
		var pcm: PackedByteArray = recording.data
		var peak := 0
		var squares := 0.0
		var clipped := 0
		var analyzed_samples := 0
		var sample_count: int = pcm.size() / 2
		for index: int in range(sample_count):
			if index % 8192 == 0 and float(Time.get_ticks_usec() - boot_usec) / 1000000.0 > HARD_DEADLINE - 0.5:
				failure = "PCM analysis reached the recording deadline."
				break
			var sample: int = pcm.decode_s16(index * 2)
			peak = maxi(peak, absi(sample))
			squares += float(sample) * float(sample)
			analyzed_samples += 1
			if absi(sample) >= 32760: clipped += 1
		var rms := sqrt(squares / float(maxi(1, analyzed_samples))) / 32768.0
		var channels := 2 if recording.stereo else 1
		var audio_seconds := float(sample_count) / float(recording.mix_rate * channels)
		stats = {"sample_rate": recording.mix_rate, "channels": channels, "pcm_bits": 16, "pcm_bytes": pcm.size(), "audio_seconds": audio_seconds, "analyzed_samples": analyzed_samples, "peak": float(peak) / 32768.0, "rms": rms, "clipped_samples": clipped}
		if peak < 32 or rms < 0.00003:
			failure = "The captured Master mix is silent or effectively silent."
		if audio_seconds < DURATION - 0.5 or audio_seconds > DURATION + 2.0:
			if failure.is_empty(): failure = "Recorded PCM duration does not match the 36-second real-time session."
		var saved: Error = recording.save_to_wav(wav_path)
		if saved != OK or not FileAccess.file_exists(wav_path): failure = "Failed to save the engine WAV: %s." % error_string(saved)
		recording = null
	else:
		if failure.is_empty(): failure = "AudioEffectRecord returned no recording."
	var metadata := {"kind": "scripted_native_engine_master_audio", "music_path": ReleaseAudio.MUSIC_PATH, "music_sha256": FileAccess.get_sha256(APPROVED_MUSIC), "music_loop_check": loop_check, "human_playthrough": false, "progression_test": false, "performance_test": false, "success": failure.is_empty(), "failure": failure, "requested_seconds": DURATION, "wall_record_seconds": record_seconds, "volume": volume, "seed": seed_value, "recorded_after_limiter": not bus_effects.is_empty() and bus_effects[-1].get("class") == "AudioEffectRecord", "bus_effect_order": bus_effects, "engine": Engine.get_version_info().string, "audio_driver": AudioServer.get_driver_name(), "mix_rate": AudioServer.get_mix_rate(), "wav": wav_path, "pcm": stats, "scripted_events": events, "telemetry": telemetry, "notes": "Staged audio audition, not progression or performance evidence. First half installs four rank III weapons and spawns one gunner per install. At18s the tool jumps to sector3 and invokes the production Guardian entry with four scripted escorts. Two full charges are injected. Combat, pilot, enemy attacks and adaptive intensity remain production behavior; health/recovery only change through normal gameplay and production entry. No preference saves."}
	var file := FileAccess.open(output_dir.path_join("release-engine-audio.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata, "  "))
		file.close()
	else:
		failure = "Could not write recording metadata."
	if is_instance_valid(game):
		game.clear_run()
		game.queue_free()
		game = null
	await process_frame
	await create_timer(0.16).timeout
	if failure.is_empty(): print("Engine audio capture saved: ", wav_path, " (", stats.get("audio_seconds", 0.0), " seconds).")
	else: push_error("Engine audio capture failed: " + failure)
	quit(0 if failure.is_empty() else 1)
