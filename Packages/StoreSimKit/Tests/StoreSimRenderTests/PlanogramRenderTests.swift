import CoreGraphics
import Foundation
import ImageIO
import RealityKit
import Testing
import UniformTypeIdentifiers
import simd
import StoreSimKit
@testable import StoreSimRender

/// Headless front views of the five concept-page bays, checked against the planogram's shelf order and
/// block order with the same pinhole model the renderer uses (45 degree vertical field of view).
@MainActor
@Suite struct PlanogramRenderTests {
    static let size = 512
    static let catalogue = PlanogramCatalogue.shipped

    struct View {
        var eye: SIMD3<Double>
        var forward: SIMD3<Double>
        var right: SIMD3<Double>
        var up: SIMD3<Double>

        init(camera: OrbitCamera) {
            eye = camera.position
            forward = simd_normalize(camera.target - camera.position)
            right = simd_normalize(simd_cross(forward, SIMD3(0, 1, 0)))
            up = simd_cross(right, forward)
        }

        /// Pixel (x right, y down) of a world point.
        func project(_ p: SIMD3<Double>, size: Int) -> (x: Double, y: Double) {
            let v = p - eye
            let depth = simd_dot(v, forward)
            let t = tan(22.5 * Double.pi / 180)
            let nx = simd_dot(v, right) / depth / t
            let ny = simd_dot(v, up) / depth / t
            return ((nx * 0.5 + 0.5) * Double(size), (0.5 - ny * 0.5) * Double(size))
        }
    }

    static func camera(target: SIMD3<Double>, distance: Double) -> OrbitCamera {
        let limits = CameraLimits(distance: 0.2...200, pitch: (5 * .pi / 180)...(80 * .pi / 180))
        return OrbitCamera(target: target, distance: distance, yaw: 0, pitch: 5 * .pi / 180, limits: limits)
    }

    static func scene(_ fixtureID: String) throws -> (root: Entity, fixture: Fixture) {
        let fixture = try #require(StoreLayout.plumCorner.fixtures.first { $0.id == fixtureID })
        let variant = ModelVariant.index(of: fixture, in: StoreLayout.plumCorner)
        var shell = FixtureBuilders.builder(for: fixture.kind).build(fixture, detail: .full, variant: variant)
        // The glass doors would tint every pack; the view is of the planogram, not of the glass.
        shell.children.removeAll { $0.name.hasPrefix("door_") || $0.name.hasPrefix("handle_") }
        let goods = Merchandiser.build(fixture, detail: .full, variant: variant)
        let urls = try FileManager.default.contentsOfDirectory(at: BriefSpec.modelsDirectory(), includingPropertiesForKeys: nil)
        let loader = ModelLoader(catalogue: AssetCatalogue(modelURLs: urls))
        let subject = EntityBuilder.entity(for: SceneNode(name: "lone", children: [shell, goods]), loader: loader)
        // Directional fills only: a sun would cast the shelves' shadows onto the goods below them.
        let key = SceneNode(name: "key", shape: .light(.fill(intensity: 3000, direction: SIMD3(-0.2, -0.3, -1))))
        let fill = SceneNode(name: "sky_fill", shape: .light(.fill(intensity: 1500, direction: SIMD3(0.4, -0.6, -0.8))))
        let lights = SceneNode(name: "lighting", children: [key, fill])
        let root = Entity()
        root.addChild(subject)
        root.addChild(EntityBuilder.entity(for: lights,
                                           loader: ModelLoader(catalogue: .empty)))
        return (root, fixture)
    }

    static func pixels(_ image: CGImage) -> [UInt8] {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return data
    }

    static func write(_ image: CGImage, _ name: String) throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("storesim-snapshots")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
        print("SNAPSHOT \(url.path)")
    }

    /// The dominant colour (0...255 per channel) of an inclusive pixel rectangle: the mean of the most common
    /// 16-level bucket. A pack front is mostly one colour, with a brand band, a window and some lettering on
    /// top, so the mode finds that colour where the mean would blend the lot.
    static func dominant(_ data: [UInt8], width: Int, x0: Int, x1: Int, y0: Int, y1: Int) -> SIMD3<Double> {
        var buckets: [Int: (n: Double, sum: SIMD3<Double>)] = [:]
        guard x0 <= x1, y0 <= y1 else { return SIMD3(0, 0, 0) }
        for y in y0...y1 {
            for x in x0...x1 {
                let o = (y * width + x) * 4
                if data[o + 3] < 255 { continue }
                let key = Int(data[o] >> 4) << 8 | Int(data[o + 1] >> 4) << 4 | Int(data[o + 2] >> 4)
                var entry = buckets[key] ?? (0, SIMD3(0, 0, 0))
                entry.n += 1
                entry.sum += SIMD3(Double(data[o]), Double(data[o + 1]), Double(data[o + 2]))
                buckets[key] = entry
            }
        }
        guard let top = buckets.values.max(by: { $0.n < $1.n }) else { return SIMD3(0, 0, 0) }
        return top.sum / top.n
    }

    /// The dominant colour of a rendered rectangle spanned by two projected corners.
    static func dominant(_ data: [UInt8], from a: (x: Double, y: Double), to b: (x: Double, y: Double)) -> SIMD3<Double> {
        dominant(data, width: size,
                 x0: max(0, Int(min(a.x, b.x).rounded(.up))), x1: min(size - 1, Int(max(a.x, b.x).rounded(.down))),
                 y0: max(0, Int(min(a.y, b.y).rounded(.up))), y1: min(size - 1, Int(max(a.y, b.y).rounded(.down))))
    }

    static func linear(_ v: Double) -> Double {
        let c = v / 255
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    static func srgb(_ l: Double) -> Double {
        let c = min(max(l, 0), 1)
        return 255 * (c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055)
    }

    /// Mean colour of a small pixel rectangle.
    static func mean(_ data: [UInt8], from a: (x: Double, y: Double), to b: (x: Double, y: Double)) -> SIMD3<Double> {
        let x0 = max(0, Int(min(a.x, b.x).rounded(.up))), x1 = min(size - 1, Int(max(a.x, b.x).rounded(.down)))
        let y0 = max(0, Int(min(a.y, b.y).rounded(.up))), y1 = min(size - 1, Int(max(a.y, b.y).rounded(.down)))
        var sum = SIMD3<Double>(0, 0, 0)
        var n = 0.0
        guard x0 <= x1, y0 <= y1 else { return sum }
        for y in y0...y1 {
            for x in x0...x1 {
                let o = (y * size + x) * 4
                sum += SIMD3(Double(data[o]), Double(data[o + 1]), Double(data[o + 2]))
                n += 1
            }
        }
        return sum / max(n, 1)
    }

    static func colour(_ c: BrandColor) -> SIMD3<Double> { SIMD3(c.r, c.g, c.b) * 255 }

    /// Distance in 8-bit sRGB, scaled to 0...1.
    static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        simd_length(a - b) / 441.7
    }

    /// Renders one bay and checks shelf order and block order.
    static func frontView(fixtureID: String, bay: String, file: String) async throws {
        let (root, fixture) = try scene(fixtureID)
        let plan = try #require(catalogue.planogram(forLabel: fixture.label))
        #expect(fixture.label == bay)
        let spec = try #require(Merchandiser.bay(for: fixture.kind))
        let levels = try #require(ShelfStacker.stack(planogram: plan, interior: spec.interior, catalogue: catalogue))
        let height = fixture.kind.verticalExtent.upperBound
        let cam = camera(target: SIMD3(0, height / 2, 0), distance: 2.2 * height)
        let image = try await OffscreenRenderer().render(root: root, camera: cam, size: (size, size))
        try write(image, "frontview-\(file).png")
        #expect(image.width == size && image.height == size)
        let data = pixels(image)
        let view = View(camera: cam)

        // (a) The shelf rows appear top to bottom in planogram order.
        var rows: [Double] = []
        for (i, shelf) in plan.shelves.enumerated() {
            var tallest = 0.0
            for block in shelf.blocks {
                if let product = catalogue.product(block.productID), let shape = catalogue.shape(of: product) {
                    tallest = max(tallest, shape.height)
                }
            }
            let mid = SIMD3<Double>(0, levels[i].goodsY + tallest / 200, spec.faceZ)
            rows.append(view.project(mid, size: size).y)
        }
        for (a, b) in zip(rows, rows.dropFirst()) { #expect(a < b, "\(bay): shelf rows are out of order \(rows)") }

        // (b) Each block's span reads as its own colour, so the blocks run left to right as planned. The light
        // multiplies every flat colour by the same per-channel gain, so the gain is estimated from all the blocks
        // of the view (the median of rendered over expected, in linear light) and then every block has to sit
        // nearer its own predicted colour than any other block's on its shelf.
        struct Seen { var shelf: Int; var block: PackedBlock; var rendered: SIMD3<Double>; var expected: SIMD3<Double> }
        var seen: [Seen] = []
        for (i, shelf) in plan.shelves.enumerated() {
            let packed = ShelfPacker.pack(shelf: shelf, width: spec.width * 100, catalogue: catalogue)
            for block in packed.blocks {
                let product = try #require(catalogue.product(block.productID))
                let shape = try #require(catalogue.shape(of: product))
                let expected = Self.colour(try #require(catalogue.colours(of: product)).base)
                let packHeight = shape.height / 100
                let y0 = levels[i].goodsY + packHeight * 0.10
                let y1 = levels[i].goodsY + packHeight * 0.90
                let span = block.right - block.left
                let x0 = -spec.width / 2 + (block.left + 0.15 * span) / 100
                let x1 = -spec.width / 2 + (block.right - 0.15 * span) / 100
                let topLeft = view.project(SIMD3<Double>(x0, y1, spec.faceZ), size: size)
                let bottomRight = view.project(SIMD3<Double>(x1, y0, spec.faceZ), size: size)
                seen.append(Seen(shelf: i, block: block, rendered: dominant(data, from: topLeft, to: bottomRight), expected: expected))
            }
        }
        var gain = SIMD3<Double>(1, 1, 1)
        for channel in 0..<3 {
            let ratios = seen.compactMap { s -> Double? in
                let e = linear(s.expected[channel])
                return e > 0.05 ? linear(s.rendered[channel]) / e : nil
            }.sorted()
            if !ratios.isEmpty { gain[channel] = ratios[ratios.count / 2] }
        }
        func predicted(_ e: SIMD3<Double>) -> SIMD3<Double> {
            SIMD3(srgb(linear(e.x) * gain.x), srgb(linear(e.y) * gain.y), srgb(linear(e.z) * gain.z))
        }
        for s in seen {
            // Two blocks whose colours are nearly the same (dark chocolate and cocoa) cannot be told apart by
            // colour, so only blocks with a clearly different colour count as "another block".
            let own = distance(s.rendered, predicted(s.expected))
            let others = seen.filter { $0.shelf == s.shelf && distance(predicted($0.expected), predicted(s.expected)) > 0.1 }
                .map { distance(s.rendered, predicted($0.expected)) }
            #expect(own <= (others.min() ?? 1) + 0.02,
                    "\(bay) shelf \(s.shelf) block \(s.block.index) (\(s.block.productID)) reads as another block: rendered \(s.rendered) expected \(predicted(s.expected)) gain \(gain)")
        }
    }

    @Test(.enabled(if: hasGPU)) func frontView_crisps() async throws {
        try await Self.frontView(fixtureID: "gondola_2", bay: "Crisps", file: "crisps")
    }
    @Test(.enabled(if: hasGPU)) func frontView_sweets() async throws {
        try await Self.frontView(fixtureID: "gondola_3", bay: "Sweets", file: "sweets")
    }
    @Test(.enabled(if: hasGPU)) func frontView_biscuits() async throws {
        try await Self.frontView(fixtureID: "gondola_4", bay: "Biscuits", file: "biscuits")
    }
    @Test(.enabled(if: hasGPU)) func frontView_softDrinks() async throws {
        try await Self.frontView(fixtureID: "wall_fridge_2", bay: "Soft drinks", file: "softdrinks")
    }

    /// The beer bay also proves the picture is not upside down: the first can on the top shelf has its silver
    /// lid at the top of its front card, and a thin rim at the bottom.
    @Test(.enabled(if: hasGPU)) func frontView_beer() async throws {
        try await Self.frontView(fixtureID: "wall_fridge_4", bay: "Beer", file: "beer")

        let (root, fixture) = try Self.scene("wall_fridge_4")
        let plan = try #require(Self.catalogue.planogram(forLabel: fixture.label))
        let spec = try #require(Merchandiser.bay(for: fixture.kind))
        let levels = try #require(ShelfStacker.stack(planogram: plan, interior: spec.interior, catalogue: Self.catalogue))
        let packed = ShelfPacker.pack(shelf: plan.shelves[0], width: spec.width * 100, catalogue: Self.catalogue)
        let first = try #require(packed.facings.first)
        let product = try #require(Self.catalogue.product(plan.shelves[0].blocks[0].productID))
        let shape = try #require(Self.catalogue.shape(of: product))
        let colours = try #require(Self.catalogue.colours(of: product))
        let x = -spec.width / 2 + first.centre / 100
        let canHeight = shape.height / 100
        let centre = SIMD3<Double>(x, levels[0].goodsY + canHeight / 2, spec.faceZ)
        let cam = Self.camera(target: centre, distance: 0.5)
        let image = try await OffscreenRenderer().render(root: root, camera: cam, size: (Self.size, Self.size))
        try Self.write(image, "frontview-beer-closeup.png")
        let data = Self.pixels(image)
        let view = View(camera: cam)
        let silver = Self.colour(Brand.packaging.canSilver)
        let green = Self.colour(colours.base)
        func probe(_ y: Double) -> SIMD3<Double> {
            let p = view.project(SIMD3<Double>(x, y, spec.faceZ), size: Self.size)
            return Self.mean(data, from: (p.x - 3, p.y - 1), to: (p.x + 3, p.y + 1))
        }
        let top = probe(levels[0].goodsY + canHeight - 0.006)
        let bottom = probe(levels[0].goodsY + 0.004)
        #expect(Self.distance(top, silver) < Self.distance(top, green), "the top of the can front is not silver: \(top)")
        #expect(Self.distance(bottom, green) < Self.distance(bottom, silver), "the bottom of the can front is silver: \(bottom)")
    }
}
