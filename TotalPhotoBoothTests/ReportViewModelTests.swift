import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct ReportViewModelTests {
    @Test func loadReportProducesReportFromRepositorySessions() async {
        let reference = Date()
        let repository = InMemoryPhotoSessionRepository(sessions: [
            PhotoSession(timestamp: reference),
            PhotoSession(timestamp: reference)
        ])
        let viewModel = ReportViewModel(repository: repository)

        await viewModel.loadReport()

        #expect(viewModel.report?.totalSessions == 2)
    }

    @Test func loadReportSetsErrorMessageOnFailure() async {
        let repository = InMemoryPhotoSessionRepository()
        repository.fetchError = URLError(.badServerResponse)
        let viewModel = ReportViewModel(repository: repository)

        await viewModel.loadReport()

        #expect(viewModel.report == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func isLoadingResetsAfterLoadCompletes() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = ReportViewModel(repository: repository)

        await viewModel.loadReport()

        #expect(!viewModel.isLoading)
    }
}
