import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

@MainActor
struct KioskFlowTests {
    private let timeouts = KioskTimeouts(
        pitch: .seconds(30),
        reviewBeforeWarning: .seconds(105),
        reviewWarningSeconds: 3,
        success: .seconds(20)
    )

    private func makeViewModel(
        sleeper: ManualSleeper,
        photoLibrarySaver: FakePhotoLibrarySaver = FakePhotoLibrarySaver()
    ) -> CustomerExperienceViewModel {
        CustomerExperienceViewModel(
            repository: InMemoryPhotoSessionRepository(),
            cameraService: FakeCameraCaptureService(),
            photoLibrarySaver: photoLibrarySaver,
            printerConnectionService: FakePrinterConnectionService(),
            supplyTracker: .forTesting(), screenFlash: FakeScreenFlash(),
            timeouts: timeouts,
            sleep: { await sleeper.sleep($0) }
        )
    }

    private func samplePhotos() -> [CapturedPhoto] {
        let data = UIImage(color: .red)!.pngData()!
        return (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: data) }
    }

    // MARK: Flow

    @Test func attractWakesToPitchAndPitchStartsCapture() {
        let viewModel = makeViewModel(sleeper: ManualSleeper())

        viewModel.showPitch()
        #expect(viewModel.step == .pitch)

        viewModel.startSession()
        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
    }

    @Test func stepViewModelsAreHeldForTheirStepAndClearedAfter() {
        let viewModel = makeViewModel(sleeper: ManualSleeper())

        viewModel.startSession()
        let capture = viewModel.captureViewModel
        #expect(capture != nil)
        #expect(viewModel.captureViewModel === capture)

        viewModel.captureSequenceCompleted(photos: samplePhotos())
        let review = viewModel.reviewViewModel
        #expect(viewModel.captureViewModel == nil)
        #expect(review != nil)
        #expect(viewModel.reviewViewModel === review)

        viewModel.finishSession()
        #expect(viewModel.reviewViewModel == nil)
    }

    @Test func cancellingAFirstRunReturnsToThePitch() {
        let viewModel = makeViewModel(sleeper: ManualSleeper())
        viewModel.startSession()

        viewModel.captureViewModel?.cancel()

        #expect(viewModel.step == .pitch)
        #expect(viewModel.captureViewModel == nil)
    }

    @Test func cancellingARetakeReturnsToReviewWithTheSamePhotos() {
        let viewModel = makeViewModel(sleeper: ManualSleeper())
        let photos = samplePhotos()
        viewModel.captureSequenceCompleted(photos: photos)
        viewModel.retake(index: 1, currentPhotos: photos)

        viewModel.captureViewModel?.cancel()

        #expect(viewModel.step == .review(photos: photos))
    }

    // MARK: Timeouts

    @Test func pitchTimesOutToAttract() async {
        let sleeper = ManualSleeper()
        let viewModel = makeViewModel(sleeper: sleeper)
        viewModel.showPitch()
        await sleeper.waitForSleeper()

        #expect(sleeper.requested == [timeouts.pitch])
        await sleeper.advanceAndSettle()

        #expect(viewModel.step == .attract)
    }

    @Test func successTimesOutToAttract() async throws {
        let sleeper = ManualSleeper()
        let viewModel = makeViewModel(sleeper: sleeper)
        try await viewModel.confirmAndSave(photos: samplePhotos())
        await sleeper.waitForSleeper()

        #expect(sleeper.requested.last == timeouts.success)
        await sleeper.advanceAndSettle()

        #expect(viewModel.step == .attract)
    }

    @Test func attractAndCaptureNeverTimeOut() async {
        let sleeper = ManualSleeper()
        let viewModel = makeViewModel(sleeper: sleeper)
        viewModel.showPitch()
        viewModel.finishSession()
        await viewModel.timeoutTask?.value

        viewModel.startSession()
        await viewModel.timeoutTask?.value

        // Only the (cancelled) pitch timer ever asked to sleep.
        #expect(sleeper.requested == [timeouts.pitch])
        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
    }

    @Test func reviewWarnsBeforeResettingAndDropsThePhotos() async {
        let sleeper = ManualSleeper()
        let viewModel = makeViewModel(sleeper: sleeper)
        viewModel.captureSequenceCompleted(photos: samplePhotos())
        await sleeper.waitForSleeper()
        #expect(sleeper.requested == [timeouts.reviewBeforeWarning])

        await sleeper.advanceAndSettle()
        #expect(viewModel.isShowingStillThere)
        #expect(viewModel.stillThereSecondsRemaining == timeouts.reviewWarningSeconds)
        #expect(viewModel.step != .attract)

        for _ in 0..<timeouts.reviewWarningSeconds {
            await sleeper.waitForSleeper()
            await sleeper.advanceAndSettle()
        }

        #expect(viewModel.step == .attract)
        #expect(viewModel.reviewViewModel == nil)
        #expect(!viewModel.isShowingStillThere)
    }

    @Test func stillHereDismissesTheWarningAndRestartsTheClock() async {
        let sleeper = ManualSleeper()
        let viewModel = makeViewModel(sleeper: sleeper)
        let photos = samplePhotos()
        viewModel.captureSequenceCompleted(photos: photos)
        await sleeper.waitForSleeper()
        await sleeper.advanceAndSettle()
        #expect(viewModel.isShowingStillThere)

        let requestsBefore = sleeper.requested.count
        viewModel.stillHere()
        await sleeper.waitForRequest(beyond: requestsBefore)

        #expect(!viewModel.isShowingStillThere)
        #expect(viewModel.step == .review(photos: photos))
        #expect(sleeper.requested.last == timeouts.reviewBeforeWarning)
    }

    @Test func aFailedConfirmLeavesReviewWithAFreshClock() async {
        let sleeper = ManualSleeper()
        let saver = FakePhotoLibrarySaver()
        saver.saveError = PhotoLibrarySaveError.saveFailed
        let viewModel = makeViewModel(sleeper: sleeper, photoLibrarySaver: saver)
        let photos = samplePhotos()
        viewModel.captureSequenceCompleted(photos: photos)
        await sleeper.waitForSleeper()
        await sleeper.advanceAndSettle()
        #expect(viewModel.isShowingStillThere)

        let requestsBefore = sleeper.requested.count
        await #expect(throws: PhotoLibrarySaveError.self) {
            try await viewModel.confirmAndSave(photos: photos)
        }
        await sleeper.waitForRequest(beyond: requestsBefore)

        #expect(!viewModel.isShowingStillThere)
        #expect(viewModel.step == .review(photos: photos))
        #expect(sleeper.requested.last == timeouts.reviewBeforeWarning)
    }
}
