import SwiftUI

struct RootView: View {
    let sessionConfigurationViewModel: SessionConfigurationViewModel
    let reportViewModel: ReportViewModel

    var body: some View {
        TabView {
            SessionConfigurationView(viewModel: sessionConfigurationViewModel)
                .tabItem { Label("Session", systemImage: "gearshape") }

            ReportView(viewModel: reportViewModel)
                .tabItem { Label("Activity", systemImage: "chart.bar") }
        }
    }
}
