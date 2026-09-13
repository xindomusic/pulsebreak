# Pulsebreak — asset origins and notices

## Project code and assets

The game code, interface, icon and procedural 3D geometry were created for this project with Codex assistance. Models and environment geometry are constructed in `scripts/art.gd` and `scripts/showcase_art.gd`; no external artwork, models, textures or sample packs were imported.

Release 1.1 uses music and combat effects generated with ElevenLabs from project-written prompts. The player selected the first **Reactor Rush** music audition (`music_v2`); the main effects use `eleven_text_to_sound_v2`. Runtime audio is bundled under `assets/audio/elevenlabs/` and plays offline. Five prepared effects are preserved exactly; additional weapon/install/Guardian cues are local edits and layers of those effects. `tools/install_release_audio.py` documents the conversion and `qa/release-audio.json` records sources and hashes. The generation credential is not part of the game or its source checkout.

Earlier procedural music and remaining interface cues were synthesized by `tools/generate_audio.py`, `tools/generate_weapon_audio.py` and `tools/generate_resonance_audio.py`. NumPy, SoundFile and ffmpeg are development tools for preparation and encoding. Historical audition assets and reports remain in the source checkout; the exported game includes the selected release soundtrack.

This notice records provenance; it does not assign an open-source license to the original game code or assets. Godot's license below applies to the engine, not automatically to the game's original content.

## Prism Drive music update (1.2)

Release 1.2 replaces the background track with **Prism Drive**, an original instrumental generated using ElevenLabs `music_v2_5` from a project-written brief for half-time festival dubstep, synth stabs and growling bass. The new music and existing 1.1 combat effects play offline.

`tools/prepare_prism_music.py` documents local loudness preparation and encoding; `qa/prism-music.json` records provenance, hashes and measurements. These checks establish technical audio properties and do not replace listening. The 1.1 soundtrack and audition history remain in the source checkout, with the new export using `music_prism_drive.ogg`.

## Godot Engine

Pulsebreak uses **Godot Engine 4.7.2**, distributed under the **MIT license**.

Copyright (c) 2014-present Godot Engine contributors.

Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

The full copyright and permission notice is available on the official [Godot license page](https://godotengine.org/license/). Godot's developers explicitly accept this documentation link as an engine license notice. The [engine's third-party notices](https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt) list bundled library and fallback-font licenses; consult the corresponding engine source version when redistributing modified engine binaries.

The export script places a copy of this file at `Pulsebreak.app/Contents/Resources/LICENSES.md` before signing the app. Keep this notice with copies of the native build.

## Fonts

The UI references the macOS system fonts **Avenir Next** and **Helvetica Neue** by name. These font files are not copied into or bundled with the project. Their rights remain with their respective owners. Engine-provided fallbacks are covered by Godot's third-party notices above.
