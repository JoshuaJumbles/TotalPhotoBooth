import SwiftUI

struct SuccessView: View {
    let onDone: () -> Void
    let printStatus: CustomerExperienceViewModel.PrintStatus

    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 180))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.system(size: 80, weight: .heavy))

            printStatusView

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 40, weight: .bold))
                    .frame(minWidth: 280)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 24)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SpiralBackground(dimming: 0.4))
    }

    /// One message for every print outcome. AirPrint can't tell us whether
    /// paper actually came out (see `AirPrintConnectionService`), and pickup
    /// happens at the counter anyway — so staff, not this screen, catch and
    /// fix a missed print. A detected failure is logged, not shown.
    @ViewBuilder
    private var printStatusView: some View {
        switch printStatus {
        case .idle, .skipped:
            EmptyView()
        case .sending, .sent, .failed:
            VStack(spacing: 12) {
                Text("Your photos are printing!")
                    .font(.system(size: 44, weight: .bold))
                Text("Pick them up at the front counter.")
                    .font(.system(size: 36, weight: .semibold))
                    .opacity(0.8)
            }
        }
    }
}
