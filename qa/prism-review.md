# Independent Prism Drive audio review

Reviewed on 2026-09-13 on `feat/prism-drive-music`. Scope: the new music request's provenance, local preparation, runtime selection, targeted audio integration checks, and a native combat recording. The reviewer did not read the private key, call the generation API, listen to the audio, or certify stylistic similarity, compositional originality, exact tempo, or game quality.

No blocking technical integration issue was found. The completed `prism_drive` receipt records a `music_v2_5` generation request for an instrumental track using musical characteristics. The request contains no reference recording or artist/song name. The provider original matches the receipt SHA-256, and the runtime Ogg and both preview MP3s match `qa/prism-music.json`.

Preparation retains the full 102.426122-second track, normalizes loudness, applies 10 ms boundary fades, and writes Vorbis in bounded blocks. The final artifact successfully decodes independently through ffmpeg. The initial large-write library crash and rejected shorter boundary fade were resolved before this review's runtime checks. Numerical results for the delivered files are:

| Asset | Duration | Sample peak | Integrated loudness | Full-scale samples |
| --- | ---: | ---: | ---: | ---: |
| Runtime Ogg | 102.426122 s | -1.352 dBFS | -13.97 LUFS | 0 |
| Music preview MP3 | 102.426122 s | -2.096 dBFS | -14.10 LUFS | 0 |
| Offline battle preview MP3 | 44.200249 s | -2.154 dBFS | — | 0 |

The provider MP3 originally decoded with 12 samples above full scale and a +0.442 dBFS peak. The prepared outputs retain headroom. Detectable music energy begins at approximately 20 ms in both the original and delivered files, using a 5 ms RMS analysis window. The runtime endpoint sample difference is 0.002131. These measurements establish decoding and sample behavior; they do not prove a perceptually seamless loop or that the music matches the requested style.

All nine existing combat WAVs and the preceding Reactor Rush Ogg are byte-identical to their files in `HEAD`, independently checked against the preparation manifest. The runtime diff changes the selected music path and its descriptive comment. Combat cue gains, ducking, cooldowns, and voice-priority rules are unchanged. The offline preview uses the current 0.75 pulse-duck amount and is explicitly labeled as a montage without production pitch variation or voice limiting.

After asset reimport, `tests/resonance_audio_test.gd` passed all 47 checks in Godot 4.7.2. Its selected resource and duration expectations now cover Prism Drive. It retains source/container versus runtime duration agreement, explicit looping, zero unverified BPM/beat-count metadata, accepted cue mapping, finite single-gain application, combat response and smoothing, playback continuity, pulse duck/recovery, mute/volume, limiter, voice budget, and production callback-order checks.

The generalized recorder ran natively on the M4 using Metal and CoreAudio at game volume 0.65. `qa/prism-native-audio/release-engine-audio.wav` contains 36.010667 seconds of 48 kHz stereo recorded after the production Master limiter. Independent analysis of all 3,457,024 interleaved PCM samples confirmed peak 0.792969, RMS 0.132521, and zero samples at or above the recorder's 32760/32768 near-full-scale threshold. The accompanying metadata names the Prism runtime resource and carries its current Ogg hash. Telemetry observed 23 weapon shots, up to seven hostile projectiles, and intensity reaching 0.6632.

Before recording, a separate native transport check observed the selected music advancing from 101.6493 seconds through its boundary to 0.1085 seconds on the same post-seek playback. Its loop counter increased from zero to one. This verifies repetition without certifying the audible seam.

The recording uses production combat and pilot behavior with explicitly staged rank III weapon installations, opponents and Guardian entry, and two injected full-charge pulses. It is an automated audio demonstration, not a human playthrough or progression/performance benchmark. Previous audio and review evidence remain separate. No listening score or overall game rating is assigned.
