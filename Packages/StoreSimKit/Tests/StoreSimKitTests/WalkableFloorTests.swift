import Testing
import simd
@testable import StoreSimKit

@Suite struct WalkableFloorTests {
    static let layout = StoreLayout.plumCorner
    static let floor = WalkableFloor(layout: layout)

    @Test func freeCellsMatchTheValidatorRule() {
        var expected = Set<GridCell>()
        for zone in Self.layout.lot.zones(of: .storeInterior) { expected.formUnion(zone.rect.cells) }
        for f in Self.layout.fixtures where f.kind.occupiesFloor { expected.subtract(f.occupiedRect.cells) }
        #expect(Self.floor.free == expected)
        #expect(Self.floor.free.contains(Self.layout.lot.entrance))
    }

    @Test func everyFreeCellCentreIsWalkable() {
        #expect(!Self.floor.walkable.isEmpty && Self.floor.walkable.isSubset(of: Self.floor.free))
        for c in Self.floor.walkable { #expect(Self.floor.isWalkable(Self.floor.centre(of: c)), "\(c)") }
    }

    @Test func doorLeafPlaneAndFrontWallAreNotWalkable() {
        let door = Self.layout.fixtures.first { $0.id == "entrance_door_1" }!.occupiedRect
        let z = (door.zRangeMetres.lowerBound + door.zRangeMetres.upperBound) / 2
        var x = door.xRangeMetres.lowerBound + 0.1
        while x < door.xRangeMetres.upperBound {
            #expect(!Self.floor.isWalkable(SIMD2(x, z)), "x \(x)")
            #expect(!Self.floor.isWalkable(SIMD2(x, z - 0.1)), "x \(x)")
            x += 0.2
        }
        // One cell in from the door is open floor.
        let inside = SIMD2((door.xRangeMetres.lowerBound + door.xRangeMetres.upperBound) / 2, z - cellSize)
        #expect(Self.floor.isWalkable(inside))
    }

    @Test func eyeStaysClearOfAnOuterFixtureCorner() {
        let g = Self.layout.fixtures.first { $0.id == "gondola_3" }!.occupiedRect
        let p = SIMD2(g.xRangeMetres.lowerBound - 0.05, g.zRangeMetres.lowerBound - 0.05)
        #expect(Self.floor.free.contains(Self.floor.cell(at: p)))
        #expect(!Self.floor.isWalkable(p))
    }

    @Test func pointInsideAGondolaIsNotWalkable() {
        let g = Self.layout.fixtures.first { $0.id == "gondola_1" }!
        #expect(!Self.floor.isWalkable(g.occupiedRect.centreMetres))
    }

    @Test func pointJustOutsideTheShopIsNotWalkable() {
        #expect(!Self.floor.isWalkable(SIMD2(8.4, 4.5)))
    }

    @Test func resolveSlidesAlongAShelf() {
        let g = Self.layout.fixtures.first { $0.id == "gondola_1" }!
        let r = g.occupiedRect
        // Stand in the aisle just below (high z) the shelf's long face, push diagonally into it.
        let x = (r.xRangeMetres.lowerBound + r.xRangeMetres.upperBound) / 2
        let from = SIMD2(x, r.zRangeMetres.upperBound + WalkableFloor.clearance + 0.01)
        #expect(Self.floor.isWalkable(from))
        let to = SIMD2(from.x + 0.1, from.y - 0.1)
        let out = Self.floor.resolve(from: from, to: to)
        #expect(out.x == to.x)
        #expect(out.y == from.y)
    }

    @Test func resolveStaysPutInACorner() {
        // The free cell with the smallest x + z has no free neighbour towards -x or -z.
        let cell = Self.floor.free.min { ($0.x + $0.z, $0.x) < ($1.x + $1.z, $1.x) }!
        let corner = Self.floor.centre(of: cell)
        #expect(Self.floor.isWalkable(corner))
        let out = Self.floor.resolve(from: corner, to: corner - SIMD2(0.1, 0.1))
        #expect(out == corner)
    }

    @Test func nearestWalkableSnapsAcrossAFixtureEdge() {
        let g = Self.layout.fixtures.first { $0.id == "gondola_1" }!
        let p = g.occupiedRect.centreMetres
        let n = Self.floor.nearestWalkable(to: p, within: 1.5)
        #expect(n != nil)
        #expect(Self.floor.isWalkable(n!))
        #expect(Self.floor.nearestWalkable(to: SIMD2(100, 100), within: 1.0) == nil)
    }

    @Test func routeReachesTheBackWallFromTheEntrance() {
        let start = WalkCamera.preset(lot: Self.layout.lot, floor: Self.floor).position
        let shop = Self.floor.shop
        let goal = SIMD2(start.x, shop.zRangeMetres.lowerBound + 0.75)
        let route = Self.floor.route(from: start, to: goal)
        #expect(!route.isEmpty)
        #expect(route.last == goal)
        for p in route { #expect(Self.floor.isWalkable(p), "\(p)") }
    }

    @Test func routeIsEmptyForAnUnreachablePoint() {
        let back = Self.layout.lot.zones(of: .backRoom).first!.rect.centreMetres
        let start = WalkCamera.preset(lot: Self.layout.lot, floor: Self.floor).position
        #expect(Self.floor.route(from: start, to: back).isEmpty)
    }

    @Test func clearDistanceFromThePresetIsAtLeastThreeMetres() {
        // The preset stands one cell inside the door and faces down an aisle with room to look.
        let cam = WalkCamera.preset(lot: Self.layout.lot, floor: Self.floor)
        #expect(Self.floor.clearDistance(from: cam.position, heading: cam.yaw, limit: 10) >= 3)
    }
}
