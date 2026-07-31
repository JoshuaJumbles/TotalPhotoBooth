import SwiftUI

struct SessionConfigurationView: View {
    let viewModel: SessionConfigurationViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("\(viewModel.sessionCount) completed session\(viewModel.sessionCount == 1 ? "" : "s")")
                .font(.title2)

            HStack {
                Image(systemName: viewModel.isPrinterConnected ? "printer.fill" : "printer.dotmatrix")
                    .foregroundStyle(viewModel.isPrinterConnected ? .green : .secondary)
                Text(viewModel.pairedPrinterName ?? "No printer paired")
                    .foregroundStyle(.secondary)
            }

            Button(viewModel.pairedPrinterName == nil ? "Select Printer" : "Change Printer") {
                viewModel.isPrinterPickerPresented = true
            }
            .background(
                PrinterPickerView(
                    isPresented: Binding(
                        get: { viewModel.isPrinterPickerPresented },
                        set: { viewModel.isPrinterPickerPresented = $0 }
                    ),
                    onSelect: { viewModel.printerSelected($0) }
                )
            )

            Button {
                Task { await viewModel.startKioskMode() }
            } label: {
                if viewModel.isStartingKioskMode {
                    ProgressView()
                } else {
                    Text("Start Kiosk Mode")
                        .font(.headline)
                        .frame(minWidth: 160)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isStartingKioskMode)
        }
        .padding()
        .task {
            await viewModel.loadInitialCount()
            await viewModel.checkPrinterConnection()
        }
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
