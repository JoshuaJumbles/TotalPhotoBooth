import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct GuidedAccessTests {
    // MARK: Starting with Guided Access off

    @Test func startingUnlockedAsksForConfirmationWithoutStartingTheCamera() async {
        let camera = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel.forTesting(
            cameraService: camera, guidedAccess: FakeGuidedAccessStatus(isEnabled: false)
        )

        await viewModel.startKioskMode()

        #expect(viewModel.isConfirmingUnlockedStart)
        #expect(camera.startHardwareSessionCallCount == 0)
        #expect(!viewModel.isPresentingCustomerExperience)
    }

    @Test func startAnywayEntersTheKioskUnlocked() async {
        let camera = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel.forTesting(
            cameraService: camera, guidedAccess: FakeGuidedAccessStatus(isEnabled: false)
        )

        await viewModel.startKioskMode(skippingGuidedAccessCheck: true)

        #expect(camera.startHardwareSessionCallCount == 1)
        #expect(viewModel.isPresentingCustomerExperience)
    }

    @Test func startingLockedGoesStraightIn() async {
        let viewModel = SessionConfigurationViewModel.forTesting(guidedAccess: FakeGuidedAccessStatus(isEnabled: true))

        await viewModel.startKioskMode()

        #expect(!viewModel.isConfirmingUnlockedStart)
        #expect(viewModel.isPresentingCustomerExperience)
    }

    @Test func debugModeSkipsTheUnlockedWarning() async {
        let viewModel = SessionConfigurationViewModel.forTesting(guidedAccess: FakeGuidedAccessStatus(isEnabled: false))
        viewModel.isDebugModeEnabled = true

        await viewModel.startKioskMode()

        #expect(!viewModel.isConfirmingUnlockedStart)
        #expect(viewModel.isPresentingCustomerExperience)
    }

    // MARK: Resuming after a relaunch

    @Test func aRealRunIsRememberedUntilStaffExit() async {
        let store = KioskResumeStore(defaults: .forTesting())
        let viewModel = SessionConfigurationViewModel.forTesting(resumeStore: store)

        await viewModel.startKioskMode()
        #expect(store.wasInKioskMode)

        await viewModel.endKioskMode()
        #expect(!store.wasInKioskMode)
    }

    @Test func aDebugRunIsNotRemembered() async {
        let store = KioskResumeStore(defaults: .forTesting())
        let viewModel = SessionConfigurationViewModel.forTesting(resumeStore: store)
        viewModel.isDebugModeEnabled = true

        await viewModel.startKioskMode()

        #expect(viewModel.isPresentingCustomerExperience)
        #expect(!store.wasInKioskMode)
    }

    @Test func relaunchUnderGuidedAccessResumesTheKiosk() async {
        let store = KioskResumeStore(defaults: .forTesting())
        store.wasInKioskMode = true
        let viewModel = SessionConfigurationViewModel.forTesting(
            guidedAccess: FakeGuidedAccessStatus(isEnabled: true), resumeStore: store
        )

        await viewModel.resumeKioskModeIfNeeded()

        #expect(viewModel.isPresentingCustomerExperience)
    }

    @Test func relaunchWithoutGuidedAccessStaysOnConfig() async {
        let store = KioskResumeStore(defaults: .forTesting())
        store.wasInKioskMode = true
        let camera = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel.forTesting(
            cameraService: camera, guidedAccess: FakeGuidedAccessStatus(isEnabled: false), resumeStore: store
        )

        await viewModel.resumeKioskModeIfNeeded()

        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(!viewModel.isConfirmingUnlockedStart)
        #expect(camera.startHardwareSessionCallCount == 0)
    }

    @Test func relaunchAfterStaffExitedStaysOnConfig() async {
        let camera = FakeCameraCaptureService()
        let viewModel = SessionConfigurationViewModel.forTesting(
            cameraService: camera, guidedAccess: FakeGuidedAccessStatus(isEnabled: true)
        )

        await viewModel.resumeKioskModeIfNeeded()

        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(camera.startHardwareSessionCallCount == 0)
    }

    @Test func aFailedResumeKeepsTryingOnTheNextLaunch() async {
        let store = KioskResumeStore(defaults: .forTesting())
        store.wasInKioskMode = true
        let camera = FakeCameraCaptureService()
        camera.startHardwareSessionError = CameraCaptureError.permissionDenied
        let viewModel = SessionConfigurationViewModel.forTesting(
            cameraService: camera, guidedAccess: FakeGuidedAccessStatus(isEnabled: true), resumeStore: store
        )

        await viewModel.resumeKioskModeIfNeeded()

        #expect(!viewModel.isPresentingCustomerExperience)
        #expect(viewModel.errorMessage != nil)
        #expect(store.wasInKioskMode)
    }

    // MARK: Staff menu

    @Test func theStaffMenuSeesTheLiveGuidedAccessStatus() async {
        let status = FakeGuidedAccessStatus(isEnabled: true)
        let viewModel = SessionConfigurationViewModel.forTesting(guidedAccess: status)

        await viewModel.startKioskMode()
        let staffMenu = viewModel.customerExperienceViewModel?.staffMenu
        #expect(staffMenu?.guidedAccess.isEnabled == true)

        status.isEnabled = false
        #expect(staffMenu?.guidedAccess.isEnabled == false)
    }
}
