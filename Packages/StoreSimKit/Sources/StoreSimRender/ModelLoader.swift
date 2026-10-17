import Foundation
import RealityKit
import StoreSimKit

public struct ModelLoaderError: Error { public let name: AssetName }

/// The only file that loads a model from disk.
@MainActor
public struct ModelLoader {
    public let catalogue: AssetCatalogue

    public init(catalogue: AssetCatalogue) { self.catalogue = catalogue }

    public func load(_ name: AssetName) throws -> Entity {
        guard case let .model(url) = catalogue.resolve(name) else { throw ModelLoaderError(name: name) }
        return try Entity.load(contentsOf: url)
    }
}
