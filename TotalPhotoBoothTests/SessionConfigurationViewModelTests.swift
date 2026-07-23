import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct SessionConfigurationViewModelTests {
    @Test func loadInitialCountReflectsExistingSessions() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession(), PhotoSession()])
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService())

        await viewModel.loadInitialCount()

        #expect(viewModel.sessionCount == 2)
    }

    @Test func startKioskModeStartsHardwareSessionAndPresentsCustomerExperience() async {
        let repository = InMemoryPhotoSessionRepository()
        let cameraService = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService)

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
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService)

        await viewModel.startKioskMode()

        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(!viewModel.isStartingKioskMode)
    }

    @Test func endKioskModeStopsHardwareSessionDismissesCustomerExperienceAndRefreshesCount() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession()])
        let cameraService = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: cameraService)
        await viewModel.startKioskMode()

        await viewModel.endKioskMode()

        #expect(cameraService.endHardwareSessionCallCount == 1)
        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(viewModel.sessionCount == 1)
    }
}
