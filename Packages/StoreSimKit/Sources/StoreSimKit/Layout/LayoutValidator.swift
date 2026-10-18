import Foundation

public enum LayoutIssue: Equatable, Sendable {
    case overlap(String, String)
    case outsideLot(String)
    case wrongZone(String)
    case unreachable(GridCell)
    case aisleTooNarrow(GridCell)
}

public enum LayoutValidator {
    public static func validate(_ layout: StoreLayout) -> [LayoutIssue] {
        var issues: [LayoutIssue] = []
        let fixtures = layout.fixtures
        let lot = layout.lot

        for f in fixtures where !lot.bounds.contains(f.occupiedRect) {
            issues.append(.outsideLot(f.id))
        }
        for f in fixtures where lot.bounds.contains(f.occupiedRect) {
            let ok = lot.zones.contains { f.kind.zoneKinds.contains($0.kind) && $0.rect.contains(f.occupiedRect) }
            if !ok { issues.append(.wrongZone(f.id)) }
        }
        let solid = fixtures.filter { $0.kind.occupiesFloor }
        for i in solid.indices {
            for j in solid.indices where j > i && solid[i].occupiedRect.intersects(solid[j].occupiedRect) {
                issues.append(.overlap(solid[i].id, solid[j].id))
            }
        }

        // Walkability of the store interior.
        var blocked = Set<GridCell>()
        for f in solid { blocked.formUnion(f.occupiedRect.cells) }
        var staff = Set<GridCell>()
        for f in solid { staff.formUnion(f.staffCells) }
        var free = Set<GridCell>()
        for zone in lot.zones(of: .storeInterior) {
            for c in zone.rect.cells where !blocked.contains(c) { free.insert(c) }
        }

        var reached = Set<GridCell>()
        if free.contains(lot.entrance) {
            var stack = [lot.entrance]
            reached.insert(lot.entrance)
            while let cur = stack.popLast() {
                for d in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                    let n = GridCell(x: cur.x + d.0, z: cur.z + d.1)
                    if free.contains(n), !reached.contains(n) {
                        reached.insert(n)
                        stack.append(n)
                    }
                }
            }
        }
        let sorted = free.sorted { ($0.z, $0.x) < ($1.z, $1.x) }
        for c in sorted where !reached.contains(c) { issues.append(.unreachable(c)) }

        // A free cell must sit in a fully free 2x2 block (a one metre aisle), unless it lies along a
        // fixture's staff side (behind a till, in front of the tobacco cabinet or the alcohol wall),
        // where half a metre is enough.
        func blockFree(_ x: Int, _ z: Int) -> Bool {
            free.contains(GridCell(x: x, z: z)) && free.contains(GridCell(x: x + 1, z: z))
                && free.contains(GridCell(x: x, z: z + 1)) && free.contains(GridCell(x: x + 1, z: z + 1))
        }
        for c in sorted {
            let wide = blockFree(c.x, c.z) || blockFree(c.x - 1, c.z) || blockFree(c.x, c.z - 1) || blockFree(c.x - 1, c.z - 1)
            if !wide, !staff.contains(c) { issues.append(.aisleTooNarrow(c)) }
        }
        return issues
    }
}
