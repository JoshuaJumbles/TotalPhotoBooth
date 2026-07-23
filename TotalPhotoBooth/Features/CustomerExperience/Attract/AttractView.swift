import SwiftUI

struct AttractView: View {
    let onStart: () -> Void
    let onExitKioskMode: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 96))
                .foregroundStyle(.tint)

            Text("Welcome!")
                .font(.largeTitle.bold())

            Button(action: onStart) {
                Text("Tap to Start")
                    .font(.title2)
                    .frame(minWidth: 220)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button("Exit Kiosk Mode", action: onExitKioskMode)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
    }
}
