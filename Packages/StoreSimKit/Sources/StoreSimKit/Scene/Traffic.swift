import Foundation
import simd

public enum MoverKind: Sendable, Equatable {
    case car
    case pedestrian
}

/// A straight line along X that movers follow, always the same way at one speed.
public struct TrafficLane: Sendable, Equatable {
    public var id: String
    public var kind: MoverKind
    /// Metres on the ground plane.
    public var z: Double
    /// +1 moves toward +X, -1 toward -X.
    public var direction: Double
    /// Metres per second.
    public var speed: Double
    /// The lot's x extent in metres.
    public var xRange: ClosedRange<Double>

    public init(id: String, kind: MoverKind, z: Double, direction: Double, speed: Double, xRange: ClosedRange<Double>) {
        self.id = id
        self.kind = kind
        self.z = z
        self.direction = direction
        self.speed = speed
        self.xRange = xRange
    }
}

/// One car or walker: a route and a starting offset along it. Nothing here is stored in the layout.
public struct Mover: Sendable, Equatable {
    public var id: String
    public var kind: MoverKind
    public var asset: AssetName
    /// Counts within the kind, from 0.
    public var ordinal: Int
    public var lane: TrafficLane
    /// Metres along the loop at time 0.
    public var offset: Double
    /// Metres along the direction of travel; sets how far past the lot it wraps and the spacing.
    public var length: Double

    public init(id: String, kind: MoverKind, asset: AssetName, ordinal: Int, lane: TrafficLane, offset: Double, length: Double) {
        self.id = id
        self.kind = kind
        self.asset = asset
        self.ordinal = ordinal
        self.lane = lane
        self.offset = offset
        self.length = length
    }
}

public struct MoverPose: Sendable, Equatable {
    public var position: SIMD3<Double>
    public var yaw: Double
    public init(position: SIMD3<Double>, yaw: Double) {
        self.position = position
        self.yaw = yaw
    }
}

/// Decorative street traffic, derived from the lot's zones and a clock. Pure: no collisions,
/// no state; the same time always gives the same pose.
public enum Traffic {
    /// Metres per second, near lane then far lane.
    public static let carSpeeds: (near: Double, far: Double) = (7.0, 8.0)
    /// Metres per second for walkers heading +X and -X.
    public static let walkerSpeeds: (forward: Double, backward: Double) = (1.2, 1.4)
    /// A mover wraps this far beyond its own length past the lot edge, out of view of the lot.
    public static let wrapPadding = 2.0
    public static let carLength = 4.5
    public static let walkerLength = 0.6
    /// Height of a walker in metres, the brief's figure.
    public static let walkerHeight = 1.75
    /// Walkers face +Z in the brief and in the stand-in. Flip this one constant if a Meshy export turns out to face -Z.
    public static let walkerFacesPlusZ = true
    /// Phase shift between lanes, so they are not locked together.
    static let lanePhase = 1.7
    /// Half the width a walker needs sideways (hips measured 0.36 m on the shipped characters).
    public static let walkerHalfWidth = 0.18

    public static func lanes(for layout: StoreLayout) -> [TrafficLane] {
        let lot = layout.lot
        let xRange = 0.0...(Double(lot.size.w) * cellSize)
        var out: [TrafficLane] = []
        if let street = lot.zones(of: .street).first {
            let lo = Double(street.rect.minZ) * cellSize
            let depth = Double(street.rect.size.d) * cellSize
            out.append(TrafficLane(id: "car_near", kind: .car, z: lo + depth / 4, direction: -1,
                                   speed: carSpeeds.near, xRange: xRange))
            out.append(TrafficLane(id: "car_far", kind: .car, z: lo + 3 * depth / 4, direction: 1,
                                   speed: carSpeeds.far, xRange: xRange))
        }
        for (label, kind) in [("near", Zone.Kind.sidewalk), ("far", .farSidewalk)] {
            guard let zone = lot.zones(of: kind).first else { continue }
            // Right-hand walking: heading +X keeps +Z on the right, so the +1 line is the one with the larger z.
            let lines = walkingLines(in: zone, layout: layout).sorted()
            for (i, z) in lines.enumerated() {
                let forward = i == lines.count - 1
                out.append(TrafficLane(id: "walk_\(label)_\(forward ? "forward" : "backward")", kind: .pedestrian, z: z,
                                       direction: forward ? 1 : -1,
                                       speed: forward ? walkerSpeeds.forward : walkerSpeeds.backward, xRange: xRange))
            }
        }
        return out
    }

    /// What a fixture actually blocks on the ground, in metres: x range and z range. Most kinds block
    /// their whole footprint; a bin, a lamp and a tree block only their body, from the brief's sizes
    /// (a walker passes under a crown, so a tree blocks its trunk).
    public static func solidMetres(of fixture: Fixture) -> (x: ClosedRange<Double>, z: ClosedRange<Double>) {
        let rect = fixture.occupiedRect
        let size: (w: Double, d: Double)?
        switch fixture.kind {
        case .litterBin: size = (0.4, 0.4)
        case .streetLamp: size = fixture.rotation.isOdd ? (0.3, 0.8) : (0.8, 0.3)
        case .tree: size = (0.3, 0.3)
        default: size = nil
        }
        guard let size else { return (rect.xRangeMetres, rect.zRangeMetres) }
        let c = rect.centreMetres
        return ((c.x - size.w / 2)...(c.x + size.w / 2), (c.y - size.d / 2)...(c.y + size.d / 2))
    }

    /// The z of each walking line on a pavement. Free bands run the whole length of the lot between
    /// the fixtures' solid z ranges; a band at least one body wide gets a line down its middle. With
    /// two or more such bands the two widest are used. With one band both lines go in it, as far
    /// apart as the band allows, each body clear of the fixtures.
    public static func walkingLines(in zone: Zone, layout: StoreLayout) -> [Double] {
        let lo = Double(zone.rect.minZ) * cellSize
        let hi = Double(zone.rect.maxZ) * cellSize
        let blocked = layout.fixtures
            .filter { $0.kind.occupiesFloor }
            .map { solidMetres(of: $0).z }
            .filter { $0.upperBound > lo && $0.lowerBound < hi }
            .sorted { $0.lowerBound < $1.lowerBound }
        var bands: [ClosedRange<Double>] = []
        var cursor = lo
        for b in blocked {
            if b.lowerBound > cursor { bands.append(cursor...b.lowerBound) }
            cursor = max(cursor, b.upperBound)
        }
        if cursor < hi { bands.append(cursor...hi) }
        let wide = bands.filter { $0.upperBound - $0.lowerBound >= 2 * walkerHalfWidth - 1e-9 }
        if wide.count >= 2 {
            let two = wide.sorted { ($0.upperBound - $0.lowerBound) > ($1.upperBound - $1.lowerBound) }.prefix(2)
            return two.map { ($0.lowerBound + $0.upperBound) / 2 }.sorted()
        }
        guard let band = wide.first else { return [] }
        let low = band.lowerBound + walkerHalfWidth
        let high = band.upperBound - walkerHalfWidth
        return [min(low, (low + high) / 2), max(high, (low + high) / 2)]
    }

    public static func movers(for layout: StoreLayout, detail: DetailLevel) -> [Mover] {
        let parked = layout.fixtures.filter { $0.kind == .parkedCar }.count
        let characters = AssetName.characterNames.sorted { $0.rawValue < $1.rawValue }
        var out: [Mover] = []
        var carOrdinal = 0
        var walkerOrdinal = 0
        for (laneIndex, lane) in lanes(for: layout).enumerated() {
            let count: Int
            switch lane.kind {
            case .car: count = detail.isFull ? 3 : 2
            case .pedestrian: count = detail.isFull ? 2 : 1
            }
            for i in 0..<count {
                let ordinal = lane.kind == .car ? carOrdinal : walkerOrdinal
                let id: String
                let asset: AssetName
                let length: Double
                switch lane.kind {
                case .car:
                    id = "moving_car_\(ordinal + 1)"
                    asset = ModelVariant.assetName(for: .parkedCar, variant: parked + ordinal)
                    length = carLength
                    carOrdinal += 1
                case .pedestrian:
                    id = "walker_\(ordinal + 1)"
                    asset = characters[ordinal % characters.count]
                    length = walkerLength
                    walkerOrdinal += 1
                }
                var mover = Mover(id: id, kind: lane.kind, asset: asset, ordinal: ordinal, lane: lane, offset: 0, length: length)
                mover.offset = Double(i) * loopLength(of: mover) / Double(count) + Double(laneIndex) * lanePhase
                out.append(mover)
            }
        }
        return out
    }

    /// Where in its walk cycle a walker starts, in seconds: every file carries the same clip, so
    /// without this the whole street steps in unison. Golden-ratio steps keep any two walkers apart.
    public static func walkCyclePhase(of mover: Mover, clipLength: Double) -> Double {
        let fraction = (Double(mover.ordinal) * 0.618_034).truncatingRemainder(dividingBy: 1)
        return fraction * clipLength
    }

    /// How far past the lot edge a mover wraps.
    public static func wrapMargin(of mover: Mover) -> Double { mover.length + wrapPadding }

    /// Metres of one full trip, lot width plus a margin at each end.
    public static func loopLength(of mover: Mover) -> Double {
        (mover.lane.xRange.upperBound - mover.lane.xRange.lowerBound) + 2 * wrapMargin(of: mover)
    }

    public static func pose(of mover: Mover, at time: Double) -> MoverPose {
        let loop = loopLength(of: mover)
        var s = (mover.offset + mover.lane.speed * time).truncatingRemainder(dividingBy: loop)
        if s < 0 { s += loop }
        let margin = wrapMargin(of: mover)
        let forward = mover.lane.direction > 0
        let x = forward ? mover.lane.xRange.lowerBound - margin + s : mover.lane.xRange.upperBound + margin - s
        let yaw: Double
        switch mover.kind {
        case .car:
            // The car's front is +X.
            yaw = forward ? 0 : .pi
        case .pedestrian:
            // A quarter turn takes the figure's front (+Z) to +X.
            let base = forward ? Double.pi / 2 : -Double.pi / 2
            yaw = walkerFacesPlusZ ? base : base + .pi
        }
        return MoverPose(position: SIMD3(x, 0, mover.lane.z), yaw: yaw)
    }
}
