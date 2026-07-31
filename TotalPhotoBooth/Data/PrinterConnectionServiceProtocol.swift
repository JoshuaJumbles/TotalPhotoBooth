import UIKit

protocol PrinterConnectionServiceProtocol {
    func pair(with printer: UIPrinter)
    func reconnectToSavedPrinter() async -> UIPrinter?
}
