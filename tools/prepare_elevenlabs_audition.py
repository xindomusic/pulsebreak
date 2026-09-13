#!/usr/bin/env python3
"""Prepare downloaded audition audio locally; no credentials or API calls.

Requires NumPy and ffmpeg. Preserve provider originals and generation receipts.
Outputs individual previews, a cue reel, and a scripted (not engine) battle mix.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "qa/elevenlabs-audition"
PCM = RAW / "prepared"
PREVIEW = ROOT / "docs/audio/elevenlabs"
RATE = 44100
NAMES = ["reactor_rush", "kinetic_fire", "plasma_fire", "armor_hit", "enemy_break", "reactor_pulse"]


def ffmpeg(arguments, data=None):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostdin"] + arguments,
                          input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)


def decode(path, filters=None):
    arguments = ["-loglevel", "error", "-i", str(path)]
    if filters:
        arguments += ["-af", filters]
    result = ffmpeg(arguments + ["-f", "f32le", "-ar", str(RATE), "-ac", "2", "pipe:1"])
    data = np.frombuffer(result.stdout, dtype="<f4").reshape(-1, 2).copy()
    if not len(data) or not np.isfinite(data).all():
        raise ValueError("Empty or invalid decoded audio: " + path.name)
    return data


def loudness(path, integrated=-14, true_peak=-1.5):
    config = "loudnorm=I={}:TP={}:LRA=11:print_format=json".format(integrated, true_peak)
    result = ffmpeg(["-i", str(path), "-af", config,
                     "-f", "null", "-"])
    output = result.stderr.decode()
    return json.JSONDecoder().raw_decode(output[output.rfind("{"):])[0]


def normalize(path, integrated=-14, true_peak=-1.5):
    measured = loudness(path, integrated, true_peak)
    config = "loudnorm=I={}:TP={}:LRA=11:linear=true".format(integrated, true_peak)
    for field, source in (("measured_I", "input_i"), ("measured_TP", "input_tp"),
                          ("measured_LRA", "input_lra"), ("measured_thresh", "input_thresh"),
                          ("offset", "target_offset")):
        config += ":" + field + "=" + measured[source]
    return decode(path, config), measured


def statistics(data):
    peak = float(np.max(np.abs(data)))
    rms = float(np.sqrt(np.mean(data.astype(np.float64) ** 2)))
    return {"duration_seconds": len(data) / RATE, "sample_peak": peak,
            "peak_dbfs": float(20 * np.log10(max(peak, 1e-12))), "rms": rms,
            "samples_at_or_above_full_scale": int(np.sum(np.abs(data) >= 1)),
            "dc_offset_per_channel": np.mean(data.astype(np.float64), axis=0).tolist()}


def bounds(data):
    window = round(RATE * 0.005)
    power = np.mean(data.astype(np.float64) ** 2, axis=1)
    energy = np.sqrt(np.mean(np.pad(power, (0, (-len(power)) % window)).reshape(-1, window), axis=1))
    threshold = max(10 ** (-50 / 20), float(energy.max()) * 10 ** (-32 / 20))
    active = np.flatnonzero(energy > threshold)
    if not len(active):
        raise ValueError("No audible signal detected")
    return int(active[0] * window), min(len(data), int((active[-1] + 1) * window))


def save(name, data):
    if not np.isfinite(data).all() or np.max(np.abs(data)) >= 1:
        raise ValueError("Invalid or clipping mix: " + name)
    wav = PCM / (name + ".wav")
    with wave.open(str(wav), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(np.round(data * 32767).astype("<i2").tobytes())
    mp3 = PREVIEW / (name + ".mp3")
    ffmpeg(["-loglevel", "error", "-i", str(wav), "-codec:a", "libmp3lame", "-b:a", "192k",
            "-map_metadata", "-1", "-y", str(mp3)])
    decoded = decode(mp3)
    measurements = statistics(decoded)
    if measurements["samples_at_or_above_full_scale"]:
        raise ValueError("Encoded audition clips: " + name)
    return {"wav": str(wav.relative_to(ROOT)), "preview": str(mp3.relative_to(ROOT)),
            "sha256": hashlib.sha256(mp3.read_bytes()).hexdigest(),
            "prepared_pcm": statistics(data), "decoded_mp3": measurements}


def save_matched(name, data, target_lufs):
    """Match measured encoded loudness, including small MP3/normalizer offsets."""
    result = save(name, data)
    for _ in range(3):
        measured = loudness(PREVIEW / (name + ".mp3"))
        difference = target_lufs - float(measured["input_i"])
        if abs(difference) <= 0.03:
            result.update(preview_loudness=measured, matched_target_lufs=target_lufs)
            return result, data
        gain = 10 ** (difference / 20)
        if float(np.max(np.abs(data))) * gain >= 10 ** (-1 / 20):
            raise ValueError("Insufficient headroom for loudness comparison: " + name)
        data = data * gain
        result = save(name, data)
    raise ValueError("Encoded loudness comparison did not converge: " + name)


def place(mix, data, seconds, gain=1.0):
    start = round(seconds * RATE)
    count = min(len(data), len(mix) - start)
    if count > 0:
        mix[start:start + count] += data[:count] * gain


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--music", choices=["reactor_rush", "reactor_rush_heavy"], default="reactor_rush")
    args = parser.parse_args()
    music_name = args.music
    names = [music_name] + NAMES[1:]
    suffix = "_heavy" if music_name == "reactor_rush_heavy" else ""
    baseline = json.loads((RAW / "preparation.json").read_text()) if suffix else None
    # Validate every input before producing output or touching existing previews.
    receipts = {}
    for name in names:
        receipts[name] = json.loads((RAW / (name + ".json")).read_text())
        raw_path = RAW / (name + ".mp3")
        if receipts[name]["status"] != "complete" or hashlib.sha256(raw_path.read_bytes()).hexdigest() != receipts[name]["sha256"]:
            raise ValueError("Incomplete or changed original: " + name)
    PCM.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    report = {"method": "Local processing of ElevenLabs outputs. Numerical checks, not a listening review.",
              "music_asset": music_name,
              "music": "Requested 174 BPM; not measured or certified as a seamless loop.",
              "battle_preview": "Offline scripted montage, not recorded gameplay; audition gains are not production settings.",
              "assets": {}, "events": []}
    sounds = {}
    for name in names:
        path = RAW / (name + ".mp3")
        original = decode(path)
        extra = {"original_sha256": receipts[name]["sha256"], "original": statistics(original)}
        if name == music_name:
            prepared, measured = normalize(path)
            extra.update(original_loudness=measured, processing="Two-pass loudness normalization targeting -14 LUFS and -1.5 dBTP before MP3 encoding.")
        else:
            first, last = bounds(original)
            start = max(0, first - round(0.006 * RATE))
            end = min(len(original), last + round(0.08 * RATE))
            prepared = original[start:end].copy()
            attack = min(round(0.001 * RATE), len(prepared))
            release = min(round(0.025 * RATE), len(prepared))
            prepared[:attack] *= np.linspace(0, 1, attack)[:, None]
            prepared[-release:] *= np.linspace(1, 0, release)[:, None]
            gain = 10 ** (-3 / 20) / float(np.max(np.abs(prepared)))
            prepared *= gain
            extra.update(raw_onset_ms=first / RATE * 1000, trimmed_start_ms=start / RATE * 1000,
                         prepared_onset_ms=bounds(prepared)[0] / RATE * 1000,
                         gain_db=float(20 * np.log10(gain)),
                         processing="Trim quiet padding, 1 ms attack / 25 ms release edge fades, -3 dBFS sample peak.")
        if name == music_name and baseline:
            target = float(baseline["assets"]["reactor_rush"]["preview_loudness"]["input_i"])
            saved, prepared = save_matched(name, prepared, target)
            extra.update(saved)
        else:
            extra.update(save(name, prepared))
        sounds[name] = prepared
        if name == music_name and not baseline:
            extra["preview_loudness"] = loudness(PREVIEW / (name + ".mp3"))
        report["assets"][name] = extra

    reel_events = [(0.3, "kinetic_fire"), (2.3, "plasma_fire"), (5.1, "armor_hit"),
                   (7.0, "enemy_break"), (10.8, "reactor_pulse")]
    reel = np.zeros((round(14.5 * RATE), 2), dtype=np.float32)
    for seconds, name in reel_events:
        place(reel, sounds[name], seconds)
    report["reel_events"] = [{"seconds": t, "cue": n} for t, n in reel_events]
    report["assets"]["effects_reel"] = save("effects_reel", reel)

    events = []
    for start in (3.0, 8.0, 26.0, 34.0):
        for shot in range(7):
            events += [(start + shot * 0.28, "kinetic_fire", 0.78)]
            if shot % 2 == 0:
                events += [(start + shot * 0.28 + 0.09, "armor_hit", 0.44)]
    for start in (13.0, 18.0, 30.0):
        for shot in range(3):
            events += [(start + shot * 0.95, "plasma_fire", 0.92),
                       (start + shot * 0.95 + 0.2, "armor_hit", 0.44)]
    events += [(6.0, "enemy_break", 0.85), (16.5, "enemy_break", 0.85),
               (29.0, "enemy_break", 0.85), (21.5, "reactor_pulse", 1.12),
               (39.5, "reactor_pulse", 1.12)]
    timeline = np.arange(len(sounds[music_name])) / RATE
    duck = np.ones(len(timeline))
    for seconds, name, gain in events:
        if name == "reactor_pulse":
            relative = timeline - seconds
            envelope = np.where((relative >= 0) & (relative < 0.22), 10 ** (-6 / 20),
                                np.where((relative >= 0.22) & (relative < 1.0),
                                         10 ** (-6 * (1 - (relative - 0.22) / 0.78) / 20), 1.0))
            duck = np.minimum(duck, envelope)
    battle = sounds[music_name] * (duck * 0.75)[:, None]
    for seconds, name, gain in sorted(events):
        place(battle, sounds[name], seconds, gain)
        report["events"].append({"seconds": round(seconds, 3), "cue": name, "gain": gain})
    peak = float(np.max(np.abs(battle)))
    mix_gain = min(1.0, 10 ** (-2 / 20) / peak)
    battle *= mix_gain
    fade = round(0.12 * RATE)
    battle[-fade:] *= np.linspace(1, 0, fade)[:, None]
    report["battle_static_gain_db"] = float(20 * np.log10(mix_gain))
    battle_name = "battle_preview" + suffix
    report["assets"][battle_name] = save(battle_name, battle)
    if suffix:
        # Match the first audition's integrated level for a fair comparison.
        target = float(baseline["assets"]["battle_preview"]["preview_loudness"]["input_i"])
        battle, measured = normalize(PCM / (battle_name + ".wav"), target, -1.8)
        report["battle_loudness_match"] = {"reference": "battle_preview.mp3", "target_lufs": target,
                                            "measurement_before_matching": measured}
        report["assets"][battle_name], battle = save_matched(battle_name, battle, target)
    report["assets"][battle_name]["preview_loudness"] = loudness(PREVIEW / (battle_name + ".mp3"))
    (RAW / ("preparation" + suffix + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    for name, result in report["assets"].items():
        decoded = result["decoded_mp3"]
        print("{}: {:.2f}s, decoded peak {:.2f} dBFS, {} full-scale samples".format(
            name, decoded["duration_seconds"], decoded["peak_dbfs"], decoded["samples_at_or_above_full_scale"]))


if __name__ == "__main__":
    main()
