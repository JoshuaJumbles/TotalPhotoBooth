import Foundation
import UIKit
import os

/// The hidden staff menu inside Kiosk Mode: reprint any photo from the
/// library and keep an eye on print supplies, without leaving the kiosk.
@Observable
final class StaffMenuViewModel {
    enum ReprintStatus: Equatable {
        case idle
        case preparing
        case sending
        /// Handed to the print system — check the printer for the sheet.
        case sent
        case failed(message: String)
    }

    private(set) var reprintStatus: ReprintStatus = .idle
    let supplyTracker: PrintSupplyTracker
    /// Shown so staff know whether the iPad is locked, and how to unlock it.
    let guidedAccess: GuidedAccessStatusProviding

    private let printerConnectionService: PrinterConnectionServiceProtocol
    private let logger = Logger(subsystem: "TotalPhotoBooth", category: "Printing")

    init(printerConnectionService: PrinterConnectionServiceProtocol,
         supplyTracker: PrintSupplyTracker,
         guidedAccess: GuidedAccessStatusProviding = SystemGuidedAccessStatus()) {
        self.printerConnectionService = printerConnectionService
        self.supplyTracker = supplyTracker
        self.guidedAccess = guidedAccess
    }

    /// Clears a finished reprint's result so a reopened menu starts fresh;
    /// a reprint still in flight keeps showing its progress.
    func clearFinishedReprintStatus() {
        switch reprintStatus {
        case .sent, .failed:
            reprintStatus = .idle
        case .idle, .preparing, .sending:
            break
        }
    }

    /// Prints the photo `loadImageData` produces (the picked library item),
    /// through the same calibrated path as a customer's strip.
    func reprint(loadImageData: () async throws -> Data?) async {
        reprintStatus = .preparing

        let image: UIImage
        do {
            guard let data = try await loadImageData(), let decoded = UIImage(data: data) else {
                reprintStatus = .failed(message: "That photo couldn't be opened.")
                return
            }
            image = decoded
        } catch {
            logger.error("Reprint load failed: \(error.localizedDescription)")
            reprintStatus = .failed(message: "That photo couldn't be opened.")
            return
        }

        reprintStatus = .sending
        do {
            try await printerConnectionService.printPhoto(image)
            supplyTracker.recordPrint()
            reprintStatus = .sent
        } catch {
            logger.error("Reprint failed: \(error.localizedDescription)")
            reprintStatus = .failed(message: error.localizedDescription)
        }
    }
}
