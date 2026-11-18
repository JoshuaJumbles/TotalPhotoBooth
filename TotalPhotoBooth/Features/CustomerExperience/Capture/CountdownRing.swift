import SwiftUI

/// The countdown number inside a ring that drains smoothly, clockwise from
/// 12 o'clock, as the time runs out.
struct CountdownRing: View {
    let remaining: Int
    let startedAt: Date?
    let totalDuration: Duration

    private let diameter: CGFloat = 300
    private let lineWidth: CGFloat = 18

    var body: some View {
        TimelineView(.animation) { context in
            ZStack {
                Circle()
                    .fill(.black.opacity(0.35))

                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress(at: context.date))
                    .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(remaining)")
                    .font(.system(size: 170, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: remaining)
            }
            .padding(lineWidth / 2)
            .frame(width: diameter, height: diameter)
        }
    }

    /// 1 when the countdown starts, falling to 0 as it ends.
    private func progress(at date: Date) -> Double {
        guard let startedAt else { return 1 }
        let total = Double(totalDuration.components.seconds)
            + Double(totalDuration.components.attoseconds) / 1e18
        guard total > 0 else { return 0 }
        return min(max(1 - date.timeIntervalSince(startedAt) / total, 0), 1)
    }
}
