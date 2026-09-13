# Prism Drive — music update 1.2

Release 1.2 changes Pulsebreak's background music to **Prism Drive**, an original half-time festival dubstep track generated with ElevenLabs. The creative brief targets 150 BPM, growling bass, sharp synth stabs, heavy kick/snare accents and brief tension breaks.

[Listen to the full track](audio/prism/prism_drive.mp3) · [Battle montage](audio/prism/battle_preview.mp3) · [Local listening page](audio/prism/index.html)

The complete 102.426-second composition is bundled as `assets/audio/elevenlabs/music_prism_drive.ogg`. It plays offline, loops and retains the existing smoothed combat intensity and blast ducking. Combat sounds, gameplay, controls and graphics retain their 1.1 behavior. The previous DnB track remains available in source and its original release ZIP.

## Build and provenance

[Download Pulsebreak 1.2.0](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0) for Mac. The release is tagged `v1.2.0` on `main`, with the universal app ZIP and checksums attached. Locally, open `build/Pulsebreak.app`. Use the [Mac export guide](MACOS_EXPORT.md) to reproduce the build with Godot 4.7.2. The source tree excludes generated application bundles; GitHub Releases hosts the download.

The [generation receipt](../qa/elevenlabs-audition/prism_drive.json) records the single `music_v2_5` request. [Preparation](../tools/prepare_prism_music.py) runs locally, without API access. It validates the provider hash, normalizes loudness, applies 10 ms boundary fades and encodes the full arrangement. Bounded Vorbis writes avoid a local encoder crash on a single full-length write. The [audio manifest](../qa/prism-music.json) records decoded levels, duration, boundary measurements and unchanged hashes for all previous release audio.

## Verification

All **591 checks in fourteen regression suites** passed, including 91 audio checks. The generator's nine offline safety tests also passed. The new runtime track measures -13.97 LUFS with a -1.35 dBFS decoded sample peak and zero full-scale samples. A 36-second CoreAudio capture passed the native loop transport check.

See the [independent audio review](../qa/prism-review.md), [native audio metadata](../qa/prism-native-audio/release-engine-audio.json), [regression log](../qa/prism-tests.log), [generator test log](../qa/prism-generator-tests.log) and [release package report](../qa/release-1.2-package.json). The battle montage is prepared offline; the native capture separately exercises production audio with staged weapons, threats and pulses.

Measured levels and a successful loop transport check establish technical playback behavior. They do not establish musical taste, an exact beat grid, an inaudible musical transition or a listening-quality rating. The [overall review](../qa/release-1.2-review.md) separately grades the available game evidence. The previous release's M4 performance measurements remain specific to that build.
