import Foundation

/// The values motion wake runs with for one Kiosk Mode session.
struct MotionWakeConfig: Equatable {
    var isEnabled: Bool = true
    /// Seconds someone must stay in view before the kiosk wakes.
    var wakeDelay: TimeInterval = 2.5
    /// Fraction of the frame that must change to count as someone there.
    var sensitivity: Double = 0.06
    /// After returning to Attract, ignore the camera this long — so staff
    /// starting the kiosk, or a customer just leaving, don't re-wake it.
    var rearmDelay: TimeInterval = 8

    static let standard = MotionWakeConfig()
}

/// Motion wake's tunables, adjusted from Debug Mode in the booth and
/// persisted so they stick.
@Observable
final class MotionWakeSettings {
    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }
    var wakeDelay: Double {
        didSet { defaults.set(wakeDelay, forKey: Keys.wakeDelay) }
    }
    var sensitivity: Double {
        didSet { defaults.set(sensitivity, forKey: Keys.sensitivity) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let isEnabled = "com.totalphotobooth.motionWake.isEnabled"
        static let wakeDelay = "com.totalphotobooth.motionWake.wakeDelay"
        static let sensitivity = "com.totalphotobooth.motionWake.sensitivity"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let standard = MotionWakeConfig.standard
        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? standard.isEnabled
        wakeDelay = defaults.object(forKey: Keys.wakeDelay) as? Double ?? standard.wakeDelay
        sensitivity = defaults.object(forKey: Keys.sensitivity) as? Double ?? standard.sensitivity
    }

    func reset() {
        let standard = MotionWakeConfig.standard
        isEnabled = standard.isEnabled
        wakeDelay = standard.wakeDelay
        sensitivity = standard.sensitivity
    }

    var config: MotionWakeConfig {
        var config = MotionWakeConfig.standard
        config.isEnabled = isEnabled
        config.wakeDelay = wakeDelay
        config.sensitivity = sensitivity
        return config
    }
}
