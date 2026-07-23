import SwiftUI

struct SessionConfigurationView: View {
    let viewModel: SessionConfigurationViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("\(viewModel.sessionCount) photo\(viewModel.sessionCount == 1 ? "" : "s") taken")
                .font(.title2)

            Button {
                viewModel.startKioskMode()
            } label: {
                Text("Start Kiosk Mode")
                    .font(.headline)
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
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
        .fullScreenCover(
            isPresented: Binding(
                get: { viewModel.isPresentingCustomerExperience },
                set: { isPresented in
                    if !isPresented {
                        Task { await viewModel.endKioskMode() }
                    }
                }
            )
        ) {
            CustomerExperienceView(viewModel: viewModel.makeCustomerExperienceViewModel())
        }
    }
}
