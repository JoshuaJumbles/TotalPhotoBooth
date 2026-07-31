import UIKit
@testable import TotalPhotoBooth

final class FakePrinterConnectionService: PrinterConnectionServiceProtocol {
    private(set) var pairedPrinter: UIPrinter?
    var reconnectResult: UIPrinter? = UIPrinter(url: URL(string: "ipp://192.168.1.100/printer")!)

    func pair(with printer: UIPrinter) {
        pairedPrinter = printer
    }

    func reconnectToSavedPrinter() async -> UIPrinter? {
        reconnectResult
    }
}
