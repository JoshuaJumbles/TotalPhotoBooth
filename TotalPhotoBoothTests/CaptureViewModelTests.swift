import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct CaptureViewModelTests {
    @Test func loadInitialCountReflectsExistingSessions() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession(), PhotoSession()])
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.loadInitialCount()

        #expect(viewModel.sessionCount == 2)
    }

    @Test func capturePhotoSavesSessionAndIncrementsCount() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        #expect(viewModel.sessionCount == 1)
        #expect(repository.sessions.count == 1)
    }

    @Test func capturePhotoSetsErrorMessageOnFailure() async {
        let repository = InMemoryPhotoSessionRepository()
        repository.saveError = URLError(.badServerResponse)
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        #expect(viewModel.sessionCount == 0)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func isSavingResetsAfterCaptureCompletes() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        #expect(!viewModel.isSaving)
    }
}
