import Foundation
import simd

public enum ViewMode: String, CaseIterable, Sendable {
    case outside, inside
}

extension OrbitCamera {
    /// The resting camera for a view: Outside frames the lot, Inside stands in the shop at head height.
    public static func preset(for mode: ViewMode, lot: Lot) -> OrbitCamera {
        switch mode {
        case .outside:
            return framing(lot: lot)
        case .inside:
            let centre = lot.zones(of: .storeInterior).first?.rect.centreMetres ?? lot.centreMetres
            return OrbitCamera(target: SIMD3(centre.x, 1.0, centre.y), distance: 6, yaw: 0,
                               pitch: 10.0 * .pi / 180, limits: .inside(lot: lot))
        }
    }
}

/// Which shell pieces step out of the way for a camera.
public enum InteriorVisibility {
    public static func interiorHiddenNames(candidates: [String], camera: OrbitCamera, lot: Lot) -> Set<String> {
        var hidden = Set<String>()
        let always: Set<String> = ["store_roof", "storefront_glazing", "canopy", "canopy_sign", "canopy_sign_text"]
        for name in candidates where always.contains(name) || name.hasPrefix("mullion_") {
            hidden.insert(name)
        }
        if let shop = lot.zones(of: .storeInterior).first?.rect {
            let p = camera.position
            if p.x < shop.xRangeMetres.lowerBound { hidden.insert("store_wall_left") }
            if p.x > shop.xRangeMetres.upperBound { hidden.insert("store_wall_right") }
            if p.z < shop.zRangeMetres.lowerBound {
                hidden.formUnion(["store_wall_back", "tile_wall", "wood_accent"])
            }
        }
        return hidden
    }

    public static func hiddenNames(mode: ViewMode, candidates: [String], camera: OrbitCamera, lot: Lot) -> Set<String> {
        switch mode {
        case .outside: return []
        case .inside: return interiorHiddenNames(candidates: candidates, camera: camera, lot: lot)
        }
    }
}
