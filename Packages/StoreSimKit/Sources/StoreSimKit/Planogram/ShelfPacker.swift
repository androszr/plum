import Foundation

/// One pack on a shelf. Positions are centimetres from the left edge of the usable shelf width.
public struct PackedFacing: Sendable, Equatable {
    public var block: Int
    /// Index within its block, from the left.
    public var index: Int
    public var left: Double
    public var width: Double
    public var centre: Double { left + width / 2 }
}

public struct PackedBlock: Sendable, Equatable {
    public var index: Int
    public var productID: String
    public var facings: Int
    public var left: Double
    public var right: Double
    /// Centre of the block's first (leftmost) facing.
    public var firstCentre: Double
}

public struct PackedShelf: Sendable, Equatable {
    public var width: Double
    public var blocks: [PackedBlock]
    public var facings: [PackedFacing]
    /// Width taken by the packs and the gaps between them.
    public var used: Double
    /// Tallest pack plus the finger gap.
    public var clearHeight: Double
    public var tallest: Double
    /// Narrowest pack on the shelf; nothing narrower than this was left over.
    public var narrowest: Double

    public var fill: Double { width > 0 ? used / width : 0 }
    public var slack: Double { width - used }
}

/// Facing allocation for one shelf. Mirrors the concept page's `packShelf`.
public enum ShelfPacker {
    /// Centimetres of finger room above the tallest pack.
    public static let fingerGap = 2.0
    static let rounds = 60

    /// Starts every block at its weight, trims from the biggest block until the row fits, then gives the
    /// leftover width to the block with the most facings first, until no pack fits. The slack is split
    /// between both ends. `width` is in centimetres.
    public static func pack(shelf: PlanogramShelf, width: Double,
                            catalogue: PlanogramCatalogue = .shipped) -> PackedShelf {
        let gap = PlanogramCatalogue.gap
        let entries: [(id: String, w: Double, h: Double)] = shelf.blocks.compactMap { block in
            guard let product = catalogue.product(block.productID), let shape = catalogue.shape(of: product) else { return nil }
            return (block.productID, shape.width, shape.height)
        }
        let weights = shelf.blocks.filter { catalogue.product($0.productID) != nil }.map { max(1, $0.weight) }
        guard !entries.isEmpty, entries.count == weights.count else {
            return PackedShelf(width: width, blocks: [], facings: [], used: 0, clearHeight: 0, tallest: 0, narrowest: 0)
        }
        var counts = weights
        func used() -> Double {
            var total = 0.0, n = 0
            for (i, e) in entries.enumerated() { total += Double(counts[i]) * e.w; n += counts[i] }
            return total + Double(max(0, n - 1)) * gap
        }
        // Trim from the block with the most facings. On a tie the lighter block gives one up first, then the
        // later block, so the hero block (the heaviest, earliest) keeps its facings.
        while used() > width, let biggest = counts.indices.max(by: { a, b in
            if counts[a] != counts[b] { return counts[a] < counts[b] }
            if weights[a] != weights[b] { return weights[a] > weights[b] }
            return a < b
        }), counts[biggest] > 1 {
            counts[biggest] -= 1
        }
        for _ in 0..<rounds {
            let room = width - used()
            let order = counts.indices.sorted { counts[$0] != counts[$1] ? counts[$0] > counts[$1] : $0 < $1 }
            guard let pick = order.first(where: { entries[$0].w + gap <= room + 1e-9 }) else { break }
            counts[pick] += 1
        }

        var cursor = max(0, (width - used()) / 2)
        var blocks: [PackedBlock] = []
        var facings: [PackedFacing] = []
        for (i, e) in entries.enumerated() {
            let start = cursor
            for f in 0..<counts[i] {
                facings.append(PackedFacing(block: i, index: f, left: cursor, width: e.w))
                cursor += e.w + gap
            }
            let right = cursor - gap
            blocks.append(PackedBlock(index: i, productID: e.id, facings: counts[i], left: start, right: right,
                                      firstCentre: start + e.w / 2))
        }
        let tallest = entries.map(\.h).max() ?? 0
        return PackedShelf(width: width, blocks: blocks, facings: facings, used: used(),
                           clearHeight: tallest + fingerGap, tallest: tallest,
                           narrowest: entries.map(\.w).min() ?? 0)
    }
}

extension PlanogramShelf {
    /// The contiguous run of blocks bay `bay` of `bays` shows: the blocks are split by count, and the first
    /// runs take the remainder, so no block is cut by the gap between two units.
    public func bayBlocks(bay: Int, of bays: Int) -> [PlanogramBlock] {
        guard bays > 0, bay >= 0, bay < bays else { return [] }
        let base = blocks.count / bays, extra = blocks.count % bays
        let start = bay * base + min(bay, extra)
        let length = base + (bay < extra ? 1 : 0)
        return Array(blocks[start..<(start + length)])
    }
}

/// The vertical room a planogram has to fit in, in metres.
public struct ShelfInterior: Sendable, Equatable {
    public var deck: Double
    public var ceiling: Double
    public var plate: Double
    public init(deck: Double, ceiling: Double, plate: Double) {
        self.deck = deck
        self.ceiling = ceiling
        self.plate = plate
    }
}

/// One shelf plate and the room above it.
public struct ShelfLevel: Sendable, Equatable {
    /// Index in the planogram (0 is the top shelf).
    public var index: Int
    /// Underside of the plate.
    public var plateY: Double
    /// Top of the plate, where the packs stand.
    public var goodsY: Double
    /// Free height above the plate: tallest pack, finger gap and a share of the leftover height.
    public var clearance: Double
}

public enum ShelfStacker {
    /// Shelves stack from the deck upward, the planogram's last shelf lowest. The leftover interior height is
    /// shared equally as extra clearance so the top shelf stays near the header. Nil when the minimal stack
    /// does not fit or a product is unknown.
    public static func stack(planogram: Planogram, interior: ShelfInterior,
                             catalogue: PlanogramCatalogue = .shipped) -> [ShelfLevel]? {
        guard !planogram.shelves.isEmpty else { return [] }
        var minimal: [Double] = []
        for shelf in planogram.shelves {
            var tallest = 0.0
            for block in shelf.blocks {
                guard let product = catalogue.product(block.productID), let shape = catalogue.shape(of: product) else { return nil }
                tallest = max(tallest, shape.height)
            }
            guard tallest > 0 else { return nil }
            minimal.append((tallest + ShelfPacker.fingerGap) / 100)
        }
        let n = Double(minimal.count)
        let needed = minimal.reduce(0, +) + n * interior.plate
        let available = interior.ceiling - interior.deck
        guard needed <= available + 1e-9 else { return nil }
        let extra = (available - needed) / n
        var levels = [ShelfLevel?](repeating: nil, count: minimal.count)
        var y = interior.deck
        for i in stride(from: minimal.count - 1, through: 0, by: -1) {
            let clearance = minimal[i] + extra
            levels[i] = ShelfLevel(index: i, plateY: y, goodsY: y + interior.plate, clearance: clearance)
            y += interior.plate + clearance
        }
        return levels.compactMap { $0 }
    }
}
