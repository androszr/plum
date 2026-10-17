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
        primary: BrandColor(rgb: 0x4A4E57),
        primaryDeep: BrandColor(rgb: 0x2E1A47),
        primaryLight: BrandColor(rgb: 0xD9D6CF),
        accentMint: BrandColor(rgb: 0xB9C6B0),
        mintDeep: BrandColor(rgb: 0x6E8B74),
        cream: BrandColor(rgb: 0xFAFAF7),
        charcoal: BrandColor(rgb: 0x22252B),
        priceRailYellow: BrandColor(rgb: 0xE9C46A),
        woodLight: BrandColor(rgb: 0xC9A27E),
        tileWhite: BrandColor(rgb: 0xF4F4F2),
        asphalt: BrandColor(rgb: 0x4B4F57),
        sidewalk: BrandColor(rgb: 0xBDBAB3),
        grassPastel: BrandColor(rgb: 0xB7C4A8),
        skyPastel: BrandColor(rgb: 0xE6EAEE),
        warmLamp: BrandColor(rgb: 0xFFE2B8)
    )

    public static let mark = PlumMark(
        body: palette.primary,
        leaf: palette.mintDeep,
        highlight: palette.primaryLight,
        bodyRadius: 0.42,
        leafAngle: 35
    )
}
