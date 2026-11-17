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
    let supplyTracker: PrintSupplyTracker

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol
    private let photoLibrarySaver: PhotoLibrarySaverProtocol
    private let printerConnectionService: PrinterConnectionServiceProtocol

    init(repository: PhotoSessionRepositoryProtocol,
         cameraService: CameraCaptureServiceProtocol,
         photoLibrarySaver: PhotoLibrarySaverProtocol,
         printerConnectionService: PrinterConnectionServiceProtocol,
         supplyTracker: PrintSupplyTracker) {
        self.repository = repository
        self.cameraService = cameraService
        self.photoLibrarySaver = photoLibrarySaver
        self.printerConnectionService = printerConnectionService
        self.supplyTracker = supplyTracker
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

    func startKioskMode() async {
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endKioskMode() async {
        cameraService.endHardwareSession()
        customerExperienceViewModel = nil
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
            isDebugMode: isDebugModeEnabled
        )
    }
}
