# Independent release audio review

Reviewed on 2026-09-13 for the user's instruction to ship the first ElevenLabs candidate. This review covers audio asset provenance, runtime integration, targeted audio tests, and a native recording. It does not assign an auditory quality score or certify the complete game, distribution package, or performance benchmark.

No blocking audio integration issue was found. `scripts/audio_director.gd` selects `assets/audio/elevenlabs/music_reactor_rush.ogg`, the accepted first `music_v2` candidate. It plays as one looping track with smoothed combat gain and essential-cue ducking. The runtime carries no unmeasured BPM or beat-count metadata. The heavier audition remains outside the runtime selection.

`qa/release-audio.json` records the approved source hashes and all ten installed assets. Independent checks verified every release asset hash, finite stereo decoding at 44.1 kHz, and zero samples at or above full scale. The five direct effects are byte-identical to their accepted prepared WAVs. The installer initially requantized those copies by up to one integer sample step; that review finding was corrected by copying the validated files directly. Scatter, arc, Guardian destruction, and weapon installation are explicitly documented local derivatives of the accepted effects.

The music retains the approved 44.199184-second arrangement. Its measured first-to-last decoded sample difference is 0.0000144. This supports a small sample discontinuity at the boundary, not a claim of a musically seamless or beat-aligned loop.

Targeted Godot 4.7.2 checks passed:

- `tests/resonance_audio_test.gd`: 47 checks, zero failures. Covers first-candidate selection, Ogg source/container and runtime duration agreement, explicit loop settings, accepted cue paths, single-gain application, combat response and smoothing, playback continuity, ducking and recovery, mute/volume, limiter, and production callback ordering.
- `tests/audio_test.gd`: 44 checks, zero failures. Retains effect import, cooldown, pitch variation, bounded voice pool, reserved essential feedback, priority replacement, ducking, mute/volume, and unknown-cue coverage.

`tools/release_audio_capture.gd` produced a separate 36.010667-second native recording in `qa/release-native-audio/release-engine-audio.wav`, with metadata alongside it. The command ran on the M4 using Metal and CoreAudio, with game volume 0.65. Recording occurs after the enabled production Master limiter. The recorder uses production combat and pilot behavior with four explicitly injected rank III weapon installations, staged opponents and Guardian entry, and two injected full-charge pulses. It is an automated audio demonstration, not a human playthrough or progression/performance test.

Independent analysis of all 3,457,024 interleaved PCM samples confirmed 48 kHz stereo, peak 0.891235, RMS 0.137224, and zero samples at or above the recorder's 32760/32768 near-full-scale threshold. The metadata reports the actual runtime track path and matching current Ogg hash. Telemetry observed 24 weapon shots, up to seven hostile projectiles, and music intensity reaching 0.6437.

A separate native transport check ran before recording. After a settled seek, the playback advanced from 43.4224 seconds through the track boundary to 0.0882 seconds, retained the same post-seek playback object, and increased its loop counter from zero to one. The initial test incorrectly compared the pre-seek playback handle and failed before recording; its metadata is preserved as `qa/release-native-audio/initial-loop-assertion.json`. The corrected check accounts for Godot replacing a playback object during seeking.

Historical Resonance recordings were not overwritten. The reviewer made no API requests, read no private key, and did not listen to the recording. These results establish technical integration and measured playback behavior; they do not establish perceived mix balance, loop appeal, or an overall game rating.
