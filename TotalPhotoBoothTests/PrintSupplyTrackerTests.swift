import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct PrintSupplyTrackerTests {
    @Test func startsWithEverySupplyFull() {
        let tracker = PrintSupplyTracker.forTesting()

        for supply in PrintSupplyTracker.Supply.allCases {
            #expect(tracker.remaining(supply) == supply.capacity)
            #expect(tracker.level(supply) == .ok)
        }
    }

    @Test func recordPrintCountsAgainstPaperAndInk() {
        let tracker = PrintSupplyTracker.forTesting()

        tracker.recordPrint()
        tracker.recordPrint()

        #expect(tracker.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity - 2)
        #expect(tracker.remaining(.ink) == PrintSupplyTracker.Supply.ink.capacity - 2)
    }

    @Test func refillingOneSupplyLeavesTheOtherAlone() {
        let tracker = PrintSupplyTracker.forTesting()
        tracker.recordPrint()

        tracker.refilled(.paper)

        #expect(tracker.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity)
        #expect(tracker.remaining(.ink) == PrintSupplyTracker.Supply.ink.capacity - 1)
    }

    @Test func levelTurnsLowNearTheEndAndEmptyAtCapacity() {
        let tracker = PrintSupplyTracker.forTesting()
        let capacity = PrintSupplyTracker.Supply.paper.capacity

        for _ in 0..<(capacity - PrintSupplyTracker.lowThreshold - 1) { tracker.recordPrint() }
        #expect(tracker.level(.paper) == .ok)

        tracker.recordPrint()
        #expect(tracker.level(.paper) == .low)

        for _ in 0..<PrintSupplyTracker.lowThreshold { tracker.recordPrint() }
        #expect(tracker.level(.paper) == .empty)
    }

    @Test func remainingNeverGoesNegativeWhenStaffForgetToReset() {
        let tracker = PrintSupplyTracker.forTesting()

        for _ in 0..<(PrintSupplyTracker.Supply.paper.capacity + 5) { tracker.recordPrint() }

        #expect(tracker.remaining(.paper) == 0)
    }

    @Test func countsPersistAcrossLaunches() {
        let defaults = UserDefaults.forTesting()
        let firstLaunch = PrintSupplyTracker(defaults: defaults)
        firstLaunch.recordPrint()

        let secondLaunch = PrintSupplyTracker(defaults: defaults)

        #expect(secondLaunch.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity - 1)
    }
}
