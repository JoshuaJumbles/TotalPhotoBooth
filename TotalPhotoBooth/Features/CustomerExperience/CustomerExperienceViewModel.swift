import Foundation
import UIKit
import os

@Observable
final class CustomerExperienceViewModel {
    enum FlowStep: Equatable {
        case attract
        /// The product pitch over the live preview, waiting for "Tap to Start".
        case pitch
        case capture(mode: CaptureViewModel.Mode, existingPhotos: [CapturedPhoto])
        case review(photos: [CapturedPhoto])
        case success(photoStrip: UIImage)

        /// Which screen, ignoring associated values — what crossfades key on.
        enum Kind: Equatable {
            case attract, pitch, capture, review, success

            /// The live camera preview sits behind these screens.
            var showsCameraPreview: Bool { self == .pitch || self == .capture }
        }

        var kind: Kind {
            switch self {
            case .attract: .attract
            case .pitch: .pitch
            case .capture: .capture
            case .review: .review
            case .success: .success
            }
        }
    }


    enum PrintStatus: Equatable {
        case idle
        case sending
        /// Handed to the print system — not a guarantee paper came out.
        case sent
        case failed
        /// Debug Mode with no printer paired: printing intentionally skipped.
        case skipped
    }

    private(set) var step: FlowStep = .attract {
        didSet { stepDidChange() }
    }
    /// Held here (not built in a view's `body`) so a re-render can't swap in
    /// a fresh view model while the old one is still running the countdown.
    private(set) var captureViewModel: CaptureViewModel?
    private(set) var reviewViewModel: ReviewViewModel?
    /// Review's "Still there?" warning, shown just before it times out.
    private(set) var isShowingStillThere = false
    private(set) var stillThereSecondsRemaining = 0
    /// The current screen's idle timeout, kept so tests can await it.
    private(set) var timeoutTask: Task<Void, Never>?
    private(set) var printStatus: PrintStatus = .idle
    /// The current print, kept so tests (and future retry logic) can await it.
    private(set) var printTask: Task<Void, Never>?
    var isStaffMenuPresented = false
    let staffMenu: StaffMenuViewModel
    /// Watches the booth on Attract and wakes the kiosk when someone looks in.
    let presenceMonitor: PresenceMonitor
    let previewView: UIView

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol
    private let photoLibrarySaver: PhotoLibrarySaverProtocol
    private let printerConnectionService: PrinterConnectionServiceProtocol
    private let supplyTracker: PrintSupplyTracker
    private let screenFlash: ScreenFlashProtocol
    private let captureTiming: CaptureTiming
    private let isDebugMode: Bool
    private let timeouts: KioskTimeouts
    /// Explicitly `@MainActor`: left unannotated (nonisolated-nonsending
    /// under this project's approachable-concurrency settings), the
    /// `Duration` argument arrived as garbage — ~187 billion seconds — when
    /// called through a test's closure, so timeouts never fired.
    private let sleep: @MainActor (Duration) async -> Void
    private let logger = Logger(subsystem: "TotalPhotoBooth", category: "Printing")

    init(repository: PhotoSessionRepositoryProtocol,
         cameraService: CameraCaptureServiceProtocol,
         photoLibrarySaver: PhotoLibrarySaverProtocol,
         printerConnectionService: PrinterConnectionServiceProtocol,
         supplyTracker: PrintSupplyTracker,
         screenFlash: ScreenFlashProtocol,
         isDebugMode: Bool = false,
         captureTiming: CaptureTiming = .standard,
         motionWake: MotionWakeConfig = .standard,
         timeouts: KioskTimeouts = .standard,
         guidedAccess: GuidedAccessStatusProviding = SystemGuidedAccessStatus(),
         sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.repository = repository
        self.cameraService = cameraService
        self.photoLibrarySaver = photoLibrarySaver
        self.printerConnectionService = printerConnectionService
        self.supplyTracker = supplyTracker
        self.screenFlash = screenFlash
        self.captureTiming = captureTiming
        self.isDebugMode = isDebugMode
        self.timeouts = timeouts
        self.sleep = sleep
        self.staffMenu = StaffMenuViewModel(
            printerConnectionService: printerConnectionService,
            supplyTracker: supplyTracker,
            guidedAccess: guidedAccess
        )
        self.previewView = cameraService.makePreviewView()
        self.presenceMonitor = PresenceMonitor(config: motionWake)
        presenceMonitor.onWake = { [weak self] in self?.wakeFromPresence() }
        presenceMonitor.arm()   // the kiosk starts on Attract
    }

    /// Debug Mode shows a live motion meter on Attract for tuning in the booth.
    var showsMotionMeter: Bool { isDebugMode }

    /// Feeds camera frames to the presence monitor for this Kiosk Mode run.
    func monitorPresence() async {
        await presenceMonitor.run(frames: cameraService.makeLumaFrameStream())
    }

    private func wakeFromPresence() {
        guard step == .attract else { return }
        showPitch()
    }

    func showPitch() {
        step = .pitch
    }

    func startSession() {
        currentPrintJobID = nil
        printStatus = .idle
        step = .capture(mode: .fullSequence, existingPhotos: [])
    }

    func captureSequenceCompleted(photos: [CapturedPhoto]) {
        step = .review(photos: photos)
    }

    func retake(index: Int, currentPhotos: [CapturedPhoto]) {
        step = .capture(mode: .retake(index: index), existingPhotos: currentPhotos)
    }

    /// The customer backed out of capture (Cancel), or it failed. A first
    /// run goes back to the pitch — someone is clearly in the booth — while a
    /// retake goes back to Review with the photos they already had.
    func captureAbandoned(mode: CaptureViewModel.Mode, existingPhotos: [CapturedPhoto]) {
        switch mode {
        case .fullSequence:
            step = .pitch
        case .retake:
            step = .review(photos: existingPhotos)
        }
    }

    /// "I'm Still Here" on Review's warning: dismiss it and restart the clock.
    func stillHere() {
        guard case .review = step else { return }
        restartTimeout()
    }

    /// Saves the session and Photos backup (throwing back to Review on
    /// failure), then shows Success and prints. A print failure never throws
    /// here — the strip is already backed up in Photos, so the customer
    /// still gets Success and staff can reprint it.
    func confirmAndSave(photos: [CapturedPhoto]) async throws {
        // Saving can't be interrupted by Review's timeout; if it fails, the
        // customer is back on Review with a fresh clock.
        cancelTimeout()
        do {
            try await saveAndShowSuccess(photos: photos)
        } catch {
            restartTimeout()
            throw error
        }
    }

    private func saveAndShowSuccess(photos: [CapturedPhoto]) async throws {
        if !isDebugMode {
            try await repository.save(PhotoSession())
        }
        let photoStrip = try CompositeImageRendererService.makeDoublePhotoStrip(photoData: photos.map { $0.imageData })
        try await photoLibrarySaver.save(image: photoStrip)
        step = .success(photoStrip: photoStrip)

        let jobID = UUID()
        currentPrintJobID = jobID
        printTask = Task { await printStrip(photoStrip, jobID: jobID) }
    }

    func finishSession() {
        step = .attract
    }

    // MARK: - Step changes and timeouts

    private func stepDidChange() {
        if step == .attract {
            presenceMonitor.arm()
        } else {
            presenceMonitor.disarm()
        }
        switch step {
        case .capture(let mode, let existingPhotos):
            captureViewModel = makeCaptureViewModel(mode: mode, existingPhotos: existingPhotos)
            reviewViewModel = nil
        case .review(let photos):
            reviewViewModel = makeReviewViewModel(photos: photos)
            captureViewModel = nil
        case .attract, .pitch, .success:
            captureViewModel = nil
            reviewViewModel = nil
        }
        restartTimeout()
    }

    private func cancelTimeout() {
        timeoutTask?.cancel()
        timeoutTask = nil
        isShowingStillThere = false
    }

    private func restartTimeout() {
        cancelTimeout()
        let step = step
        timeoutTask = Task { [weak self] in
            await self?.runTimeout(for: step)
        }
    }

    private func runTimeout(for step: FlowStep) async {
        switch step {
        case .attract, .capture:
            return
        case .pitch:
            await sleep(timeouts.pitch)
        case .success:
            await sleep(timeouts.success)
        case .review:
            await sleep(timeouts.reviewBeforeWarning)
            guard !Task.isCancelled else { return }
            isShowingStillThere = true
            for remaining in stride(from: timeouts.reviewWarningSeconds, to: 0, by: -1) {
                stillThereSecondsRemaining = remaining
                await sleep(.seconds(1))
                guard !Task.isCancelled else { return }
            }
        }
        guard !Task.isCancelled else { return }
        self.step = .attract
    }

    private func makeCaptureViewModel(mode: CaptureViewModel.Mode, existingPhotos: [CapturedPhoto]) -> CaptureViewModel {
        CaptureViewModel(
            mode: mode,
            existingPhotos: existingPhotos,
            cameraService: cameraService,
            screenFlash: screenFlash,
            timing: captureTiming,
            onComplete: { [weak self] photos in self?.captureSequenceCompleted(photos: photos) },
            onCancel: { [weak self] in self?.captureAbandoned(mode: mode, existingPhotos: existingPhotos) }
        )
    }

    private func makeReviewViewModel(photos: [CapturedPhoto]) -> ReviewViewModel {
        ReviewViewModel(
            photos: photos,
            onRetake: { [weak self] index in self?.retake(index: index, currentPhotos: photos) },
            onConfirm: { [weak self] in try await self?.confirmAndSave(photos: photos) }
        )
    }

    func openStaffMenu() {
        staffMenu.clearFinishedReprintStatus()
        isStaffMenuPresented = true
    }

    /// Identifies the session's print, so a slow print from a previous
    /// customer can't overwrite the next customer's status.
    private var currentPrintJobID: UUID?

    private func printStrip(_ photoStrip: UIImage, jobID: UUID) async {
        if isDebugMode && !printerConnectionService.hasPairedPrinter {
            printStatus = .skipped
            return
        }

        printStatus = .sending
        let result: PrintStatus
        do {
            try await printerConnectionService.printPhoto(photoStrip)
            supplyTracker.recordPrint()
            result = .sent
        } catch {
            logger.error("Print failed: \(error.localizedDescription)")
            result = .failed
        }
        if currentPrintJobID == jobID {
            printStatus = result
        }
    }
}
