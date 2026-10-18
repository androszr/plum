import Foundation
import Testing
@testable import StoreSimKit

@Suite struct TrafficTests {
    static let layout = StoreLayout.plumCorner
    static var carLanes: [TrafficLane] { Traffic.lanes(for: layout).filter { $0.kind == .car } }
    static var walkLanes: [TrafficLane] { Traffic.lanes(for: layout).filter { $0.kind == .pedestrian } }
    static let times = Array(stride(from: 0.0, through: 600.0, by: 0.25))
    static func shown(_ m: Mover, at t: Double) -> MoverPose? {
        let pose = Traffic.pose(of: m, at: t)
        return pose.visibility > 0 ? pose : nil
    }

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
            // Walkers heading opposite ways always meet somewhere along the street, so the lines must
            // be a full body apart. Far: trees leave two wide bands, one line in each. Near: one
            // 1.1 m band between the bins and the lamp posts holds both bodies side by side.
            #expect(gap >= 2 * h - 1e-9, "\(side) lines \(gap) apart")
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
        #expect(Set(near.map { Self.row($0.z) }) == [19, 20])
        #expect(Set(far.map { Self.row($0.z) }) == [38, 41])
        #expect(Set(near.map(\.direction)) == [1, -1])
        #expect(Set(far.map(\.direction)) == [1, -1])
    }

    @Test func walkersStartAtDifferentPointsOfTheirWalkCycle() {
        let clip = 1.0667
        for detail in [DetailLevel.full, .reduced] {
            let phases = Traffic.movers(for: Self.layout, detail: detail)
                .filter { $0.kind == .pedestrian }
                .map { Traffic.walkCyclePhase(of: $0, clipLength: clip) }
            #expect(phases.count >= 2)
            for (i, a) in phases.enumerated() {
                #expect(a >= 0 && a < clip)
                for b in phases[(i + 1)...] {
                    let d = abs(a - b)
                    #expect(min(d, clip - d) >= 0.05 * clip, "phases \(a) and \(b) step together")
                }
            }
        }
    }

    @Test func theStreetIsTheSameOnEveryRun() {
        // Pinned values from an independent SplitMix64 + FNV-1a run: a per-process seed (`Hasher`) would miss them.
        var rng = SlotRandom(lane: "near_road", slot: 7)
        #expect(rng.next() == 0.4621577287141748)
        #expect(rng.next() == 0.9864962377915878)
        #expect(rng.next() == 0.3249453449289249)
    }

    @Test func nothingIsDrawnBeyondTheLotEdge() {
        for m in Traffic.movers(for: Self.layout, detail: .full) {
            for t in Self.times {
                guard let pose = Self.shown(m, at: t) else { continue }
                let x = pose.position.x
                #expect(x - m.length / 2 >= m.lane.xRange.lowerBound - 1e-9 && x + m.length / 2 <= m.lane.xRange.upperBound + 1e-9,
                        "\(m.id) shown at \(t) with its body over the void: x \(x)")
            }
        }
    }

    @Test func moversFadeInAndOutRatherThanPop() {
        for m in Traffic.movers(for: Self.layout, detail: .full) {
            var last = 0.0
            for t in stride(from: 0.0, through: 300.0, by: 0.05) {
                let v = Traffic.pose(of: m, at: t).visibility
                // One 50 ms frame never jumps from hidden to fully shown or back.
                #expect(abs(v - last) < 0.5, "\(m.id) jumps from \(last) to \(v) at \(t)")
                last = v
            }
        }
    }

    @Test func carsAreUnhurriedAndEachCrossingHasItsOwnSpeed() {
        for m in Traffic.movers(for: Self.layout, detail: .full) where m.kind == .car {
            var speeds = Set<Double>()
            for t in Self.times { if let p = Self.shown(m, at: t) { speeds.insert(p.speed) } }
            #expect(speeds.allSatisfy { (3.5...6.0).contains($0) }, "\(m.id) speeds \(speeds)")
            #expect(speeds.count >= 3, "\(m.id) drives at only \(speeds.count) speeds in ten minutes")
        }
    }

    /// Times a lane's movers enter the lot, in order.
    static func arrivals(in lane: TrafficLane, detail: DetailLevel) -> [Double] {
        let group = Traffic.movers(for: Self.layout, detail: detail).filter { $0.lane == lane }
        var out: [Double] = []
        for m in group {
            var was = false
            for t in Self.times {
                let now = Self.shown(m, at: t) != nil
                if now && !was { out.append(t) }
                was = now
            }
        }
        return out.sorted()
    }

    @Test func carsComeIrregularlyAndNotTooOften() {
        for lane in Self.carLanes {
            let times = Self.arrivals(in: lane, detail: .full)
            let gaps = zip(times.dropFirst(), times).map { $0 - $1 }
            // About one car or pair every twenty seconds a lane, never on a fixed beat.
            #expect(times.count >= 20 && times.count <= 60, "\(lane.id): \(times.count) cars in ten minutes")
            #expect((gaps.max() ?? 0) - (gaps.min() ?? 0) > 10, "\(lane.id) gaps \(gaps)")
        }
    }

    @Test func carsSometimesComeInPairsAndTheRoadIsSometimesEmpty() {
        let movers = Traffic.movers(for: Self.layout, detail: .full).filter { $0.kind == .car }
        var two = false, empty = false
        for lane in Self.carLanes {
            for t in Self.times {
                let n = movers.filter { $0.lane == lane && Self.shown($0, at: t) != nil }.count
                if n >= 2 { two = true }
                if n == 0 { empty = true }
            }
        }
        #expect(two && empty)
    }

    @Test func lanesDoNotRunInStep() {
        let firsts = Traffic.lanes(for: Self.layout).map { Self.arrivals(in: $0, detail: .full).prefix(3) }
        #expect(Set(firsts.map { Array($0) }).count == firsts.count)
    }

    @Test func walkersPlayTheirWalkAtTheirOwnPace() {
        for m in Traffic.movers(for: Self.layout, detail: .full) where m.kind == .pedestrian {
            for t in Self.times {
                guard let p = Self.shown(m, at: t) else { continue }
                #expect((1.1...1.6).contains(p.speed))
            }
        }
        // The clip walks in place at the measured 1.45 m/s; this rate keeps the planted foot still.
        #expect(abs(Traffic.walkCycleRate(at: 1.45) - 1.0) < 1e-12)
        #expect(abs(Traffic.walkCycleRate(at: 1.16) - 0.8) < 1e-12)
    }

    @Test func carsFaceTheWayTheyDrive() {
        for m in Traffic.movers(for: Self.layout, detail: .full) where m.kind == .car {
            for t in Self.times {
                guard let a = Self.shown(m, at: t), let b = Self.shown(m, at: t + 0.01) else { continue }
                #expect((b.position.x - a.position.x) * m.lane.direction > 0, "\(m.id) moves against its lane")
                // The front is +X; yaw 0 keeps it, yaw pi turns it round.
                #expect(a.yaw == (m.lane.direction > 0 ? 0 : .pi))
            }
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
                        guard let pa = Self.shown(a, at: t), let pb = Self.shown(b, at: t) else { continue }
                        let gap = abs(pa.position.x - pb.position.x)
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
                guard let p = Self.shown(m, at: t)?.position else { continue }
                for car in parked {
                    let x = car.occupiedRect.xRangeMetres, z = car.occupiedRect.zRangeMetres
                    let inside = p.x + m.length / 2 > x.lowerBound && p.x - m.length / 2 < x.upperBound
                        && p.z + halfAcross > z.lowerBound && p.z - halfAcross < z.upperBound
                    #expect(!inside, "\(m.id) overlaps \(car.id) at \(t)")
                }
            }
        }
    }
}
