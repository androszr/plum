import Foundation

/// The code-built walker used until (or unless) a character file replaces it.
/// 1.75 m tall, 0.36 m wide (the width a walker is given on the pavement), front toward +Z, standing on the floor at its centre.
enum PedestrianBuilder {
    static func coat(for asset: AssetName) -> BrandColor {
        let c = Brand.palette
        switch asset {
        case .pedestrianA: return c.primary
        case .pedestrianB: return c.mintDeep
        default: return c.priceRailYellow
        }
    }

    static func build(id: String, asset: AssetName, detail: DetailLevel) -> SceneNode {
        let c = Brand.palette
        let coat = SurfaceMaterial.paint(coat(for: asset))
        let trousers = SurfaceMaterial.paint(c.charcoal)
        let skin = SurfaceMaterial.paint(c.woodLight)
        var p = Parts()
        p.box("leg_left", -0.07, 0, 0, 0.12, 0.8, 0.18, trousers, round: 0.04)
        p.box("leg_right", 0.07, 0, 0, 0.12, 0.8, 0.18, trousers, round: 0.04)
        p.box("torso", 0, 0.8, 0, 0.3, 0.6, 0.3, coat, round: 0.06)
        p.box("head", 0, 1.45, 0, 0.22, 0.3, 0.22, skin, round: 0.08)
        if detail.isFull {
            p.box("arm_left", -0.15, 0.85, 0, 0.06, 0.55, 0.12, coat, round: 0.04)
            p.box("arm_right", 0.15, 0.85, 0, 0.06, 0.55, 0.12, coat, round: 0.04)
            p.box("bag", 0, 0.85, -0.1, 0.26, 0.3, 0.1, .paint(c.cream), round: 0.03)
        }
        return SceneNode(name: id, size: SIMD3(2 * Traffic.walkerHalfWidth, Traffic.walkerHeight, 0.3), children: p.nodes)
    }
}
