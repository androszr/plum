import Foundation
import simd

/// The goods of the till end of the shop, built from the same planogram machinery as the island shelves:
/// the two-bay spirits wall behind the tills, the stepped impulse rack on each counter, and the plain price
/// lines on the tobacco cabinet (a front, not a planogram: a Polish shop may not show the packs).
public enum TillZone {
    static let alcoholKey = "Vodka & whisky"
    static let impulseKey = "Till impulse"

    /// The six plain lines on the tobacco boards: digits and a comma only, no currency sign, no brand.
    static let priceLines = [
        "Cigarettes 17,99 - 24,99", "Cigarillos 12,99", "Rolling tobacco 29,99 - 42,99",
        "Papers 2,49", "Filters 3,49", "Lighters 4,99",
    ]

    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int, catalogue: PlanogramCatalogue) -> SceneNode {
        switch fixture.kind {
        case .alcoholWall:
            SceneNode(name: "merchandise", children: alcoholWall(fixture, detail: detail, bay: variant,
                                                                 bays: ModelVariant.count(for: FixtureKind.alcoholWall), catalogue: catalogue))
        case .checkoutCounter:
            SceneNode(name: "merchandise", children: impulseRack(fixture, detail: detail, catalogue: catalogue))
        case .cigaretteCabinet:
            SceneNode(name: "merchandise", children: tobaccoFront(detail: detail))
        default:
            SceneNode(name: "merchandise")
        }
    }

    // MARK: Row of goods on one shelf

    /// Where one shelf's goods stand, in the fixture's local space.
    struct Row {
        var shelf: Int
        /// Left edge of the usable width.
        var x0: Double
        /// Top of the plate, where the packs stand.
        var goodsY: Double
        /// The front face of the packs.
        var faceZ: Double
        var railY: Double
        var railDepth: Double
        var frontZ: Double
        /// Whether a promo tag hangs on the rail beside its label (the shelf above the plinth has no room under it).
        var promoBesideLabel: Bool
    }

    /// Packs, price labels and promo tags for one packed shelf. At reduced detail every second pack stays
    /// (counted along the block on a wall, along the whole shelf on the small rack).
    static func goods(_ packed: PackedShelf, row: Row, detail: DetailLevel, catalogue cat: PlanogramCatalogue,
                      thinAlongShelf: Bool) -> [SceneNode] {
        let c = Brand.palette
        var out: [SceneNode] = []
        let i = row.shelf
        for block in packed.blocks {
            guard let product = cat.product(block.productID), let shape = cat.shape(of: product),
                  let colours = cat.colours(of: product), let regions = cat.atlasRegion(for: product.id) else { continue }
            let w = shape.width / 100, h = shape.height / 100, d = shape.depth / 100
            var kept = 0
            for f in packed.facings where f.block == block.index {
                let globalIndex = packed.facings.firstIndex(of: f) ?? 0
                let counted = thinAlongShelf ? globalIndex : f.index
                guard detail.isFull || counted % 2 == 0 else { continue }
                kept += 1
                let x = row.x0 + f.centre / 100
                let name = "product_\(i)_\(globalIndex)"
                let bodyH: Double
                switch shape.form {
                case .bottle: bodyH = h * 0.72
                case .flask: bodyH = h * 0.78
                default: bodyH = h
                }
                let bodyShape: NodeShape = (shape.form == .box || shape.form == .flask) ? .box : .cylinder
                let centreY = row.goodsY + bodyH / 2
                // Alternate facings sit half a millimetre apart in depth so neighbours never share a face.
                let centreZ = row.faceZ - d / 2 + (globalIndex % 2 == 0 ? 0 : 0.0005)
                out.append(SceneNode(name: name, shape: bodyShape, size: SIMD3(w, bodyH, d),
                                     position: SIMD3(x, centreY, centreZ), material: .paint(colours.base)))
                var art = regions.art
                if shape.form == .bottle { art.height *= 0.72 }
                if shape.form == .flask { art.height *= 0.78 }
                out.append(SceneNode(name: "\(name)_front", shape: .quad, size: SIMD3(w, bodyH, 0),
                                     position: SIMD3(x, centreY, centreZ + d / 2 + 0.001),
                                     material: .atlas(.packFronts, region: art, fallback: colours.base)))
                if detail.isFull, shape.form == .bottle || shape.form == .flask {
                    let neckW = shape.form == .flask ? w * 0.3 : w * 0.4
                    let neckH = h - bodyH
                    out.append(SceneNode(name: "\(name)_neck", shape: .cylinder, size: SIMD3(neckW, neckH, neckW),
                                         position: SIMD3(x, row.goodsY + bodyH + neckH / 2, centreZ),
                                         material: .paint(colours.base)))
                }
            }
            guard kept > 0 else { continue }
            let labelX = row.x0 + block.firstCentre / 100
            out.append(SceneNode(name: "label_\(i)_\(block.index)", shape: .quad,
                                 size: SIMD3(Merchandiser.labelSize.x, Merchandiser.labelSize.y, 0),
                                 position: SIMD3(labelX, row.railY, row.frontZ + row.railDepth + 0.001),
                                 material: .atlas(.packFronts, region: regions.label, fallback: c.cream)))
            if product.promo != nil {
                let tagX = row.promoBesideLabel
                    ? labelX + (Merchandiser.labelSize.x + Merchandiser.promoSize.x) / 2 + 0.004 : labelX
                let tagY = row.promoBesideLabel
                    ? row.railY : row.railY - Merchandiser.railHeight / 2 - 0.003 - Merchandiser.promoSize.y / 2
                out.append(SceneNode(name: "promo_\(i)_\(block.index)", shape: .quad,
                                     size: SIMD3(Merchandiser.promoSize.x, Merchandiser.promoSize.y, 0),
                                     position: SIMD3(tagX, tagY, row.frontZ + row.railDepth + 0.002),
                                     material: .atlas(.packFronts, region: regions.promo, fallback: c.priceRailYellow)))
            }
        }
        return out
    }

    // MARK: The spirits wall

    /// One bay of the spirits wall, which is a 2.0 m unit holding a 1.9 m run of goods one bottle deep.
    /// The shelf heights come from the whole planogram, so they line up across both bays; each shelf's
    /// blocks are split into one contiguous run per bay.
    public static let alcoholBay = Merchandiser.Bay(width: 1.9, depth: 0.139, plate: 0.02, deck: 0.10, ceiling: 2.44,
                                             frontZ: -0.09, doubleSided: false, shelfPrefix: "shelf")

    static func alcoholWall(_ fixture: Fixture, detail: DetailLevel, bay index: Int, bays: Int,
                            catalogue cat: PlanogramCatalogue) -> [SceneNode] {
        let c = Brand.palette
        let bay = alcoholBay
        guard let plan = cat.planogram(forLabel: alcoholKey),
              let levels = ShelfStacker.stack(planogram: plan, interior: bay.interior, catalogue: cat) else { return [] }
        var out: [SceneNode] = []
        let plateCentreZ = bay.frontZ - bay.depth / 2
        for (i, shelf) in plan.shelves.enumerated() {
            let level = levels[i]
            out.append(SceneNode(name: "shelf_\(i)", shape: .box, size: SIMD3(bay.width, bay.plate, bay.depth),
                                 position: SIMD3(0, level.plateY + bay.plate / 2, plateCentreZ),
                                 material: .paint(c.tileWhite)))
            let railY = level.plateY - 0.015 + Merchandiser.railHeight / 2
            out.append(SceneNode(name: "price_rail_\(i)", shape: .box,
                                 size: SIMD3(bay.width, Merchandiser.railHeight, Merchandiser.railDepth),
                                 position: SIMD3(0, railY, bay.frontZ + Merchandiser.railDepth / 2),
                                 material: .paint(c.priceRailYellow)))
            let mine = PlanogramShelf(blocks: shelf.bayBlocks(bay: index, of: bays), band: shelf.band)
            let packed = ShelfPacker.pack(shelf: mine, width: bay.width * 100, catalogue: cat)
            let row = Row(shelf: i, x0: -bay.width / 2, goodsY: level.goodsY, faceZ: bay.faceZ, railY: railY,
                          railDepth: Merchandiser.railDepth, frontZ: bay.frontZ,
                          promoBesideLabel: i == plan.shelves.count - 1)
            out.append(contentsOf: goods(packed, row: row, detail: detail, catalogue: cat, thinAlongShelf: false))
        }
        return out
    }

    // MARK: The counter rack

    public static let rackWidth = 0.66
    public static let rackCentreX = 0.02
    public static let tierPlate = 0.01
    static let tierDepth = 0.085
    public static let rackRailDepth = 0.006
    public static let rackRailHeight = 0.015

    /// Tiers step 6 cm; the trays are 4.5 cm tall, so each tier's rail and labels stand clear above the trays
    /// of the tier in front.
    public static let tierStep = 0.06
    public static func tierPlateY(_ i: Int) -> Double { 1.01 + tierStep * Double(2 - i) }
    public static func tierFrontZ(_ i: Int) -> Double { 0.25 + 0.085 * Double(i) }

    /// A stepped three-tier rack on the counter top: back tier first in the planogram (bars), then mints, then
    /// gum at the front and lowest. Each tier is packed edge to edge with a price label under every block.
    static func impulseRack(_ fixture: Fixture, detail: DetailLevel, catalogue cat: PlanogramCatalogue) -> [SceneNode] {
        let c = Brand.palette
        guard let plan = cat.planogram(forLabel: impulseKey), plan.shelves.count == 3 else { return [] }
        var out: [SceneNode] = []
        out.append(SceneNode(name: "rack_base", shape: .box, size: SIMD3(0.70, 0.01, 0.26),
                             position: SIMD3(rackCentreX, 1.005, 0.29), material: .paint(c.charcoal)))
        for (i, shelf) in plan.shelves.enumerated() {
            let plateY = tierPlateY(i)
            let front = tierFrontZ(i)
            out.append(SceneNode(name: "tier_\(i)", shape: .box, size: SIMD3(rackWidth, tierPlate, tierDepth),
                                 position: SIMD3(rackCentreX, plateY + tierPlate / 2, front - tierDepth / 2),
                                 material: .paint(c.tileWhite)))
            if plateY - 1.01 > 0.001 {
                let rise = plateY - 1.01
                out.append(SceneNode(name: "riser_\(i)", shape: .box, size: SIMD3(rackWidth - 0.004, rise, tierDepth - 0.004),
                                     position: SIMD3(rackCentreX, 1.01 + rise / 2, front - tierDepth / 2),
                                     material: .paint(c.charcoal)))
            }
            let railY = plateY + rackRailHeight / 2 - 0.005
            if detail.isFull {
                out.append(SceneNode(name: "price_rail_\(i)", shape: .box,
                                     size: SIMD3(rackWidth, rackRailHeight, rackRailDepth),
                                     position: SIMD3(rackCentreX, railY, front + rackRailDepth / 2),
                                     material: .paint(c.priceRailYellow)))
            }
            let packed = ShelfPacker.pack(shelf: shelf, width: rackWidth * 100, catalogue: cat)
            // Without the rail (reduced detail) the labels sit straight on the tier's front edge.
            let row = Row(shelf: i, x0: rackCentreX - rackWidth / 2, goodsY: plateY + tierPlate, faceZ: front - 0.002,
                          railY: railY, railDepth: detail.isFull ? rackRailDepth : 0, frontZ: front, promoBesideLabel: true)
            out.append(contentsOf: goods(packed, row: row, detail: detail, catalogue: cat, thinAlongShelf: true))
        }
        return out
    }

    // MARK: The tobacco front

    /// Centres of the two price boards on the cabinet's doors, and the depth of their text.
    public static let boardCentreX = 0.36
    static let boardTextZ = 0.233
    static let boardY = 1.05...1.45
    static let boardWidth = 0.50

    static func tobaccoFront(detail: DetailLevel) -> [SceneNode] {
        let c = Brand.palette
        var out: [SceneNode] = []
        let rows = [1.36, 1.25, 1.14]
        for (i, line) in priceLines.enumerated() {
            guard detail.isFull || i % 3 == 0 else { continue }
            let x = i < 3 ? -boardCentreX : boardCentreX
            out.append(SceneNode(name: "price_line_\(i)", shape: .text(line), size: SIMD3(0, 0.026, 0),
                                 position: SIMD3(x, rows[i % 3], boardTextZ), material: .paint(c.charcoal)))
        }
        return out
    }
}
