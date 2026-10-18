import Foundation
import simd

/// Where a person can stand in the shop, derived from a `StoreLayout`. Points are ground
/// positions `(x, z)` in metres.
public struct WalkableFloor: Sendable {
    public let shop: GridRect
    /// The validator's free interior cells: every interior cell no floor fixture covers.
    public let free: Set<GridCell>
    /// The cells a person may stand in: `free` minus the row (or column) of the shop edge that
    /// holds the entrance, which is where the front wall, the glazing and the door leaves stand.
    public let walkable: Set<GridCell>
    /// The staff strips behind the tills and in front of the cabinets: walkable, but not a
    /// customer's first view.
    public let staff: Set<GridCell>

    /// How far the eye stays clear of every wall and fixture, in metres.
    public static let clearance = 0.2

    public init(layout: StoreLayout) {
        shop = layout.lot.zones(of: .storeInterior).first?.rect ?? GridRect(x: 0, z: 0, w: 0, d: 0)
        free = Self.freeInteriorCells(of: layout)
        let e = layout.lot.entrance
        let rect = shop
        walkable = free.filter { c in
            if e.z >= rect.maxZ - 1 { return c.z < rect.maxZ - 1 }
            if e.z <= rect.minZ { return c.z > rect.minZ }
            if e.x >= rect.maxX - 1 { return c.x < rect.maxX - 1 }
            if e.x <= rect.minX { return c.x > rect.minX }
            return true
        }
        staff = Set(layout.fixtures.filter { $0.kind.occupiesFloor }.flatMap(\.staffCells)).intersection(walkable)
    }

    private init(shop: GridRect, free: Set<GridCell>, walkable: Set<GridCell>, staff: Set<GridCell>) {
        self.shop = shop
        self.free = free
        self.walkable = walkable
        self.staff = staff
    }

    /// The same floor with the staff strips taken out: what a customer walking in can see.
    public var customerFloor: WalkableFloor {
        WalkableFloor(shop: shop, free: free, walkable: walkable.subtracting(staff), staff: [])
    }

    /// Every interior cell not covered by a floor-standing fixture. The layout validator uses
    /// the same set, so "free floor" has one definition.
    public static func freeInteriorCells(of layout: StoreLayout) -> Set<GridCell> {
        var blocked = Set<GridCell>()
        for f in layout.fixtures where f.kind.occupiesFloor { blocked.formUnion(f.occupiedRect.cells) }
        var free = Set<GridCell>()
        for zone in layout.lot.zones(of: .storeInterior) {
            for c in zone.rect.cells where !blocked.contains(c) { free.insert(c) }
        }
        return free
    }

    public func cell(at p: SIMD2<Double>) -> GridCell {
        GridCell(x: Int((p.x / cellSize).rounded(.down)), z: Int((p.y / cellSize).rounded(.down)))
    }

    public func centre(of cell: GridCell) -> SIMD2<Double> {
        SIMD2((Double(cell.x) + 0.5) * cellSize, (Double(cell.z) + 0.5) * cellSize)
    }

    /// True when the point, the four points one clearance away on x and z and the four diagonal
    /// points are all walkable floor.
    public func isWalkable(_ p: SIMD2<Double>) -> Bool {
        let c = Self.clearance
        let probes = [p, SIMD2(p.x - c, p.y), SIMD2(p.x + c, p.y), SIMD2(p.x, p.y - c), SIMD2(p.x, p.y + c),
                      SIMD2(p.x - c, p.y - c), SIMD2(p.x + c, p.y - c),
                      SIMD2(p.x - c, p.y + c), SIMD2(p.x + c, p.y + c)]
        return probes.allSatisfy { walkable.contains(cell(at: $0)) }
    }

    /// The move to `to`, or the part of it a wall allows: x only, then z only, else stay.
    public func resolve(from: SIMD2<Double>, to: SIMD2<Double>) -> SIMD2<Double> {
        if isWalkable(to) { return to }
        let xOnly = SIMD2(to.x, from.y)
        if isWalkable(xOnly) { return xOnly }
        let zOnly = SIMD2(from.x, to.y)
        if isWalkable(zOnly) { return zOnly }
        return from
    }

    /// The centre of the closest free cell within `radius` whose centre is walkable.
    public func nearestWalkable(to p: SIMD2<Double>, within radius: Double) -> SIMD2<Double>? {
        let reach = Int((radius / cellSize).rounded(.up)) + 1
        let origin = cell(at: p)
        var best: (d: Double, p: SIMD2<Double>)?
        for dx in -reach...reach {
            for dz in -reach...reach {
                let c = GridCell(x: origin.x + dx, z: origin.z + dz)
                guard walkable.contains(c) else { continue }
                let centre = centre(of: c)
                guard isWalkable(centre) else { continue }
                let d = simd_length(centre - p)
                if d <= radius, best == nil || d < best!.d { best = (d, centre) }
            }
        }
        return best?.p
    }

    /// Cell centres along a shortest 4-neighbour path, then `to` itself. Empty when there is no route.
    public func route(from: SIMD2<Double>, to: SIMD2<Double>) -> [SIMD2<Double>] {
        let start = cell(at: from), goal = cell(at: to)
        guard walkable.contains(start), walkable.contains(goal), isWalkable(to) else { return [] }
        var previous: [GridCell: GridCell] = [:]
        var seen: Set<GridCell> = [start]
        var queue = [start]
        var head = 0
        search: while head < queue.count {
            let cur = queue[head]
            head += 1
            if cur == goal { break search }
            for d in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let n = GridCell(x: cur.x + d.0, z: cur.z + d.1)
                if walkable.contains(n), !seen.contains(n) {
                    seen.insert(n)
                    previous[n] = cur
                    queue.append(n)
                }
            }
        }
        guard seen.contains(goal) else { return [] }
        var cells: [GridCell] = []
        var cursor = goal
        while cursor != start {
            cells.append(cursor)
            cursor = previous[cursor]!
        }
        return cells.reversed().map { centre(of: $0) } + [to]
    }

    /// How far a walker can go from `from` along `heading` (the camera yaw convention) before
    /// the floor ends, capped at `limit`.
    public func clearDistance(from: SIMD2<Double>, heading: Double, limit: Double) -> Double {
        let dir = SIMD2(-sin(heading), -cos(heading))
        var d = 0.0
        let step = 0.05
        while d + step <= limit {
            if !isWalkable(from + dir * (d + step)) { return d }
            d += step
        }
        return limit
    }
}
