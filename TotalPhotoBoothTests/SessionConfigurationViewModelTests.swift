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

    @Test func startKioskModePresentsCustomerExperience() {
        let repository = InMemoryPhotoSessionRepository()
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService())

        viewModel.startKioskMode()

        #expect(viewModel.isPresentingCustomerExperience)
    }

    @Test func endKioskModeDismissesCustomerExperienceAndRefreshesCount() async {
        let repository = InMemoryPhotoSessionRepository(sessions: [PhotoSession()])
        let viewModel = SessionConfigurationViewModel(repository: repository, cameraService: FakeCameraCaptureService())
        viewModel.startKioskMode()

        await viewModel.endKioskMode()

        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(viewModel.sessionCount == 1)
    }
}
