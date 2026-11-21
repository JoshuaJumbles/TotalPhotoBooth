import SwiftUI

/// Debug Mode's live readout of motion wake, for tuning in the booth: how
/// much of the frame differs from the empty booth, against the threshold.
struct MotionMeter: View {
    let monitor: PresenceMonitor

    private let barWidth: CGFloat = 220
    /// The bar spans 0–30% of the frame changed.
    private let fullScale = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Motion \(Int((monitor.motionLevel * 100).rounded()))%")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.2))
                Capsule()
                    .fill(monitor.isPresenceDetected ? .green : .white)
                    .frame(width: barWidth * min(monitor.motionLevel / fullScale, 1))
                Rectangle()
                    .fill(.orange)
                    .frame(width: 3)
                    .offset(x: barWidth * min(monitor.config.sensitivity / fullScale, 1))
            }
            .frame(width: barWidth, height: 12)

            Text(status)
                .font(.system(size: 15, weight: .medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }

    private var status: String {
        if !monitor.config.isEnabled { return "Motion wake off" }
        if !monitor.isArmed { return "Warming up…" }
        if let seconds = monitor.secondsUntilWake {
            return String(format: "Someone's here — waking in %.1f s", seconds)
        }
        return monitor.isPresenceDetected ? "Someone's here" : "Watching"
    }
}
