import Foundation

public enum FixtureKind: String, CaseIterable, Codable, Sendable {
    case gondolaShelf, wallShelf, endCap, wallFridge, dairyChiller, checkoutCounter
    case cigaretteCabinet, hotFoodCounter, coffeeMachine, menuScreen, windowLedge, highStool
    case basketStack, backRoomDoor, pendantLamp, entranceDoor, windowPoster, atmLocker
    case aFrameSign, litterBin, bikeRack, streetLamp, tree, parkedCar
    case selfCheckout, alcoholWall

    /// Footprint in cells at rotation zero (width along x, depth along z).
    public var footprint: GridSize {
        switch self {
        case .gondolaShelf: GridSize(w: 2, d: 2)
        case .wallShelf: GridSize(w: 2, d: 1)
        case .endCap: GridSize(w: 2, d: 1)
        case .wallFridge: GridSize(w: 2, d: 2)
        case .dairyChiller: GridSize(w: 3, d: 2)
        case .checkoutCounter: GridSize(w: 4, d: 2)
        case .cigaretteCabinet: GridSize(w: 3, d: 1)
        case .hotFoodCounter: GridSize(w: 5, d: 2)
        case .coffeeMachine: GridSize(w: 1, d: 1)
        case .menuScreen: GridSize(w: 5, d: 1)
        case .windowLedge: GridSize(w: 4, d: 1)
        case .highStool: GridSize(w: 1, d: 1)
        case .basketStack: GridSize(w: 1, d: 1)
        case .backRoomDoor: GridSize(w: 2, d: 1)
        case .pendantLamp: GridSize(w: 1, d: 1)
        case .entranceDoor: GridSize(w: 3, d: 1)
        case .windowPoster: GridSize(w: 2, d: 1)
        case .atmLocker: GridSize(w: 3, d: 1)
        case .aFrameSign: GridSize(w: 1, d: 1)
        case .litterBin: GridSize(w: 1, d: 1)
        case .bikeRack: GridSize(w: 3, d: 1)
        case .streetLamp: GridSize(w: 1, d: 1)
        case .tree: GridSize(w: 2, d: 2)
        case .parkedCar: GridSize(w: 9, d: 4)
        case .selfCheckout: GridSize(w: 2, d: 1)
        case .alcoholWall: GridSize(w: 4, d: 1)
        }
    }

    /// Kinds that hang from the ceiling or sit in a wall line take no floor cells.
    public var occupiesFloor: Bool {
        switch self {
        case .pendantLamp, .menuScreen, .windowPoster, .entranceDoor: false
        default: true
        }
    }

    public var zoneKinds: Set<Zone.Kind> {
        switch self {
        case .atmLocker, .aFrameSign, .litterBin, .bikeRack: [.sidewalk]
        case .streetLamp, .tree: [.sidewalk, .farSidewalk]
        case .parkedCar: [.parkingLane]
        default: [.storeInterior]
        }
    }

    public var displayName: String {
        switch self {
        case .gondolaShelf: "Shelf"
        case .wallShelf: "Wall shelf"
        case .endCap: "End cap"
        case .wallFridge: "Wall fridge"
        case .dairyChiller: "Dairy chiller"
        case .checkoutCounter: "Checkout"
        case .cigaretteCabinet: "Tobacco cabinet"
        case .hotFoodCounter: "Hot food counter"
        case .coffeeMachine: "Coffee machine"
        case .menuScreen: "Menu screen"
        case .windowLedge: "Window ledge"
        case .highStool: "High stool"
        case .basketStack: "Baskets"
        case .backRoomDoor: "Back room door"
        case .pendantLamp: "Pendant lamp"
        case .entranceDoor: "Entrance door"
        case .windowPoster: "Window poster"
        case .atmLocker: "Cash machine and parcel locker"
        case .aFrameSign: "A-frame sign"
        case .litterBin: "Litter bin"
        case .bikeRack: "Bike rack"
        case .streetLamp: "Street lamp"
        case .tree: "Tree"
        case .parkedCar: "Parked car"
        case .selfCheckout: "Self-checkout"
        case .alcoholWall: "Alcohol wall"
        }
    }

    /// Vertical extent in metres (min, max) used for the selection box.
    public var verticalExtent: ClosedRange<Double> {
        switch self {
        case .gondolaShelf: 0...1.75
        case .wallShelf: 0...1.9
        case .endCap: 0...1.4
        case .wallFridge: 0...2.1
        case .dairyChiller: 0...1.3
        case .checkoutCounter: 0...1.2
        case .cigaretteCabinet: 0...1.9
        case .hotFoodCounter: 0...1.5
        case .coffeeMachine: 0...0.7
        case .menuScreen: 2.12...3.0
        case .windowLedge: 0...1.1
        case .highStool: 0...0.8
        case .basketStack: 0...0.6
        case .backRoomDoor: 0...2.1
        case .pendantLamp: 2.0...3.1
        case .entranceDoor: 0...2.4
        case .windowPoster: 0.8...2.0
        case .atmLocker: 0...2.2
        case .aFrameSign: 0...1.0
        case .litterBin: 0...1.0
        case .bikeRack: 0...0.9
        case .streetLamp: 0...4.5
        case .tree: 0...4.0
        case .parkedCar: 0...1.5
        case .selfCheckout: 0...1.6
        case .alcoholWall: 0...2.1
        }
    }

    public var assetName: AssetName {
        switch self {
        case .gondolaShelf: .gondolaShelf
        case .wallShelf: .wallShelf
        case .endCap: .endCap
        case .wallFridge: .wallFridge
        case .dairyChiller: .dairyChiller
        case .checkoutCounter: .checkoutCounter
        case .cigaretteCabinet: .cigaretteCabinet
        case .hotFoodCounter: .hotFoodCounter
        case .coffeeMachine: .coffeeMachine
        case .menuScreen: .menuScreen
        case .windowLedge: .windowLedge
        case .highStool: .highStool
        case .basketStack: .basketStack
        case .backRoomDoor: .backRoomDoor
        case .pendantLamp: .pendantLamp
        case .entranceDoor: .entranceDoor
        case .windowPoster: .windowPoster
        case .atmLocker: .atmLocker
        case .aFrameSign: .aFrameSign
        case .litterBin: .litterBin
        case .bikeRack: .bikeRack
        case .streetLamp: .streetLamp
        case .tree: .tree
        case .parkedCar: .parkedCar
        case .selfCheckout: .selfCheckout
        case .alcoholWall: .alcoholWall
        }
    }
}
