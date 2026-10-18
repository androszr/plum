import Foundation

/// Builds one node per passing car or walker. Traffic is scenery: never selectable and a child of
/// `traffic`, never of a fixture. It does take clicks, through a pick box the size of the mover, so a
/// click on a car or walker clears the selection instead of passing through to a fixture behind it.
enum TrafficComposer {
    static func nodes(layout: StoreLayout, detail: DetailLevel, catalogue: AssetCatalogue) -> [SceneNode] {
        Traffic.movers(for: layout, detail: detail).map { mover in
            let variant = ModelVariant.index(of: mover, in: layout)
            var standIn: SceneNode
            switch mover.kind {
            case .car:
                let car = Fixture(id: mover.id, kind: .parkedCar, cell: GridCell(x: 0, z: 0))
                standIn = ParkedCarBuilder.build(car, detail: detail, variant: variant)
            case .pedestrian:
                standIn = PedestrianBuilder.build(id: mover.id, asset: mover.asset, detail: detail)
            }
            var node: SceneNode
            switch catalogue.resolve(mover.asset) {
            case .model:
                standIn.name = "fallback"
                node = SceneNode(name: mover.id, shape: .asset(mover.asset), children: [standIn])
            case .procedural, .texture:
                node = standIn
                node.name = mover.id
            }
            let start = Traffic.pose(of: mover, at: 0)
            node.selectable = false
            node.blocksPicking = true
            node.bounds = pickBox(for: mover.kind)
            node.variant = variant
            node.mover = mover
            node.position = start.position
            node.yaw = start.yaw
            return node
        }
    }

    /// The mover's own frame, standing on the ground: a car's long axis is x, a walker faces z.
    static func pickBox(for kind: MoverKind) -> NodeBounds {
        switch kind {
        case .car:
            NodeBounds(center: SIMD3(0, 0.75, 0), size: SIMD3(Traffic.carLength, 1.5, 2.0))
        case .pedestrian:
            NodeBounds(center: SIMD3(0, Traffic.walkerHeight / 2, 0),
                       size: SIMD3(2 * Traffic.walkerHalfWidth, Traffic.walkerHeight, 0.3))
        }
    }
}
