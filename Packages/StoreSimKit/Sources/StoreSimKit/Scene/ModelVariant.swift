import Foundation

/// Derived per-instance variety. The index is the fixture's ordinal among fixtures of its
/// kind in `layout.fixtures`, wrapped at the kind's variant count. It is recomputed every
/// time the scene is built and never stored (no `Codable` type carries it).
public enum ModelVariant {
    public static func count(for kind: FixtureKind) -> Int {
        switch kind {
        case .windowPoster, .gondolaShelf, .wallShelf, .endCap, .wallFridge, .dairyChiller, .parkedCar: 3
        case .tree: 2
        default: 1
        }
    }

    public static func count(for name: AssetName) -> Int {
        switch name {
        case .windowPoster, .gondolaShelf, .wallShelf, .endCap, .wallFridge, .dairyChiller: 3
        case .parkedCarHatchback, .parkedCarSaloon, .parkedCarVan: 3
        case .treeLinden, .treeMaple: 2
        default: 1
        }
    }

    /// The model file a placed fixture of `kind` uses for `variant` (wrapped at the kind's count).
    public static func assetName(for kind: FixtureKind, variant: Int) -> AssetName {
        switch kind {
        case .parkedCar:
            [AssetName.parkedCarHatchback, .parkedCarSaloon, .parkedCarVan][wrap(variant, count: 3)]
        case .tree:
            [AssetName.treeLinden, .treeMaple][wrap(variant, count: 2)]
        default:
            kind.assetName
        }
    }

    /// `((v % count) + count) % count`, safe for negative and oversized input.
    public static func wrap(_ v: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((v % count) + count) % count
    }

    public static func index(of fixture: Fixture, in layout: StoreLayout) -> Int {
        let same = layout.fixtures.filter { $0.kind == fixture.kind }
        guard let ordinal = same.firstIndex(where: { $0.id == fixture.id }) else { return 0 }
        return wrap(ordinal, count: count(for: fixture.kind))
    }

    /// A moving car continues the count where the parked cars stop, so its model follows theirs;
    /// a walker has one look per character file and its variant is 0.
    public static func index(of mover: Mover, in layout: StoreLayout) -> Int {
        guard mover.kind == .car else { return 0 }
        let parked = layout.fixtures.filter { $0.kind == .parkedCar }.count
        return wrap(parked + mover.ordinal, count: count(for: .parkedCar))
    }

    /// In atlas order.
    public static let posterHeadlines: [String] = ["Hot coffee?", "Hungry?", "Open 6-23"]

    public static let posterTints: [BrandColor] = {
        let c = Brand.palette
        return [c.priceRailYellow, c.accentMint, c.cream]
    }()

    /// A seven-colour window of the nine product colours, starting at `(variant * 3) % 9`.
    public static func productColours(_ variant: Int) -> [BrandColor] {
        let all = ProductRows.colours()
        let start = wrap(variant * 3, count: all.count)
        return (0..<7).map { all[(start + $0) % all.count] }
    }

    public static func productColour(variant: Int, shelf: Int, facing: Int) -> BrandColor {
        let window = productColours(variant)
        return window[wrap(shelf * 3 + facing, count: window.count)]
    }

    public static func productPartStems(for name: AssetName) -> Set<String> {
        switch name {
        case .gondolaShelf, .wallShelf, .endCap: ["product", "product_back"]
        case .wallFridge: ["bottle"]
        case .dairyChiller: ["carton"]
        default: []
        }
    }

    /// The shape shown at a spot: `(shelf + facing + variant) mod 3` over packet, can, bottle, so each
    /// shelf starts one step along and the variant shifts the whole walk. A negative variant wraps.
    public static func visibleShape(variant: Int, shelf: Int, facing: Int) -> ProductShape {
        let all = ProductShape.allCases
        return all[wrap(shelf + facing + wrap(variant, count: all.count), count: all.count)]
    }

    /// `<stem>_<shelf>_<facing>[_<shape>]` with the stem in `stems`; anything else (`_neck`, uprights) is nil.
    /// `shape` is nil for a part with no shape suffix (fridge bottles, cartons, the stand-in).
    public static func parseProductPart(_ name: String, stems: Set<String>)
        -> (shelf: Int, facing: Int, shape: ProductShape?)? {
        var parts = name.split(separator: "_", omittingEmptySubsequences: false)
        var shape: ProductShape?
        if let last = parts.last, let found = ProductShape(rawValue: String(last)) {
            shape = found
            parts.removeLast()
        }
        guard parts.count >= 3,
              let shelf = Int(parts[parts.count - 2]),
              let facing = Int(parts[parts.count - 1]) else { return nil }
        let stem = parts.dropLast(2).joined(separator: "_")
        return stems.contains(stem) ? (shelf, facing, shape) : nil
    }
}

/// The three goods a shelf spot can show, in canonical order.
public enum ProductShape: String, CaseIterable, Sendable {
    case packet, can, bottle
}
