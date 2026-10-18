import Foundation
import simd

/// The goods layer of a shelving fixture: shelves, price rails, packs, labels and promo tags, built from the
/// fixture's planogram. It is a sibling of the shell (the model or its stand-in), never part of it.
public enum Merchandiser {
    /// The fixture kinds whose goods are drawn by the app rather than baked into the model.
    public static let kinds: [FixtureKind] = [.gondolaShelf, .wallFridge]

    /// Where the goods of one fixture kind may stand, in metres.
    public struct Bay: Sendable {
        public var width: Double
        public var depth: Double
        public var plate: Double
        public var deck: Double
        public var ceiling: Double
        public var frontZ: Double
        public var doubleSided: Bool
        var shelfPrefix: String

        public var interior: ShelfInterior { ShelfInterior(deck: deck, ceiling: ceiling, plate: plate) }
        /// The front plane of the packs: level with the plate's front edge; the price rail stands in front of it.
        public var faceZ: Double { frontZ - 0.002 }
    }

    static let railDepth = 0.015
    static let railHeight = 0.04
    static let labelSize = SIMD2(0.06, 0.015)
    static let promoSize = SIMD2(0.048, 0.012)
    /// Bag shapes lean a little against their neighbours.
    static let leaningShapes: Set<String> = ["bag", "bagS", "puff", "bagSw"]

    public static func bay(for kind: FixtureKind) -> Bay? {
        switch kind {
        case .gondolaShelf:
            Bay(width: 0.88, depth: 0.42, plate: 0.02, deck: 0.08, ceiling: 1.71, frontZ: 0.44,
                doubleSided: true, shelfPrefix: "shelf")
        case .wallFridge:
            Bay(width: 0.84, depth: 0.50, plate: 0.025, deck: 0.10, ceiling: 2.04, frontZ: 0.40,
                doubleSided: false, shelfPrefix: "shelf")
        default:
            nil
        }
    }

    /// The `merchandise` node for a fixture. Without a planogram for its label it is today's generic rows.
    public static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int,
                             catalogue: PlanogramCatalogue = .shipped) -> SceneNode {
        guard let bay = bay(for: fixture.kind) else { return SceneNode(name: "merchandise") }
        if let plan = catalogue.planogram(forLabel: fixture.label),
           let levels = ShelfStacker.stack(planogram: plan, interior: bay.interior, catalogue: catalogue) {
            var nodes: [SceneNode] = []
            let faces: [Face] = bay.doubleSided ? [.front, .back] : [.front]
            for face in faces {
                nodes.append(contentsOf: planned(fixture, plan, levels, bay, face, detail, catalogue))
            }
            return SceneNode(name: "merchandise", children: nodes)
        }
        return SceneNode(name: "merchandise", children: generic(fixture, detail: detail, variant: variant))
    }

    // MARK: Planned shelves

    enum Face {
        case front, back
        var suffix: String { self == .front ? "" : "_back" }
        var sign: Double { self == .front ? 1 : -1 }
        var salt: UInt64 { self == .front ? 0 : 11400714819323198485 }
    }

    /// Everything is placed as if on the front face and then turned a half turn about the fixture's
    /// centre line for the back face (x and z negated, yaw pi), so the fronts read from the other aisle.
    private static func place(_ node: SceneNode, face: Face) -> SceneNode {
        guard face == .back else { return node }
        var n = node
        n.position = SIMD3(-node.position.x, node.position.y, -node.position.z)
        n.yaw = node.yaw + .pi
        return n
    }

    private static func planned(_ fixture: Fixture, _ plan: Planogram, _ levels: [ShelfLevel], _ bay: Bay,
                                _ face: Face, _ detail: DetailLevel, _ cat: PlanogramCatalogue) -> [SceneNode] {
        let c = Brand.palette
        var out: [SceneNode] = []
        func add(_ n: SceneNode) { out.append(place(n, face: face)) }
        let seed = ProductRows.seed(fixture.id) ^ face.salt
        let suffix = face.suffix
        let plateCentreZ = bay.frontZ - bay.depth / 2

        for (i, shelf) in plan.shelves.enumerated() {
            let level = levels[i]
            add(SceneNode(name: "\(bay.shelfPrefix)\(suffix)_\(i)", shape: .box,
                          size: SIMD3(bay.width, bay.plate, bay.depth),
                          position: SIMD3(0, level.plateY + bay.plate / 2, plateCentreZ),
                          material: .paint(c.tileWhite)))
            let railY = level.plateY - 0.015 + railHeight / 2
            add(SceneNode(name: "price_rail\(suffix)_\(i)", shape: .box,
                          size: SIMD3(bay.width, railHeight, railDepth),
                          position: SIMD3(0, railY, bay.frontZ + railDepth / 2),
                          material: .paint(c.priceRailYellow)))

            let packed = ShelfPacker.pack(shelf: shelf, width: bay.width * 100, catalogue: cat)
            for block in packed.blocks {
                guard let product = cat.product(block.productID), let shape = cat.shape(of: product),
                      let colours = cat.colours(of: product), let regions = cat.atlasRegion(for: product.id) else { continue }
                let w = shape.width / 100, h = shape.height / 100, d = shape.depth / 100
                let x0 = -bay.width / 2
                if detail.isFull {
                    let laneDepth = max(0.01, bay.depth - 0.002 - d - 0.005)
                    add(SceneNode(name: "lane\(suffix)_\(i)_\(block.index)", shape: .box,
                                  size: SIMD3((block.right - block.left) / 100, h * 0.92, laneDepth),
                                  position: SIMD3(x0 + (block.left + block.right) / 200, level.goodsY + h * 0.46,
                                                  bay.faceZ - d - laneDepth / 2),
                                  material: .paint(colours.base.scaled(by: 0.75))))
                }
                for f in packed.facings where f.block == block.index {
                    guard detail.isFull || f.index % 2 == 0 else { continue }
                    let globalIndex = packed.facings.firstIndex(of: f) ?? 0
                    let x = x0 + f.centre / 100
                    let roll = leaningShapes.contains(shape.id)
                        ? lean(seed: seed, shelf: i, facing: globalIndex) : 0
                    let name = "product\(suffix)_\(i)_\(globalIndex)"
                    let bodyH = shape.form == .bottle ? h * 0.72 : h
                    let bodyShape: NodeShape = shape.form == .box ? .box : .cylinder
                    let centreY = level.goodsY + bodyH / 2
                    // Alternate facings sit half a millimetre apart in depth so leaning neighbours never share a face.
                    let centreZ = bay.faceZ - d / 2 + (globalIndex % 2 == 0 ? 0 : 0.0005)
                    add(SceneNode(name: name, shape: bodyShape, size: SIMD3(w, bodyH, d),
                                  position: SIMD3(x, centreY, centreZ), roll: roll, material: .paint(colours.base)))
                    var art = regions.art
                    if shape.form == .bottle { art.height *= 0.72 }
                    add(SceneNode(name: "\(name)_front", shape: .quad, size: SIMD3(w, bodyH, 0),
                                  position: SIMD3(x, centreY, centreZ + d / 2 + 0.001), roll: roll,
                                  material: .atlas(.packFronts, region: art, fallback: colours.base)))
                    if shape.form == .bottle, detail.isFull {
                        add(SceneNode(name: "\(name)_neck", shape: .cylinder, size: SIMD3(w * 0.4, h * 0.28, w * 0.4),
                                      position: SIMD3(x, level.goodsY + bodyH + h * 0.14, centreZ), material: .paint(colours.base)))
                    }
                }
                let labelX = x0 + block.firstCentre / 100
                add(SceneNode(name: "label\(suffix)_\(i)_\(block.index)", shape: .quad,
                              size: SIMD3(labelSize.x, labelSize.y, 0),
                              position: SIMD3(labelX, railY, bay.frontZ + railDepth + 0.001),
                              material: .atlas(.packFronts, region: regions.label, fallback: c.cream)))
                if product.promo != nil {
                    // Hung just under the rail. The lowest shelf has the plinth right below it, so its tags
                    // sit on the rail beside the label instead.
                    let lowest = i == plan.shelves.count - 1
                    let tagX = lowest ? labelX + (labelSize.x + promoSize.x) / 2 + 0.004 : labelX
                    let tagY = lowest ? railY : railY - railHeight / 2 - 0.003 - promoSize.y / 2
                    add(SceneNode(name: "promo\(suffix)_\(i)_\(block.index)", shape: .quad,
                                  size: SIMD3(promoSize.x, promoSize.y, 0),
                                  position: SIMD3(tagX, tagY, bay.frontZ + railDepth + 0.002),
                                  material: .atlas(.packFronts, region: regions.promo, fallback: c.priceRailYellow)))
                }
            }
        }
        return out
    }

    /// Roll in degrees, converted to radians, within -2...+2. Seeded from the fixture id with the project's own hash.
    static func lean(seed: UInt64, shelf: Int, facing: Int) -> Double {
        var h = seed ^ (UInt64(shelf + 1) &* 0x9E37_79B9_7F4A_7C15) ^ (UInt64(facing + 1) &* 0xC2B2_AE3D_27D4_EB4F)
        h ^= h >> 33
        h = h &* 0xFF51_AFD7_ED55_8CCD
        h ^= h >> 33
        let degrees = Double(h % 4001) / 1000 - 2
        return degrees * .pi / 180
    }

    // MARK: Generic rows (a label with no planogram)

    private static func generic(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> [SceneNode] {
        let c = Brand.palette
        let seed = ProductRows.seed(fixture.id)
        var p = Parts()
        switch fixture.kind {
        case .gondolaShelf:
            let w = 0.9, d = 0.5
            let shelfDepth = d / 2 - 0.03
            let sides: [(sign: Double, suffix: String)] = [(1, ""), (-1, "_back")]
            for side in sides {
                let centreZ = side.sign * (d / 4 + 0.005)
                let railZ = side.sign * (d / 2 - 0.02)
                let productZ = side.sign * (d / 2 - 0.09)
                for i in 0..<4 {
                    let y = 0.12 + 0.35 * Double(i)
                    p.box("shelf\(side.suffix)_\(i)", 0, y, centreZ, w - 0.08, 0.03, shelfDepth, .paint(c.tileWhite))
                    p.box("price_rail\(side.suffix)_\(i)", 0, y - 0.01, railZ, w - 0.08, 0.04, 0.015, .paint(c.priceRailYellow))
                    let rowSeed = side.sign > 0 ? seed : seed ^ 11400714819323198485
                    for n in ProductRows.make(onShelf: i, y: y + 0.03, width: w - 0.14, z: productZ, detail: detail,
                                              seed: rowSeed, prefix: "product\(side.suffix)", variant: variant) {
                        p.add(n)
                    }
                }
            }
        case .wallFridge:
            let w = 0.95
            for i in 0..<4 {
                let y = 0.2 + 0.45 * Double(i)
                p.box("shelf_\(i)", 0, y, 0.15, w - 0.1, 0.025, 0.5, .solid(c.tileWhite, roughness: 0.3))
                for n in ProductRows.make(onShelf: i, y: y + 0.025, width: w - 0.16, z: 0.2, detail: detail,
                                          seed: seed, prefix: "bottle", mode: .bottles, variant: variant) {
                    p.add(n)
                }
            }
        default:
            break
        }
        return p.nodes
    }
}
