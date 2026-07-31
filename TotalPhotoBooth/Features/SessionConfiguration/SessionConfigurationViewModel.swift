import Foundation
import UIKit

@Observable
final class SessionConfigurationViewModel {
    private(set) var sessionCount: Int = 0
    private(set) var isPresentingCustomerExperience: Bool = false
    private(set) var isStartingKioskMode: Bool = false
    private(set) var pairedPrinterName: String?
    private(set) var isPrinterConnected: Bool = false
    var isPrinterPickerPresented: Bool = false
    var errorMessage: String?

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol
    private let photoLibrarySaver: PhotoLibrarySaverProtocol
    private let printerConnectionService: PrinterConnectionServiceProtocol

    init(repository: PhotoSessionRepositoryProtocol,
         cameraService: CameraCaptureServiceProtocol,
         photoLibrarySaver: PhotoLibrarySaverProtocol,
         printerConnectionService: PrinterConnectionServiceProtocol) {
        self.repository = repository
        self.cameraService = cameraService
        self.photoLibrarySaver = photoLibrarySaver
        self.printerConnectionService = printerConnectionService
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
        guard printer != nil else {
            errorMessage = "No printer connected. Please connect a printer before starting Kiosk Mode."
            return
        }

        do {
            try await cameraService.startHardwareSession()
            isPresentingCustomerExperience = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endKioskMode() async {
        cameraService.endHardwareSession()
        isPresentingCustomerExperience = false
        await loadInitialCount()
        await checkPrinterConnection()
    }

    func makeCustomerExperienceViewModel() -> CustomerExperienceViewModel {
        CustomerExperienceViewModel(
            repository: repository,
            cameraService: cameraService,
            photoLibrarySaver: photoLibrarySaver
        )
    }
}
