import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct SessionConfigurationViewModelTests {
    @Test func loadInitialCountReflectsExistingSessions() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession(), PhotoSession()])
        let viewModel = SessionConfigurationViewModel(repository: repository)

        await viewModel.loadInitialCount()

        #expect(viewModel.sessionCount == 2)
    }

    @Test func startSessionPresentsCapture() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = SessionConfigurationViewModel(repository: repository)

        viewModel.startSession()

        #expect(viewModel.isPresentingCapture)
    }

    @Test func endSessionDismissesCaptureAndRefreshesCount() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession()])
        let viewModel = SessionConfigurationViewModel(repository: repository)
        viewModel.startSession()

        await viewModel.endSession()

        #expect(!viewModel.isPresentingCapture)
        #expect(viewModel.sessionCount == 1)
    }
}
