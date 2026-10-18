import Testing
import simd
@testable import StoreSimKit

@Suite struct FloorMarkerTests {
    static let layout = StoreLayout.plumCorner
    static let floor = WalkableFloor(layout: layout)
    static var preset: WalkCamera { .preset(lot: layout.lot, floor: floor) }

    @Test func opacityIsFullAtAndBeyondTheFadeDistance() {
        #expect(FloorMarker.opacity(remaining: 1.0) == 1)
        #expect(FloorMarker.opacity(remaining: 5) == 1)
    }

    @Test func opacityFadesLinearlyInsideTheFadeDistance() {
        #expect(abs(FloorMarker.opacity(remaining: 0.5) - 0.5) < 1e-9)
        #expect(abs(FloorMarker.opacity(remaining: 0.25) - 0.25) < 1e-9)
    }

    @Test func opacityIsZeroAtArrivalAndBelow() {
        #expect(FloorMarker.opacity(remaining: 0) == 0)
        #expect(FloorMarker.opacity(remaining: -0.1) == 0)
    }

    @Test func opacityRejectsNonsense() {
        #expect(FloorMarker.opacity(remaining: .nan) == 0)
        #expect(FloorMarker.opacity(remaining: .infinity) == 0)
        #expect(FloorMarker.opacity(remaining: 0.5, fadeDistance: 0) == 0)
    }

    @Test func markerSitsJustAboveTheFloor() {
        let m = FloorMarker(target: SIMD2(7, 9))
        #expect(m.position.y == FloorMarker.lift)
        #expect(FloorMarker.lift > 0 && FloorMarker.lift < 0.05)
        #expect(m.position.x == 7 && m.position.z == 9)
    }

    @Test func markerRadiusFitsInsideAWalkableCell() {
        #expect(FloorMarker.radius < cellSize / 2)
    }

    @Test func presentationIsNilOutside() {
        var c = Self.preset
        let goal = SIMD2(c.position.x, Self.floor.shop.zRangeMetres.lowerBound + 0.75)
        let started = c.stroll(to: goal, on: Self.floor)
        #expect(started)
        let m = FloorMarker.placed(after: c)!
        #expect(m.presentation(camera: c, mode: .inside) != nil)
        #expect(m.presentation(camera: c, mode: .outside) == nil)
    }

    @Test func presentationIsNilWhenNotStrolling() {
        let c = Self.preset
        #expect(FloorMarker(target: SIMD2(5, 5)).presentation(camera: c, mode: .inside) == nil)
    }

    @Test func placedMarkerUsesTheResolvedTargetNotTheRawTap() {
        var c = Self.preset
        let g = Self.layout.fixtures.first { $0.id == "gondola_1" }!
        let raw = g.occupiedRect.centreMetres
        let started = c.stroll(to: raw, on: Self.floor)
        #expect(started)
        let m = FloorMarker.placed(after: c)
        #expect(m != nil)
        #expect(m?.target == c.route.last)
        #expect(Self.floor.isWalkable(m!.target))
        #expect(m!.target != raw)
    }

    @Test func placedIsNilWhenTheStrollIsRefused() {
        var c = Self.preset
        let started = c.stroll(to: SIMD2(100, 100), on: Self.floor)
        #expect(!started)
        #expect(c.route.isEmpty)
        #expect(FloorMarker.placed(after: c) == nil)
    }

    @Test func retapMovesTheMarkerAndRestoresFullOpacity() {
        var c = Self.preset
        let shop = Self.floor.shop
        let a = SIMD2(c.position.x, shop.zRangeMetres.lowerBound + 0.75)
        let started = c.stroll(to: a, on: Self.floor)
        #expect(started)
        for _ in 0..<30 { c.advance(dt: 1.0 / 60, on: Self.floor) }
        // A second goal at least 3 m from where the walker stands and from A.
        let b = Self.floor.nearestWalkable(to: SIMD2(c.position.x, c.position.y - 4.0), within: 1.0)
            ?? SIMD2(c.position.x, c.position.y - 4.0)
        #expect(simd_length(b - c.position) >= 3)
        let restarted = c.stroll(to: b, on: Self.floor)
        #expect(restarted)
        let m = FloorMarker.placed(after: c)!
        #expect(m.target == c.route.last)
        #expect(simd_length(m.target - b) < 1.01)
        #expect(m.presentation(camera: c, mode: .inside)?.opacity == 1)
    }

    @Test func opacityFallsAsTheWalkerAdvancesAndEndsNil() {
        var c = Self.preset
        let goal = SIMD2(c.position.x, Self.floor.shop.zRangeMetres.lowerBound + 0.75)
        let started = c.stroll(to: goal, on: Self.floor)
        #expect(started)
        let m = FloorMarker.placed(after: c)!
        var seen: [Double] = []
        var ticks = 0
        while c.isStrolling && ticks < 20000 {
            seen.append(m.presentation(camera: c, mode: .inside)!.opacity)
            c.advance(dt: 1.0 / 60, on: Self.floor)
            ticks += 1
        }
        #expect(!c.isStrolling)
        #expect(seen.first == 1)
        #expect((seen.last ?? 1) < 0.2)
        let tail = seen.drop { $0 >= 1 }
        #expect(zip(tail, tail.dropFirst()).allSatisfy { $1 <= $0 + 1e-9 })
        #expect(m.presentation(camera: c, mode: .inside) == nil)
    }
}
