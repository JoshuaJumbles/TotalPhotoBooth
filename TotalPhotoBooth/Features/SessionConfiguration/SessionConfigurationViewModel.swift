import Foundation

@Observable
final class SessionConfigurationViewModel {
    private(set) var sessionCount: Int = 0
    private(set) var isPresentingCustomerExperience: Bool = false
    private(set) var isStartingKioskMode: Bool = false
    var errorMessage: String?

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol

    init(repository: PhotoSessionRepositoryProtocol, cameraService: CameraCaptureServiceProtocol) {
        self.repository = repository
        self.cameraService = cameraService
    }

    func loadInitialCount() async {
        do {
            sessionCount = try await repository.fetchAll().count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startKioskMode() async {
        isStartingKioskMode = true
        defer { isStartingKioskMode = false }
        do {
            try await cameraService.startHardwareSession()
            isPresentingCustomerExperience = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endKioskMode() async {
        cameraService.endHardwareSession()
        isPresentingCustomerExperience = false
        await loadInitialCount()
    }

    func makeCustomerExperienceViewModel() -> CustomerExperienceViewModel {
        CustomerExperienceViewModel(repository: repository, cameraService: cameraService)
    }
}
