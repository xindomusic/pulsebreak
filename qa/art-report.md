# Procedural art implementation

`scripts/art.gd` provides the four agreed static methods: `build_arena(parent)`, `player()`, `enemy(kind)`, and `boss()`. Every asset is original geometry built from Godot primitives; no downloaded models, textures, fonts, or licensed third-party assets are used.

## Visual intent

- The transfer deck is slate blue with narrow seams, subtle alternate tile values, flush fasteners, dim service rings, and restrained cyan circuit inlays. The full playable square at x/z ±15 is open, with its floor at y=0.
- Navigation pips, warm hazard hatching, small deck labels, and low perimeter rails establish scale without covering enemies. Turbines, an octagonal reactor, pipework, suspended supports, and distant megastructure silhouettes establish a sky foundry around the combat surface.
- The pale armored courier has separate boots, shin plates, shoulders, helmet, cyan visor, rear reactor pack, and a floating segmented energy ring.
- The gunner is an orange tripod with a forward cannon and sensor mast. The magenta charger is a low angular mechanical hound. The heavier purple bruiser carries a large visibly bordered front shield. The guardian has heavy legs and gauntlets, a chest reactor, crown, and segmented orange halo.

## Integration

- All models face local +Z and stand at local ground level. `Body` and `Reactor` are direct children of each actor; the courier and boss also have `Ring`; the bruiser has `Shield`. These groups can be animated independently by the controller.
- Static materials and primitive meshes are cached. Repeated deck tiles, circuit lines, pips, fasteners, rings, rail posts, turbine blades, skyline blocks, and motes use MultiMesh batches. There are no frame callbacks, particle simulations, scene lights, or environment overrides in this file.
- The courier is approximately 1.6 units tall; standard enemies remain small and distinct, with the crouched charger approximately 1.1 units tall. The guardian is approximately 3 units tall. Low rails begin outside the movement boundary.
- Lighting, fog, camera framing, animation, gameplay collision, and effects remain owned by the game director. The raised distant reactor is at approximately (-10, -2, -23), with side turbines outside x ±17.

## Verification

Godot **4.7.2.stable.official.ed1daf0bf** parsed the final script successfully with exit code 0:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/art.gd --check-only
```

The geometry placement and animation-node interface were checked in source. MultiMesh transforms apply local scale before rotation, preserving the intended dimensions of ring segments and angled turbine blades. This report does not claim observed gameplay readability, measured performance, or completed visual review: those require the integrated game's camera and lighting and are part of the main runtime review.
