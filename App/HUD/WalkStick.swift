#if os(iOS)
import SwiftUI

/// A thumb stick for walking Inside: drag the knob, release to stop. Reports a vector in the
/// unit disc, x to the right and y forward (up the screen).
struct WalkStick: View {
    var onChange: (SIMD2<Double>) -> Void
    /// A @GestureState returns to zero when the gesture ends or is cancelled, so a cancelled
    /// touch (edge swipe, Control Centre, backgrounding) always stops the walk.
    @GestureState private var drag: CGSize = .zero

    private let size: CGFloat = 120
    private let knob: CGFloat = 44
    private let reach: CGFloat = 40

    private var clamped: CGSize {
        var dx = drag.width, dy = drag.height
        let len = (dx * dx + dy * dy).squareRoot()
        if len > reach { dx *= reach / len; dy *= reach / len }
        return CGSize(width: dx, height: dy)
    }

    var body: some View {
        Circle()
            .fill(.clear)
            .frame(width: size, height: size)
            .glassEffect(.regular, in: .circle)
            .overlay {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: knob, height: knob)
                    .offset(clamped)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($drag) { value, state, _ in state = value.translation }
            )
            .onChange(of: drag) {
                onChange(SIMD2(Double(clamped.width / reach), Double(-clamped.height / reach)))
            }
            .onDisappear { onChange(.zero) }
            .accessibilityLabel("Walk")
    }
}
#endif
