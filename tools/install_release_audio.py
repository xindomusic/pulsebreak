#!/usr/bin/env python3
"""Install the accepted FIRST ElevenLabs audition as offline game assets.

No API calls. Validates the original audition hashes, preserves its arrangement,
and derives the remaining weapon roles from its accepted effect recordings.
Requires NumPy, SoundFile and ffmpeg; run preparation first on a fresh checkout.
"""
import hashlib
import json
from pathlib import Path
import shutil
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools/audio-python"))
import numpy as np
import soundfile as sf
from prepare_elevenlabs_audition import decode, statistics

AUDITION = ROOT / "qa/elevenlabs-audition"
DESTINATION = ROOT / "assets/audio/elevenlabs"
RATE = 44100


def pitch(data, rate):
    source = np.arange(len(data))
    positions = np.arange(0, len(data) - 1, rate)
    return np.column_stack([np.interp(positions, source, data[:, channel]) for channel in range(2)])


def layer(parts):
    count = max(round(seconds * RATE) + len(data) for seconds, data, _ in parts)
    result = np.zeros((count, 2))
    for seconds, data, gain in parts:
        start = round(seconds * RATE)
        result[start:start + len(data)] += data * gain
    return result


def finish(data, seconds=None):
    result = data[:round(seconds * RATE)].copy() if seconds else data.copy()
    # Suppress a constant component in derived layers, then fade only their edges.
    result -= np.mean(result, axis=0)
    attack = min(44, len(result))
    release = min(round(0.04 * RATE), len(result))
    result[:attack] *= np.linspace(0, 1, attack)[:, None]
    result[-release:] *= np.linspace(1, 0, release)[:, None]
    result *= 10 ** (-3 / 20) / float(np.max(np.abs(result)))
    return result


def write_wav(path, data):
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(np.round(data * 32767).astype("<i2").tobytes())


def main():
    accepted = json.loads((AUDITION / "preparation.json").read_text())
    inputs = ["reactor_rush", "kinetic_fire", "plasma_fire", "armor_hit", "enemy_break", "reactor_pulse"]
    sounds = {}
    sources = {}
    for name in inputs:
        item = accepted["assets"][name]
        preview = ROOT / item["preview"]
        if hashlib.sha256(preview.read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError("Accepted audition has changed: " + name)
        pcm = ROOT / item["wav"]
        data, rate = sf.read(pcm, always_2d=True)
        expected = item["prepared_pcm"]
        if rate != RATE or data.shape[1] != 2 or abs(len(data) / rate - expected["duration_seconds"]) > 1 / RATE:
            raise ValueError("Prepared audition format differs: " + name)
        # Compare with the approved encoded file as well as the original preparation metrics.
        actual = statistics(data)
        reference = decode(preview)
        if len(data) != len(reference) or float(np.sqrt(np.mean((data - reference) ** 2))) > 0.03:
            raise ValueError("Prepared audio differs materially from the accepted preview: " + name)
        if abs(actual["sample_peak"] - expected["sample_peak"]) > 0.0001:
            raise ValueError("Prepared audition peak differs: " + name)
        sounds[name] = data
        sources[name] = {"accepted_preview": item["preview"], "accepted_preview_sha256": item["sha256"],
                         "prepared_wav_sha256": hashlib.sha256(pcm.read_bytes()).hexdigest()}
    DESTINATION.mkdir(parents=True, exist_ok=True)
    report = {"selection": "User accepted FIRST ElevenLabs audition and requested shipping the game.",
              "music_source": "reactor_rush (music_v2); heavier music_v2_5 revision is excluded from runtime.",
              "sources": sources, "assets": {}}
    music = sounds["reactor_rush"]
    music_path = DESTINATION / "music_reactor_rush.ogg"
    sf.write(music_path, music, RATE, format="OGG", subtype="VORBIS")
    decoded, rate = sf.read(music_path, always_2d=True)
    seam = float(np.max(np.abs(decoded[0] - decoded[-1])))
    if rate != RATE or len(decoded) != len(music) or seam > 0.003:
        raise ValueError("Music loop changed duration or has an excessive boundary discontinuity")
    report["assets"]["music"] = {"path": str(music_path.relative_to(ROOT)),
        "sha256": hashlib.sha256(music_path.read_bytes()).hexdigest(), "decoded": statistics(decoded),
        "loop_boundary_sample_difference": seam,
        "processing": "Vorbis encoding of accepted PCM; full arrangement, length and tempo preserved. Loop repeats the file, with no claim of beat-grid certification."}
    cues = {"kinetic_fire": sounds["kinetic_fire"], "plasma_fire": sounds["plasma_fire"],
            "armor_impact": sounds["armor_hit"], "machine_break": sounds["enemy_break"],
            "pulse": sounds["reactor_pulse"]}
    direct_sources = {"kinetic_fire": "kinetic_fire", "plasma_fire": "plasma_fire",
                      "armor_impact": "armor_hit", "machine_break": "enemy_break", "pulse": "reactor_pulse"}
    descriptions = {name: "Accepted prepared effect, unchanged PCM." for name in cues}
    cues["scatter_fire"] = finish(layer([
        (0.0, pitch(sounds["kinetic_fire"], 0.78), 1.0),
        (0.012, sounds["armor_hit"], 0.36),
        (0.025, sounds["enemy_break"][:round(0.55 * RATE)], 0.2)]), 0.65)
    descriptions["scatter_fire"] = "Pitched kinetic body, armor layer, and short mechanical debris from accepted effects."
    cues["arc_fire"] = finish(pitch(sounds["plasma_fire"], 1.38), 0.54)
    descriptions["arc_fire"] = "Shorter, higher-pitched accepted plasma discharge."
    cues["guardian_break"] = finish(layer([
        (0.0, sounds["reactor_pulse"], 1.0), (0.06, pitch(sounds["enemy_break"], 0.85), 0.6)]), 2.9)
    descriptions["guardian_break"] = "Accepted reactor pulse with a lower-pitched mechanical destruction layer."
    cues["weapon_install"] = finish(layer([
        (0.0, sounds["armor_hit"], 0.5),
        (0.10, sounds["plasma_fire"][round(0.15 * RATE):round(0.60 * RATE)], 0.32),
        (0.25, sounds["kinetic_fire"][round(0.07 * RATE):], 0.3)]), 0.62)
    descriptions["weapon_install"] = "Mechanical latch and short power-up layers cut from accepted effects."
    for name, data in cues.items():
        path = DESTINATION / (name + ".wav")
        if name in direct_sources:
            shutil.copyfile(ROOT / accepted["assets"][direct_sources[name]]["wav"], path)
        else:
            write_wav(path, data)
        decoded, rate = sf.read(path, always_2d=True)
        stats = statistics(decoded)
        if rate != RATE or stats["samples_at_or_above_full_scale"]:
            raise ValueError("Invalid runtime effect: " + name)
        report["assets"][name] = {"path": str(path.relative_to(ROOT)),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "decoded": stats,
            "processing": descriptions[name]}
    (ROOT / "qa/release-audio.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Installed first audition: {:.3f}s music and {} cues; loop boundary delta {:.6f}.".format(
        len(music) / RATE, len(cues), seam))


if __name__ == "__main__":
    main()
