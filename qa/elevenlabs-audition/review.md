# ElevenLabs audition review

Reviewed on 2026-09-13 by the independent audio tooling review agent. Scope: `tools/generate_elevenlabs_audio.py`, `tools/prepare_elevenlabs_audition.py`, receipt integrity, delivered preview measurements, and audition page wording. This was an offline code and numerical review. The reviewer did not read the private key, call ElevenLabs, listen to the audio, or evaluate the sounds in Godot.

No blocking defect found in the current private audition workflow. Two generator findings were corrected and verified: completed assets now reject changed request parameters, and interrupted downloads retain provider recovery identifiers. Exclusive receipt creation, refusal to resubmit failed requests, and redirect rejection protect against duplicate submissions and accidental credential forwarding. The rejected oversized plasma prompt has a separate preserved receipt; the successful revised request has its own completed receipt.

Nine regression tests pass with dummy credentials, fake responses, and temporary files only. They cover the default dry run, completed and interrupted request reuse, altered requests and downloads, unreceipted output, provider error redaction, redirect rejection, and prompt length rejection before credential access. Run with:

```sh
python3 -B -m unittest discover -s tests -p test_elevenlabs_generator.py
```

All six provider originals match their receipt SHA-256 hashes and decode to finite stereo PCM. Preparation preserves those originals, trims SFX padding using a 5 ms RMS window, fades the edges, applies SFX gain, and normalizes the music before generating previews. All eight preview hashes match `preparation.json`. Independently decoding each preview produced these results:

| Preview | Duration | Sample peak | Samples at or above full scale |
| --- | ---: | ---: | ---: |
| Reactor Rush | 44.199 s | -1.508 dBFS | 0 |
| Kinetic fire | 0.394 s | -3.183 dBFS | 0 |
| Plasma fire | 1.407 s | -3.387 dBFS | 0 |
| Armor hit | 0.364 s | -3.039 dBFS | 0 |
| Enemy break | 2.036 s | -3.316 dBFS | 0 |
| Reactor pulse | 2.689 s | -3.265 dBFS | 0 |
| Effects reel | 14.500 s | -3.129 dBFS | 0 |
| Battle preview | 44.199 s | -2.232 dBFS | 0 |

All five individual SFX have detectable energy in the first analysis window, matching the reported prepared onset of 0 ms. This establishes prompt onset at roughly 5 ms resolution; it does not establish perceived attack quality or absence of unwanted secondary events.

The stored loudness measurements report music at -14.10 LUFS / -1.39 dBTP and the battle preview at -16.70 LUFS / -2.17 dBTP. The music normalization setting of -1.5 dBTP should be described as a target: MP3 encoding produced the measured -1.39 dBTP peak. Raw kinetic, plasma, and enemy-break MP3s decode above full scale, while the prepared previews retain headroom. Decode overshoot alone does not establish source distortion.

The preview correctly identifies its battle mix as an offline scripted montage and 174 BPM as a requested target. Listening is still required to judge the aggressive DnB character, bass/drum balance, SFX identity, repeated-shot fatigue, and emotional impact. Tempo accuracy, seamless looping, dynamic stem synchronization, and gameplay mixing were not certified. No listening score or overall game rating is assigned by this review.

## Heavier music revision

The same reviewer checked the subsequent `reactor_rush_heavy` revision after the user requested heavier bass and drums. Its completed receipt records a new `music_v2_5` request and preserves the first `music_v2` request separately. Both originals match their receipt hashes. All eight first-version preview hashes still match the original preparation report. Shared effects and the effects reel have identical hashes in both reports, and both battle montages use the same event schedule.

The preparation selector writes the heavier music, battle preview, and report to distinct names. It targets the first version's measured integrated loudness separately for music and battle playback. The final `save_matched` pass measures the encoded MP3, applies a small gain correction to PCM, re-encodes, and checks the measured result within 0.03 LU. It checks gain headroom before correction and rejects encoded full-scale samples. Independent decoding and loudness measurement of the final files confirmed:

| Comparison | First version | Heavier revision | Difference |
| --- | ---: | ---: | ---: |
| Music integrated loudness | -14.10 LUFS | -14.11 LUFS | 0.01 LU |
| Battle integrated loudness | -16.70 LUFS | -16.70 LUFS | 0.00 LU |
| Music estimated true peak | -1.39 dBTP | -1.24 dBTP | — |
| Battle estimated true peak | -2.17 dBTP | -2.98 dBTP | — |

The heavier music and battle previews last 44.147 seconds and decode to finite stereo PCM with zero samples at or above full scale. Their sample peaks are -1.224 dBFS and -2.964 dBFS respectively. The measured integrated levels match the first version within 0.01 LU at the measurement precision reported by ffmpeg. This supports the page's loudness comparison claim and limits a simple playback-level bias; it does not prove equal perceived loudness for different musical arrangements or that the revision has stronger bass and drums. The first version's preview hashes and the shared cue hashes remain unchanged after the final correction.

Static inspection of the page confirms that the A/B buttons select the corresponding music and battle files, update pressed states and accessible labels, and keep playback volume unchanged. Switching versions reloads each selected player from the start. The page describes the sound direction as requested, without assigning a listening score. This review did not exercise the controls in a browser or listen to either version. The earlier limits on tempo, loop quality, gameplay mixing, and game rating remain.
