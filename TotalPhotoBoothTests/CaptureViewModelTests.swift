import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

@MainActor
struct CaptureViewModelTests {
    @Test func fullSequenceCapturesAllPhotosInOrder() async {
        let sampleImageData = UIImage(color: .red, size: CGSize(width: 400, height: 400))!.pngData()!
        let cameraService = FakeCameraCaptureService(imageData: sampleImageData)
        var completedPhotos: [CapturedPhoto]?
        var tickCount = 0
        let viewModel = CaptureViewModel(
            mode: .fullSequence,
            existingPhotos: [],
            cameraService: cameraService,
            countdownTick: { tickCount += 1 },
            onComplete: { completedPhotos = $0 }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.count == CompositeImageRendererService.totalPhotos)
        #expect(viewModel.capturedPhotos.map(\.index) == [0, 1, 2])
        #expect(viewModel.capturedPhotos.allSatisfy { photo in
            guard let image = UIImage(data: photo.imageData) else { return false }
            let ratio = image.size.width / image.size.height
            return abs(ratio - CompositeImageRendererService.pictureAspectRatio) < 0.01
        })
        #expect(cameraService.captureCount == CompositeImageRendererService.totalPhotos)
        #expect(completedPhotos?.count == CompositeImageRendererService.totalPhotos)
        // 3 countdown ticks per photo, plus a pacing tick between each pair of photos
        // (not after the last one): 4*3 + 3 = 15.
        #expect(tickCount == CompositeImageRendererService.totalPhotos * 3 + (CompositeImageRendererService.totalPhotos - 1))
    }

    @Test func retakeOnlyRecapturesTargetedIndex() async {
        let existingPhotos = (0..<CompositeImageRendererService.totalPhotos).map {
            CapturedPhoto(index: $0, imageData: Data())
        }
        let originalIDs = existingPhotos.map(\.id)
        let cameraService = FakeCameraCaptureService()
        var tickCount = 0

        let viewModel = CaptureViewModel(
            mode: .retake(index: 2),
            existingPhotos: existingPhotos,
            cameraService: cameraService,
            countdownTick: { tickCount += 1 },
            onComplete: { _ in }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.count == CompositeImageRendererService.totalPhotos)
        #expect(viewModel.capturedPhotos[2].id != originalIDs[2])
        #expect(viewModel.capturedPhotos[0].id == originalIDs[0])
        #expect(viewModel.capturedPhotos[1].id == originalIDs[1])
        #expect(cameraService.captureCount == 1)
        // Just the 3 countdown ticks -- no pacing delay after a single retake.
        #expect(tickCount == 3)
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
