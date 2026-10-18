import Foundation
import simd

public enum ViewMode: String, CaseIterable, Sendable {
    case outside, inside
}

extension OrbitCamera {
    /// The resting orbit camera for a view. Both modes frame the lot: the Inside camera is a
    /// walk, `WalkCamera.preset(lot:floor:)`, and the controller never asks for an Inside orbit.
    public static func preset(for mode: ViewMode, lot: Lot) -> OrbitCamera {
        switch mode {
        case .outside, .inside:
            return framing(lot: lot)
        }
    }
}

/// Which shell pieces step out of the way for a camera.
public enum InteriorVisibility {
    public static func interiorHiddenNames(candidates: [String], camera: OrbitCamera, lot: Lot) -> Set<String> {
        interiorHiddenNames(candidates: candidates, eye: camera.position, lot: lot)
    }

    public static func interiorHiddenNames(candidates: [String], eye: SIMD3<Double>, lot: Lot) -> Set<String> {
        var hidden = Set<String>()
        let always: Set<String> = ["store_roof", "storefront_glazing", "canopy", "canopy_sign", "canopy_sign_text"]
        for name in candidates where always.contains(name) || name.hasPrefix("mullion_") {
            hidden.insert(name)
        }
        if let shop = lot.zones(of: .storeInterior).first?.rect {
            let p = eye
            if p.x < shop.xRangeMetres.lowerBound { hidden.insert("store_wall_left") }
            if p.x > shop.xRangeMetres.upperBound { hidden.insert("store_wall_right") }
            if p.z < shop.zRangeMetres.lowerBound {
                hidden.formUnion(["store_wall_back", "tile_wall", "wood_accent"])
            }
        }
        return hidden
    }

    public static func hiddenNames(mode: ViewMode, candidates: [String], camera: OrbitCamera, lot: Lot) -> Set<String> {
        hiddenNames(mode: mode, candidates: candidates, eye: camera.position, lot: lot)
    }

    public static func hiddenNames(mode: ViewMode, candidates: [String], eye: SIMD3<Double>, lot: Lot) -> Set<String> {
        switch mode {
        case .outside: return []
        case .inside: return interiorHiddenNames(candidates: candidates, eye: eye, lot: lot)
        }
    }
}
