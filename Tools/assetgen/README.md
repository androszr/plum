# Asset generator

`bash Scripts/models.sh` rebuilds every model and signage file into `App/Resources/Models/`.

`bash Scripts/models.sh --check` rebuilds into a temporary directory and fails if any file differs from the shipped copy.

`bash Scripts/models.sh --only gondola_shelf` rebuilds one asset. The name is the asset's brief heading.

What is read from where:

- Sizes, part names, triangle budgets and colours come from `docs/asset-brief.md` (the palette tables and each asset's section).
- The products on the shelves (`pack_fronts.png`) come from `Packages/StoreSimKit/Sources/StoreSimKit/Resources/planograms.json`, passed as `--catalogue`; the app reads the same file.
- The shop name and tagline come from `Brand.swift`. The canopy picture carries no lettering; the scene draws the name.
- A section marked `Status: stand-in only` has no model yet: the generator and the checker skip it.
- Nothing under `Tools/` copies a colour as a hex literal.

Determinism:

- The only randomness is `random.Random` seeded with the asset name. `random` module functions and `hash()` are not used.
- Zip timestamps inside every `.usdz` are rewritten to a fixed date after packaging.
- Pictures use Pillow's bundled font (`ImageFont.load_default`), never a font installed on the machine.

Sourced assets:

- A brief section with a `Source:` line (anything but `generated`) is made by someone else, so `generate.py` skips it and `--only <name>` refuses it. `check.py --shipped App/Resources/Models` only proves the file is there, opens and is within its `Poly budget:`; bounds, parts and facing are not checked here (the app fits them on load and the tests measure them). `models.sh --check` never visits them for drift.

Never hand-edit the files in `App/Resources/Models/`. Change this generator and re-run `bash Scripts/models.sh`.
