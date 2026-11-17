import UIKit
@testable import TotalPhotoBooth

final class FakePrinterConnectionService: PrinterConnectionServiceProtocol {
    private(set) var pairedPrinter: UIPrinter?
    var reconnectResult: UIPrinter? = UIPrinter(url: URL(string: "ipp://192.168.1.100/printer")!)
    var hasPairedPrinter: Bool = true
    var printError: Error?
    private(set) var printedImages: [UIImage] = []

    func pair(with printer: UIPrinter) {
        pairedPrinter = printer
    }

    func reconnectToSavedPrinter() async -> UIPrinter? {
        reconnectResult
    }

    func printPhoto(_ image: UIImage) async throws {
        if let printError {
            throw printError
        }
        printedImages.append(image)
    }
}
