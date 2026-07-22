import SwiftUI

struct RootView: View {
    let captureViewModel: CaptureViewModel
    let reportViewModel: ReportViewModel

    var body: some View {
        TabView {
            CaptureView(viewModel: captureViewModel)
                .tabItem { Label("Capture", systemImage: "camera") }

            ReportView(viewModel: reportViewModel)
                .tabItem { Label("Activity", systemImage: "chart.bar") }
        }
    }
}
