import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

@MainActor
struct StaffMenuViewModelTests {
    private struct LoadFailure: Error {}

    private let photoData = UIImage(color: .red)!.pngData()!

    @Test func reprintPrintsThePickedPhotoAndCountsIt() async {
        let printer = FakePrinterConnectionService()
        let tracker = PrintSupplyTracker.forTesting()
        let viewModel = StaffMenuViewModel(printerConnectionService: printer, supplyTracker: tracker)

        await viewModel.reprint { photoData }

        #expect(viewModel.reprintStatus == .sent)
        #expect(printer.printedImages.count == 1)
        #expect(tracker.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity - 1)
    }

    @Test func reprintFailsWithoutPrintingWhenThePhotoCantBeDecoded() async {
        let printer = FakePrinterConnectionService()
        let viewModel = StaffMenuViewModel(printerConnectionService: printer, supplyTracker: .forTesting())

        await viewModel.reprint { Data("not an image".utf8) }

        #expect(isFailed(viewModel.reprintStatus))
        #expect(printer.printedImages.isEmpty)
    }

    @Test func reprintFailsWithoutPrintingWhenLoadingThePhotoThrows() async {
        let printer = FakePrinterConnectionService()
        let viewModel = StaffMenuViewModel(printerConnectionService: printer, supplyTracker: .forTesting())

        await viewModel.reprint { throw LoadFailure() }

        #expect(isFailed(viewModel.reprintStatus))
        #expect(printer.printedImages.isEmpty)
    }

    @Test func reprintReportsAPrinterErrorAndDoesNotCountIt() async {
        let printer = FakePrinterConnectionService()
        printer.printError = PrintError.printerUnavailable
        let tracker = PrintSupplyTracker.forTesting()
        let viewModel = StaffMenuViewModel(printerConnectionService: printer, supplyTracker: tracker)

        await viewModel.reprint { photoData }

        #expect(viewModel.reprintStatus == .failed(message: PrintError.printerUnavailable.localizedDescription))
        #expect(tracker.remaining(.paper) == PrintSupplyTracker.Supply.paper.capacity)
    }

    @Test func clearingFinishedStatusResetsAResultButNotAnIdleMenu() async {
        let viewModel = StaffMenuViewModel(printerConnectionService: FakePrinterConnectionService(), supplyTracker: .forTesting())
        await viewModel.reprint { photoData }
        #expect(viewModel.reprintStatus == .sent)

        viewModel.clearFinishedReprintStatus()

        #expect(viewModel.reprintStatus == .idle)
    }

    private func isFailed(_ status: StaffMenuViewModel.ReprintStatus) -> Bool {
        if case .failed = status { return true }
        return false
    }
}
