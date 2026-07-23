import SwiftUI

struct CaptureView: View {
    let viewModel: CaptureViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("\(viewModel.capturedCount) photo\(viewModel.capturedCount == 1 ? "" : "s") this session")
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

            Button("End Session") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
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
