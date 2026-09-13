#!/usr/bin/env python3
"""Generate a small, resumable ElevenLabs audition; never load a key into Godot.

Default: print the plan without network access. --generate makes paid requests.
Credentials: ~/.config/pulsebreak/elevenlabs.env (outside this repository).
Each request gets a receipt BEFORE submission. Interrupted/failed requests are
never automatically resubmitted: check provider history before replacing one.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "qa/elevenlabs-audition"
KEY_FILE = Path.home() / ".config/pulsebreak/elevenlabs.env"
FORMAT = "mp3_44100_128"
ASSETS = [
    {
        "name": "reactor_rush", "kind": "music", "title": "Reactor Rush — aggressive DnB",
        "body": {
            "model_id": "music_v2", "music_length_ms": 44138,
            "force_instrumental": True,
            "prompt": (
                "Original instrumental combat soundtrack for a kinetic futuristic arena game. "
                "174 BPM aggressive drum and bass, neurofunk weight with dancefloor momentum. "
                "Make it feel like a finished record: hard syncopated punchy kicks, enormous "
                "cracking snare with acoustic body and tight metallic snap, intricate rolling "
                "chopped breakbeats, snare ghost notes, swinging shuffles and crisp hi-hats. "
                "A snarling distorted modulated Reese bass trades short rhythmic phrases with "
                "a growling mid-bass answer; deep controlled mono sub follows the kick pockets. "
                "Dark electric tension with vivid triumphant futuristic synth stabs, very little "
                "sustained lead so combat sounds have room. Immediate full-energy drum and bass "
                "groove in the first second, no cinematic ambient introduction. Develop a "
                "memorable bass hook, add short drum fills every four bars, one brief one-bar "
                "tension pullback near the middle, then a heavier second drop with evolving bass "
                "rhythm. Maintain fast forward motion to the end. Cohesive punchy club mix, "
                "powerful bass and drums, transients preserved, clean controlled high frequencies. "
                "No vocals, speech, chanting, acoustic ballad, chiptune, trap beat or four-on-the-floor house. "
                "Music only: no gunfire or explosions."
            ),
        },
    },
    {
        "name": "kinetic_fire", "kind": "sfx", "title": "Kinetic cannon",
        "body": {"duration_seconds": 1.2, "text": (
            "One isolated single shot from a powerful futuristic kinetic rifle, immediate "
            "dry sharp ballistic CRACK layered with a deep compact chesty punch, a quick "
            "metal bolt clack and tiny hot casing tick, short controlled tail. Expensive "
            "cinematic game weapon sound, tactile and aggressive, close perspective. "
            "One shot only at the very start, silence after its decay. No firing sequence, "
            "laser beep, voice, music, ambience or long reverb."
        )},
    },
    {
        "name": "plasma_fire", "kind": "sfx", "title": "Heavy plasma launcher",
        "body": {"duration_seconds": 1.8, "text": (
            "One heavy sci-fi plasma cannon shot at the very start. Huge low-mid "
            "electromagnetic THWUMP, vicious bright ion crack, thick tearing electrical "
            "texture and short descending resonant tail. Physical cinematic game sound, "
            "centered punch and wide electrical aftermath, then silence. No charging intro, "
            "thin cartoon pew, repeated shots, music, speech or ambience."
        )},
    },
    {
        "name": "armor_hit", "kind": "sfx", "title": "Armor impact",
        "body": {"duration_seconds": 1.0, "text": (
            "One isolated high velocity projectile striking a robot's thick armored plate. "
            "Immediate sharp hard metallic crunch, compact weighty knock, brief brittle "
            "ceramic shatter and tiny sizzling sparks. Extremely tight satisfying game hit "
            "confirmation, short dry decay. One impact at the start, no ricochet whistle, "
            "second impact, explosion, voice, music or background noise."
        )},
    },
    {
        "name": "enemy_break", "kind": "sfx", "title": "Robot destruction",
        "body": {"duration_seconds": 2.5, "text": (
            "One futuristic combat robot breaking apart at the very start. Forceful crunchy "
            "metal rupture and electrical POP, fast tumbling armor fragments, fizzing servo "
            "failures and a descending dying power-core whine. Detailed cinematic game enemy "
            "destruction, clearly mechanical. Tight impactful start, debris finishes within "
            "two seconds then silence. No voice, music, repeated explosions or ambience."
        )},
    },
    {
        "name": "reactor_pulse", "kind": "sfx", "title": "Overload reactor blast",
        "body": {"duration_seconds": 3.0, "text": (
            "One spectacular sci-fi reactor pulse detonation at the very start. Enormous "
            "sharp energy CRACK, dense concussive low-mid body, deep sub drop and a radial "
            "tearing electromagnetic shockwave. Bright crystalline fragments scatter wide, "
            "a collapsing ion storm crackles into silence. Cinematic ultimate attack with "
            "a textured aftermath. No pre-charge, repeated blasts, voice, music or ambience."
        )},
    },
]

# A distinct request name preserves the first audition and its paid receipt.
# User feedback: "Make the bass and drums heavier."
ASSETS.append({
    "name": "reactor_rush_heavy", "kind": "music", "title": "Reactor Rush — heavier DnB revision",
    "body": {
        "model_id": "music_v2_5", "music_length_ms": 44138, "force_instrumental": True,
        "prompt": (
            "Original instrumental 174 BPM drum and bass for an intense futuristic arena battle. "
            "Extremely heavy, aggressive neurofunk with relentless rolling breakbeats. DRUMS AND "
            "BASS ARE THE FEATURED INSTRUMENTS, up front and dominant throughout. A huge tight "
            "deep punchy kick drives syncopated DnB rhythms. Every backbeat has a thick hard "
            "acoustic snare body, hard rimshot crack and explosive short noisy snap; tightly "
            "compressed break layers, busy snare ghost notes and rolling shuffling percussion "
            "make the groove urgent and physical. Bass is massive: snarling distorted "
            "modulated Reese bass, grinding resonant mid-bass, nasty growling call-and-response "
            "phrases and a thick controlled mono sub. Bass articulation follows the drum "
            "syncopation and punches through with audible low-mid weight, not only deep rumble. "
            "Very sparse dark sci-fi synth stabs only as punctuation; focus the whole record "
            "on the bass hook and hard drums. Start straight on a violent full-energy drop "
            "in the first beat. Maintain relentless 174 BPM breakbeat motion, with intricate "
            "fills and increasingly aggressive bass answers every four bars. One very short "
            "half-bar tension gap near the middle, then slam back into an even harder final "
            "drop. Heavy saturated drum bus character and gritty bass texture, defined "
            "transients, controlled sub and clean treble. Finished muscular modern club mix. "
            "No vocals, speech, melodic singing, soft pads, airy cinematic intro, long "
            "breakdown, euphoric trance lead, house beat, trap beat or chiptune. "
            "Music only, no weapons or explosion sound effects."
        ),
    },
})


def timestamp():
    return datetime.now(timezone.utc).isoformat()


def write_json(path, data):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    temporary.replace(path)


def read_key():
    try:
        rows = KEY_FILE.read_text().splitlines()
    except OSError:
        raise RuntimeError("Private ElevenLabs key file is unavailable.") from None
    values = [row.partition("=")[2].strip().strip("\"'") for row in rows
              if row.strip().startswith("ELEVENLABS_API_KEY=")]
    if len(values) != 1 or not values[0] or values[0] == "replace_with_your_key":
        raise RuntimeError("Configure exactly one ELEVENLABS_API_KEY in the private key file.")
    return values[0]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward a credential to another host, including on provider error.
        return None


def generate(asset, key, opener):
    name = asset["name"]
    receipt_path = OUTPUT / (name + ".json")
    destination = OUTPUT / (name + ".mp3")
    endpoint = "/v1/music" if asset["kind"] == "music" else "/v1/sound-generation"
    body = dict(asset["body"])
    if asset["kind"] == "sfx":
        body.update(model_id="eleven_text_to_sound_v2", prompt_influence=0.6, loop=False)
    if receipt_path.exists():
        previous = json.loads(receipt_path.read_text())
        if any(previous.get(field) != value for field, value in
               (("request", body), ("endpoint", endpoint), ("output_format", FORMAT))):
            print(name + ": request differs from existing receipt; use a new asset name.", flush=True)
            return False
        if previous.get("status") == "complete" and destination.exists():
            digest = hashlib.sha256(destination.read_bytes()).hexdigest()
            if digest == previous.get("sha256"):
                print(name + ": already downloaded; no request.", flush=True)
                return True
        print(name + ": existing incomplete or changed receipt; inspect before retrying.", flush=True)
        return False
    if destination.exists():
        print(name + ": output already exists without a receipt; refusing to overwrite.", flush=True)
        return False
    receipt = {"provider": "ElevenLabs", "name": name, "title": asset["title"],
               "endpoint": endpoint, "output_format": FORMAT, "request": body,
               "started_at": timestamp(), "status": "request_started",
               "purpose": "Private audition; not yet approved for game integration."}
    # Exclusive creation prevents two processes from submitting the same paid request.
    with receipt_path.open("x") as output:
        json.dump(receipt, output, indent=2, ensure_ascii=False)
        output.write("\n")
    print(name + ": generating…", flush=True)
    req = urllib.request.Request(
        "https://api.elevenlabs.io" + endpoint + "?output_format=" + FORMAT,
        data=json.dumps(body).encode(), method="POST",
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    partial = destination.with_suffix(".mp3.part")
    try:
        with opener.open(req, timeout=300) as response:
            # Save recovery identifiers before downloading a potentially interrupted body.
            for header in ("character-cost", "song-id", "request-id"):
                value = response.headers.get(header)
                if value:
                    receipt[header] = value.replace(key, "[redacted]")[:160]
            write_json(receipt_path, receipt)
            if "audio/" not in response.headers.get("Content-Type", "").lower():
                raise ValueError("Unexpected response format")
            count = 0
            digest = hashlib.sha256()
            with partial.open("xb") as output:
                while True:
                    chunk = response.read(65536)
                    if not chunk:
                        break
                    count += len(chunk)
                    if count > 32 * 1024 * 1024:
                        raise ValueError("Response exceeded audition size limit")
                    output.write(chunk)
                    digest.update(chunk)
            if count < 1024:
                raise ValueError("Audio response was empty or too small")
        partial.replace(destination)
        receipt.update(status="complete", completed_at=timestamp(), bytes=count,
                       sha256=digest.hexdigest(), file=destination.name)
        write_json(receipt_path, receipt)
        print(name + ": saved (" + str(count) + " bytes).", flush=True)
        return True
    except urllib.error.HTTPError as error:
        receipt.update(status="http_error", http_status=error.code, completed_at=timestamp())
        # Raw provider error bodies can contain account data; keep only a short code.
        try:
            detail = json.loads(error.read(8192)).get("detail", {})
            status = detail.get("status", "unknown") if isinstance(detail, dict) else "unknown"
            if isinstance(status, str) and len(status) < 80 and key not in status:
                receipt["api_status"] = status
        except (ValueError, AttributeError):
            pass
        write_json(receipt_path, receipt)
        print(name + ": HTTP " + str(error.code) + "; no automatic retry.", flush=True)
        return False
    except (OSError, ValueError) as error:
        receipt.update(status="interrupted_or_invalid", error_type=type(error).__name__,
                       completed_at=timestamp())
        write_json(receipt_path, receipt)
        print(name + ": request/download interrupted; check provider history before retrying.", flush=True)
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generate", action="store_true", help="Submit paid generation requests")
    parser.add_argument("--only", nargs="+", choices=[item["name"] for item in ASSETS])
    args = parser.parse_args()
    selected = [item for item in ASSETS if not args.only or item["name"] in args.only]
    # The SFX product has a 450-character prompt limit; check before any paid calls.
    for item in selected:
        body = item["body"]
        limit = 450 if item["kind"] == "sfx" else 4100
        if len(body.get("text", body.get("prompt", ""))) > limit:
            parser.error(item["name"] + " exceeds provider prompt length limit")
    if not args.generate:
        for item in selected:
            seconds = item["body"].get("duration_seconds", item["body"].get("music_length_ms", 0) / 1000)
            print("{}: {} seconds requested — {}".format(item["name"], seconds, item["title"]))
        print("Plan only. No key read, network access or generation charges.")
        return 0
    try:
        key = read_key()
        OUTPUT.mkdir(parents=True, exist_ok=True)
        opener = urllib.request.build_opener(NoRedirect())
        # Sequential submissions bound spending; stop at the first failed request.
        for item in selected:
            if not generate(item, key, opener):
                return 1
    except (RuntimeError, OSError, ValueError) as error:
        print("Generation stopped: " + type(error).__name__ + ". Inspect local setup.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
