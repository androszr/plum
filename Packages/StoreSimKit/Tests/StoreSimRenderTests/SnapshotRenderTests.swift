import CoreGraphics
import Foundation
import ImageIO
import Metal
import RealityKit
import Testing
import UniformTypeIdentifiers
import StoreSimKit
@testable import StoreSimRender

/// Free of the main actor so the `.enabled(if:)` trait can read it.
let hasGPU = MTLCreateSystemDefaultDevice() != nil

@MainActor
@Suite struct SnapshotRenderTests {
    static func render(detail: DetailLevel, size: (Int, Int), name: String) async throws -> CGImage {
        let catalogue = AssetCatalogue.empty
        let node = SceneComposer.compose(layout: .plumCorner, detail: detail, catalogue: catalogue)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
        EntityBuilder.applyRoofOpacity(root: root, camera: .isoPreset)
        let image = try await OffscreenRenderer().render(root: root, camera: .isoPreset, size: size)
        try write(image, name: name)
        return image
    }

    static func write(_ image: CGImage, name: String) throws {
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

    /// Distinct colours and the centre/corner pixels (RGBA8).
    static func stats(_ image: CGImage) -> (distinct: Int, centre: [UInt8], corner: [UInt8]) {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var seen = Set<UInt32>()
        for i in stride(from: 0, to: data.count, by: 4) {
            seen.insert(UInt32(data[i]) << 16 | UInt32(data[i + 1]) << 8 | UInt32(data[i + 2]))
        }
        func px(_ x: Int, _ y: Int) -> [UInt8] { let o = (y * w + x) * 4; return Array(data[o..<o + 3]) }
        return (seen.count, px(w / 2, h / 2), px(2, 2))
    }

    @Test(.enabled(if: hasGPU))
    func fullDetailDesktopSnapshot() async throws {
        let image = try await Self.render(detail: .full, size: (512, 512), name: "desktop-full-512x512.png")
        #expect(image.width == 512 && image.height == 512)
        let s = Self.stats(image)
        #expect(s.distinct >= 16)
        #expect(s.centre != s.corner)
    }

    @Test(.enabled(if: hasGPU))
    func reducedDetailPhoneSnapshot() async throws {
        let image = try await Self.render(detail: .reduced, size: (390, 844), name: "phone-reduced-390x844.png")
        #expect(image.width == 390 && image.height == 844)
        let s = Self.stats(image)
        #expect(s.distinct >= 16)
        #expect(s.centre != s.corner)
    }
}
