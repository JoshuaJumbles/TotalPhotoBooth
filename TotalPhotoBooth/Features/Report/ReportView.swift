import SwiftUI

struct ReportView: View {
    let viewModel: ReportViewModel

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total Sessions", value: "\(viewModel.report?.totalSessions ?? 0)")
                }

                Section("Last 7 Days") {
                    ForEach(viewModel.report?.dailyCounts ?? []) { day in
                        LabeledContent(Self.dayFormatter.string(from: day.date), value: "\(day.count)")
                    }
                }
            }
            .navigationTitle("Activity")
            .overlay {
                if viewModel.isLoading && viewModel.report == nil {
                    ProgressView()
                }
            }
            .task { await viewModel.loadReport() }
            .refreshable { await viewModel.loadReport() }
        }
    }
}
