import Foundation
import Testing
@testable import StoreSimKit

@Suite struct TrafficTests {
    static let layout = StoreLayout.plumCorner
    static var carLanes: [TrafficLane] { Traffic.lanes(for: layout).filter { $0.kind == .car } }
    static var walkLanes: [TrafficLane] { Traffic.lanes(for: layout).filter { $0.kind == .pedestrian } }
    static let times = stride(from: 0.0, through: 120.0, by: 0.25)

    static func row(_ z: Double) -> Int { Int((z / cellSize).rounded(.down)) }

    @Test func twoCarLanesSitInsideTheStreetZone() throws {
        let street = try #require(Self.layout.lot.zones(of: .street).first)
        let z = street.rect.zRangeMetres
        #expect(Self.carLanes.count == 2)
        for lane in Self.carLanes { #expect(z.contains(lane.z), "\(lane.id)") }
        #expect(Self.carLanes[0].z != Self.carLanes[1].z)
    }

    @Test func carLanesDriveOppositeWaysRightHanded() {
        let sorted = Self.carLanes.sorted { $0.z < $1.z }
        #expect(sorted[0].direction == -1)
        #expect(sorted[1].direction == 1)
        #expect(sorted[0].z < sorted[1].z)
    }

    @Test func walkersNeverClipAFixture() {
        #expect(Self.walkLanes.count == 4)
        let h = Traffic.walkerHalfWidth
        for lane in Self.walkLanes {
            let body = (lane.z - h)...(lane.z + h)
            for f in Self.layout.fixtures where f.kind.occupiesFloor {
                let solid = Traffic.solidMetres(of: f).z
                // A walker passes every x, so only the z ranges matter. Touching is clear.
                let clear = body.upperBound <= solid.lowerBound + 1e-9 || body.lowerBound >= solid.upperBound - 1e-9
                #expect(clear, "\(lane.id) (z \(lane.z)) clips \(f.id) (solid z from \(solid.lowerBound) to \(solid.upperBound))")
            }
        }
    }

    @Test func walkersStayOnTheirPavement() throws {
        for (id, kind) in [("near", Zone.Kind.sidewalk), ("far", .farSidewalk)] {
            let zone = try #require(Self.layout.lot.zones(of: kind).first).rect.zRangeMetres
            for lane in Self.walkLanes where lane.id.contains(id) {
                #expect(zone.contains(lane.z - Traffic.walkerHalfWidth) && zone.contains(lane.z + Traffic.walkerHalfWidth), Comment(rawValue: lane.id))
            }
        }
    }

    @Test func walkingLinesAreAWalkerWidthApartWhereThePavementAllows() {
        let h = Traffic.walkerHalfWidth
        for side in ["near", "far"] {
            let lanes = Self.walkLanes.filter { $0.id.contains(side) }.sorted { $0.z < $1.z }
            #expect(lanes.count == 2)
            let gap = lanes[1].z - lanes[0].z
            if side == "far" {
                // Trees leave two wide bands, one line in each.
                #expect(gap >= 2 * h, "far lines \(gap) apart")
            } else {
                // One 0.65 m band between the bin and the lamp posts holds both bodies side by side
                // only when it is 4 half-widths wide; here it is not, so the lines sit as far apart as
                // that band allows, every body clear of the fixtures (walkersNeverClipAFixture).
                #expect(gap > h, "near lines \(gap) apart")
            }
        }
    }

    @Test func walkersKeepToTheRightOfTheirDirection() {
        // Heading +X, +Z is on the right, so the +1 line has the larger z.
        for side in ["near", "far"] {
            let lanes = Self.walkLanes.filter { $0.id.contains(side) }.sorted { $0.z < $1.z }
            #expect(lanes[0].direction == -1 && lanes[1].direction == 1)
        }
    }

    @Test func eachPavementHasItsClearLines() {
        let near = Self.walkLanes.filter { $0.id.contains("near") }
        let far = Self.walkLanes.filter { $0.id.contains("far") }
        #expect(near.count == 2 && far.count == 2)
        for lane in near { #expect(Self.row(lane.z) == 20, "\(lane.id)") }
        #expect(Set(far.map { Self.row($0.z) }) == [38, 41])
        #expect(Set(near.map(\.direction)) == [1, -1])
        #expect(Set(far.map(\.direction)) == [1, -1])
    }

    @Test func poseIsPeriodic() {
        for detail in [DetailLevel.full, .reduced] {
            for m in Traffic.movers(for: Self.layout, detail: detail) {
                let period = Traffic.loopLength(of: m) / m.lane.speed
                for t in [0.0, 1.3, 7.7] {
                    let a = Traffic.pose(of: m, at: t)
                    let b = Traffic.pose(of: m, at: t + period)
                    #expect(abs(a.position.x - b.position.x) < 1e-9, "\(m.id)")
                    #expect(a.position.z == b.position.z)
                    #expect(a.yaw == b.yaw)
                }
            }
        }
    }

    @Test func moverStaysWithinTheLoop() {
        for m in Traffic.movers(for: Self.layout, detail: .full) {
            let margin = Traffic.wrapMargin(of: m)
            for t in Self.times {
                let x = Traffic.pose(of: m, at: t).position.x
                #expect(x >= m.lane.xRange.lowerBound - margin - 1e-9 && x <= m.lane.xRange.upperBound + margin + 1e-9,
                        "\(m.id) at \(t): \(x)")
            }
        }
    }

    @Test func carsFaceTheWayTheyDrive() {
        for m in Traffic.movers(for: Self.layout, detail: .full) where m.kind == .car {
            let a = Traffic.pose(of: m, at: 10)
            let b = Traffic.pose(of: m, at: 10.01)
            let travelled = b.position.x - a.position.x
            #expect(travelled * m.lane.direction > 0 || abs(travelled) > 10, "\(m.id) moves against its lane")
            // The front is +X; yaw 0 keeps it, yaw pi turns it round.
            #expect(a.yaw == (m.lane.direction > 0 ? 0 : .pi))
        }
    }

    @Test func walkersFaceTheWayTheyWalk() {
        for m in Traffic.movers(for: Self.layout, detail: .full) where m.kind == .pedestrian {
            let yaw = Traffic.pose(of: m, at: 3).yaw
            // The front is +Z; a yaw of +90 degrees turns it to +X.
            let front = (x: sin(yaw), z: cos(yaw))
            let facing = Traffic.walkerFacesPlusZ ? m.lane.direction : -m.lane.direction
            #expect(abs(front.x - facing) < 1e-9, "\(m.id)")
            #expect(abs(front.z) < 1e-9)
        }
    }

    @Test func sameLaneMoversNeverOverlap() {
        let movers = Traffic.movers(for: Self.layout, detail: .full)
        for lane in Traffic.lanes(for: Self.layout) {
            let group = movers.filter { $0.lane == lane }
            for t in Self.times {
                for (i, a) in group.enumerated() {
                    for b in group[(i + 1)...] {
                        let loop = Traffic.loopLength(of: a)
                        let d = abs(Traffic.pose(of: a, at: t).position.x - Traffic.pose(of: b, at: t).position.x)
                        // Across the wrap the two are a loop apart, not close.
                        let gap = min(d, loop - d)
                        #expect(gap >= a.length + 1, "\(a.id) and \(b.id) at \(t): \(gap)")
                    }
                }
            }
        }
    }

    @Test func reducedDetailHasFewerMovers() {
        let full = Traffic.movers(for: Self.layout, detail: .full)
        let reduced = Traffic.movers(for: Self.layout, detail: .reduced)
        #expect(reduced.count < full.count)
        #expect(full.filter { $0.kind == .car }.count == 6)
        #expect(full.filter { $0.kind == .pedestrian }.count == 8)
        #expect(reduced.filter { $0.kind == .car }.count == 4)
        #expect(reduced.filter { $0.kind == .pedestrian }.count == 4)
    }

    @Test func moverIdsAreUniqueAndNeverClashWithFixtureIds() {
        let ids = Traffic.movers(for: Self.layout, detail: .full).map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Set(ids).isDisjoint(with: Set(Self.layout.fixtures.map(\.id))))
    }

    @Test func walkersCycleThroughTheThreeCharacters() {
        let walkers = Traffic.movers(for: Self.layout, detail: .full).filter { $0.kind == .pedestrian }
        #expect(Set(walkers.map(\.asset)) == AssetName.characterNames)
        #expect(walkers.prefix(3).map(\.asset) == [.pedestrianA, .pedestrianB, .pedestrianC])
        #expect(walkers.map(\.ordinal) == Array(0..<walkers.count))
    }

    @Test func movingCarsReuseTheParkedCarModels() {
        let cars = Traffic.movers(for: Self.layout, detail: .full).filter { $0.kind == .car }
        let models: Set<AssetName> = [.parkedCarHatchback, .parkedCarSaloon, .parkedCarVan]
        #expect(Set(cars.map(\.asset)) == models)
    }

    @Test func parkedCarsAreNotMovers() {
        let parked = Self.layout.fixtures.filter { $0.kind == .parkedCar }
        #expect(!parked.isEmpty)
        let movers = Traffic.movers(for: Self.layout, detail: .full)
        #expect(!movers.contains { parked.map(\.id).contains($0.id) })
        for m in movers {
            // Half the body width across the lane, half the length along it.
            let halfAcross = m.kind == .car ? 1.0 : 0.3
            for t in Self.times {
                let p = Traffic.pose(of: m, at: t).position
                for car in parked {
                    let x = car.occupiedRect.xRangeMetres, z = car.occupiedRect.zRangeMetres
                    let inside = p.x + m.length / 2 > x.lowerBound && p.x - m.length / 2 < x.upperBound
                        && p.z + halfAcross > z.lowerBound && p.z - halfAcross < z.upperBound
                    #expect(!inside, "\(m.id) overlaps \(car.id) at \(t)")
                }
            }
        }
    }

    @Test func laneOffsetsKeepLanesApartInPhase() {
        let movers = Traffic.movers(for: Self.layout, detail: .full)
        let firsts = Traffic.lanes(for: Self.layout).compactMap { lane in movers.first { $0.lane == lane } }
        #expect(Set(firsts.map(\.offset)).count == firsts.count)
    }
}
