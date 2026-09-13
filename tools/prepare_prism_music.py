#!/usr/bin/env python3
"""Prepare the original Prism Drive music request for offline game playback.

No API calls or reference-song audio. Preserve the downloaded provider original,
all prior auditions, the release1.1 soundtrack and every combat effect.
"""
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools/audio-python"))
import numpy as np
import soundfile as sf
import prepare_elevenlabs_audition as prep

QA = ROOT / "qa/prism-music"
RAW = ROOT / "qa/elevenlabs-audition/prism_drive.mp3"
RECEIPT = RAW.with_suffix(".json")
MUSIC = ROOT / "assets/audio/elevenlabs/music_prism_drive.ogg"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def checked(path):
    data = prep.decode(path)
    stats = prep.statistics(data)
    if stats["samples_at_or_above_full_scale"]:
        raise ValueError("Decoded audio clips: " + path.name)
    return stats


def main():
    receipt = json.loads(RECEIPT.read_text())
    if receipt.get("status") != "complete" or digest(RAW) != receipt.get("sha256"):
        raise ValueError("Prism generation is incomplete or original hash changed")
    if receipt["name"] != "prism_drive" or receipt["request"]["model_id"] != "music_v2_5":
        raise ValueError("Unexpected music generation receipt")
    # Track all existing release audio to prove this is a music-only change.
    previous = {str(p.relative_to(ROOT)): digest(p) for p in MUSIC.parent.iterdir()
                if p.is_file() and p.suffix in [".wav", ".ogg"] and p != MUSIC}
    prep.PCM = QA / "prepared"
    prep.PREVIEW = ROOT / "docs/audio/prism"
    prep.PCM.mkdir(parents=True, exist_ok=True)
    prep.PREVIEW.mkdir(parents=True, exist_ok=True)
    data, before = prep.normalize(RAW, -14.1, -1.7)
    # Short boundary fades reduce the file-wrap step after lossy encoding.
    # The complete composition and duration remain intact; no beat grid is asserted.
    edge = round(prep.RATE * 0.010)
    data[:edge] *= np.linspace(0, 1, edge)[:, None]
    data[-edge:] *= np.linspace(1, 0, edge)[:, None]
    preview, data = prep.save_matched("prism_drive", data, -14.1)
    MUSIC.parent.mkdir(parents=True, exist_ok=True)
    # Feed bounded blocks: this libsndfile build crashes on one large Vorbis
    # write for the full 102-second arrangement.
    with sf.SoundFile(MUSIC, "w", samplerate=prep.RATE, channels=2,
                      format="OGG", subtype="VORBIS") as encoded:
        for start in range(0, len(data), 16384):
            encoded.write(data[start:start + 16384])
    runtime, rate = sf.read(MUSIC, always_2d=True)
    if rate != prep.RATE or len(runtime) != len(data):
        raise ValueError("Vorbis encoding changed duration or sample rate")
    seam = float(np.max(np.abs(runtime[0] - runtime[-1])))
    runtime_stats = checked(MUSIC)
    if seam > 0.003:
        raise ValueError("Excessive music-loop boundary discontinuity")
    # A short offline context preview uses the unchanged production effects at
    # ordinary cue strengths, plus representative full-combat gain and pulse duck.
    events = []
    for start in [3.0, 8.0, 26.0, 34.0]:
        for shot in range(7):
            events.append((start + 0.28 * shot, "kinetic_fire", 0.82, -3.9))
            if shot % 2 == 0:
                events.append((start + 0.28 * shot + 0.09, "armor_impact", 0.48, -4.2))
    for start in [13.0, 18.0, 30.0]:
        for shot in range(3):
            events.append((start + 0.95 * shot, "plasma_fire", 0.82, -2.5))
    events += [(6.0, "machine_break", 0.7, -1.8), (16.5, "machine_break", 0.7, -1.8),
               (29.0, "machine_break", 0.7, -1.8), (21.5, "pulse", 1.0, -2.5),
               (39.5, "pulse", 1.0, -2.5)]
    duration = min(len(data), round(44.2 * prep.RATE))
    timeline = np.arange(duration) / prep.RATE
    duck_db = np.zeros(duration)
    for seconds in [21.5, 39.5]:
        elapsed = timeline - seconds
        duck_db = np.maximum(duck_db, np.where(elapsed >= 0, np.maximum(0, 0.75 - elapsed * 1.1) * 8, 0))
    mix = data[:duration] * (10 ** ((-6.0 - duck_db) / 20))[:, None]
    for seconds, name, strength, db in events:
        cue, rate = sf.read(MUSIC.parent / (name + ".wav"), always_2d=True)
        if rate != prep.RATE:
            raise ValueError("Unexpected effect sample rate")
        prep.place(mix, cue, seconds, strength * 10 ** (db / 20))
    mix *= min(1.0, 10 ** (-2 / 20) / float(np.max(np.abs(mix))))
    tail = round(0.12 * prep.RATE)
    mix[-tail:] *= np.linspace(1, 0, tail)[:, None]
    battle = prep.save("battle_preview", mix)
    battle["preview_loudness"] = prep.loudness(prep.PREVIEW / "battle_preview.mp3")
    for name, value in previous.items():
        if digest(ROOT / name) != value:
            raise ValueError("Existing release audio was modified: " + name)
    report = {
        "brief": "Original 150 BPM half-time festival dubstep, responding to the user's high-level reference direction.",
        "reference": "https://soundcloud.com/rayvolpemusic/laserbeam",
        "reference_audio_used": False, "musical_similarity_reviewed_by_listening": False,
        "tempo": "150 BPM requested; no exact tempo/beat-grid certification.",
        "provider_receipt": str(RECEIPT.relative_to(ROOT)), "provider_original_sha256": digest(RAW),
        "original_loudness": before,
        "processing": "Two-pass loudness normalization, 10ms boundary fades and final measured MP3 loudness matching. Full arrangement retained.",
        "runtime": {"path": str(MUSIC.relative_to(ROOT)), "sha256": digest(MUSIC),
                    "decoded": runtime_stats, "loop_boundary_sample_difference": seam,
                    "loudness": prep.loudness(MUSIC)},
        "music_preview": preview, "battle_preview": battle,
        "battle_method": "Offline 44.2s montage using release 1.1 effects and representative full-combat gains. Not an engine recording; no pitch variation or voice limiting is simulated.",
        "battle_events": [{"seconds": round(t, 3), "cue": n, "strength": s, "gain_db": g} for t, n, s, g in sorted(events)],
        "preserved_release_audio_sha256": previous,
    }
    (ROOT / "qa/prism-music.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Prism ready: {:.3f}s, runtime peak {:.2f}dBFS, loop boundary delta {:.6f}.".format(
        runtime_stats["duration_seconds"], runtime_stats["peak_dbfs"], seam))


if __name__ == "__main__":
    main()
