import Foundation

/// The logo described as data: a rounded body, a leaf and a highlight.
public struct PlumMark: Sendable {
    public var body: BrandColor
    public var leaf: BrandColor
    public var highlight: BrandColor
    public var bodyRadius: Double
    public var leafAngle: Double
}

public struct Palette: Sendable {
    public var primary: BrandColor
    public var primaryDeep: BrandColor
    public var primaryLight: BrandColor
    public var accentMint: BrandColor
    public var mintDeep: BrandColor
    public var cream: BrandColor
    public var charcoal: BrandColor
    public var priceRailYellow: BrandColor
    public var woodLight: BrandColor
    public var tileWhite: BrandColor
    public var asphalt: BrandColor
    public var sidewalk: BrandColor
    public var grassPastel: BrandColor
    public var skyPastel: BrandColor
    public var warmLamp: BrandColor

    /// Every colour, in declaration order (used by the asset brief test).
    public var all: [BrandColor] {
        [primary, primaryDeep, primaryLight, accentMint, mintDeep, cream, charcoal,
         priceRailYellow, woodLight, tileWhite, asphalt, sidewalk, grassPastel, skyPastel, warmLamp]
    }
}

/// The only file allowed a colour literal or the brand name.
public enum Brand {
    public static let name = "Plum"
    public static let tagline = "Fresh. Close. Yours."

    public static let palette = Palette(
        primary: BrandColor(rgb: 0x6B2D8C),
        primaryDeep: BrandColor(rgb: 0x3E1A5C),
        primaryLight: BrandColor(rgb: 0xB58BD6),
        accentMint: BrandColor(rgb: 0x7EE0B5),
        mintDeep: BrandColor(rgb: 0x2FA37A),
        cream: BrandColor(rgb: 0xFFF6E5),
        charcoal: BrandColor(rgb: 0x2B2B33),
        priceRailYellow: BrandColor(rgb: 0xF7D23E),
        woodLight: BrandColor(rgb: 0xD9B382),
        tileWhite: BrandColor(rgb: 0xF2F4F5),
        asphalt: BrandColor(rgb: 0x5A5D66),
        sidewalk: BrandColor(rgb: 0xC9C6BE),
        grassPastel: BrandColor(rgb: 0xA8D8A0),
        skyPastel: BrandColor(rgb: 0xBFE3F5),
        warmLamp: BrandColor(rgb: 0xFFD9A0)
    )

    public static let mark = PlumMark(
        body: palette.primary,
        leaf: palette.mintDeep,
        highlight: palette.primaryLight,
        bodyRadius: 0.42,
        leafAngle: 35
    )
}
