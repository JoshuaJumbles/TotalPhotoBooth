import Foundation
import UIKit

@Observable
final class SessionConfigurationViewModel {
    private(set) var sessionCount: Int = 0
    /// Built once per Kiosk Mode run and held here, so the customer flow
    /// survives this screen re-rendering underneath it (e.g. when a print
    /// updates the supply counts).
    private(set) var customerExperienceViewModel: CustomerExperienceViewModel?
    var isPresentingCustomerExperience: Bool { customerExperienceViewModel != nil }
    private(set) var isStartingKioskMode: Bool = false
    private(set) var pairedPrinterName: String?
    private(set) var isPrinterConnected: Bool = false
    var isPrinterPickerPresented: Bool = false
    var isDebugModeEnabled: Bool = false
    var errorMessage: String?
    /// True while Debug Mode's "Test Flash" has the flash overlay up.
    private(set) var isTestFlashing = false
    let supplyTracker: PrintSupplyTracker
    let flashSettings: FlashSettings
    let motionWakeSettings: MotionWakeSettings
    /// Whether the iPad is locked to this app; shown on Config and the staff menu.
    let guidedAccess: GuidedAccessStatusProviding
    /// True while asking staff to confirm starting the kiosk with Guided
    /// Access off, when customers could leave the app.
    var isConfirmingUnlockedStart = false

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol
    private let photoLibrarySaver: PhotoLibrarySaverProtocol
    private let printerConnectionService: PrinterConnectionServiceProtocol
    private let screenFlash: ScreenFlashProtocol
    private let resumeStore: KioskResumeStore

    init(repository: PhotoSessionRepositoryProtocol,
         cameraService: CameraCaptureServiceProtocol,
         photoLibrarySaver: PhotoLibrarySaverProtocol,
         printerConnectionService: PrinterConnectionServiceProtocol,
         supplyTracker: PrintSupplyTracker,
         flashSettings: FlashSettings,
         screenFlash: ScreenFlashProtocol,
         motionWakeSettings: MotionWakeSettings,
         guidedAccess: GuidedAccessStatusProviding,
         resumeStore: KioskResumeStore) {
        self.repository = repository
        self.cameraService = cameraService
        self.photoLibrarySaver = photoLibrarySaver
        self.printerConnectionService = printerConnectionService
        self.supplyTracker = supplyTracker
        self.flashSettings = flashSettings
        self.screenFlash = screenFlash
        self.motionWakeSettings = motionWakeSettings
        self.guidedAccess = guidedAccess
        self.resumeStore = resumeStore
    }

    /// Fires the real flash for a moment so its warmth can be judged in the
    /// booth itself.
    func testFlash(duration: Duration = .milliseconds(700)) async {
        guard !isTestFlashing else { return }
        isTestFlashing = true
        screenFlash.begin()
        try? await Task.sleep(for: duration)
        screenFlash.end()
        isTestFlashing = false
    }

    func loadInitialCount() async {
        do {
            sessionCount = try await repository.fetchAll().count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkPrinterConnection() async {
        let printer = await printerConnectionService.reconnectToSavedPrinter()
        pairedPrinterName = printer?.displayName
        isPrinterConnected = printer != nil
    }

    func printerSelected(_ printer: UIPrinter) {
        printerConnectionService.pair(with: printer)
        pairedPrinterName = printer.displayName
        isPrinterConnected = true
    }

    /// Starts the customer flow. With Guided Access off (outside Debug Mode)
    /// it first asks staff to confirm; "Start Anyway" calls back with
    /// `skippingGuidedAccessCheck`.
    func startKioskMode(skippingGuidedAccessCheck: Bool = false) async {
        guard skippingGuidedAccessCheck || isDebugModeEnabled || guidedAccess.isEnabled else {
            isConfirmingUnlockedStart = true
            return
        }

        isStartingKioskMode = true
        defer { isStartingKioskMode = false }

        let printer = await printerConnectionService.reconnectToSavedPrinter()
        pairedPrinterName = printer?.displayName
        isPrinterConnected = printer != nil
        if !isDebugModeEnabled {
            guard printer != nil else {
                errorMessage = "No printer connected. Please connect a printer before starting Kiosk Mode."
                return
            }
        }

        do {
            try await cameraService.startHardwareSession()
            customerExperienceViewModel = makeCustomerExperienceViewModel()
            // Debug runs are for tuning; only a real run should come back on relaunch.
            if !isDebugModeEnabled {
                resumeStore.wasInKioskMode = true
            }
            // A kiosk must never auto-lock; the spiral is its screensaver.
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// After a launch: if the kiosk was running when the app last went away
    /// and the iPad is still locked with Guided Access, go straight back in,
    /// so a relaunch never leaves a customer looking at Config. Without
    /// Guided Access, someone is working on the iPad, so stay on Config.
    func resumeKioskModeIfNeeded() async {
        guard resumeStore.wasInKioskMode,
              guidedAccess.isEnabled,
              !isPresentingCustomerExperience,
              !isStartingKioskMode else { return }
        await startKioskMode(skippingGuidedAccessCheck: true)
    }

    func endKioskMode() async {
        // Cleared first: staff chose to leave, so a relaunch shouldn't resume.
        resumeStore.wasInKioskMode = false
        cameraService.endHardwareSession()
        customerExperienceViewModel = nil
        UIApplication.shared.isIdleTimerDisabled = false
        await loadInitialCount()
        await checkPrinterConnection()
    }

    private func makeCustomerExperienceViewModel() -> CustomerExperienceViewModel {
        CustomerExperienceViewModel(
            repository: repository,
            cameraService: cameraService,
            photoLibrarySaver: photoLibrarySaver,
            printerConnectionService: printerConnectionService,
            supplyTracker: supplyTracker,
            screenFlash: screenFlash,
            isDebugMode: isDebugModeEnabled,
            // Snapshotted per kiosk run, like Debug Mode.
            captureTiming: flashSettings.captureTiming,
            motionWake: motionWakeSettings.config,
            guidedAccess: guidedAccess
        )
    }
}
