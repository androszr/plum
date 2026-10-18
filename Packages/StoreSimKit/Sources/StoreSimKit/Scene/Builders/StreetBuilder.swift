import Foundation

enum StreetBuilder {
    /// `carRects` are the parked cars' footprints; bay lines are drawn between them, never under them.
    static func build(lot: Lot, detail: DetailLevel, carRects: [GridRect] = []) -> SceneNode {
        let c = Brand.palette
        var p = Parts()
        let w = Double(lot.size.w) * cellSize
        let d = Double(lot.size.d) * cellSize
        p.box("ground", w / 2, -0.6, d / 2, w + 2, 0.5, d + 2, .paint(c.grassPastel))

        func slab(_ name: String, _ kind: Zone.Kind, top: Double, thickness: Double, _ col: BrandColor) {
            guard let z = lot.zones(of: kind).first else { return }
            let m = metres(z.rect)
            p.box(name, m.cx, top - thickness, m.cz, m.w, thickness, m.d, .paint(col))
        }
        slab("sidewalk", .sidewalk, top: 0, thickness: 0.3, c.sidewalk)
        slab("far_sidewalk", .farSidewalk, top: 0, thickness: 0.3, c.sidewalk)

        // Asphalt covers the parking lane and the street in one slab.
        let road = lot.zones(of: .parkingLane) + lot.zones(of: .street)
        if let first = road.first {
            var minZ = first.rect.minZ, maxZ = first.rect.maxZ
            for z in road { minZ = min(minZ, z.rect.minZ); maxZ = max(maxZ, z.rect.maxZ) }
            let m = metres(GridRect(x: 0, z: minZ, w: lot.size.w, d: maxZ - minZ))
            p.box("road", m.cx, -0.35, m.cz, m.w, 0.3, m.d, .paint(c.asphalt))
            let roadTop = -0.05
            // Kerb between sidewalk and parking lane.
            if let sw = lot.zones(of: .sidewalk).first {
                let edge = Double(sw.rect.maxZ) * cellSize
                p.box("kerb", w / 2, roadTop, edge - 0.04, w, 0.05, 0.08, .paint(c.cream))
            }
            // Dashed lane line down the middle of the street, parking bay ticks, zebra crossing.
            if let st = lot.zones(of: .street).first {
                let sm = metres(st.rect)
                let step = detail.isFull ? 2.0 : 4.0
                var i = 0
                var x = 1.0
                while x < w - 1 {
                    p.box("lane_marking_\(i)", x, roadTop, sm.cz, 1.0, 0.006, 0.12, .paint(c.cream))
                    x += step
                    i += 1
                }
                // The crossing runs kerb to kerb: over the parking lane as well as the street.
                let zebraX = w - 4.0
                let zebraMinZ = min(minZ, st.rect.minZ).asMetres, zebraMaxZ = max(maxZ, st.rect.maxZ).asMetres
                let n = Int((zebraMaxZ - zebraMinZ) / 0.6)
                for k in 0..<n {
                    p.box("zebra_\(k)", zebraX, roadTop, zebraMinZ + 0.3 + 0.6 * Double(k), 2.6, 0.006, 0.3, .paint(c.cream))
                }
                if let pk = lot.zones(of: .parkingLane).first {
                    let pm = metres(pk.rect)
                    let cars = carRects.sorted { $0.minX < $1.minX }
                    var xs: [Double] = []
                    if let first = cars.first { xs.append(Double(first.minX) * cellSize - 0.5) }
                    for (a, b) in zip(cars, cars.dropFirst()) {
                        xs.append((Double(a.maxX) + Double(b.minX)) / 2 * cellSize)
                    }
                    if let last = cars.last { xs.append(Double(last.maxX) * cellSize + 0.5) }
                    for (k, x) in xs.enumerated() {
                        p.box("parking_marking_\(k)", x, roadTop, pm.cz, 0.1, 0.006, pm.d, .paint(c.cream))
                    }
                }
            }
        }
        return SceneNode(name: "ground_group", children: p.nodes)
    }
}

extension Int {
    var asMetres: Double { Double(self) * cellSize }
}
