import Foundation
@testable import TotalPhotoBooth

extension PrintSupplyTracker {
    /// A tracker backed by its own throwaway defaults suite, so tests never
    /// touch (or depend on) the real counts.
    static func forTesting() -> PrintSupplyTracker {
        PrintSupplyTracker(defaults: .forTesting())
    }
}

extension UserDefaults {
    static func forTesting() -> UserDefaults {
        let suiteName = "TotalPhotoBoothTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
