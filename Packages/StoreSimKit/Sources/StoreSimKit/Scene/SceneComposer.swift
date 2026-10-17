import Foundation

public struct SceneComposer {
    public static func compose(layout: StoreLayout, detail: DetailLevel, catalogue: AssetCatalogue) -> SceneNode {
        var fixtureNodes: [SceneNode] = []
        for f in layout.fixtures {
            let built = FixtureBuilders.builder(for: f.kind).build(f, detail: detail)
            let m = f.occupiedRect.centreMetres
            let ext = f.kind.verticalExtent
            let fp = footprintMetres(f.kind)
            var node: SceneNode
            switch catalogue.resolve(f.kind.assetName) {
            case .model:
                var fallback = built
                fallback.name = "fallback"
                node = SceneNode(name: f.id, shape: .asset(f.kind.assetName), children: [fallback])
            case .procedural:
                node = built
                node.name = f.id
            }
            node.displayName = f.label ?? f.kind.displayName
            node.selectable = true
            node.position = SIMD3(m.x, 0, m.y)
            node.yaw = f.rotation.yaw
            node.bounds = NodeBounds(center: SIMD3(0, (ext.lowerBound + ext.upperBound) / 2, 0),
                                     size: SIMD3(fp.w, ext.upperBound - ext.lowerBound, fp.d))
            fixtureNodes.append(node)
        }
        let centre = layout.lot.centreMetres
        let root = SceneNode(name: "root", children: [
            StreetBuilder.build(lot: layout.lot, detail: detail,
                                carRects: layout.fixtures.filter { $0.kind == .parkedCar }.map(\.occupiedRect)).renamed("ground"),
            BuildingBuilder.build(lot: layout.lot, detail: detail),
            SceneNode(name: "fixtures", children: fixtureNodes),
            SceneNode(name: "lighting", children: Lighting.nodes(for: layout)),
            SceneNode(name: "camera_target", position: SIMD3(centre.x, 0, centre.y)),
        ])
        return root
    }
}

extension SceneNode {
    func renamed(_ n: String) -> SceneNode {
        var copy = self
        copy.name = n
        return copy
    }
}
