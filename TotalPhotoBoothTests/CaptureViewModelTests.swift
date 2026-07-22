import XCTest
@testable import TotalPhotoBooth

@MainActor
final class CaptureViewModelTests: XCTestCase {
    func testLoadInitialCountReflectsExistingSessions() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession(), PhotoSession()])
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.loadInitialCount()

        XCTAssertEqual(viewModel.sessionCount, 2)
    }

    func testCapturePhotoSavesSessionAndIncrementsCount() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        XCTAssertEqual(viewModel.sessionCount, 1)
        XCTAssertEqual(repository.sessions.count, 1)
    }

    func testCapturePhotoSetsErrorMessageOnFailure() async {
        let repository = InMemoryPhotoSessionRepository()
        repository.saveError = URLError(.badServerResponse)
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        XCTAssertEqual(viewModel.sessionCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testIsSavingResetsAfterCaptureCompletes() async {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CaptureViewModel(repository: repository)

        await viewModel.capturePhoto()

        XCTAssertFalse(viewModel.isSaving)
    }
}
