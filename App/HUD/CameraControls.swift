import StoreSimKit
import SwiftUI

/// Turn left, Outside | Inside, turn right.
struct CameraControls: View {
    @Bindable var controller: CameraController
    var compact: Bool

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button { controller.turnLeft() } label: {
                    Image(systemName: "rotate.left")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Turn left")

                Picker("View", selection: $controller.mode) {
                    Text("Outside").tag(ViewMode.outside)
                    Text("Inside").tag(ViewMode.inside)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .font(compact ? .caption : .body)
                .frame(width: compact ? 150 : 180)
                .padding(4)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .accessibilityLabel("View")

                Button { controller.turnRight() } label: {
                    Image(systemName: "rotate.right")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Turn right")
            }
        }
    }
}
