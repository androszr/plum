import CoreGraphics
import Foundation
import RealityKit
import Testing
import simd
import StoreSimKit
@testable import StoreSimRender

/// Headless front views of the till zone, checked against the planograms with the same pinhole model and
/// helpers as `PlanogramRenderTests`.
@MainActor
@Suite struct TillZoneRenderTests {
    typealias R = PlanogramRenderTests
    static let size = R.size
    static let catalogue = PlanogramCatalogue.shipped

    /// The stand-in shell (kept whole, doors included) plus the merchandise layer, lit like the planogram views.
    static func scene(_ id: String) throws -> (root: Entity, fixture: Fixture) {
        let fixture = try #require(StoreLayout.plumCorner.fixtures.first { $0.id == id })
        let variant = ModelVariant.index(of: fixture, in: StoreLayout.plumCorner)
        let shell = FixtureBuilders.builder(for: fixture.kind).build(fixture, detail: .full, variant: variant)
        let goods = Merchandiser.build(fixture, detail: .full, variant: variant)
        // The real pack-fronts picture loads, so a front card shows its art and a wrong region would show.
        let urls = try FileManager.default.contentsOfDirectory(at: BriefSpec.modelsDirectory(), includingPropertiesForKeys: nil)
        let loader = ModelLoader(catalogue: AssetCatalogue(modelURLs: urls))
        let subject = EntityBuilder.entity(for: SceneNode(name: "lone", children: [shell, goods]), loader: loader)
        let key = SceneNode(name: "key", shape: .light(.fill(intensity: 3000, direction: SIMD3(-0.2, -0.3, -1))))
        let fill = SceneNode(name: "sky_fill", shape: .light(.fill(intensity: 1500, direction: SIMD3(0.4, -0.6, -0.8))))
        let root = Entity()
        root.addChild(subject)
        root.addChild(EntityBuilder.entity(for: SceneNode(name: "lighting", children: [key, fill]), loader: loader))
        return (root, fixture)
    }

    struct Seen { var shelf: Int; var rendered: SIMD3<Double>; var options: [SIMD3<Double>] }

    /// Each block has to read as its own colours (the glass or pack base, or its label accent) rather than as a
    /// clearly different block on its shelf. The light multiplies every flat colour by one gain, estimated from
    /// all blocks of the view.
    static func check(_ seen: [Seen], _ what: String) {
        var gain = SIMD3<Double>(1, 1, 1)
        for channel in 0..<3 {
            var ratios: [Double] = []
            for s in seen {
                let rendered = R.linear(s.rendered[channel])
                var best = s.options[0][channel]
                for o in s.options where abs(R.linear(o[channel]) - rendered) < abs(R.linear(best) - rendered) { best = o[channel] }
                let e = R.linear(best)
                if e > 0.05 { ratios.append(rendered / e) }
            }
            ratios.sort()
            if !ratios.isEmpty { gain[channel] = ratios[ratios.count / 2] }
        }
        func predicted(_ e: SIMD3<Double>) -> SIMD3<Double> {
            SIMD3(R.srgb(R.linear(e.x) * gain.x), R.srgb(R.linear(e.y) * gain.y), R.srgb(R.linear(e.z) * gain.z))
        }
        func nearest(_ s: Seen, _ options: [SIMD3<Double>]) -> Double {
            options.map { R.distance(s.rendered, predicted($0)) }.min()!
        }
        for (n, s) in seen.enumerated() {
            let own = nearest(s, s.options)
            // Another block counts only if none of its colours is close to one of this block's.
            let others = seen.filter { o in
                o.shelf == s.shelf && o.options.allSatisfy { a in s.options.allSatisfy { R.distance(predicted(a), predicted($0)) > 0.25 } }
            }.map { nearest(s, $0.options) }
            #expect(own <= (others.min() ?? 1) + 0.08, "\(what) shelf \(s.shelf) block #\(n) reads as another block: rendered \(s.rendered) expected \(s.options.map(predicted)) gain \(gain)")
        }
    }

    static func plateYForLabel(_ i: Int) -> Double { TillZone.tierPlateY(i) + TillZone.rackRailHeight / 2 - 0.005 }

    static func palette(_ cat: PlanogramCatalogue, _ id: String) throws -> [SIMD3<Double>] {
        let product = try #require(cat.product(id))
        let colours = try #require(cat.colours(of: product))
        return [R.colour(colours.base), R.colour(colours.accent)]
    }

    static func wallView(_ id: String, bay: Int) async throws {
        let (root, _) = try scene(id)
        let plan = try #require(catalogue.planogram(forLabel: "Vodka & whisky"))
        let spec = TillZone.alcoholBay
        let levels = try #require(ShelfStacker.stack(planogram: plan, interior: spec.interior, catalogue: catalogue))
        let height = FixtureKind.alcoholWall.verticalExtent.upperBound
        let cam = R.camera(target: SIMD3(0, height / 2, 0), distance: 2.0 * height)
        let image = try await OffscreenRenderer().render(root: root, camera: cam, size: (size, size))
        try R.write(image, "frontview-alcoholwall-bay\(bay).png")
        let data = R.pixels(image)
        let view = R.View(camera: cam)

        // (a) Seven shelf rows, top to bottom in planogram order.
        var rows: [Double] = []
        for (i, shelf) in plan.shelves.enumerated() {
            let tallest = shelf.blocks.compactMap { catalogue.product($0.productID).flatMap { catalogue.shape(of: $0)?.height } }.max() ?? 0
            rows.append(view.project(SIMD3(0, levels[i].goodsY + tallest / 200, spec.faceZ), size: size).y)
        }
        #expect(rows.count == 7)
        for (a, b) in zip(rows, rows.dropFirst()) { #expect(a < b, "shelf rows are out of order \(rows)") }

        // (b) Blocks left to right as the bay's split plans them.
        var seen: [Seen] = []
        for (i, shelf) in plan.shelves.enumerated() {
            let mine = PlanogramShelf(blocks: shelf.bayBlocks(bay: bay, of: 2))
            let packed = ShelfPacker.pack(shelf: mine, width: spec.width * 100, catalogue: catalogue)
            for block in packed.blocks {
                let product = try #require(catalogue.product(block.productID))
                let h = try #require(catalogue.shape(of: product)).height / 100
                let span = block.right - block.left
                let x0 = -spec.width / 2 + (block.left + 0.15 * span) / 100
                let x1 = -spec.width / 2 + (block.right - 0.15 * span) / 100
                let a = view.project(SIMD3(x0, levels[i].goodsY + h * 0.7, spec.faceZ), size: size)
                let b = view.project(SIMD3(x1, levels[i].goodsY + h * 0.2, spec.faceZ), size: size)
                seen.append(Seen(shelf: i, rendered: R.dominant(data, from: a, to: b), options: try palette(catalogue, block.productID)))
            }
        }
        check(seen, "wall bay \(bay)")

        // (c) The picture is on the card in the right cell and region: on the first flask the glass tint shows
        // near the top of the body, the label band (the accent) below it. A wrong cell or a cropped or half-height
        // region lands on other colours.
        let firstBlock = plan.shelves[0].bayBlocks(bay: bay, of: 2)[0]
        let first = try #require(ShelfPacker.pack(shelf: PlanogramShelf(blocks: [firstBlock]),
                                                  width: spec.width * 100, catalogue: catalogue).facings.first)
        let flask = try #require(catalogue.product(firstBlock.productID))
        let colours = try #require(catalogue.colours(of: flask))
        let bodyH = 0.16 * 0.78
        let bodyTop = levels[0].goodsY + bodyH
        let x = -spec.width / 2 + first.centre / 100
        func sample(_ fromTop: Double) -> SIMD3<Double> {
            let p = view.project(SIMD3(x, bodyTop - fromTop * bodyH, spec.faceZ), size: size)
            return R.mean(data, from: (p.x - 0.5, p.y - 0.5), to: (p.x + 0.5, p.y + 0.5))
        }
        let glass = R.colour(colours.base), band = R.colour(colours.accent)
        let top = sample(0.10), mid = sample(0.5)
        #expect(R.distance(top, glass) < R.distance(top, band), "top of the flask is not glass: \(top)")
        #expect(R.distance(mid, band) < R.distance(mid, glass), "middle of the flask is not its label band: \(mid)")
    }

    @Test(.enabled(if: hasGPU)) func frontView_alcoholWall_bay0() async throws {
        try await Self.wallView("alcohol_wall_1", bay: 0)
    }

    @Test(.enabled(if: hasGPU)) func frontView_alcoholWall_bay1() async throws {
        try await Self.wallView("alcohol_wall_2", bay: 1)
    }

    @Test(.enabled(if: hasGPU)) func frontView_tillRack() async throws {
        let (root, _) = try Self.scene("checkout_1")
        let plan = try #require(Self.catalogue.planogram(forLabel: "Till impulse"))
        let centre = SIMD3<Double>(TillZone.rackCentreX, 1.12, 0.3)
        let cam = R.camera(target: centre, distance: 1.0)
        let image = try await OffscreenRenderer().render(root: root, camera: cam, size: (Self.size, Self.size))
        try R.write(image, "frontview-tillrack.png")
        let data = R.pixels(image)
        let view = R.View(camera: cam)

        // Bars highest and furthest back, gum lowest and nearest: the tiers' centre rows run down the picture.
        var rows: [Double] = []
        var seen: [Seen] = []
        for (i, shelf) in plan.shelves.enumerated() {
            let goodsY = TillZone.tierPlateY(i) + TillZone.tierPlate
            let faceZ = TillZone.tierFrontZ(i) - 0.002
            rows.append(view.project(SIMD3(TillZone.rackCentreX, goodsY + 0.03, faceZ), size: Self.size).y)
            let packed = ShelfPacker.pack(shelf: shelf, width: TillZone.rackWidth * 100, catalogue: Self.catalogue)
            for block in packed.blocks {
                let span = block.right - block.left
                let x0 = TillZone.rackCentreX - TillZone.rackWidth / 2 + (block.left + 0.2 * span) / 100
                let x1 = TillZone.rackCentreX - TillZone.rackWidth / 2 + (block.right - 0.2 * span) / 100
                let top = goodsY + (try #require(Self.catalogue.product(block.productID).flatMap { Self.catalogue.shape(of: $0) })).height / 100
                let a = view.project(SIMD3(x0, top - 0.005, faceZ), size: Self.size)
                let b = view.project(SIMD3(x1, goodsY + 0.01, faceZ), size: Self.size)
                // The block's price label stands on the rail, clear above the trays in front: it reads as cream paper.
                let labelX = TillZone.rackCentreX - TillZone.rackWidth / 2 + block.firstCentre / 100
                let labelY = Self.plateYForLabel(i)
                let l = view.project(SIMD3(labelX, labelY, TillZone.tierFrontZ(i) + TillZone.rackRailDepth + 0.001), size: Self.size)
                let paper = R.mean(data, from: (l.x - 6, l.y - 1), to: (l.x + 6, l.y + 1))
                #expect(paper.min() > 110 && paper.max() - paper.min() < 45, "tier \(i) label is hidden or not paper: \(paper)")
                seen.append(Seen(shelf: i, rendered: R.dominant(data, from: a, to: b),
                                 options: try Self.palette(Self.catalogue, block.productID)))
            }
        }
        for (a, b) in zip(rows, rows.dropFirst()) { #expect(a < b, "tier rows are out of order \(rows)") }
        Self.check(seen, "till rack")
        // The four bar brands must not all look alike: the first and last are clearly different, and no two
        // neighbours are the same colour.
        let bars = seen.filter { $0.shelf == 0 }.map(\.rendered)
        #expect(bars.count == 4)
        #expect(R.distance(bars[0], bars[3]) > 0.15, "bars one and four look alike: \(bars)")
        for (x, y) in zip(bars, bars.dropFirst()) { #expect(R.distance(x, y) > 0.05, "neighbouring bars look alike: \(bars)") }
    }

    @Test(.enabled(if: hasGPU)) func frontView_tobacco() async throws {
        let (root, _) = try Self.scene("cigarette_cabinet_1")
        let cam = R.camera(target: SIMD3(0, 1.0, 0), distance: 2.2 * 1.9)
        let image = try await OffscreenRenderer().render(root: root, camera: cam, size: (Self.size, Self.size))
        try R.write(image, "frontview-tobacco.png")
        let data = R.pixels(image)
        let view = R.View(camera: cam)
        let c = Brand.palette
        for x in [-TillZone.boardCentreX, TillZone.boardCentreX] {
            // Above the board the door is solid grey, not the pale glass of before.
            let d = view.project(SIMD3(x, 1.7, 0.221), size: Self.size)
            let door = R.mean(data, from: (d.x - 2, d.y - 2), to: (d.x + 2, d.y + 2))
            #expect(R.distance(door, R.colour(c.primary)) < R.distance(door, R.colour(c.skyPastel)), "door reads as glass: \(door)")
            // The lower part of the board has no text, so it reads as the cream board.
            let b = view.project(SIMD3(x, 1.08, 0.231), size: Self.size)
            let board = R.mean(data, from: (b.x - 2, b.y - 1), to: (b.x + 2, b.y + 1))
            #expect(R.distance(board, R.colour(c.cream)) < R.distance(board, R.colour(c.primary)), "board is not cream: \(board)")
        }
    }
}
