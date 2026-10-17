import Foundation

enum BasketStackBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("stand", 0, 0, 0, 0.4, 0.05, 0.4, .paint(c.charcoal))
        for i in 0..<5 {
            p.box("basket_\(i)", 0, 0.05 + 0.1 * Double(i), 0, 0.38, 0.1, 0.3, .paint(i % 2 == 0 ? c.primary : c.accentMint), round: 0.02)
        }
        return fixtureGroup(fixture, p)
    }
}

enum BackRoomDoorBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        // The footprint is 0.5 m deep; the frame's back sits on the wall at z = -0.25.
        p.box("frame", 0, 0, -0.21, 1.0, 2.1, 0.08, .paint(c.charcoal))
        p.box("door", 0, 0, -0.18, 0.9, 2.0, 0.05, .paint(c.woodLight))
        p.box("push_plate", 0.3, 0.95, -0.14, 0.1, 0.25, 0.01, .paint(c.asphalt))
        p.box("staff_only_sign", 0, 1.7, -0.14, 0.4, 0.12, 0.01, .paint(c.primaryDeep))
        return fixtureGroup(fixture, p)
    }
}

enum PendantLampBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.cyl("cord", 0, 2.6, 0, 0.008, 0.5, .paint(c.charcoal))
        p.cyl("shade", 0, 2.35, 0, 0.16, 0.25, .paint(c.primary))
        p.cyl("bulb", 0, 2.28, 0, 0.05, 0.08, .emissive(c.warmLamp))
        return fixtureGroup(fixture, p)
    }
}

enum EntranceDoorBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        let glass = SurfaceMaterial.glass(c.skyPastel, opacity: 0.25)
        p.box("frame", 0, 2.25, 0, 1.5, 0.1, 0.1, .paint(c.charcoal))
        p.box("leaf_left", -0.37, 0, 0.0, 0.72, 2.25, 0.04, glass)
        p.box("leaf_right", 0.37, 0, 0.0, 0.72, 2.25, 0.04, glass)
        p.box("handle_left", -0.08, 0.9, 0.05, 0.03, 0.4, 0.03, .paint(c.cream))
        p.box("handle_right", 0.08, 0.9, 0.05, 0.03, 0.4, 0.03, .paint(c.cream))
        p.box("mat", 0, 0, 0.3, 1.2, 0.02, 0.4, .paint(c.primaryDeep))
        return fixtureGroup(fixture, p)
    }
}

enum WindowPosterBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        let tint = fixture.id.hasSuffix("1") ? c.priceRailYellow : c.accentMint
        p.box("poster", 0, 0.9, 0.2, 0.8, 1.0, 0.01, .paint(tint))
        p.box("headline_block", 0, 1.45, 0.21, 0.6, 0.2, 0.01, .paint(c.primary))
        return fixtureGroup(fixture, p)
    }
}

enum AtmLockerBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        // 1.5 m x 0.5 m: cash machine on the left, parcel lockers on the right.
        p.box("atm_body", -0.35, 0, 0, 0.7, 1.9, 0.4, .paint(c.primaryDeep))
        p.box("atm_screen", -0.35, 1.3, 0.205, 0.4, 0.3, 0.01, .emissive(c.accentMint))
        p.box("keypad", -0.35, 1.0, 0.21, 0.25, 0.15, 0.02, .paint(c.asphalt))
        p.box("locker_body", 0.4, 0, 0, 0.7, 2.0, 0.4, .paint(c.primary))
        for i in 0..<4 {
            p.box("locker_door_\(i)", 0.4, 0.15 + 0.45 * Double(i), 0.205, 0.6, 0.4, 0.01, .paint(i % 2 == 0 ? c.primaryLight : c.accentMint))
        }
        return fixtureGroup(fixture, p)
    }
}

enum AFrameSignBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("leg_left", -0.17, 0, 0, 0.04, 0.9, 0.3, .paint(c.woodLight))
        p.box("leg_right", 0.17, 0, 0, 0.04, 0.9, 0.3, .paint(c.woodLight))
        p.box("board", 0, 0.3, 0.0, 0.4, 0.55, 0.04, .paint(c.charcoal))
        if detail.isFull { p.text("board_text", "Coffee", 0, 0.58, 0.03, 0.08, .paint(c.cream)) }
        return fixtureGroup(fixture, p)
    }
}

enum LitterBinBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.cyl("post", 0, 0, 0, 0.03, 0.4, .paint(c.charcoal))
        p.cyl("body", 0, 0.4, 0, 0.18, 0.5, .paint(c.mintDeep))
        p.cyl("lid", 0, 0.9, 0, 0.2, 0.06, .paint(c.charcoal))
        return fixtureGroup(fixture, p)
    }
}

enum BikeRackBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("base", 0, 0, 0, 1.4, 0.03, 0.12, .paint(c.asphalt))
        for i in 0..<3 {
            p.group("hoop_\(i)", -0.45 + 0.45 * Double(i), 0, 0) { g in
                g.box("hoop_\(i)_post_left", -0.1, 0.03, 0, 0.03, 0.8, 0.03, .paint(c.charcoal))
                g.box("hoop_\(i)_post_right", 0.1, 0.03, 0, 0.03, 0.8, 0.03, .paint(c.charcoal))
                g.box("hoop_\(i)_bar", 0, 0.83, 0, 0.23, 0.03, 0.03, .paint(c.charcoal))
            }
        }
        return fixtureGroup(fixture, p)
    }
}

enum StreetLampBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.cyl("post", 0, 0, 0, 0.06, 4.2, .paint(c.charcoal))
        p.box("arm", 0.2, 4.15, 0, 0.5, 0.05, 0.05, .paint(c.charcoal))
        p.box("head", 0.45, 4.05, 0, 0.3, 0.1, 0.18, .paint(c.charcoal))
        p.box("glow", 0.45, 4.0, 0, 0.24, 0.04, 0.14, .emissive(c.warmLamp))
        return fixtureGroup(fixture, p)
    }
}

enum TreeBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.cyl("trunk", 0, 0, 0, 0.12, 1.8, .paint(c.woodLight.scaled(by: 0.7)))
        p.box("crown", 0, 1.6, 0, 1.4, 1.5, 1.4, .paint(c.grassPastel), round: 0.4)
        p.box("crown_top", 0, 2.9, 0, 0.9, 0.9, 0.9, .paint(c.grassPastel.scaled(by: 1.05)), round: 0.3)
        return fixtureGroup(fixture, p)
    }
}

enum ParkedCarBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        // Colour varies per car, picked from the palette by id.
        let bodies = [c.primaryLight, c.accentMint, c.priceRailYellow, c.cream]
        let body = bodies[Int(ProductRows.seed(fixture.id) % UInt64(bodies.count))]
        var p = Parts()
        // 4.5 m x 2.0 m, long axis along x, front of the car towards +x.
        p.box("body", 0, 0.3, 0, 4.2, 0.7, 1.8, .paint(body), round: 0.15)
        p.box("cabin", -0.2, 1.0, 0, 2.2, 0.6, 1.6, .paint(body.scaled(by: 0.95)), round: 0.2)
        p.box("windows", -0.2, 1.05, 0, 2.25, 0.45, 1.62, .glass(c.skyPastel, opacity: 0.45))
        for (i, pos) in [(1.35, 0.9), (1.35, -0.9), (-1.35, 0.9), (-1.35, -0.9)].enumerated() {
            p.cylZ("wheel_\(i)", pos.0, 0, pos.1, 0.32, 0.22, .paint(c.charcoal))
        }
        p.box("headlight_left", 2.1, 0.65, 0.6, 0.06, 0.15, 0.3, .emissive(c.warmLamp))
        p.box("headlight_right", 2.1, 0.65, -0.6, 0.06, 0.15, 0.3, .emissive(c.warmLamp))
        p.box("tail_lights", -2.1, 0.65, 0, 0.06, 0.12, 1.4, .paint(c.primaryDeep))
        if detail.isFull {
            p.box("bumper_front", 2.12, 0.3, 0, 0.1, 0.12, 1.7, .paint(c.asphalt))
            p.box("bumper_rear", -2.12, 0.3, 0, 0.1, 0.12, 1.7, .paint(c.asphalt))
        }
        return fixtureGroup(fixture, p)
    }
}
