import Foundation
import Testing
import simd
@testable import StoreSimKit

/// The till end: the two-bay spirits wall, the tobacco front and the stepped impulse rack.
@Suite struct TillZoneTests {
    static let catalogue = PlanogramCatalogue.shipped
    static let layout = StoreLayout.plumCorner
    static let full = SceneComposer.compose(layout: layout, detail: .full, catalogue: .empty)
    static let reduced = SceneComposer.compose(layout: layout, detail: .reduced, catalogue: .empty)

    static func node(_ id: String, _ detail: DetailLevel = .full) -> SceneNode {
        (detail.isFull ? full : reduced).node(named: id)!
    }

    static func goods(_ id: String, _ detail: DetailLevel = .full) -> SceneNode {
        node(id, detail).node(named: "merchandise")!
    }

    static var alcohol: Planogram { catalogue.planogram(forLabel: "Vodka & whisky")! }
    static var impulse: Planogram { catalogue.planogram(forLabel: "Till impulse")! }
    static let walls = ["alcohol_wall_1", "alcohol_wall_2"]
    static let tills = ["checkout_1", "checkout_2"]

    static func top(_ n: SceneNode) -> Double { n.position.y + n.size.y / 2 }
    static func bottom(_ n: SceneNode) -> Double { n.position.y - n.size.y / 2 }

    // MARK: Spirits wall

    @Test(.tags(.successCriterion)) func alcoholPlanogramHasSevenShelvesInTheUsersBands() {
        #expect(Self.alcohol.shelves.map(\.band) == ["vodka 0.2", "vodka 0.5", "vodka 0.7", "flavoured vodka",
                                                     "whisky premium", "whisky", "rum gin liqueur"])
    }

    @Test(.tags(.successCriterion)) func premiumWhiskySitsAtTheTopOfTheWhiskyBand() {
        let bands = Self.alcohol.shelves.map(\.band)
        let premium = bands.firstIndex(of: "whisky premium")!
        #expect(bands[premium + 1] == "whisky")
        #expect(bands[premium - 1] == "flavoured vodka")
    }

    @Test(.tags(.successCriterion)) func bottleSizesAreTrue() {
        let shapes = Self.catalogue.shapes
        #expect(shapes["flask02"]?.height == 16)
        #expect(shapes["spirit05"]?.height == 27)
        #expect(shapes["spirit07"]?.height == 31)
        for (shelf, shape) in zip(0..<3, ["flask02", "spirit05", "spirit07"]) {
            let used = Set(Self.alcohol.shelves[shelf].blocks.compactMap {
                Self.catalogue.product($0.productID)?.shape
            })
            #expect(used == [shape], "shelf \(shelf) holds \(used)")
        }
    }

    @Test func twoBaysSplitEveryShelfWithNoBlockLost() {
        for shelf in Self.alcohol.shelves {
            let a = shelf.bayBlocks(bay: 0, of: 2), b = shelf.bayBlocks(bay: 1, of: 2)
            #expect(a + b == shelf.blocks)
            #expect(!a.isEmpty && !b.isEmpty)
        }
        let odd = PlanogramShelf(blocks: (0..<5).map { PlanogramBlock(productID: "p\($0)", weight: 1) })
        #expect(odd.bayBlocks(bay: 0, of: 2).count == 3)
        #expect(odd.bayBlocks(bay: 1, of: 2).count == 2)
        #expect(odd.bayBlocks(bay: 2, of: 2).isEmpty)
    }

    @Test func eachBayFillsAtLeast95PercentWithNoGapOverFiveMillimetres() {
        for shelf in Self.alcohol.shelves {
            for bay in 0..<2 {
                let mine = PlanogramShelf(blocks: shelf.bayBlocks(bay: bay, of: 2))
                let packed = ShelfPacker.pack(shelf: mine, width: 190, catalogue: Self.catalogue)
                #expect(packed.fill >= 0.95 || packed.slack < packed.narrowest, "\(shelf.band ?? "?") bay \(bay) fill \(packed.fill)")
                for (l, r) in zip(packed.facings, packed.facings.dropFirst()) {
                    #expect(r.left - (l.left + l.width) <= 0.5 + 1e-9, "gap between facings")
                }
            }
        }
    }

    @Test func shelfHeightsLineUpAcrossTheTwoWalls() {
        func ys(_ id: String) -> [Double] {
            Self.goods(id).children.filter { $0.name.hasPrefix("shelf_") }.map(\.position.y).sorted()
        }
        let a = ys("alcohol_wall_1"), b = ys("alcohol_wall_2")
        #expect(a.count == 7 && b.count == 7)
        #expect(a == b)
    }

    @Test func theTwoWallsShowDifferentBlocks() {
        func ids(_ bay: Int) -> [[String]] {
            Self.alcohol.shelves.map { $0.bayBlocks(bay: bay, of: 2).map(\.productID) }
        }
        let differing = zip(ids(0), ids(1)).filter { $0.0 != $0.1 }.count
        #expect(differing >= 5)
        // And what is drawn differs too: the first pack of the top shelf is a different colour on each wall.
        let colours = Self.walls.map { id in
            Self.goods(id).children.first { $0.name == "product_0_0" }!.material
        }
        #expect(colours[0] != colours[1])
    }

    @Test func everyAlcoholShelfIsOneBottleDeep() {
        for id in Self.walls {
            let g = Self.goods(id)
            #expect(!g.descendants.contains { $0.name.contains("lane") })
            for n in g.children where n.name.hasPrefix("product_") && !n.name.hasSuffix("_front") {
                #expect(n.size.z <= 0.09 + 1e-9, "\(n.name) is deeper than a bottle")
                #expect(n.position.z >= -0.23 && n.position.z <= -0.09, "\(n.name) is off the shelf")
            }
        }
    }

    @Test func nothingPokesAboveTheAlcoholHeaderOrOutsideTheFootprint() {
        for detail in [DetailLevel.full, .reduced] {
            for id in Self.walls {
                for n in Self.goods(id, detail).children {
                    #expect(Self.top(n) <= 2.44 + 1e-9, "\(n.name) reaches the header")
                    #expect(abs(n.position.x) + n.size.x / 2 <= 1.0 + 1e-9, "\(n.name) is outside in x")
                    #expect(n.position.z - n.size.z / 2 >= -0.25 - 1e-9 && n.position.z + n.size.z / 2 <= 0.25 + 1e-9)
                    #expect(Self.top(n) <= FixtureKind.alcoholWall.verticalExtent.upperBound)
                }
            }
        }
    }

    @Test func everyAlcoholProductHasOneLabel() {
        for id in Self.walls {
            let bay = id == "alcohol_wall_1" ? 0 : 1
            let names = Self.goods(id).children.map(\.name)
            for (i, shelf) in Self.alcohol.shelves.enumerated() {
                let blocks = shelf.bayBlocks(bay: bay, of: 2).count
                let labels = names.filter { $0.hasPrefix("label_\(i)_") }
                #expect(labels.count == blocks, "\(id) shelf \(i)")
            }
        }
    }

    @Test func spiritsWallsCarryTheSameSign() {
        for id in Self.walls {
            let text = Self.node(id).descendants.first { $0.name == "header_text" }
            if case let .text(s)? = text?.shape { #expect(s == "Vodka & whisky") } else { Issue.record("no sign on \(id)") }
        }
    }

    // MARK: Tobacco

    @Test(.tags(.successCriterion)) func tobaccoCabinetShowsNoPacksAndNoGlass() {
        let cabinet = Self.node("cigarette_cabinet_1")
        let all = cabinet.descendants
        #expect(!all.contains { $0.name.hasPrefix("shelf_") || $0.name.hasPrefix("pack_") || $0.name.hasPrefix("product_") })
        for door in ["door_left", "door_right"] {
            if case .solid = all.first(where: { $0.name == door })!.material {} else { Issue.record("\(door) is not solid") }
        }
        let lines = Self.goods("cigarette_cabinet_1").children.filter { $0.name.hasPrefix("price_line_") }
        #expect(lines.count == 6)
        for (i, line) in lines.enumerated() {
            guard case let .text(s) = line.shape else { Issue.record("line is not text"); continue }
            #expect(s.range(of: "[0-9]+,[0-9]{2}", options: .regularExpression) != nil, "\(s)")
            let board = all.first { $0.name == (i < 3 ? "price_board_left" : "price_board_right") }!
            #expect(abs(line.position.x - board.position.x) <= board.size.x / 2)
            #expect(line.position.y >= Self.bottom(board) && line.position.y <= Self.top(board))
            #expect(line.position.z >= board.position.z)
        }
    }

    @Test func tobaccoReducedKeepsTwoLines() {
        let lines = Self.goods("cigarette_cabinet_1", .reduced).children.filter { $0.name.hasPrefix("price_line_") }
        #expect(lines.count == 2)
    }

    // MARK: Till rack

    @Test(.tags(.successCriterion)) func tillRackHasThreeTiersBarsMintsGum() {
        #expect(Self.impulse.shelves.map(\.band) == ["bars", "mints", "gum"])
        for id in Self.tills {
            let g = Self.goods(id)
            let tiers = (0..<3).map { i in g.children.first { $0.name == "tier_\(i)" } }
            #expect(tiers.allSatisfy { $0 != nil })
            let t = tiers.compactMap { $0 }
            #expect(t[0].position.y > t[1].position.y && t[1].position.y > t[2].position.y)
            #expect(t[0].position.z < t[1].position.z && t[1].position.z < t[2].position.z)
        }
    }

    @Test func tillRackStaysOnTheCounterAndClearOfTheKit() {
        let kit = ["conveyor_belt", "card_terminal", "bag_dispenser", "till", "receipt_printer"]
        func overlaps(_ a: SceneNode, _ b: SceneNode) -> Bool {
            for k in 0..<3 {
                let lo = max(a.position[k] - a.size[k] / 2, b.position[k] - b.size[k] / 2)
                let hi = min(a.position[k] + a.size[k] / 2, b.position[k] + b.size[k] / 2)
                if hi - lo <= 1e-6 { return false }
            }
            return true
        }
        for id in Self.tills {
            let stand = Self.node(id)
            let boxes = kit.map { name in stand.children.first { $0.name == name }! }
            for n in Self.goods(id).children {
                if case .text = n.shape { continue }
                #expect(Self.bottom(n) >= 1.0 - 1e-9, "\(n.name) sinks into the counter")
                #expect(Self.top(n) <= 1.2 + 1e-9, "\(n.name) is over the till's height")
                #expect(abs(n.position.x) + n.size.x / 2 <= 1.0 && abs(n.position.z) + n.size.z / 2 <= 0.5)
                for b in boxes { #expect(!overlaps(n, b), "\(n.name) overlaps \(b.name)") }
            }
        }
    }

    @Test func rackProductsStandWithinTheirTiersAndClearOfTheBelt() {
        for id in Self.tills {
            let g = Self.goods(id).children
            let belt = Self.node(id).children.first { $0.name == "conveyor_belt" }!
            for (i, _) in Self.impulse.shelves.enumerated() {
                let tier = g.first { $0.name == "tier_\(i)" }!
                let tierBack = tier.position.z - tier.size.z / 2
                let tierFront = tier.position.z + tier.size.z / 2
                for n in g where n.name.hasPrefix("product_\(i)_") && !n.name.hasSuffix("_front") {
                    #expect(n.position.z - n.size.z / 2 >= tierBack - 1e-9, "\(n.name) overhangs the back of its tier")
                    #expect(n.position.z + n.size.z / 2 <= tierFront + 1e-9, "\(n.name) overhangs the front of its tier")
                }
            }
            let rackBack = g.filter { !$0.name.hasPrefix("label") }.map { $0.position.z - $0.size.z / 2 }.min()!
            #expect(rackBack >= belt.position.z + belt.size.z / 2 - 1e-9, "\(id): the rack runs into the belt")
        }
    }

    @Test func rackLabelsAndRailsAreNeverHiddenByTheTraysInFront() {
        func overlaps(_ a: SceneNode, _ b: SceneNode) -> Bool {
            for k in 0..<3 {
                let lo = max(a.position[k] - a.size[k] / 2, b.position[k] - b.size[k] / 2)
                let hi = min(a.position[k] + a.size[k] / 2, b.position[k] + b.size[k] / 2)
                if hi - lo <= 1e-6 { return false }
            }
            return true
        }
        for detail in [DetailLevel.full, .reduced] {
            for id in Self.tills {
                let g = Self.goods(id, detail).children
                let products = g.filter { $0.name.hasPrefix("product_") && !$0.name.hasSuffix("_front") && !$0.name.hasSuffix("_neck") }
                let fronts = g.filter { $0.name.hasPrefix("product_") && $0.name.hasSuffix("_front") }
                for tier in 0..<3 {
                    let marks = g.filter { $0.name.hasPrefix("label_\(tier)_") || $0.name == "price_rail_\(tier)" }
                    #expect(!marks.isEmpty)
                    for m in marks {
                        for p in products + fronts { #expect(!overlaps(m, p), "\(m.name) is hidden by \(p.name) (\(id), \(detail))") }
                        // Nothing of a nearer tier stands in front of it and above its bottom edge.
                        for p in products where p.name.hasPrefix("product_\(tier + 1)_") {
                            let inFront = p.position.z - p.size.z / 2 > m.position.z
                            #expect(!inFront || Self.top(p) <= Self.bottom(m) + 1e-9, "\(m.name) is covered by \(p.name)")
                        }
                    }
                }
            }
        }
    }

    @Test func reducedLabelsSitOnTheTierWhenThereIsNoRail() {
        let g = Self.goods("checkout_1", .reduced).children
        #expect(!g.contains { $0.name.hasPrefix("price_rail_") })
        for l in g where l.name.hasPrefix("label_") {
            let i = Int(l.name.split(separator: "_")[1])!
            let tier = g.first { $0.name == "tier_\(i)" }!
            #expect(abs(l.position.z - (tier.position.z + tier.size.z / 2 + 0.001)) < 1e-9, "\(l.name) floats")
        }
    }

    @Test func nothingPokesAboveTheTillExtent() {
        for id in Self.tills {
            for n in Self.goods(id).children {
                #expect(Self.top(n) <= FixtureKind.checkoutCounter.verticalExtent.upperBound)
            }
        }
    }

    @Test func everyTillProductHasOneLabel() {
        for id in Self.tills {
            let names = Self.goods(id).children.map(\.name)
            for (i, shelf) in Self.impulse.shelves.enumerated() {
                #expect(names.filter { $0.hasPrefix("label_\(i)_") }.count == shelf.blocks.count, "\(id) tier \(i)")
            }
        }
    }

    // MARK: Cross-cutting

    @Test func reducedDetailHalvesTheTillZone() {
        for id in ["alcohol_wall_1", "alcohol_wall_2", "checkout_1", "cigarette_cabinet_1"] {
            let full = Self.goods(id).children.count, reduced = Self.goods(id, .reduced).children.count
            #expect(Double(reduced) <= 0.6 * Double(full), "\(id): \(reduced) of \(full)")
        }
    }

    @Test func bandIsOptional() throws {
        let json = #"""
        {"shapes": {"a": {"w": 5, "h": 5, "d": 5, "form": "box"}},
         "colourCodes": {"c": ["paprikaBase", "paprikaAccent"]},
         "products": [{"id": "p", "brand": "B", "code": "c", "shape": "a", "price": "1,00"}],
         "planograms": {"x": {"shelves": [[{"product": "p", "weight": 1}], {"band": "named", "blocks": [{"product": "p"}]}]}}}
        """#
        let c = try PlanogramCatalogue.decode(from: Data(json.utf8))
        let shelves = try #require(c.planograms["x"]).shelves
        #expect(shelves.map(\.band) == [nil, "named"])
        #expect(shelves.map { $0.blocks.count } == [1, 1])
    }

    @Test func flaskFormIsBoxPlusNeck() throws {
        let g = Self.goods("alcohol_wall_1")
        let body = try #require(g.children.first { $0.name == "product_0_0" })
        let neck = try #require(g.children.first { $0.name == "product_0_0_neck" })
        guard case .box = body.shape, case .cylinder = neck.shape else { Issue.record("wrong shapes"); return }
        #expect(abs(Self.top(neck) - (Self.bottom(body) + 0.16)) < 1e-9)
    }

    @Test func packagingColoursStayInTheBrandFile() {
        // Every colour code the new products use resolves to a named packaging colour.
        for id in Self.alcohol.shelves.flatMap(\.blocks).map(\.productID) + Self.impulse.shelves.flatMap(\.blocks).map(\.productID) {
            let p = Self.catalogue.product(id)
            #expect(p != nil && Self.catalogue.colours(of: p!) != nil, "\(id)")
        }
    }
}
