import Foundation

enum Shelving {
    /// Shared uprights, back panel, shelves, rails, header and product rows.
    /// A double-sided unit has its back panel on the centre line and mirrors the
    /// shelves, rails and products onto the -z side (names carry `_back`).
    static func parts(_ f: Fixture, width w: Double, depth d: Double, height h: Double,
                      header: String, detail: DetailLevel, doubleSided: Bool = false) -> Parts {
        let c = Brand.palette
        var p = Parts()
        let seed = ProductRows.seed(f.id)
        p.box("base", 0, 0, 0, w, 0.1, d, .paint(c.charcoal))
        p.box("upright_left", -w / 2 + 0.02, 0.1, 0, 0.04, h - 0.1, d, .paint(c.primaryDeep))
        p.box("upright_right", w / 2 - 0.02, 0.1, 0, 0.04, h - 0.1, d, .paint(c.primaryDeep))
        let panelZ = doubleSided ? 0.0 : -d / 2 + 0.01
        p.box("back_panel", 0, 0.1, panelZ, w - 0.08, h - 0.1, 0.02, .paint(c.cream))
        if detail.isFull {
            for i in 0..<3 {
                p.box("slot_row_\(i)", 0, 0.33 + 0.35 * Double(i), panelZ + 0.015, w - 0.1, 0.012, 0.01, .paint(c.charcoal))
            }
        }
        let shelfDepth = doubleSided ? d / 2 - 0.03 : d - 0.04
        let sides: [(sign: Double, suffix: String)] = doubleSided ? [(1, ""), (-1, "_back")] : [(1, "")]
        for side in sides {
            let centreZ = doubleSided ? side.sign * (d / 4 + 0.005) : 0
            let railZ = side.sign * (d / 2 - 0.02)
            let productZ = doubleSided ? side.sign * (d / 2 - 0.09) : d / 2 - 0.12
            for i in 0..<4 {
                let y = 0.12 + 0.35 * Double(i)
                p.box("shelf\(side.suffix)_\(i)", 0, y, centreZ, w - 0.08, 0.03, shelfDepth, .paint(c.tileWhite))
                p.box("price_rail\(side.suffix)_\(i)", 0, y - 0.01, railZ, w - 0.08, 0.04, 0.015, .paint(c.priceRailYellow))
                let rowSeed = side.sign > 0 ? seed : seed ^ 11400714819323198485
                for n in ProductRows.make(onShelf: i, y: y + 0.03, width: w - 0.14, z: productZ, detail: detail,
                                          seed: rowSeed, prefix: "product\(side.suffix)") {
                    p.add(n)
                }
            }
        }
        p.box("header_sign", 0, h, 0, w, 0.2, d, .paint(c.primary))
        p.text("header_text", header, 0, h + 0.1, d / 2 + 0.012, 0.1, .paint(c.cream))
        if doubleSided {
            p.text("header_text_back", header, 0, h + 0.1, -d / 2 - 0.012, 0.1, .paint(c.cream), yaw: .pi)
        }
        return p
    }
}

enum GondolaShelfBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        fixtureGroup(fixture, Shelving.parts(fixture, width: 0.9, depth: 0.5, height: 1.5,
                                              header: fixture.label ?? "Shelf", detail: detail,
                                              doubleSided: true))
    }
}

enum WallShelfBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        var inner = Shelving.parts(fixture, width: 0.95, depth: 0.3, height: 1.7,
                                   header: fixture.label ?? "Wall shelf", detail: detail)
        inner.box("wall_rail", 0, 1.55, -0.14, 0.95, 0.03, 0.02, .paint(Brand.palette.woodLight))
        // Shift the 0.3 m deep unit to the back edge of its 0.5 m footprint.
        var p = Parts()
        p.group("shelf_unit", 0, 0, -0.1) { $0 = inner }
        return fixtureGroup(fixture, p)
    }
}

enum EndCapBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        let w = 0.9, d = 0.4
        var p = Parts()
        let seed = ProductRows.seed(fixture.id)
        p.box("base", 0, 0, 0, w, 0.1, d, .paint(c.charcoal))
        p.box("back", 0, 0.1, -d / 2 + 0.01, w, 1.1, 0.02, .paint(c.cream))
        for i in 0..<3 {
            let y = 0.15 + 0.35 * Double(i)
            p.box("shelf_\(i)", 0, y, 0, w - 0.04, 0.03, d - 0.04, .paint(c.tileWhite))
            p.box("price_rail_\(i)", 0, y - 0.01, d / 2 - 0.02, w - 0.04, 0.04, 0.015, .paint(c.priceRailYellow))
            for n in ProductRows.make(onShelf: i, y: y + 0.03, width: w - 0.12, z: d / 2 - 0.1, detail: detail, seed: seed) {
                p.add(n)
            }
        }
        p.box("promo_sign", 0, 1.2, 0, w, 0.2, d, .paint(c.mintDeep))
        p.text("promo_text", fixture.label ?? "Offers", 0, 1.3, d / 2 + 0.012, 0.09, .paint(c.cream))
        return fixtureGroup(fixture, p)
    }
}
