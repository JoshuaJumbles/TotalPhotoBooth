import SwiftUI

/// The visible half of the screen flash: the whole display filled with the
/// tuned warm white. It snaps on and eases off, and never blocks touches.
struct FlashOverlay: View {
    @Environment(FlashSettings.self) private var flashSettings
    let isOn: Bool

    var body: some View {
        FlashColor.color(kelvin: flashSettings.kelvin)
            .ignoresSafeArea()
            .opacity(isOn ? 1 : 0)
            .animation(isOn ? .linear(duration: 0.06) : .easeOut(duration: 0.2), value: isOn)
            .allowsHitTesting(false)
    }
}
