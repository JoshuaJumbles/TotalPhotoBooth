import UIKit

protocol PrinterConnectionServiceProtocol {
    /// Whether a printer has ever been paired (regardless of reachability).
    var hasPairedPrinter: Bool { get }
    func pair(with printer: UIPrinter)
    func reconnectToSavedPrinter() async -> UIPrinter?
    /// Sends `image` to the paired printer. Returning normally means the job
    /// was *handed to the print system* — not that paper came out.
    func printPhoto(_ image: UIImage) async throws
}
