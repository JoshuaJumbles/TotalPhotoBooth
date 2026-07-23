import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct CustomerExperienceViewModelTests {
    @Test func startsAtAttract() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository)

        #expect(viewModel.step == .attract)
    }

    @Test func startSessionEntersFullSequenceCapture() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository)

        viewModel.startSession()

        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
    }

    @Test func captureSequenceCompletedEntersReview() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository)
        let photos = (0..<CaptureViewModel.totalPhotos).map { CapturedPhoto(index: $0) }

        viewModel.captureSequenceCompleted(photos: photos)

        #expect(viewModel.step == .review(photos: photos))
    }

    @Test func retakeEntersCaptureWithRetakeModeAndExistingPhotos() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository)
        let photos = (0..<CaptureViewModel.totalPhotos).map { CapturedPhoto(index: $0) }

        viewModel.retake(index: 1, currentPhotos: photos)

        #expect(viewModel.step == .capture(mode: .retake(index: 1), existingPhotos: photos))
    }

    @Test func confirmAndSaveSavesExactlyOnePhotoSessionAndEntersSuccess() async throws {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository)

        try await viewModel.confirmAndSave()

        #expect(repository.sessions.count == 1)
        #expect(viewModel.step == .success)
    }

    @Test func finishSessionReturnsToAttract() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository)
        viewModel.captureSequenceCompleted(photos: [])

        viewModel.finishSession()

        #expect(viewModel.step == .attract)
    }
}
