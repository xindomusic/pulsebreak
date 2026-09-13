#!/usr/bin/env python3
"""Compose original 174 BPM drum and bass and a layered reactor discharge.

Requires NumPy, SoundFile and ffmpeg. No downloaded music or samples.
PCM synthesis is deterministic; Vorbis container serials may vary per encode.
Three stereo stems share one 64-bar sample timeline, including wrapped tails.
"""
from pathlib import Path
import hashlib
import json
import math
import subprocess
import sys
import tempfile
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools/audio-python"))
import numpy as np
import soundfile as sf
ASSETS = ROOT / "assets/audio"
QA = ROOT / "qa"
PREVIEW = ROOT / "docs/audio"
RATE = 44100
BPM = 174
BEAT = 60 / BPM
BAR = 4 * BEAT
BARS = 64
FRAMES = round(BARS * BAR * RATE)
RNG = np.random.default_rng(913174)
TAU = 2 * np.pi
SECTIONS = [
    (0, 8, "Ignition / rolling introduction"),
    (8, 24, "First drop / bass call and response"),
    (24, 32, "Pressure / melodic development"),
    (32, 40, "Suspension / half-time break and rebuild"),
    (40, 56, "Second drop / doubled upper-bass answers"),
    (56, 64, "Afterburn / return to the loop"),
]


def clock(seconds):
    return np.arange(max(1, round(seconds * RATE)), dtype=np.float64) / RATE


def envelope(t, attack=0.002, release=0.022):
    return np.minimum(t / attack, 1) * np.minimum((t[-1] - t) / release, 1).clip(0, 1)


def band_noise(seconds, low, high):
    t = clock(seconds)
    raw = RNG.standard_normal(len(t))
    freq = np.fft.rfftfreq(len(t), 1 / RATE)
    highpass = 1 - np.exp(-(freq / max(1, low)) ** 4)
    lowpass = np.exp(-(freq / high) ** 6)
    result = np.fft.irfft(np.fft.rfft(raw) * highpass * lowpass, n=len(t))
    return result / max(0.01, np.sqrt(np.mean(result * result)))


def stereo(mono, width=0.0):
    if mono.ndim == 2:
        return mono
    # Low frequencies remain centered; stereo motion is only added to tops.
    side = np.roll(mono, 23) * width
    return np.column_stack((mono + side, mono - side))


def put(track, seconds, sound, gain=1.0, pan=0.0):
    sound = stereo(sound).astype(np.float32) * gain
    sound[:, 0] *= math.sqrt(1 - pan)
    sound[:, 1] *= math.sqrt(1 + pan)
    start = round(seconds * RATE) % len(track)
    first = min(len(sound), len(track) - start)
    track[start:start + first] += sound[:first]
    if first < len(sound):
        track[:len(sound) - first] += sound[first:]


def note(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def kick():
    t = clock(0.27)
    phase = TAU * (48 * t + 115 * 0.024 * (1 - np.exp(-t / 0.024)))
    body = np.sin(phase) * np.exp(-t / 0.082)
    click = band_noise(t[-1], 1300, 8500)
    click = np.resize(click, len(t)) * np.exp(-t / 0.0035) * 0.10
    return (body + click) * envelope(t, 0.0006, 0.016)


def snare(ghost=False):
    t = clock(0.22 if not ghost else 0.12)
    body = (np.sin(TAU * (185 * t + 18 * 0.018 * (1 - np.exp(-t / 0.018))))
            + 0.32 * np.sin(TAU * 330 * t)) * np.exp(-t / 0.038)
    noise = band_noise(len(t) / RATE, 1100, 10800)
    snap = noise * (np.exp(-t / 0.052) * 0.48 + np.exp(-t / 0.006) * 0.22)
    clap = np.zeros(len(t))
    for offset in [0.009, 0.017, 0.026]:
        elapsed = np.maximum(t - offset, 0)
        clap += noise * np.exp(-elapsed / 0.023) * (t >= offset) * 0.075
    return stereo((body * 0.62 + snap + clap) * envelope(t, 0.0008), 0.07)


def hat(opened=False):
    t = clock(0.23 if opened else 0.065)
    metal = sum(np.sin(TAU * f * t) for f in [4387, 6037, 7589, 10009]) * 0.13
    metal += band_noise(len(t) / RATE, 5700, 15500) * 0.5
    return metal * np.exp(-t / (0.063 if opened else 0.017)) * envelope(t, 0.0008, 0.015)


def reese(midi, seconds, bright=1.0, answer=False):
    t = clock(seconds)
    f = note(midi)
    sub = np.sin(TAU * f * t) + 0.16 * np.sin(TAU * 2 * f * t)
    sides = []
    for detune in [-0.0032, 0.0032]:
        tone = np.zeros(len(t))
        for h in range(2, 22):
            if h * f > RATE * 0.42:
                continue
            # Moving spectral slope gives bite without a harsh unfiltered saw.
            opening = 5 + 11 * bright * (0.5 + 0.5 * np.sin(TAU * (2.9 if answer else 1.45) * t + 0.4))
            tone += np.sin(TAU * f * (1 + detune) * h * t + h * 0.17) / h * np.exp(-h / opening)
        sides.append(np.tanh(tone * 2.4) * 0.49)
    mid = np.column_stack(sides)
    amp = envelope(t, 0.009, min(0.045, seconds / 4))
    wobble = 0.86 + 0.14 * np.sin(TAU * 5.8 * t)
    return (stereo(sub) * 0.62 + mid * wobble[:, None]) * amp[:, None]


def lead(midi, seconds, brightness=1.0):
    t = clock(seconds)
    f = note(midi)
    channels = []
    for detune in [-0.0017, 0.0017]:
        phase = TAU * f * (1 + detune) * t + 0.017 * np.sin(TAU * 5.2 * t)
        signal = sum(np.sin(phase * h) * np.exp(-h / (2.5 + brightness * 3)) / h for h in range(1, 13))
        channels.append(np.tanh(signal * 1.6))
    return np.column_stack(channels) * (envelope(t, 0.004, 0.055) * np.exp(-t / 0.25))[:, None]


def chord(root_midi, seconds):
    t = clock(seconds)
    out = np.zeros((len(t), 2))
    for interval in [0, 7, 10, 14]:
        out += lead(root_midi + interval, seconds, 0.25) * 0.23
    return out * (0.55 + 0.45 * np.exp(-t / 0.18))[:, None]


def riser(seconds):
    t = clock(seconds)
    progress = t / seconds
    noise = band_noise(seconds, 1800, 11500)
    gated = 0.45 + 0.55 * np.sin(TAU * t / BEAT * (1 + progress)) ** 2
    sweep = np.sin(TAU * (300 * t + 950 * t * t / seconds))
    return stereo((noise * 0.17 + sweep * 0.045) * progress ** 2 * gated * envelope(t, 0.1), 0.30)


def pcm(path, data):
    data = stereo(data)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((data.clip(-0.999, 0.999) * 32767).astype("<i2").tobytes())


def encode(path, data, temporary, title):
    if path.suffix == ".ogg":
        sf.write(str(path), data, RATE, format="OGG", subtype="VORBIS", compression_level=0.3)
        return
    wav = temporary / (path.stem + ".wav")
    pcm(wav, data)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(wav),
                    "-c:a", "libmp3lame", "-q:a", "2", "-metadata", "title=" + title,
                    "-metadata", "artist=Pulsebreak / original procedural score", str(path)], check=True)


def stats(data):
    return {"peak": float(np.max(np.abs(data))), "rms": float(np.sqrt(np.mean(data.astype(np.float64) ** 2))),
            "dc": float(np.mean(data)), "boundary_step": float(np.max(np.abs(data[-1] - data[0])))}


def build():
    ASSETS.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    foundation = np.zeros((FRAMES, 2), dtype=np.float32)
    bass = np.zeros_like(foundation)
    drive = np.zeros_like(foundation)
    upper = np.zeros_like(foundation)
    kick_sound, snare_sound, ghost, closed, opened = kick(), snare(), snare(True), hat(), hat(True)
    kicks = []
    roots = [38, 34, 41, 36]  # D minor, Bb, F, C. Audible mid harmonics carry small speakers.
    kick_patterns = [[0, 1.75, 2.5], [0, 2.5, 3.75], [0, 0.75, 2.5], [0, 2.25, 2.75]]
    bass_phrases = [[(0, 0, 0.65), (0.75, 0, 0.5), (1.5, 12, 0.35), (2, 0, 0.4), (2.75, 7, 0.45), (3.5, 0, 0.35)],
                    [(0, 0, 1.1), (1.5, 0, 0.38), (2.25, 12, 0.35), (2.75, 10, 0.35), (3.25, 7, 0.55)]]
    for bar in range(BARS):
        start = bar * BAR
        intro = bar < 8
        quiet = 32 <= bar < 36
        build_up = 36 <= bar < 40
        drop2 = 40 <= bar < 56
        outro = bar >= 60
        root_midi = roots[(bar // 4) % 4]
        pattern = [0, 2.5] if intro or outro else kick_patterns[bar % 4]
        if quiet:
            pattern = [0] if bar % 2 == 0 else [0, 2.75]
        if bar in [7, 39, 63]:
            pattern = [0, 1.75]
        for b in pattern:
            put(foundation, start + b * BEAT, kick_sound, 0.93 if not quiet else 0.54)
            kicks.append(start + b * BEAT)
        for b in ([2] if quiet else [1, 3]):
            put(foundation, start + b * BEAT, snare_sound, 0.94 if not quiet else 0.48)
            if not quiet:
                put(drive, start + b * BEAT, snare_sound, 0.24)
        # Velocity-shaped sixteenths and syncopated ghost notes establish a break.
        for step in range(16):
            if quiet and step % 2:
                continue
            when = start + step * BEAT / 4 + (0.008 if step % 2 else 0)
            velocity = [0.13, 0.055, 0.105, 0.07][step % 4]
            put(foundation, when, closed, velocity * (0.6 if quiet else 1.0), -0.22 if step % 2 else 0.22)
            if not quiet and not intro and step % 2:
                put(drive, when + 0.006, closed, 0.15 if drop2 else 0.09, 0.45 if step % 4 == 1 else -0.45)
        for b in ([0.75, 2.75] if quiet else [0.75, 1.625, 2.75, 3.5]):
            put(drive, start + b * BEAT, ghost, 0.11 if quiet else 0.19 + 0.025 * (bar % 3), -0.12)
        if not quiet:
            for b in [0.5, 2.5]:
                put(drive, start + b * BEAT, opened, 0.19, 0.3)
        if bar % 8 == 7:
            for step in range(6):
                put(drive, start + (3.25 + step * 0.125) * BEAT, ghost, 0.14 + step * 0.048, (step % 2 - 0.5) * 0.45)
        phrase = bass_phrases[bar % 2]
        if quiet:
            phrase = [(0, 0, 3.5)]
        elif intro and bar < 4:
            phrase = [(0, 0, 1.35), (2.5, 0, 0.7)]
        for b, interval, duration in phrase:
            put(bass, start + b * BEAT, reese(root_midi + interval, duration * BEAT, 0.30 if quiet else 0.8), 0.52 if quiet else 0.83)
            if drop2 and b >= 2:
                put(drive, start + (b + 0.125) * BEAT, reese(root_midi + interval + 12, min(duration, 0.3) * BEAT, 1.0, True), 0.18)
        # Harmonic stabs support an eight-bar melodic call and answer.
        for b in ([0] if quiet else [0.5, 2.75]):
            put(upper, start + b * BEAT, chord(root_midi + 24, 1.8 if quiet else 0.44), 0.38 if quiet else 0.31, 0.0)
        if not (intro and bar < 4):
            motif = [(0.5, 24), (1.25, 31), (2.5, 27), (3.25, 26)] if bar % 4 < 2 else [(0.75, 34), (1.5, 31), (2.75, 29), (3.5, 26)]
            if quiet:
                motif = [(0.5, 31), (2.5, 34)]
            for index, (b, interval) in enumerate(motif):
                sound = lead(root_midi + interval, 0.34 if not quiet else 0.8, 1.0 if drop2 else 0.55)
                level = 0.18 if intro or outro else 0.28 if drop2 else 0.22
                pan = 0.13 if index % 2 else -0.13
                put(upper, start + b * BEAT, sound, level, pan)
                put(upper, start + (b + 0.75) * BEAT, sound, level * 0.24, -pan * 3)
                put(upper, start + (b + 1.5) * BEAT, sound, level * 0.10, pan * 3)
        if build_up:
            for step in range(8 if bar < 39 else 16):
                count = 8 if bar < 39 else 16
                put(drive, start + step * BAR / count, ghost, 0.06 + 0.025 * (bar - 36) + 0.04 * step / count)

    for end in [8, 40]:
        put(drive, (end - 2) * BAR, riser(2 * BAR), 0.85)
    for start in [8, 24, 40, 56]:
        t = clock(1.2)
        crash = band_noise(1.2, 3000, 12500) * np.exp(-t / 0.32) * envelope(t, 0.003, 0.15)
        put(drive, start * BAR, stereo(crash, 0.22), 0.20)

    # Kick-timed sidechain recovery, shared across bass and upper tonal layers.
    duck = np.ones(FRAMES, dtype=np.float32)
    t = clock(0.18)
    contour = 1 - 0.67 * np.exp(-t / 0.050)
    for when in kicks:
        start = round(when * RATE)
        n = min(len(contour), FRAMES - start)
        duck[start:start + n] = np.minimum(duck[start:start + n], contour[:n])
    foundation += bass * duck[:, None]
    upper *= (0.48 + 0.52 * duck)[:, None]
    tracks = {"foundation": foundation, "drive": drive, "lead": upper}
    peaks = {"foundation": 0.86, "drive": 0.82, "lead": 0.75}
    report = {"bpm": BPM, "bars": BARS, "beats": 256, "sample_rate": RATE, "frames": FRAMES,
              "seconds": FRAMES / RATE, "channels": 2, "seed": 913174,
              "revision": "Aggressive bass/drums after user audition",
              "method": "Original additive/subtractive procedural synthesis; no third-party samples. Numeric analysis is not listening.",
              "sections": [{"start_bar": a, "end_bar": b, "name": name} for a, b, name in SECTIONS], "stems": {}}
    with tempfile.TemporaryDirectory(prefix="pulsebreak-resonance-") as temporary:
        temp = Path(temporary)
        for name, data in tracks.items():
            # Remove global DC and leave headroom; never hard clip composition.
            data -= np.mean(data, axis=0)
            # A 2 ms raised-cosine join suppresses discontinuities from wrapped
            # noisy tails; it is shorter than the first percussion attack.
            join = 96
            edge = (0.5 - 0.5 * np.cos(np.linspace(0, np.pi, join))).astype(np.float32)
            data[:join] *= edge[:, None]
            data[-join:] *= edge[::-1, None]
            data *= peaks[name] / np.max(np.abs(data))
            if name in ["foundation", "drive"]:
                # Controlled parallel saturation raises bass and drum body
                # while retaining the dry transient and the kick clearance.
                amount = 1.8 if name == "foundation" else 2.0
                saturated = peaks[name] * np.tanh(data / peaks[name] * amount) / np.tanh(amount)
                data[:] = data * 0.28 + saturated * 0.72
            path = ASSETS / ("music_resonance_" + name + ".ogg")
            if "--previews-only" not in sys.argv:
                encode(path, data, temp, "Resonance / " + name)
            report["stems"][name] = {**stats(data), "bytes": path.stat().st_size,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "section_rms": [float(np.sqrt(np.mean(data[round(a * BAR * RATE):round(b * BAR * RATE)] ** 2))) for a, b, _ in SECTIONS]}

        # Immediate click/crack, a rising intake underneath, tuned collapsing body,
        # three metallic splinters and a broad stereo tail. Damage is never delayed.
        t = clock(1.25)
        blast = np.zeros((len(t), 2))
        low = np.sin(TAU * (39 * t + 103 * 0.068 * (1 - np.exp(-t / 0.068)))) * np.exp(-t / 0.22)
        grit = band_noise(1.25, 480, 10000)
        crack = grit * np.exp(-t / 0.025) * 0.52
        peak = np.exp(-np.maximum(t - 0.040, 0) / 0.065) * np.minimum(t / 0.040, 1)
        blast += stereo(low * 0.65 + crack + np.tanh(grit * 1.8) * peak * 0.20)
        intake = np.sin(TAU * (650 * t + 14500 * t * t)) * np.exp(-((t - 0.038) / 0.023) ** 2) * 0.09
        blast += stereo(intake, 0.18)
        for index, f in enumerate([1318.5, 2093, 2793.8]):
            offset = 0.075 + index * 0.028
            age = np.maximum(t - offset, 0)
            shard = np.sin(TAU * (f * age - f * 0.16 * age * age)) * np.exp(-age / 0.16) * (t >= offset)
            blast[:, index % 2] += shard * 0.095 * np.minimum(age / 0.003, 1)
        tail = band_noise(1.25, 1600, 7400) * (1 - np.exp(-t / 0.055)) * np.exp(-t / 0.27) * 0.085
        blast += stereo(tail, 0.5)
        blast *= envelope(t, 0.0005, 0.12)[:, None]
        blast -= np.mean(blast, axis=0)
        blast *= 0.88 / np.max(np.abs(blast))
        if "--previews-only" not in sys.argv:
            pcm(ASSETS / "pulse_resonance.wav", blast)
        report["pulse"] = {**stats(blast), "seconds": len(blast) / RATE}

        # Preview one full composed arc at full-combat stem gains, then a short
        # offline reconstruction using actual director gains and event ducking.
        full_mix = foundation * 10 ** (-4 / 20) + drive * 10 ** (-5 / 20) + upper * 10 ** (-12 / 20)
        report["music_mix"] = stats(full_mix)
        encode(PREVIEW / "resonance-dnb.mp3", full_mix, temp, "Resonance / full 64-bar DnB score")
        demo_frames = round(36 * RATE)
        timeline = np.arange(demo_frames) / RATE
        intensity = np.minimum(0.35 + timeline / 25, 1)
        # Slice across first-drop entry, so the short preview includes a build.
        offset = round(5 * BAR * RATE)
        excerpt = np.zeros((demo_frames, 2), dtype=np.float32)
        for name, lo, hi in [("foundation", -8.5, -4), ("drive", -18, -5), ("lead", -30, -12)]:
            gains = 10 ** ((lo + (hi - lo) * intensity) / 20)
            excerpt += tracks[name][offset:offset + demo_frames] * gains[:, None]
        cues = np.zeros_like(excerpt)
        demo_duck = np.zeros(demo_frames, dtype=np.float32)
        events = [(8.0, "pulse_resonance", -7), (16.5, "pulse_resonance", -7),
                  (25.0, "guardian_break", -7), (30.0, "pulse_resonance", -7)]
        for when, name, db in events:
            with wave.open(str(ASSETS / (name + ".wav")), "rb") as f:
                cue = np.frombuffer(f.readframes(f.getnframes()), dtype="<i2").astype(np.float32).reshape(-1, f.getnchannels()) / 32768
                if f.getnchannels() == 1:
                    cue = np.repeat(cue, 2, axis=1)
            put(cues, when, cue, 10 ** (db / 20))
            start = round(when * RATE)
            age = clock(0.58 / 1.1)
            length = min(len(age), demo_frames - start)
            demo_duck[start:start + length] = np.maximum(demo_duck[start:start + length], np.maximum(0, 0.58 - 1.1 * age[:length]))
        weapon_events = []
        for start, end, name, db, cadence in [(3, 9, "kinetic_fire", -12, 0.28), (9, 18, "scatter_fire", -9.5, 0.75),
                                             (18, 27, "arc_fire", -11, 0.62), (27, 34, "plasma_fire", -8.5, 0.95)]:
            weapon_events.extend((float(when), name, db) for when in np.arange(start, end, cadence))
        for when, name, db in weapon_events:
            with wave.open(str(ASSETS / (name + ".wav")), "rb") as f:
                cue = np.frombuffer(f.readframes(f.getnframes()), dtype="<i2").astype(np.float32).reshape(-1, 2) / 32768
            put(cues, float(when), cue, 10 ** (db / 20))
        demo = excerpt * 10 ** ((-demo_duck * 8)[:, None] / 20) + cues
        demo *= 0.65  # Default persisted volume used in representative runtime.
        fade = round(0.3 * RATE)
        demo[-fade:] *= np.cos(np.linspace(0, np.pi / 2, fade))[:, None] ** 2
        report["battle_preview"] = {**stats(demo), "seconds": 36, "kind": "offline reconstruction, not engine capture", "volume": 0.65}
        encode(PREVIEW / "resonance-battle.mp3", demo, temp, "Resonance / offline battle mix preview")
    (QA / "resonance-audio.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"seconds": report["seconds"], "music_peak": report["music_mix"]["peak"],
                      "battle_peak": report["battle_preview"]["peak"],
                      "stem_bytes": sum(s["bytes"] for s in report["stems"].values())}, indent=2))


if __name__ == "__main__":
    build()
