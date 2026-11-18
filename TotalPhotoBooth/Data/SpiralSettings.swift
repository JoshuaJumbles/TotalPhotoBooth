import Foundation

/// The spiral style the kiosk shows, tuned from Debug Mode and persisted so
/// a tuned palette survives relaunches (and Debug Mode being switched off).
@Observable
final class SpiralSettings {
    var style: SpiralStyle {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private static let key = "com.totalphotobooth.spiralStyle"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(SpiralStyle.self, from: data) {
            style = saved
        } else {
            style = .default
        }
    }

    func reset() {
        style = .default
    }

    private func save() {
        if let data = try? JSONEncoder().encode(style) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
