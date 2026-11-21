import SwiftUI

struct RootView: View {
    let sessionConfigurationViewModel: SessionConfigurationViewModel
    let reportViewModel: ReportViewModel
    @Environment(SpiralSettings.self) private var spiralSettings

    var body: some View {
        TabView {
            SessionConfigurationView(viewModel: sessionConfigurationViewModel)
                .tabItem { Label("Config", systemImage: "gearshape") }

            ReportView(viewModel: reportViewModel)
                .tabItem { Label("Activity", systemImage: "chart.bar") }
        }
        // The tunable app-wide accent (Debug Mode → Look).
        .tint(spiralSettings.style.accentColor.color)
    }
}
