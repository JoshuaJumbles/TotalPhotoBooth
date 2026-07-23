import SwiftUI

struct CaptureView: View {
    let viewModel: CaptureViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Photo \(viewModel.activeIndex + 1) of \(CaptureViewModel.totalPhotos)")
                .font(.headline)

            if viewModel.countdownValue > 0 {
                Text("\(viewModel.countdownValue)")
                    .font(.system(size: 96, weight: .bold))
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.tint)
            }
        }
        .padding()
        .task { await viewModel.beginCaptureSequence() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK") { viewModel.errorMessage = nil } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }
}
