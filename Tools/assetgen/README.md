# Asset generator

`bash Scripts/models.sh` rebuilds every model and signage file into `App/Resources/Models/`.

`bash Scripts/models.sh --check` rebuilds into a temporary directory and fails if any file differs from the shipped copy.

`bash Scripts/models.sh --only gondola_shelf` rebuilds one asset. The name is the asset's brief heading.

What is read from where:

- Sizes, part names, triangle budgets and colours come from `docs/asset-brief.md` (the palette table and each asset's section).
- The shop name and tagline come from `Brand.swift`. The canopy picture carries no lettering; the scene draws the name.
- Nothing under `Tools/` copies a colour as a hex literal.

Determinism:

- The only randomness is `random.Random` seeded with the asset name. `random` module functions and `hash()` are not used.
- Zip timestamps inside every `.usdz` are rewritten to a fixed date after packaging.
- Pictures use Pillow's bundled font (`ImageFont.load_default`), never a font installed on the machine.

Never hand-edit the files in `App/Resources/Models/`. Change this generator and re-run `bash Scripts/models.sh`.
