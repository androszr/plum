import Foundation

/// Builds one node per passing car or walker. Traffic is scenery: never selectable, no bounds,
/// and a child of `traffic`, never of a fixture, so a click on it reaches the ground.
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
            node.bounds = nil
            node.variant = variant
            node.mover = mover
            node.position = start.position
            node.yaw = start.yaw
            return node
        }
    }
}
