import Foundation

public struct Fixture: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var kind: FixtureKind
    /// Minimum corner of the occupied rectangle (after rotation).
    public var cell: GridCell
    public var rotation: QuarterTurn
    public var label: String?

    public init(id: String, kind: FixtureKind, cell: GridCell, rotation: QuarterTurn = .none, label: String? = nil) {
        self.id = id
        self.kind = kind
        self.cell = cell
        self.rotation = rotation
        self.label = label
    }

    private enum CodingKeys: String, CodingKey { case id, kind, cell, rotation, label }

    /// Every optional key has a default so older or newer data still reads.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(FixtureKind.self, forKey: .kind)
        cell = try c.decode(GridCell.self, forKey: .cell)
        rotation = try c.decodeIfPresent(QuarterTurn.self, forKey: .rotation) ?? .none
        label = try c.decodeIfPresent(String.self, forKey: .label)
    }

    public var occupiedRect: GridRect {
        let f = kind.footprint
        let size = rotation.isOdd ? GridSize(w: f.d, d: f.w) : f
        return GridRect(origin: cell, size: size)
    }
}
