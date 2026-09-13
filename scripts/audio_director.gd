extends Node
## The player's accepted first ElevenLabs DnB track, played entirely offline.
## Threats shape music gain; reserved cue voices and blast ducking retain clarity.

const MUSIC_PATH := "res://assets/audio/elevenlabs/music_reactor_rush.ogg"
const RELEASE_CUES := ["kinetic_fire", "scatter_fire", "arc_fire", "plasma_fire", "armor_impact", "machine_break", "guardian_break", "weapon_install", "pulse"]

const CUE_NAMES: Array[String] = ["dash", "absorb", "pulse", "shoot", "hit", "kill", "warning", "upgrade", "boss", "core", "victory", "defeat", "ready", "kinetic_fire", "scatter_fire", "arc_fire", "plasma_fire", "armor_impact", "machine_break", "guardian_break", "weapon_install"]
const COOLDOWNS: Dictionary = {"shoot": 0.105, "absorb": 0.045, "kill": 0.080, "hit": 0.14, "warning": 0.42, "ready": 0.15, "kinetic_fire":0.09, "scatter_fire":0.15, "arc_fire":0.15, "plasma_fire":0.18, "armor_impact":0.055, "machine_break":0.10, "guardian_break":1.0}
const PRIORITIES: Dictionary = {"shoot": 0, "kill": 1, "absorb": 2, "dash": 3, "ready": 3, "core": 4, "warning": 5, "pulse": 6, "hit": 7, "upgrade": 8, "boss": 9, "victory": 10, "defeat": 10, "kinetic_fire":1, "scatter_fire":2, "arc_fire":2, "plasma_fire":3, "armor_impact":2, "machine_break":4, "guardian_break":9, "weapon_install":8}
const CUE_LEVELS: Dictionary = {"shoot": -3.9, "kill": -1.8, "absorb": -12.0, "dash": -11.0, "ready": -15.0, "core": -10.0, "warning": -10.0, "pulse": -2.5, "hit": -8.0, "upgrade": -9.0, "boss": -8.0, "victory": -7.0, "defeat": -9.0, "kinetic_fire":-3.9, "scatter_fire":-3.0, "arc_fire":-4.0, "plasma_fire":-2.5, "armor_impact":-4.2, "machine_break":-1.8, "guardian_break":-2.0, "weapon_install":-7.0}
const ABSORB_PITCHES: Array[float] = [1.0, 1.12246, 1.18921, 1.33484, 1.49831]

var _streams: Dictionary = {}
var _last_cue: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _volume: float = 0.8
var _muted: bool = false
var _intensity: float = 0.0
var _smooth_intensity: float = 0.0
var _absorb_step: int = 0
var _last_absorb: float = -10.0
var _duck: float = 0.0
var _cue_sequence: int = 0


static func cue_path(cue: String) -> String:
	if cue == "shoot": cue = "kinetic_fire"
	if cue == "kill": cue = "machine_break"
	return "res://assets/audio/elevenlabs/%s.wav" % cue if cue in RELEASE_CUES else "res://assets/audio/%s.wav" % cue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue: String in CUE_NAMES:
		var path := cue_path(cue)
		if ResourceLoader.exists(path):
			_streams[cue] = load(path)
	for index: int in range(12):
		var voice := AudioStreamPlayer.new()
		voice.name = "CueVoice%d" % index
		voice.set_meta("priority", -1)
		voice.set_meta("started", 0.0)
		voice.set_meta("level", -12.0)
		add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	_music.name = "ReactorRushMusic"
	if ResourceLoader.exists(MUSIC_PATH):
		var stream := load(MUSIC_PATH).duplicate() as AudioStreamOggVorbis
		stream.loop = true
		stream.loop_offset = 0.0
		# The provider's tempo brief is not a measured beat grid.
		stream.bpm = 0.0
		stream.beat_count = 0
		_music.stream = stream
	else:
		push_error("Missing release soundtrack: " + MUSIC_PATH)
	add_child(_music)
	_apply_music_levels()
	# Keep the accepted arrangement intact across combat and menu transitions.
	_music.play()


func _process(delta: float) -> void:
	_duck = move_toward(_duck,0.0,delta*1.1)
	var response := 3.5 if _intensity > _smooth_intensity else 0.75
	_smooth_intensity = lerpf(_smooth_intensity, _intensity, 1.0 - exp(-delta * response))
	_apply_music_levels()


func _gain_db() -> float:
	return -80.0 if _muted or _volume <= 0.001 else linear_to_db(_volume)


func _apply_music_levels() -> void:
	if not is_instance_valid(_music):
		return
	_music.volume_db = clampf(_gain_db()+mix_levels()[0]-_duck*8.0, -80.0, 0.0)


func mix_levels() -> PackedFloat32Array:
	# Full combat follows the accepted audition's music/effect balance.
	# A modest gain range keeps the full arrangement present between encounters.
	return PackedFloat32Array([lerpf(-10.0, -6.0, _smooth_intensity)])


func get_intensity() -> float:
	return _smooth_intensity


func set_battle_state(enemy_pressure: float, incoming_pressure: float, charge: float, boss: bool, active: bool) -> void:
	set_intensity(0.28 + _unit(enemy_pressure)*0.35 + _unit(incoming_pressure)*0.22 + _unit(charge)*0.10 + (0.20 if boss else 0.0) if active else 0.0)


func _unit(value: float) -> float:
	return clampf(value,0.0,1.0) if is_finite(value) else 0.0


func play_cue(cue_name: String, strength: float = 1.0) -> void:
	if _muted or _volume <= 0.001 or not _streams.has(cue_name):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var cooldown: float = float(COOLDOWNS.get(cue_name, 0.06))
	if now - float(_last_cue.get(cue_name, -100.0)) < cooldown:
		return
	var priority: int = int(PRIORITIES.get(cue_name, 3))
	var chosen: AudioStreamPlayer = null
	var oldest: float = INF
	# Three voices are reserved for essential feedback, so automatic fire
	# cannot consume the entire pool. Busy higher-priority cues are protected.
	var usable: int = 12 if priority >= 5 else 9
	for index: int in range(usable):
		var voice: AudioStreamPlayer = _voices[index]
		if not voice.playing:
			chosen = voice
			break
		var started: float = float(voice.get_meta("started"))
		if int(voice.get_meta("priority")) <= priority and started < oldest:
			oldest = started
			chosen = voice
	if chosen == null:
		return
	_last_cue[cue_name] = now
	chosen.stop()
	chosen.stream = _streams[cue_name]
	chosen.pitch_scale = 1.0
	_cue_sequence += 1
	if cue_name.ends_with("_fire") or cue_name in ["armor_impact","machine_break"]:
		chosen.pitch_scale = 0.97+float(_cue_sequence%5)*0.015
	if priority>=6: _duck=maxf(_duck,0.75)
	if cue_name == "absorb":
		if now - _last_absorb > 0.55:
			_absorb_step = 0
		chosen.pitch_scale = ABSORB_PITCHES[_absorb_step % ABSORB_PITCHES.size()]
		_absorb_step += 1
		_last_absorb = now
	elif cue_name == "pulse":
		chosen.pitch_scale = lerpf(1.12, 0.85, clampf(strength, 0.0, 1.5) / 1.5)
	var level: float = float(CUE_LEVELS.get(cue_name, -12.0)) + linear_to_db(clampf(strength, 0.35, 1.3))
	chosen.set_meta("priority", priority)
	chosen.set_meta("started", now)
	chosen.set_meta("level", level)
	chosen.volume_db = level + _gain_db()
	chosen.play()


func set_intensity(amount: float) -> void:
	_intensity = _unit(amount)


func set_volume(amount: float) -> void:
	_volume = _unit(amount)
	_refresh_volume()


func set_muted(value: bool) -> void:
	_muted = value
	_refresh_volume()


func _refresh_volume() -> void:
	_apply_music_levels()
	for voice: AudioStreamPlayer in _voices:
		voice.volume_db = clampf(float(voice.get_meta("level")) + _gain_db(), -80.0, 0.0)


func _exit_tree() -> void:
	# Release playback references while the audio server is still available.
	# Looping streams otherwise remain active until engine teardown.
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
		voice.stream = null
	if is_instance_valid(_music):
		_music.stop()
		_music.stream = null
	# Godot queues stop as FADE_OUT_TO_DELETION; the audio thread releases
	# its playback references on the following mix. Immediate engine exit
	# otherwise shuts the driver down before that mix can complete.
	OS.delay_usec(int(clampf(AudioServer.get_time_to_next_mix() + 0.04, 0.04, 0.10) * 1000000.0))
	_streams.clear()
	_voices.clear()
	_music = null
