import Foundation

enum Lighting {
    static func nodes(for layout: StoreLayout) -> [SceneNode] {
        let c = Brand.palette
        let w = Double(layout.lot.size.w) * cellSize
        let d = Double(layout.lot.size.d) * cellSize
        var out: [SceneNode] = []
        out.append(SceneNode(name: "sun", shape: .light(.sun(intensity: 2800, direction: SIMD3(-0.5, -1.0, -0.6))),
                             position: SIMD3(w / 2, 20, d / 2)))
        out.append(SceneNode(name: "sky_fill", shape: .light(.fill(intensity: 900, direction: SIMD3(0.6, -0.5, 0.5))),
                             position: SIMD3(w / 2, 20, d / 2)))
        for f in layout.fixtures where f.kind == .pendantLamp {
            let m = f.occupiedRect.centreMetres
            out.append(SceneNode(name: "lamp_\(f.id)_light",
                                 shape: .light(.point(color: c.warmLamp, intensity: 9000, radius: 4.5)),
                                 position: SIMD3(m.x, 2.3, m.y)))
        }
        if let shop = layout.lot.zones(of: .storeInterior).first {
            let s = metres(shop.rect)
            out.append(SceneNode(name: "sign_glow",
                                 shape: .light(.spot(color: c.warmLamp, intensity: 6000, radius: 5, direction: SIMD3(0, -1, 0.3))),
                                 position: SIMD3(s.cx, 3.3, s.cz + s.d / 2 + 0.9)))
        }
        return out
    }
}
