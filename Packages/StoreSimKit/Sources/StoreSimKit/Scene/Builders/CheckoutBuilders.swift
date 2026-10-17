import Foundation

enum CheckoutCounterBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        // 2.0 m x 1.0 m footprint; the customer side is +z.
        p.box("counter", 0, 0, 0, 2.0, 0.95, 0.8, .paint(c.primary))
        p.box("counter_top", 0, 0.95, 0, 2.04, 0.05, 0.84, .paint(c.woodLight))
        p.box("front_stripe", 0, 0.35, 0.405, 1.9, 0.12, 0.01, .paint(c.accentMint))
        p.box("conveyor_belt", -0.45, 1.0, 0.15, 0.8, 0.01, 0.35, .paint(c.charcoal))
        p.box("till", 0.5, 1.0, -0.15, 0.4, 0.12, 0.35, .paint(c.charcoal))
        p.box("till_screen", 0.5, 1.12, -0.2, 0.25, 0.18, 0.02, .emissive(c.accentMint))
        p.box("card_terminal", 0.4, 1.0, 0.2, 0.1, 0.04, 0.16, .paint(c.asphalt))
        p.box("receipt_printer", 0.78, 1.0, -0.12, 0.12, 0.1, 0.14, .paint(c.cream))
        p.box("bag_dispenser", 0.85, 1.0, 0.18, 0.1, 0.2, 0.1, .paint(c.mintDeep))
        p.group("impulse_rack", 0.0, 1.0, 0.3) { g in
            g.box("rack_frame", 0, 0, 0, 0.5, 0.08, 0.1, .paint(c.charcoal))
            let items = [c.priceRailYellow, c.accentMint, c.primaryLight, c.warmLamp, c.cream, c.mintDeep, c.woodLight, c.primary]
            for i in 0..<8 where detail.isFull || i % 2 == 0 {
                g.box("impulse_item_\(i)", -0.21 + 0.06 * Double(i), 0.08, 0, 0.045, 0.1, 0.03, .paint(items[i]))
            }
        }
        return fixtureGroup(fixture, p)
    }
}

enum CigaretteCabinetBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("cabinet", 0, 0, -0.05, 1.45, 1.9, 0.35, .paint(c.charcoal))
        let door = SurfaceMaterial.glass(c.skyPastel, opacity: 0.3)
        p.box("door_left", -0.36, 0.9, 0.13, 0.7, 0.95, 0.02, door)
        p.box("door_right", 0.36, 0.9, 0.13, 0.7, 0.95, 0.02, door)
        for i in 0..<3 {
            p.box("shelf_\(i)", 0, 0.95 + 0.3 * Double(i), 0.0, 1.35, 0.02, 0.25, .paint(c.primaryLight))
        }
        p.box("lottery_screen", 0, 0.35, 0.13, 0.5, 0.3, 0.02, .emissive(c.priceRailYellow))
        if detail.isFull {
            p.box("scratchcard_rack", -0.5, 0.35, 0.14, 0.3, 0.3, 0.03, .paint(c.warmLamp))
        }
        return fixtureGroup(fixture, p)
    }
}

/// Stand-in for a dual self-checkout (1.0 m x 0.5 m); the customer side is +z.
enum SelfCheckoutBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("base", 0, 0, 0, 0.95, 0.1, 0.45, .paint(c.charcoal))
        for (side, x) in [("left", -0.25), ("right", 0.25)] {
            p.box("body_\(side)", x, 0.1, -0.05, 0.4, 0.95, 0.3, .paint(c.primary))
            p.box("screen_\(side)", x, 0.75, 0.105, 0.3, 0.22, 0.02, .emissive(c.accentMint))
            p.box("scanner_\(side)", x, 1.05, -0.03, 0.2, 0.03, 0.2, .paint(c.asphalt))
            p.box("card_terminal_\(side)", x + 0.1, 0.62, 0.12, 0.1, 0.05, 0.1, .paint(c.asphalt))
            p.box("bagging_shelf_\(side)", x, 0.3, 0.12, 0.36, 0.03, 0.14, .paint(c.woodLight))
            if detail.isFull {
                p.cyl("light_pole_\(side)", x - 0.15, 1.05, -0.05, 0.012, 0.5, .paint(c.charcoal))
                p.cyl("beacon_\(side)", x - 0.15, 1.55, -0.05, 0.03, 0.05, .emissive(c.priceRailYellow))
            }
        }
        return fixtureGroup(fixture, p)
    }
}

/// Stand-in for the tall bottle wall behind the tills (2.0 m x 0.5 m); the front is +z.
enum AlcoholWallBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        let w = 1.9, d = 0.35
        let zBack = -0.25 + d / 2
        var p = Parts()
        let seed = ProductRows.seed(fixture.id)
        p.box("base", 0, 0, zBack, w, 0.1, d, .paint(c.charcoal))
        p.box("upright_left", -w / 2 + 0.02, 0.1, zBack, 0.04, 1.8, d, .paint(c.charcoal))
        p.box("upright_right", w / 2 - 0.02, 0.1, zBack, 0.04, 1.8, d, .paint(c.charcoal))
        p.box("back_panel", 0, 0.1, -0.25 + 0.02, w, 1.8, 0.02, .paint(c.cream))
        for i in 0..<5 {
            let y = 0.18 + 0.34 * Double(i)
            p.box("shelf_\(i)", 0, y, zBack, w - 0.08, 0.03, d - 0.04, .paint(c.tileWhite))
            p.box("price_rail_\(i)", 0, y - 0.01, zBack + d / 2 - 0.02, w - 0.08, 0.04, 0.015, .paint(c.priceRailYellow))
            for n in ProductRows.make(onShelf: i, y: y + 0.03, width: w - 0.16, z: zBack + 0.02, detail: detail,
                                      seed: seed, prefix: "bottle", mode: .bottles, variant: variant) {
                p.add(n)
            }
        }
        p.box("header_sign", 0, 1.9, zBack, w, 0.2, d, .paint(c.primary))
        p.text("header_text", fixture.label ?? "Wine & spirits", 0, 2.0, zBack + d / 2 + 0.012, 0.1, .paint(c.cream))
        if detail.isFull {
            p.box("lock_rail", 0, 1.0, zBack + d / 2 - 0.005, w - 0.08, 0.03, 0.01, .paint(c.charcoal))
        }
        return fixtureGroup(fixture, p)
    }
}
