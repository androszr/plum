import Foundation
import CoreGraphics
import Metal
import RealityKit
import StoreSimKit

public struct OffscreenRenderError: Error, CustomStringConvertible {
    public let description: String
}

/// Renders an entity tree to an image without a window.
@MainActor
public final class OffscreenRenderer {
    public init() {}

    public func render(root: Entity, camera: OrbitCamera, size: (Int, Int)) async throws -> CGImage {
        try await render(root: root, pose: camera.pose, size: size)
    }

    public func render(root: Entity, pose: CameraPose, size: (Int, Int)) async throws -> CGImage {
        guard let device = MTLCreateSystemDefaultDevice() else { throw OffscreenRenderError(description: "no GPU") }
        let renderer = try RealityRenderer()
        renderer.entities.append(root)

        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 45
        cam.camera.far = 400
        cam.look(at: SIMD3<Float>(pose.target), from: SIMD3<Float>(pose.eye), relativeTo: nil as Entity?)
        renderer.entities.append(cam)
        renderer.activeCamera = cam
        let sky = Brand.palette.skyPastel
        renderer.cameraSettings.colorBackground = .color(.init(
            red: CGFloat(sky.r), green: CGFloat(sky.g), blue: CGFloat(sky.b), alpha: 1))

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: size.0, height: size.1, mipmapped: false)
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        desc.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: desc) else {
            throw OffscreenRenderError(description: "texture allocation failed")
        }
        let output = try RealityRenderer.CameraOutput(RealityRenderer.CameraOutput.Descriptor.singleProjection(colorTexture: texture))

        // Two frames: the first lets materials and lights finish loading.
        for _ in 0..<2 {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                do {
                    try renderer.updateAndRender(deltaTime: 0.5, cameraOutput: output, whenScheduled: nil, onComplete: { _ in
                        cont.resume()
                    })
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
        return try Self.image(from: texture)
    }

    private static func image(from texture: MTLTexture) throws -> CGImage {
        let w = texture.width, h = texture.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        texture.getBytes(&bytes, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        let info = CGBitmapInfo.byteOrder32Little.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue))
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info, provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { throw OffscreenRenderError(description: "image creation failed") }
        return image
    }
}
