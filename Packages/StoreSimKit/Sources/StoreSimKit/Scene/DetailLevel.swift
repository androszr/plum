import Foundation

public enum DetailLevel: Sendable, Equatable {
    case full
    case reduced

    public var isFull: Bool { self == .full }
}
