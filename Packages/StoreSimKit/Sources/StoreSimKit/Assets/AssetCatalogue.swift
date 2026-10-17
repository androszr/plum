import Foundation

/// Knows which dropped model files replace which code shapes.
public struct AssetCatalogue: Sendable {
    public enum Resolution: Equatable, Sendable {
        case model(URL)
        case procedural
    }

    private let models: [AssetName: URL]

    /// Keeps only `.usdz` files whose basename is exactly an `AssetName` raw value.
    public init(modelURLs: [URL]) {
        var found: [AssetName: URL] = [:]
        for url in modelURLs where url.pathExtension == "usdz" {
            let base = url.deletingPathExtension().lastPathComponent
            if let name = AssetName(rawValue: base) { found[name] = url }
        }
        models = found
    }

    public func resolve(_ name: AssetName) -> Resolution {
        if let url = models[name] { return .model(url) }
        return .procedural
    }

    public static let empty = AssetCatalogue(modelURLs: [])
}
