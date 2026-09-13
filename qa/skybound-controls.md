# Skybound keyboard and animation checks

Godot 4.7.2 passed **30/30 keyboard, animation-state, pause, remap, and restart checks** in both headless execution and native Metal rendering on Apple M4. The successful native run produced **11 captures**: seven gameplay frames and four close views of the articulated courier.

`tests/native_controls_check.gd` injects `InputEventKey` events with `Input.parse_input_event` and advances the real `game._physics_process`. Jump requests are exercised through the game's keyboard handler; the test never calls `traversal.request_jump` directly. Movement runs with `qa_mode = false`, so the automated campaign pilot is not involved. Rebinding temporarily enables `qa_mode` only to prevent saving test preferences.

The native fixture temporarily disconnects incidental desktop focus-loss callbacks during capture and repeats held-key echo events between simulated physics frames. It reconnects the original production callback and verifies its pause behavior explicitly. The rig close views temporarily change the camera and hide the HUD; they show poses reached through the keyboard sequence, without assigning joint transforms. These are automated input and rendering checks, not a human playtest or an audio review.

| Behavior | Evidence |
| --- | --- |
| D movement articulates hips, knees, and alternating legs | [Gait A](skybound-controls/captures/02-gait-a-rig.png), [gait B](skybound-controls/captures/03-gait-b-rig.png) have visibly different steps and arm swings. |
| F raises the actual model and reaches the three-meter apex | [Ascent](skybound-controls/captures/04-jump-ascent.png) shows 1.9m, [apex](skybound-controls/captures/05-apex.png) shows 3.2m and clear separation from the ground marker. |
| Holding F deploys wings and consumes flight fuel | [Glide gameplay](skybound-controls/captures/06-glide.png) shows the reduced fuel bar; [glide rig](skybound-controls/captures/06-glide-rig.png) shows deployed wings, pitched torso, and airborne legs. |
| Releasing F ends glide and restores a landing pose | [Landing rig](skybound-controls/captures/07-landing-rig.png) returns the feet to the deck with folded wings. The test also checks impact compression and subsequent plume shutdown. |
| Space uses the newly pressed movement direction | A then Space, with no gameplay physics frame between presses, produces a leftward dash at the real dash speed. |
| Jump remapping, pause, focus loss, and restart work | The real rebind handler changes jump from F to J; F stops jumping, J jumps and holds. Escape pauses/resumes, the original focus callback pauses, and campaign restart clears altitude/resources/objectives while preserving J. |

The earlier native launch lost desktop focus and paused before movement. Its captures were replaced by the successful 30/30 run; only the regenerated files above are evidence.

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/native_controls_check.gd
.tools/Godot.app/Contents/MacOS/Godot --path . --script tests/native_controls_check.gd
```

The related altitude/gate suite also passed **34/34 checks** after adding a regression for Wide Receiver's expanded radius: a collector on the opposite side of a closed shutter cannot harvest through it, while a receiver on the same side still works. Harvest visibility is evaluated at the swept closest-approach time.
