---
name: ui-hill-climb
description: Run scored UI/UX improvement loops as hill-climbing — every attempt starts from the best-scoring checkpoint, and any attempt that scores lower is thrown out entirely.
---

# UI Hill-Climb Loops

Use when asked to iteratively improve a UI toward a target score with a
cap on loops (e.g. "improve UI/UX to 9/10, max 10 loops"). Never run
linear loops that keep building on the previous attempt regardless of
score: that lets a late, worse loop ship below an earlier, better one.

## Method

1. **Baseline first.** Capture the fixed screen set from the current
   code and score it before changing anything. This is loop 0. Its
   commit is the first checkpoint. No attempt is ever compared
   against scores from an older series or a different rubric.
2. **Fixed measurement.** Every attempt uses the identical capture
   set, identical reviewer prompts, and identical rubric weights.
   Two independent screenshot-only reviewers per attempt: one
   history-aware (given the prior defect list to re-judge), one
   fresh-eyes. Score = the average of both. Record both scores,
   not just the average.
3. **One direction per attempt.** Each attempt starts from the
   best-scoring checkpoint (never from a rejected attempt) and makes
   one coherent set of changes, so accept/reject attribution is clean.
4. **Accept only on a strict win.** If the attempt average is greater
   than the best average, commit it as the new checkpoint
   (`ui-loop: attempt N <direction> (score X)`). If it ties or drops,
   throw the code out: restore the working tree to the best
   checkpoint (`git restore .` plus removing any files the attempt
   added) and verify the tree is clean before the next attempt.
5. **Diagnose every rejection before designing the next attempt.**
   A lower score is data, not just a discard. For each rejected
   attempt, read both full reviews and write a short diagnosis in
   the series record:
   - what the attempt changed (the one direction it tried);
   - which axes and verdicts got worse versus the best checkpoint's
     reviews, quoted from the reviewers' own pixel evidence;
   - the hypothesis for why it scored lower (e.g. "new element read
     as clutter", "fix traded one ambiguity for another",
     "regression: X now overlaps Y");
   - the design consequence: the refined variant or different
     direction the next attempt will take, and why it should not
     repeat the failure.
   The next attempt's plan must cite this diagnosis. Never retry
   the same direction unchanged, and never ignore a regression the
   reviewers photographed — a regression means the direction itself
   is suspect, not just its tuning.
6. **No silent salvage.** A good idea inside a rejected attempt is
   not cherry-picked into the tree unscored; it re-enters as its own
   scored attempt from the best checkpoint, shaped by the diagnosis.
7. **Stop conditions.** Stop early only when the best average reaches
   the target (default: target − 0.5 when the user says "close to",
   e.g. ≥ 8.5 for "close to 9"). Otherwise run the full attempt cap.
   A plateau is reported, never used as an excuse to end early.
8. **Ship the best, not the last.** At the end, the working tree must
   equal the best checkpoint. Verify that state (test suites,
   packaged build, packaged run) and ship it. If no attempt beat the
   baseline, ship nothing and say so.
9. **Record everything.** One series file (e.g. `qa/ui<series>-review.md`)
   with a table: attempt, base checkpoint, direction tried, reviewer
   A, reviewer B, average, accepted or rejected. Rejected attempts
   stay in the record with their scores, what was tried, and the
   step-5 diagnosis (why it scored lower + the design consequence),
   so the next attempt is designed from evidence, not vibes.
10. **Report scores honestly.** Never claim the target was reached
   unless the recorded best average meets it. Name the best score,
   the checkpoint it lives at, and how many attempts were rejected.
