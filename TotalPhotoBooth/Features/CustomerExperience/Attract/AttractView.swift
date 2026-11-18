import SwiftUI

/// The idle "screensaver": the slowly turning spiral and the store logo.
/// Any touch moves on to the pitch (motion will wake it too, later).
struct AttractView: View {
    @Environment(SpiralSettings.self) private var spiralSettings
    let onWake: () -> Void

    var body: some View {
        // One clock, so the logo's orbit stays in step with the spiral's turn.
        SpiralTimeline { time in
            ZStack {
                HypnoSpiralView(style: spiralSettings.style, time: time)

                LayeredLogo(style: spiralSettings.style, time: time)
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.75 }

                VStack {
                    Spacer()
                    Text("Touch anywhere to begin")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.6), radius: 6)
                        .padding(.bottom, 72)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onWake)
    }
}
