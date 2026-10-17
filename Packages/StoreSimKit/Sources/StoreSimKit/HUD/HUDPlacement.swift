import Foundation

public enum HUDCorner: Sendable {
    case topLeading, topTrailing, bottom, bottomTrailing
}

/// Which corner each HUD element uses, for the desktop and the compact (phone) shell.
public struct HUDPlacement: Equatable, Sendable {
    public var brand: HUDCorner
    public var selection: HUDCorner
    public var controls: HUDCorner

    public init(compact: Bool) {
        if compact {
            brand = .topLeading
            selection = .bottom
            controls = .bottom
        } else {
            brand = .topLeading
            selection = .topTrailing
            controls = .bottomTrailing
        }
    }
}
