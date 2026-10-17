import StoreSimKit
import SwiftUI

/// Every card and control, placed by the shared rule. One tree for both shells.
struct HUDLayer: View {
    var controller: CameraController
    var compact: Bool

    var body: some View {
        let placement = HUDPlacement(compact: compact)
        ZStack {
            BrandCard(compact: compact)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(placement.brand))
            SelectionCard(selection: controller.selection)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(placement.selection))
            CameraControls(controller: controller, compact: compact)
                .padding(12)
                .padding(.bottom, compact ? 64 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(placement.controls))
        }
    }

    private func alignment(_ corner: HUDCorner) -> Alignment {
        switch corner {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottom: .bottom
        case .bottomTrailing: .bottomTrailing
        }
    }
}
