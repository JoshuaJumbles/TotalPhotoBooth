import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct CaptureViewModelTests {
    @Test func fullSequenceCapturesAllPhotosInOrder() async {
        var completedPhotos: [CapturedPhoto]?
        let viewModel = CaptureViewModel(
            mode: .fullSequence,
            existingPhotos: [],
            countdownTick: {},
            onComplete: { completedPhotos = $0 }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.count == CaptureViewModel.totalPhotos)
        #expect(viewModel.capturedPhotos.map(\.index) == [0, 1, 2, 3])
        #expect(completedPhotos?.count == CaptureViewModel.totalPhotos)
    }

    @Test func retakeOnlyRecapturesTargetedIndex() async {
        let existingPhotos = (0..<CaptureViewModel.totalPhotos).map { CapturedPhoto(index: $0) }
        let originalIDs = existingPhotos.map(\.id)

        let viewModel = CaptureViewModel(
            mode: .retake(index: 2),
            existingPhotos: existingPhotos,
            countdownTick: {},
            onComplete: { _ in }
        )

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.count == CaptureViewModel.totalPhotos)
        #expect(viewModel.capturedPhotos[2].id != originalIDs[2])
        #expect(viewModel.capturedPhotos[0].id == originalIDs[0])
        #expect(viewModel.capturedPhotos[1].id == originalIDs[1])
        #expect(viewModel.capturedPhotos[3].id == originalIDs[3])
    }
}
