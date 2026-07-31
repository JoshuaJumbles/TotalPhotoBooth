import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

@MainActor
struct SessionConfigurationViewModelTests {
    @Test func loadInitialCountReflectsExistingSessions() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession(), PhotoSession()])
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService())

        await viewModel.loadInitialCount()

        #expect(viewModel.sessionCount == 2)
    }

    @Test func startKioskModeStartsHardwareSessionAndPresentsCustomerExperience() async {
        let repository = InMemoryPhotoSessionRepository()
        let cameraService = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService, photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService())

        await viewModel.startKioskMode()

        #expect(cameraService.startHardwareSessionCallCount == 1)
        #expect(viewModel.isPresentingCustomerExperience)
        #expect(!viewModel.isStartingKioskMode)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func startKioskModeSetsErrorMessageWhenHardwareSessionFailsToStart() async {
        let repository = InMemoryPhotoSessionRepository()
        let cameraService = FakeCameraCaptureService()
        cameraService.startHardwareSessionError = CameraCaptureError.permissionDenied
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService, photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService())

        await viewModel.startKioskMode()

        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(!viewModel.isStartingKioskMode)
    }

    @Test func endKioskModeStopsHardwareSessionDismissesCustomerExperienceAndRefreshesCount() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession()])
        let cameraService = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService, photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: FakePrinterConnectionService())
        await viewModel.startKioskMode()

        await viewModel.endKioskMode()

        #expect(cameraService.endHardwareSessionCallCount == 1)
        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(viewModel.sessionCount == 1)
    }

    @Test func checkPrinterConnectionReflectsAConnectedPrinter() async {
        let repository = InMemoryPhotoSessionRepository()
        let printerConnectionService = FakePrinterConnectionService()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printerConnectionService)

        await viewModel.checkPrinterConnection()

        #expect(viewModel.isPrinterConnected)
        #expect(viewModel.pairedPrinterName != nil)
    }

    @Test func checkPrinterConnectionReflectsNoPrinterConnected() async {
        let repository = InMemoryPhotoSessionRepository()
        let printerConnectionService = FakePrinterConnectionService()
        printerConnectionService.reconnectResult = nil
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printerConnectionService)

        await viewModel.checkPrinterConnection()

        #expect(!viewModel.isPrinterConnected)
        #expect(viewModel.pairedPrinterName == nil)
    }

    @Test func startKioskModeBlocksAndDoesNotStartCameraSessionWhenPrinterNotConnected() async {
        let repository = InMemoryPhotoSessionRepository()
        let cameraService = FakeCameraCaptureService()
        let printerConnectionService = FakePrinterConnectionService()
        printerConnectionService.reconnectResult = nil
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService, photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printerConnectionService)

        await viewModel.startKioskMode()

        #expect(cameraService.startHardwareSessionCallCount == 0)
        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(!viewModel.isPrinterConnected)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func startKioskModeBypassesPrinterGateWhenDebugModeEnabled() async {
        let repository = InMemoryPhotoSessionRepository()
        let cameraService = FakeCameraCaptureService()
        let printerConnectionService = FakePrinterConnectionService()
        printerConnectionService.reconnectResult = nil
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService, photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printerConnectionService)
        viewModel.isDebugModeEnabled = true

        await viewModel.startKioskMode()

        #expect(cameraService.startHardwareSessionCallCount == 1)
        #expect(viewModel.isPresentingCustomerExperience)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func printerSelectedPersistsPairingAndUpdatesDisplayedState() {
        let repository = InMemoryPhotoSessionRepository()
        let printerConnectionService = FakePrinterConnectionService()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService(), photoLibrarySaver: FakePhotoLibrarySaver(), printerConnectionService: printerConnectionService)
        let printer = UIPrinter(url: URL(string: "ipp://192.168.1.200/printer")!)

        viewModel.printerSelected(printer)

        #expect(printerConnectionService.pairedPrinter != nil)
        #expect(viewModel.isPrinterConnected)
        #expect(viewModel.pairedPrinterName != nil)
    }
}
