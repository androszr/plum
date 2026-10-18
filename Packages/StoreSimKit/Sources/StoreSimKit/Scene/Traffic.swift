import Foundation
import simd

public enum MoverKind: Sendable, Equatable {
    case car
    case pedestrian
}

/// A straight line along X that movers follow, always the same way.
public struct TrafficLane: Sendable, Equatable {
    public var id: String
    public var kind: MoverKind
    /// Metres on the ground plane.
    public var z: Double
    /// +1 moves toward +X, -1 toward -X.
    public var direction: Double
    /// The lot's x extent in metres.
    public var xRange: ClosedRange<Double>

    public init(id: String, kind: MoverKind, z: Double, direction: Double, xRange: ClosedRange<Double>) {
        self.id = id
        self.kind = kind
        self.z = z
        self.direction = direction
        self.xRange = xRange
    }
}

/// One car or walker: a lane and its seat among the lane's movers. Nothing here is stored in the layout.
public struct Mover: Sendable, Equatable {
    public var id: String
    public var kind: MoverKind
    public var asset: AssetName
    /// Counts within the kind, from 0.
    public var ordinal: Int
    public var lane: TrafficLane
    /// This mover's place among the lane's movers, from 0, and how many the lane has.
    public var seat: Int
    public var seats: Int
    /// Metres along the direction of travel.
    public var length: Double

    public init(id: String, kind: MoverKind, asset: AssetName, ordinal: Int, lane: TrafficLane, seat: Int, seats: Int, length: Double) {
        self.id = id
        self.kind = kind
        self.asset = asset
        self.ordinal = ordinal
        self.lane = lane
        self.seat = seat
        self.seats = seats
        self.length = length
    }
}

public struct MoverPose: Sendable, Equatable {
    public var position: SIMD3<Double>
    public var yaw: Double
    /// 0 hidden, 1 fully shown; between, it is fading in or out at the lot edge.
    public var visibility: Double
    /// Metres per second along the lane at this moment; 0 while hidden.
    public var speed: Double
    public init(position: SIMD3<Double>, yaw: Double, visibility: Double = 1, speed: Double = 0) {
        self.position = position
        self.yaw = yaw
        self.visibility = visibility
        self.speed = speed
    }
}

/// How one kind of mover is timetabled. Time is cut into slots of one `period`; in each slot a lane
/// either stays empty or sends one mover across, sometimes with a second following at the same speed.
/// The slot is long enough for the slowest crossing, so a lane never has two movers that could meet.
public struct TrafficTimetable: Sendable, Equatable {
    /// Metres per second, drawn per crossing.
    public var speeds: ClosedRange<Double>
    /// Chance that a slot sends anybody.
    public var presence: Double
    /// Chance that a second mover follows the first, when the lane has two.
    public var pairChance: Double
    /// Metres between the first mover's tail and the follower's nose.
    public var gaps: ClosedRange<Double>
    /// Metres inside the lot edge over which a mover fades in or out.
    public var fade: Double
}

/// Decorative street traffic, derived from the lot's zones and a clock. Pure: no collisions,
/// no state; the same time always gives the same pose. Who crosses when, and how fast, comes from a
/// seeded hash of the lane and the slot, so the street looks random but every run is the same.
public enum Traffic {
    public static let carTimetable = TrafficTimetable(speeds: 3.5...6.0, presence: 0.85, pairChance: 0.3,
                                                      gaps: 6...14, fade: 2.0)
    public static let walkerTimetable = TrafficTimetable(speeds: 1.1...1.6, presence: 0.85, pairChance: 0.25,
                                                         gaps: 1.5...4, fade: 1.0)
    /// The shipped walk clip walks in place: a planted foot slides back this fast (0.74 m in 0.5 s,
    /// measured on all three characters). Played at speed / this, the feet stay put on the pavement.
    public static let walkClipSpeed = 1.45
    /// A hidden mover waits this far beyond its own length past the lot edge.
    public static let wrapPadding = 2.0
    public static let carLength = 4.5
    public static let walkerLength = 0.6
    /// Height of a walker in metres, the brief's figure.
    public static let walkerHeight = 1.75
    /// Walkers face +Z in the brief and in the stand-in. Flip this one constant if a Meshy export turns out to face -Z.
    public static let walkerFacesPlusZ = true
    /// Half the width a walker needs sideways (hips measured 0.36 m on the shipped characters).
    public static let walkerHalfWidth = 0.18

    public static func lanes(for layout: StoreLayout) -> [TrafficLane] {
        let lot = layout.lot
        let xRange = 0.0...(Double(lot.size.w) * cellSize)
        var out: [TrafficLane] = []
        if let street = lot.zones(of: .street).first {
            let lo = Double(street.rect.minZ) * cellSize
            let depth = Double(street.rect.size.d) * cellSize
            out.append(TrafficLane(id: "car_near", kind: .car, z: lo + depth / 4, direction: -1, xRange: xRange))
            out.append(TrafficLane(id: "car_far", kind: .car, z: lo + 3 * depth / 4, direction: 1, xRange: xRange))
        }
        for (label, kind) in [("near", Zone.Kind.sidewalk), ("far", .farSidewalk)] {
            guard let zone = lot.zones(of: kind).first else { continue }
            // Right-hand walking: heading +X keeps +Z on the right, so the +1 line is the one with the larger z.
            let lines = walkingLines(in: zone, layout: layout).sorted()
            for (i, z) in lines.enumerated() {
                let forward = i == lines.count - 1
                out.append(TrafficLane(id: "walk_\(label)_\(forward ? "forward" : "backward")", kind: .pedestrian, z: z,
                                       direction: forward ? 1 : -1, xRange: xRange))
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
        for lane in lanes(for: layout) {
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
                out.append(Mover(id: id, kind: lane.kind, asset: asset, ordinal: ordinal, lane: lane,
                                 seat: i, seats: count, length: length))
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

    public static func timetable(for kind: MoverKind) -> TrafficTimetable {
        kind == .car ? carTimetable : walkerTimetable
    }

    /// How far past the lot edge a hidden mover waits.
    public static func wrapMargin(of mover: Mover) -> Double { mover.length + wrapPadding }

    /// Metres of one crossing, lot width plus a margin at each end.
    public static func crossing(of mover: Mover) -> Double {
        (mover.lane.xRange.upperBound - mover.lane.xRange.lowerBound) + 2 * wrapMargin(of: mover)
    }

    /// Seconds per slot: the slowest crossing of a pair, plus a second.
    public static func slotPeriod(of mover: Mover) -> Double {
        let t = timetable(for: mover.kind)
        return (crossing(of: mover) + t.gaps.upperBound + mover.length) / t.speeds.lowerBound + 1
    }

    /// One slot of a lane's timetable, the same for every mover of the lane.
    public struct Slot: Sendable, Equatable {
        public var present: Bool
        public var speed: Double
        /// The seat that leads, and the one following it (nil when nobody follows).
        public var lead: Int
        public var follower: Int?
        /// Metres from the leader's tail to the follower's nose.
        public var gap: Double
        /// Seconds into the slot when the leader sets off.
        public var delay: Double
    }

    public static func slot(_ index: Int, of mover: Mover) -> Slot {
        let t = timetable(for: mover.kind)
        var rng = SlotRandom(lane: mover.lane.id, slot: index)
        let present = rng.next() < t.presence
        let speed = t.speeds.lowerBound + rng.next() * (t.speeds.upperBound - t.speeds.lowerBound)
        let lead = min(Int(rng.next() * Double(mover.seats)), mover.seats - 1)
        let paired = mover.seats >= 2 && rng.next() < t.pairChance
        let gap = t.gaps.lowerBound + rng.next() * (t.gaps.upperBound - t.gaps.lowerBound)
        let travel = (crossing(of: mover) + (paired ? gap + mover.length : 0)) / speed
        let delay = rng.next() * max(0, slotPeriod(of: mover) - travel)
        return Slot(present: present, speed: speed, lead: lead, follower: paired ? (lead + 1) % mover.seats : nil,
                    gap: gap, delay: delay)
    }

    /// How fast to play the walk clip for a walker moving at `speed`, so its feet do not slide.
    public static func walkCycleRate(at speed: Double) -> Double { speed / walkClipSpeed }

    public static func pose(of mover: Mover, at time: Double) -> MoverPose {
        let period = slotPeriod(of: mover)
        let index = Int((time / period).rounded(.down))
        let slot = slot(index, of: mover)
        let behind: Double? = mover.seat == slot.lead ? 0 : (mover.seat == slot.follower ? slot.gap + mover.length : nil)
        var s = -1.0
        if slot.present, let behind { s = slot.speed * (time - Double(index) * period - slot.delay) - behind }
        let span = crossing(of: mover)
        let shown = s >= 0 && s <= span
        let margin = wrapMargin(of: mover)
        let forward = mover.lane.direction > 0
        let along = shown ? s : 0
        let x = forward ? mover.lane.xRange.lowerBound - margin + along : mover.lane.xRange.upperBound + margin - along
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
        var visibility = 0.0
        if shown {
            // Metres the whole body is inside the lot; nothing is drawn over the void beyond it.
            let inside = min(x - mover.length / 2 - mover.lane.xRange.lowerBound,
                             mover.lane.xRange.upperBound - (x + mover.length / 2))
            visibility = min(1, max(0, inside / timetable(for: mover.kind).fade))
        }
        return MoverPose(position: SIMD3(x, 0, mover.lane.z), yaw: yaw, visibility: visibility,
                         speed: visibility > 0 ? slot.speed : 0)
    }
}

/// SplitMix64 seeded from a lane id (FNV-1a, stable across runs, unlike `Hasher`) and a slot index.
struct SlotRandom {
    private var state: UInt64

    init(lane: String, slot: Int) {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in lane.utf8 { h = (h ^ UInt64(byte)) &* 0x0000_0100_0000_01b3 }
        state = h ^ (UInt64(bitPattern: Int64(slot)) &* 0x9e37_79b9_7f4a_7c15)
    }

    /// Uniform in [0, 1).
    mutating func next() -> Double {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}
