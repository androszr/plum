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
    public static func platformColor(_ c: BrandColor) -> PlatformColor {
        PlatformColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
    }

    public static func material(for m: SurfaceMaterial) -> RealityKit.Material? {
        switch m {
        case .none:
            return nil
        case let .solid(color, roughness):
            return SimpleMaterial(color: platformColor(color), roughness: .float(Float(roughness)), isMetallic: false)
        case let .emissive(color):
            return UnlitMaterial(color: platformColor(color))
        case let .glass(color, opacity):
            var pbr = PhysicallyBasedMaterial()
            pbr.baseColor = .init(tint: platformColor(color))
            pbr.roughness = .init(floatLiteral: 0.1)
            pbr.blending = .transparent(opacity: .init(floatLiteral: Float(opacity)))
            return pbr
        }
    }
}
