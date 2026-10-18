import Foundation
import RealityKit
import StoreSimKit
#if canImport(AppKit)
import AppKit
public typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
public typealias PlatformColor = UIColor
#endif

public enum Materials {
    @MainActor private static var cache: [CacheKey: RealityKit.Material] = [:]

    private struct CacheKey: Hashable {
        var material: SurfaceMaterial
        var hasPicture: Bool
    }

    public static func platformColor(_ c: BrandColor) -> PlatformColor {
        PlatformColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
    }

    @MainActor
    public static func material(for m: SurfaceMaterial) -> RealityKit.Material? {
        make(m, loader: nil)
    }

    /// `loader` supplies a picture for `.textured`. Without one, that case is the fallback colour.
    @MainActor
    public static func make(_ m: SurfaceMaterial, loader: ModelLoader?) -> RealityKit.Material? {
        switch m {
        case .none:
            return nil
        case let .solid(color, roughness):
            let key = CacheKey(material: m, hasPicture: false)
            if let hit = cache[key] { return hit }
            let made = SimpleMaterial(color: platformColor(color), roughness: .float(Float(roughness)), isMetallic: false)
            cache[key] = made
            return made
        case let .emissive(color):
            return UnlitMaterial(color: platformColor(color))
        case let .glass(color, opacity):
            var pbr = PhysicallyBasedMaterial()
            pbr.baseColor = .init(tint: platformColor(color))
            pbr.roughness = .init(floatLiteral: 0.1)
            pbr.blending = .transparent(opacity: .init(floatLiteral: Float(opacity)))
            return pbr
        case let .textured(name, fallback):
            if let loader, let texture = try? loader.texture(name) {
                var unlit = UnlitMaterial()
                unlit.color = .init(tint: .white, texture: .init(texture))
                return unlit
            }
            return UnlitMaterial(color: platformColor(fallback))
        case let .atlas(name, region, fallback):
            let texture = loader.flatMap { try? $0.texture(name) }
            let key = CacheKey(material: m, hasPicture: texture != nil)
            if let hit = cache[key] { return hit }
            let made: RealityKit.Material
            if let texture {
                var pbr = PhysicallyBasedMaterial()
                pbr.baseColor = .init(tint: .white, texture: .init(texture))
                pbr.roughness = .init(floatLiteral: 0.6)
                // `AtlasRegion.v` counts up from the bottom of the picture; RealityKit's transform measures the
                // offset from the picture's top (after the plane's own flip), so convert once here.
                pbr.textureCoordinateTransform.offset = SIMD2<Float>(Float(region.u), Float(1 - region.v - region.height))
                pbr.textureCoordinateTransform.scale = SIMD2<Float>(Float(region.width), Float(region.height))
                made = pbr
            } else {
                made = SimpleMaterial(color: platformColor(fallback), roughness: .float(0.6), isMetallic: false)
            }
            cache[key] = made
            return made
        }
    }
}
