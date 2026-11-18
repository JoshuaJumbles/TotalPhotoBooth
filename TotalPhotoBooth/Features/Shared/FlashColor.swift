import SwiftUI

/// The screen-flash color for a color temperature, so the flash can be tuned
/// in friendly units (Kelvin) rather than raw RGB.
enum FlashColor {
    /// sRGB components (0…1) approximating black-body light at `kelvin`.
    /// Tanner Helland's curve fit, good from about 1000 K to 40000 K.
    static func components(kelvin: Double) -> (red: Double, green: Double, blue: Double) {
        let temperature = kelvin / 100

        let red: Double
        let green: Double
        let blue: Double

        if temperature <= 66 {
            red = 255
            green = 99.4708025861 * log(temperature) - 161.1195681661
        } else {
            red = 329.698727446 * pow(temperature - 60, -0.1332047592)
            green = 288.1221695283 * pow(temperature - 60, -0.0755148492)
        }

        if temperature >= 66 {
            blue = 255
        } else if temperature <= 19 {
            blue = 0
        } else {
            blue = 138.5177312231 * log(temperature - 10) - 305.0447927307
        }

        func unit(_ value: Double) -> Double { min(max(value, 0), 255) / 255 }
        return (unit(red), unit(green), unit(blue))
    }

    static func color(kelvin: Double) -> Color {
        let c = components(kelvin: kelvin)
        return Color(.sRGB, red: c.red, green: c.green, blue: c.blue)
    }
}
