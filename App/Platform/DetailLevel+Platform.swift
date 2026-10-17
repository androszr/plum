import StoreSimKit

extension DetailLevel {
    /// Full detail on the Mac, reduced on the phone.
    static var platformDefault: DetailLevel {
        #if os(macOS)
        .full
        #else
        .reduced
        #endif
    }
}
