import Foundation

/// The screen flash's warmth and lead time, tuned from Debug Mode in the
/// booth itself and persisted so the tuned values stick.
@Observable
final class FlashSettings {
    static let defaultKelvin: Double = 3800
    static let defaultLeadTime: Double = 0.4

    /// Color temperature of the flash, in Kelvin. Lower is warmer.
    var kelvin: Double {
        didSet { defaults.set(kelvin, forKey: Keys.kelvin) }
    }

    /// Seconds the flash is on before the shutter fires.
    var leadTime: Double {
        didSet { defaults.set(leadTime, forKey: Keys.leadTime) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let kelvin = "com.totalphotobooth.flash.kelvin"
        static let leadTime = "com.totalphotobooth.flash.leadTime"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        kelvin = defaults.object(forKey: Keys.kelvin) as? Double ?? Self.defaultKelvin
        leadTime = defaults.object(forKey: Keys.leadTime) as? Double ?? Self.defaultLeadTime
    }

    func reset() {
        kelvin = Self.defaultKelvin
        leadTime = Self.defaultLeadTime
    }

    /// The capture rhythm with this flash lead time.
    var captureTiming: CaptureTiming {
        var timing = CaptureTiming.standard
        timing.flashLead = .milliseconds(Int((leadTime * 1000).rounded()))
        return timing
    }
}
