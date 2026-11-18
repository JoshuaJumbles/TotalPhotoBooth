import Foundation
import Testing
import UIKit

@testable import TotalPhotoBooth

@MainActor
struct CustomerExperienceViewModelTests {
    @Test func startsAtAttract() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())

        #expect(viewModel.step == .attract)
    }

    @Test func startSessionEntersFullSequenceCapture() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())

        viewModel.startSession()

        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
    }

    @Test func captureSequenceCompletedEntersReview() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: Data()) }

        viewModel.captureSequenceCompleted(photos: photos)

        #expect(viewModel.step == .review(photos: photos))
    }

    @Test func retakeEntersCaptureWithRetakeModeAndExistingPhotos() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: Data()) }

        viewModel.retake(index: 1, currentPhotos: photos)

        #expect(viewModel.step == .capture(mode: .retake(index: 1), existingPhotos: photos))
    }

    @Test func confirmAndSaveSavesExactlyOnePhotoSessionSavesToPhotoLibraryAndEntersSuccess() async throws {
        let repository = InMemoryPhotoSessionRepository()
        let photoLibrarySaver = FakePhotoLibrarySaver()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: photoLibrarySaver, printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        let sampleImageData = UIImage(color: .red)!.pngData()!
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: sampleImageData) }

        try await viewModel.confirmAndSave(photos: photos)

        #expect(repository.sessions.count == 1)
        #expect(photoLibrarySaver.savedImages.count == 1)
        if case .success(let photoStrip) = viewModel.step {
            #expect(photoStrip.size.width > 0)
            #expect(photoStrip.size.height > 0)
        } else {
            Issue.record("Expected step to be .success")
        }
    }

    @Test func confirmAndSaveThrowsAndDoesNotEnterSuccessWhenPhotoLibrarySaveFails() async {
        let repository = InMemoryPhotoSessionRepository()
        let photoLibrarySaver = FakePhotoLibrarySaver()
        photoLibrarySaver.saveError = PhotoLibrarySaveError.permissionDenied
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: photoLibrarySaver, printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        let sampleImageData = UIImage(color: .red)!.pngData()!
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: sampleImageData) }

        await #expect(throws: PhotoLibrarySaveError.self) {
            try await viewModel.confirmAndSave(photos: photos)
        }

        if case .success = viewModel.step {
            Issue.record("Expected step not to be .success")
        }
    }

    @Test func confirmAndSaveSkipsPhotoSessionButStillSavesToPhotoLibraryWhenDebugModeEnabled() async throws {
        let repository = InMemoryPhotoSessionRepository()
        let photoLibrarySaver = FakePhotoLibrarySaver()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: photoLibrarySaver, printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash(), isDebugMode: true)
        let sampleImageData = UIImage(color: .red)!.pngData()!
        let photos = (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: sampleImageData) }

        try await viewModel.confirmAndSave(photos: photos)

        #expect(repository.sessions.count == 0)
        #expect(photoLibrarySaver.savedImages.count == 1)
        if case .success = viewModel.step {
        } else {
            Issue.record("Expected step to be .success")
        }
    }

    private func samplePhotos() -> [CapturedPhoto] {
        let sampleImageData = UIImage(color: .red)!.pngData()!
        return (0..<CompositeImageRendererService.totalPhotos).map { CapturedPhoto(index: $0, imageData: sampleImageData) }
    }

    @Test func confirmAndSavePrintsTheRenderedStripAndReportsSent() async throws {
        let printer = FakePrinterConnectionService()
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printer, supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())

        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        #expect(printer.printedImages.count == 1)
        #expect(viewModel.printStatus == .sent)
        if case .success(let photoStrip) = viewModel.step {
            #expect(printer.printedImages.first === photoStrip)
        } else {
            Issue.record("Expected step to be .success")
        }
    }

    @Test func printFailureReportsFailedButKeepsSuccessAndTheSavedSession() async throws {
        let repository = InMemoryPhotoSessionRepository()
        let printer = FakePrinterConnectionService()
        printer.printError = PrintError.printerUnavailable
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printer, supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())

        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        #expect(viewModel.printStatus == .failed)
        #expect(repository.sessions.count == 1)
        if case .success = viewModel.step {
        } else {
            Issue.record("Expected step to stay .success")
        }
    }

    @Test func debugModeWithNoPairedPrinterSkipsPrinting() async throws {
        let printer = FakePrinterConnectionService()
        printer.hasPairedPrinter = false
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printer, supplyTracker: .forTesting(), screenFlash: FakeScreenFlash(), isDebugMode: true)

        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        #expect(viewModel.printStatus == .skipped)
        #expect(printer.printedImages.isEmpty)
    }

    @Test func debugModeWithAPairedPrinterStillPrints() async throws {
        let printer = FakePrinterConnectionService()
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printer, supplyTracker: .forTesting(), screenFlash: FakeScreenFlash(), isDebugMode: true)

        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        #expect(viewModel.printStatus == .sent)
        #expect(printer.printedImages.count == 1)
    }

    @Test func startSessionResetsPrintStatus() async throws {
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        viewModel.finishSession()
        viewModel.startSession()

        #expect(viewModel.printStatus == .idle)
    }

    @Test func aSentPrintCountsAgainstPrintSupplies() async throws {
        let tracker = PrintSupplyTracker.forTesting()
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: tracker, screenFlash: FakeScreenFlash())

        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        #expect(tracker.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity - 1)
    }

    @Test func aFailedPrintDoesNotCountAgainstPrintSupplies() async throws {
        let printer = FakePrinterConnectionService()
        printer.printError = PrintError.printerUnavailable
        let tracker = PrintSupplyTracker.forTesting()
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printer, supplyTracker: tracker, screenFlash: FakeScreenFlash())

        try await viewModel.confirmAndSave(photos: samplePhotos())
        await viewModel.printTask?.value

        #expect(tracker.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity)
    }

    @Test func openStaffMenuPresentsItWithoutDisturbingTheFlow() {
        let viewModel = CustomerExperienceViewModel(repository: InMemoryPhotoSessionRepository(), cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        viewModel.startSession()

        viewModel.openStaffMenu()

        #expect(viewModel.isStaffMenuPresented)
        #expect(viewModel.step == .capture(mode: .fullSequence, existingPhotos: []))
    }

    @Test func finishSessionReturnsToAttract() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = CustomerExperienceViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting(), screenFlash: FakeScreenFlash())
        viewModel.captureSequenceCompleted(photos: [])

        viewModel.finishSession()

        #expect(viewModel.step == .attract)
    }
}
