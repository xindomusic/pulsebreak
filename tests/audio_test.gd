extends SceneTree
## Objective asset/voice/mix-state checks. No speaker listening is claimed.
const AudioDirector = preload("res://scripts/audio_director.gd")
const NEW_CUES := ["kinetic_fire","scatter_fire","arc_fire","plasma_fire","armor_impact","machine_break","guardian_break","weapon_install"]
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+description)

func _initialize() -> void: call_deferred("run_checks")

func pcm_stats(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if not file or file.get_buffer(4).get_string_from_ascii()!="RIFF": return {}
	file.get_32()
	if file.get_buffer(4).get_string_from_ascii()!="WAVE": return {}
	var format := 0
	var channels := 0
	var rate := 0
	var bits := 0
	var pcm := PackedByteArray()
	while file.get_position()+8<=file.get_length():
		var kind := file.get_buffer(4).get_string_from_ascii()
		var length := file.get_32()
		var next := file.get_position()+length+(length%2)
		if next>file.get_length()+1: return {}
		if kind=="fmt ":
			format=file.get_16()
			channels=file.get_16()
			rate=file.get_32()
			file.get_32()
			file.get_16()
			bits=file.get_16()
		elif kind=="data": pcm=file.get_buffer(length)
		file.seek(next)
	if format!=1 or bits!=16 or channels!=2 or pcm.is_empty(): return {}
	var peak := 0
	var sum := 0.0
	var squared := 0.0
	var differences := 0
	var left := 0
	for index in range(0,pcm.size(),2):
		var sample: int=int(pcm[index])|(int(pcm[index+1])<<8)
		if sample>=32768: sample-=65536
		peak=maxi(peak,absi(sample))
		sum+=float(sample)/32768.0
		squared+=pow(float(sample)/32768.0,2)
		if index%4==0: left=sample
		elif sample!=left: differences+=1
	var samples: int=pcm.size()/2
	return {"rate":rate,"channels":channels,"bits":bits,"seconds":float(samples)/channels/rate,"peak":float(peak)/32768.0,"rms":sqrt(squared/samples),"dc":sum/samples,"stereo_differences":differences,"hash":FileAccess.get_sha256(path)}

func reset_voices(director: Node) -> void:
	for voice: AudioStreamPlayer in director._voices:
		voice.stop()
		voice.stream=null
		voice.set_meta("priority",-1)
		voice.set_meta("started",0.0)
	director._last_cue.clear()
	director._duck=0.0
	director._cue_sequence=0

func occupy(director: Node, index: int, priority: int, started: float) -> void:
	var voice: AudioStreamPlayer=director._voices[index]
	voice.stream=director._music.stream
	voice.set_meta("priority",priority)
	voice.set_meta("started",started)
	voice.play()

func run_checks() -> void:
	var hashes: Dictionary={}
	var fire_lengths: Dictionary={}
	var maximum_peak := 0.0
	for name: String in NEW_CUES:
		var stats:=pcm_stats("res://assets/audio/%s.wav" % name)
		check(not stats.is_empty(),name+" is readable stereo16-bit PCM")
		if stats.is_empty(): continue
		check(stats.rate==44100 and stats.seconds>=0.15 and stats.seconds<=2.0,name+" has the intended sample rate and a bounded cue duration")
		check(stats.peak<0.95 and stats.rms>0.01 and absf(stats.dc)<0.01 and stats.stereo_differences>100,name+" contains non-silent distinct channels without saturated PCM or large DC offset")
		hashes[stats.hash]=true
		maximum_peak=maxf(maximum_peak,stats.peak)
		if name.ends_with("_fire"): fire_lengths[stats.seconds]=true
	check(hashes.size()==NEW_CUES.size() and fire_lengths.size()==4,"weapon and impact assets have different PCM data and firing durations")

	var director=AudioDirector.new()
	root.add_child(director)
	await process_frame
	director.set_process(false)
	check(director._voices.size()==12 and director._streams.size()==director.CUE_NAMES.size(),"the director loads all declared cues into twelve reusable effect voices")
	var imported_stereo := true
	for name: String in NEW_CUES:
		var stream: AudioStreamWAV=director._streams.get(name) as AudioStreamWAV
		imported_stereo=imported_stereo and stream!=null and stream.stereo and stream.mix_rate==44100
	check(imported_stereo,"engine import preserves stereo and sample rate for all new cues")
	check(director._music.playing and director._pressure.playing and is_equal_approx(director._music.stream.get_length(),director._pressure.stream.get_length()),"both equal-length music stems start playback")
	check(director._music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and director._pressure.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and director._music.stream.loop_end>0,"both stems have explicit nonempty forward loops")

	reset_voices(director)
	director.play_cue("kinetic_fire")
	var sequence: int=director._cue_sequence
	director.play_cue("kinetic_fire")
	check(sequence==1 and director._cue_sequence==sequence,"repeat fire cues are rate limited within their cooldown")
	director._last_cue.kinetic_fire=Time.get_ticks_msec()/1000.0-0.2
	director.play_cue("kinetic_fire")
	check(director._cue_sequence==sequence+1,"a fire cue becomes available after its elapsed cooldown")
	var distinct_pitches: Dictionary={}
	for voice: AudioStreamPlayer in director._voices:
		if voice.playing: distinct_pitches[voice.pitch_scale]=true
	check(distinct_pitches.size()==2,"repeated shots receive bounded variation instead of one identical playback pitch")

	reset_voices(director)
	for index in range(9): occupy(director,index,1,float(10-index))
	director.play_cue("kinetic_fire")
	check(director._voices[8].stream==director._streams.kinetic_fire,"equal-priority saturation replaces the oldest eligible voice")
	var reserved_idle := true
	for index in range(9,12): reserved_idle=reserved_idle and not director._voices[index].playing
	check(reserved_idle,"ordinary weapon fire leaves the three essential-cue voices available")
	reset_voices(director)
	for index in range(9): occupy(director,index,9,float(index))
	director.play_cue("warning")
	check(director._voices[9].stream==director._streams.warning and director._voices[9].playing,"a danger warning can use reserved capacity while ordinary slots are occupied")
	sequence=director._cue_sequence
	director.play_cue("kinetic_fire")
	check(director._cue_sequence==sequence,"lower-priority firing cannot steal protected higher-priority voices")
	reset_voices(director)
	for index in range(12): occupy(director,index,9,float(index))
	director.play_cue("victory")
	check(director._voices[0].stream==director._streams.victory,"a major result cue can replace the oldest lower-priority saturated voice")

	reset_voices(director)
	director.set_volume(1)
	director.set_intensity(0)
	director._smooth_intensity=0
	director._process(0)
	var music_before: float=director._music.volume_db
	director.play_cue("pulse")
	director._process(0)
	check(director._music.volume_db<music_before-4.0,"a major combat cue ducks the music level immediately on the next mix-state update")
	director._process(1.0)
	check(is_equal_approx(director._music.volume_db,music_before),"music gain recovers after the bounded duck envelope")
	var pressure_before: float=director._pressure.volume_db
	director.set_intensity(2.0)
	director._process(1.0)
	check(director._intensity==1.0 and director._pressure.volume_db>pressure_before,"clamped combat intensity raises the pressure stem")

	director.set_muted(true)
	sequence=director._cue_sequence
	director.play_cue("guardian_break")
	var silent: bool = director._music.volume_db<=-80 and director._pressure.volume_db<=-80
	for voice: AudioStreamPlayer in director._voices: silent=silent and voice.volume_db<=-80
	check(silent and director._cue_sequence==sequence,"mute attenuates current playback and suppresses new cue requests")
	director.set_muted(false)
	director.set_volume(-3)
	director.play_cue("weapon_install")
	check(director._volume==0 and director._cue_sequence==sequence,"zero/clamped-negative volume suppresses new sounds")
	director.set_volume(4)
	director.play_cue("weapon_install")
	check(director._volume==1 and director._cue_sequence==sequence+1,"restoring volume resumes valid cue playback")
	sequence=director._cue_sequence
	director.play_cue("missing_cue")
	check(director._cue_sequence==sequence and director._voices.size()==12,"unknown cues are safe and cannot expand the voice budget")
	director.queue_free()
	await process_frame
	await process_frame
	print("Audio: %d checks, %d failures; source PCM peak %.4f; numeric/runtime checks only, no audition" % [checks,failures,maximum_peak])
	quit(1 if failures else 0)
