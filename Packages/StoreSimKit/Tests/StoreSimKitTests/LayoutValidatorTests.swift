import Testing
@testable import StoreSimKit

@Suite struct LayoutValidatorTests {
    /// A small lot: a 6 x 6 shop with its entrance on the front edge, a sidewalk below.
    static func lot() -> Lot {
        Lot(size: GridSize(w: 10, d: 12),
            zones: [
                Zone(id: "shop", kind: .storeInterior, rect: GridRect(x: 2, z: 0, w: 6, d: 6)),
                Zone(id: "walk", kind: .sidewalk, rect: GridRect(x: 0, z: 6, w: 10, d: 6)),
            ],
            entrance: GridCell(x: 4, z: 5))
    }

    static func layout(_ fixtures: [Fixture]) -> StoreLayout { StoreLayout(lot: lot(), fixtures: fixtures) }

    @Test func overlapIsDetected() {
        let a = Fixture(id: "a", kind: .gondolaShelf, cell: GridCell(x: 2, z: 0))
        let b = Fixture(id: "b", kind: .gondolaShelf, cell: GridCell(x: 3, z: 1))
        #expect(LayoutValidator.validate(Self.layout([a, b])).contains(.overlap("a", "b")))
    }

    @Test func outsideLotIsDetected() {
        let f = Fixture(id: "out", kind: .gondolaShelf, cell: GridCell(x: 9, z: 0))
        #expect(LayoutValidator.validate(Self.layout([f])).contains(.outsideLot("out")))
    }

    @Test func wrongZoneIsDetected() {
        let f = Fixture(id: "car", kind: .parkedCar, cell: GridCell(x: 0, z: 6))
        // A car on the sidewalk, not the parking lane.
        #expect(LayoutValidator.validate(Self.layout([f])).contains(.wrongZone("car")))
    }

    @Test func footprintSwapsOnRotation() {
        let flat = Fixture(id: "c", kind: .checkoutCounter, cell: GridCell(x: 0, z: 0))
        let turned = Fixture(id: "c", kind: .checkoutCounter, cell: GridCell(x: 0, z: 0), rotation: QuarterTurn(1))
        #expect(flat.occupiedRect.size == GridSize(w: 4, d: 2))
        #expect(turned.occupiedRect.size == GridSize(w: 2, d: 4))
    }

    @Test func overlapAppearsOnlyAfterTheSwap() {
        let counter = Fixture(id: "c", kind: .checkoutCounter, cell: GridCell(x: 2, z: 0))
        let neighbour = Fixture(id: "n", kind: .gondolaShelf, cell: GridCell(x: 2, z: 2))
        #expect(!LayoutValidator.validate(Self.layout([counter, neighbour])).contains(.overlap("c", "n")))
        let turned = Fixture(id: "c", kind: .checkoutCounter, cell: GridCell(x: 2, z: 0), rotation: QuarterTurn(1))
        #expect(LayoutValidator.validate(Self.layout([turned, neighbour])).contains(.overlap("c", "n")))
    }

    @Test func blockedAisleIsUnreachable() {
        // A wall of shelves across the whole shop cuts off the back.
        let wall = [0, 2, 4].map { Fixture(id: "w\($0)", kind: .gondolaShelf, cell: GridCell(x: 2 + $0, z: 2)) }
        let issues = LayoutValidator.validate(Self.layout(wall))
        #expect(issues.contains { if case .unreachable = $0 { true } else { false } })
    }

    @Test func oneCellCorridorIsTooNarrow() {
        // Leaves a single-cell corridor between the shelf and the wall at x == 2.
        let shelf = Fixture(id: "s", kind: .gondolaShelf, cell: GridCell(x: 3, z: 0))
        let blocker = Fixture(id: "t", kind: .gondolaShelf, cell: GridCell(x: 5, z: 0))
        let issues = LayoutValidator.validate(Self.layout([shelf, blocker]))
        #expect(issues.contains(.aisleTooNarrow(GridCell(x: 2, z: 0))))
    }

    @Test func ceilingKindsDoNotBlock() {
        let lamp = Fixture(id: "lamp", kind: .pendantLamp, cell: GridCell(x: 4, z: 2))
        let door = Fixture(id: "door", kind: .entranceDoor, cell: GridCell(x: 3, z: 5))
        #expect(LayoutValidator.validate(Self.layout([lamp, door])).isEmpty)
    }

    @Test func cleanSetHasNoIssues() {
        let shelf = Fixture(id: "s", kind: .gondolaShelf, cell: GridCell(x: 2, z: 0))
        #expect(LayoutValidator.validate(Self.layout([shelf])).isEmpty)
    }
}
