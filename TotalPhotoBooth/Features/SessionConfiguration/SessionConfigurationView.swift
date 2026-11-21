import SwiftUI

struct SessionConfigurationView: View {
    let viewModel: SessionConfigurationViewModel
    @Environment(SpiralSettings.self) private var spiralSettings

    var body: some View {
        // Scrolls once Debug Mode's spiral tuning makes the content taller
        // than the screen; otherwise it stays vertically centered.
        GeometryReader { geometry in
            ScrollView {
                content
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
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
        .overlay {
            FlashOverlay(isOn: viewModel.isTestFlashing)
        }
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
            if let customerExperienceViewModel = viewModel.customerExperienceViewModel {
                CustomerExperienceView(viewModel: customerExperienceViewModel)
            }
        }
    }

    private var content: some View {
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

            VStack(spacing: 12) {
                ForEach(PrintSupplyTracker.Supply.allCases) { supply in
                    PrintSupplyRow(tracker: viewModel.supplyTracker, supply: supply)
                }
            }
            .frame(maxWidth: 420)

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

            VStack(spacing: 4) {
                Toggle("Debug Mode", isOn: Binding(
                    get: { viewModel.isDebugModeEnabled },
                    set: { viewModel.isDebugModeEnabled = $0 }
                ))
                .tint(.orange)
                .frame(width: 220)

                Text("Bypasses the printer requirement. Sessions aren't saved to reports.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            if viewModel.isDebugModeEnabled {
                SpiralTuningSection(settings: spiralSettings)
                    .padding(.top, 16)

                FlashTuningSection(
                    settings: viewModel.flashSettings,
                    isTestFlashing: viewModel.isTestFlashing,
                    onTestFlash: { Task { await viewModel.testFlash() } }
                )
                .padding(.top, 16)

                MotionWakeTuningSection(settings: viewModel.motionWakeSettings)
                    .padding(.top, 16)
            }
        }
    }
}
