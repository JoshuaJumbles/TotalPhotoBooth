import UIKit
import os

enum PrintError: LocalizedError {
    case printerUnavailable
    case couldNotStart
    case cancelled
    case timedOut

    var errorDescription: String? {
        switch self {
        case .printerUnavailable:
            return "The printer couldn't be reached."
        case .couldNotStart:
            return "The print job couldn't be started."
        case .cancelled:
            return "The print job was cancelled."
        case .timedOut:
            return "The printer didn't respond in time."
        }
    }
}

/// AirPrint-backed printer boundary: pairing persistence, reachability, and
/// silent printing to the paired printer.
///
/// Note on what printing can report: `print(to:)` completing only means the
/// job was handed to the iOS print system. Out of paper, an empty cassette,
/// a jam, or the printer dropping offline mid-job are *not* reported — the
/// job just waits in iOS's print queue. A future retry feature can't rely on
/// this completion to know whether paper actually came out.
final class AirPrintConnectionService: NSObject, PrinterConnectionServiceProtocol {
    private let pairedPrinterURLKey = "com.totalphotobooth.pairedPrinterURL"
    private let printTimeout: Duration = .seconds(90)
    private let logger = Logger(subsystem: "TotalPhotoBooth", category: "Printing")

    /// The previous job, awaited before starting the next one: the shared
    /// `UIPrintInteractionController` must only hold one job's state at a time.
    private var inFlightJob: Task<Void, Never>?
    private var hasLoggedPaperList = false

    var hasPairedPrinter: Bool {
        UserDefaults.standard.url(forKey: pairedPrinterURLKey) != nil
    }

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

    func printPhoto(_ image: UIImage) async throws {
        let previousJob = inFlightJob
        let job = Task { () throws -> Void in
            await previousJob?.value
            try await self.runPrintJob(image)
        }
        inFlightJob = Task { _ = try? await job.value }
        try await job.value
    }

    private func runPrintJob(_ image: UIImage) async throws {
        guard let printer = await reconnectToSavedPrinter() else {
            throw PrintError.printerUnavailable
        }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.outputType = .photo
        info.orientation = .portrait
        info.jobName = "Total Recall Photo Strip"

        // The shared controller's content properties are alternatives to each
        // other — reset all of them so nothing from a previous job lingers.
        controller.printingItem = nil
        controller.printingItems = nil
        controller.printFormatter = nil
        controller.printInfo = info
        controller.delegate = self
        controller.printPageRenderer = FullBleedImagePrintRenderer(image: image)
        defer {
            controller.printPageRenderer = nil
            controller.delegate = nil
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let resumeOnce = ResumeOnce(continuation)

            let timeout = Task {
                try? await Task.sleep(for: printTimeout)
                resumeOnce.finish(.failure(PrintError.timedOut))
            }

            let started = controller.print(to: printer) { _, completed, error in
                timeout.cancel()
                if let error {
                    resumeOnce.finish(.failure(error))
                } else if completed {
                    resumeOnce.finish(.success(()))
                } else {
                    resumeOnce.finish(.failure(PrintError.cancelled))
                }
            }

            if !started {
                timeout.cancel()
                resumeOnce.finish(.failure(PrintError.couldNotStart))
            }
        }
    }
}

extension AirPrintConnectionService: UIPrintInteractionControllerDelegate {
    func printInteractionController(
        _ printInteractionController: UIPrintInteractionController,
        choosePaper paperList: [UIPrintPaper]
    ) -> UIPrintPaper {
        let candidates = paperList.map {
            PostcardPaperSelector.Candidate(paperSize: $0.paperSize, printableRect: $0.printableRect)
        }

        if !hasLoggedPaperList {
            hasLoggedPaperList = true
            for candidate in candidates {
                logger.info("Printer offers paper \(String(describing: candidate.paperSize)), printable \(String(describing: candidate.printableRect))")
            }
        }

        if let index = PostcardPaperSelector.bestIndex(in: candidates) {
            logger.info("Chose paper \(String(describing: candidates[index].paperSize)), borderless: \(PostcardPaperSelector.isBorderless(candidates[index]))")
            return paperList[index]
        }

        logger.warning("No postcard-sized paper offered; falling back to bestPaper")
        return UIPrintPaper.bestPaper(forPageSize: PostcardPaperSelector.fourBySixSize, withPapersFrom: paperList)
    }
}

/// Guarantees a continuation is resumed exactly once, whichever of the print
/// completion, the "didn't start" path, or the timeout gets there first.
private final class ResumeOnce {
    private var continuation: CheckedContinuation<Void, Error>?

    init(_ continuation: CheckedContinuation<Void, Error>) {
        self.continuation = continuation
    }

    func finish(_ result: Result<Void, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
