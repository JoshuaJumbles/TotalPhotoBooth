import Foundation
import Testing
@testable import TotalPhotoBooth

/// Synthetic camera frames: a softly textured empty booth, optionally with a
/// bright "head" block or an overall lighting change.
enum BoothFrames {
    static let columns = 32
    static let rows = 24

    /// The head covers 8 × 6 = 48 of 768 cells: 6.25% of the frame.
    static let headCells: Set<Int> = Set((8..<14).flatMap { row in (12..<20).map { row * columns + $0 } })
    static var headFraction: Double { Double(headCells.count) / Double(columns * rows) }

    static func empty(at time: TimeInterval, lighting: Float = 1) -> LumaGrid {
        frame(at: time) { _, base in base * lighting }
    }

    static func withHead(at time: TimeInterval) -> LumaGrid {
        frame(at: time) { index, base in headCells.contains(index) ? base + 0.4 : base }
    }

    static func frame(at time: TimeInterval, _ transform: (Int, Float) -> Float) -> LumaGrid {
        let values = (0..<(columns * rows)).map { index in
            // Gentle texture, so normalization has something to preserve.
            transform(index, 0.25 + 0.1 * Float((index * 7) % 5) / 4)
        }
        return LumaGrid(columns: columns, rows: rows, values: values, timestamp: time)
    }
}

@MainActor
struct PresenceDetectorTests {
    @Test func anUnchangedBoothScoresZero() {
        var detector = PresenceDetector(presenceThreshold: 0.05)
        for step in 0..<20 {
            let score = detector.process(BoothFrames.empty(at: Double(step) * 0.2))
            #expect(score == 0)
        }
        #expect(!detector.isPresent)
    }

    @Test func aChangeInOverallLightingIsIgnored() {
        var detector = PresenceDetector(presenceThreshold: 0.05)
        detector.process(BoothFrames.empty(at: 0))

        let score = detector.process(BoothFrames.empty(at: 0.2, lighting: 1.6))

        #expect(score == 0)
    }

    @Test func aHeadLeaningInScoresTheShareOfTheFrameItCovers() {
        var detector = PresenceDetector(presenceThreshold: 0.05)
        detector.process(BoothFrames.empty(at: 0))

        let score = detector.process(BoothFrames.withHead(at: 0.2))

        #expect(abs(score - BoothFrames.headFraction) < 0.001)
        #expect(detector.isPresent)
    }

    @Test func someoneHoldingStillIsStillSeen() {
        var detector = PresenceDetector(presenceThreshold: 0.05)
        detector.process(BoothFrames.empty(at: 0))

        var score = 0.0
        for step in 1...25 {   // five seconds of a motionless head
            score = detector.process(BoothFrames.withHead(at: Double(step) * 0.2))
        }

        #expect(detector.isPresent)
        #expect(score > 0.05)
    }

    @Test func aPermanentChangeIsEventuallyLearnedAsTheNewEmptyBooth() {
        // e.g. staff were in view when the kiosk started, then walked off.
        var detector = PresenceDetector(presenceThreshold: 0.05)
        detector.process(BoothFrames.withHead(at: 0))

        var score = 1.0
        for step in 1...1500 {   // five minutes of the now-empty booth
            score = detector.process(BoothFrames.empty(at: Double(step) * 0.2))
        }

        #expect(score == 0)
        #expect(!detector.isPresent)
    }

    @Test func nearBlackFramesDoNotRegisterAsSomeone() {
        var detector = PresenceDetector(presenceThreshold: 0.05)
        let dark = { (time: Double, seed: Int) in
            BoothFrames.frame(at: time) { index, _ in 0.005 + 0.004 * Float((index + seed) % 3) / 2 }
        }
        detector.process(dark(0, 0))

        let score = detector.process(dark(0.2, 1))

        #expect(score == 0)
    }
}

@MainActor
struct WakeTriggerTests {
    @Test func firesOnceSomeoneHasStayedForTheHoldDuration() {
        var trigger = WakeTrigger(holdDuration: 2.5)

        let fired1 = trigger.update(isPresent: true, at: 0)

        #expect(!fired1)
        let fired2 = trigger.update(isPresent: true, at: 2.4)
        #expect(!fired2)
        let fired3 = trigger.update(isPresent: true, at: 2.5)
        #expect(fired3)
    }

    @Test func aBriefDipDoesNotRestartTheClock() {
        var trigger = WakeTrigger(holdDuration: 2.5)
        _ = trigger.update(isPresent: true, at: 0)
        _ = trigger.update(isPresent: true, at: 1.0)
        _ = trigger.update(isPresent: false, at: 1.4)   // 0.4 s gap: tolerated

        let fired4 = trigger.update(isPresent: true, at: 2.6)

        #expect(fired4)
    }

    @Test func aLongerAbsenceRestartsTheClock() {
        var trigger = WakeTrigger(holdDuration: 2.5)
        _ = trigger.update(isPresent: true, at: 0)
        _ = trigger.update(isPresent: true, at: 1.0)
        _ = trigger.update(isPresent: false, at: 2.0)   // 1 s gap: they left

        let fired5 = trigger.update(isPresent: true, at: 2.6)

        #expect(!fired5)
        #expect(trigger.timeUntilWake(at: 2.6) == 2.5)
        let fired6 = trigger.update(isPresent: true, at: 5.2)
        #expect(fired6)
    }

    @Test func firesOnlyOncePerArming() {
        var trigger = WakeTrigger(holdDuration: 1)
        _ = trigger.update(isPresent: true, at: 0)
        let fired7 = trigger.update(isPresent: true, at: 1)
        #expect(fired7)
        let fired8 = trigger.update(isPresent: true, at: 5)
        #expect(!fired8)

        trigger.reset()
        _ = trigger.update(isPresent: true, at: 6)
        let fired9 = trigger.update(isPresent: true, at: 7)
        #expect(fired9)
    }
}

@MainActor
struct MotionWakeFlowTests {
    private let config = MotionWakeConfig(isEnabled: true, wakeDelay: 2.5, sensitivity: 0.05, rearmDelay: 8)

    private func makeViewModel(config: MotionWakeConfig? = nil) -> CustomerExperienceViewModel {
        CustomerExperienceViewModel(
            repository: InMemoryPhotoSessionRepository(),
            cameraService: FakeCameraCaptureService(),
            photoLibrarySaver: FakePhotoLibrarySaver(),
            printerConnectionService: FakePrinterConnectionService(),
            supplyTracker: .forTesting(),
            screenFlash: FakeScreenFlash(),
            motionWake: config ?? self.config
        )
    }

    /// Feeds frames every 0.2 s over `range` (seconds).
    private func feed(_ viewModel: CustomerExperienceViewModel, _ range: ClosedRange<Double>, frame: (TimeInterval) -> LumaGrid) {
        for time in stride(from: range.lowerBound, through: range.upperBound, by: 0.2) {
            viewModel.presenceMonitor.handle(frame(time))
        }
    }

    @Test func someoneLookingInWakesAttractToThePitchAfterTheDelay() {
        let viewModel = makeViewModel()
        feed(viewModel, 0...9) { BoothFrames.empty(at: $0) }     // learn the empty booth; re-arm
        #expect(viewModel.presenceMonitor.isArmed)

        feed(viewModel, 9.2...11.4) { BoothFrames.withHead(at: $0) }   // 2.2 s: not yet
        #expect(viewModel.step == .attract)

        feed(viewModel, 11.6...12) { BoothFrames.withHead(at: $0) }
        #expect(viewModel.step == .pitch)
    }

    @Test func nothingWakesBeforeTheRearmDelayHasPassed() {
        let viewModel = makeViewModel()
        feed(viewModel, 0...3) { BoothFrames.empty(at: $0) }
        feed(viewModel, 3.2...7.8) { BoothFrames.withHead(at: $0) }   // 4.6 s present, still re-arming

        #expect(viewModel.step == .attract)
    }

    @Test func onlyAttractWatches() {
        let viewModel = makeViewModel()
        viewModel.startSession()

        feed(viewModel, 0...10) { BoothFrames.empty(at: $0) }
        feed(viewModel, 10.2...20) { BoothFrames.withHead(at: $0) }

        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
        #expect(!viewModel.presenceMonitor.isArmed)
    }

    @Test func turnedOffInSettingsNeverWakes() {
        var off = config
        off.isEnabled = false
        let viewModel = makeViewModel(config: off)

        feed(viewModel, 0...9) { BoothFrames.empty(at: $0) }
        feed(viewModel, 9.2...20) { BoothFrames.withHead(at: $0) }

        #expect(viewModel.step == .attract)
    }

    @Test func returningToAttractRearmsAfterTheDelay() {
        let viewModel = makeViewModel()
        feed(viewModel, 0...9) { BoothFrames.empty(at: $0) }
        viewModel.showPitch()
        viewModel.finishSession()   // back to Attract, re-arming

        feed(viewModel, 9.2...12) { BoothFrames.withHead(at: $0) }   // inside the new re-arm window
        #expect(viewModel.step == .attract)
        #expect(!viewModel.presenceMonitor.isArmed)
    }

    @Test func settingsPersistAndReset() {
        let defaults = UserDefaults.forTesting()
        let settings = MotionWakeSettings(defaults: defaults)
        #expect(settings.config == .standard)

        settings.isEnabled = false
        settings.wakeDelay = 4
        settings.sensitivity = 0.1
        let relaunched = MotionWakeSettings(defaults: defaults)
        #expect(relaunched.config.isEnabled == false)
        #expect(relaunched.config.wakeDelay == 4)
        #expect(relaunched.config.sensitivity == 0.1)

        relaunched.reset()
        #expect(MotionWakeSettings(defaults: defaults).config == .standard)
    }
}
