import Foundation

/// Metres of a cell rectangle: centre (x, z) and size (w, d).
func metres(_ r: GridRect) -> (cx: Double, cz: Double, w: Double, d: Double) {
    let c = r.centreMetres
    return (c.x, c.y, Double(r.size.w) * cellSize, Double(r.size.d) * cellSize)
}

enum BuildingBuilder {
    static let wallHeight = 3.2

    static func build(lot: Lot, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        guard let shop = lot.zones(of: .storeInterior).first else { return SceneNode(name: "building") }
        let s = metres(shop.rect)
        let lotW = Double(lot.size.w) * cellSize
        let x0 = s.cx - s.w / 2, x1 = s.cx + s.w / 2
        let z0 = s.cz - s.d / 2, z1 = s.cz + s.d / 2
        let h = wallHeight

        // Shell.
        p.box("store_floor", s.cx, -0.1, s.cz, s.w, 0.1, s.d, .solid(c.cream.scaled(by: 0.97), roughness: 0.4))
        if detail.isFull {
            // Inner grid lines only, kept clear of the walls so no face is shared with them.
            for i in 1..<Int(s.w) {
                p.box("floor_line_x_\(i)", x0 + Double(i), 0.0, s.cz, 0.012, 0.004, s.d - 0.04, .paint(c.sidewalk))
            }
            for i in 1..<Int(s.d) {
                p.box("floor_line_z_\(i)", s.cx, 0.0, z0 + Double(i), s.w - 0.04, 0.003, 0.012, .paint(c.sidewalk))
            }
        }
        p.box("store_wall_back", s.cx, 0, z0 - 0.05, s.w + 0.2, h, 0.1, .paint(c.cream))
        p.box("store_wall_left", x0 - 0.05, 0, s.cz, 0.1, h, s.d, .paint(c.cream))
        p.box("store_wall_right", x1 + 0.05, 0, s.cz, 0.1, h, s.d, .paint(c.cream))
        p.box("tile_wall", s.cx, 0, z0 + 0.005, s.w, 1.4, 0.01, .paint(c.tileWhite))
        p.box("wood_accent", s.cx, 1.4, z0 + 0.02, s.w, 0.07, 0.04, .paint(c.woodLight))
        // The roof reaches 0.1 m further back (into the facade, out of sight) so its back edge does not
        // share a plane with the neighbouring shops' back faces, which now sit on the facade front.
        p.box("store_roof", s.cx, h, s.cz - 0.05, s.w + 0.4, 0.15, s.d + 0.3, .paint(c.primaryLight))

        // Storefront glazing, split around the entrance doorway, under a canopy with the lit sign.
        let doorX = (Double(lot.entrance.x) + 0.5) * cellSize
        let halfDoor = Double(FixtureKind.entranceDoor.footprint.w) * cellSize / 2
        let doorL = doorX - halfDoor, doorR = doorX + halfDoor
        let glass = SurfaceMaterial.glass(c.skyPastel, opacity: 0.18)
        var glazing = Parts()
        glazing.box("glazing_left", (x0 + doorL) / 2, 0.1, z1, doorL - x0, h - 0.1, 0.04, glass)
        glazing.box("glazing_right", (doorR + x1) / 2, 0.1, z1, x1 - doorR, h - 0.1, 0.04, glass)
        glazing.box("glazing_transom", doorX, 2.4, z1, doorR - doorL, h - 2.4, 0.04, glass)
        p.add(SceneNode(name: "storefront_glazing", children: glazing.nodes))
        let mullions = Int(s.w / 1.5)
        for i in 0...mullions {
            let x = x0 + s.w * Double(i) / Double(mullions)
            if x > doorL - 0.05 && x < doorR + 0.05 { continue } // keep the doorway clear
            p.box("mullion_\(i)", x, 0.0, z1 + 0.02, 0.05, h - 0.05, 0.05, .paint(c.charcoal))
        }
        p.box("mullion_door_left", doorL, 0.0, z1 + 0.02, 0.05, 2.4, 0.05, .paint(c.charcoal))
        p.box("mullion_door_right", doorR, 0.0, z1 + 0.02, 0.05, 2.4, 0.05, .paint(c.charcoal))
        p.box("canopy", s.cx, h + 0.1, z1 + 0.6, s.w + 0.6, 0.12, 1.3, .paint(c.primary))
        p.box("canopy_sign", s.cx, h + 0.22, z1 + 1.27, 6.0, 0.55, 0.06, .textured(.storefrontSign, fallback: c.primaryDeep))
        p.text("canopy_sign_text", Brand.name, s.cx, h + 0.5, z1 + 1.32, 0.42, .emissive(c.cream))

        // Block of flats above the shop's back and beside it.
        // Stops at the back wall's outer face (z = 0.9) so no face is shared with it.
        let facadeFront = z0 - 0.1
        p.box("facade", lotW / 2, 0, facadeFront / 2, lotW, 9.0, facadeFront, .paint(c.primaryLight.scaled(by: 0.9)))
        let cols = Int(lotW / 2.5)
        for r in 0..<3 {
            for col in 0..<cols {
                let x = (Double(col) + 0.5) * lotW / Double(cols)
                let lit = (r + col) % 3 == 0
                p.box("facade_window_\(r)_\(col)", x, 4.0 + 1.7 * Double(r), facadeFront + 0.01, 1.0, 1.1, 0.04,
                      lit ? .emissive(c.warmLamp) : .glass(c.skyPastel, opacity: 0.6))
                if detail.isFull && r > 0 && col % 2 == 0 {
                    p.box("balcony_\(r)_\(col)", x, 3.85 + 1.7 * Double(r), facadeFront + 0.25, 1.3, 0.06, 0.5, .paint(c.cream))
                }
            }
        }
        // Low neighbouring shops either side of the store. They run 0.1 m further back than the
        // shop so their back face lies on the facade's front face (z = facadeFront): face-to-face,
        // never coplanar, so there is no slot and no z-fighting.
        let neighbourDepth = s.d + 0.1
        let neighbourZ = s.cz - 0.05
        p.box("neighbour_left", (x0 - 0.1) / 2, 0, neighbourZ, x0 - 0.1, 3.6, neighbourDepth, .paint(c.accentMint.scaled(by: 0.9)))
        p.box("neighbour_right", (x1 + 0.1 + lotW) / 2, 0, neighbourZ, lotW - x1 - 0.1, 3.6, neighbourDepth, .paint(c.warmLamp.scaled(by: 0.9)))
        // Opaque shell parts catch clicks so fixtures hidden behind them cannot be picked through them.
        let opaque: Set<String> = ["store_wall_back", "store_wall_left", "store_wall_right", "facade",
                                   "neighbour_left", "neighbour_right", "canopy"]
        let nodes = p.nodes.map { node -> SceneNode in
            var n = node
            if opaque.contains(n.name) { n.blocksPicking = true }
            return n
        }
        return SceneNode(name: "building", children: nodes)
    }
}
