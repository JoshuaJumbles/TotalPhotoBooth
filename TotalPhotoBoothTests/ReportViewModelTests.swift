import XCTest
@testable import TotalPhotoBooth

@MainActor
final class ReportViewModelTests: XCTestCase {
    func testLoadReportProducesReportFromRepositorySessions() async {
        let reference = Date()
        let repository = InMemoryPhotoSessionRepository(sessions: [
            PhotoSession(timestamp: reference),
            PhotoSession(timestamp: reference)
        ])
        let viewModel = ReportViewModel(repository: repository)

        await viewModel.loadReport()

        XCTAssertEqual(viewModel.report?.totalSessions, 2)
    }

    func testLoadReportSetsErrorMessageOnFailure() async {
        let repository = InMemoryPhotoSessionRepository()
        repository.fetchError = URLError(.badServerResponse)
        let viewModel = ReportViewModel(repository: repository)

        await viewModel.loadReport()

        XCTAssertNil(viewModel.report)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testIsLoadingResetsAfterLoadCompletes() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = ReportViewModel(repository: repository)

        await viewModel.loadReport()

        XCTAssertFalse(viewModel.isLoading)
    }
}
