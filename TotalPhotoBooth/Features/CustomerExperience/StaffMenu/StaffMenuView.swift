import PhotosUI
import SwiftUI

struct StaffMenuView: View {
    let viewModel: StaffMenuViewModel
    let onExitKioskMode: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $pickedPhoto, matching: .images) {
                        Label("Reprint from Photos", systemImage: "printer")
                    }
                    .disabled(isReprintInProgress)

                    reprintStatusRow
                } header: {
                    Text("Reprint")
                } footer: {
                    Text("Every strip is saved to Photos. Pick one to print it again.")
                }

                Section("Print Supplies") {
                    ForEach(PrintSupplyTracker.Supply.allCases) { supply in
                        PrintSupplyRow(tracker: viewModel.supplyTracker, supply: supply)
                    }
                }

                Section {
                    Label(
                        viewModel.guidedAccess.isEnabled ? "Guided Access on" : "Guided Access off",
                        systemImage: viewModel.guidedAccess.isEnabled ? "lock.fill" : "lock.open"
                    )
                } header: {
                    Text("iPad Lock")
                } footer: {
                    Text(viewModel.guidedAccess.isEnabled
                         ? "To unlock the iPad, triple-click the Home button and enter the passcode."
                         : "Customers could leave the app. Triple-click the Home button to lock the iPad to this app.")
                }

                Section {
                    Button("Exit Kiosk Mode", role: .destructive, action: onExitKioskMode)
                }
            }
            .navigationTitle("Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            Task {
                await viewModel.reprint { try await item.loadTransferable(type: Data.self) }
            }
        }
    }

    private var isReprintInProgress: Bool {
        viewModel.reprintStatus == .preparing || viewModel.reprintStatus == .sending
    }

    @ViewBuilder
    private var reprintStatusRow: some View {
        switch viewModel.reprintStatus {
        case .idle:
            EmptyView()
        case .preparing, .sending:
            HStack(spacing: 8) {
                ProgressView()
                Text("Sending to the printer…")
            }
            .foregroundStyle(.secondary)
        case .sent:
            Label("Sent — check the printer", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}
