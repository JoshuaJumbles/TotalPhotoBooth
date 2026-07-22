import SwiftUI

struct CaptureView: View {
    let viewModel: CaptureViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("\(viewModel.sessionCount) photo\(viewModel.sessionCount == 1 ? "" : "s") taken")
                .font(.title2)

            Button {
                Task { await viewModel.capturePhoto() }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text("Take Photo")
                        .font(.headline)
                        .frame(minWidth: 160)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)
        }
        .padding()
        .task { await viewModel.loadInitialCount() }
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
