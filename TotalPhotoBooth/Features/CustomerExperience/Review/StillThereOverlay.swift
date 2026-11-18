import SwiftUI

/// Review's last warning before the kiosk resets and drops the photos.
struct StillThereOverlay: View {
    let secondsRemaining: Int
    let onStillHere: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Still there?")
                    .font(.system(size: 88, weight: .heavy))

                Text("Starting over in \(secondsRemaining)…")
                    .font(.system(size: 40, weight: .semibold))
                    .monospacedDigit()
                    .opacity(0.85)

                Button(action: onStillHere) {
                    Text("I'm Still Here")
                        .font(.system(size: 44, weight: .bold))
                        .padding(.horizontal, 56)
                        .padding(.vertical, 22)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.top, 24)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(48)
        }
    }
}
