import SwiftUI

@main
struct StoreSimApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            StoreView()
                .frame(minWidth: 900, minHeight: 600)
            #else
            StoreView()
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 800)
        #endif
    }
}
