import Foundation
@testable import TotalPhotoBooth

@MainActor
extension SessionConfigurationViewModel {
    /// A Config view model wired to fakes and throwaway defaults. Guided
    /// Access defaults to on, so starting the kiosk goes straight in unless a
    /// test is about the unlocked-start warning.
    static func forTesting(
        repository: PhotoSessionRepositoryProtocol = InMemoryPhotoSessionRepository(),
        cameraService: CameraCaptureServiceProtocol = FakeCameraCaptureService(),
        printerConnectionService: PrinterConnectionServiceProtocol = FakePrinterConnectionService(),
        screenFlash: ScreenFlashProtocol = FakeScreenFlash(),
        guidedAccess: GuidedAccessStatusProviding = FakeGuidedAccessStatus(isEnabled: true),
        resumeStore: KioskResumeStore = KioskResumeStore(defaults: .forTesting())
    ) -> SessionConfigurationViewModel {
        SessionConfigurationViewModel(
            repository: repository,
            cameraService: cameraService,
            photoLibrarySaver: FakePhotoLibrarySaver(),
            printerConnectionService: printerConnectionService,
            supplyTracker: .forTesting(),
            flashSettings: FlashSettings(defaults: .forTesting()),
            screenFlash: screenFlash,
            motionWakeSettings: MotionWakeSettings(defaults: .forTesting()),
            guidedAccess: guidedAccess,
            resumeStore: resumeStore
        )
    }
}
