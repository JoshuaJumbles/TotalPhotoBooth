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

    @ViewBuilder
    private var printStatusView: some View {
        switch printStatus {
        case .idle, .skipped:
            EmptyView()
        case .sending:
            HStack(spacing: 8) {
                ProgressView()
                Text("Printing your photos…")
            }
            .font(.title3)
        case .sent:
            Label("Your photos are on their way!", systemImage: "printer.fill")
                .font(.title3)
        case .failed:
            Label("If your print doesn't appear, please see a staff member.", systemImage: "person.fill.questionmark")
                .font(.title3)
                .multilineTextAlignment(.center)
        }
    }
}
