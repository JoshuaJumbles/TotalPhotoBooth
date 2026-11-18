import SwiftUI
import UIKit

/// Everything that defines the hypnosis spiral's look and motion, as plain
/// values so it can be persisted, tuned in Debug Mode, and unit-tested.
struct SpiralStyle: Codable, Equatable {
    /// A color stored as sRGB components, so the style stays `Codable`.
    struct RGBA: Codable, Equatable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double = 1

        init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        init(_ color: Color) {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
            self.init(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
        }

        var color: Color {
            Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        }

        /// This color with its hue rotated by `degrees`, saturation and
        /// brightness unchanged.
        func hueRotated(by degrees: Double) -> RGBA {
            var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
            UIColor(red: red, green: green, blue: blue, alpha: alpha).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
            let shifted = (Double(h) + degrees / 360).truncatingRemainder(dividingBy: 1)
            let hue = shifted < 0 ? shifted + 1 : shifted
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            UIColor(hue: hue, saturation: s, brightness: v, alpha: a).getRed(&r, green: &g, blue: &b, alpha: &a)
            return RGBA(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
        }
    }

    var colorA: RGBA
    var colorB: RGBA
    /// How far, in degrees, both colors' hue swings either side of the base.
    var swellDegrees: Double
    /// Seconds for one full swell (base → +swing → base → −swing → base).
    var swellPeriod: Double
    /// Seconds for the spiral to make one full turn.
    var rotationPeriod: Double
    var arms: Int

    /// Two close-contrast deep purples: present but calm. Tune on device.
    static let `default` = SpiralStyle(
        colorA: RGBA(red: 0.20, green: 0.10, blue: 0.36),
        colorB: RGBA(red: 0.33, green: 0.18, blue: 0.52),
        swellDegrees: 25,
        swellPeriod: 60,
        rotationPeriod: 40,
        arms: 2
    )

    /// The hue swell at `time` seconds: a sine wave, not a rainbow cycle.
    func hueOffset(at time: Double) -> Double {
        guard swellPeriod > 0 else { return 0 }
        return swellDegrees * sin(2 * .pi * time / swellPeriod)
    }

    /// Both colors at `time`, shifted together by the same swell.
    func colors(at time: Double) -> (a: RGBA, b: RGBA) {
        let offset = hueOffset(at: time)
        return (colorA.hueRotated(by: offset), colorB.hueRotated(by: offset))
    }

    /// The spiral's turn at `time`, in radians, wrapped to one revolution.
    func rotation(at time: Double) -> Double {
        guard rotationPeriod > 0 else { return 0 }
        return (2 * .pi * time / rotationPeriod).truncatingRemainder(dividingBy: 2 * .pi)
    }
}
