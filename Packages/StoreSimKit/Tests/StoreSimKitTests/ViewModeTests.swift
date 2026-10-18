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

    static var floor: WalkableFloor { WalkableFloor(layout: .plumCorner) }
    static var walk: WalkCamera { .preset(lot: lot, floor: floor) }

    @Test func walkPresetEyeIsInsideTheShopAtEyeHeight() {
        let eye = Self.walk.pose.eye
        #expect(Self.shop.xRangeMetres.contains(eye.x) && Self.shop.zRangeMetres.contains(eye.z))
        #expect(eye.y == WalkCamera.eyeHeight)
    }

    @Test func walkPresetFacesTheAisles() {
        let w = Self.walk
        #expect(Self.floor.clearDistance(from: w.position, heading: w.yaw, limit: 10) >= 3)
    }

    @Test func walkPresetHidesRoofAndFrontOnly() {
        let names = Self.candidates
        let hidden = InteriorVisibility.hiddenNames(
            mode: .inside, candidates: names, eye: Self.walk.pose.eye, lot: Self.lot)
        for n in ["store_roof", "storefront_glazing", "canopy", "canopy_sign", "canopy_sign_text"] {
            #expect(hidden.contains(n), "\(n)")
        }
        let mullions = names.filter { $0.hasPrefix("mullion_") }
        #expect(!mullions.isEmpty)
        for m in mullions { #expect(hidden.contains(m)) }
        #expect(!hidden.contains("store_wall_left") && !hidden.contains("store_wall_right")
                && !hidden.contains("store_wall_back"))
    }

    @Test func interiorAlwaysHidesRoofAndFront() {
        let hidden = InteriorVisibility.interiorHiddenNames(
            candidates: Self.candidates, eye: Self.walk.pose.eye, lot: Self.lot)
        #expect(hidden.contains("store_roof") && hidden.contains("storefront_glazing"))
    }

    @Test func eyeBeyondAWallStillHidesIt() {
        let x = Self.shop.xRangeMetres, z = Self.shop.zRangeMetres
        func hidden(_ eye: SIMD3<Double>) -> Set<String> {
            InteriorVisibility.interiorHiddenNames(candidates: Self.candidates, eye: eye, lot: Self.lot)
        }
        #expect(hidden(SIMD3(x.lowerBound - 1, 1.6, 4)).contains("store_wall_left"))
        #expect(hidden(SIMD3(x.upperBound + 1, 1.6, 4)).contains("store_wall_right"))
        #expect(hidden(SIMD3(14, 1.6, z.lowerBound - 1)).isSuperset(of: ["store_wall_back", "tile_wall", "wood_accent"]))
    }

    @Test func outsideHidesNothing() {
        let hidden = InteriorVisibility.hiddenNames(
            mode: .outside, candidates: Self.candidates, camera: .isoPreset, lot: Self.lot)
        #expect(hidden.isEmpty)
    }
}
