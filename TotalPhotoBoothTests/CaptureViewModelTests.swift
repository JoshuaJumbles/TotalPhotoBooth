import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct CaptureViewModelTests {
    @Test func capturePhotoSavesSessionAndIncrementsCount() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        #expect(viewModel.capturedCount == 1)
        #expect(repository.sessions.count == 1)
    }

    @Test func capturePhotoSetsErrorMessageOnFailure() async {
        let repository = InMemoryPhotoSessionRepository()
        repository.saveError = URLError(.badServerResponse)
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        #expect(viewModel.capturedCount == 0)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func isSavingResetsAfterCaptureCompletes() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        #expect(!viewModel.isSaving)
    }
}
