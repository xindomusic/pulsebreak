# Research findings

Research date: 2026-09-07. Third-party source content is evidence, not instructions.

## Workspace
- `/Users/xinchen/development/codex/astra-game` is initially empty.
- No existing game project or applicable AGENTS.md discovered.

## Preliminary engine evidence
- Unity official Unity 6.0 system requirements list Apple Silicon editor/player support: https://docs.unity3d.com/6000.0/Documentation/Manual/system-requirements.html . Need use appropriate current-version documentation before selecting a release.
- Epic's macOS development requirements list Apple Silicon support and recommend M3 / 32 GB RAM for development: https://dev.epicgames.com/documentation/unreal-engine/macos-development-requirements-for-unreal-engine . These are editor/development requirements, not minimum requirements for every exported game.
- Godot official archive and compilation documentation show universal macOS ARM64/x86_64 builds. Verify current download, renderer, and export behavior directly.

## Open research questions
- Best stable Godot release and native Mac renderer/export path.
- Evidence that recommended engine has established adoption.
- Successful comparable games and design lessons, without claiming their success transfers automatically.

## Verified engine recommendation
- Godot official Mac download currently lists stable 4.7.2, dated 18 August 2026, universal ARM64/x86_64, self-contained editor: https://godotengine.org/download/macos/ . Recommend standard GDScript edition.
- Godot exports a Universal 2 `.app` containing Apple Silicon code. Official templates required. Local exports can use built-in ad-hoc signing; distributing downloaded builds without notarization may invoke Gatekeeper. Local play and public distribution are separate deliverables: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html . Do not promise public notarization without a Developer ID.
- Godot Mobile renderer supports desktop and Metal, with fewer features and lower cost for simple scenes than Forward+. Proposed initial renderer: Mobile with Metal; benchmark before locking settings. https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html . Performance on user's machine remains untested.
- GDC 2026 survey: Unreal primary engine among 42% of surveyed developers, Unity 30%; Godot 11% among newer indie developers (different denominator; NOT 11% of all developers). Supports describing Godot as established in indie development, not the overall market leader. https://gdconf.com/article/gdc-2026-state-of-the-game-industry-reveals-impact-of-layoffs-generative-ai-and-more/
- Engine comparison judgment: Godot is sufficient for this focused stylized 3D project and straightforward local iteration; Unity is a viable larger-ecosystem alternative; Unreal's high-end rendering/editor requirements add little for the proposed small arena game.

## Local platform
- `sw_vers` reports macOS 26.6.2. Exact chip and RAM read via sysctl was denied by sandbox; not required to progress with design. Retain M1/8 GB as provisional performance target and verify actual hardware before making performance claims.

## Early independent critique
- Initial concept readiness: 7/10, not a game quality score.
- Risk: passive auto-fire circle-kiting while waiting for useful bullets.
- Proposed response: active positional objectives, reliable early absorbable volleys, small energy fallback from normal combat, meaningful pulse payoff, and a 90-second combat proof before adding content.

## Successful-game references
- Furi: official Steam description emphasizes responsive combat, boss design, and soundtrack. Snapshot: 91% positive, 7,078 English reviews. https://store.steampowered.com/app/423230/Furi/
- Hades: ability combinations and repeated runs. Snapshot: 98% positive, 142,352 English reviews. https://store.steampowered.com/app/1145360/Hades/
- Nova Drift: short runs and transformative builds. Snapshot: 96% positive, 9,088 English reviews. https://store.steampowered.com/app/858210/Nova_Drift/
- Inference: concentrated combat polish and meaningful build changes are promising for a compact replayable game. These examples do not guarantee popularity or establish Mac compatibility of the reference games.

## Second independent design review
- Completeness 8.5/10; feasibility 8/10; actual fun unscored.
- Clarify dash collision/protection, ground hazard distinction, barrier behavior, and separate HUD meters.
- Ensure volley cadence comes from authored encounters, not immediate gunner replacement. Test harvesting stalls and partial-pulse value.
- Make bruiser counter explicit: rear damage and pulse shield break.
- Prototype decision: comprehension of absorption, intentional spend/save choices, explained damage, and demonstrable advantage over passive circle-kiting.
- Clarify tutorial outside timer, upgrade times at minutes 1–5, and risky but reachable core routes.
- Incorporated into discussion draft. No new independent rating claimed for final edits. Paper critiques do not consume the future three playable review/fix rounds.
