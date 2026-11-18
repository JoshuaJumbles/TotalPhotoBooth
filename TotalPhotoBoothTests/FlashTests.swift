import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct FlashTests {
    @Test func daylightIsNearWhite() {
        let c = FlashColor.components(kelvin: 6500)
        #expect(c.red > 0.95 && c.green > 0.9 && c.blue > 0.9)
    }

    @Test func warmLightLeansRedOverGreenOverBlue() {
        let c = FlashColor.components(kelvin: 2700)
        #expect(c.red > c.green)
        #expect(c.green > c.blue)
    }

    @Test func blueRisesAsTheTemperatureRises() {
        let blues = stride(from: 2700.0, through: 6500, by: 400).map { FlashColor.components(kelvin: $0).blue }
        #expect(blues == blues.sorted())
    }

    @Test func componentsStayInRangeAtTheExtremes() {
        for kelvin in [500.0, 1000, 40000] {
            let c = FlashColor.components(kelvin: kelvin)
            for value in [c.red, c.green, c.blue] {
                #expect((0...1).contains(value))
            }
        }
    }

    @Test func settingsStartAtDefaultsPersistAndReset() {
        let defaults = UserDefaults.forTesting()
        let settings = FlashSettings(defaults: defaults)
        #expect(settings.kelvin == FlashSettings.defaultKelvin)
        #expect(settings.leadTime == FlashSettings.defaultLeadTime)

        settings.kelvin = 3100
        settings.leadTime = 0.65
        let relaunched = FlashSettings(defaults: defaults)
        #expect(relaunched.kelvin == 3100)
        #expect(relaunched.leadTime == 0.65)

        relaunched.reset()
        #expect(FlashSettings(defaults: defaults).kelvin == FlashSettings.defaultKelvin)
    }

    @Test func leadTimeFeedsTheCaptureTiming() {
        let settings = FlashSettings(defaults: .forTesting())
        settings.leadTime = 0.65

        #expect(settings.captureTiming.flashLead == .milliseconds(650))
        #expect(settings.captureTiming.pauseBetweenShots == CaptureTiming.standard.pauseBetweenShots)
    }

    @Test func testFlashTurnsTheScreenFlashOnThenOff() async {
        let flash = FakeScreenFlash()
        let viewModel = SessionConfigurationViewModel(
            repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(),
            photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(),
            supplyTracker: .forTesting(), flashSettings: FlashSettings(defaults: .forTesting()), screenFlash: flash
        )

        await viewModel.testFlash(duration: .zero)

        #expect(flash.beginCount == 1)
        #expect(flash.endCount == 1)
        #expect(!viewModel.isTestFlashing)
    }
}
