import Foundation
import simd

/// The first-person Inside camera: where you stand, which way you face, how far you look up.
public struct WalkCamera: Equatable, Sendable {
    /// Ground position `(x, z)` in metres.
    public var position: SIMD2<Double>
    /// Radians, wrapped into [0, 2pi). Same convention as `OrbitCamera`: 0 looks towards -Z.
    public var yaw: Double
    /// Radians; positive looks up. Clamped to `pitchLimit`.
    public var pitch: Double
    /// Waypoints still to walk, nearest first.
    public var route: [SIMD2<Double>] = []

    public static let eyeHeight = 1.6
    public static let pitchLimit = 60.0 * Double.pi / 180
    public static let walkSpeed = 1.4
    public static let turnStep = OrbitCamera.rotateStep
    public static let lookYawPerPoint = 0.005
    public static let lookPitchPerPoint = 0.004
    public static let scrollMetresPerPoint = 0.01

    public init(position: SIMD2<Double>, yaw: Double, pitch: Double = 0) {
        self.position = position
        self.yaw = OrbitCamera.wrap(yaw)
        self.pitch = min(max(pitch, -Self.pitchLimit), Self.pitchLimit)
    }

    public var forward: SIMD3<Double> {
        SIMD3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
    }

    public var pose: CameraPose {
        let eye = SIMD3(position.x, Self.eyeHeight, position.y)
        return CameraPose(eye: eye, target: eye + forward)
    }

    /// Drag: right turns the head right, down looks down.
    public mutating func look(by delta: SIMD2<Double>) {
        yaw = OrbitCamera.wrap(yaw - delta.x * Self.lookYawPerPoint)
        pitch = min(max(pitch - delta.y * Self.lookPitchPerPoint, -Self.pitchLimit), Self.pitchLimit)
    }

    public mutating func turn(by angle: Double) { yaw = OrbitCamera.wrap(yaw + angle) }

    /// Positive steps turn left, like `OrbitCamera.turned`.
    public func turned(by steps: Int) -> WalkCamera {
        var c = self
        c.turn(by: Double(steps) * Self.turnStep)
        return c
    }

    public func interpolated(to other: WalkCamera, t: Double) -> WalkCamera {
        var c = other
        c.position = position + (other.position - position) * t
        c.pitch = pitch + (other.pitch - pitch) * t
        var delta = (other.yaw - yaw).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi }
        if delta <= -.pi { delta += 2 * .pi }
        c.yaw = OrbitCamera.wrap(yaw + delta * t)
        return c
    }

    private var groundForward: SIMD2<Double> { SIMD2(-sin(yaw), -cos(yaw)) }
    private var groundRight: SIMD2<Double> { SIMD2(cos(yaw), -sin(yaw)) }

    /// Input x is sidestep (right positive), y is forward; clamped to unit length.
    public mutating func walk(input: SIMD2<Double>, dt: Double, on floor: WalkableFloor) {
        var v = input
        let len = simd_length(v)
        guard len > 0 else { return }
        if len > 1 { v /= len }
        route = []
        let move = (groundRight * v.x + groundForward * v.y) * (Self.walkSpeed * dt)
        position = floor.resolve(from: position, to: position + move)
    }

    /// Longest single resolved move; `resolve` checks only the end point, so longer moves are cut up.
    static let maxResolvedMove = 0.1

    /// A move of `metres` along the ground forward (negative walks back), resolved in short pieces
    /// so a long trackpad flick stops at a fixture instead of landing beyond it.
    public mutating func step(forward metres: Double, on floor: WalkableFloor) {
        route = []
        let pieces = max(1, Int((abs(metres) / Self.maxResolvedMove).rounded(.up)))
        let piece = groundForward * (metres / Double(pieces))
        for _ in 0..<pieces {
            position = floor.resolve(from: position, to: position + piece)
        }
    }

    @discardableResult
    public mutating func stroll(to point: SIMD2<Double>, on floor: WalkableFloor) -> Bool {
        let goal = floor.isWalkable(point) ? point : (floor.nearestWalkable(to: point, within: 1.0) ?? point)
        route = floor.route(from: position, to: goal)
        return !route.isEmpty
    }

    public var isStrolling: Bool { !route.isEmpty }

    /// Walks towards the next waypoint; a step that makes no progress ends the stroll.
    public mutating func advance(dt: Double, on floor: WalkableFloor) {
        guard let target = route.first else { return }
        let d = target - position
        let dist = simd_length(d)
        if dist <= 0.05 {
            route.removeFirst()
            return
        }
        let to = position + d / dist * min(Self.walkSpeed * dt, dist)
        let moved = floor.resolve(from: position, to: to)
        if moved == position {
            route = []
            return
        }
        position = moved
        if simd_length(target - position) <= 0.05 { route.removeFirst() }
    }

    /// Stands just inside the entrance (the entrance row itself is the door and front wall, which
    /// the floor keeps you off) and faces along an aisle: an axis-aligned heading (a multiple of
    /// 90 degrees). It looks at the walkable spots within 1.5 m of the entrance centre, starting
    /// one cell in, and takes the heading and spot with the longest open view (ties go to the
    /// spot nearest the entrance, then to the heading closest to the shop centre).
    public static let minimumView = 3.0

    public static func preset(lot: Lot, floor: WalkableFloor) -> WalkCamera {
        // Aim along the customer floor, so the first view never runs down a staff strip.
        let aim = floor.customerFloor
        let shop = floor.shop
        let entrance = floor.centre(of: lot.entrance)
        let centre = shop.centreMetres
        var inward = SIMD2<Double>(0, 0)
        if lot.entrance.z >= shop.maxZ - 1 { inward = SIMD2(0, -1) }
        else if lot.entrance.z <= shop.minZ { inward = SIMD2(0, 1) }
        else if lot.entrance.x >= shop.maxX - 1 { inward = SIMD2(-1, 0) }
        else if lot.entrance.x <= shop.minX { inward = SIMD2(1, 0) }
        else { inward = abs(centre.x - entrance.x) > abs(centre.y - entrance.y)
                ? SIMD2(centre.x > entrance.x ? 1 : -1, 0) : SIMD2(0, centre.y > entrance.y ? 1 : -1) }
        let tangent = SIMD2(inward.y, inward.x)

        func angleGap(_ a: Double, _ b: Double) -> Double {
            var d = (a - b).truncatingRemainder(dividingBy: 2 * .pi)
            if d > .pi { d -= 2 * .pi }
            if d < -.pi { d += 2 * .pi }
            return abs(d)
        }

        var best: (view: Double, distance: Double, gap: Double, position: SIMD2<Double>, yaw: Double)?
        for steps in 1...3 {
            for offset in [0.0, 0.5, -0.5, 1.0, -1.0] {
                let position = entrance + inward * (cellSize * Double(steps)) + tangent * offset
                let distance = simd_length(position - entrance)
                guard distance <= 1.5, aim.isWalkable(position) else { continue }
                let toCentre = atan2(-(centre.x - position.x), -(centre.y - position.y))
                for k in 0..<4 {
                    let yaw = OrbitCamera.wrap(Double(k) * .pi / 2)
                    let view = aim.clearDistance(from: position, heading: yaw, limit: 10)
                    let gap = angleGap(yaw, toCentre)
                    let better: Bool
                    if let b = best {
                        if abs(view - b.view) > 1e-6 { better = view > b.view }
                        else if abs(distance - b.distance) > 1e-6 { better = distance < b.distance }
                        else { better = gap < b.gap }
                    } else { better = true }
                    if better { best = (view, distance, gap, position, yaw) }
                }
            }
        }
        if let b = best { return WalkCamera(position: b.position, yaw: b.yaw, pitch: 0) }
        let fallback = floor.nearestWalkable(to: entrance + inward * cellSize, within: 1.5) ?? entrance
        return WalkCamera(position: fallback, yaw: 0, pitch: 0)
    }

    /// The ground point under a tap, or nil when the ray does not reach the floor.
    /// `viewSize` and `tap` are in points; the field of view is the vertical one.
    public static func floorPoint(pose: CameraPose, tap: SIMD2<Double>, viewSize: SIMD2<Double>,
                                  verticalFOVDegrees: Double = 45) -> SIMD2<Double>? {
        guard viewSize.x > 0, viewSize.y > 0 else { return nil }
        let f = simd_normalize(pose.target - pose.eye)
        let r = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let u = simd_cross(r, f)
        let tanHalf = tan(verticalFOVDegrees * .pi / 360)
        let nx = (tap.x / viewSize.x * 2 - 1) * tanHalf * (viewSize.x / viewSize.y)
        let ny = (1 - tap.y / viewSize.y * 2) * tanHalf
        let dir = f + r * nx + u * ny
        guard dir.y < -1e-9 else { return nil }
        let t = -pose.eye.y / dir.y
        guard t > 0 else { return nil }
        let hit = pose.eye + dir * t
        return SIMD2(hit.x, hit.z)
    }
}
