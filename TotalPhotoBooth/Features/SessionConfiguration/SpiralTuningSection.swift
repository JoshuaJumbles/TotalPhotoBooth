import SwiftUI

/// Debug Mode's "Look" controls: the spiral, the Attract logo, and the app's
/// accent color, grouped because they all play off each other. Every change
/// is live on the preview and saved immediately, so a tuned look sticks.
struct SpiralTuningSection: View {
    @Bindable var settings: SpiralSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Look")
                .font(.headline)

            HStack(alignment: .top, spacing: 24) {
                preview

                VStack(alignment: .leading, spacing: 12) {
                    ColorPicker("Spiral A", selection: colorBinding(\.colorA), supportsOpacity: false)
                    ColorPicker("Spiral B", selection: colorBinding(\.colorB), supportsOpacity: false)
                    ColorPicker("Logo", selection: colorBinding(\.logoColor), supportsOpacity: false)
                    ColorPicker("Logo shadow", selection: colorBinding(\.logoShadowColor), supportsOpacity: false)
                    ColorPicker("Accent", selection: colorBinding(\.accentColor), supportsOpacity: false)
                }
            }

            Text("The spiral and logo colors swell together; the accent (buttons) stays steady.")
                .font(.caption)
                .foregroundStyle(.secondary)

            labeledSlider(
                "Color swell: ±\(Int(settings.style.swellDegrees))°",
                value: $settings.style.swellDegrees, in: 0...60, step: 1
            )
            labeledSlider(
                "Swell length: \(Int(settings.style.swellPeriod)) s",
                value: $settings.style.swellPeriod, in: 15...180, step: 1
            )
            labeledSlider(
                "Spiral turns once every \(Int(settings.style.rotationPeriod)) s",
                value: $settings.style.rotationPeriod, in: 10...120, step: 1
            )
            labeledSlider(
                logoSpinTitle,
                value: $settings.style.logoSpinFactor, in: 0...4, step: 0.25
            )
            Stepper("Spiral arms: \(settings.style.arms)", value: $settings.style.arms, in: 1...6)

            Button("Reset Look to Defaults", role: .destructive) {
                settings.reset()
            }
        }
        .frame(maxWidth: 480)
    }

    /// The spiral with the layered logo on it, so colors and spin can be
    /// judged together, just as Attract will show them.
    private var preview: some View {
        SpiralTimeline { time in
            ZStack {
                HypnoSpiralView(style: settings.style, time: time)
                LayeredLogo(style: settings.style, time: time, orbitRadius: 3)
                    .padding(16)
            }
        }
        .frame(width: 220, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var logoSpinTitle: String {
        let factor = settings.style.logoSpinFactor
        return factor == 0
            ? "Logo spin: still"
            : "Logo spin: \(factor.formatted(.number.precision(.fractionLength(0...2))))× the spiral"
    }

    private func colorBinding(_ keyPath: WritableKeyPath<SpiralStyle, SpiralStyle.RGBA>) -> Binding<Color> {
        Binding(
            get: { settings.style[keyPath: keyPath].color },
            set: { settings.style[keyPath: keyPath] = SpiralStyle.RGBA($0) }
        )
    }

    private func labeledSlider(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Slider(value: value, in: range, step: step)
        }
    }
}
