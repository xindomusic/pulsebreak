# Pulsebreak audio audition

[Open the listening page](audio/elevenlabs/index.html) and start with **Battle mix**. **Heavier revision** is selected by default; the **First version** button switches both the music and battle players for comparison.

## Heavier revision

After hearing the first ElevenLabs audition, the player requested heavier bass and drums. One additional 44-second track was generated with `music_v2_5`: dominant hard drums, thick snare body, more audible bass weight and movement, sparse synth punctuation, and immediate full-energy playing. This is a separately generated composition, not a volume increase applied to the first track. The five combat effects and scripted cue schedule are shared between versions.

- [Heavier battle mix](audio/elevenlabs/battle_preview_heavy.mp3).
- [Heavier music alone](audio/elevenlabs/reactor_rush_heavy.mp3).

Playback loudness is matched after MP3 encoding: music measures **−14.10 LUFS for A and −14.11 LUFS for B**, while both battle mixes measure **−16.70 LUFS**. The final revision's estimated true peaks are −1.24 dBTP for music and −2.98 dBTP for the battle mix. All delivered files retain headroom. The [revision preparation report](../qa/elevenlabs-audition/preparation_heavy.json) records the matching and measurements. All first-version MP3 hashes still match the original report.

## First audition

- [Battle mix](audio/elevenlabs/battle_preview.mp3): 44.20 seconds of music with scripted combat cues.
- [Reactor Rush](audio/elevenlabs/reactor_rush.mp3): the music by itself.
- [Effects reel](audio/elevenlabs/effects_reel.mp3): kinetic shot, plasma shot, armor impact, robot destruction, reactor overload, in that order.

The track was generated with ElevenLabs `music_v2`, requesting instrumental 174 BPM drum and bass with rolling breaks, snare body, distorted Reese bass and immediate energy. The five effects use `eleven_text_to_sound_v2`. These are new generated audio files, distinct from the earlier procedural Resonance score. Requested genre, instrument descriptions and tempo describe the brief; they are not a listening verdict or a measured tempo certification.

This is an audition package. The battle mix is an offline montage, not an engine capture. It demonstrates kinetic shots at 0.28-second intervals, plasma at 0.95-second intervals, impacts, robot destruction and two reactor pulses. Music dips briefly under the reactor pulses. Its audition gains are documented in the preparation report and do not represent the production mixer. It has not been loop-edited or split into synchronized adaptive stems.

## Preparation and checks

Provider originals, exact prompts and receipts are in [qa/elevenlabs-audition](../qa/elevenlabs-audition/). Original files are checked against SHA-256 receipts before preparation. A rejected plasma prompt exceeded the provider's 450-character SFX limit; that rejection is retained in `rejected/`, and the corrected shorter prompt succeeded. Successful requests were reused, with no automatic paid retries.

Preparation removes quiet end padding from effects, applies brief edge fades and sets effect sample peaks to −3 dBFS. All five effects begin within the first 5 ms analysis window. The music uses two-pass normalization targeting −14 LUFS. The delivered MP3 measures −14.10 LUFS with a −1.39 dBTP estimated true peak; the scripted battle mix measures −16.70 LUFS and −2.17 dBTP. Lossy encoding can shift peaks slightly from normalization targets. All eight delivered MP3 files decode successfully with finite stereo samples and zero samples at or above full scale.

The [preparation report](../qa/elevenlabs-audition/preparation.json) contains original and prepared measurements, output hashes, trim amounts and the complete montage event schedule. The [independent review](../qa/elevenlabs-audition/review.md) separates technical verification from listening. These checks do not establish that the music is enjoyable, that effects contain exactly one perceptual event, or that the game deserves a 9/10 rating. The next creative decision depends on hearing this batch.

## Local tools

The credential is read only by the generation tool from `~/.config/pulsebreak/elevenlabs.env`; it is outside the checkout and is never included in a Godot resource, receipt, preview or command argument. The audition page and preparation tool do not need the key or network access.

```sh
# Show the plan without reading credentials or using the network.
python3 tools/generate_elevenlabs_audio.py

# Submit paid requests only for assets without receipts; completed matches are reused.
# An incomplete receipt blocks resubmission until it has been investigated.
python3 tools/generate_elevenlabs_audio.py --generate

# Rebuild previews from downloaded originals, without further API use.
python3 tools/prepare_elevenlabs_audition.py
python3 tools/prepare_elevenlabs_audition.py --music reactor_rush_heavy

# Exercise credential and duplicate-request guards with mocked networking only.
python3 -m unittest discover -s tests -p 'test_elevenlabs_generator.py'
```

The generator blocks redirects and saves recovery identifiers before streaming a response. Existing receipts must match the current request and output hash. It stops at the first failed request. Generation receipts allow recovery and auditing; the provider does not guarantee that repeating a prompt reproduces identical audio.

API references: [music generation](https://elevenlabs.io/docs/api-reference/music/compose), [sound generation](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert), and the [SFX prompt limit and generation guidance](https://elevenlabs.io/docs/eleven-creative/playground/sound-effects).
