import Foundation

public enum HUDCorner: Sendable {
    case topLeading, topTrailing, bottom, bottomLeading, bottomTrailing
}

/// Which corner each HUD element uses, for the desktop and the compact (phone) shell.
public struct HUDPlacement: Equatable, Sendable {
    public var brand: HUDCorner
    public var selection: HUDCorner
    public var controls: HUDCorner
    /// The walking stick, shown on the phone while Inside.
    public var stick: HUDCorner

    public init(compact: Bool) {
        stick = .bottomLeading
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
