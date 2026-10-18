import Foundation
import Testing
import simd
@testable import StoreSimKit

@Suite struct MerchandiseTests {
    static let catalogue = PlanogramCatalogue.shipped
    static let layout = StoreLayout.plumCorner

    static func fixture(_ id: String) -> Fixture { layout.fixtures.first { $0.id == id }! }

    static func goods(_ id: String, detail: DetailLevel = .full) -> SceneNode {
        let f = fixture(id)
        return Merchandiser.build(f, detail: detail, variant: ModelVariant.index(of: f, in: layout))
    }

    /// The shelving kinds whose goods follow the shelf bays; the till zone has its own `TillZoneTests`.
    static var stocked: [Fixture] { layout.fixtures.filter { [.gondolaShelf, .wallFridge].contains($0.kind) } }

    /// Product bodies: `product_<shelf>_<facing>` with no suffix, on either face.
    static func bodies(_ node: SceneNode) -> [SceneNode] {
        node.children.filter {
            $0.name.hasPrefix("product") && !$0.name.hasSuffix("_front") && !$0.name.hasSuffix("_neck")
        }
    }

    static func modelURL(_ name: String) -> URL {
        URL(fileURLWithPath: "/nonexistent").appendingPathComponent(name).appendingPathExtension("usdz")
    }

    @Test func merchandiseIsASiblingOfFallback() {
        let cat = AssetCatalogue(modelURLs: [Self.modelURL("gondola_shelf"), Self.modelURL("wall_fridge")])
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: cat)
        for f in Self.stocked {
            let node = root.node(named: f.id)!
            guard case .asset = node.shape else { Issue.record("\(f.id) is not an asset node"); continue }
            #expect(node.children.map(\.name) == ["fallback", "merchandise"], "\(f.id)")
            // The goods are not inside the stand-in, or they would be drawn twice when it is used.
            #expect(node.children[0].node(named: "merchandise") == nil)
        }
        let plain = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        for f in Self.stocked {
            let node = plain.node(named: f.id)!
            #expect(node.children.last?.name == "merchandise", "\(f.id) without a model")
            #expect(node.children.filter { $0.name == "merchandise" }.count == 1)
        }
        // Kinds the merchandiser does not stock gain no layer.
        #expect(plain.node(named: "wall_shelf_1")?.node(named: "merchandise") == nil)
    }

    @Test func plannedShelvesVaryByCategory() {
        func plates(_ id: String) -> [Double] {
            Self.goods(id).children.filter { $0.name.hasPrefix("shelf_") && !$0.name.hasPrefix("shelf_back_") }
                .map { $0.position.y }.sorted()
        }
        let crisps = plates("gondola_2"), sweets = plates("gondola_3")
        #expect(crisps.count == 5)
        #expect(crisps != sweets)
        #expect(plates("gondola_1").count == 4)
        #expect(plates("gondola_1") != plates("gondola_5"))
    }

    @Test func everyProductHasOneLabelUnderItsFirstFacing() throws {
        for f in Self.stocked {
            let plan = try #require(Self.catalogue.planogram(forLabel: f.label))
            let bay = try #require(Merchandiser.bay(for: f.kind))
            let node = Self.goods(f.id)
            for (i, shelf) in plan.shelves.enumerated() {
                let packed = ShelfPacker.pack(shelf: shelf, width: bay.width * 100, catalogue: Self.catalogue)
                for block in packed.blocks {
                    let labels = node.children.filter { $0.name == "label_\(i)_\(block.index)" }
                    #expect(labels.count == 1, "\(f.id) shelf \(i) block \(block.index)")
                    guard let label = labels.first else { continue }
                    #expect(abs(label.position.x - (-bay.width / 2 + block.firstCentre / 100)) < 1e-9)
                    let rail = try #require(node.children.first { $0.name == "price_rail_\(i)" })
                    #expect(abs(label.position.y - rail.position.y) < 1e-9, "the label sits on the rail")
                }
                #expect(node.children.filter { $0.name.hasPrefix("label_\(i)_") }.count == packed.blocks.count)
            }
        }
    }

    @Test func promoTagsOnlyOnPromoProducts() throws {
        var tags = 0
        for f in Self.stocked {
            let plan = try #require(Self.catalogue.planogram(forLabel: f.label))
            let node = Self.goods(f.id)
            for (i, shelf) in plan.shelves.enumerated() {
                for (b, block) in shelf.blocks.enumerated() {
                    let hasTag = node.children.contains { $0.name == "promo_\(i)_\(b)" }
                    let promo = Self.catalogue.product(block.productID)?.promo != nil
                    #expect(hasTag == promo, "\(f.id) shelf \(i) block \(b)")
                    if hasTag { tags += 1 }
                }
            }
        }
        #expect(tags >= 8)
        let crisps = Self.goods("gondola_2")
        #expect(crisps.children.filter { $0.name.hasPrefix("promo_") && !$0.name.hasPrefix("promo_back_") }.count == 2)
    }

    @Test func bagsLeanWithinTwoDegrees() {
        let bodies = Self.bodies(Self.goods("gondola_2")).filter { $0.name.hasPrefix("product_") && !$0.name.hasPrefix("product_back_") }
        let leaning = bodies.filter { $0.roll != 0 }
        #expect(leaning.count >= 10)
        for b in leaning { #expect(abs(b.roll) <= 2 * .pi / 180 + 1e-12, "\(b.name) leans \(b.roll)") }
        // Tubes (cylinders on the Crisps shelf) stand straight.
        let tubes = bodies.filter { if case .cylinder = $0.shape { true } else { false } }
        #expect(tubes.count >= 5)
        #expect(tubes.allSatisfy { $0.roll == 0 })
        // Not every bag leans the same way.
        #expect(Set(leaning.map(\.roll)).count > 3)
    }

    @Test func cansDoNotLean() {
        for id in ["wall_fridge_1", "wall_fridge_2", "wall_fridge_3", "wall_fridge_4", "wall_fridge_5"] {
            let node = Self.goods(id)
            #expect(node.children.allSatisfy { $0.roll == 0 }, "\(id) leans")
        }
    }

    @Test func leanIsSeededByFixtureId() {
        func rolls(_ f: Fixture) -> [Double] {
            Self.bodies(Merchandiser.build(f, detail: .full, variant: 0)).map(\.roll)
        }
        func positions(_ f: Fixture) -> [SIMD3<Double>] {
            Self.bodies(Merchandiser.build(f, detail: .full, variant: 0)).map(\.position)
        }
        let a = Fixture(id: "island_a", kind: .gondolaShelf, cell: GridCell(x: 0, z: 0), label: "Crisps")
        let b = Fixture(id: "island_b", kind: .gondolaShelf, cell: GridCell(x: 0, z: 0), label: "Crisps")
        #expect(rolls(a) == rolls(a))
        #expect(positions(a) == positions(b), "the same planogram stands in the same places")
        #expect(rolls(a) != rolls(b), "but the lean follows the fixture id")
        // The two Beer fridges share their positions (and have no bags to lean).
        #expect(positions(Self.fixture("wall_fridge_4")) == positions(Self.fixture("wall_fridge_5")))
    }

    @Test func backFaceIsTurnedNotMirrored() {
        let node = Self.goods("gondola_2")
        let back = node.children.filter { $0.name.contains("_back_") }
        #expect(back.count > 50)
        for n in back {
            #expect(abs(n.yaw - .pi) < 1e-12, "\(n.name) yaw \(n.yaw)")
            #expect(n.position.z < 0, "\(n.name) is on the front side")
        }
        let front = node.children.filter { !$0.name.contains("_back_") }
        #expect(front.allSatisfy { $0.yaw == 0 && $0.position.z > 0 })
        // Turned a half turn about the centre line: the same planogram, x and z negated.
        for n in front {
            let twin = n.name.replacingOccurrences(of: "product_", with: "product_back_")
                .replacingOccurrences(of: "shelf_", with: "shelf_back_")
                .replacingOccurrences(of: "price_rail_", with: "price_rail_back_")
                .replacingOccurrences(of: "label_", with: "label_back_")
                .replacingOccurrences(of: "promo_", with: "promo_back_")
                .replacingOccurrences(of: "lane_", with: "lane_back_")
            guard let other = back.first(where: { $0.name == twin }) else { Issue.record("no back twin of \(n.name)"); continue }
            #expect(abs(other.position.x + n.position.x) < 1e-12 && abs(other.position.z + n.position.z) < 1e-12)
            #expect(other.position.y == n.position.y)
        }
    }

    @Test func fridgeHasNoBackFace() {
        let node = Self.goods("wall_fridge_2")
        #expect(!node.children.contains { $0.name.contains("_back") })
        #expect(node.children.allSatisfy { $0.yaw == 0 })
    }

    @Test func genericRowsForUnknownLabel() {
        let gondola = Fixture(id: "gondola_x", kind: .gondolaShelf, cell: GridCell(x: 0, z: 0))
        let odd = Fixture(id: "gondola_y", kind: .gondolaShelf, cell: GridCell(x: 0, z: 0), label: "Not a category")
        for f in [gondola, odd] {
            let node = Merchandiser.build(f, detail: .full, variant: 0)
            let shelves = node.children.filter { $0.name.hasPrefix("shelf_") && !$0.name.hasPrefix("shelf_back_") }
                .sorted { $0.name < $1.name }
            #expect(shelves.map(\.name) == ["shelf_0", "shelf_1", "shelf_2", "shelf_3"])
            for (a, b) in zip(shelves, shelves.dropFirst()) {
                #expect(abs((b.position.y - a.position.y) - 0.35) < 1e-9, "today's 0.35 m pitch")
            }
            let products = node.children.filter { $0.name.hasPrefix("product_") && !$0.name.hasPrefix("product_back_") }
            #expect(products.count >= 16)
            for p in products { if case .solid = p.material {} else { Issue.record("\(p.name) is not a plain colour") } }
        }
        let fridge = Fixture(id: "fridge_x", kind: .wallFridge, cell: GridCell(x: 0, z: 0))
        let rows = Merchandiser.build(fridge, detail: .full, variant: 0)
        #expect(rows.children.contains { $0.name == "shelf_3" })
        #expect(rows.children.filter { $0.name.hasPrefix("bottle_") }.count >= 12)
    }

    @Test func reducedDetailHalvesTheLayer() {
        var full = 0, reduced = 0
        for f in Self.stocked {
            let a = Self.goods(f.id, detail: .full), b = Self.goods(f.id, detail: .reduced)
            full += a.children.count
            reduced += b.children.count
            #expect(b.children.count < a.children.count, "\(f.id)")
            #expect(!b.children.contains { $0.name.hasPrefix("lane") }, "\(f.id) keeps lanes when reduced")
            #expect(a.children.contains { $0.name.hasPrefix("lane") })
        }
        #expect(Double(reduced) <= 0.6 * Double(full), "reduced \(reduced) of \(full)")
    }

    @Test func frontCardsUseTheAtlas() {
        for f in Self.stocked {
            let fronts = Self.goods(f.id).children.filter { $0.name.hasSuffix("_front") }
            #expect(fronts.count >= 20, "\(f.id)")
            for n in fronts {
                guard case .quad = n.shape else { Issue.record("\(n.name) is not a quad"); continue }
                guard case let .atlas(name, region, _) = n.material else { Issue.record("\(n.name) has no atlas material"); continue }
                #expect(name == .packFronts)
                #expect(region.width > 0 && region.height > 0 && region.u >= 0 && region.v >= 0)
                #expect(region.u + region.width <= 1 && region.v + region.height <= 1)
            }
        }
    }

    @Test func labelsAndPromoTagsUseTheAtlasToo() {
        for n in Self.goods("gondola_2").children where n.name.hasPrefix("label_") || n.name.hasPrefix("promo_") {
            guard case .quad = n.shape, case let .atlas(name, _, _) = n.material else { Issue.record("\(n.name)"); continue }
            #expect(name == .packFronts)
        }
    }

    @Test func packsStandOnTheirShelfAndCardsSitInFront() throws {
        for id in ["gondola_3", "wall_fridge_4"] {
            let node = Self.goods(id)
            for body in Self.bodies(node) where body.roll == 0 && !body.name.hasPrefix("product_back_") {
                let shelf = body.name.split(separator: "_")[1]
                let plate = try #require(node.children.first { $0.name == "shelf_\(shelf)" })
                let top = plate.position.y + plate.size.y / 2
                let bottom = body.position.y - body.size.y / 2
                #expect(abs(bottom - top) < 1e-9, "\(body.name) floats or sinks")
                let card = try #require(node.children.first { $0.name == body.name + "_front" })
                #expect(abs(card.position.z - (body.position.z + body.size.z / 2 + 0.001)) < 1e-9)
                #expect(abs(card.position.x - body.position.x) < 1e-12)
            }
        }
    }

    @Test func nothingPokesAboveTheHeader() {
        for f in Self.stocked {
            let bay = Merchandiser.bay(for: f.kind)!
            for n in Self.goods(f.id).children {
                // A leaning bag may rise a few millimetres; there are two centimetres of finger room.
                #expect(n.position.y + n.size.y / 2 <= bay.ceiling + 1e-9, "\(f.id) \(n.name) reaches the header")
                #expect(n.position.y - n.size.y / 2 >= bay.deck - 0.02, "\(f.id) \(n.name) is below the deck")
                // A label is wider than a five-centimetre can, so it may overhang the shelf end by a few millimetres.
                let tag = n.name.hasPrefix("label") || n.name.hasPrefix("promo")
                #expect(abs(n.position.x) + n.size.x / 2 <= bay.width / 2 + (tag ? 0.02 : 1e-9), "\(f.id) \(n.name) is past the side")
            }
        }
    }

    @Test func goodsStayBehindTheFridgeDoors() {
        let node = Self.goods("wall_fridge_1")
        let doorFront = 1.0 / 2 - 0.012 - 0.01
        for n in node.children {
            #expect(n.position.z + n.size.z / 2 <= doorFront, "\(n.name) reaches the glass")
        }
    }

    @Test func merchandiseNamesAreUnique() {
        for f in Self.stocked {
            let names = Self.goods(f.id).children.map(\.name)
            #expect(Set(names).count == names.count, "\(f.id) has duplicate names")
        }
    }

    @Test func merchandiseFloorAtFullDetail() {
        for f in Self.stocked {
            let count = Self.goods(f.id).children.count
            #expect(count >= 80, "\(f.id) has \(count) parts")
        }
    }

    @Test func buildingTwiceGivesTheSameLayer() {
        let a = Self.goods("gondola_4"), b = Self.goods("gondola_4")
        #expect(a.children.map(\.name) == b.children.map(\.name))
        #expect(a.children.map(\.position) == b.children.map(\.position))
        #expect(a.children.map(\.roll) == b.children.map(\.roll))
    }

    @Test func variantNeverChangesAPlannedLayer() {
        let f = Self.fixture("gondola_2")
        let a = Merchandiser.build(f, detail: .full, variant: 0)
        let b = Merchandiser.build(f, detail: .full, variant: 2)
        #expect(a.children.map(\.name) == b.children.map(\.name))
        #expect(a.children.map(\.position) == b.children.map(\.position))
    }

    @Test func familyPacksAndBigBottlesAreOnTheBottomShelf() {
        // Crisps shelf 4 (the fifth) holds the XXL bags; the Soft drinks fridge holds 1.5 L bottles at the bottom.
        let fridge = Self.goods("wall_fridge_2")
        let bottom = fridge.children.first { $0.name == "shelf_4" }!
        let big = fridge.children.filter { $0.name.hasPrefix("product_4_") && !$0.name.hasSuffix("_front") && !$0.name.hasSuffix("_neck") }
        #expect(!big.isEmpty)
        let lowest = fridge.children.filter { $0.name.hasPrefix("shelf_") }.map(\.position.y).min()!
        #expect(bottom.position.y == lowest)
        #expect(big.allSatisfy { $0.position.y > bottom.position.y })
    }
}
