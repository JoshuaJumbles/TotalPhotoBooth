import SwiftUI

struct ReviewView: View {
    let viewModel: ReviewViewModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 24) {
            Text("Review Your Photos")
                .font(.title2)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.photos) { photo in
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)
                        Button("Retake") {
                            viewModel.retake(at: photo.index)
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.horizontal)

            Button {
                Task { await viewModel.confirm() }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text("Confirm")
                        .font(.headline)
                        .frame(minWidth: 160)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)
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
