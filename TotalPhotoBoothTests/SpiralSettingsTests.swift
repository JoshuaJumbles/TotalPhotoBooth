import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct SpiralSettingsTests {
    @Test func startsAtTheDefaultStyle() {
        #expect(SpiralSettings(defaults: .forTesting()).style == .default)
    }

    @Test func tunedStyleSurvivesARelaunch() {
        let defaults = UserDefaults.forTesting()
        let settings = SpiralSettings(defaults: defaults)
        settings.style.arms = 5
        settings.style.colorA = SpiralStyle.RGBA(red: 0.9, green: 0.1, blue: 0.2)

        let relaunched = SpiralSettings(defaults: defaults)

        #expect(relaunched.style == settings.style)
    }

    @Test func resetRestoresAndPersistsTheDefaults() {
        let defaults = UserDefaults.forTesting()
        let settings = SpiralSettings(defaults: defaults)
        settings.style.swellDegrees = 55

        settings.reset()

        #expect(settings.style == .default)
        #expect(SpiralSettings(defaults: defaults).style == .default)
    }
}
