import Foundation

enum CheckoutCounterBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        // 2.0 m x 1.0 m footprint; the customer side is +z.
        p.box("counter", 0, 0, 0, 2.0, 0.95, 0.8, .paint(c.primary))
        p.box("counter_top", 0, 0.95, 0, 2.04, 0.05, 0.84, .paint(c.woodLight))
        p.box("front_stripe", 0, 0.35, 0.405, 1.9, 0.12, 0.01, .paint(c.accentMint))
        // The belt and the card terminal stand clear of the till rack, which the app draws on the counter top.
        p.box("conveyor_belt", -0.45, 1.0, -0.02, 0.8, 0.01, 0.35, .paint(c.charcoal))
        p.box("till", 0.5, 1.0, -0.15, 0.4, 0.12, 0.35, .paint(c.charcoal))
        p.box("till_screen", 0.5, 1.12, -0.2, 0.25, 0.18, 0.02, .emissive(c.accentMint))
        p.box("card_terminal", 0.5, 1.0, 0.28, 0.1, 0.04, 0.16, .paint(c.asphalt))
        p.box("receipt_printer", 0.78, 1.0, -0.12, 0.12, 0.1, 0.14, .paint(c.cream))
        p.box("bag_dispenser", 0.85, 1.0, 0.18, 0.1, 0.2, 0.1, .paint(c.mintDeep))
        return fixtureGroup(fixture, p)
    }
}

/// Closed and plain, as a Polish shop must keep it: solid doors, nothing visible inside, and a small cream
/// price board on each door (the app writes the plain price lines on them).
enum CigaretteCabinetBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("cabinet", 0, 0, -0.025, 1.45, 1.9, 0.45, .paint(c.charcoal))
        p.box("door_left", -0.36, 0.9, 0.21, 0.7, 0.95, 0.02, .paint(c.primary))
        p.box("door_right", 0.36, 0.9, 0.21, 0.7, 0.95, 0.02, .paint(c.primary))
        p.box("price_board_left", -0.36, 1.05, 0.225, 0.5, 0.4, 0.01, .paint(c.cream))
        p.box("price_board_right", 0.36, 1.05, 0.225, 0.5, 0.4, 0.01, .paint(c.cream))
        p.box("lottery_screen", 0, 0.35, 0.21, 0.5, 0.3, 0.02, .emissive(c.priceRailYellow))
        if detail.isFull {
            p.box("scratchcard_rack", -0.5, 0.35, 0.22, 0.3, 0.3, 0.03, .paint(c.warmLamp))
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

/// Stand-in for the spirits wall behind the tills: a thin empty frame (2.0 m x 0.2 m x 2.6 m) against the
/// front wall. Its shelves, bottles, labels and promo tags are the merchandise layer, drawn from the
/// planogram; one bottle deep, so the frame is thin. The front is +z.
enum AlcoholWallBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode {
        let c = Brand.palette
        let w = 2.0, d = 0.2, h = 2.6
        let zBack = -0.25 + d / 2
        let header = 0.16
        let top = h - header
        var p = Parts()
        p.box("base", 0, 0, zBack, w, 0.10, d, .paint(c.charcoal))
        p.box("upright_left", -w / 2 + 0.02, 0.10, zBack, 0.04, top - 0.10, d, .paint(c.charcoal))
        p.box("upright_right", w / 2 - 0.02, 0.10, zBack, 0.04, top - 0.10, d, .paint(c.charcoal))
        p.box("back_panel", 0, 0.10, -0.25 + 0.01, w - 0.08, top - 0.10, 0.02, .paint(c.cream))
        p.box("header_sign", 0, top, zBack, w, header, d, .paint(c.primary))
        p.text("header_text", fixture.label ?? "Vodka & whisky", 0, top + header / 2, zBack + d / 2 + 0.012, 0.09, .paint(c.cream))
        if detail.isFull {
            p.box("lock_rail", 0, 0.04, zBack + d / 2 + 0.003, w - 0.08, 0.03, 0.006, .paint(c.charcoal))
        }
        return fixtureGroup(fixture, p)
    }
}
