import SwiftUI

/// Debug Mode controls for the screen flash, meant to be tuned in the dark
/// booth: warmth, how long it leads the shutter, and a button to fire it.
struct FlashTuningSection: View {
    @Bindable var settings: FlashSettings
    let isTestFlashing: Bool
    let onTestFlash: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flash")
                .font(.headline)

            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(FlashColor.color(kelvin: settings.kelvin))
                    .frame(width: 72, height: 72)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.3)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Warmth: \(Int(settings.kelvin)) K")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Slider(value: $settings.kelvin, in: 2700...6500, step: 100) {
                        Text("Warmth")
                    } minimumValueLabel: {
                        Text("Warm").font(.caption)
                    } maximumValueLabel: {
                        Text("Cool").font(.caption)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Lights up \(settings.leadTime, specifier: "%.2f") s before the shutter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Slider(value: $settings.leadTime, in: 0.1...1.0, step: 0.05)
            }

            HStack {
                Button("Test Flash", action: onTestFlash)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(isTestFlashing)

                Spacer()

                Button("Reset Flash to Defaults", role: .destructive) {
                    settings.reset()
                }
            }
        }
        .frame(maxWidth: 480)
    }
}
