import Foundation

/// Turns "someone seems to be there" readings into a single wake, once
/// they've stayed for `holdDuration` — so the spiral isn't yanked away the
/// instant a head appears.
struct WakeTrigger {
    var holdDuration: TimeInterval
    /// Brief dips (a head bobbing in and out) don't restart the clock.
    var gapTolerance: TimeInterval = 0.6

    private var presentSince: TimeInterval?
    private var lastPresentAt: TimeInterval?
    private(set) var hasFired = false

    init(holdDuration: TimeInterval) {
        self.holdDuration = holdDuration
    }

    /// Returns true exactly once, when presence has lasted long enough.
    mutating func update(isPresent: Bool, at time: TimeInterval) -> Bool {
        guard !hasFired else { return false }

        if isPresent {
            if presentSince == nil { presentSince = time }
            lastPresentAt = time
        } else if let lastPresentAt, time - lastPresentAt > gapTolerance {
            presentSince = nil
            self.lastPresentAt = nil
        }

        if let presentSince, time - presentSince >= holdDuration {
            hasFired = true
            return true
        }
        return false
    }

    /// Seconds left before a wake, while someone is being counted.
    func timeUntilWake(at time: TimeInterval) -> TimeInterval? {
        guard !hasFired, let presentSince else { return nil }
        return max(0, holdDuration - (time - presentSince))
    }

    mutating func reset() {
        presentSince = nil
        lastPresentAt = nil
        hasFired = false
    }
}
