import Foundation

/// Watches camera brightness frames while the kiosk sits on Attract and
/// wakes it when someone has been in the booth for a moment.
@Observable
final class PresenceMonitor {
    /// Latest score: the fraction of the frame that differs from the empty
    /// booth. Shown on the Debug Mode meter.
    private(set) var motionLevel: Double = 0
    private(set) var isPresenceDetected = false
    /// Counting down to a wake, while someone is being counted.
    private(set) var secondsUntilWake: TimeInterval?
    /// True once the re-arm delay has passed and a wake can happen.
    private(set) var isArmed = false

    let config: MotionWakeConfig
    var onWake: () -> Void = {}

    private enum ArmState {
        case disarmed
        /// Armed on request; the delay starts from the next frame's time.
        case waiting(since: TimeInterval?)
        case armed
    }

    private var armState: ArmState = .disarmed
    private var detector: PresenceDetector
    private var trigger: WakeTrigger

    init(config: MotionWakeConfig) {
        self.config = config
        detector = PresenceDetector(presenceThreshold: config.sensitivity)
        trigger = WakeTrigger(holdDuration: config.wakeDelay)
    }

    /// Start watching (after the re-arm delay). Called on entering Attract.
    func arm() {
        armState = .waiting(since: nil)
        isArmed = false
        trigger.reset()
        secondsUntilWake = nil
    }

    /// Stop watching. Called on leaving Attract.
    func disarm() {
        armState = .disarmed
        isArmed = false
        trigger.reset()
        secondsUntilWake = nil
    }

    /// Consumes frames until the stream ends or the task is cancelled.
    func run(frames: AsyncStream<LumaGrid>) async {
        for await grid in frames {
            handle(grid)
        }
    }

    /// One frame. Only frames seen while on Attract teach the background, so
    /// the bright, busy screens of a session (and the flash) never do.
    func handle(_ grid: LumaGrid) {
        guard config.isEnabled else { return }

        switch armState {
        case .disarmed:
            return
        case .waiting(let since):
            let start = since ?? grid.timestamp
            if grid.timestamp - start >= config.rearmDelay {
                armState = .armed
                isArmed = true
            } else {
                armState = .waiting(since: start)
            }
        case .armed:
            break
        }

        motionLevel = detector.process(grid)
        isPresenceDetected = detector.isPresent

        guard isArmed else { return }
        let shouldWake = trigger.update(isPresent: detector.isPresent, at: grid.timestamp)
        secondsUntilWake = trigger.timeUntilWake(at: grid.timestamp)
        if shouldWake {
            onWake()
        }
    }
}
