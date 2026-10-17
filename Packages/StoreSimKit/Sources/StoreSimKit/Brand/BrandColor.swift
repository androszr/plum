import Foundation

/// A colour as plain numbers. No literals live here; the palette is `Brand.palette`.
public struct BrandColor: Hashable, Sendable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// Builds a colour from a packed RGB integer (used only by `Brand.swift`).
    public init(rgb: UInt32) {
        self.init(
            r: Double((rgb >> 16) & 0xFF) / 255,
            g: Double((rgb >> 8) & 0xFF) / 255,
            b: Double(rgb & 0xFF) / 255
        )
    }

    /// Six uppercase hex digits, no prefix.
    public var hex: String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "%02X%02X%02X", byte(r), byte(g), byte(b))
    }

    /// Multiplies the colour channels (alpha untouched) for cheap shading.
    public func scaled(by factor: Double) -> BrandColor {
        BrandColor(r: min(r * factor, 1), g: min(g * factor, 1), b: min(b * factor, 1), a: a)
    }
}
