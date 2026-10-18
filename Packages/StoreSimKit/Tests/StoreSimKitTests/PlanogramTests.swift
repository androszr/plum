import Foundation
import Testing
@testable import StoreSimKit

@Suite struct PlanogramTests {
    static let catalogue = PlanogramCatalogue.shipped

    /// The label of every fixture the merchandiser stocks, as the shop lays them out.
    static var stockedFixtures: [Fixture] {
        StoreLayout.plumCorner.fixtures.filter { Merchandiser.kinds.contains($0.kind) }
    }

    static func packed(_ plan: Planogram, width: Double) -> [PackedShelf] {
        plan.shelves.map { ShelfPacker.pack(shelf: $0, width: width, catalogue: catalogue) }
    }

    // MARK: Catalogue

    @Test func shippedCatalogueDecodes() {
        let c = Self.catalogue
        #expect(c.version == 1)
        #expect(c.planograms.count == 9)
        #expect(c.products.count > 90)
        #expect(c.shapes.count == 20)
        #expect(c.atlas.cellCount == 128)
    }

    @Test func everyPlanogramdLabelMapsToAPlanogram() {
        let fixtures = Self.stockedFixtures
        #expect(fixtures.count == 10)
        for f in fixtures {
            #expect(Self.catalogue.planogram(forLabel: f.label) != nil, "\(f.id) labelled \(f.label ?? "nil") has no planogram")
        }
    }

    @Test func everyBlockNamesAKnownProduct() {
        for (label, plan) in Self.catalogue.planograms {
            for (i, shelf) in plan.shelves.enumerated() {
                #expect(!shelf.blocks.isEmpty, "\(label) shelf \(i) is empty")
                for block in shelf.blocks {
                    let product = Self.catalogue.product(block.productID)
                    #expect(product != nil, "\(label): unknown product \(block.productID)")
                    #expect(block.weight >= 1)
                }
            }
        }
    }

    @Test func productIdsAreUniqueAndCellsAreInOrder() {
        let ids = Self.catalogue.products.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Self.catalogue.products.map(\.cell) == Array(0..<ids.count))
    }

    @Test func atlasHasRoomForEveryProduct() {
        #expect(Self.catalogue.products.count <= Self.catalogue.atlas.columns * Self.catalogue.atlas.rows)
    }

    @Test func everyProductHasColoursAndAPrice() {
        for p in Self.catalogue.products {
            #expect(Self.catalogue.colours(of: p) != nil, "\(p.id) colours do not resolve")
            #expect(p.price.wholeMatch(of: /[0-9]+,[0-9]{2}/) != nil, "\(p.id) price \(p.price)")
            #expect(Self.catalogue.shape(of: p) != nil)
        }
    }

    @Test func eachAtlasProductNamesItsFlavourAndKeepsItsPromoAndTagOnTheProduct() throws {
        let beer = try #require(Self.catalogue.product("old_harbour_lager_cant"))
        #expect(beer.promo == "4+2")
        let xxl = try #require(Self.catalogue.product("crunchtown_paprika_bag_xxl"))
        #expect(xxl.tag == "XXL")
        #expect(Self.catalogue.product("crunchtown_paprika_bag")?.tag == nil)
    }

    // MARK: The five mockup bays, verbatim

    /// Brand / code / shape / weight / price / promo / tag, per block, per shelf, top to bottom.
    static let mockupBays: [String: [[String]]] = [
        "Crisps": [
            ["Stax Up/salted/tube/3/9,99//", "Stax Up/paprika/tube/3/9,99//", "Stax Up/onion/tube/3/9,99//", "Crunchtown/crab/bagS/2/4,49//"],
            ["Crunchtown/onion/bag/1/7,99//", "Crunchtown/paprika/bag/2/7,99//", "Crunchtown/salted/bag/1/7,99//", "Golden Field/bbq/bag/1/8,49/-25%/"],
            ["Crunchtown/crab/bag/1/7,99//", "Max Ridge/max/bag/1/8,99//", "Max Ridge/maxR/bag/1/8,99//", "Golden Field/cheese/bag/1/8,49//"],
            ["Puffo/puffB/puff/2/5,99/2 for 9/", "Puffo/puffO/puff/1/5,99//", "Twisty/cheese/puff/1/4,99//"],
            ["Crunchtown/paprika/bag/2/12,99//XXL", "Golden Field/salted/bag/2/11,99//XXL"],
        ],
        "Sweets": [
            ["Cocoa Lane/milk/tablet/3/6,49//", "Cocoa Lane/dark/tablet/2/6,99//", "Cocoa Lane/nut/tablet/2/6,99//"],
            ["Moonbar/milk/tray/1/2,99//", "Nutty/nut/tray/1/3,29//", "Wafflo/wafer/tray/1/1,99/-30%/"],
            ["Moonbar/mint/tray/1/2,99//", "Darko/dark/tray/1/3,49//", "Wafflo/cocoa/tray/1/1,99//"],
            ["Jelly Jam/gum/bagSw/2/5,99//", "Jelly Jam/lemon/bagSw/1/5,99//", "Jelly Jam/orange/bagSw/1/5,99//"],
            ["Jelly Jam/crab/bagSw/2/5,99//", "Fizz Pop/mint/bagSw/2/4,49//"],
        ],
        "Biscuits": [
            ["Oatbake/oat/roll/3/4,99//", "Oatbake/cocoa/roll/3/4,99//", "Crispy/wafer/roll/2/3,99//"],
            ["Choco Dip/cocoa/bbox/2/6,99//", "Choco Dip/milk/bbox/1/6,99/-20%/", "Crispy/nut/bbox/1/5,49//"],
            ["Biscotto/oat/bbox/2/5,99//", "Biscotto/wafer/bbox/2/5,99//"],
            ["Crispy/cocoa/roll/3/3,99//", "Crispy/oat/roll/2/3,99//", "Choco Dip/dark/roll/3/4,49//"],
            ["Oatbake/oat/fam/2/11,99//", "Choco Dip/cocoa/fam/1/12,99//"],
        ],
        "Soft drinks": [
            ["Fizzo/cola/can/4/3,49//", "Fizzo/zero/can/3/3,49//", "Sunny/orange/can/3/3,29//"],
            ["Volt/volt/canT/4/6,49//", "Volt/voltB/canT/3/6,49//", "Volt/voltW/canT/3/6,49/2 for 10/"],
            ["Fizzo/cola/pet05/4/4,99//", "Fizzo/zero/pet05/3/4,99//", "Sunny/lemon/pet05/3/4,49//"],
            ["Spring Peak/water/pet05/5/2,49//", "Spring Peak/waterG/pet05/5/2,49//"],
            ["Fizzo/cola/pet15/4/7,99//", "Spring Peak/water/pet15/5/3,99//"],
        ],
        "Beer": [
            ["Old Harbour/lager/canT/4/4,29/4+2/", "Hopwright/pils/canT/4/4,49//", "Black Mill/dark2/canT/3/5,29//"],
            ["Old Harbour/lager/canT/4/4,29/4+2/", "Hopwright/pils/canT/4/4,49//", "Wheatfield/wheat/canT/3/4,99//"],
            ["Old Harbour/lager/btl/4/4,79//", "Hopwright/pils/btl/3/4,99//", "Black Mill/dark2/btl/3/5,49//"],
            ["Old Harbour/radler/canT/4/4,49//", "Hopwright/radler/canT/4/4,49//", "Wheatfield/wheat/btl/2/5,29//"],
            ["Old Harbour/lager/canT/4/4,29/4+2/", "Hopwright/pils/canT/4/4,49//", "Black Mill/dark2/canT/3/5,29//"],
        ],
    ]

    @Test func mockupBaysMatchThePlan() throws {
        #expect(Self.mockupBays.count == 5)
        for (label, shelves) in Self.mockupBays {
            let plan = try #require(Self.catalogue.planogram(forLabel: label), "no planogram \(label)")
            #expect(plan.shelves.count == shelves.count, "\(label) shelf count")
            for (i, expected) in shelves.enumerated() where i < plan.shelves.count {
                let blocks = plan.shelves[i].blocks
                #expect(blocks.count == expected.count, "\(label) shelf \(i) block count")
                for (j, line) in expected.enumerated() where j < blocks.count {
                    let f = line.components(separatedBy: "/")
                    let product = try #require(Self.catalogue.product(blocks[j].productID))
                    let spot = "\(label) shelf \(i) block \(j)"
                    #expect(product.brand == f[0], "\(spot) brand")
                    #expect(product.code == f[1], "\(spot) code")
                    #expect(product.shape == f[2], "\(spot) shape")
                    #expect(blocks[j].weight == Int(f[3]), "\(spot) weight")
                    #expect(product.price == f[4], "\(spot) price")
                    #expect(product.promo == (f[5].isEmpty ? nil : f[5]), "\(spot) promo")
                    #expect(product.tag == (f[6].isEmpty ? nil : f[6]), "\(spot) tag")
                }
            }
        }
    }

    @Test func newBaysExist() {
        for label in ["Snacks", "Tea & coffee", "Cold drinks", "Water & juice"] {
            let count = Self.catalogue.planogram(forLabel: label)?.shelves.count ?? 0
            #expect((4...5).contains(count), "\(label) has \(count) shelves")
        }
    }

    @Test func twoBeerFridgesHoldTheSamePlanogram() {
        let beer = Self.stockedFixtures.filter { $0.label == "Beer" }
        #expect(beer.count == 2)
        let plans = beer.map { Self.catalogue.planogram(forLabel: $0.label) }
        #expect(plans[0] == plans[1])
        #expect(plans[0] != nil)
    }

    // MARK: Packing

    @Test func noGapWiderThanFiveMillimetres() {
        for f in Self.stockedFixtures {
            let plan = Self.catalogue.planogram(forLabel: f.label)!
            let bay = Merchandiser.bay(for: f.kind)!
            for shelf in Self.packed(plan, width: bay.width * 100) {
                for (a, b) in zip(shelf.facings, shelf.facings.dropFirst()) {
                    let gap = b.left - (a.left + a.width)
                    #expect(gap >= -1e-9 && gap <= 0.5, "\(f.label ?? "?"): gap \(gap) cm")
                }
            }
        }
    }

    /// A shelf is filled across at least 95 percent of its width, or what is left is narrower than the
    /// narrowest pack on it (plus the gap), so nothing more can stand there. Some bays hold wide packs
    /// (family biscuit packs are 22 cm), where the second half cannot be met by any whole number of packs.
    @Test func everyShelfIsAtLeast95PercentFilled() {
        var fills: [Double] = []
        for f in Self.stockedFixtures {
            let plan = Self.catalogue.planogram(forLabel: f.label)!
            let bay = Merchandiser.bay(for: f.kind)!
            for (i, shelf) in Self.packed(plan, width: bay.width * 100).enumerated() {
                fills.append(shelf.fill)
                let full = shelf.fill >= 0.95
                let nothingFits = shelf.slack < shelf.narrowest + PlanogramCatalogue.gap
                #expect(full || nothingFits, "\(f.label ?? "?") shelf \(i) is \(Int(shelf.fill * 100)) percent filled")
            }
        }
        let mean = fills.reduce(0, +) / Double(fills.count)
        #expect(mean >= 0.93, "average fill \(mean)")
        #expect(fills.filter { $0 >= 0.95 }.count * 4 >= fills.count * 3, "at least three shelves in four are 95 percent full")
    }

    @Test func noPackTallerThanItsClearance() throws {
        for f in Self.stockedFixtures {
            let plan = Self.catalogue.planogram(forLabel: f.label)!
            let bay = Merchandiser.bay(for: f.kind)!
            let levels = try #require(ShelfStacker.stack(planogram: plan, interior: bay.interior))
            for (shelf, level) in zip(plan.shelves, levels) {
                for block in shelf.blocks {
                    let shape = Self.catalogue.shape(of: Self.catalogue.product(block.productID)!)!
                    #expect(shape.height / 100 + 0.02 <= level.clearance + 1e-9, "\(f.label ?? "?"): \(block.productID) too tall")
                }
            }
        }
    }

    @Test func heavyShapesSitOnTheBottomShelf() {
        for (label, plan) in Self.catalogue.planograms {
            for (i, shelf) in plan.shelves.enumerated() where i < plan.shelves.count - 1 {
                for block in shelf.blocks {
                    let shape = Self.catalogue.shape(of: Self.catalogue.product(block.productID)!)!
                    #expect(!shape.heavy, "\(label) shelf \(i) holds heavy \(shape.id)")
                }
            }
        }
    }

    @Test func everyPlanogramFitsItsFixture() {
        for f in Self.stockedFixtures {
            let plan = Self.catalogue.planogram(forLabel: f.label)!
            let bay = Merchandiser.bay(for: f.kind)!
            let levels = ShelfStacker.stack(planogram: plan, interior: bay.interior)
            #expect(levels != nil, "\(f.label ?? "?") does not fit \(f.id)")
            guard let levels else { continue }
            #expect(levels.count == plan.shelves.count)
            // Stacked bottom up, the top shelf's clearance ends at the header underside.
            let top = levels[0]
            #expect(abs(top.goodsY + top.clearance - bay.ceiling) < 1e-9)
            #expect(abs(levels.last!.plateY - bay.deck) < 1e-9)
        }
    }

    @Test func shelfHeightsVaryByCategory() throws {
        let crisps = try #require(Self.catalogue.planogram(forLabel: "Crisps"))
        let sweets = try #require(Self.catalogue.planogram(forLabel: "Sweets"))
        let bay = try #require(Merchandiser.bay(for: .gondolaShelf))
        let a = try #require(ShelfStacker.stack(planogram: crisps, interior: bay.interior)).map(\.plateY)
        let b = try #require(ShelfStacker.stack(planogram: sweets, interior: bay.interior)).map(\.plateY)
        #expect(a != b)
        #expect(a.count == 5 && b.count == 5)
    }

    @Test func overfullPlanogramDoesNotStack() throws {
        let crisps = try #require(Self.catalogue.planogram(forLabel: "Crisps"))
        let tiny = ShelfInterior(deck: 0.08, ceiling: 0.9, plate: 0.02)
        #expect(ShelfStacker.stack(planogram: crisps, interior: tiny) == nil)
    }

    @Test func packingIsDeterministic() throws {
        let crisps = try #require(Self.catalogue.planogram(forLabel: "Crisps"))
        for shelf in crisps.shelves {
            #expect(ShelfPacker.pack(shelf: shelf, width: 88) == ShelfPacker.pack(shelf: shelf, width: 88))
        }
        // The same planogram at another width differs only in its facings, never in its block order.
        let narrow = crisps.shelves.map { ShelfPacker.pack(shelf: $0, width: 60) }
        let wide = crisps.shelves.map { ShelfPacker.pack(shelf: $0, width: 88) }
        #expect(narrow != wide)
        for (n, w) in zip(narrow, wide) {
            #expect(n.blocks.map(\.productID) == w.blocks.map(\.productID))
        }
    }

    @Test func leftoverWidthGoesToTheHeaviestBlock() {
        let shelf = PlanogramShelf(blocks: [
            PlanogramBlock(productID: "stax_up_salted_tube", weight: 3),
            PlanogramBlock(productID: "crunchtown_crab_bags", weight: 1),
        ])
        // Room for several more packs, wide enough for a tube and for a small bag: the tubes, with more
        // facings, are served first.
        let packed = ShelfPacker.pack(shelf: shelf, width: 54.7, catalogue: Self.catalogue)
        #expect(packed.blocks[0].facings > 3)
        #expect(packed.blocks[1].facings == 1)
        // With room for one tube and no more, the tube block takes it and the bag block is unchanged.
        let tight = ShelfPacker.pack(shelf: shelf, width: 47, catalogue: Self.catalogue)
        #expect(tight.blocks.map(\.facings) == [4, 1])
    }

    @Test func slackIsSplitEquallyAtBothEnds() {
        let shelf = PlanogramShelf(blocks: [PlanogramBlock(productID: "crunchtown_crab_bags", weight: 1)])
        let packed = ShelfPacker.pack(shelf: shelf, width: 40, catalogue: Self.catalogue)
        let left = packed.facings.first!.left
        let right = 40 - (packed.facings.last!.left + packed.facings.last!.width)
        #expect(abs(left - right) < 1e-9)
    }

    @Test func trimTiesGoToTheLighterThenTheLaterBlock() {
        // Snacks shelf 1: weights 3, 2, 2 of 15 cm bags in 88 cm. After the biggest block drops to 2 all three
        // tie; the hero block must not be the next to lose a facing.
        let snacks = Self.catalogue.planogram(forLabel: "Snacks")!.shelves[0]
        let packed = ShelfPacker.pack(shelf: snacks, width: 88, catalogue: Self.catalogue)
        let counts = packed.blocks.map(\.facings)
        #expect(counts[0] >= counts[1] && counts[0] >= counts[2], "hero block lost out: \(counts)")
        #expect(counts[0] >= 2)
        #expect(counts[1] >= counts[2], "the later block gives up first: \(counts)")
    }

    @Test func tooManyFacingsAreTrimmedFromTheBiggestBlock() {
        let shelf = PlanogramShelf(blocks: [
            PlanogramBlock(productID: "crunchtown_paprika_bag_xxl", weight: 6),
            PlanogramBlock(productID: "stax_up_salted_tube", weight: 1),
        ])
        let packed = ShelfPacker.pack(shelf: shelf, width: 88, catalogue: Self.catalogue)
        #expect(packed.used <= 88)
        #expect(packed.blocks[0].facings < 6)
        #expect(packed.blocks[1].facings >= 1)
    }

    // MARK: Atlas

    @Test func atlasRegionIsInsideItsCell() throws {
        let c = Self.catalogue
        let total = Double(c.atlas.columns * c.atlas.cellWidth)
        for p in c.products {
            let r = try #require(c.atlasRegion(for: p.id))
            let col = Double(p.cell % c.atlas.columns), row = Double(p.cell / c.atlas.columns)
            let left = col * Double(c.atlas.cellWidth) / total
            let right = (col + 1) * Double(c.atlas.cellWidth) / total
            let rowTop = 1 - row * Double(c.atlas.cellHeight) / total
            let rowBottom = 1 - (row + 1) * Double(c.atlas.cellHeight) / total
            for region in [r.art, r.label, r.promo] {
                #expect(region.u >= left - 1e-9 && region.u + region.width <= right + 1e-9, "\(p.id) u")
                #expect(region.v >= rowBottom - 1e-9 && region.v + region.height <= rowTop + 1e-9, "\(p.id) v")
            }
            #expect(r.art.v >= r.label.v + r.label.height - 1e-9, "art sits above its label")
            #expect(r.label.v >= r.promo.v + r.promo.height - 1e-9, "label sits above its promo band")
        }
    }

    @Test func atlasRegionFlipsV() throws {
        let c = Self.catalogue
        let first = try #require(c.atlasRegion(for: c.products[0].id))
        let second = try #require(c.atlasRegion(for: c.products[c.atlas.columns].id))
        // Row 0 is the top of the picture, so its v is the highest; the next row is lower.
        #expect(first.art.v > second.art.v)
        #expect(abs(first.promo.v - (1 - 256.0 / 2048)) < 1e-9)
        #expect(abs(first.label.v + first.label.height - (1 - 192.0 / 2048)) < 1e-9)
    }

    @Test func artRectangleIsWholePixelsAndKeepsTheAspect() throws {
        let c = Self.catalogue
        for p in c.products {
            let shape = c.shape(of: p)!
            let a = c.artPixels(for: shape)
            #expect(a.width <= c.atlas.cellWidth && a.height <= c.atlas.artHeight)
            #expect(a.x >= 0 && a.y >= 0)
            let aspect = Double(a.width) / Double(a.height)
            #expect(abs(aspect - shape.width / shape.height) < 0.08, "\(shape.id) aspect")
        }
    }

    // MARK: Lenient decoding

    @Test func lenientDecodingDropsUnknownShape() throws {
        let json = """
        {"version": 3,
         "shapes": {"bag": {"w": 20, "h": 30, "d": 7, "form": "box"}},
         "colourCodes": {"paprika": ["paprikaBase", "paprikaAccent"], "ghost": ["nopeBase", "nopeAccent"]},
         "products": [
           {"id": "bad_shape", "brand": "X", "code": "paprika", "shape": "mystery", "price": "1,00"},
           {"id": "good", "brand": "Y", "code": "paprika", "shape": "bag", "price": "2,00"},
           {"id": "bad_colour", "brand": "Z", "code": "ghost", "shape": "bag", "price": "3,00"}
         ],
         "planograms": {"Test": {"shelves": [[{"product": "good", "weight": 2}, {"product": "bad_shape"}, {"product": "bad_colour"}]]}},
         "unknownFutureKey": true}
        """
        let c = try PlanogramCatalogue.decode(from: Data(json.utf8))
        #expect(c.version == 3)
        #expect(c.products.map(\.id) == ["good"])
        // The surviving product keeps the picture cell its position in the file gave it.
        #expect(c.products.first?.cell == 1)
        let blocks = try #require(c.planogram(forLabel: "Test")?.shelves.first?.blocks)
        #expect(blocks == [PlanogramBlock(productID: "good", weight: 2)])
        #expect(c.product("good")?.promo == nil && c.product("good")?.tag == nil)
        #expect(c.shapes["bag"]?.heavy == false)
    }

    @Test func missingKeysTakeTheirDefaults() throws {
        let c = try PlanogramCatalogue.decode(from: Data("{}".utf8))
        #expect(c.version == 1)
        #expect(c.products.isEmpty && c.planograms.isEmpty)
        #expect(c.atlas == PlanogramCatalogue.empty.atlas)
        #expect(c.planogram(forLabel: nil) == nil)
    }
}
