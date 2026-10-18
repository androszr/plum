import Foundation

/// How a pack is drawn as a solid: a box, a cylinder, a cylinder with a neck, or (a flat spirits flask)
/// a box with a neck.
public enum PackForm: String, Sendable {
    case box, cylinder, bottle, flask
}

/// A pack shape at its real size, in centimetres.
public struct PackShape: Sendable, Equatable {
    public var id: String
    public var width: Double
    public var height: Double
    public var depth: Double
    public var form: PackForm
    /// Heavy shapes (1.5 L bottles, family packs) may only sit on the bottom shelf.
    public var heavy: Bool
}

/// The base and accent packaging colour names behind a flavour code.
public struct ColourCode: Sendable, Equatable {
    public var base: String
    public var accent: String
}

public struct Product: Sendable, Equatable {
    public var id: String
    public var brand: String
    public var code: String
    public var shape: String
    /// Printed on the shelf label, e.g. "7,99". A string: it is never arithmetic.
    public var price: String
    public var promo: String?
    public var tag: String?
    /// Position in the pack-fronts picture (row-major). Stable even when an earlier product is dropped.
    public var cell: Int
}

public struct PlanogramBlock: Sendable, Equatable {
    public var productID: String
    public var weight: Int
}

public struct PlanogramShelf: Sendable, Equatable {
    public var blocks: [PlanogramBlock]
    /// What the shelf holds ("vodka 0.5", "gum"), for tests and readers of the file. The merchandiser ignores it.
    public var band: String?

    public init(blocks: [PlanogramBlock], band: String? = nil) {
        self.blocks = blocks
        self.band = band
    }
}

/// The shelves of one category, listed top to bottom.
public struct Planogram: Sendable, Equatable {
    public var label: String
    public var shelves: [PlanogramShelf]
}

public struct AtlasLayout: Sendable, Equatable {
    public var columns: Int
    public var rows: Int
    public var cellWidth: Int
    public var cellHeight: Int
    public var artHeight: Int
    public var labelHeight: Int
    public var cellCount: Int { columns * rows }
    /// Width and height of the whole picture in pixels.
    public var pixels: (Int, Int) { (columns * cellWidth, rows * cellHeight) }
}

/// The regions of one product's cell in the pack-fronts picture.
public struct ProductRegions: Sendable, Equatable {
    public var art: AtlasRegion
    public var label: AtlasRegion
    public var promo: AtlasRegion
}

/// Products and planograms, read from `planograms.json`. The generator reads the same file.
public struct PlanogramCatalogue: Sendable {
    public var version: Int
    public var atlas: AtlasLayout
    public var shapes: [String: PackShape]
    public var colourCodes: [String: ColourCode]
    public var products: [Product]
    public var planograms: [String: Planogram]

    private var productIndex: [String: Int]

    public static let gap = 0.3

    public static let empty = PlanogramCatalogue(
        version: 1,
        atlas: AtlasLayout(columns: 16, rows: 8, cellWidth: 128, cellHeight: 256, artHeight: 192, labelHeight: 32),
        shapes: [:], colourCodes: [:], products: [], planograms: [:], productIndex: [:])

    /// The catalogue shipped in the package, loaded once. Empty if the resource is missing.
    public static let shipped: PlanogramCatalogue = {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "planograms", withExtension: "json")
            ?? bundle.url(forResource: "planograms", withExtension: "json", subdirectory: "Resources")
        guard let url, let data = try? Data(contentsOf: url),
              let catalogue = try? PlanogramCatalogue.decode(from: data) else { return .empty }
        return catalogue
    }()

    public func planogram(forLabel label: String?) -> Planogram? {
        guard let label else { return nil }
        return planograms[label]
    }

    public func product(_ id: String) -> Product? {
        productIndex[id].map { products[$0] }
    }

    public func shape(of product: Product) -> PackShape? { shapes[product.shape] }

    public func colours(of product: Product) -> (base: BrandColor, accent: BrandColor)? {
        guard let code = colourCodes[product.code] else { return nil }
        let table = Brand.packaging.byName
        guard let base = table[code.base], let accent = table[code.accent] else { return nil }
        return (base, accent)
    }

    // MARK: Atlas

    /// The art rectangle in whole pixels: the pack's aspect scaled by `min(cellWidth / w, artHeight / h)`,
    /// floored, centred in the art area. The generator draws the same rectangle.
    public func artPixels(for shape: PackShape) -> (x: Int, y: Int, width: Int, height: Int) {
        let scale = min(Double(atlas.cellWidth) / shape.width, Double(atlas.artHeight) / shape.height)
        let w = Int((shape.width * scale).rounded(.down))
        let h = Int((shape.height * scale).rounded(.down))
        return ((atlas.cellWidth - w) / 2, (atlas.artHeight - h) / 2, w, h)
    }

    /// The art, label and promo regions of a product's cell. Nil if the product or its shape is unknown.
    public func atlasRegion(for productID: String) -> ProductRegions? {
        guard let product = product(productID), let shape = shape(of: product) else { return nil }
        let col = product.cell % atlas.columns
        let row = product.cell / atlas.columns
        let totalW = Double(atlas.columns * atlas.cellWidth)
        let totalH = Double(atlas.rows * atlas.cellHeight)
        let originX = col * atlas.cellWidth
        let originY = row * atlas.cellHeight
        func region(x: Int, y: Int, w: Int, h: Int) -> AtlasRegion {
            // Row 0 of a picture is its top; RealityKit measures v from the bottom, so flip once here.
            AtlasRegion(u: Double(originX + x) / totalW,
                        v: 1 - Double(originY + y + h) / totalH,
                        width: Double(w) / totalW,
                        height: Double(h) / totalH)
        }
        let art = artPixels(for: shape)
        return ProductRegions(
            art: region(x: art.x, y: art.y, w: art.width, h: art.height),
            label: region(x: 0, y: atlas.artHeight, w: atlas.cellWidth, h: atlas.labelHeight),
            promo: region(x: 0, y: atlas.artHeight + atlas.labelHeight, w: atlas.cellWidth, h: atlas.labelHeight))
    }
}

// MARK: Lenient decoding

extension PlanogramCatalogue {
    private struct Raw: Decodable {
        var version: Int?
        var atlas: RawAtlas?
        var shapes: [String: RawShape]?
        var colourCodes: [String: [String]]?
        var products: [RawProduct]?
        var planograms: [String: RawPlanogram]?
    }
    private struct RawAtlas: Decodable {
        var columns: Int?, rows: Int?, cellWidth: Int?, cellHeight: Int?, artHeight: Int?, labelHeight: Int?
    }
    private struct RawShape: Decodable {
        var w: Double?, h: Double?, d: Double?
        var form: String?
        var heavy: Bool?
    }
    private struct RawProduct: Decodable {
        var id: String?, brand: String?, code: String?, shape: String?, price: String?
        var promo: String?, tag: String?
    }
    private struct RawBlock: Decodable {
        var product: String?
        var weight: Int?
    }
    /// A shelf is either a bare list of blocks (the older shape) or an object with a `band` and its `blocks`.
    private struct RawShelf: Decodable {
        var band: String?
        var blocks: [RawBlock]

        private enum Keys: String, CodingKey { case band, blocks }

        init(from decoder: Decoder) throws {
            if let list = try? decoder.singleValueContainer().decode([RawBlock].self) {
                band = nil
                blocks = list
                return
            }
            let c = try decoder.container(keyedBy: Keys.self)
            band = try c.decodeIfPresent(String.self, forKey: .band)
            blocks = try c.decodeIfPresent([RawBlock].self, forKey: .blocks) ?? []
        }
    }
    private struct RawPlanogram: Decodable {
        var shelves: [RawShelf]?
    }

    /// Decodes leniently: a missing key takes its default, a product whose shape or colour is unknown is
    /// dropped together with every block that names it, and unknown keys are ignored.
    public static func decode(from data: Data) throws -> PlanogramCatalogue {
        let raw = try JSONDecoder().decode(Raw.self, from: data)
        let fallback = PlanogramCatalogue.empty.atlas
        let a = raw.atlas
        let atlas = AtlasLayout(
            columns: a?.columns ?? fallback.columns, rows: a?.rows ?? fallback.rows,
            cellWidth: a?.cellWidth ?? fallback.cellWidth, cellHeight: a?.cellHeight ?? fallback.cellHeight,
            artHeight: a?.artHeight ?? fallback.artHeight, labelHeight: a?.labelHeight ?? fallback.labelHeight)

        var shapes: [String: PackShape] = [:]
        for (id, s) in raw.shapes ?? [:] {
            guard let w = s.w, let h = s.h, let d = s.d, w > 0, h > 0, d > 0,
                  let form = PackForm(rawValue: s.form ?? "box") else { continue }
            shapes[id] = PackShape(id: id, width: w, height: h, depth: d, form: form, heavy: s.heavy ?? false)
        }
        var codes: [String: ColourCode] = [:]
        for (id, names) in raw.colourCodes ?? [:] {
            guard names.count >= 2 else { continue }
            codes[id] = ColourCode(base: names[0], accent: names[1])
        }
        let table = Brand.packaging.byName
        var products: [Product] = []
        for (cell, p) in (raw.products ?? []).enumerated() {
            guard let id = p.id, let shape = p.shape, shapes[shape] != nil,
                  let code = p.code, let colour = codes[code],
                  table[colour.base] != nil, table[colour.accent] != nil else { continue }
            products.append(Product(id: id, brand: p.brand ?? "", code: code, shape: shape,
                                    price: p.price ?? "", promo: p.promo, tag: p.tag, cell: cell))
        }
        let known = Set(products.map(\.id))
        var planograms: [String: Planogram] = [:]
        for (label, p) in raw.planograms ?? [:] {
            let shelves = (p.shelves ?? []).map { shelf in
                PlanogramShelf(blocks: shelf.blocks.compactMap { b -> PlanogramBlock? in
                    guard let id = b.product, known.contains(id) else { return nil }
                    return PlanogramBlock(productID: id, weight: b.weight ?? 1)
                }, band: shelf.band)
            }
            planograms[label] = Planogram(label: label, shelves: shelves)
        }
        var index: [String: Int] = [:]
        for (i, p) in products.enumerated() where index[p.id] == nil { index[p.id] = i }
        return PlanogramCatalogue(version: raw.version ?? 1, atlas: atlas, shapes: shapes, colourCodes: codes,
                                  products: products, planograms: planograms, productIndex: index)
    }
}
