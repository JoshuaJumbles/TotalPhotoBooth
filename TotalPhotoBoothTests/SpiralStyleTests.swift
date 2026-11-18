import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

@MainActor
struct SpiralStyleTests {
    private var style: SpiralStyle {
        var style = SpiralStyle.default
        style.swellDegrees = 20
        style.swellPeriod = 60
        style.rotationPeriod = 40
        return style
    }

    @Test func hueSwellIsASineWaveNotARainbowCycle() {
        #expect(abs(style.hueOffset(at: 0)) < 0.0001)
        #expect(abs(style.hueOffset(at: 15) - 20) < 0.0001)   // quarter period: +swing
        #expect(abs(style.hueOffset(at: 45) + 20) < 0.0001)   // three quarters: −swing
        #expect(abs(style.hueOffset(at: 60)) < 0.0001)        // full period: back to base
    }

    @Test func bothColorsShiftByTheSameHueAndKeepTheirSaturationAndBrightness() {
        let (a, b) = style.colors(at: 15)

        for (shifted, base) in [(a, style.colorA), (b, style.colorB)] {
            let shiftedHSB = hsb(shifted), baseHSB = hsb(base)
            #expect(abs(hueDistance(shiftedHSB.h, baseHSB.h) - 20.0 / 360) < 0.002)
            #expect(abs(shiftedHSB.s - baseHSB.s) < 0.002)
            #expect(abs(shiftedHSB.b - baseHSB.b) < 0.002)
        }
    }

    @Test func hueRotationWrapsAroundRed() {
        let red = SpiralStyle.RGBA(red: 1, green: 0, blue: 0)

        let back = hsb(red.hueRotated(by: -30)).h
        let forward = hsb(red.hueRotated(by: 30)).h

        #expect(abs(back - (330.0 / 360)) < 0.002)
        #expect(abs(forward - (30.0 / 360)) < 0.002)
    }

    @Test func rotationAdvancesOneTurnPerRotationPeriod() {
        #expect(abs(style.rotation(at: 10) - .pi / 2) < 0.0001)
        #expect(abs(style.rotation(at: 40)) < 0.0001)          // wrapped back to 0
    }

    @Test func styleSurvivesACodableRoundTrip() throws {
        let data = try JSONEncoder().encode(style)
        #expect(try JSONDecoder().decode(SpiralStyle.self, from: data) == style)
    }

    @Test func maskBandsMatchTheSpiralFormula() {
        let radius: CGFloat = 1000
        let arms = 2, tightness = 4.0
        let path = SpiralMask.armsPath(arms: arms, tightness: tightness, radius: radius)

        var checked = 0
        for x in stride(from: -900.0, through: 900.0, by: 37) {
            for y in stride(from: -900.0, through: 900.0, by: 41) {
                let r = (x * x + y * y).squareRoot()
                guard r > 20, r < Double(radius) else { continue }
                let phase = Double(arms) * atan2(y, x) + 2 * .pi * tightness * r / Double(radius)
                let value = sin(phase)
                guard abs(value) > 0.2 else { continue }   // skip points near an edge
                #expect(path.contains(CGPoint(x: x, y: y)) == (value > 0), "at (\(x), \(y))")
                checked += 1
            }
        }
        #expect(checked > 500)
    }

    private func hsb(_ color: SpiralStyle.RGBA) -> (h: Double, s: Double, b: Double) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b))
    }

    /// Signed hue difference in turns, folded into −0.5…0.5.
    private func hueDistance(_ a: Double, _ b: Double) -> Double {
        var d = a - b
        if d > 0.5 { d -= 1 }
        if d < -0.5 { d += 1 }
        return d
    }
}
