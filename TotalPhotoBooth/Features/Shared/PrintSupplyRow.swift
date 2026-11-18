import SwiftUI

/// One supply's estimated prints left, with the button staff tap after
/// physically refilling it. Shared by the Config screen and the staff menu.
struct PrintSupplyRow: View {
    let tracker: PrintSupplyTracker
    let supply: PrintSupplyTracker.Supply

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: supply.systemImage)
                .foregroundStyle(levelColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(supply.name)
                Text(remainingText)
                    .font(.subheadline)
                    .foregroundStyle(levelColor)
            }

            Spacer(minLength: 16)

            Button(supply.refillActionTitle) {
                tracker.refilled(supply)
            }
            .buttonStyle(.bordered)
        }
    }

    private var remainingText: String {
        let remaining = tracker.remaining(supply)
        switch tracker.level(supply) {
        case .empty:
            return "Likely empty — refill now"
        case .low, .ok:
            return "About \(remaining) of \(supply.capacity) prints left"
        }
    }

    private var levelColor: Color {
        switch tracker.level(supply) {
        case .ok: .secondary
        case .low: .orange
        case .empty: .red
        }
    }
}
