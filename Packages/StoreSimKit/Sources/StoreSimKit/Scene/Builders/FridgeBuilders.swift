import Foundation

/// The drinks fridge's empty carcass: 1.0 x 1.0 x 2.2 m, centred on its footprint. Its shelves and goods
/// are the merchandise layer (`Merchandiser`), laid out from the planogram.
enum WallFridgeBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        // Built 5 mm inside its 1.0 m footprint on every side, so it never shares a face with the wall or a neighbour.
        let w = 0.99, d = 0.99, h = 2.2
        let headerHeight = 0.16
        let top = h - headerHeight
        var p = Parts()
        p.box("frame", 0, 0.10, -d / 2 + 0.02, w, top - 0.10, 0.04, .paint(c.charcoal))
        p.box("frame_side_left", -w / 2 + 0.02, 0.10, 0, 0.04, top - 0.10, d, .paint(c.charcoal))
        p.box("frame_side_right", w / 2 - 0.02, 0.10, 0, 0.04, top - 0.10, d, .paint(c.charcoal))
        p.box("plinth", 0, 0, 0, w, 0.10, d, .paint(c.primaryDeep))
        p.box("interior_glow", 0, 0.12, -d / 2 + 0.05, w - 0.1, top - 0.14, 0.01, .emissive(c.tileWhite))
        let glass = SurfaceMaterial.glass(c.skyPastel, opacity: 0.25)
        let zDoor = d / 2 - 0.012
        p.box("door_left", -w / 4, 0.10, zDoor, w / 2 - 0.02, top - 0.10, 0.02, glass)
        p.box("door_right", w / 4, 0.10, zDoor, w / 2 - 0.02, top - 0.10, 0.02, glass)
        p.box("handle_left", -0.04, 0.8, d / 2 + 0.007, 0.025, 0.5, 0.02, .solid(c.cream, roughness: 0.3))
        p.box("handle_right", 0.04, 0.8, d / 2 + 0.007, 0.025, 0.5, 0.02, .solid(c.cream, roughness: 0.3))
        p.box("header", 0, top, 0, w, headerHeight, d, .paint(c.primary))
        p.text("header_text", fixture.label ?? "Cold drinks", 0, top + headerHeight / 2, d / 2 + 0.012, 0.09, .paint(c.cream))
        if detail.isFull {
            p.box("compressor_vent", 0, 0.02, d / 2, w - 0.2, 0.05, 0.01, .paint(c.charcoal))
        }
        return fixtureGroup(fixture, p)
    }
}

enum DairyChillerBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
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
                                      seed: seed, prefix: "carton", mode: .cartons, variant: variant) {
                p.add(n)
            }
        }
        p.box("back_riser", 0, 0.9, -d / 2 + 0.02, w, 0.45, 0.04, .paint(c.primary))
        p.text("riser_text", "Dairy", 0, 1.12, -d / 2 + 0.05, 0.1, .paint(c.cream))
        return fixtureGroup(fixture, p)
    }
}
