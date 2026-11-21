import SwiftUI

/// Debug Mode controls for motion wake. Start Kiosk Mode with Debug Mode on
/// to see the live meter on Attract while tuning these.
struct MotionWakeTuningSection: View {
    @Bindable var settings: MotionWakeSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Motion Wake")
                .font(.headline)

            Toggle("Wake when someone looks in", isOn: $settings.isEnabled)

            VStack(alignment: .leading, spacing: 4) {
                Text("Wakes after someone's in view for \(settings.wakeDelay, specifier: "%.1f") s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Slider(value: $settings.wakeDelay, in: 1...6, step: 0.5)
            }
            .disabled(!settings.isEnabled)

            VStack(alignment: .leading, spacing: 4) {
                Text("Counts as someone when \(Int((settings.sensitivity * 100).rounded()))% of the view changes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Slider(value: $settings.sensitivity, in: 0.02...0.2, step: 0.01) {
                    Text("Sensitivity")
                } minimumValueLabel: {
                    Text("More").font(.caption)
                } maximumValueLabel: {
                    Text("Less").font(.caption)
                }
            }
            .disabled(!settings.isEnabled)

            Text("Start Kiosk Mode with Debug Mode on to see a live motion meter on the spiral screen.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Reset Motion Wake to Defaults", role: .destructive) {
                settings.reset()
            }
        }
        .frame(maxWidth: 480)
    }
}
