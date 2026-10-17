import Foundation

/// One grid cell is half a metre.
public let cellSize: Double = 0.5

public struct GridCell: Hashable, Codable, Sendable {
    public var x: Int
    public var z: Int
    public init(x: Int, z: Int) {
        self.x = x
        self.z = z
    }
}

public struct GridSize: Hashable, Codable, Sendable {
    public var w: Int
    public var d: Int
    public init(w: Int, d: Int) {
        self.w = w
        self.d = d
    }
}

public struct GridRect: Hashable, Codable, Sendable {
    public var origin: GridCell
    public var size: GridSize
    public init(origin: GridCell, size: GridSize) {
        self.origin = origin
        self.size = size
    }
    public init(x: Int, z: Int, w: Int, d: Int) {
        self.init(origin: GridCell(x: x, z: z), size: GridSize(w: w, d: d))
    }

    public var minX: Int { origin.x }
    public var minZ: Int { origin.z }
    /// Exclusive.
    public var maxX: Int { origin.x + size.w }
    /// Exclusive.
    public var maxZ: Int { origin.z + size.d }

    public func contains(_ cell: GridCell) -> Bool {
        cell.x >= minX && cell.x < maxX && cell.z >= minZ && cell.z < maxZ
    }

    public func contains(_ other: GridRect) -> Bool {
        other.minX >= minX && other.maxX <= maxX && other.minZ >= minZ && other.maxZ <= maxZ
    }

    public func intersects(_ other: GridRect) -> Bool {
        minX < other.maxX && other.minX < maxX && minZ < other.maxZ && other.minZ < maxZ
    }

    public var cells: [GridCell] {
        var out: [GridCell] = []
        for x in minX..<maxX { for z in minZ..<maxZ { out.append(GridCell(x: x, z: z)) } }
        return out
    }

    /// Centre in metres, on the ground plane (x, z).
    public var centreMetres: SIMD2<Double> {
        SIMD2(Double(minX + maxX) / 2 * cellSize, Double(minZ + maxZ) / 2 * cellSize)
    }
}

/// A quarter turn about the vertical axis: 0, 1, 2 or 3 (always normalised).
public struct QuarterTurn: Hashable, Codable, Sendable {
    public let rawValue: Int
    public init(_ value: Int) { rawValue = ((value % 4) + 4) % 4 }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.init(try c.decode(Int.self))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
    public static let none = QuarterTurn(0)
    public var isOdd: Bool { rawValue % 2 == 1 }
    /// Yaw in radians; a quarter turn of 1 turns the fixture's front (+Z) to +X.
    public var yaw: Double { Double(rawValue) * .pi / 2 }
}
