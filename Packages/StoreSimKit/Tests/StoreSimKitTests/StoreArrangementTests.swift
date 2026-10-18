import Foundation
import Testing
@testable import StoreSimKit

/// Pins the researched shop arrangement: dairy opposite drinks, two tills with the alcohol wall behind,
/// one island with a clear loop, coffee and baskets by the door.
@Suite struct StoreArrangementTests {
    static let layout = StoreLayout.plumCorner
    static let shop = layout.lot.zones(of: .storeInterior)[0].rect

    static func fixtures(_ kind: FixtureKind) -> [Fixture] { layout.fixtures.filter { $0.kind == kind } }

    /// Cells of the two-cell ring around the island (shelves plus end caps), as (x, z) pairs.
    static var islandRect: (minX: Int, maxX: Int, minZ: Int, maxZ: Int) {
        let rects = (fixtures(.gondolaShelf) + fixtures(.endCap).filter { $0.occupiedRect.minZ > shop.minZ })
            .map { $0.occupiedRect }
        return (rects.map(\.minX).min()!, rects.map(\.maxX).max()!, rects.map(\.minZ).min()!, rects.map(\.maxZ).max()!)
    }

    static var ring: [GridCell] {
        let i = islandRect
        var cells: [GridCell] = []
        for x in (i.minX - 2)..<(i.maxX + 2) {
            for z in (i.minZ - 2)..<(i.maxZ + 2) {
                let inside = x >= i.minX && x < i.maxX && z >= i.minZ && z < i.maxZ
                if !inside { cells.append(GridCell(x: x, z: z)) }
            }
        }
        return cells
    }

    static func covers(_ r: GridRect, _ c: GridCell) -> Bool {
        c.x >= r.minX && c.x < r.maxX && c.z >= r.minZ && c.z < r.maxZ
    }

    static func floorCovered(_ c: GridCell) -> Bool {
        layout.fixtures.contains { $0.kind.occupiesFloor && covers($0.occupiedRect, c) }
    }

    static func touches(_ a: GridRect, _ b: GridRect) -> Bool {
        let xOverlap = a.minX < b.maxX && b.minX < a.maxX
        let zOverlap = a.minZ < b.maxZ && b.minZ < a.maxZ
        return (xOverlap && (a.maxZ == b.minZ || b.maxZ == a.minZ)) || (zOverlap && (a.maxX == b.minX || b.maxX == a.minX))
    }

    static func gap(_ a: GridRect, _ b: GridRect) -> Int {
        let dx = max(0, max(a.minX - b.maxX, b.minX - a.maxX))
        let dz = max(0, max(a.minZ - b.maxZ, b.minZ - a.maxZ))
        return max(dx, dz)
    }

    @Test(.tags(.successCriterion)) func dairyChillersLineTheLeftWall() {
        let chillers = Self.fixtures(.dairyChiller)
        #expect(chillers.count >= 4)
        for f in chillers {
            #expect(f.rotation == QuarterTurn(1), "\(f.id)")
            #expect(f.occupiedRect.minX == Self.shop.minX, "\(f.id)")
        }
        for f in Self.fixtures(.wallFridge) { #expect(f.occupiedRect.minX != Self.shop.minX, "\(f.id) is a drinks fridge on the dairy wall") }
    }

    @Test(.tags(.successCriterion)) func drinksFridgesLineTheOppositeWall() {
        let fridges = Self.fixtures(.wallFridge)
        let right = fridges.filter { $0.rotation == QuarterTurn(3) && $0.occupiedRect.maxX == Self.shop.maxX }
        #expect(right.count >= 3)
        for f in fridges where !right.contains(f) { #expect(f.occupiedRect.minZ == Self.shop.minZ, "\(f.id)") }
        for f in Self.fixtures(.dairyChiller) { #expect(f.occupiedRect.maxX != Self.shop.maxX, "\(f.id)") }
    }

    /// Every cell along the staff side of a till, the alcohol wall or the tobacco cabinet.
    static var lane: Set<GridCell> {
        let kinds: [FixtureKind] = [.checkoutCounter, .alcoholWall, .cigaretteCabinet]
        return Set(kinds.flatMap { fixtures($0).flatMap(\.staffCells) })
    }

    /// Free interior cells reachable from `start` over `cells`, 4-neighbour.
    static func reachable(from start: GridCell, over cells: Set<GridCell>) -> Set<GridCell> {
        guard cells.contains(start) else { return [] }
        var seen: Set<GridCell> = [start]
        var stack = [start]
        while let cur = stack.popLast() {
            for d in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let n = GridCell(x: cur.x + d.0, z: cur.z + d.1)
                if cells.contains(n), !seen.contains(n) {
                    seen.insert(n)
                    stack.append(n)
                }
            }
        }
        return seen
    }

    @Test(.tags(.successCriterion)) func twoTillsFaceTheShopWithACashierLaneAndTheAlcoholWallBehind() {
        let tills = Self.fixtures(.checkoutCounter)
        #expect(tills.count == 2)
        let walls = Self.fixtures(.alcoholWall)
        for till in tills {
            #expect(till.rotation == QuarterTurn(2), "\(till.id)")
            let t = till.occupiedRect
            let wall = walls.first { $0.occupiedRect.minZ == t.maxZ + 1 && $0.occupiedRect.minX == t.minX && $0.occupiedRect.maxX == t.maxX }
            #expect(wall != nil, "\(till.id) has no alcohol wall with exactly one free cell behind it")
            let row = Set((t.minX..<t.maxX).map { GridCell(x: $0, z: t.maxZ) })
            #expect(row.allSatisfy { !Self.floorCovered($0) }, "\(till.id) lane is blocked")
            #expect(row == Set(wall?.staffCells ?? []), "\(till.id) lane is not the wall's staff row")
        }
    }

    @Test(.tags(.successCriterion)) func cashierLaneIsOneEmptyWalkableStrip() {
        let lane = Self.lane
        #expect(lane.count == 11)
        let free = Set(Self.shop.cells.filter { !Self.floorCovered($0) })
        let fromDoor = Self.reachable(from: Self.layout.lot.entrance, over: free)
        for c in lane {
            #expect(Self.shop.contains(c), "\(c) outside the shop")
            #expect(!Self.floorCovered(c), "\(c) is covered")
            #expect(fromDoor.contains(c), "\(c) cannot be reached from the door")
        }
        if let first = lane.first {
            #expect(Self.reachable(from: first, over: lane).count == lane.count, "the lane is not one strip")
        }
    }

    @Test(.tags(.successCriterion)) func tobaccoCabinetOpensOntoTheCashierLane() {
        let cabinet = Self.fixtures(.cigaretteCabinet)
        #expect(cabinet.count == 1)
        guard let c = cabinet.first else { return }
        #expect(!c.staffCells.isEmpty)
        let blockers = (Self.fixtures(.checkoutCounter) + Self.fixtures(.alcoholWall)).map(\.occupiedRect)
        for cell in c.staffCells {
            #expect(Self.lane.contains(cell))
            #expect(!Self.floorCovered(cell))
            #expect(!blockers.contains { Self.covers($0, cell) })
        }
    }

    @Test(.tags(.successCriterion)) func selfCheckoutStandsBesideTheTills() {
        let sc = Self.fixtures(.selfCheckout)
        #expect(sc.count == 1)
        let nearest = Self.fixtures(.checkoutCounter).map { Self.gap(sc[0].occupiedRect, $0.occupiedRect) }.min() ?? 99
        #expect(nearest <= 2)
    }

    @Test(.tags(.successCriterion)) func coffeeAndBasketsAreByTheEntrance() {
        let e = Self.layout.lot.entrance
        for f in Self.fixtures(.coffeeMachine) + Self.fixtures(.basketStack) {
            let d = max(abs(f.cell.x - e.x), abs(f.cell.z - e.z))
            #expect(d <= 3, "\(f.id) is \(d) cells from the entrance")
        }
        #expect(!Self.fixtures(.coffeeMachine).isEmpty && !Self.fixtures(.basketStack).isEmpty)
    }

    @Test(.tags(.successCriterion)) func oneIslandWithAClearLoop() {
        let shelves = Self.fixtures(.gondolaShelf).map(\.occupiedRect).sorted { $0.minX < $1.minX }
        #expect(!shelves.isEmpty)
        #expect(Set(shelves.map(\.minZ)).count == 1 && Set(shelves.map(\.maxZ)).count == 1)
        for (a, b) in zip(shelves, shelves.dropFirst()) { #expect(a.maxX == b.minX, "island shelves are not contiguous") }
        let caps = Self.fixtures(.endCap).map(\.occupiedRect).filter { $0.minZ > Self.shop.minZ }
        #expect(caps.contains { $0.maxX == shelves.first!.minX })
        #expect(caps.contains { $0.minX == shelves.last!.maxX })
        for c in Self.ring {
            #expect(Self.covers(Self.shop, c), "ring cell \(c) leaves the shop")
            #expect(!Self.floorCovered(c), "ring cell \(c) is blocked")
        }
    }

    @Test func pendantLampsHangOverTheLoop() {
        let lamps = Self.fixtures(.pendantLamp)
        #expect(lamps.count >= 6)
        for l in lamps {
            #expect(Self.ring.contains(l.cell), "\(l.id) is not over the loop")
            #expect(!Self.floorCovered(l.cell), "\(l.id) hangs over a fixture")
        }
    }

    @Test func shelvingCarriesDistinctLabels() {
        let shelving = Self.layout.fixtures.filter { [.gondolaShelf, .wallShelf, .endCap].contains($0.kind) }
        let labels = shelving.compactMap(\.label).filter { !$0.isEmpty }
        #expect(labels.count == shelving.count)
        #expect(Set(labels).count == labels.count)
    }

    @Test func cafeCornerTouchesTheTills() {
        let counter = Self.fixtures(.hotFoodCounter)
        #expect(counter.count == 1)
        let tills = Self.fixtures(.checkoutCounter).map(\.occupiedRect)
        #expect(tills.contains { Self.touches(counter[0].occupiedRect, $0) })
        let screens = Self.fixtures(.menuScreen)
        #expect(screens.count == 1)
        #expect(screens[0].rotation == counter[0].rotation)
        let c = counter[0].occupiedRect, s = screens[0].occupiedRect
        #expect(s.minZ == c.minZ && s.maxZ == c.maxZ)
        #expect(s.minX >= c.minX && s.maxX <= Self.shop.maxX)
    }
}

extension Tag {
    @Tag static var successCriterion: Self
}
