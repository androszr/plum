import Foundation

public struct Zone: Hashable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case storeInterior, backRoom, sidewalk, street, parkingLane, farSidewalk, facadeStrip
    }
    public var id: String
    public var kind: Kind
    public var rect: GridRect
    public init(id: String, kind: Kind, rect: GridRect) {
        self.id = id
        self.kind = kind
        self.rect = rect
    }
}

public struct Lot: Hashable, Codable, Sendable {
    public var size: GridSize
    public var zones: [Zone]
    public var entrance: GridCell
    public init(size: GridSize, zones: [Zone], entrance: GridCell) {
        self.size = size
        self.zones = zones
        self.entrance = entrance
    }

    public var bounds: GridRect { GridRect(origin: GridCell(x: 0, z: 0), size: size) }

    public func zones(of kind: Zone.Kind) -> [Zone] { zones.filter { $0.kind == kind } }

    /// Centre of the lot in metres (x, z).
    public var centreMetres: SIMD2<Double> { bounds.centreMetres }
}
