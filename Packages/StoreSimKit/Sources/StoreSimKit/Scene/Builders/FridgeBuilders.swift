import Foundation

enum WallFridgeBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        let w = 0.95, d = 0.6, h = 2.0
        let zBack = -0.15 // pushed against the back wall of the footprint
        var p = Parts()
        let seed = ProductRows.seed(fixture.id)
        p.box("frame", 0, 0.08, zBack - d / 2 + 0.02, w, h - 0.08, 0.04, .paint(c.charcoal))
        p.box("frame_side_left", -w / 2 + 0.02, 0.08, zBack, 0.04, h - 0.08, d, .paint(c.charcoal))
        p.box("frame_side_right", w / 2 - 0.02, 0.08, zBack, 0.04, h - 0.08, d, .paint(c.charcoal))
        p.box("plinth", 0, 0, zBack, w, 0.08, d, .paint(c.primaryDeep))
        p.box("interior_glow", 0, 0.12, zBack - d / 2 + 0.05, w - 0.1, h - 0.3, 0.01, .emissive(c.tileWhite))
        for i in 0..<4 {
            let y = 0.2 + 0.45 * Double(i)
            p.box("shelf_\(i)", 0, y, zBack, w - 0.1, 0.025, d - 0.1, .solid(c.tileWhite, roughness: 0.3))
            for n in ProductRows.make(onShelf: i, y: y + 0.025, width: w - 0.16, z: zBack + 0.02,
                                      detail: detail, seed: seed, prefix: "bottle", mode: .bottles) {
                p.add(n)
            }
        }
        let glass = SurfaceMaterial.glass(c.skyPastel, opacity: 0.25)
        let zFront = zBack + d / 2
        p.box("door_left", -w / 4, 0.08, zFront, w / 2 - 0.02, h - 0.1, 0.02, glass)
        p.box("door_right", w / 4, 0.08, zFront, w / 2 - 0.02, h - 0.1, 0.02, glass)
        p.box("handle_left", -0.04, 0.8, zFront + 0.03, 0.025, 0.5, 0.025, .solid(c.cream, roughness: 0.3))
        p.box("handle_right", 0.04, 0.8, zFront + 0.03, 0.025, 0.5, 0.025, .solid(c.cream, roughness: 0.3))
        p.box("header", 0, h, zBack, w, 0.18, d, .paint(c.primary))
        p.text("header_text", fixture.label ?? "Cold drinks", 0, h + 0.09, zFront + 0.012, 0.09, .paint(c.cream))
        if detail.isFull {
            p.box("compressor_vent", 0, 0.01, zFront + 0.005, w - 0.2, 0.05, 0.01, .paint(c.charcoal))
        }
        return fixtureGroup(fixture, p)
    }
}

enum DairyChillerBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        let w = 1.45, d = 0.9
        var p = Parts()
        let seed = ProductRows.seed(fixture.id)
        p.box("body", 0, 0, 0, w, 0.9, d, .paint(c.primaryLight))
        p.box("open_front_lip", 0, 0.9, d / 2 - 0.03, w, 0.06, 0.06, .paint(c.primaryDeep))
        p.box("glow", 0, 0.9, -0.1, w - 0.1, 0.012, d - 0.3, .emissive(c.tileWhite))
        for i in 0..<3 {
            let y = 0.78 + 0.18 * Double(i)
            p.box("shelf_\(i)", 0, y, -0.05, w - 0.12, 0.02, 0.5 - 0.1 * Double(i), .solid(c.tileWhite, roughness: 0.3))
            for n in ProductRows.make(onShelf: i, y: y + 0.02, width: w - 0.2, z: -0.05, detail: detail,
                                      seed: seed, prefix: "carton", mode: .cartons) {
                p.add(n)
            }
        }
        p.box("back_riser", 0, 0.9, -d / 2 + 0.02, w, 0.45, 0.04, .paint(c.primary))
        p.text("riser_text", "Dairy", 0, 1.12, -d / 2 + 0.05, 0.1, .paint(c.cream))
        return fixtureGroup(fixture, p)
    }
}
