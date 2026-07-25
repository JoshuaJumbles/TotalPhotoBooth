import Foundation
import Testing
import UIKit

@testable import TotalPhotoBooth

@MainActor
struct CustomerExperienceViewModelTests {
    @Test func startsAtAttract() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService())

        #expect(viewModel.step == .attract)
    }

    @Test func startSessionEntersFullSequenceCapture() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService())

        viewModel.startSession()

        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
    }

    @Test func captureSequenceCompletedEntersReview() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService())
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: Data()) }

        viewModel.captureSequenceCompleted(photos: photos)

        #expect(viewModel.step == .review(photos: photos))
    }

    @Test func retakeEntersCaptureWithRetakeModeAndExistingPhotos() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService())
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: Data()) }

        viewModel.retake(index: 1, currentPhotos: photos)

        #expect(viewModel.step == .capture(mode: .retake(index: 1), existingPhotos: photos))
    }

    @Test func confirmAndSaveSavesExactlyOnePhotoSessionAndEntersSuccess() async throws {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService())
        let sampleImageData = UIImage(color: .red)!.pngData()!
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: sampleImageData) }

        try await viewModel.confirmAndSave(photos: photos)

        #expect(repository.sessions.count == 1)
        if case .success(let photoStrip) = viewModel.step {
            #expect(photoStrip.size.width > 0)
            #expect(photoStrip.size.height > 0)
        } else {
            Issue.record("Expected step to be .success")
        }
    }

    @Test func finishSessionReturnsToAttract() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService())
        viewModel.captureSequenceCompleted(photos: [])

        viewModel.finishSession()

        #expect(viewModel.step == .attract)
    }
}
