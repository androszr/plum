# Plum — Store Sim

A small 3D corner shop you can look around, built natively for macOS and iOS
with SwiftUI and RealityKit. The shop, "Plum", is an invented brand: about
51 m² of shelves, fridges, tills and a self-checkout on a street corner, with
parked cars, trees, passing traffic and pedestrians outside.

## What you can do

- **Outside** — orbit, pan and zoom around the lot. Drag to move over the
  ground (two fingers on a trackpad do the same), pinch, a mouse wheel or a
  Command-held scroll zooms, tap a fixture to select it.
- **Inside** — walk the aisles at eye level. W, A, S, D or the arrow keys walk
  (an on-screen stick on iPhone), dragging or two-finger scrolling looks
  around, and tapping bare floor strolls there.

## Requirements

- macOS 26 with Xcode 26 (Swift 6)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Python 3.12 only if you want to regenerate the models (see below)

## Build and run

```bash
xcodegen generate          # writes StoreSim.xcodeproj (not checked in)
open StoreSim.xcodeproj    # run the StoreSim_macOS or StoreSim_iOS scheme
```

Or from the command line, the same checks CI runs:

```bash
bash Scripts/lint.sh                                 # conventions (grep rules)
swift build --package-path Packages/StoreSimKit      # typecheck
swift test  --package-path Packages/StoreSimKit      # unit and snapshot tests
bash Scripts/build.sh                                # Mac app + iPhone simulator app
```

## Layout of the code

| Path | What lives there |
|---|---|
| `App/` | The app shell: `StoreView`, the camera controller, the HUD |
| `Packages/StoreSimKit/Sources/StoreSimKit` | Pure Swift (Foundation + simd only): the shop layout as data, fixture builders, planograms, camera maths, traffic |
| `Packages/StoreSimKit/Sources/StoreSimRender` | The RealityKit side: turns the scene tree into entities, loads models |
| `App/Resources/Models` | Generated `.usdz` models and the product atlas, plus a few sourced ones |
| `App/Resources/Characters` | The three walking pedestrians |
| `Tools/assetgen` | The Python generator that builds the models from `docs/asset-brief.md` |
| `docs/context.md` | Architecture notes and the project's conventions |

The layout is data (`StoreLayout`), validated by `LayoutValidator`, so most of
the scene can be tested without a GPU.

## Models

Most models are generated deterministically:

```bash
bash Scripts/models.sh           # rebuild every model into App/Resources/Models
bash Scripts/models.sh --check   # fail if a shipped file differs from the generator
```

The cars, trees and pedestrians were made with the [Meshy](https://www.meshy.ai)
service and post-processed locally; how each was made is recorded in
`App/Resources/Models.md` and `App/Resources/Characters.md`.

## License

The code is released under the [MIT License](LICENSE).
