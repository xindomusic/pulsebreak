# Lessons from the experiment

The most useful result of the GPT-6 Astra/Codex workflow was not a score. It was a playable artifact accompanied by specific examples of failures that were found, reproduced, and corrected.

## Independent review needs concrete observations

An instruction to “make it better than 9” does not define a test. Review became useful when the reviewer explained an input sequence, a mismatched collision boundary, or a misleading teaching condition. The implementation agent could then challenge the explanation, reproduce it, and fix the actual behavior.

| Finding | Why it mattered | Resolution |
|---|---|---|
| Practice completed into a Resume loop | The default completion action immediately paused again | A dedicated completion state with a fresh full-run action |
| Charger warnings lacked direction | Players could see danger without seeing the committed path | A locked direction strip with appropriate contact width |
| HUD bars overlapped helper text | Runtime control minimum size differed from intended size | Configure styles/percentage behavior before assigning final bar dimensions |
| Rebinding left old teaching labels | Correct InputMap behavior was still confusing to a player | Shared binding labels and immediate practice-hint refresh |
| Quick direction changes used old dash facing | Physics-frame sampling missed current held input | Sample movement when accepting the human dash |
| A diagonal charge slid along a wall | Movement continued outside the shortened warning | Share the first-wall travel calculation between warning and lunge |
| Any pulse completed the lesson | A miss or immune spawning target could “teach” success | Require a direct hit on a live target; keep retry possible |
| Static Field did not slow lunges | The card promised more than one movement branch delivered | Apply the movement reduction to committed charges too |
| Changing apps left combat running | A routine desktop action could cost a run | Pause human gameplay on window focus loss |

The [review reports](../qa/README.md) preserve the original findings and rechecks, instead of silently replacing the first assessment with the improved result.

## A green test suite can miss the user's path

The automated driver set its desired facing immediately before calling dash. Human input followed a different path, where facing could be one physics frame old. A successful bot run therefore did not expose a consequential input defect.

Similarly, a tutorial test that only checks whether a pulse was requested can pass while teaching the wrong thing. The useful assertion was that a live target actually took pulse damage. Tests should be tied to the user's observable result, not only to the implementation's intermediate counter.

The final suites contain 131 checks, including those regressions. That count is evidence of coverage in named areas, not a percentage of correctness or a substitute for manual play.

## Measure what you intend to claim

The initial 16.67 ms timing was a fixed physics step. Treating it as rendering performance would have manufactured a 60 FPS result. The instrumentation was replaced with elapsed rendered-frame intervals, simulation labeling, settings/hardware metadata, and minute/boss segments.

The measured round-two native candidate had a 10.353 ms p95 on an M1 Max / 32 GB machine. The final package has later fixes, so the documentation does not relabel that old benchmark as a fresh final-package measurement. Exact resource-pack hashes make that distinction inspectable.

Screen captures also need labels. A staged boss scene can demonstrate readable UI, but cannot demonstrate that a human survived to it. Numeric sound peaks can demonstrate absence of sample clipping, but cannot demonstrate a pleasing mix.

## Small scope made the end-to-end loop feasible

One arena and a small set of reusable mechanics allowed effort to go into pause behavior, practice, save recovery, menus, packaging, and a real ending. Procedural geometry and synthesized audio removed asset-pipeline dependencies while keeping provenance clear.

The tradeoff is visible: a restrained arena, limited content, and only a few build families. The approach produced a complete experiment, not the breadth of a commercial roguelite. Expanding content before validating the core control and combat loop would make both development and evaluation harder.

## Build diversity needs more than a catalogue

Nine distinct upgrades exist, but the recorded alternate trail-oriented driver still lost. Universal checkpoint repairs reduced early dependence on a healing pick, and the review corrected Static Field's lunge behavior. Those changes do not establish that every build is equally useful.

An improved balance study would keep seeds and difficulty matched, use policies or humans that actually exploit each build's mechanics, and record wins and losses across multiple runs. Selecting a single successful run after many hidden failures would not answer the balance question.

## Preserve the shortfall

The final observational score was 8.2/10 after the third authorized cycle. Human control feel, audible quality, and alternate-build balance remained uncertain. The cap was honored and the missing evidence was recorded. A review workflow is more credible when it can finish below its requested target.

The [roadmap](ROADMAP.md) turns those limits into possible follow-up work. The original experiment remains complete as a historical record; a new iteration should have its own protocol and measurements.
