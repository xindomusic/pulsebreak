#!/usr/bin/env python3
"""Original Pulsebreak score and cues. Python standard library only; deterministic.

Run from any directory: python3 tools/generate_audio.py
All synthesis, composition and sound design here are original procedural work.
Writes 22.05 kHz, signed 16-bit mono WAV files and measured QA documentation.
"""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

RATE = 22050
TAU = math.tau
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
RNG = random.Random(74921)
REPORT = []


def buffer(duration):
    return array("f", [0.0]) * round(duration * RATE)


def mix(dst, src, start=0.0, gain=1.0, wrap=False):
    offset = round(start * RATE)
    for i, value in enumerate(src):
        pos = offset + i
        if wrap:
            pos %= len(dst)
        if 0 <= pos < len(dst):
            dst[pos] += value * gain


def midi(note):
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def tone(freq, duration, voice="bell", attack=0.006):
    result = buffer(duration)
    for i in range(len(result)):
        t = i / RATE
        x = t / duration
        p = TAU * freq * t
        fade = min(1.0, t / attack) * min(1.0, (duration - t) / 0.03)
        if voice == "pad":
            env = math.sin(math.pi * x) ** 1.4
            v = (math.sin(p) + 0.25 * math.sin(p * 1.003)
                 + 0.13 * math.sin(p * 2) + 0.055 * math.sin(p * 3)) / 1.435
        elif voice == "bass":
            env = math.exp(-3.0 * x) * fade
            v = (math.sin(p) + 0.28 * math.sin(p * 2) + 0.12 * math.sin(p * 3)) / 1.4
        else:
            env = math.exp(-5.0 * x) * fade
            v = math.sin(p) + 0.21 * math.sin(p * 2.003) * math.exp(-8 * x)
        result[i] = v * env
    return result


def sweep(start, end, duration, noise=0.0, decay=4.0):
    result = buffer(duration)
    phase = 0.0
    smooth_noise = 0.0
    for i in range(len(result)):
        t = i / RATE
        x = t / duration
        freq = end + (start - end) * math.exp(-6.0 * x)
        phase += TAU * freq / RATE
        smooth_noise += 0.3 * (RNG.uniform(-1, 1) - smooth_noise)
        env = min(1.0, t / 0.004) * math.exp(-decay * x) * min(1.0, (duration - t) / 0.025)
        result[i] = (math.sin(phase) * (1.0 - noise) + smooth_noise * noise) * env
    return result


def noise_hit(duration, bright=False):
    result = buffer(duration)
    prev = 0.0
    low = 0.0
    for i in range(len(result)):
        t = i / RATE
        x = t / duration
        white = RNG.uniform(-1.0, 1.0)
        low += 0.32 * (white - low)
        v = (white - prev) * 0.4 if bright else low
        prev = white
        result[i] = v * min(1, t / 0.002) * math.exp(-7 * x) * min(1, (duration - t) / 0.01)
    return result


def save(name, data, peak=0.7):
    # Remove DC and normalize only downward/upward to a deliberate conservative peak.
    dc = sum(data) / len(data)
    maximum = max(abs(v - dc) for v in data)
    gain = peak / maximum if maximum else 1.0
    pcm = array("h", (round((v - dc) * gain * 32767) for v in data))
    actual_peak = max(abs(v) for v in pcm) / 32768.0
    rms = math.sqrt(sum(v * v for v in pcm) / len(pcm)) / 32768.0
    assert actual_peak < 0.95, (name, actual_peak)
    assert len(pcm) > RATE * 0.02
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUT / (name + ".wav")), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())
    REPORT.append((name, len(data) / RATE, actual_peak, rms, (OUT / (name + ".wav")).stat().st_size))


def score():
    beat = 60.0 / 112.0
    duration = 64.0 * beat
    base, drums = buffer(duration), buffer(duration)
    # Four four-bar chord regions: Em7 / Cmaj7 / Am7 / Dsus2.
    chords = [(40, [52, 55, 59, 62]), (36, [48, 52, 55, 59]),
              (33, [45, 48, 52, 55]), (38, [50, 52, 57, 62])]
    motif = [0, 2, 1, 3, 2, 1, 3, 1]
    for bar in range(16):
        root, notes = chords[bar // 4]
        start = bar * 4 * beat
        for note in notes:
            mix(base, tone(midi(note), 5 * beat, "pad"), start - beat * 0.5, 0.065, True)
        for step, length in [(0, 0.68), (1.5, 0.38), (2, 0.65), (3.25, 0.38)]:
            note = root + (12 if step == 3.25 and bar % 2 else 0)
            mix(base, tone(midi(note), beat * length, "bass"), start + step * beat, 0.29, True)
        for step in range(8):
            note = notes[motif[(step + bar % 2 * 2) % 8]] + 12
            arp = tone(midi(note), beat * 0.68)
            level = 0.055 + 0.025 * (step % 3 == 0)
            mix(base, arp, start + step * beat / 2, level, True)
            mix(base, arp, start + step * beat / 2 + beat * 0.75, level * 0.25, True)
        for step in [0, 1.75, 2, 3.5] if bar % 4 == 3 else [0, 2, 2.75]:
            mix(drums, sweep(155, 45, 0.30, noise=0.025, decay=6), start + step * beat, 0.8, True)
        for step in [1, 3]:
            mix(drums, sweep(235, 148, 0.15, decay=6), start + step * beat, 0.21, True)
            mix(drums, noise_hit(0.20), start + step * beat, 0.68, True)
        for step in range(8):
            mix(drums, noise_hit(0.15 if step % 2 else 0.07, True),
                start + step * beat / 2, 0.15 if step % 2 else 0.09, True)
        if bar % 4 == 3:
            for step in [3.25, 3.75]:
                mix(drums, noise_hit(0.11), start + step * beat, 0.2, True)
    save("music_foundry", base, 0.66)
    save("music_pressure", drums, 0.68)


def cues():
    save("dash", sweep(340, 1050, 0.23, noise=0.62, decay=3.7), 0.56)
    data = buffer(0.3)
    mix(data, tone(midi(83), 0.27), gain=0.8)
    mix(data, tone(midi(90), 0.20), 0.045, 0.27)
    save("absorb", data, 0.58)
    data = buffer(0.78)
    mix(data, sweep(230, 42, 0.65, noise=0.16), gain=0.9)
    mix(data, sweep(1350, 210, 0.35, noise=0.4), gain=0.23)
    mix(data, tone(midi(52), 0.75, "pad"), gain=0.23)
    save("pulse", data, 0.80)
    save("shoot", sweep(1100, 330, 0.095, noise=0.16, decay=7), 0.40)
    data = buffer(0.29)
    mix(data, sweep(180, 57, 0.28, noise=0.25), gain=0.7)
    mix(data, noise_hit(0.13), gain=0.5)
    save("hit", data, 0.70)
    data = buffer(0.24)
    mix(data, sweep(360, 92, 0.22, noise=0.48), gain=0.8)
    mix(data, tone(midi(71), 0.13), gain=0.2)
    save("kill", data, 0.51)
    data = buffer(0.68)
    for t in [0.0, 0.25]:
        mix(data, tone(midi(74), 0.18), t, 0.6)
        mix(data, tone(midi(75), 0.17), t, 0.16)
    save("warning", data, 0.63)
    for name, notes, spacing, duration, level in [
        ("upgrade", [64, 67, 71, 76], 0.105, 0.85, 0.65),
        ("core", [76, 83, 88], 0.080, 0.61, 0.63),
        ("victory", [64, 67, 71, 76, 79, 83, 88], 0.145, 2.2, 0.72),
        ("defeat", [64, 59, 55, 52, 40], 0.22, 2.0, 0.65),
        ("ready", [76, 83], 0.075, 0.30, 0.40),
    ]:
        data = buffer(duration)
        for i, note in enumerate(notes):
            tail = min(duration - i * spacing, 0.7 if name in ("victory", "defeat") else 0.40)
            mix(data, tone(midi(note), tail), i * spacing, 0.65)
        if name == "victory":
            for note in [52, 59, 64]:
                mix(data, tone(midi(note), 2.0, "pad"), 0.1, 0.17)
        save(name, data, level)
    data = buffer(1.75)
    for note in [28, 40, 47, 58]:
        mix(data, tone(midi(note), 1.7, "pad"), gain=0.20)
    for t in [0.0, 0.38, 0.76]:
        mix(data, sweep(135, 47, 0.5, noise=0.14), t, 0.5)
    save("boss", data, 0.72)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    score()
    cues()
    lines = ["# Pulsebreak audio generation report", "",
             "All music and cues are original procedural composition and synthesis generated by `tools/generate_audio.py`. No external samples or attribution requirements.", "",
             "Two synchronized mono music stems: 112 BPM, 16 bars, E-minor family. The tonal stem carries bass, soft pad and delayed arpeggio; the pressure stem adds kick, snare, hats and four-bar fills. Wrapped event tails preserve the loop boundary. All assets are 22,050 Hz signed 16-bit PCM.", "",
             "| Asset | Seconds | Peak (linear) | RMS (linear) | Bytes |",
             "|---|---:|---:|---:|---:|"]
    for name, secs, peak, rms, size in REPORT:
        lines.append(f"| {name} | {secs:.3f} | {peak:.4f} | {rms:.4f} | {size:,} |")
    total = sum(row[4] for row in REPORT)
    assert total < 10_000_000
    lines += ["", f"Total WAV assets: {total:,} bytes. All measured peaks < 0.95; no PCM clipping. Regeneration uses fixed random seed 74921.", "",
              "Listening status: not auditioned by this agent. Numeric validation does not establish perceived balance or aesthetic quality. Runtime mix and music-loop behavior require in-game listening.", ""]
    (ROOT / "qa" / "audio-report.md").write_text("\n".join(lines))
    print("\n".join(lines))


if __name__ == "__main__":
    main()
