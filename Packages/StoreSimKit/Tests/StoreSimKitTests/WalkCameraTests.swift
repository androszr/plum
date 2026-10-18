import Testing
import simd
@testable import StoreSimKit

@Suite struct WalkCameraTests {
    static let layout = StoreLayout.plumCorner
    static let floor = WalkableFloor(layout: layout)
    static var preset: WalkCamera { .preset(lot: layout.lot, floor: floor) }

    static func angleDiff(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 2 * .pi)
        if d > .pi { d -= 2 * .pi }
        if d < -.pi { d += 2 * .pi }
        return abs(d)
    }

    @Test func presetStandsOneCellInsideTheEntranceAtEyeHeight() {
        let cam = Self.preset
        let shop = Self.floor.shop
        #expect(shop.xRangeMetres.contains(cam.position.x) && shop.zRangeMetres.contains(cam.position.y))
        #expect(cam.pose.eye.y == 1.6)
        let entrance = Self.floor.centre(of: Self.layout.lot.entrance)
        #expect(simd_length(cam.position - entrance) <= 1.5)
    }

    @Test func presetFacesDownAnAisle() {
        let cam = Self.preset
        let steps = cam.yaw / (.pi / 2)
        #expect(abs(steps - steps.rounded()) < 1e-9)
        #expect(Self.floor.clearDistance(from: cam.position, heading: cam.yaw, limit: 10) >= 3)
    }

    @Test func presetNeverLooksDownTheStaffLane() {
        let cam = Self.preset
        #expect(!Self.floor.staff.isEmpty)
        #expect(!Self.floor.staff.contains(Self.floor.cell(at: cam.position)))
        #expect(Self.floor.customerFloor.clearDistance(from: cam.position, heading: cam.yaw, limit: 10) >= 3)
    }

    @Test func everyWalkableCellIsReachableFromThePreset() {
        let start = Self.preset.position
        for c in Self.floor.walkable {
            let p = Self.floor.centre(of: c)
            let route = Self.floor.route(from: start, to: p)
            #expect(!route.isEmpty, "\(c)")
        }
    }

    @Test func lookClampsPitchBothWays() {
        var c = Self.preset
        c.look(by: SIMD2(0, -100000))
        #expect(abs(c.pitch - WalkCamera.pitchLimit) < 1e-12)
        c.look(by: SIMD2(0, 200000))
        #expect(abs(c.pitch + WalkCamera.pitchLimit) < 1e-12)
    }

    @Test func lookDraggingRightTurnsRight() {
        var c = Self.preset
        let before = c.forward
        c.look(by: SIMD2(40, 0))
        let right = SIMD3(cos(Self.preset.yaw), 0, -sin(Self.preset.yaw))
        #expect(simd_dot(c.forward - before, right) > 0)
    }

    @Test func walkTurnedLeftMatchesTheOrbitConvention() {
        let walk = WalkCamera(position: SIMD2(13.75, 6), yaw: 0.3)
        let orbit = OrbitCamera(target: .zero, distance: 20, yaw: 0.3, pitch: 0.7)
        #expect(abs(walk.turned(by: 1).yaw - orbit.turned(by: 1).yaw) < 1e-9)
        #expect(abs(walk.turned(by: -1).yaw - orbit.turned(by: -1).yaw) < 1e-9)
    }

    @Test func interpolatedYawTakesTheShortArc() {
        let a = WalkCamera(position: .zero, yaw: 0.1)
        let b = a.turned(by: -1)
        let mid = a.interpolated(to: b, t: 0.5)
        #expect(abs(mid.yaw - OrbitCamera.wrap(0.1 - .pi / 8)) < 1e-9)
    }

    @Test func walkForwardMovesAlongForward() {
        var c = Self.preset
        let start = c.position
        c.walk(input: SIMD2(0, 1), dt: 1, on: Self.floor)
        #expect(abs(simd_length(c.position - start) - 1.4) < 1e-9)
    }

    @Test func walkIntoAShelfStopsAgainstIt() {
        var c = Self.preset
        for _ in 0..<2000 {
            c.walk(input: SIMD2(0.3, 1), dt: 1.0 / 60, on: Self.floor)
            #expect(Self.floor.isWalkable(c.position))
        }
        for _ in 0..<2000 {
            c.turn(by: 0.01)
            c.walk(input: SIMD2(0, 1), dt: 1.0 / 60, on: Self.floor)
            #expect(Self.floor.isWalkable(c.position))
        }
    }

    @Test func aLongScrollStepNeverJumpsAFixture() {
        // A trackpad flick can ask for metres in one event; every point it passes must be floor.
        for c in Self.floor.walkable {
            for heading in [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2] {
                let start = Self.floor.centre(of: c)
                guard Self.floor.isWalkable(start) else { continue }
                var cam = WalkCamera(position: start, yaw: heading)
                cam.step(forward: 3, on: Self.floor)
                let n = Int((simd_length(cam.position - start) / 0.02).rounded(.up))
                for i in 0...max(n, 1) {
                    let p = start + (cam.position - start) * (Double(i) / Double(max(n, 1)))
                    let onFloor = Self.floor.isWalkable(p)
                    #expect(onFloor, "\(c) heading \(heading) at \(p)")
                }
            }
        }
    }

    @Test func walkInputClearsTheRoute() {
        var c = Self.preset
        c.route = [SIMD2(14, 6)]
        c.walk(input: SIMD2(0, 1), dt: 0.016, on: Self.floor)
        #expect(!c.isStrolling)
        c.route = [SIMD2(14, 6)]
        c.step(forward: 0.1, on: Self.floor)
        #expect(!c.isStrolling)
    }

    @Test func strollAdvancesAlongTheRouteAndArrives() {
        var c = Self.preset
        let goal = SIMD2(c.position.x, Self.floor.shop.zRangeMetres.lowerBound + 0.75)
        let started = c.stroll(to: goal, on: Self.floor)
        #expect(started)
        var ticks = 0
        while c.isStrolling && ticks < 20000 {
            c.advance(dt: 1.0 / 60, on: Self.floor)
            ticks += 1
        }
        #expect(!c.isStrolling)
        #expect(simd_length(c.position - goal) < 0.1)
    }

    @Test func strollToABlockedSpotSnapsToTheNearestFloor() {
        var c = Self.preset
        let g = Self.layout.fixtures.first { $0.id == "gondola_1" }!
        let started = c.stroll(to: g.occupiedRect.centreMetres, on: Self.floor)
        #expect(started)
        #expect(Self.floor.isWalkable(c.route.last!))
        var far = Self.preset
        let ok = far.stroll(to: SIMD2(100, 100), on: Self.floor)
        #expect(!ok)
    }

    @Test func floorPointAtTheCentreLandsStraightAhead() {
        let c = WalkCamera(position: SIMD2(10, 5), yaw: 0, pitch: -30 * .pi / 180)
        let p = WalkCamera.floorPoint(pose: c.pose, tap: SIMD2(200, 100), viewSize: SIMD2(400, 200))!
        let ahead = 1.6 / tan(30 * Double.pi / 180)
        #expect(abs(p.x - 10) < 1e-9)
        #expect(abs((5 - p.y) - ahead) < 1e-9)
    }

    @Test func floorPointIsNilWhenLookingUp() {
        let c = WalkCamera(position: SIMD2(10, 5), yaw: 0, pitch: 40 * .pi / 180)
        #expect(WalkCamera.floorPoint(pose: c.pose, tap: SIMD2(200, 100), viewSize: SIMD2(400, 200)) == nil)
    }

    @Test func floorPointsMirrorAboutTheHeading() {
        let c = WalkCamera(position: SIMD2(10, 5), yaw: 0, pitch: -30 * .pi / 180)
        let a = WalkCamera.floorPoint(pose: c.pose, tap: SIMD2(100, 150), viewSize: SIMD2(400, 200))!
        let b = WalkCamera.floorPoint(pose: c.pose, tap: SIMD2(300, 150), viewSize: SIMD2(400, 200))!
        #expect(abs((a.x - 10) + (b.x - 10)) < 1e-9)
        #expect(abs(a.y - b.y) < 1e-9)
        #expect(a.x < b.x)
    }
}
