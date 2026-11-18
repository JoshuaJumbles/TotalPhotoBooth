import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

@MainActor
struct CaptureViewModelTests {
    private let timing = CaptureTiming.standard
    private let totalPhotos = CompositeImageRendererService.totalPhotos

    /// Records every wait the sequence asks for, returning immediately, and
    /// lets a test hook a specific wait (e.g. to cancel during the flash).
    private final class SleepRecorder {
        private(set) var requested: [Duration] = []
        var onSleep: (Duration) -> Void = { _ in }

        func sleep(_ duration: Duration) async {
            requested.append(duration)
            onSleep(duration)
        }
    }

    private func makeViewModel(
        mode: CaptureViewModel.Mode = .fullSequence,
        existingPhotos: [CapturedPhoto] = [],
        cameraService: FakeCameraCaptureService = FakeCameraCaptureService(),
        flash: FakeScreenFlash = FakeScreenFlash(),
        recorder: SleepRecorder = SleepRecorder(),
        onComplete: @escaping ([CapturedPhoto]) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) -> CaptureViewModel {
        CaptureViewModel(
            mode: mode,
            existingPhotos: existingPhotos,
            cameraService: cameraService,
            screenFlash: flash,
            timing: timing,
            sleep: { await recorder.sleep($0) },
            onComplete: onComplete,
            onCancel: onCancel
        )
    }

    /// The waits for one photo: the countdown, then the flash lead and hold.
    private var oneShot: [Duration] {
        Array(repeating: timing.countdownStep, count: timing.countdownFrom) + [timing.flashLead, timing.flashHold]
    }

    @Test func fullSequenceCapturesAllPhotosInOrderAtTheStripAspect() async {
        let sampleImageData = UIImage(color: .red, size: CGSize(width: 400, height: 400))!.pngData()!
        let cameraService = FakeCameraCaptureService(imageData: sampleImageData)
        var completedPhotos: [CapturedPhoto]?
        let viewModel = makeViewModel(cameraService: cameraService, onComplete: { completedPhotos = $0 })

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos.map(\.index) == [0, 1, 2])
        #expect(viewModel.capturedPhotos.allSatisfy { photo in
            guard let image = UIImage(data: photo.imageData) else { return false }
            return abs(image.size.width / image.size.height - CompositeImageRendererService.pictureAspectRatio) < 0.01
        })
        #expect(cameraService.captureCount == totalPhotos)
        #expect(completedPhotos?.count == totalPhotos)
        #expect(viewModel.thumbnails.count == totalPhotos)
        #expect(viewModel.phase == .idle)
    }

    @Test func fullSequencePausesBetweenShotsButNotAfterTheLast() async {
        let recorder = SleepRecorder()
        let viewModel = makeViewModel(recorder: recorder)

        await viewModel.beginCaptureSequence()

        let expected = oneShot + [timing.pauseBetweenShots] + oneShot + [timing.pauseBetweenShots] + oneShot
        #expect(recorder.requested == expected)
    }

    @Test func retakeOnlyRecapturesTheTargetedPhotoWithNoPause() async {
        let existingPhotos = (0..<totalPhotos).map { CapturedPhoto(index: $0, imageData: Data()) }
        let originalIDs = existingPhotos.map(\.id)
        let cameraService = FakeCameraCaptureService()
        let recorder = SleepRecorder()
        let viewModel = makeViewModel(mode: .retake(index: 2), existingPhotos: existingPhotos, cameraService: cameraService, recorder: recorder)

        await viewModel.beginCaptureSequence()

        #expect(viewModel.capturedPhotos[2].id != originalIDs[2])
        #expect(viewModel.capturedPhotos[0].id == originalIDs[0])
        #expect(viewModel.capturedPhotos[1].id == originalIDs[1])
        #expect(cameraService.captureCount == 1)
        #expect(recorder.requested == oneShot)
    }

    @Test func flashBeginsAndEndsOncePerPhoto() async {
        let flash = FakeScreenFlash()
        let viewModel = makeViewModel(flash: flash)

        await viewModel.beginCaptureSequence()

        #expect(flash.beginCount == totalPhotos)
        #expect(flash.endCount == totalPhotos)
        #expect(!flash.isOn)
    }

    @Test func phaseWalksCountdownThenFlashThenBetweenShots() async {
        let recorder = SleepRecorder()
        var phases: [CaptureViewModel.Phase] = []
        var viewModel: CaptureViewModel!
        recorder.onSleep = { _ in phases.append(viewModel.phase) }
        viewModel = makeViewModel(mode: .fullSequence, recorder: recorder)

        await viewModel.beginCaptureSequence()

        let firstPhoto = Array(phases.prefix(6))
        #expect(firstPhoto == [
            .countdown(remaining: 3), .countdown(remaining: 2), .countdown(remaining: 1),
            .flash, .flash,
            .betweenShots,
        ])
    }

    @Test func cancelMidCountdownNeverFlashesOrCaptures() async {
        let cameraService = FakeCameraCaptureService()
        let flash = FakeScreenFlash()
        let recorder = SleepRecorder()
        var completed = false
        var cancelCount = 0
        var viewModel: CaptureViewModel!
        recorder.onSleep = { _ in viewModel.cancel() }
        viewModel = makeViewModel(
            cameraService: cameraService, flash: flash, recorder: recorder,
            onComplete: { _ in completed = true }, onCancel: { cancelCount += 1 }
        )

        await viewModel.beginCaptureSequence()

        #expect(flash.beginCount == 0)
        #expect(cameraService.captureCount == 0)
        #expect(!completed)
        #expect(cancelCount == 1)
    }

    @Test func cancelDuringTheFlashStillTurnsItOff() async {
        let cameraService = FakeCameraCaptureService()
        let flash = FakeScreenFlash()
        let recorder = SleepRecorder()
        var viewModel: CaptureViewModel!
        recorder.onSleep = { duration in
            if duration == timing.flashLead { viewModel.cancel() }
        }
        viewModel = makeViewModel(cameraService: cameraService, flash: flash, recorder: recorder)

        await viewModel.beginCaptureSequence()

        #expect(flash.beginCount == 1)
        #expect(!flash.isOn)
        #expect(cameraService.captureCount == 0)
        #expect(viewModel.phase != .flash)
    }

    @Test func captureFailureTurnsTheFlashOffAndHaltsWithAnError() async {
        let cameraService = FakeCameraCaptureService()
        cameraService.captureError = CameraCaptureError.captureFailed
        let flash = FakeScreenFlash()
        var completed = false
        let viewModel = makeViewModel(cameraService: cameraService, flash: flash, onComplete: { _ in completed = true })

        await viewModel.beginCaptureSequence()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.capturedPhotos.isEmpty)
        #expect(cameraService.captureCount == 1)
        #expect(!flash.isOn)
        #expect(!completed)
    }

    @Test func dismissingACaptureErrorLeavesCapture() async {
        let cameraService = FakeCameraCaptureService()
        cameraService.captureError = CameraCaptureError.permissionDenied
        var cancelCount = 0
        let viewModel = makeViewModel(cameraService: cameraService, onCancel: { cancelCount += 1 })
        await viewModel.beginCaptureSequence()
        #expect(viewModel.errorMessage != nil)

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
        #expect(cancelCount == 1)
    }

    @Test func retakeShowsTheOtherPhotosInTheTrayFromTheStart() {
        let data = UIImage(color: .red, size: CGSize(width: 400, height: 400))!.pngData()!
        let existingPhotos = (0..<totalPhotos).map { CapturedPhoto(index: $0, imageData: data) }

        let viewModel = makeViewModel(mode: .retake(index: 1), existingPhotos: existingPhotos)

        #expect(viewModel.thumbnails.count == totalPhotos)
    }
}
