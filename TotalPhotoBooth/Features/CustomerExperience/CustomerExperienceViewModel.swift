import Foundation
import UIKit
import os

@Observable
final class CustomerExperienceViewModel {
    enum FlowStep: Equatable {
        case attract
        case capture(mode: CaptureViewModel.Mode, existingPhotos: [CapturedPhoto])
        case review(photos: [CapturedPhoto])
        case success(photoStrip: UIImage)
    }

    enum PrintStatus: Equatable {
        case idle
        case sending
        /// Handed to the print system — not a guarantee paper came out.
        case sent
        case failed
        /// Debug Mode with no printer paired: printing intentionally skipped.
        case skipped
    }

    private(set) var step: FlowStep = .attract
    private(set) var printStatus: PrintStatus = .idle
    /// The current print, kept so tests (and future retry logic) can await it.
    private(set) var printTask: Task<Void, Never>?
    let previewView: UIView

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol
    private let photoLibrarySaver: PhotoLibrarySaverProtocol
    private let printerConnectionService: PrinterConnectionServiceProtocol
    private let isDebugMode: Bool
    private let logger = Logger(subsystem: "TotalPhotoBooth", category: "Printing")

    init(repository: PhotoSessionRepositoryProtocol,
         cameraService: CameraCaptureServiceProtocol,
         photoLibrarySaver: PhotoLibrarySaverProtocol,
         printerConnectionService: PrinterConnectionServiceProtocol,
         isDebugMode: Bool = false) {
        self.repository = repository
        self.cameraService = cameraService
        self.photoLibrarySaver = photoLibrarySaver
        self.printerConnectionService = printerConnectionService
        self.isDebugMode = isDebugMode
        self.previewView = cameraService.makePreviewView()
    }

    func startSession() {
        currentPrintJobID = nil
        printStatus = .idle
        step = .capture(mode: .fullSequence, existingPhotos: [])
    }

    func captureSequenceCompleted(photos: [CapturedPhoto]) {
        step = .review(photos: photos)
    }

    func retake(index: Int, currentPhotos: [CapturedPhoto]) {
        step = .capture(mode: .retake(index: index), existingPhotos: currentPhotos)
    }

    func makeCaptureViewModel(
        mode: CaptureViewModel.Mode,
        existingPhotos: [CapturedPhoto],
        onComplete: @escaping ([CapturedPhoto]) -> Void
    ) -> CaptureViewModel {
        CaptureViewModel(
            mode: mode,
            existingPhotos: existingPhotos,
            cameraService: cameraService,
            onComplete: onComplete
        )
    }

    /// Saves the session and Photos backup (throwing back to Review on
    /// failure), then shows Success and prints. A print failure never throws
    /// here — the strip is already backed up, so the customer still gets
    /// Success, just with a "see staff" note.
    func confirmAndSave(photos: [CapturedPhoto]) async throws {
        if !isDebugMode {
            try await repository.save(PhotoSession())
        }
        let photoStrip = try CompositeImageRendererService.makeDoublePhotoStrip(photoData: photos.map { $0.imageData })
        try await photoLibrarySaver.save(image: photoStrip)
        step = .success(photoStrip: photoStrip)

        let jobID = UUID()
        currentPrintJobID = jobID
        printTask = Task { await printStrip(photoStrip, jobID: jobID) }
    }

    func finishSession() {
        step = .attract
    }

    /// Identifies the session's print, so a slow print from a previous
    /// customer can't overwrite the next customer's status.
    private var currentPrintJobID: UUID?

    private func printStrip(_ photoStrip: UIImage, jobID: UUID) async {
        if isDebugMode && !printerConnectionService.hasPairedPrinter {
            printStatus = .skipped
            return
        }

        printStatus = .sending
        let result: PrintStatus
        do {
            try await printerConnectionService.printPhoto(photoStrip)
            result = .sent
        } catch {
            logger.error("Print failed: \(error.localizedDescription)")
            result = .failed
        }
        if currentPrintJobID == jobID {
            printStatus = result
        }
    }
}
