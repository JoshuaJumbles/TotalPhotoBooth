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
    /// The Attract logo's foreground layer. Swells with the spiral.
    var logoColor: RGBA
    /// The logo's offset "drop shadow" layer underneath. Swells with the spiral.
    var logoShadowColor: RGBA
    /// How fast the logo's layers orbit, as a multiple of the spiral's turn.
    /// 0 holds the offset still.
    var logoSpinFactor: Double
    /// The app-wide accent (buttons, highlights). Steady — it doesn't swell.
    var accentColor: RGBA

    /// Two close-contrast deep purples: present but calm. Tune on device.
    /// The logo and accent defaults match the look before they were tunable.
    static let `default` = SpiralStyle(
        colorA: RGBA(red: 0.20, green: 0.10, blue: 0.36),
        colorB: RGBA(red: 0.33, green: 0.18, blue: 0.52),
        swellDegrees: 25,
        swellPeriod: 60,
        rotationPeriod: 40,
        arms: 2,
        logoColor: RGBA(red: 0, green: 0, blue: 0),
        logoShadowColor: RGBA(red: 1, green: 1, blue: 1),
        logoSpinFactor: 1,
        accentColor: RGBA(red: 0, green: 0.533, blue: 1)
    )

    init(
        colorA: RGBA,
        colorB: RGBA,
        swellDegrees: Double,
        swellPeriod: Double,
        rotationPeriod: Double,
        arms: Int,
        logoColor: RGBA,
        logoShadowColor: RGBA,
        logoSpinFactor: Double,
        accentColor: RGBA
    ) {
        self.colorA = colorA
        self.colorB = colorB
        self.swellDegrees = swellDegrees
        self.swellPeriod = swellPeriod
        self.rotationPeriod = rotationPeriod
        self.arms = arms
        self.logoColor = logoColor
        self.logoShadowColor = logoShadowColor
        self.logoSpinFactor = logoSpinFactor
        self.accentColor = accentColor
    }

    private enum CodingKeys: String, CodingKey {
        case colorA, colorB, swellDegrees, swellPeriod, rotationPeriod, arms
        case logoColor, logoShadowColor, logoSpinFactor, accentColor
    }

    /// Tolerates styles saved before the logo and accent were tunable: they
    /// keep their spiral settings and pick up the defaults for the rest.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = SpiralStyle.default
        colorA = try container.decode(RGBA.self, forKey: .colorA)
        colorB = try container.decode(RGBA.self, forKey: .colorB)
        swellDegrees = try container.decode(Double.self, forKey: .swellDegrees)
        swellPeriod = try container.decode(Double.self, forKey: .swellPeriod)
        rotationPeriod = try container.decode(Double.self, forKey: .rotationPeriod)
        arms = try container.decode(Int.self, forKey: .arms)
        logoColor = try container.decodeIfPresent(RGBA.self, forKey: .logoColor) ?? fallback.logoColor
        logoShadowColor = try container.decodeIfPresent(RGBA.self, forKey: .logoShadowColor) ?? fallback.logoShadowColor
        logoSpinFactor = try container.decodeIfPresent(Double.self, forKey: .logoSpinFactor) ?? fallback.logoSpinFactor
        accentColor = try container.decodeIfPresent(RGBA.self, forKey: .accentColor) ?? fallback.accentColor
    }

    /// The hue swell at `time` seconds: a sine wave, not a rainbow cycle.
    func hueOffset(at time: Double) -> Double {
        guard swellPeriod > 0 else { return 0 }
        return swellDegrees * sin(2 * .pi * time / swellPeriod)
    }

    /// `color` at `time`, hue-shifted by the shared swell — so anything
    /// passed through here moves in lockstep with the spiral.
    func swelled(_ color: RGBA, at time: Double) -> RGBA {
        color.hueRotated(by: hueOffset(at: time))
    }

    /// Both spiral colors at `time`, shifted together by the same swell.
    func colors(at time: Double) -> (a: RGBA, b: RGBA) {
        (swelled(colorA, at: time), swelled(colorB, at: time))
    }

    /// Both logo colors at `time`, on the same swell as the spiral.
    func logoColors(at time: Double) -> (foreground: RGBA, shadow: RGBA) {
        (swelled(logoColor, at: time), swelled(logoShadowColor, at: time))
    }

    /// The spiral's turn at `time`, in radians, wrapped to one revolution.
    func rotation(at time: Double) -> Double {
        guard rotationPeriod > 0 else { return 0 }
        return (2 * .pi * time / rotationPeriod).truncatingRemainder(dividingBy: 2 * .pi)
    }

    /// Where the logo's orbiting layer sits at `time`, in radians. Computed
    /// from time (not the wrapped spiral angle times the factor) so it never
    /// jumps when the spiral completes a lap.
    func logoOrbitAngle(at time: Double) -> Double {
        guard rotationPeriod > 0 else { return 0 }
        return (2 * .pi * time / rotationPeriod * logoSpinFactor).truncatingRemainder(dividingBy: 2 * .pi)
    }
}
