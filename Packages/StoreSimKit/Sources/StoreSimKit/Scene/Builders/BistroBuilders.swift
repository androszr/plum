import Foundation

enum HotFoodCounterBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        // 2.5 m x 1.0 m footprint; the back wall is at z = -0.5.
        p.box("counter", 0, 0, 0.1, 2.5, 0.85, 0.7, .paint(c.primary))
        p.box("counter_top", 0, 0.85, 0.1, 2.54, 0.05, 0.74, .paint(c.woodLight))
        p.box("kick_strip", 0, 0, 0.46, 2.5, 0.08, 0.02, .paint(c.charcoal))

        let top = 0.9
        p.group("roller_grill", -0.85, top, 0.1) { g in
            g.box("grill_base", 0, 0, 0, 0.7, 0.12, 0.45, .paint(c.charcoal))
            for i in 0..<6 {
                g.cylX("roller_\(i)", 0, 0.12, -0.18 + 0.072 * Double(i), 0.025, 0.62, .solid(c.asphalt, roughness: 0.3))
            }
            for i in 0..<4 {
                g.cylX("sausage_\(i)", -0.15 + 0.1 * Double(i), 0.165, -0.18 + 0.072 * Double(i) + 0.036, 0.02, 0.2,
                       .paint(i % 2 == 0 ? c.woodLight : c.primaryLight))
            }
        }
        p.group("heated_case", -0.05, top, 0.1) { g in
            g.box("case_base", 0, 0, 0, 0.8, 0.1, 0.5, .paint(c.charcoal))
            g.box("case_glass", 0, 0.1, 0.22, 0.8, 0.4, 0.02, .glass(c.skyPastel, opacity: 0.25))
            g.box("case_roof", 0, 0.5, 0, 0.8, 0.03, 0.5, .paint(c.charcoal))
            g.box("case_glow", 0, 0.47, 0, 0.7, 0.01, 0.4, .emissive(c.warmLamp))
            for i in 0..<3 {
                g.box("pastry_\(i)", -0.25 + 0.2 * Double(i), 0.1, 0.0, 0.14, 0.07, 0.14, .paint(i == 1 ? c.woodLight : c.warmLamp), round: 0.03)
            }
            for i in 0..<2 {
                g.cylX("baguette_\(i)", 0.0, 0.18, -0.12 + 0.17 * Double(i), 0.04, 0.6, .paint(c.woodLight))
            }
        }
        p.group("bun_warmer", 0.6, top, 0.1) { g in
            g.box("warmer_body", 0, 0, 0, 0.4, 0.3, 0.4, .paint(c.mintDeep))
            g.box("warmer_lid", 0, 0.3, 0, 0.42, 0.04, 0.42, .paint(c.charcoal))
        }
        p.group("condiment_station", 1.03, top, 0.1) { g in
            g.box("station_tray", 0, 0, 0, 0.3, 0.04, 0.4, .paint(c.charcoal))
            if detail.isFull {
                for i in 0..<3 {
                    g.cyl("pump_\(i)", 0, 0.04, -0.12 + 0.12 * Double(i), 0.03, 0.2, .paint([c.priceRailYellow, c.primaryLight, c.accentMint][i]))
                }
            }
            g.box("napkin_box", 0.0, 0.04, 0.17, 0.12, 0.1, 0.08, .paint(c.cream))
        }
        // White tile wall behind the counter, with grout lines at full detail.
        p.box("tile_wall", 0, 0, -0.46, 2.5, 2.1, 0.04, .paint(c.tileWhite))
        if detail.isFull {
            for i in 0..<3 { p.box("grout_h_\(i)", 0, 0.7 + 0.5 * Double(i), -0.435, 2.5, 0.012, 0.01, .paint(c.sidewalk)) }
            for i in 0..<4 { p.box("grout_v_\(i)", -1.0 + 0.6 * Double(i), 0.0, -0.435, 0.012, 2.1, 0.01, .paint(c.sidewalk)) }
        }
        return fixtureGroup(fixture, p)
    }
}

enum CoffeeMachineBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("stand", 0, 0, 0, 0.46, 0.4, 0.4, .paint(c.woodLight))
        p.box("body", 0, 0.4, -0.03, 0.4, 0.3, 0.3, .paint(c.charcoal))
        p.box("screen", 0, 0.52, 0.13, 0.16, 0.1, 0.01, .emissive(c.accentMint))
        p.box("spout_left", -0.07, 0.4, 0.13, 0.03, 0.06, 0.03, .paint(c.asphalt))
        p.box("spout_right", 0.07, 0.4, 0.13, 0.03, 0.06, 0.03, .paint(c.asphalt))
        p.box("drip_tray", 0, 0.4, 0.17, 0.3, 0.02, 0.08, .paint(c.asphalt))
        for i in 0..<3 {
            p.cyl("cup_stack_\(i)", -0.15 + 0.15 * Double(i), 0.7, 0.0, 0.035, 0.1 - 0.015 * Double(i), .paint(c.cream))
        }
        return fixtureGroup(fixture, p)
    }
}

enum MenuScreenBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        // Footprint is 0.5 m deep: the bezel's back sits on the back edge (z = -0.25).
        let z = -0.25 + 0.03
        p.box("bezel", 0, 2.12, z, 2.4, 0.85, 0.06, .paint(c.charcoal))
        p.box("screen", 0, 2.16, z + 0.03, 2.3, 0.77, 0.01, .emissive(c.primaryDeep))
        let tiles = [c.priceRailYellow, c.accentMint, c.primaryLight, c.warmLamp, c.mintDeep, c.cream]
        for i in 0..<6 {
            let col = Double(i % 3), row = Double(i / 3)
            p.box("menu_tile_\(i)", -0.7 + 0.7 * col, 2.22 + 0.34 * (1 - row), z + 0.045, 0.55, 0.26, 0.01, .paint(tiles[i]))
            if detail.isFull || i % 2 == 0 {
                p.cyl("price_dot_\(i)", -0.7 + 0.7 * col + 0.2, 2.22 + 0.34 * (1 - row) + 0.1, z + 0.055, 0.025, 0.01, .paint(c.charcoal))
            }
        }
        return fixtureGroup(fixture, p)
    }
}

enum WindowLedgeBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.box("ledge_top", 0, 0.95, 0, 2.0, 0.05, 0.45, .paint(c.woodLight))
        p.box("support_left", -0.9, 0, 0, 0.05, 0.95, 0.4, .paint(c.charcoal))
        p.box("support_right", 0.9, 0, 0, 0.05, 0.95, 0.4, .paint(c.charcoal))
        return fixtureGroup(fixture, p)
    }
}

enum HighStoolBuilder: FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        p.cyl("base_disc", 0, 0, 0, 0.18, 0.02, .paint(c.charcoal))
        p.cyl("post", 0, 0.02, 0, 0.025, 0.65, .paint(c.asphalt))
        p.cyl("foot_ring", 0, 0.25, 0, 0.15, 0.02, .paint(c.asphalt))
        p.cyl("seat", 0, 0.67, 0, 0.17, 0.06, .paint(c.primary))
        return fixtureGroup(fixture, p)
    }
}
