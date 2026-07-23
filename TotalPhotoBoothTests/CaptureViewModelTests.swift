import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct CaptureViewModelTests {
    @Test func fullSequenceCapturesAllPhotosInOrder() async {
        let cameraService = FakeCameraCaptureService(imageData: Data([0xAA]))
        var completedPhotos: [CapturedPhoto]?
        let viewModel = CaptureViewModel(
            mode: .fullSequence,
            existingPhotos: [],
            cameraService: cameraService,
            countdownTick: {},
            onComplete: { completedPhotos = $0 }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.count == CaptureViewModel.totalPhotos)
        #expect(viewModel.capturedPhotos.map(\.index) == [0, 1, 2, 3])
        #expect(viewModel.capturedPhotos.allSatisfy { $0.imageData == Data([0xAA]) })
        #expect(cameraService.captureCount == CaptureViewModel.totalPhotos)
        #expect(completedPhotos?.count == CaptureViewModel.totalPhotos)
    }

    @Test func retakeOnlyRecapturesTargetedIndex() async {
        let existingPhotos = (0..<CaptureViewModel.totalPhotos).map {
            CapturedPhoto(index: $0, imageData: Data())
        }
        let originalIDs = existingPhotos.map(\.id)
        let cameraService = FakeCameraCaptureService()

        let viewModel = CaptureViewModel(
            mode: .retake(index: 2),
            existingPhotos: existingPhotos,
            cameraService: cameraService,
            countdownTick: {},
            onComplete: { _ in }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.count == CaptureViewModel.totalPhotos)
        #expect(viewModel.capturedPhotos[2].id != originalIDs[2])
        #expect(viewModel.capturedPhotos[0].id == originalIDs[0])
        #expect(viewModel.capturedPhotos[1].id == originalIDs[1])
        #expect(viewModel.capturedPhotos[3].id == originalIDs[3])
        #expect(cameraService.captureCount == 1)
    }

    @Test func captureFailureSetsErrorMessageAndHaltsSequence() async {
        let cameraService = FakeCameraCaptureService()
        cameraService.captureError = CameraCaptureError.captureFailed
        var completed = false

        let viewModel = CaptureViewModel(
            mode: .fullSequence,
            existingPhotos: [],
            cameraService: cameraService,
            countdownTick: {},
            onComplete: { _ in completed = true }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.capturedPhotos.isEmpty)
        #expect(cameraService.captureCount == 1)
        #expect(!completed)
    }
}
