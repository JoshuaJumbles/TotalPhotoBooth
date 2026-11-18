import SwiftUI

/// Debug Mode controls for the kiosk spiral. Every change is live on the
/// preview and saved immediately, so a palette tuned here sticks.
struct SpiralTuningSection: View {
    @Bindable var settings: SpiralSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spiral")
                .font(.headline)

            HStack(alignment: .top, spacing: 24) {
                SpiralTimeline { time in
                    HypnoSpiralView(style: settings.style, time: time)
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    ColorPicker("Color A", selection: colorBinding(\.colorA), supportsOpacity: false)
                    ColorPicker("Color B", selection: colorBinding(\.colorB), supportsOpacity: false)
                    Stepper("Arms: \(settings.style.arms)", value: $settings.style.arms, in: 1...6)
                }
            }

            labeledSlider(
                "Color swell: ±\(Int(settings.style.swellDegrees))°",
                value: $settings.style.swellDegrees, in: 0...60
            )
            labeledSlider(
                "Swell length: \(Int(settings.style.swellPeriod)) s",
                value: $settings.style.swellPeriod, in: 15...180
            )
            labeledSlider(
                "One turn every \(Int(settings.style.rotationPeriod)) s",
                value: $settings.style.rotationPeriod, in: 10...120
            )

            Button("Reset Spiral to Defaults", role: .destructive) {
                settings.reset()
            }
        }
        .frame(maxWidth: 480)
    }

    private func colorBinding(_ keyPath: WritableKeyPath<SpiralStyle, SpiralStyle.RGBA>) -> Binding<Color> {
        Binding(
            get: { settings.style[keyPath: keyPath].color },
            set: { settings.style[keyPath: keyPath] = SpiralStyle.RGBA($0) }
        )
    }

    private func labeledSlider(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Slider(value: value, in: range, step: 1)
        }
    }
}
