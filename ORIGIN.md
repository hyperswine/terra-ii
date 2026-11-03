# Extraction provenance

Upstream: https://github.com/hyperswine/qos

Application revision: `7b5f9c122ada1fe429a865a0a48fdd59d2aa1e2f`.

Application inputs:

- `programs/terra2.fpr`
- `models/tank/tank.fpr`
- `models/infantry/infantry.fpr`
- `models/truck/truck.fpr`
- `models/hq/hq.fpr`

Local changes:

- Package the application in its own repository and retain its original behavior.
- Add Sol build/launch/test orchestration and isolated, ignored data directories.
- Resolve app-local imports within this repository and standard modules through installed toolchain homes.
- Split the single-file program into `src/` modules along the sections it already had: `prelude`, `motion`, `cards`, `board`, `palette`, `model`, `rules`, `actions`, `ai`, `save`, `scene`, `ui`, `terminal` and `input`, leaving the elm four and the tick in `src/terra2.fpr`. Behaviour is unchanged: 248 of 248 native functions, the same 180 precondition obligations, and the same Sol acceptance run. List construction uses `[a, b]`; `::` remains in patterns.
- Build and run with the QOS Portable SDK's `qos build` / `qos run` (`qos.toml` v2, `kind = "app"`). The app-side platform files and the matching FP-RISC runtime are the SDK's private build inputs; no copy is vendored. (Earlier revisions vendored them under `support/` and packaged with a Sol ELF/QAR2 writer.)
- Bound compiler memory and disable optional optimizations for the large game through `qos.toml`; preserve all frontend checks.

Generated artifacts and test captures are not upstream source; reports identify the checks actually run.
