import SwiftUI

struct SuccessView: View {
    let onDone: () -> Void
    let photoStripImage: UIImage
    let printStatus: CustomerExperienceViewModel.PrintStatus
    let showDebugPrintPreview = true

    var body: some View {
        VStack(spacing: 24) {
            if showDebugPrintPreview {
                Image(uiImage: photoStripImage)
                    .resizable()
                    .scaledToFit()
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.title)

            printStatusView

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
            Label("Your photos are printing! Pick them up at the front counter.", systemImage: "printer.fill")
                .font(.title3)
                .multilineTextAlignment(.center)
        }
    }
}
