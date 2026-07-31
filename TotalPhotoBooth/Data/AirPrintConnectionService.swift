import UIKit

final class AirPrintConnectionService: PrinterConnectionServiceProtocol {
    private let pairedPrinterURLKey = "com.totalphotobooth.pairedPrinterURL"

    func pair(with printer: UIPrinter) {
        UserDefaults.standard.set(printer.url, forKey: pairedPrinterURLKey)
    }

    func reconnectToSavedPrinter() async -> UIPrinter? {
        guard let url = UserDefaults.standard.url(forKey: pairedPrinterURLKey) else {
            return nil
        }

        let printer = UIPrinter(url: url)
        let isAvailable = await withCheckedContinuation { continuation in
            printer.contactPrinter { available in
                continuation.resume(returning: available)
            }
        }
        return isAvailable ? printer : nil
    }
}
