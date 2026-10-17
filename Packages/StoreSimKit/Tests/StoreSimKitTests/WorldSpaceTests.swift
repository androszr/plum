import Foundation
import Testing
@testable import StoreSimKit

/// Facts about where things stand in composed world space.
@Suite struct WorldSpaceTests {
    static let layout = StoreLayout.plumCorner
    static let root = SceneComposer.compose(layout: layout, detail: .full, catalogue: .empty)

    struct Box { var minX = Double.infinity, maxX = -Double.infinity, minZ = Double.infinity, maxZ = -Double.infinity }

    /// Ground-plane extent of every box-like part under `node`, in the node's parent space.
    static func extent(of node: SceneNode, includingSelf: Bool = true) -> Box {
        var box = Box()
        func walk(_ n: SceneNode, _ ox: Double, _ oz: Double, _ yaw: Double) {
            let c = cos(yaw), s = sin(yaw)
            let px = ox + n.position.x * c + n.position.z * s
            let pz = oz - n.position.x * s + n.position.z * c
            let totalYaw = yaw + n.yaw
            switch n.shape {
            case .box, .roundedBox, .cylinder:
                var sx = n.size.x, sz = n.size.z
                if abs(n.roll - .pi / 2) < 1e-6 { sx = n.size.y }
                if abs(n.pitch - .pi / 2) < 1e-6 { sz = n.size.y }
                let tc = cos(totalYaw), ts = sin(totalYaw)
                for (dx, dz) in [(-sx / 2, -sz / 2), (sx / 2, -sz / 2), (-sx / 2, sz / 2), (sx / 2, sz / 2)] {
                    let x = px + dx * tc + dz * ts
                    let z = pz - dx * ts + dz * tc
                    box.minX = min(box.minX, x); box.maxX = max(box.maxX, x)
                    box.minZ = min(box.minZ, z); box.maxZ = max(box.maxZ, z)
                }
            default: break
            }
            for child in n.children { walk(child, px, pz, totalYaw) }
        }
        // Children inherit the node's own placement; start at the node's position and yaw.
        let c = cos(node.yaw), s = sin(node.yaw)
        _ = (c, s)
        for child in node.children { walk(child, node.position.x, node.position.z, node.yaw) }
        return box
    }

    static var shop: (minX: Double, maxX: Double, minZ: Double) {
        let r = layout.lot.zones(of: .storeInterior)[0].rect
        return (Double(r.minX) * cellSize, Double(r.maxX) * cellSize, Double(r.minZ) * cellSize)
    }

    @Test func wallLineFixturesHangFlushOnTheirWall() {
        let wallKinds: Set<FixtureKind> = [.wallShelf, .wallFridge, .dairyChiller, .hotFoodCounter, .menuScreen,
                                           .backRoomDoor, .cigaretteCabinet]
        let fixtures = Self.root.node(named: "fixtures")!
        var checked = 0
        for f in Self.layout.fixtures where wallKinds.contains(f.kind) {
            let r = f.occupiedRect
            let zone = Self.layout.lot.zones(of: .storeInterior)[0].rect
            let node = fixtures.children.first { $0.name == f.id }!
            let e = Self.extent(of: node)
            // Distance between the fixture's back and the wall it hangs on (negative means inside the wall).
            var gap: Double?
            if r.minZ == zone.minZ, f.rotation.rawValue == 0 { gap = e.minZ - Self.shop.minZ }
            else if r.minX == zone.minX, f.rotation.rawValue == 1 { gap = e.minX - Self.shop.minX }
            else if r.maxX == zone.maxX, f.rotation.rawValue == 3 { gap = Self.shop.maxX - e.maxX }
            guard let gap else { continue }
            checked += 1
            #expect(gap >= -0.001, "\(f.id) is inside its wall by \(-gap) m")
            #expect(gap <= 0.08, "\(f.id) floats \(gap) m off its wall")
        }
        #expect(checked >= 12, "only \(checked) wall fixtures were checked")
    }

    @Test func menuScreenSelectionBoxSitsOnItsFixture() {
        let f = Self.layout.fixtures.first { $0.kind == .menuScreen }!
        let node = Self.root.node(named: f.id)!
        let e = Self.extent(of: node)
        #expect(e.minZ >= Self.shop.minZ - 0.001)
        let b = node.bounds!
        #expect(node.position.z - b.size.z / 2 >= Self.shop.minZ - 0.001)
        #expect(e.maxZ <= node.position.z + b.size.z / 2 + 0.001)
    }

    @Test func gondolasAreDoubleSided() {
        let g = Self.root.node(named: "gondola_a1")!
        let names = Set(g.descendants.map(\.name))
        for want in ["shelf_0", "shelf_back_0", "price_rail_0", "price_rail_back_0", "header_text_back"] {
            #expect(names.contains(want), "missing \(want)")
        }
        let back = g.descendants.filter { $0.name.hasPrefix("product_back_") && !$0.name.hasSuffix("_neck") }
        let front = g.descendants.filter { $0.name.hasPrefix("product_") && !$0.name.hasPrefix("product_back_") && !$0.name.hasSuffix("_neck") }
        #expect(back.count >= 16 && front.count >= 16)
        #expect(back.allSatisfy { $0.position.z < 0 })
        #expect(front.allSatisfy { $0.position.z > 0 })
    }

    @Test func doorwayIsClearOfGlassAndMullions() {
        let entrance = Self.layout.lot.entrance
        let doorX = (Double(entrance.x) + 0.5) * cellSize
        let half = Double(FixtureKind.entranceDoor.footprint.w) * cellSize / 2
        let glazing = Self.root.node(named: "storefront_glazing")!
        for part in glazing.children where part.name != "glazing_transom" {
            let lo = part.position.x - part.size.x / 2, hi = part.position.x + part.size.x / 2
            #expect(hi <= doorX - half + 0.001 || lo >= doorX + half - 0.001, "\(part.name) spans the doorway")
        }
        let building = Self.root.node(named: "building")!
        for m in building.children where m.name.hasPrefix("mullion_") && !m.name.hasPrefix("mullion_door") {
            #expect(m.position.x < doorX - half || m.position.x > doorX + half, "\(m.name) stands in the doorway")
        }
        #expect(building.children.contains { $0.name == "mullion_door_left" })
    }

    @Test func parkingMarkingsStayOutFromUnderCars() {
        let cars = Self.layout.fixtures.filter { $0.kind == .parkedCar }.map(\.occupiedRect)
        let markings = Self.root.allNodes().filter { $0.name.hasPrefix("parking_marking_") }
        #expect(markings.count >= cars.count)
        for m in markings {
            for car in cars {
                let lo = m.position.x - m.size.x / 2, hi = m.position.x + m.size.x / 2
                let clear = hi <= Double(car.minX) * cellSize || lo >= Double(car.maxX) * cellSize
                #expect(clear, "\(m.name) lies under a car")
            }
        }
    }

    @Test func opaqueShellBlocksPickingButIsNotSelectable() {
        for name in ["store_wall_back", "store_wall_left", "store_wall_right", "facade", "neighbour_left", "neighbour_right"] {
            let n = Self.root.node(named: name)!
            #expect(n.blocksPicking && !n.selectable, "\(name)")
        }
        #expect(Self.root.node(named: "store_roof")!.blocksPicking == false)
    }

    // MARK: Coplanar faces (z-fighting)

    struct AABB {
        var owner: String
        var name: String
        var lo: SIMD3<Double>
        var hi: SIMD3<Double>
    }

    /// World boxes of the opaque, box-shaped parts under `node` (yaw is always a quarter turn).
    static func opaqueBoxes(under node: SceneNode, owner: String, originX: Double, originZ: Double, yaw: Double) -> [AABB] {
        var out: [AABB] = []
        func walk(_ n: SceneNode, _ ox: Double, _ oz: Double, _ oy: Double, _ yaw: Double) {
            let c = cos(yaw).rounded(), s = sin(yaw).rounded()
            let px = ox + n.position.x * c + n.position.z * s
            let pz = oz - n.position.x * s + n.position.z * c
            let py = oy + n.position.y
            let total = yaw + n.yaw
            var opaque = false
            switch n.material {
            case .solid, .emissive: opaque = true
            default: break
            }
            var isBox = false
            switch n.shape {
            case .box, .roundedBox: isBox = true
            default: break
            }
            if isBox && opaque {
                let tc = cos(total).rounded(), ts = sin(total).rounded()
                let hx = (abs(tc) * n.size.x + abs(ts) * n.size.z) / 2
                let hz = (abs(ts) * n.size.x + abs(tc) * n.size.z) / 2
                out.append(AABB(owner: owner, name: n.name,
                                lo: SIMD3(px - hx, py - n.size.y / 2, pz - hz),
                                hi: SIMD3(px + hx, py + n.size.y / 2, pz + hz)))
            }
            for child in n.children { walk(child, px, pz, py, total) }
        }
        for child in node.children { walk(child, originX, originZ, node.position.y, yaw) }
        return out
    }

    @Test func noTwoShellOrWallFixtureBoxesShareACoplanarFace() {
        var boxes: [AABB] = []
        let building = Self.root.node(named: "building")!
        for part in building.children {
            if part.children.isEmpty {
                var holder = SceneNode(name: part.name, children: [part])
                holder.position = .zero
                boxes += Self.opaqueBoxes(under: holder, owner: "shell:" + part.name, originX: 0, originZ: 0, yaw: 0)
            }
        }
        let wallKinds: Set<FixtureKind> = [.wallShelf, .wallFridge, .dairyChiller, .hotFoodCounter, .menuScreen,
                                           .backRoomDoor, .cigaretteCabinet]
        let fixtures = Self.root.node(named: "fixtures")!
        for f in Self.layout.fixtures where wallKinds.contains(f.kind) {
            let node = fixtures.children.first { $0.name == f.id }!
            boxes += Self.opaqueBoxes(under: node, owner: "fixture:" + f.id, originX: node.position.x,
                                      originZ: node.position.z, yaw: node.yaw)
        }
        #expect(boxes.count > 100)
        let eps = 1e-6
        var clashes: [String] = []
        for i in boxes.indices {
            for j in boxes.indices where j > i && boxes[i].owner != boxes[j].owner {
                let a = boxes[i], b = boxes[j]
                for axis in 0..<3 {
                    let others = (0..<3).filter { $0 != axis }
                    let overlap = others.allSatisfy { min(a.hi[$0], b.hi[$0]) - max(a.lo[$0], b.lo[$0]) > eps }
                    guard overlap else { continue }
                    let sharedOutward = abs(a.hi[axis] - b.hi[axis]) < eps
                    let bothShell = a.owner.hasPrefix("shell:") && b.owner.hasPrefix("shell:")
                    // Bottoms (axis 1, low side) rest on the floor and are never seen.
                    let sharedInward = bothShell && axis != 1 && abs(a.lo[axis] - b.lo[axis]) < eps
                    if sharedOutward || sharedInward {
                        clashes.append("\(a.name) / \(b.name) on axis \(axis)")
                    }
                }
            }
        }
        #expect(clashes.isEmpty, "\(clashes)")
    }
}
