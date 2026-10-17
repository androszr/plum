import Foundation
import Testing
@testable import StoreSimKit

@Suite struct DefaultLayoutTests {
    @Test func shippedLayoutValidatesClean() {
        let issues = LayoutValidator.validate(StoreLayout.plumCorner)
        #expect(issues.isEmpty, "\(issues)")
    }

    @Test func fixtureIdsAreUnique() {
        let ids = StoreLayout.plumCorner.fixtures.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func minimumCountsPerKind() {
        let minimums: [FixtureKind: Int] = [
            .gondolaShelf: 6, .wallShelf: 4, .endCap: 2, .wallFridge: 4, .dairyChiller: 1, .checkoutCounter: 1,
            .cigaretteCabinet: 1, .hotFoodCounter: 1, .coffeeMachine: 1, .menuScreen: 1, .windowLedge: 1,
            .highStool: 2, .basketStack: 1, .backRoomDoor: 1, .pendantLamp: 4, .entranceDoor: 1,
            .windowPoster: 3, .atmLocker: 1, .aFrameSign: 1, .litterBin: 2, .bikeRack: 1,
            .streetLamp: 4, .tree: 6, .parkedCar: 3,
        ]
        #expect(Set(minimums.keys) == Set(FixtureKind.allCases))
        for (kind, n) in minimums {
            let have = StoreLayout.plumCorner.fixtures.filter { $0.kind == kind }.count
            #expect(have >= n, "\(kind): \(have) < \(n)")
        }
    }

    @Test func codableRoundTrips() throws {
        let data = try JSONEncoder().encode(StoreLayout.plumCorner)
        let back = try JSONDecoder().decode(StoreLayout.self, from: data)
        #expect(back.fixtures == StoreLayout.plumCorner.fixtures)
        #expect(back.lot == StoreLayout.plumCorner.lot)
    }

    @Test func olderFixtureJSONDecodesWithDefaults() throws {
        let json = #"{"id":"x","kind":"tree","cell":{"x":1,"z":2},"someFutureKey":true}"#
        let f = try JSONDecoder().decode(Fixture.self, from: Data(json.utf8))
        #expect(f.rotation == QuarterTurn.none)
        #expect(f.label == nil)
        #expect(f.cell == GridCell(x: 1, z: 2))
    }
}
