# Terra II

The original Terra II positional card game in a standalone 3D QOS Portable window, including its embedded unit meshes.

## Install and run

Needs QOS Portable 0.3.0 or later (`[sdk] version` in `qos.toml`), which adds `kind = "app"` projects to `qos build` and `qos run`. 0.3.0 is not released yet; until it is, put a staged SDK's `bin/` first on `PATH`. Tested on macOS ARM64.

```sh
brew install hyperswine/tap/fprisc hyperswine/tap/qos-portable  # fprisc provides sol
git clone https://github.com/hyperswine/terra-ii.git
cd terra-ii
qos build
qos run
```

Enter starts/continues a game. Arrow keys move the cursor; Enter picks/confirms; Space or E ends the turn. A attacks, O overwatches, R retreats, V advances, C charges and F fires artillery. Escape cancels/pauses; P captures a frame; Q quits.

The upstream V1 rules and existing exclusions are retained. This extraction does not add card texts, the Unsupplied rule, RECALL, requisition or a mulligan.

## Test

![Game captured by the Sol test harness](evidence/game.png)

```sh
sol project.sol test
```

The Sol GUI harness captures the original title and game screens, sends cursor/card/end-turn input, checks changed frames, and verifies a clean quit. It runs against a fresh temporary disk; screenshots and JSON results are retained under `evidence/`.

Builds can take several minutes for the larger applications. Build/test commands have explicit deadlines and return a failure when a child process fails. Generated binaries, caches, data, keys and raw logs are excluded from Git.

## Build tools

`qos.toml` (manifest 2, `kind = "app"`) describes the game. `qos build` compiles it with the SDK's own compiler, prelude and modules, links the SDK's private app-side platform files and the FP-RISC runtime that matches that compiler, checks a second link displaced by 256 MiB, and writes `build/terra-ii.qa`. `qos run` creates `data/terra-ii.disk` if needed and starts the SDK's `qosp-gl`. The project carries no copy of QOS's platform code and no build scripts; `sol project.sol build | run | test` only sequences those commands and the Sol test harness.

This game is large, so `qos.toml` sets `optimize = "checks-only"` and `compiler-memory-mb = 2048`: the compiler's heap is bounded at 2 GiB and its optional specialisation, inlining, reuse, vector and receive-turn optimisations are off. Type, safety and linearity checks stay on. The built archive records both settings.

The SDK's `qos` command needs Python 3.11+, Clang and lld. macOS `sips` exports test PNGs; a shell and standard utilities provide FIFO and descriptor plumbing for the tests.

## Source layout

`src/terra2.fpr` is the entry: the elm four (`init`, `update`, `subs`, `view`), the 40 ms tick and `run`/`main`. The rest of the game is beside it, one module per concern:

| module | what lives there |
| --- | --- |
| `src/prelude.fpr` | index math, list surgery, the LCG |
| `src/motion.fpr` | easing, integer trig, the clock's waves |
| `src/cards.fpr` | the two factions and what a card is |
| `src/board.fpr` | units, sides, supply, the walker's milli geometry |
| `src/palette.fpr` | every colour, named once |
| `src/model.fpr` | screens, selection, queued actions, the animation in flight |
| `src/rules.fpr` | validation, effects, the phases of a turn |
| `src/actions.fpr` | a queued action's animation, and the clock that plays it |
| `src/ai.fpr` | the enemy side's plan |
| `src/save.fpr` | the profile and the live game on the disk |
| `src/scene.fpr` | the 3D board the walker draws |
| `src/ui.fpr` | the scene2d layer over it |
| `src/terminal.fpr` | the model as a data console |
| `src/input.fpr` | keys, the selection state machine, the lifecycle |

## Source and license

Extracted from [hyperswine/qos](https://github.com/hyperswine/qos/tree/7b5f9c122ada1fe429a865a0a48fdd59d2aa1e2f) at `7b5f9c122ada1fe429a865a0a48fdd59d2aa1e2f`. See [ORIGIN.md](ORIGIN.md) for the source map and local changes, and [LICENSE](LICENSE) for the upstream MIT license. No existing application data, private credentials, deployed host configuration or original source checkout is required.
