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

/// Packaging colours for the invented products on the shelves. Names are the keys the
/// planogram catalogue uses (`colourCodes`); the asset brief's `## Packaging palette` lists the same.
public struct PackagingPalette: Sendable {
    public var paprikaBase: BrandColor
    public var paprikaAccent: BrandColor
    public var onionBase: BrandColor
    public var onionAccent: BrandColor
    public var saltedBase: BrandColor
    public var saltedAccent: BrandColor
    public var cheeseBase: BrandColor
    public var cheeseAccent: BrandColor
    public var crabBase: BrandColor
    public var crabAccent: BrandColor
    public var bbqBase: BrandColor
    public var bbqAccent: BrandColor
    public var maxBase: BrandColor
    public var maxAccent: BrandColor
    public var maxRAccent: BrandColor
    public var puffOBase: BrandColor
    public var puffOAccent: BrandColor
    public var puffBBase: BrandColor
    public var puffBAccent: BrandColor
    public var milkBase: BrandColor
    public var milkAccent: BrandColor
    public var darkBase: BrandColor
    public var darkAccent: BrandColor
    public var nutBase: BrandColor
    public var nutAccent: BrandColor
    public var mintBase: BrandColor
    public var pilsBase: BrandColor
    public var pilsAccent: BrandColor
    public var wheatBase: BrandColor
    public var wheatAccent: BrandColor
    public var gumBase: BrandColor
    public var gumAccent: BrandColor
    public var waferBase: BrandColor
    public var waferAccent: BrandColor
    public var cocoaBase: BrandColor
    public var cocoaAccent: BrandColor
    public var oatBase: BrandColor
    public var oatAccent: BrandColor
    public var colaBase: BrandColor
    public var colaAccent: BrandColor
    public var zeroBase: BrandColor
    public var zeroAccent: BrandColor
    public var lemonBase: BrandColor
    public var lemonAccent: BrandColor
    public var orangeAccent: BrandColor
    public var voltBase: BrandColor
    public var voltAccent: BrandColor
    public var voltBBase: BrandColor
    public var voltBAccent: BrandColor
    public var voltWBase: BrandColor
    public var voltWAccent: BrandColor
    public var waterBase: BrandColor
    public var waterAccent: BrandColor
    public var waterGBase: BrandColor
    public var waterGAccent: BrandColor
    public var lagerBase: BrandColor
    public var dark2Base: BrandColor
    public var dark2Accent: BrandColor
    public var canSilver: BrandColor
    public var canRim: BrandColor
    public var crispWindow: BrandColor
    public var puffWindow: BrandColor
    public var lagerGlass: BrandColor
    public var brownGlass: BrandColor
    public var clearPet: BrandColor

    /// Every colour, in declaration order (used by the asset brief test).
    public var all: [BrandColor] {
        [
            paprikaBase,
            paprikaAccent,
            onionBase,
            onionAccent,
            saltedBase,
            saltedAccent,
            cheeseBase,
            cheeseAccent,
            crabBase,
            crabAccent,
            bbqBase,
            bbqAccent,
            maxBase,
            maxAccent,
            maxRAccent,
            puffOBase,
            puffOAccent,
            puffBBase,
            puffBAccent,
            milkBase,
            milkAccent,
            darkBase,
            darkAccent,
            nutBase,
            nutAccent,
            mintBase,
            pilsBase,
            pilsAccent,
            wheatBase,
            wheatAccent,
            gumBase,
            gumAccent,
            waferBase,
            waferAccent,
            cocoaBase,
            cocoaAccent,
            oatBase,
            oatAccent,
            colaBase,
            colaAccent,
            zeroBase,
            zeroAccent,
            lemonBase,
            lemonAccent,
            orangeAccent,
            voltBase,
            voltAccent,
            voltBBase,
            voltBAccent,
            voltWBase,
            voltWAccent,
            waterBase,
            waterAccent,
            waterGBase,
            waterGAccent,
            lagerBase,
            dark2Base,
            dark2Accent,
            canSilver,
            canRim,
            crispWindow,
            puffWindow,
            lagerGlass,
            brownGlass,
            clearPet
        ]
    }

    /// Every colour name, in the same order as `all`.
    public static let names: [String] = [
        "paprikaBase",
        "paprikaAccent",
        "onionBase",
        "onionAccent",
        "saltedBase",
        "saltedAccent",
        "cheeseBase",
        "cheeseAccent",
        "crabBase",
        "crabAccent",
        "bbqBase",
        "bbqAccent",
        "maxBase",
        "maxAccent",
        "maxRAccent",
        "puffOBase",
        "puffOAccent",
        "puffBBase",
        "puffBAccent",
        "milkBase",
        "milkAccent",
        "darkBase",
        "darkAccent",
        "nutBase",
        "nutAccent",
        "mintBase",
        "pilsBase",
        "pilsAccent",
        "wheatBase",
        "wheatAccent",
        "gumBase",
        "gumAccent",
        "waferBase",
        "waferAccent",
        "cocoaBase",
        "cocoaAccent",
        "oatBase",
        "oatAccent",
        "colaBase",
        "colaAccent",
        "zeroBase",
        "zeroAccent",
        "lemonBase",
        "lemonAccent",
        "orangeAccent",
        "voltBase",
        "voltAccent",
        "voltBBase",
        "voltBAccent",
        "voltWBase",
        "voltWAccent",
        "waterBase",
        "waterAccent",
        "waterGBase",
        "waterGAccent",
        "lagerBase",
        "dark2Base",
        "dark2Accent",
        "canSilver",
        "canRim",
        "crispWindow",
        "puffWindow",
        "lagerGlass",
        "brownGlass",
        "clearPet"
    ]

    public var byName: [String: BrandColor] {
        Dictionary(uniqueKeysWithValues: zip(Self.names, all))
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

    public static let packaging = PackagingPalette(
        paprikaBase: BrandColor(rgb: 0xD8331F),
        paprikaAccent: BrandColor(rgb: 0xF4B23A),
        onionBase: BrandColor(rgb: 0x2E8B3C),
        onionAccent: BrandColor(rgb: 0xE8E36A),
        saltedBase: BrandColor(rgb: 0xF2C230),
        saltedAccent: BrandColor(rgb: 0x1D56A8),
        cheeseBase: BrandColor(rgb: 0xF28C1F),
        cheeseAccent: BrandColor(rgb: 0x7A3A12),
        crabBase: BrandColor(rgb: 0xE25A78),
        crabAccent: BrandColor(rgb: 0x1E3F8F),
        bbqBase: BrandColor(rgb: 0x5A2A18),
        bbqAccent: BrandColor(rgb: 0xF2A33A),
        maxBase: BrandColor(rgb: 0x1C1C1E),
        maxAccent: BrandColor(rgb: 0x5BC84A),
        maxRAccent: BrandColor(rgb: 0xE8462B),
        puffOBase: BrandColor(rgb: 0xF07D18),
        puffOAccent: BrandColor(rgb: 0x2A65C8),
        puffBBase: BrandColor(rgb: 0x2A55B8),
        puffBAccent: BrandColor(rgb: 0xF5D02C),
        milkBase: BrandColor(rgb: 0x7E5AB0),
        milkAccent: BrandColor(rgb: 0xF4F1FA),
        darkBase: BrandColor(rgb: 0x4A2A1A),
        darkAccent: BrandColor(rgb: 0xD9B27A),
        nutBase: BrandColor(rgb: 0xC8962E),
        nutAccent: BrandColor(rgb: 0x5A2E10),
        mintBase: BrandColor(rgb: 0x2EA58C),
        pilsBase: BrandColor(rgb: 0xC9A43A),
        pilsAccent: BrandColor(rgb: 0x1A2E5A),
        wheatBase: BrandColor(rgb: 0xE9D9A6),
        wheatAccent: BrandColor(rgb: 0x2E4E9A),
        gumBase: BrandColor(rgb: 0xE8316B),
        gumAccent: BrandColor(rgb: 0xFFE24A),
        waferBase: BrandColor(rgb: 0xC9372C),
        waferAccent: BrandColor(rgb: 0xF2E3C0),
        cocoaBase: BrandColor(rgb: 0x3B2416),
        cocoaAccent: BrandColor(rgb: 0xE7C77E),
        oatBase: BrandColor(rgb: 0xC9A76A),
        oatAccent: BrandColor(rgb: 0x5A3A1A),
        colaBase: BrandColor(rgb: 0xB5121B),
        colaAccent: BrandColor(rgb: 0xF2F2F2),
        zeroBase: BrandColor(rgb: 0x151515),
        zeroAccent: BrandColor(rgb: 0xD6121B),
        lemonBase: BrandColor(rgb: 0xE8D93A),
        lemonAccent: BrandColor(rgb: 0x2D8B3A),
        orangeAccent: BrandColor(rgb: 0x1E5CB0),
        voltBase: BrandColor(rgb: 0x1C2A22),
        voltAccent: BrandColor(rgb: 0x7BE04A),
        voltBBase: BrandColor(rgb: 0x1E3A8A),
        voltBAccent: BrandColor(rgb: 0xC9D6F2),
        voltWBase: BrandColor(rgb: 0xE9ECEF),
        voltWAccent: BrandColor(rgb: 0x1A1A1A),
        waterBase: BrandColor(rgb: 0xDCEFFA),
        waterAccent: BrandColor(rgb: 0x1E72C8),
        waterGBase: BrandColor(rgb: 0xD9F2E2),
        waterGAccent: BrandColor(rgb: 0x2E8B4A),
        lagerBase: BrandColor(rgb: 0x1E6A3A),
        dark2Base: BrandColor(rgb: 0x3A1F12),
        dark2Accent: BrandColor(rgb: 0xD6A84A),
        canSilver: BrandColor(rgb: 0xC9CDD2),
        canRim: BrandColor(rgb: 0xB8BCC2),
        crispWindow: BrandColor(rgb: 0xF2CF6A),
        puffWindow: BrandColor(rgb: 0xF6A43A),
        lagerGlass: BrandColor(rgb: 0x2F6B2A),
        brownGlass: BrandColor(rgb: 0x5A3412),
        clearPet: BrandColor(rgb: 0xCFE6F4)
    )

    public static let mark = PlumMark(
        body: palette.primary,
        leaf: palette.mintDeep,
        highlight: palette.primaryLight,
        bodyRadius: 0.42,
        leafAngle: 35
    )
}
