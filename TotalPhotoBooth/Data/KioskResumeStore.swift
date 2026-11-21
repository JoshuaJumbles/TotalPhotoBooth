import Foundation

/// Remembers that a customer-facing Kiosk Mode run is underway, so that when
/// Guided Access relaunches the app (after a crash, or the system ending it)
/// the booth goes straight back into the kiosk instead of sitting on Config.
///
/// Set when a non-Debug run starts; cleared only when staff exit Kiosk Mode.
final class KioskResumeStore {
    private let defaults: UserDefaults
    private static let key = "com.totalphotobooth.kiosk.wasInKioskMode"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var wasInKioskMode: Bool {
        get { defaults.bool(forKey: Self.key) }
        set { defaults.set(newValue, forKey: Self.key) }
    }
}
