# The GPT-6 Astra × Codex experiment

## The question

Could **GPT-6 Astra inside Codex** help carry an idea all the way to a playable, tested native 3D game on an Apple Silicon Mac, while independent sub-agents found defects and assessed the result?

The user asked for research, a suitable established engine, a fun and replayable game, a design discussion before implementation, and a score above 9/10 after at most three review/fix loops. After the design and model recommendation, the user approved implementation. A later request authorized public publication under [xindomusic](https://github.com/xindomusic).

The result is Pulsebreak. The above-9 target was **not** established: the final observational rating was **8.2/10**. Both the functioning game and that shortfall are part of the experiment.

## What “GPT-6 Astra inside Codex” means here

GPT-6 Astra was the chosen model for the development workflow. Codex was the working environment for research, repository edits, shell execution, delegation, and native UI inspection. Astra with `xhigh` reasoning was recommended for the build; bounded specialist and reviewer tasks used Astra sub-agents. These are the choices recorded in this session. The repository does not contain a full model-request audit log.

The [official GPT-6 Astra model page](https://developers.openai.com/api/docs/models/gpt-6-astra) and [Codex documentation](https://developers.openai.com/codex/) provide product context. The experiment's conclusions come from the repository and recorded runs, not a competing-model benchmark.

There is no AI service in the shipped game. Enemy behavior, progression, collisions, assets, and saves execute locally in Godot. The Python audio generator performs deterministic synthesis without an audio-generation API. Players need neither a Codex subscription nor an OpenAI API key.

## Division of work

| Participant or component | Role |
|---|---|
| Human requester | Set platform and quality goal; requested design first; approved implementation and public publication |
| Main Codex agent | Researched engines and references, implemented gameplay, integrated modules, ran tools and addressed findings |
| Art sub-agent | Wrote isolated procedural arena and actor geometry |
| Audio sub-agent | Created synthesized cues/music, playback logic, and a shutdown fix |
| Save sub-agent | Implemented validated atomic persistence and checks; later prepared initial delivery documentation |
| Independent review sub-agent | Inspected code, tests and captures; found defects; scored each cycle with evidence limits |
| Godot and native tools | Imported assets, ran simulations, rendered frames, exported the app, verified signatures |
| CUA interface | Exercised native keyboard/menu paths and inspected the application visually |

This was iterative tool-assisted work, not a single prompt producing an untouched finished game. Separate review sessions reduced shared implementation assumptions, but remained AI reviews within the same overall tool environment.

## Workflow

1. **Research and discussion.** Compare Godot, Unity, and Unreal for a focused Mac project. Study successful combat/build patterns without assuming a new game inherits their popularity.
2. **Approve a bounded design.** One arena, three regular enemy roles, nine upgrades, six wave minutes, and a two-phase boss.
3. **Build rules and presentation.** Separate resource rules from rendered entities, UI, audio, and storage. Bound effects and projectiles.
4. **Test actual failure cases.** Reproduce findings with failing checks before implementing fixes.
5. **Package and observe.** Export a native app, inspect screens, exercise controls, and measure real frames separately from fixed-speed simulations.
6. **Use at most three review/fix cycles.** Preserve original findings and focused rechecks. Stop at the cap and report the achieved result.

Two earlier paper-design critiques are recorded in the research history. They were design feedback, not playable quality rounds, and did not consume the three later cycles.

## Results

| Measure | Outcome |
|---|---|
| Complete local game | Native universal Mac app, including Apple Silicon code |
| Final checks | 131 passing assertions across three suites |
| Final packaged simulation | Normal-mode victory at 405.6 seconds; 30 hull remaining |
| Native render evidence | Round-two candidate: 48,258 samples, p95 10.353 ms on M1 Max / 32 GB |
| Round-one post-fix rating | 7.385/10 observational |
| Round-two post-fix rating | 8.05/10 observational |
| Round-three post-fix rating | 8.2/10 observational |
| Alternate-build trials | Losses retained; an Assist trial reached the boss before losing |

The [QA index](../qa/README.md) identifies packages, settings, hardware, and reports. The render benchmark predates the last fixes; the final package has a verified title render and full headless victory. Those are distinct pieces of evidence.

## Limits

This is one project, engine, machine, and recorded workflow. There is no control group, matched competing-model implementation, blinded human panel, or repeated population of developers. Elapsed time, token consumption, monetary cost, and the full prompt stream were not captured as a complete audit dataset. This repository does not invent totals for them.

The driver knows game state and behaves consistently. It uses actual abilities and collision limits, but makes different decisions from a human. A victory establishes a reachable winning path for that driver; a loss does not establish that a build is unwinnable. Staged images establish layout and visual intent, not control feel. Numeric audio validation is not listening.

The useful conclusion is narrow: this workflow produced a complete local game and found consequential defects through independent review. It did not establish 9+ subjective quality. [Lessons learned](LESSONS_LEARNED.md) explains which checks provided the strongest evidence.

## Repeat or extend it

Use [Getting started](GETTING_STARTED.md), then run the [tests and drivers](TESTING.md). For a new development experiment, record the initial prompt, human interventions, model and reasoning setting, tool versions, elapsed time, cost if available, and evaluation rules before implementation.

Keep scope and review caps comparable. Ask reviewers for observable defects and reasons, not a desired score. To study model quality, use repeated matched tasks and independent human evaluation rather than treating this project's 8.2 as a general model score.
