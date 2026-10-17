import Testing
import simd
@testable import StoreSimKit

@Suite struct ViewModeTests {
    static let lot = StoreLayout.plumCorner.lot
    static var shop: GridRect { lot.zones(of: .storeInterior).first!.rect }
    static var candidates: [String] {
        SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: .empty)
            .node(named: "building")!.children.map(\.name)
    }

    @Test func outsidePresetIsTheIsoPreset() {
        #expect(OrbitCamera.preset(for: .outside, lot: Self.lot) == .isoPreset)
    }

    @Test func insidePresetSitsAtHeadHeight() {
        let y = OrbitCamera.preset(for: .inside, lot: Self.lot).position.y
        #expect(y >= 1.5 && y <= 2.6)
    }

    @Test func insidePresetTargetIsOnTheShopFloor() {
        let t = OrbitCamera.preset(for: .inside, lot: Self.lot).target
        #expect(Self.shop.xRangeMetres.contains(t.x))
        #expect(Self.shop.zRangeMetres.contains(t.z))
        #expect(t.y == 1)
    }

    @Test func insidePanIsConfinedToTheShop() {
        var c = OrbitCamera.preset(for: .inside, lot: Self.lot)
        let x = Self.shop.xRangeMetres, z = Self.shop.zRangeMetres
        for delta in [SIMD2(100.0, 100.0), SIMD2(-100.0, -100.0)] {
            c.pan(by: delta)
            #expect(c.target.x >= x.lowerBound + 0.5 - 1e-9 && c.target.x <= x.upperBound - 0.5 + 1e-9)
            #expect(c.target.z >= z.lowerBound + 0.5 - 1e-9 && c.target.z <= z.upperBound - 0.5 + 1e-9)
        }
    }

    @Test func insideZoomAndTiltClamp() {
        var c = OrbitCamera.preset(for: .inside, lot: Self.lot)
        c.zoom(by: 1000)
        #expect(c.distance == 9)
        c.zoom(by: 0.0001)
        #expect(c.distance == 2.5)
        c.tilt(by: 5)
        #expect(abs(c.pitch - 35 * .pi / 180) < 1e-12)
        c.tilt(by: -5)
        #expect(abs(c.pitch - 3 * .pi / 180) < 1e-12)
    }

    @Test func interiorAlwaysHidesRoofAndFront() {
        let names = Self.candidates
        let hidden = InteriorVisibility.hiddenNames(
            mode: .inside, candidates: names, camera: .preset(for: .inside, lot: Self.lot), lot: Self.lot)
        for n in ["store_roof", "storefront_glazing", "canopy", "canopy_sign", "canopy_sign_text"] {
            #expect(hidden.contains(n), "\(n)")
        }
        let mullions = names.filter { $0.hasPrefix("mullion_") }
        #expect(!mullions.isEmpty)
        for m in mullions { #expect(hidden.contains(m)) }
        #expect(!hidden.contains("store_wall_left") && !hidden.contains("store_wall_right")
                && !hidden.contains("store_wall_back"))
    }

    @Test func nearWallHidesWhenTheCameraCrossesIt() {
        let base = OrbitCamera.preset(for: .inside, lot: Self.lot)
        func hidden(_ turn: Double) -> Set<String> {
            var c = base
            c.rotate(by: turn)
            return InteriorVisibility.interiorHiddenNames(candidates: Self.candidates, camera: c, lot: Self.lot)
        }
        let a = hidden(.pi / 2)
        #expect(a.contains("store_wall_right") && !a.contains("store_wall_left"))
        let b = hidden(-.pi / 2)
        #expect(b.contains("store_wall_left") && !b.contains("store_wall_right"))
        let c = hidden(.pi)
        #expect(c.isSuperset(of: ["store_wall_back", "tile_wall", "wood_accent"]))
    }

    @Test func outsideHidesNothing() {
        let hidden = InteriorVisibility.hiddenNames(
            mode: .outside, candidates: Self.candidates, camera: .isoPreset, lot: Self.lot)
        #expect(hidden.isEmpty)
    }
}
