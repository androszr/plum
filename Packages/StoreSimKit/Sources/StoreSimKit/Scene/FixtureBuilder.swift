import Foundation

public protocol FixtureBuilding {
    /// Returns a group named after the fixture, built around the footprint centre at floor level.
    /// `variant` is the derived per-instance version (see `ModelVariant`); most kinds ignore it.
    static func build(_ fixture: Fixture, detail: DetailLevel, variant: Int) -> SceneNode
}

public extension FixtureBuilding {
    static func build(_ fixture: Fixture, detail: DetailLevel) -> SceneNode {
        build(fixture, detail: detail, variant: 0)
    }
}

public enum FixtureBuilders {
    public static func builder(for kind: FixtureKind) -> FixtureBuilding.Type {
        switch kind {
        case .gondolaShelf: GondolaShelfBuilder.self
        case .wallShelf: WallShelfBuilder.self
        case .endCap: EndCapBuilder.self
        case .wallFridge: WallFridgeBuilder.self
        case .dairyChiller: DairyChillerBuilder.self
        case .checkoutCounter: CheckoutCounterBuilder.self
        case .cigaretteCabinet: CigaretteCabinetBuilder.self
        case .hotFoodCounter: HotFoodCounterBuilder.self
        case .coffeeMachine: CoffeeMachineBuilder.self
        case .menuScreen: MenuScreenBuilder.self
        case .windowLedge: WindowLedgeBuilder.self
        case .highStool: HighStoolBuilder.self
        case .basketStack: BasketStackBuilder.self
        case .backRoomDoor: BackRoomDoorBuilder.self
        case .pendantLamp: PendantLampBuilder.self
        case .entranceDoor: EntranceDoorBuilder.self
        case .windowPoster: WindowPosterBuilder.self
        case .atmLocker: AtmLockerBuilder.self
        case .aFrameSign: AFrameSignBuilder.self
        case .litterBin: LitterBinBuilder.self
        case .bikeRack: BikeRackBuilder.self
        case .streetLamp: StreetLampBuilder.self
        case .tree: TreeBuilder.self
        case .parkedCar: ParkedCarBuilder.self
        case .selfCheckout: SelfCheckoutBuilder.self
        case .alcoholWall: AlcoholWallBuilder.self
        }
    }

    /// Minimum number of named descendants at full detail. The island shelf and the drinks fridge are
    /// carcasses; their goods are the merchandise layer, whose floor is pinned by `MerchandiseTests`.
    public static let minimumPartCount: [FixtureKind: Int] = [
        .gondolaShelf: 12, .wallShelf: 24, .endCap: 12, .wallFridge: 11, .dairyChiller: 14,
        .checkoutCounter: 16, .cigaretteCabinet: 8, .hotFoodCounter: 28, .coffeeMachine: 7,
        .menuScreen: 4, .windowLedge: 3, .highStool: 3, .basketStack: 6, .backRoomDoor: 4,
        .pendantLamp: 3, .entranceDoor: 6, .windowPoster: 2, .atmLocker: 6, .aFrameSign: 3,
        .litterBin: 3, .bikeRack: 4, .streetLamp: 4, .tree: 3, .parkedCar: 9,
        .selfCheckout: 11, .alcoholWall: 24,
    ]
}

/// Metres of a fixture's unrotated footprint.
func footprintMetres(_ kind: FixtureKind) -> (w: Double, d: Double) {
    (Double(kind.footprint.w) * cellSize, Double(kind.footprint.d) * cellSize)
}

func fixtureGroup(_ fixture: Fixture, _ parts: Parts) -> SceneNode {
    let fp = footprintMetres(fixture.kind)
    let ext = fixture.kind.verticalExtent
    return SceneNode(
        name: fixture.id,
        size: SIMD3(fp.w, ext.upperBound - ext.lowerBound, fp.d),
        children: parts.nodes
    )
}

/// Deterministic product rows: same fixture id, same rows; no `hashValue`.
enum ProductRows {
    enum Mode { case mixed, bottles, cartons }

    static func seed(_ id: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in id.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return h
    }

    private static func next(_ s: inout UInt64) -> UInt64 {
        s = s &* 6364136223846793005 &+ 1442695040888963407
        return s >> 33
    }

    static func colours() -> [BrandColor] {
        let c = Brand.palette
        return [c.primary, c.primaryLight, c.accentMint, c.mintDeep, c.priceRailYellow,
                c.cream, c.woodLight, c.warmLamp, c.charcoal]
    }

    /// One row of facings on one shelf. Reduced detail keeps every second facing.
    static func make(onShelf shelf: Int, y: Double, width: Double, z: Double, detail: DetailLevel,
                     seed: UInt64, prefix: String = "product", mode: Mode = .mixed,
                     variant: Int = 0) -> [SceneNode] {
        let palette = ModelVariant.productColours(variant)
        let facings = max(2, Int(width / 0.1))
        let pitch = width / Double(facings)
        var state = seed &+ UInt64(shelf) &* 7919
        var out: [SceneNode] = []
        for i in 0..<facings {
            _ = next(&state)  // keeps the colour and height draws where they were
            let colour = palette[Int(next(&state) % UInt64(palette.count))]
            let tall = 0.05 * Double(next(&state) % 3)
            guard detail.isFull || i % 2 == 0 else { continue }
            let x = -width / 2 + pitch * (Double(i) + 0.5)
            let name = "\(prefix)_\(shelf)_\(i)"
            let m = SurfaceMaterial.paint(colour)
            switch mode {
            case .cartons:
                out.append(SceneNode(name: name, shape: .box, size: SIMD3(pitch * 0.8, 0.14 + tall, 0.07),
                                     position: SIMD3(x, y + (0.14 + tall) / 2, z), material: m))
            case .bottles:
                out.append(SceneNode(name: name, shape: .cylinder, size: SIMD3(0.055, 0.16 + tall, 0.055),
                                     position: SIMD3(x, y + (0.16 + tall) / 2, z), material: m))
                if detail.isFull {
                    out.append(SceneNode(name: "\(name)_neck", shape: .cylinder, size: SIMD3(0.024, 0.05, 0.024),
                                         position: SIMD3(x, y + 0.16 + tall + 0.025, z), material: m))
                }
            case .mixed:
                switch ModelVariant.visibleShape(variant: variant, shelf: shelf, facing: i) {
                case .packet:
                    out.append(SceneNode(name: name, shape: .box, size: SIMD3(pitch * 0.75, 0.15 + tall, 0.035),
                                         position: SIMD3(x, y + (0.15 + tall) / 2, z), material: m))
                case .can:
                    out.append(SceneNode(name: name, shape: .cylinder, size: SIMD3(0.065, 0.11 + tall / 2, 0.065),
                                         position: SIMD3(x, y + (0.11 + tall / 2) / 2, z), material: m))
                case .bottle:
                    out.append(SceneNode(name: name, shape: .cylinder, size: SIMD3(0.06, 0.15 + tall, 0.06),
                                         position: SIMD3(x, y + (0.15 + tall) / 2, z), material: m))
                    if detail.isFull {
                        out.append(SceneNode(name: "\(name)_neck", shape: .cylinder, size: SIMD3(0.025, 0.05, 0.025),
                                             position: SIMD3(x, y + 0.15 + tall + 0.025, z), material: m))
                    }
                }
            }
        }
        return out
    }
}
