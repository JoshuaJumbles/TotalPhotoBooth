import Foundation

/// A stand-in for `Task.sleep` that suspends until the test says time has
/// passed, so timeout logic can be stepped through deterministically.
@MainActor
final class ManualSleeper {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requested: [Duration] = []

    var pendingCount: Int { waiters.count }

    func sleep(_ duration: Duration) async {
        requested.append(duration)
        await withCheckedContinuation { waiters.append($0) }
    }

    /// Wakes every current sleeper (cancelled ones just return).
    func advance() {
        let current = waiters
        waiters = []
        current.forEach { $0.resume() }
    }

    /// Lets queued tasks run until something is asleep again.
    func waitForSleeper() async {
        for _ in 0..<1_000 where pendingCount == 0 {
            await Task.yield()
        }
    }

    /// Lets queued tasks run until a sleep beyond the first `count` is
    /// requested — use when a cancelled task may still hold a stale sleeper.
    func waitForRequest(beyond count: Int) async {
        for _ in 0..<1_000 where requested.count <= count {
            await Task.yield()
        }
    }

    /// `advance()`, then let the woken work settle.
    func advanceAndSettle() async {
        advance()
        for _ in 0..<50 { await Task.yield() }
    }
}
